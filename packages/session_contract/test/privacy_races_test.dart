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
    engine = FakeSessionEngine()..seed('A');
    coordinator = SessionCoordinator(engine);
  });
  tearDown(() async {
    await coordinator.dispose();
    await engine.close();
  });

  test(
    'native lock failure remains covered and cannot unlock the Dart shell',
    () async {
      await coordinator.select('A');
      engine.ready(engine.active!);
      await drain();
      engine.lockError = const SessionFailure('lock_failed');
      await expectLater(coordinator.lock(), throwsA(failure('lock_failed')));
      expect(coordinator.state.locked, isTrue);
      expect(coordinator.state.covered, isTrue);
      expect(engine.covered, isTrue);
      engine.emit(
        EngineEvent(kind: EngineEventKind.privacyChanged, locked: false),
      );
      await drain();
      expect(coordinator.state.locked, isTrue);
    },
  );

  test('late authentication cannot cancel a newer manual lock', () async {
    await coordinator.select('A');
    engine.ready(engine.active!);
    await drain();
    await coordinator.lock();
    final gate = engine.authenticationGate = Completer<void>();
    final unlock = coordinator.unlock();
    await drain();
    await coordinator.lock();
    engine.authenticationGate = null;
    gate.complete();
    expect(await unlock, isFalse);
    expect(coordinator.state.locked, isTrue);
    expect(engine.locked, isTrue);
    expect(engine.covered, isTrue);
  });

  test(
    'timed out reveal is covered again when native completion arrives late',
    () async {
      await coordinator.dispose();
      coordinator = SessionCoordinator(
        engine,
        operationTimeout: const Duration(milliseconds: 15),
      );
      await coordinator.select('A');
      final gate = engine.revealGate = Completer<void>();
      engine.ready(engine.active!);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(coordinator.state.requiresReconciliation, isTrue);
      engine.revealGate = null;
      gate.complete();
      await drain();
      expect(engine.covered, isTrue);
      expect(coordinator.state.covered, isTrue);
      expect(coordinator.state.requiresReconciliation, isFalse);
    },
  );

  test('timed out authentication is relocked after a late success', () async {
    await coordinator.dispose();
    coordinator = SessionCoordinator(
      engine,
      operationTimeout: const Duration(milliseconds: 15),
    );
    await coordinator.select('A');
    await coordinator.lock();
    final gate = engine.authenticationGate = Completer<void>();
    await expectLater(
      coordinator.unlock(),
      throwsA(failure('operation_timeout')),
    );
    engine.authenticationGate = null;
    gate.complete();
    await drain();
    expect(coordinator.state.locked, isTrue);
    expect(engine.locked, isTrue);
    expect(engine.covered, isTrue);
    expect(coordinator.state.requiresReconciliation, isFalse);
  });
}
