import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import 'engine.dart';
import 'messages.g.dart';

enum WorkspacePhase { detached, switching, loading, visible, failed }

class SessionFailure implements Exception {
  const SessionFailure(this.code);
  final String code;
  @override
  String toString() => 'SessionFailure($code)';
}

/// A snapshot of shell state. Navigation completion is never authentication.
class SessionState {
  const SessionState({
    this.selectedProfileId,
    this.phase = WorkspacePhase.detached,
    this.covered = true,
    this.locked = false,
    this.transferActive = false,
    this.transferProgress,
    this.network = NetworkObservation.unknown,
    this.generation = 0,
    this.errorCode,
    this.requiresReconciliation = false,
    _ViewIdentity? identity,
  }) : _identity = identity;

  final String? selectedProfileId;
  final WorkspacePhase phase;
  final bool covered;
  final bool locked;
  final bool transferActive;
  final double? transferProgress;
  final NetworkObservation network;
  final int generation;
  final String? errorCode;
  final bool requiresReconciliation;
  final _ViewIdentity? _identity;

  // Pigeon transport DTOs are mutable. Never expose the internal owner instance.
  ViewHandle? get view => _identity?.toHandle();
}

class _ViewIdentity {
  _ViewIdentity(ViewHandle handle)
    : profileId = handle.profileId,
      viewInstanceId = handle.viewInstanceId,
      operationId = handle.operationId,
      generation = handle.selectionGeneration;

  final String profileId;
  final String viewInstanceId;
  final String operationId;
  final int generation;

  ViewHandle toHandle() => ViewHandle(
    profileId: profileId,
    viewInstanceId: viewInstanceId,
    operationId: operationId,
    selectionGeneration: generation,
  );

  bool matches(ViewHandle other) =>
      profileId == other.profileId &&
      viewInstanceId == other.viewInstanceId &&
      operationId == other.operationId &&
      generation == other.selectionGeneration;
}

class _CleanupInvocation {
  const _CleanupInvocation(this.completion);
  final Future<void> completion;
}

/// Serializes native view ownership, while cleanup events remain selection-free.
/// Native SQLite is the sole durable authority. This object stores no journal.
class SessionCoordinator {
  SessionCoordinator(
    this.engine, {
    this.operationTimeout = const Duration(seconds: 30),
  }) {
    _subscription = engine.events.listen(
      _onEvent,
      onError: (_) {
        _fail('engine_event_failure');
      },
    );
  }

  final SessionEngine engine;
  final Duration operationTimeout;
  final _states = StreamController<SessionState>.broadcast(sync: true);
  final _cleanup = StreamController<EngineEvent>.broadcast(sync: true);
  final _blockedProfiles = <String>{};
  final _random = Random.secure();
  late final StreamSubscription<EngineEvent> _subscription;
  Future<void> _tail = Future<void>.value();
  SessionState _state = const SessionState();
  _ViewIdentity? _active;
  int _generation = 0;
  int _lockGeneration = 0;
  bool _closed = false;
  int _pendingReconciliations = 0;
  bool _reconciliationFailed = false;
  bool _ready = false;
  Future<bool>? _unlockInFlight;
  bool get _uncertain => _pendingReconciliations > 0 || _reconciliationFailed;

  SessionState get state => _state;
  Stream<SessionState> get states => _states.stream;
  Stream<EngineEvent> get cleanupEvents => _cleanup.stream;

  String _id() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  void _publish({
    String? selectedProfileId,
    bool clearSelection = false,
    WorkspacePhase? phase,
    bool? covered,
    bool? locked,
    bool? transferActive,
    double? transferProgress,
    bool clearTransferProgress = false,
    NetworkObservation? network,
    String? errorCode,
  }) {
    if (_closed) return;
    _state = SessionState(
      selectedProfileId: clearSelection
          ? null
          : selectedProfileId ?? _state.selectedProfileId,
      phase: phase ?? _state.phase,
      covered: covered ?? _state.covered,
      locked: locked ?? _state.locked,
      transferActive: transferActive ?? _state.transferActive,
      transferProgress: transferActive == false || clearTransferProgress
          ? null
          : transferProgress ?? _state.transferProgress,
      network: network ?? _state.network,
      generation: _generation,
      errorCode: errorCode,
      requiresReconciliation: _uncertain,
      identity: _active,
    );
    _states.add(_state);
  }

  void _fail(String code) =>
      _publish(phase: WorkspacePhase.failed, covered: true, errorCode: code);

  Future<T> _enqueue<T>(Future<T> Function() action) {
    if (_closed)
      return Future<T>.error(const SessionFailure('coordinator_closed'));
    final result = _tail.then((_) async {
      if (_closed) throw const SessionFailure('coordinator_closed');
      return action();
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  void _checkUncertain() {
    if (_uncertain) throw const SessionFailure('reconciliation_required');
  }

  /// A timeout does not cancel native work. New mutations remain blocked until
  /// its real result has been reconciled; a late opened view is disposed.
  Future<T> _mutation<T>(
    Future<T> source, {
    Future<void> Function(T)? reconcile,
  }) async {
    try {
      return await source.timeout(operationTimeout);
    } on TimeoutException {
      _pendingReconciliations++;
      _fail('operation_timeout');
      unawaited(
        source
            .then<void>(
              (value) async {
                if (reconcile != null) await reconcile(value);
                _pendingReconciliations--;
                _publish(
                  covered: true,
                  phase: WorkspacePhase.failed,
                  errorCode: 'operation_reconciled',
                );
              },
              onError: (Object _, StackTrace __) {
                _pendingReconciliations--;
                _fail('operation_failed_after_timeout');
              },
            )
            .catchError((Object _) {
              // Failed late disposal requires restart/native reconciliation. Fail closed.
              _pendingReconciliations--;
              _reconciliationFailed = true;
              _fail('reconciliation_required');
            }),
      );
      throw const SessionFailure('operation_timeout');
    }
  }

  String _errorCode(Object error) {
    if (error is SessionFailure) return error.code;
    if (error is PlatformException) return error.code;
    if (error is TimeoutException) return 'operation_timeout';
    return 'engine_failure';
  }

  Future<EngineSnapshot> initialize() => _enqueue(() async {
    _checkUncertain();
    final snapshot = await _mutation(engine.initialize());
    _blockedProfiles.addAll(
      snapshot.profiles
          .where(
            (p) =>
                p.state == StoreState.removing ||
                p.state == StoreState.cleanupPending,
          )
          .map((p) => p.id),
    );
    _publish(
      locked: snapshot.locked,
      transferActive: snapshot.transferActive,
      network: snapshot.network,
      covered: true,
    );
    return snapshot;
  });

  Future<void> select(String profileId, {bool cancelActiveTransfer = false}) {
    if (_state.transferActive && !cancelActiveTransfer) {
      return Future.error(const SessionFailure('transfer_active'));
    }
    if (_blockedProfiles.contains(profileId))
      return Future.error(const SessionFailure('profile_unavailable'));
    final generation = ++_generation;
    return _enqueue(() async {
      if (generation != _generation) return;
      try {
        _checkUncertain();
        // Alias remains unchanged until native cover has actually been applied.
        await _mutation(engine.setPrivacyCover(true, _active?.toHandle()));
        if (generation != _generation) return;
        _publish(covered: true, phase: WorkspacePhase.switching);
        if (_state.transferActive) {
          if (!cancelActiveTransfer)
            throw const SessionFailure('transfer_active');
          await _mutation(engine.cancelTransfer());
          if (generation != _generation) return;
          _publish(transferActive: false);
        }
        await _disposeActive();
        if (generation != _generation) return;
        final profiles = await engine.listProfiles().timeout(operationTimeout);
        if (generation != _generation) return;
        final eligible = profiles.any(
          (p) => p.id == profileId && p.state == StoreState.available,
        );
        if (!eligible || _blockedProfiles.contains(profileId))
          throw const SessionFailure('profile_unavailable');
        _publish(
          selectedProfileId: profileId,
          phase: WorkspacePhase.loading,
          covered: true,
        );
        final operationId = _id();
        final handle = await _mutation(
          engine.openProfile(profileId, operationId, generation),
          reconcile: (lateView) => engine.disposeView(lateView),
        );
        final identity = _ViewIdentity(handle);
        if (handle.profileId != profileId ||
            handle.operationId != operationId ||
            handle.selectionGeneration != generation) {
          await _mutation(engine.disposeView(handle));
          throw const SessionFailure('invalid_view_binding');
        }
        if (generation != _generation || _blockedProfiles.contains(profileId)) {
          await _mutation(engine.disposeView(identity.toHandle()));
          return;
        }
        _active = identity;
        _ready = false;
        _publish(covered: true, phase: WorkspacePhase.loading);
      } catch (error) {
        if (generation == _generation) _fail(_errorCode(error));
        rethrow;
      }
    });
  }

  Future<void> _disposeActive() async {
    final previous = _active;
    if (previous == null) return;
    await _mutation(
      engine.disposeView(previous.toHandle()),
      reconcile: (_) async {
        if (identical(previous, _active)) _active = null;
      },
    );
    if (identical(previous, _active)) _active = null;
    _ready = false;
  }

  bool _owns(ViewHandle view) =>
      _active?.matches(view) == true &&
      view.selectionGeneration == _generation &&
      !_blockedProfiles.contains(view.profileId) &&
      _state.selectedProfileId == view.profileId;

  void _onEvent(EngineEvent event) {
    if (_closed) return;
    if (event.kind == EngineEventKind.networkChanged) {
      _publish(network: event.network, errorCode: _state.errorCode);
      return;
    }
    if (event.kind == EngineEventKind.unlockRequested) {
      if (_state.locked) {
        unawaited(
          unlock().catchError((Object error) {
            _fail(_errorCode(error));
            return false;
          }),
        );
      }
      return;
    }
    if (event.kind == EngineEventKind.cleanupChanged) {
      // Native has persisted this stage. Selection generation is irrelevant.
      if (event.profileId != null && event.cleanupOperationId != null)
        _cleanup.add(event);
      return;
    }
    if (event.kind == EngineEventKind.privacyChanged) {
      final locked = event.locked;
      if (locked == null) return;
      if (locked) _lockGeneration++;
      // An explicit unlock call owns authentication completion. A late native
      // unlocked notification cannot cancel a newer manual/background lock.
      if (!locked && _state.locked) return;
      _publish(locked: locked, covered: true);
      // Native emits unlocked only on eligible foreground return and also
      // rejects reveal while backgrounded independently of app-lock settings.
      final view = _active?.toHandle();
      if (!locked && view != null) {
        unawaited(
          _enqueue(() => _revealIfEligible(view)).catchError((Object error) {
            if (_owns(view)) _fail(_errorCode(error));
          }),
        );
      }
      return;
    }
    if (event.kind == EngineEventKind.transferChanged) {
      final view = event.view;
      if (view != null && _owns(view)) {
        final progress = event.progress;
        _publish(
          transferActive: event.transferActive ?? false,
          transferProgress: progress != null && progress.isFinite
              ? progress.clamp(0, 1)
              : null,
          clearTransferProgress: progress == null || !progress.isFinite,
        );
      }
      return;
    }
    final eventView = event.view;
    if (eventView == null) return;
    // Freeze mutable transport values before queuing asynchronous work.
    final view = _ViewIdentity(eventView).toHandle();
    final kind = event.kind;
    final code = event.errorCode;
    unawaited(
      _enqueue(() async {
        if (!_owns(view) || _uncertain) return;
        if (kind == EngineEventKind.viewFailed) {
          _ready = false;
          await _mutation(engine.setPrivacyCover(true, view));
          if (_owns(view)) _fail(code ?? 'navigation_failed');
        } else if (kind == EngineEventKind.viewReady) {
          _ready = true;
          await _revealIfEligible(view);
        }
      }).catchError((Object error) {
        if (_owns(view)) _fail(_errorCode(error));
      }),
    );
  }

  Future<void> _revealIfEligible(ViewHandle view) async {
    if (!_owns(view) || _state.locked || !_ready || _uncertain) return;
    await _mutation(
      engine.setPrivacyCover(false, view),
      reconcile: (_) => engine.setPrivacyCover(true, view),
    );
    if (_owns(view) && !_state.locked)
      _publish(phase: WorkspacePhase.visible, covered: false);
  }

  /// Rebuilds only the selected view against its existing store. A fresh owner
  /// invalidates callbacks from the prior navigation without reading page state.
  Future<void> reload() {
    final profileId = _state.selectedProfileId;
    if (profileId == null)
      return Future.error(const SessionFailure('no_active_view'));
    return select(profileId);
  }

  Future<void> detach() {
    ++_generation;
    return _enqueue(() async {
      _checkUncertain();
      await _mutation(engine.setPrivacyCover(true, _active?.toHandle()));
      _publish(covered: true);
      await _disposeActive();
      _publish(
        clearSelection: true,
        phase: WorkspacePhase.detached,
        transferActive: false,
      );
    });
  }

  Future<void> lock() async {
    if (_closed) throw const SessionFailure('coordinator_closed');
    // Block queued reveals immediately. Native also covers on lifecycle events.
    ++_lockGeneration;
    _publish(locked: true, covered: true);
    try {
      // Privacy takes priority over an in-flight view/navigation operation.
      await _mutation(engine.lockApp());
      _publish(locked: true, covered: true, transferActive: false);
    } catch (error) {
      _fail(_errorCode(error));
      rethrow;
    }
  }

  Future<bool> unlock() {
    if (_unlockInFlight != null) return _unlockInFlight!;
    if (!_state.locked) return Future.value(true);
    late final Future<bool> result;
    result =
        _enqueue(() async {
          _checkUncertain();
          final lockGeneration = _lockGeneration;
          final authenticated = await _mutation(
            engine.authenticate(),
            reconcile: (_) => engine.lockApp(),
          );
          if (lockGeneration != _lockGeneration) {
            await _mutation(engine.lockApp());
            _publish(locked: true, covered: true);
            return false;
          }
          _publish(locked: !authenticated, covered: true);
          final view = _active?.toHandle();
          if (authenticated && view != null) await _revealIfEligible(view);
          return authenticated;
        }).whenComplete(() {
          if (identical(_unlockInFlight, result)) _unlockInFlight = null;
        });
    _unlockInFlight = result;
    return result;
  }

  Future<void> removeProfile(String profileId) {
    // A local guard closes the interval before native SQLite persists tombstone.
    _blockedProfiles.add(profileId);
    if (_state.selectedProfileId == profileId ||
        _active?.profileId == profileId)
      ++_generation;
    final preparation = _enqueue<_CleanupInvocation>(() async {
      _checkUncertain();
      if (_state.selectedProfileId == profileId ||
          _active?.profileId == profileId) {
        await _mutation(engine.setPrivacyCover(true, _active?.toHandle()));
        _publish(covered: true);
        await _disposeActive();
        _publish(
          clearSelection: true,
          covered: true,
          phase: WorkspacePhase.detached,
          transferActive: false,
        );
      }
      // Begin native tombstoning in command order, but do not hold the view
      // selection queue while an inactive store's deletion callback is pending.
      return _CleanupInvocation(engine.requestLocalRemoval(profileId, _id()));
    });
    return preparation.then(
      (invocation) => invocation.completion.timeout(
        operationTimeout,
        onTimeout: () => throw const SessionFailure('cleanup_timeout'),
      ),
    );
  }

  Future<void> dispose() async {
    if (_closed) return;
    await detach();
    _closed = true;
    await _subscription.cancel();
    await _states.close();
    await _cleanup.close();
  }
}
