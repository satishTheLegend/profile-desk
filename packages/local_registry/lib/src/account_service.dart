import 'dart:async';

import 'package:session_contract/session_contract.dart';

import 'account_setup_archive.dart';

/// Metadata facade, never a second database or deletion journal.
class AccountService {
  AccountService(
    this.engine,
    this.coordinator, {
    this.operationTimeout = const Duration(seconds: 30),
    this.onSetupCommitted,
  }) {
    _subscription = engine.events.listen((event) {
      if (event.kind == EngineEventKind.profilesChanged ||
          event.kind == EngineEventKind.cleanupChanged) {
        unawaited(
          refresh().catchError((Object error, StackTrace trace) {
            if (!_closed) _changes.addError(error, trace);
            return profiles;
          }),
        );
      }
    });
  }

  static const capacity = 10;
  static const maxAliasLength = 40;
  final SessionEngine engine;
  final SessionCoordinator coordinator;
  final Duration operationTimeout;
  final Future<void> Function()? onSetupCommitted;
  final _changes = StreamController<List<AccountProfile>>.broadcast();
  late final StreamSubscription<EngineEvent> _subscription;
  List<AccountProfile> _profiles = [];
  int _refreshGeneration = 0;
  int _publishedRefreshGeneration = 0;
  bool _closed = false;
  final _replacements = <String>{};
  int _pendingMutations = 0;

  List<AccountProfile> get profiles => List.unmodifiable(_profiles.map(_copy));
  Stream<List<AccountProfile>> get changes => _changes.stream;
  bool get requiresReconciliation => _pendingMutations > 0;

  Future<T> _mutate<T>(Future<T> Function() operation) async {
    if (_closed) throw const SessionFailure('account_service_closed');
    if (requiresReconciliation)
      throw const SessionFailure('registry_reconciliation_required');
    final source = Future<T>.sync(operation);
    try {
      return await source.timeout(operationTimeout);
    } on TimeoutException {
      _pendingMutations++;
      // Keep the original platform future: a timeout is not cancellation. Do
      // not replay the mutation or select a profile created by a late result.
      Future<void> refreshOutcome() async {
        if (!_closed) await refresh();
      }

      unawaited(
        source
            .then<void>(
              (_) => refreshOutcome(),
              onError: (Object _, StackTrace __) => refreshOutcome(),
            )
            .whenComplete(() {
              _pendingMutations--;
            })
            .catchError((Object _, StackTrace trace) {
              if (!_closed)
                _changes.addError(
                  const SessionFailure('registry_refresh_required'),
                  trace,
                );
            }),
      );
      throw const SessionFailure('registry_operation_timeout');
    }
  }

  // Capacity is ultimately enforced by native SQLite in the reservation transaction.
  int get usedSlots => _profiles.where(_reservesSlot).length;

  static bool _reservesSlot(AccountProfile p) =>
      !(p.state == StoreState.cleanupPending &&
          p.cleanupStage == 'containerDeletionPending');

  static AccountProfile _copy(AccountProfile p) => AccountProfile(
    id: p.id,
    platformProfileId: p.platformProfileId,
    alias: p.alias,
    color: p.color,
    orderIndex: p.orderIndex,
    createdAt: p.createdAt,
    lastOpenedAt: p.lastOpenedAt,
    state: p.state,
    observation: p.observation,
    cleanupOperationId: p.cleanupOperationId,
    cleanupStage: p.cleanupStage,
  );

  static String normalizedAlias(String alias) => alias.trim().toLowerCase();

  String _validateAlias(
    String alias, {
    String? excludingId,
    Iterable<AccountProfile>? existingProfiles,
  }) {
    final trimmed = alias.trim();
    if (trimmed.isEmpty) throw const SessionFailure('alias_empty');
    if (trimmed.runes.length > maxAliasLength)
      throw const SessionFailure('alias_too_long');
    if (trimmed.runes.any((r) => r < 32 || (r >= 127 && r <= 159)))
      throw const SessionFailure('alias_invalid');
    final normalized = normalizedAlias(trimmed);
    if ((existingProfiles ?? _profiles).any(
      (p) =>
          p.id != excludingId &&
          _reservesSlot(p) &&
          normalizedAlias(p.alias) == normalized,
    )) {
      throw const SessionFailure('alias_duplicate');
    }
    return trimmed;
  }

  Future<List<AccountProfile>> refresh() async {
    final generation = ++_refreshGeneration;
    final result = await engine.listProfiles().timeout(
      operationTimeout,
      onTimeout: () => throw const SessionFailure('registry_read_timeout'),
    );
    final fresh = result.map(_copy).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    // A newer requested read may still be pending or fail. Publish this completed
    // read unless a newer read has already committed its snapshot.
    if (!_closed && generation > _publishedRefreshGeneration) {
      _publishedRefreshGeneration = generation;
      _profiles = fresh;
      _changes.add(profiles);
    }
    // A newer refresh may still be pending. Return this read's actual result,
    // never an older cached snapshot, to lifecycle callers making decisions.
    return List.unmodifiable(fresh.map(_copy));
  }

  Future<AccountProfile> add(String alias, int color) async {
    final validated = _validateAlias(alias);
    final profile = await _mutate(
      () => engine.allocateProfile(validated, color),
    );
    await refresh();
    return _copy(profile);
  }

  Future<void> rename(String profileId, String alias, int color) async {
    await _mutate(
      () => engine.renameProfile(
        profileId,
        _validateAlias(alias, excludingId: profileId),
        color,
      ),
    );
    await refresh();
  }

  Future<void> reorder(List<String> profileIds) async {
    final current = _profiles
        .where(
          (p) =>
              p.state != StoreState.removing &&
              p.state != StoreState.cleanupPending,
        )
        .map((p) => p.id)
        .toSet();
    if (profileIds.length != current.length ||
        profileIds.toSet().length != profileIds.length ||
        !current.containsAll(profileIds)) {
      throw const SessionFailure('invalid_order');
    }
    await _mutate(() => engine.reorderProfiles(List.of(profileIds)));
    await refresh();
  }

  Future<void> confirmAccount(String profileId) async {
    await _mutate(
      () => engine.setObservation(profileId, AuthObservation.userConfirmed),
    );
    await refresh();
  }

  Future<void> requestRelink(String profileId) async {
    await _mutate(
      () => engine.setObservation(profileId, AuthObservation.relinkRequested),
    );
    await refresh();
    await coordinator.select(profileId);
  }

  Future<void> remove(String profileId) async {
    await coordinator.removeProfile(profileId);
    await refresh();
  }

  /// Replaces only an unavailable store, after its actual wipe has completed.
  /// Alias preservation is a deliberate caller choice; browser IDs never carry over.
  Future<AccountProfile> replaceUnavailable(
    String profileId, {
    required bool keepAlias,
    String? newAlias,
  }) async {
    if (!_replacements.add(profileId))
      throw const SessionFailure('replacement_in_progress');
    try {
      final before = await refresh();
      final matches = before.where((p) => p.id == profileId);
      if (matches.length != 1 ||
          (matches.single.state != StoreState.missing &&
              matches.single.state != StoreState.quarantined)) {
        throw const SessionFailure('replacement_not_eligible');
      }
      final previous = _copy(matches.single);
      String alias;
      if (keepAlias) {
        alias = previous.alias;
      } else if (newAlias != null) {
        alias = _validateAlias(
          newAlias,
          excludingId: profileId,
          existingProfiles: before,
        );
      } else {
        alias = 'New account';
        var suffix = 2;
        while (before.any(
          (p) =>
              _reservesSlot(p) &&
              normalizedAlias(p.alias) == normalizedAlias(alias),
        )) {
          alias = 'New account ${suffix++}';
        }
      }
      await coordinator.removeProfile(profileId);
      final afterCleanup = await refresh();
      if (afterCleanup.any((p) => p.id == profileId && _reservesSlot(p)))
        throw const SessionFailure('cleanup_pending');
      final replacement = await _mutate(
        () => engine.allocateProfile(
          _validateAlias(alias, existingProfiles: afterCleanup),
          previous.color,
        ),
      );
      await refresh();
      if (replacement.id == previous.id ||
          replacement.platformProfileId == previous.platformProfileId) {
        throw const SessionFailure('invalid_replacement_identity');
      }
      await coordinator.select(replacement.id);
      return replacement;
    } finally {
      _replacements.remove(profileId);
    }
  }

  Future<void> removeAll() async {
    final ids = (await refresh()).map((p) => p.id).toList();
    Object? firstError;
    StackTrace? firstTrace;
    for (final id in ids) {
      try {
        await coordinator.removeProfile(id);
      } catch (error, trace) {
        firstError ??= error;
        firstTrace ??= trace;
      }
    }
    await refresh();
    if (firstError != null) Error.throwWithStackTrace(firstError, firstTrace!);
  }

  Future<void> retryCleanup() async {
    await _mutate(engine.retryPendingCleanup);
    await refresh();
  }

  Future<void> dispose() async {
    _closed = true;
    await _subscription.cancel();
    await _changes.close();
  }

  Future<List<AccountProfile>> importSetup(
    AccountSetupArchive archive, {
    bool applyAppearance = false,
  }) async {
    final encoded = archive.encode();
    try {
      final imported = await _mutate(() async {
        final result = await engine.importAccountSetupArchive(
          encoded,
          applyAppearance,
        );
        // The native future remains alive after a route leaves or a facade
        // deadline expires. Re-read preferences here, not from that route.
        if (!_closed && applyAppearance && onSetupCommitted != null) {
          try {
            await onSetupCommitted!();
          } catch (_, trace) {
            if (!_closed)
              _changes.addError(
                const SessionFailure('preferences_refresh_required'),
                trace,
              );
          }
        }
        return result;
      });
      await refresh();
      return List.unmodifiable(imported.map(_copy));
    } catch (_) {
      // Publish actual recovery state without replaying an uncertain mutation.
      try {
        await refresh();
      } catch (_) {
        /* Preserve the original error. */
      }
      rethrow;
    }
  }
}
