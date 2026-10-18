import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:session_contract/session_contract.dart';

import 'support/fake_engine.dart';

Future<void> drain() => Future<void>.delayed(Duration.zero);

void main() {
  test('native overlay requests one authentication and cancellation remains locked', () async {
    final engine = FakeSessionEngine()..seed('A');
    final coordinator = SessionCoordinator(engine);
    await coordinator.select('A');
    engine.ready(engine.active!);
    await drain();
    await coordinator.lock();
    engine.authenticated = false;
    final gate = engine.authenticationGate = Completer<void>();
    for (var tap = 0; tap < 3; tap++) {
      engine.emit(EngineEvent(kind: EngineEventKind.unlockRequested));
    }
    await drain();
    expect(engine.calls.where((call) => call == 'authenticate').length, 1);
    expect(coordinator.state.locked, isTrue);
    engine.authenticationGate = null;
    gate.complete();
    await drain();
    expect(coordinator.state.locked, isTrue);
    expect(coordinator.state.covered, isTrue);

    engine.authenticated = true;
    engine.emit(EngineEvent(kind: EngineEventKind.unlockRequested));
    await drain();
    expect(engine.calls.where((call) => call == 'authenticate').length, 2);
    expect(coordinator.state.locked, isFalse);
    expect(coordinator.state.covered, isFalse);
    engine.emit(EngineEvent(kind: EngineEventKind.unlockRequested));
    await drain();
    expect(engine.calls.where((call) => call == 'authenticate').length, 2);
    await coordinator.dispose();
    await engine.close();
  });
}
