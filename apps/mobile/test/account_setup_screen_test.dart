import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_registry/local_registry.dart';
import 'package:profile_desk/app/design.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/features/backup/account_setup_screen.dart';
import 'package:profile_desk/l10n/app_localizations.dart';
import 'package:session_contract/session_contract.dart';

import '../../../packages/session_contract/test/support/fake_engine.dart';

String setupFile(String alias) => AccountSetupArchive(
  accounts: [AccountSetupEntry(alias: alias, color: 0xff21675e)],
  theme: 'dark',
).encode();

Future<ProviderContainer> mount(
  WidgetTester tester,
  FakeSessionEngine engine, {
  double textScale = 1,
}) async {
  final container = ProviderContainer(
    overrides: [engineProvider.overrideWithValue(engine)],
  );
  addTearDown(container.dispose);
  await container.read(appProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: deskTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const AccountSetupScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('appearance reconciles after the import route is removed', (
    tester,
  ) async {
    final engine = FakeSessionEngine()
      ..setupArchiveToPick = setupFile('Work')
      ..setupImportGate = Completer<void>();
    final container = await mount(tester, engine);
    await tester.ensureVisible(find.text('Choose setup file'));
    await tester.tap(find.text('Choose setup file'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Import accounts'));
    await tester.tap(find.text('Import accounts'));
    await tester.pump();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Text('Another route')),
      ),
    );
    engine.setupImportGate!.complete();
    await tester.pumpAndSettle();
    expect(container.read(appProvider).requireValue.preferences.theme, 'dark');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'discloses relinking and readable export; picker cancel changes nothing',
    (tester) async {
      final engine = FakeSessionEngine();
      await mount(tester, engine);
      expect(
        find.textContaining('Each imported account must be linked again.'),
        findsOneWidget,
      );
      expect(find.textContaining('It is not encrypted.'), findsOneWidget);
      await tester.ensureVisible(find.text('Choose setup file'));
      await tester.tap(find.text('Choose setup file'));
      await tester.pumpAndSettle();
      expect(engine.records, isEmpty);
      expect(engine.calls, isNot(contains('import_setup')));
    },
  );

  testWidgets('preview requires unique names then imports fresh profiles', (
    tester,
  ) async {
    final engine = FakeSessionEngine()
      ..seed('old', alias: 'Work')
      ..setupArchiveToPick = setupFile('Work');
    await mount(tester, engine);
    await tester.ensureVisible(find.text('Choose setup file'));
    await tester.tap(find.text('Choose setup file'));
    await tester.pumpAndSettle();
    expect(find.text('Review accounts to import'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Import accounts'),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), 'Team');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Import accounts'));
    await tester.tap(find.text('Import accounts'));
    await tester.pumpAndSettle();
    expect(
      engine.records.values.map((p) => p.alias),
      containsAll(['Work', 'Team']),
    );
    expect(engine.records.values.last.observation, AuthObservation.unknown);
    expect(engine.active, isNull);
    expect(engine.preferences.theme, 'system');
    expect(find.textContaining('Added 1 accounts.'), findsOneWidget);
  });

  testWidgets('capacity and invalid file cannot commit', (tester) async {
    final engine = FakeSessionEngine()..setupArchiveToPick = setupFile('Extra');
    for (var i = 0; i < 10; i++) {
      engine.seed('old-$i');
    }
    await mount(tester, engine);
    await tester.ensureVisible(find.text('Choose setup file'));
    await tester.tap(find.text('Choose setup file'));
    await tester.pumpAndSettle();
    expect(find.textContaining('There is not enough room'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Import accounts'),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    engine.setupArchiveToPick = jsonEncode({'cookies': 'sensitive-invalid'});
    await tester.ensureVisible(find.text('Choose setup file'));
    await tester.tap(find.text('Choose setup file'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not a supported Profile Desk'), findsOneWidget);
    expect(find.textContaining('sensitive-invalid'), findsNothing);
    expect(engine.records, hasLength(10));
  });

  testWidgets('narrow large-text import preview stays scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = FakeSessionEngine()..setupArchiveToPick = setupFile('Work');
    await mount(tester, engine, textScale: 2);
    await tester.ensureVisible(find.text('Choose setup file'));
    await tester.tap(find.text('Choose setup file'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Import accounts'));
    await tester.pumpAndSettle();
    expect(find.text('Import accounts').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
