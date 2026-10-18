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

  test('unavailable replacement gets new identity and preserves alias only by choice', () async {
    final old = engine.seed('old', alias: 'Office', state: StoreState.missing);
    final replacement = await accounts.replaceUnavailable(
      'old',
      keepAlias: true,
    );
    expect(replacement.alias, 'Office');
    expect(replacement.id, isNot(old.id));
    expect(replacement.platformProfileId, isNot(old.platformProfileId));
    expect(engine.active!.profileId, replacement.id);
    expect(
      engine.calls.indexOf('remove:old'),
      lessThan(engine.calls.indexOf('allocate')),
    );
  });

  test(
    'available profiles cannot be destructively replaced through recovery',
    () async {
      engine.seed('valid');
      await expectLater(
        accounts.replaceUnavailable('valid', keepAlias: true),
        throwsA(failure('replacement_not_eligible')),
      );
      expect(engine.calls, isEmpty);
    },
  );

  test('failed or pending wipe cannot allocate a replacement', () async {
    engine.seed('old', state: StoreState.quarantined);
    engine.cleanupAvailable = false;
    await expectLater(
      accounts.replaceUnavailable('old', keepAlias: true),
      throwsA(failure('cleanup_pending')),
    );
    expect(engine.calls, isNot(contains('allocate')));
    expect(accounts.profiles.single.state, StoreState.cleanupPending);
    expect(accounts.usedSlots, 1);
  });

  test('post-wipe deferred container permits a fresh replacement', () async {
    engine.seed('old', alias: 'Office', state: StoreState.missing);
    engine.deferContainerDeletion = true;
    final replacement = await accounts.replaceUnavailable(
      'old',
      keepAlias: false,
      newAlias: 'New office',
    );
    expect(replacement.alias, 'New office');
    expect(accounts.profiles.length, 2);
    expect(accounts.usedSlots, 1);
    expect(engine.records['old']!.cleanupStage, 'containerDeletionPending');
  });

  test('tombstone alias remains reserved until actual wipe', () async {
    final old = engine.seed('old', alias: 'Office', state: StoreState.removing)
      ..cleanupStage = 'websiteWipePending';
    await accounts.refresh();
    await expectLater(
      accounts.add('office', 0),
      throwsA(failure('alias_duplicate')),
    );
    old.state = StoreState.cleanupPending;
    old.cleanupStage = 'containerDeletionPending';
    await accounts.refresh();
    final created = await accounts.add('office', 0);
    expect(created.id, isNot('old'));
  });
}
