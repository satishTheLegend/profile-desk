import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/features/accounts/account_screens.dart';
import 'package:profile_desk/main.dart';
import 'package:session_contract/session_contract.dart';

import '../../../packages/session_contract/test/support/fake_engine.dart';

void main() {
  Future<void> openManager(
    WidgetTester tester,
    FakeSessionEngine engine,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [engineProvider.overrideWithValue(engine)],
        child: const ProfileDeskApp(),
      ),
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(builder: (_) => const AccountManagerScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'account tiles adapt to width and large text without truncating actions',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final engine = FakeSessionEngine()
        ..seed('one', alias: 'Personal workspace')
        ..seed('two', alias: 'Studio workspace');
      await openManager(tester, engine);
      final firstWide = tester.getTopLeft(find.text('Personal workspace'));
      final secondWide = tester.getTopLeft(find.text('Studio workspace'));
      expect(firstWide.dy, secondWide.dy);
      expect(secondWide.dx, greaterThan(firstWide.dx));

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
      final firstNarrow = tester.getTopLeft(find.text('Personal workspace'));
      final secondNarrow = tester.getTopLeft(find.text('Studio workspace'));
      expect(secondNarrow.dx, firstNarrow.dx);
      expect(secondNarrow.dy, greaterThan(firstNarrow.dy));
      await tester.scrollUntilVisible(find.text('Add account'), 240);
      expect(tester.takeException(), isNull);
      expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'tiles keep unavailable access disabled and details distinct from opening',
    (tester) async {
      final engine = FakeSessionEngine()
        ..seed('one', alias: 'Unavailable', state: StoreState.missing)
        ..seed('two', alias: 'Personal');
      await openManager(tester, engine);
      final openButtons = tester
          .widgetList<TextButton>(find.widgetWithText(TextButton, 'Open'))
          .toList();
      expect(openButtons, hasLength(2));
      expect(openButtons.first.onPressed, isNull);
      expect(openButtons.last.onPressed, isNotNull);
      await tester.tap(find.text('Unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('Account details'), findsOneWidget);
      expect(find.text('Replace unavailable profile'), findsOneWidget);
      expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'tile reordering preserves account identities and labeled touch targets',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = FakeSessionEngine()
        ..seed('one', alias: 'Personal')
        ..seed('two', alias: 'Studio');
      await openManager(tester, engine);
      final semantics = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
      await tester.tap(find.byTooltip('Move Personal down'));
      await tester.pumpAndSettle();
      expect(engine.records['one']!.orderIndex, 1);
      expect(engine.records['two']!.orderIndex, 0);
      expect(engine.calls, contains('reorder'));
      expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'account form stays usable above the keyboard with large text and keeps validation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final engine = FakeSessionEngine()..seed('one', alias: 'Personal');
      await openManager(tester, engine);
      await tester.scrollUntilVisible(find.text('Add account'), 240);
      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 216);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Personal');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create and link account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create and link account'));
      await tester.pumpAndSettle();
      expect(find.text('That name is already in use.'), findsOneWidget);
      expect(engine.calls, isNot(contains('allocate')));
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
