import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_registry/local_registry.dart';
import 'package:session_contract/session_contract.dart';

import '../../session_contract/test/support/fake_engine.dart';

Matcher failure(String code) =>
    isA<SessionFailure>().having((e) => e.code, 'code', code);

void main() {
  test('timed-out allocation is reconciled from its real late result without replay', () async {
    final engine = FakeSessionEngine();
    final coordinator = SessionCoordinator(engine);
    final accounts = AccountService(
      engine,
      coordinator,
      operationTimeout: const Duration(milliseconds: 15),
    );
    final gate = engine.allocationGate = Completer<void>();
    await expectLater(
      accounts.add('Late account', 1),
      throwsA(failure('registry_operation_timeout')),
    );
    expect(accounts.requiresReconciliation, isTrue);
    await expectLater(
      accounts.add('Another account', 2),
      throwsA(failure('registry_reconciliation_required')),
    );
    expect(engine.calls.where((call) => call == 'allocate').length, 1);
    engine.allocationGate = null;
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(accounts.requiresReconciliation, isFalse);
    expect(accounts.profiles.single.alias, 'Late account');
    expect(engine.active, isNull);
    await accounts.add('Another account', 2);
    expect(accounts.usedSlots, 2);
    await accounts.dispose();
    await coordinator.dispose();
    await engine.close();
  });

  test(
    'read deadline does not overwrite known metadata or replay reads',
    () async {
      final engine = FakeSessionEngine()..seed('A');
      final coordinator = SessionCoordinator(engine);
      final accounts = AccountService(
        engine,
        coordinator,
        operationTimeout: const Duration(milliseconds: 15),
      );
      await accounts.refresh();
      final delayed = Completer<List<AccountProfile>>();
      engine.profilesResponse = () => delayed.future;
      await expectLater(
        accounts.refresh(),
        throwsA(failure('registry_read_timeout')),
      );
      expect(accounts.profiles.single.id, 'A');
      delayed.complete([]);
      await Future<void>.delayed(Duration.zero);
      expect(accounts.profiles.single.id, 'A');
      await accounts.dispose();
      await coordinator.dispose();
      await engine.close();
    },
  );
}
