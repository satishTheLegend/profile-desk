import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/main.dart';
import 'package:session_contract/session_contract.dart';

import '../../../packages/session_contract/test/support/fake_engine.dart';

void main() {
  testWidgets('workspace tiles open only the chosen available profile', (
    tester,
  ) async {
    final engine = FakeSessionEngine()
      ..readyBeforeOpenReturns = true
      ..seed('personal', alias: 'Personal')
      ..seed('unavailable', alias: 'Unavailable', state: StoreState.missing);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [engineProvider.overrideWithValue(engine)],
        child: const ProfileDeskApp(),
      ),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
    expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
    await tester.tap(find.text('Unavailable'));
    await tester.pumpAndSettle();
    expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();
    expect(engine.calls.where((call) => call.startsWith('open:')), [
      'open:personal',
    ]);
    expect(find.text('Choose your workspace'), findsNothing);
    expect(
      find.text('Link with your primary phone, then check the account shown.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('workspace tiles and selector fit narrow screens at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final engine = FakeSessionEngine();
    for (var index = 0; index < 10; index++) {
      engine.seed('$index', alias: 'Workspace number $index');
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [engineProvider.overrideWithValue(engine)],
        child: const ProfileDeskApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Workspace number 9'), 260);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Your accounts'));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    final lastProfile = find.descendant(
      of: sheet,
      matching: find.text('Workspace number 9'),
    );
    await tester.scrollUntilVisible(
      lastProfile,
      240,
      scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    expect(lastProfile.hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Add account'),
      240,
      scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();
    final add = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add account'),
    );
    expect(add.onPressed, isNull);
    expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
