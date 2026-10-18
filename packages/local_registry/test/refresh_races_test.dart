import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_registry/local_registry.dart';
import 'package:session_contract/session_contract.dart';

import '../../session_contract/test/support/fake_engine.dart';

void main() {
  test('add publishes its completed read while a later event read is pending', () async {
    final engine = FakeSessionEngine();
    final coordinator = SessionCoordinator(engine);
    final accounts = AccountService(engine, coordinator);
    final allocationEventRead = Completer<List<AccountProfile>>();
    final mutationRead = Completer<List<AccountProfile>>();
    final laterEventRead = Completer<List<AccountProfile>>();
    final mutationReadStarted = Completer<void>();
    final laterEventReadStarted = Completer<void>();
    var calls = 0;
    engine.profilesResponse = () {
      switch (calls++) {
        case 0:
          return allocationEventRead.future;
        case 1:
          mutationReadStarted.complete();
          return mutationRead.future;
        case 2:
          laterEventReadStarted.complete();
          return laterEventRead.future;
        default:
          throw StateError('Unexpected registry read');
      }
    };
    try {
      final addition = accounts.add('Synthetic account', 1);
      await mutationReadStarted.future;
      engine.emit(EngineEvent(kind: EngineEventKind.profilesChanged));
      await laterEventReadStarted.future;

      mutationRead.complete(engine.records.values.toList());
      final created = await addition;
      // Match the real native integration assertion, with the later refresh
      // deliberately unresolved. Mutation completion must expose its snapshot.
      expect(accounts.profiles.single.id, created.id);
      expect(accounts.usedSlots, 1);
      expect(laterEventRead.isCompleted, isFalse);
    } finally {
      allocationEventRead.complete([]);
      laterEventRead.complete(engine.records.values.toList());
      await accounts.dispose();
      await coordinator.dispose();
      await engine.close();
    }
  });

  test(
    'a failed newer read does not suppress an earlier successful snapshot',
    () async {
      final engine = FakeSessionEngine();
      final profile = engine.seed('A');
      final coordinator = SessionCoordinator(engine);
      final accounts = AccountService(engine, coordinator);
      final older = Completer<List<AccountProfile>>();
      final newer = Completer<List<AccountProfile>>();
      var calls = 0;
      engine.profilesResponse = () =>
          calls++ == 0 ? older.future : newer.future;
      final firstRead = accounts.refresh();
      final secondRead = accounts.refresh();
      final failedRead = expectLater(
        secondRead,
        throwsA(
          isA<SessionFailure>().having((e) => e.code, 'code', 'read_failed'),
        ),
      );
      newer.completeError(const SessionFailure('read_failed'));
      await failedRead;
      older.complete([profile]);
      expect((await firstRead).single.id, 'A');
      expect(accounts.profiles.single.id, 'A');
      await accounts.dispose();
      await coordinator.dispose();
      await engine.close();
    },
  );

  test('late registry reads do not replace newer cache or return unrelated cached data', () async {
    final engine = FakeSessionEngine();
    final a = engine.seed('A');
    final b = engine.seed('B');
    final coordinator = SessionCoordinator(engine);
    final accounts = AccountService(engine, coordinator);
    final older = Completer<List<AccountProfile>>();
    final newer = Completer<List<AccountProfile>>();
    var calls = 0;
    engine.profilesResponse = () => calls++ == 0 ? older.future : newer.future;
    final firstRead = accounts.refresh();
    final secondRead = accounts.refresh();
    newer.complete([b]);
    expect((await secondRead).single.id, 'B');
    older.complete([a]);
    expect((await firstRead).single.id, 'A');
    expect(accounts.profiles.single.id, 'B');
    await accounts.dispose();
    await coordinator.dispose();
    await engine.close();
  });
}
