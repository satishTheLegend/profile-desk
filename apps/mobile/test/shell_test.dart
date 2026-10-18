import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_desk/main.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/features/accounts/account_screens.dart';

import '../../../packages/session_contract/test/support/fake_engine.dart';

void main() {
  Future<void> launch(WidgetTester tester, FakeSessionEngine engine) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [engineProvider.overrideWithValue(engine)],
        child: const ProfileDeskApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('first launch explains separate primary device before setup', (
    tester,
  ) async {
    final engine = FakeSessionEngine();
    engine.preferences.welcomeSeen = false;
    await launch(tester, engine);
    expect(find.text('Your accounts,\nkept separate.'), findsOneWidget);
    expect(
      find.textContaining('A separate device is normally needed'),
      findsOneWidget,
    );
    expect(engine.calls.where((c) => c.startsWith('open')), isEmpty);
    await tester.scrollUntilVisible(find.text('Set up your workspace'), 200);
    await tester.tap(find.text('Set up your workspace'));
    await tester.pumpAndSettle();
    expect(find.text('Link your first account'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  testWidgets('lock conceals account access and exposes explicit unlock', (
    tester,
  ) async {
    final engine = FakeSessionEngine()..locked = true;
    engine.seed('one', alias: 'Private alias');
    await launch(tester, engine);
    expect(find.text('Your accounts are locked'), findsOneWidget);
    expect(find.text('Private alias'), findsNothing);
    expect(find.text('Unlock'), findsOneWidget);
    expect(find.text('Link your first account'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  testWidgets('small screen and large text welcome remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final engine = FakeSessionEngine();
    engine.preferences.welcomeSeen = false;
    await launch(tester, engine);
    await tester.scrollUntilVisible(find.text('Set up your workspace'), 200);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  testWidgets('account manager rejects eleventh slot in visible controls', (
    tester,
  ) async {
    final engine = FakeSessionEngine();
    for (var i = 0; i < 10; i++) {
      engine.seed('$i', alias: 'Account $i');
    }
    await launch(tester, engine);
    final context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AccountManagerScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('10 of 10 accounts'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Add account'), 300);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add account'),
    );
    expect(button.onPressed, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  for (final remove in [false, true]) {
    testWidgets(
      'partial setup ${remove ? 'removes only that profile' : 'keeps its reserved slot'}',
      (tester) async {
        final engine = FakeSessionEngine();
        engine.seed('setup', alias: 'Unfinished');
        engine.seed('other', alias: 'Other');
        await launch(tester, engine);
        final context = tester.element(find.byType(Scaffold).first);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ProfileSettingsScreen(profileId: 'setup'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pause account setup'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(remove ? 'Remove local setup' : 'Keep for later'),
        );
        await tester.pumpAndSettle();
        expect(engine.records.containsKey('setup'), !remove);
        expect(engine.records.containsKey('other'), isTrue);
        expect(engine.calls.where((c) => c.startsWith('open:')), isEmpty);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
  testWidgets('tablet landscape dark shell has labeled reachable controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = FakeSessionEngine();
    engine.preferences.theme = 'dark';
    engine.seed('one', alias: 'Full accessible label with a long name');
    await launch(tester, engine);
    final semantics = tester.ensureSemantics();
    await tester.tap(find.text('Your accounts'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Full accessible label with a long name'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
