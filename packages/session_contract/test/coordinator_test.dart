import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:session_contract/session_contract.dart';

import 'support/fake_engine.dart';

Future<void> drain() => Future<void>.delayed(Duration.zero);
Matcher failure(String code) =>
    isA<SessionFailure>().having((e) => e.code, 'code', code);

void main() {
  late FakeSessionEngine engine;
  late SessionCoordinator coordinator;

  setUp(() {
    engine = FakeSessionEngine()
      ..seed('A')
      ..seed('B')
      ..seed('C');
    coordinator = SessionCoordinator(engine);
  });
  tearDown(() async {
    engine.coverGate?.complete();
    engine.coverGate = null;
    engine.disposeError = null;
    await coordinator.dispose();
    await engine.close();
  });

  test('native cover completes before the selected label changes', () async {
    await coordinator.select('A');
    engine.ready(engine.active!);
    await drain();
    expect(coordinator.state.phase, WorkspacePhase.visible);
    final gate = engine.coverGate = Completer<void>();
    final switchFuture = coordinator.select('B');
    await drain();
    expect(coordinator.state.selectedProfileId, 'A');
    expect(engine.active?.profileId, 'A');
    engine.coverGate = null;
    gate.complete();
    await switchFuture;
    expect(coordinator.state.selectedProfileId, 'B');
    expect(coordinator.state.covered, isTrue);
    expect(
      engine.calls.indexOf('dispose:A'),
      lessThan(engine.calls.indexOf('open:B')),
    );
  });

  test(
    'switch waits for outgoing disposal and preserves persistent profile',
    () async {
      await coordinator.select('A');
      final gate = engine.pendingDisposals['A'] = Completer<void>();
      final switching = coordinator.select('B');
      await drain();
      expect(engine.calls, isNot(contains('open:B')));
      expect(engine.records['A']?.state, StoreState.available);
      gate.complete();
      await switching;
      expect(engine.active?.profileId, 'B');
      expect(engine.records['A']?.platformProfileId, 'store-A');
    },
  );

  test(
    'newer selection disposes a late obsolete open before opening target',
    () async {
      final gate = engine.pendingOpens['A'] = Completer<void>();
      final older = coordinator.select('A');
      await drain();
      final newer = coordinator.select('B');
      gate.complete();
      await Future.wait([older, newer]);
      expect(engine.active?.profileId, 'B');
      expect(engine.calls.where((v) => v == 'dispose:A').length, 1);
      expect(
        engine.calls.indexOf('dispose:A'),
        lessThan(engine.calls.indexOf('open:B')),
      );
    },
  );

  test(
    'same profile reopened has new identity and rejects stale events',
    () async {
      await coordinator.select('A');
      final stale = engine.active!;
      await coordinator.select('B');
      await coordinator.select('A');
      engine.ready(stale);
      await drain();
      expect(coordinator.state.covered, isTrue);
      expect(coordinator.state.phase, WorkspacePhase.loading);
      engine.ready(engine.active!);
      await drain();
      expect(coordinator.state.phase, WorkspacePhase.visible);
    },
  );

  test(
    'mutating a public wire handle cannot change coordinator owner',
    () async {
      await coordinator.select('A');
      final view = coordinator.state.view!..profileId = 'B';
      engine.ready(view);
      await drain();
      expect(coordinator.state.view!.profileId, 'A');
      expect(coordinator.state.covered, isTrue);
    },
  );

  test('all four view ownership fields are required for reveal', () async {
    await coordinator.select('A');
    final original = engine.active!;
    for (var field = 0; field < 4; field++) {
      final stale = ViewHandle(
        profileId: field == 0 ? 'B' : original.profileId,
        viewInstanceId: field == 1 ? 'wrong' : original.viewInstanceId,
        operationId: field == 2 ? 'wrong' : original.operationId,
        selectionGeneration: field == 3
            ? original.selectionGeneration + 1
            : original.selectionGeneration,
      );
      engine.ready(stale);
    }
    await drain();
    expect(engine.calls, isNot(contains('cover:false')));
    expect(coordinator.state.covered, isTrue);
  });

  test(
    'ready under lock cannot reveal and canceled authentication stays covered',
    () async {
      await coordinator.select('A');
      await coordinator.lock();
      engine.ready(engine.active!);
      await drain();
      expect(coordinator.state.covered, isTrue);
      engine.authenticated = false;
      expect(await coordinator.unlock(), isFalse);
      expect(coordinator.state.locked, isTrue);
      expect(engine.calls, isNot(contains('cover:false')));
      engine.authenticated = true;
      expect(await coordinator.unlock(), isTrue);
      expect(coordinator.state.phase, WorkspacePhase.visible);
    },
  );

  test(
    'active transfer requires explicit cancel and rejects stale transfer state',
    () async {
      await coordinator.select('A');
      final original = engine.active!;
      engine.emit(
        EngineEvent(
          kind: EngineEventKind.transferChanged,
          view: original,
          transferActive: true,
        ),
      );
      await expectLater(
        coordinator.select('B'),
        throwsA(failure('transfer_active')),
      );
      await coordinator.select('B', cancelActiveTransfer: true);
      expect(
        engine.calls.indexOf('cancel_transfer'),
        lessThan(engine.calls.indexOf('dispose:A')),
      );
      engine.emit(
        EngineEvent(
          kind: EngineEventKind.transferChanged,
          view: original,
          transferActive: true,
        ),
      );
      expect(coordinator.state.transferActive, isFalse);
    },
  );

  test(
    'inactive cleanup completion remains independent of active selection',
    () async {
      final cleanup = <EngineEvent>[];
      final subscription = coordinator.cleanupEvents.listen(cleanup.add);
      await coordinator.select('A');
      final removalGate = engine.pendingRemovals['B'] = Completer<void>();
      final removal = coordinator.removeProfile('B');
      await drain();
      await coordinator.select('C');
      expect(engine.records['B']?.state, StoreState.removing);
      expect(cleanup, isEmpty);
      removalGate.complete();
      await removal;
      expect(cleanup.last.profileId, 'B');
      expect(coordinator.state.selectedProfileId, 'C');
      expect(engine.active?.profileId, 'C');
      await subscription.cancel();
    },
  );

  test(
    'requested removal blocks reopen immediately, including failed cleanup',
    () async {
      engine.removalError = const SessionFailure('wipe_failed');
      await expectLater(
        coordinator.removeProfile('B'),
        throwsA(failure('wipe_failed')),
      );
      await expectLater(
        coordinator.select('B'),
        throwsA(failure('profile_unavailable')),
      );
      await coordinator.select('A');
      expect(engine.active?.profileId, 'A');
      expect(engine.records['B']?.state, StoreState.removing);
    },
  );

  test('disposal failure never opens a second view', () async {
    await coordinator.select('A');
    engine.disposeError = const SessionFailure('dispose_failed');
    await expectLater(
      coordinator.select('B'),
      throwsA(failure('dispose_failed')),
    );
    expect(engine.calls, isNot(contains('open:B')));
    expect(coordinator.state.covered, isTrue);
    expect(coordinator.state.phase, WorkspacePhase.failed);
  });

  test(
    'timeout blocks new mutations until the late view is disposed',
    () async {
      await coordinator.dispose();
      coordinator = SessionCoordinator(
        engine,
        operationTimeout: const Duration(milliseconds: 15),
      );
      final gate = engine.pendingOpens['A'] = Completer<void>();
      await expectLater(
        coordinator.select('A'),
        throwsA(failure('operation_timeout')),
      );
      expect(coordinator.state.requiresReconciliation, isTrue);
      await expectLater(
        coordinator.select('B'),
        throwsA(failure('reconciliation_required')),
      );
      expect(engine.calls, isNot(contains('open:B')));
      gate.complete();
      await drain();
      expect(engine.active, isNull);
      expect(coordinator.state.requiresReconciliation, isFalse);
      await coordinator.select('B');
      expect(engine.active?.profileId, 'B');
    },
  );

  test(
    'navigation readiness does not change authentication observation',
    () async {
      await coordinator.select('A');
      engine.ready(engine.active!);
      await drain();
      expect(engine.records['A']!.observation, AuthObservation.unknown);
    },
  );

  test(
    'viewReady arriving before the open reply is processed after ownership',
    () async {
      engine.readyBeforeOpenReturns = true;
      await coordinator.select('A');
      await drain();
      expect(coordinator.state.phase, WorkspacePhase.visible);
      expect(coordinator.state.view!.profileId, 'A');
    },
  );

  test(
    'foreground unlock notification re-reveals only a ready current view',
    () async {
      await coordinator.select('A');
      engine.emit(
        EngineEvent(kind: EngineEventKind.privacyChanged, locked: false),
      );
      await drain();
      expect(coordinator.state.covered, isTrue);
      engine.ready(engine.active!);
      await drain();
      engine.covered = true;
      engine.emit(
        EngineEvent(kind: EngineEventKind.privacyChanged, locked: false),
      );
      await drain();
      expect(coordinator.state.covered, isFalse);
      expect(engine.covered, isFalse);
    },
  );

  test('reload rebuilds same store with new ownership and never replays operations', () async {
    await coordinator.select('A');
    final stale = engine.active!;
    await coordinator.reload();
    expect(engine.records['A']!.platformProfileId, 'store-A');
    expect(engine.active!.viewInstanceId, isNot(stale.viewInstanceId));
    expect(engine.active!.operationId, isNot(stale.operationId));
    engine.ready(stale);
    await drain();
    expect(coordinator.state.covered, isTrue);
    expect(engine.calls.where((call) => call.startsWith('remove:')), isEmpty);
  });

  test(
    'startup blocks tombstones but allows allocation reconciled by native',
    () async {
      engine.records['A']!.state = StoreState.allocating;
      engine.records['B']!.state = StoreState.cleanupPending;
      await coordinator.initialize();
      await expectLater(
        coordinator.select('A'),
        throwsA(failure('profile_unavailable')),
      );
      engine.records['A']!.state = StoreState.available;
      await coordinator.select('A');
      expect(engine.active?.profileId, 'A');
      engine.records['B']!.state = StoreState.available;
      await expectLater(
        coordinator.select('B'),
        throwsA(failure('profile_unavailable')),
      );
    },
  );
}
