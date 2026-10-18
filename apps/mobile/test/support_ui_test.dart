import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_desk/app/design.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/features/help/help_screen.dart';
import 'package:profile_desk/features/privacy/lock_gate.dart';
import 'package:profile_desk/features/privacy/privacy_screen.dart';
import 'package:profile_desk/l10n/app_localizations.dart';
import 'package:profile_desk/main.dart';
import 'package:session_contract/session_contract.dart';

import '../../../packages/session_contract/test/support/fake_engine.dart';

void main() {
  testWidgets('tablet workspace footer opens a reachable account selector', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = FakeSessionEngine()..seed('personal', alias: 'Personal');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [engineProvider.overrideWithValue(engine)],
        child: const ProfileDeskApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Switch account'));
    await tester.tap(find.text('Switch account'));
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    final profile = find.descendant(
      of: dialog,
      matching: find.text('Personal'),
    );
    expect(profile.hitTestable(), findsOneWidget);
    final add = find.widgetWithText(FilledButton, 'Add account');
    expect(tester.getRect(add).bottom, lessThanOrEqualTo(768));
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('Add an account'), findsOneWidget);
    expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets(
    'lock hides route semantics and blocks touches on the first frame',
    (tester) async {
      final states = StreamController<SessionState>(sync: true);
      addTearDown(states.close);
      final semantics = tester.ensureSemantics();
      var privateActionCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionProvider.overrideWith((ref) => states.stream)],
          child: MaterialApp(
            theme: deskTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppLockGate(
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: TextButton(
                    onPressed: () => privateActionCount++,
                    child: const Text('Private account route'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Private account route'), findsOneWidget);
      final privateButtonPosition = tester.getCenter(
        find.text('Private account route'),
      );

      states.add(const SessionState(locked: true));
      await tester.idle();
      // No settling or animation duration: content is protected immediately.
      await tester.pump();
      expect(find.text('Your accounts are locked'), findsOneWidget);
      expect(
        tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!
            .toStringDeep(),
        isNot(contains('Private account route')),
      );
      final surface = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Your accounts are locked'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(surface.color?.a, 1);
      await tester.tapAt(privateButtonPosition);
      expect(privateActionCount, 0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  for (final showHelp in [false, true]) {
    testWidgets(
      '${showHelp ? 'help steps' : 'privacy preferences'} fit a narrow screen at double text size',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final engine = FakeSessionEngine();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [engineProvider.overrideWithValue(engine)],
            child: const ProfileDeskApp(),
          ),
        );
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(Scaffold).first)).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                showHelp ? const HelpScreen() : const PrivacyScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final screenScroll = find
            .descendant(
              of: find.byType(showHelp ? HelpScreen : PrivacyScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        if (showHelp) {
          expect(find.text('Add and name a profile here.'), findsOneWidget);
          expect(
            find.text('Scan the QR displayed inside this profile.'),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.text('Open-source licenses'),
            400,
            maxScrolls: 60,
            scrollable: screenScroll,
          );
          expect(tester.takeException(), isNull);
        } else {
          await tester.scrollUntilVisible(
            find.text('Dark'),
            300,
            scrollable: screenScroll,
          );
          await tester.tap(find.text('Dark'));
          await tester.pumpAndSettle();
          expect(engine.preferences.theme, 'dark');
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text('Review and share safe diagnostics'),
            400,
            maxScrolls: 50,
            scrollable: screenScroll,
          );
          expect(tester.takeException(), isNull);
        }
        expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
}
