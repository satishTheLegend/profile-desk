import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_registry/local_registry.dart';
import 'package:session_contract/session_contract.dart';

import '../../session_contract/test/support/fake_engine.dart';

Map<String, Object?> validDocument({int count = 1}) => {
  'format': AccountSetupArchive.format,
  'version': 1,
  'requiresRelinking': true,
  'accounts': [
    for (var i = 0; i < count; i++)
      {'alias': 'Account $i', 'color': 0xffffffff},
  ],
  'appearance': {'theme': 'dark'},
};

void main() {
  test('zero through ten entries roundtrip with only portable fields', () {
    for (final count in [0, 1, 10]) {
      final parsed = AccountSetupArchive.decode(
        jsonEncode(validDocument(count: count)),
      );
      expect(parsed.accounts, hasLength(count));
      expect(jsonDecode(parsed.encode()), validDocument(count: count));
    }
  });

  test(
    'rejects unsupported, extra, secret and trust fields at every level',
    () {
      final invalid = <Map<String, Object?>>[
        {...validDocument(), 'version': 2},
        {...validDocument(), 'version': 1.0},
        {...validDocument(), 'requiresRelinking': false},
        {...validDocument(), 'cookies': []},
        {
          ...validDocument(),
          'appearance': {'theme': 'dark', 'lockEnabled': false},
        },
        {
          ...validDocument(),
          'accounts': [
            {'alias': 'Work', 'color': 0, 'platformProfileId': 'old-store'},
          ],
        },
        {
          ...validDocument(),
          'accounts': [
            {'alias': 'Work', 'color': 0, 'observation': 'userConfirmed'},
          ],
        },
      ];
      for (final item in invalid) {
        expect(
          () => AccountSetupArchive.decode(jsonEncode(item)),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'rejects unbounded, malformed, duplicate, control and invalid typed data',
    () {
      final invalid = [
        '',
        '[]',
        '{',
        ' ' * (AccountSetupArchive.maxBytes + 1),
        jsonEncode(validDocument(count: 11)),
        jsonEncode({
          ...validDocument(),
          'appearance': {'theme': 'purple'},
        }),
        for (final color in [-1, 0x100000000, 1.2, true, '42'])
          jsonEncode({
            ...validDocument(),
            'accounts': [
              {'alias': 'Work', 'color': color},
            ],
          }),
        for (final alias in ['', '  ', 'a' * 41, 'Work\u0000', 'Work\u0081'])
          jsonEncode({
            ...validDocument(),
            'accounts': [
              {'alias': alias, 'color': 0},
            ],
          }),
        jsonEncode({
          ...validDocument(),
          'accounts': [
            {'alias': ' Work ', 'color': 0},
            {'alias': 'WORK', 'color': 1},
          ],
        }),
      ];
      for (final item in invalid) {
        expect(() => AccountSetupArchive.decode(item), throwsFormatException);
      }
    },
  );

  test('unicode scalar length counts emoji correctly and trims names', () {
    final parsed = AccountSetupArchive.decode(
      jsonEncode({
        ...validDocument(),
        'accounts': [
          {'alias': ' ${'😀' * 40} ', 'color': 0},
        ],
      }),
    );
    expect(parsed.accounts.single.alias.runes.length, 40);
  });

  test(
    'rejects repeated or escaped duplicate keys and deeply nested input',
    () {
      final source = jsonEncode(validDocument());
      for (final prefix in ['"version":2,', '"ver\\u0073ion":2,']) {
        expect(
          () => AccountSetupArchive.decode('{$prefix${source.substring(1)}'),
          throwsFormatException,
        );
      }
      expect(
        () => AccountSetupArchive.decode('${'[' * 20000}0${']' * 20000}'),
        throwsFormatException,
      );
      final unusual = AccountSetupArchive(
        accounts: const [
          AccountSetupEntry(alias: 'A "quoted" {name}', color: 1),
        ],
      );
      expect(
        AccountSetupArchive.decode(unusual.encode()).accounts.single.alias,
        unusual.accounts.single.alias,
      );
    },
  );

  test('service imports fresh unknown profiles, preserving existing records and lock', () async {
    final engine = FakeSessionEngine()..seed('existing', alias: 'Personal');
    engine.preferences.lockEnabled = true;
    final coordinator = SessionCoordinator(engine);
    final service = AccountService(engine, coordinator);
    addTearDown(service.dispose);
    addTearDown(coordinator.dispose);
    addTearDown(engine.close);
    final imported = await service.importSetup(
      AccountSetupArchive.decode(jsonEncode(validDocument(count: 2))),
    );
    expect(imported, hasLength(2));
    expect(
      imported.every((p) => p.observation == AuthObservation.unknown),
      isTrue,
    );
    expect(engine.records['existing']!.alias, 'Personal');
    expect(engine.preferences.lockEnabled, isTrue);
    expect(engine.preferences.theme, 'system');
    expect(engine.active, isNull);
  });

  test('timed out import is reconciled once, never replayed', () async {
    final engine = FakeSessionEngine()..setupImportGate = Completer<void>();
    final coordinator = SessionCoordinator(engine);
    var preferencesReconciled = 0;
    final service = AccountService(
      engine,
      coordinator,
      operationTimeout: const Duration(milliseconds: 5),
      onSetupCommitted: () async {
        preferencesReconciled++;
      },
    );
    addTearDown(service.dispose);
    addTearDown(coordinator.dispose);
    addTearDown(engine.close);
    final archive = AccountSetupArchive.decode(jsonEncode(validDocument()));
    await expectLater(
      service.importSetup(archive, applyAppearance: true),
      throwsA(isA<SessionFailure>()),
    );
    expect(service.requiresReconciliation, isTrue);
    await expectLater(
      service.importSetup(archive),
      throwsA(isA<SessionFailure>()),
    );
    engine.setupImportGate!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(engine.calls.where((c) => c == 'import_setup'), hasLength(1));
    expect(service.requiresReconciliation, isFalse);
    expect(service.profiles, hasLength(1));
    expect(preferencesReconciled, 1);
    expect(engine.preferences.theme, 'dark');
  });
}
