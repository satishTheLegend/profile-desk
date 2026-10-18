import 'package:flutter_test/flutter_test.dart';
import 'package:local_registry/local_registry.dart';
import 'package:session_contract/session_contract.dart';

import '../../session_contract/test/support/fake_engine.dart';

Matcher failure(String code) =>
    isA<SessionFailure>().having((e) => e.code, 'code', code);

void main() {
  late FakeSessionEngine engine;
  late SessionCoordinator coordinator;
  late AccountService accounts;

  setUp(() {
    engine = FakeSessionEngine();
    coordinator = SessionCoordinator(engine);
    accounts = AccountService(engine, coordinator);
  });
  tearDown(() async {
    await accounts.dispose();
    await coordinator.dispose();
    await engine.close();
  });

  test(
    'validates aliases and leaves authoritative writes to native registry',
    () async {
      await expectLater(accounts.add('  ', 0), throwsA(failure('alias_empty')));
      await expectLater(
        accounts.add('a' * 41, 0),
        throwsA(failure('alias_too_long')),
      );
      await expectLater(
        accounts.add('bad\nlabel', 0),
        throwsA(failure('alias_invalid')),
      );
      await expectLater(
        accounts.add('bad\u0085label', 0),
        throwsA(failure('alias_invalid')),
      );
      expect(engine.calls, isEmpty);
      final created = await accounts.add('  Office  ', 3);
      expect(created.alias, 'Office');
      await expectLater(
        accounts.add('office', 4),
        throwsA(failure('alias_duplicate')),
      );
      expect(accounts.usedSlots, 1);
    },
  );

  test('simultaneous adds all reach native capacity authority with no phantom rows', () async {
    final results = await Future.wait(
      List.generate(11, (i) async {
        try {
          await accounts.add('Synthetic $i', i);
          return true;
        } on SessionFailure catch (error) {
          expect(error.code, 'capacity_reached');
          return false;
        }
      }),
    );
    await accounts.refresh();
    expect(results.where((success) => success).length, 10);
    expect(engine.calls.where((call) => call == 'allocate').length, 11);
    expect(accounts.profiles.length, 10);
    expect(accounts.usedSlots, 10);
  });

  test('native allocation failure never adds a Dart-only account', () async {
    engine.allocationError = const SessionFailure('disk_full');
    await expectLater(accounts.add('Office', 0), throwsA(failure('disk_full')));
    expect(accounts.profiles, isEmpty);
    expect(accounts.usedSlots, 0);
  });

  test(
    'rename reorder and caller mutations preserve immutable backing identities',
    () async {
      final a = await accounts.add('A', 1);
      final b = await accounts.add('B', 2);
      final backing = a.platformProfileId;
      await accounts.rename(a.id, 'Renamed A', 3);
      await accounts.reorder([b.id, a.id]);
      expect(accounts.profiles.map((p) => p.id), [b.id, a.id]);
      expect(accounts.profiles.last.platformProfileId, backing);
      accounts.profiles.first.platformProfileId = 'tampered';
      expect(accounts.profiles.first.platformProfileId, b.platformProfileId);
      await expectLater(
        accounts.reorder([a.id, a.id]),
        throwsA(failure('invalid_order')),
      );
    },
  );

  test(
    'capacity is retained until actual wipe leaves only deferred container',
    () async {
      engine.seed('A');
      final pending = engine.seed('B', state: StoreState.removing)
        ..cleanupStage = 'websiteWipePending';
      await accounts.refresh();
      expect(accounts.usedSlots, 2);
      pending.state = StoreState.cleanupPending;
      await accounts.refresh();
      expect(accounts.usedSlots, 2);
      pending.cleanupStage = 'containerDeletionPending';
      await accounts.refresh();
      expect(accounts.usedSlots, 1);
    },
  );

  test(
    'capability loss keeps cleanup pending and later retry changes only target',
    () async {
      engine.seed('A');
      engine.seed('B');
      engine.cleanupAvailable = false;
      await accounts.refresh();
      await coordinator.select('A');
      await accounts.remove('B');
      expect(
        accounts.profiles.singleWhere((p) => p.id == 'B').cleanupStage,
        'websiteWipePending',
      );
      expect(accounts.usedSlots, 2);
      final cleanupId = engine.records['B']!.cleanupOperationId;
      engine.cleanupAvailable = true;
      await accounts.retryCleanup();
      expect(accounts.profiles.map((p) => p.id), ['A']);
      expect(engine.active!.profileId, 'A');
      expect(cleanupId, isNotEmpty);
    },
  );

  test(
    'removeAll continues independent cleanup and reports partial failure',
    () async {
      for (final id in ['A', 'B', 'C']) engine.seed(id);
      engine.removalFailures.add('B');
      await expectLater(accounts.removeAll(), throwsA(failure('wipe_failed')));
      expect(engine.calls, containsAll(['remove:A', 'remove:B', 'remove:C']));
      expect(accounts.profiles.map((p) => p.id), ['B']);
      expect(accounts.profiles.single.state, StoreState.removing);
    },
  );

  test(
    'confirmation is explicit and relink never replaces or wipes the store',
    () async {
      final created = await accounts.add('A', 1);
      await coordinator.select(created.id);
      engine.ready(engine.active!);
      await Future<void>.delayed(Duration.zero);
      expect(accounts.profiles.single.observation, AuthObservation.unknown);
      await accounts.confirmAccount(created.id);
      expect(
        accounts.profiles.single.observation,
        AuthObservation.userConfirmed,
      );
      await accounts.requestRelink(created.id);
      expect(
        accounts.profiles.single.observation,
        AuthObservation.relinkRequested,
      );
      expect(
        accounts.profiles.single.platformProfileId,
        created.platformProfileId,
      );
      expect(engine.calls.where((call) => call.startsWith('remove:')), isEmpty);
    },
  );
}
