import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:session_contract/session_contract.dart';

import 'support/fake_engine.dart';

Future<void> drain() => Future<void>.delayed(Duration.zero);

void main() {
  test('200 seeded switches retain one live owner despite delayed disposal and stale callbacks', () async {
    final random = Random(0x51A7E);
    final engine = FakeSessionEngine();
    for (var index = 0; index < 10; index++) engine.seed('profile-$index');
    final coordinator = SessionCoordinator(engine);
    final history = <ViewHandle>[];
    final violations = <String>[];
    final subscription = coordinator.states.listen((state) {
      if (!state.covered) {
        if (state.locked ||
            state.phase != WorkspacePhase.visible ||
            state.view == null ||
            state.view!.profileId != state.selectedProfileId ||
            engine.active?.viewInstanceId != state.view!.viewInstanceId) {
          violations.add(
            'Revealed state has no matching unlocked native owner.',
          );
        }
      }
    });
    for (var index = 0; index < 200; index++) {
      final target = 'profile-${random.nextInt(10)}';
      final previous = engine.active;
      final disposalGate = previous != null && random.nextBool()
          ? Completer<void>()
          : null;
      if (disposalGate != null)
        engine.pendingDisposals[previous!.profileId] = disposalGate;
      final switching = coordinator.select(target);
      await drain();
      if (disposalGate != null) {
        expect(
          engine.active?.viewInstanceId,
          previous!.viewInstanceId,
          reason: 'switch $index must await disposal',
        );
        expect(coordinator.state.covered, isTrue);
        engine.pendingDisposals.remove(previous.profileId);
        disposalGate.complete();
      }
      await switching;
      final current = engine.active!;
      expect(current.profileId, target);
      expect(coordinator.state.selectedProfileId, target);
      expect(coordinator.state.covered, isTrue);
      if (history.isNotEmpty) {
        final stale = history[random.nextInt(history.length)];
        engine.ready(stale);
        engine.emit(
          EngineEvent(
            kind: EngineEventKind.viewFailed,
            view: stale,
            errorCode: 'obsolete_failure',
          ),
        );
        engine.emit(
          EngineEvent(
            kind: EngineEventKind.transferChanged,
            view: stale,
            transferActive: true,
          ),
        );
        await drain();
        expect(coordinator.state.covered, isTrue);
        expect(coordinator.state.transferActive, isFalse);
        expect(coordinator.state.phase, WorkspacePhase.loading);
      }
      if (random.nextInt(5) == 0) {
        await coordinator.lock();
        engine.ready(current);
        await drain();
        expect(coordinator.state.covered, isTrue);
        expect(await coordinator.unlock(), isTrue);
      } else {
        engine.ready(current);
        await drain();
      }
      expect(coordinator.state.phase, WorkspacePhase.visible);
      expect(coordinator.state.view!.viewInstanceId, current.viewInstanceId);
      expect(engine.records.length, 10);
      history.add(current);
    }
    expect(history.map((view) => view.viewInstanceId).toSet().length, 200);
    expect(history.map((view) => view.operationId).toSet().length, 200);
    expect(engine.calls.where((call) => call.startsWith('open:')).length, 200);
    expect(
      engine.calls.where((call) => call.startsWith('dispose:')).length,
      199,
    );
    expect(violations, isEmpty);
    await subscription.cancel();
    await coordinator.dispose();
    await engine.close();
  });
}
