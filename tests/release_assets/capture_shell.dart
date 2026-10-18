// Render actual shell widgets with explicitly fictional data. No native engine,
// website, account, QR code or conversation is opened by this asset builder.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/features/accounts/account_screens.dart';
import 'package:profile_desk/features/privacy/privacy_screen.dart';
import 'package:profile_desk/features/help/help_screen.dart';
import 'package:profile_desk/features/backup/account_setup_screen.dart';
import 'package:local_registry/local_registry.dart';
import 'package:lottie/lottie.dart';
import 'package:profile_desk/main.dart';

import '../../packages/session_contract/test/support/fake_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fontDirectory = String.fromEnvironment('PREVIEW_FONT_DIR');
  const bodyFontDirectory = String.fromEnvironment('PREVIEW_BODY_FONT_DIR');
  const outputDirectory = String.fromEnvironment('PREVIEW_OUTPUT_DIR');
  setUpAll(() async {
    if (fontDirectory.isEmpty || outputDirectory.isEmpty) {
      throw StateError('Provide PREVIEW_FONT_DIR and PREVIEW_OUTPUT_DIR.');
    }
    final fonts = FontLoader('Roboto');
    final bodyFonts = bodyFontDirectory.isEmpty
        ? [
            for (final weight in ['Regular', 'Medium', 'Bold'])
              '$fontDirectory/Roboto-$weight.ttf',
          ]
        : ['$bodyFontDirectory/Arial.ttf', '$bodyFontDirectory/Arial Bold.ttf'];
    for (final path in bodyFonts) {
      fonts.addFont(File(path).readAsBytes().then(ByteData.sublistView));
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File('$fontDirectory/MaterialIcons-Regular.otf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    await icons.load();
    await (FontLoader(
      'Manrope',
    )..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'))).load();
    for (final scene in ['accounts', 'opening', 'privacy']) {
      await AssetLottie('assets/animations/$scene.json').load();
    }
    await Directory(outputDirectory).create(recursive: true);
  });

  for (final name in [
    'welcome',
    'accounts',
    'selector',
    'privacy',
    'lock',
    'workspace',
    'help',
    'details',
    'accounts-dark',
    'accounts-tablet',
    'welcome-narrow',
    'privacy-large-text',
    'lock-reduced',
    'workspace-landscape',
    'selector-large-text',
    'backup',
    'backup-preview',
  ]) {
    final screen = name.split('-').first;
    testWidgets('render fictional $name shell preview', (tester) async {
      tester.view.physicalSize = switch (name) {
        'accounts-tablet' => const Size(1024, 768),
        'welcome-narrow' ||
        'privacy-large-text' ||
        'selector-large-text' => const Size(320, 568),
        'workspace-landscape' => const Size(932, 430),
        _ => const Size(430, 932),
      };
      tester.platformDispatcher.textScaleFactorTestValue =
          name.endsWith('-large-text') ? 2 : 1;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: name == 'lock-reduced');
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = FakeSessionEngine();
      if (screen == 'backup') {
        engine.setupArchiveToPick = AccountSetupArchive(
          accounts: const [
            AccountSetupEntry(alias: 'Projects', color: 0xff21675e),
            AccountSetupEntry(alias: 'Family', color: 0xff805395),
          ],
        ).encode();
      }
      engine.preferences.welcomeSeen = screen != 'welcome';
      engine.preferences.theme = name.endsWith('-dark') ? 'dark' : 'light';
      engine.locked = screen == 'lock';
      if (screen != 'welcome') {
        engine.seed('fictional-personal', alias: 'Personal')
          ..color = 0xff21675e;
        engine.seed('fictional-studio', alias: 'Studio')..color = 0xff3557a2;
        engine.seed('fictional-community', alias: 'Community')
          ..color = 0xff805395;
      }
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                const ColoredBox(
                  color: Color(0xff172d29),
                  child: SizedBox(
                    height: 30,
                    child: Center(
                      child: Text(
                        'SHELL PREVIEW · FICTIONAL PROFILES',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 11,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ProviderScope(
                    overrides: [engineProvider.overrideWithValue(engine)],
                    child: const ProfileDeskApp(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final destination = switch (screen) {
        'accounts' => const AccountManagerScreen(),
        'privacy' => const PrivacyScreen(),
        'help' => const HelpScreen(),
        'backup' => const AccountSetupScreen(),
        'details' => const ProfileSettingsScreen(
          profileId: 'fictional-personal',
        ),
        _ => null,
      };
      if (destination != null) {
        final context = tester.element(find.byType(Scaffold).first);
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => destination));
        await tester.pumpAndSettle();
      } else if (screen == 'selector') {
        await tester.tap(find.text('Your accounts'));
        await tester.pumpAndSettle();
      }
      if (name == 'backup-preview') {
        await tester.ensureVisible(find.text('Choose setup file'));
        await tester.tap(find.text('Choose setup file'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(engine.calls.where((call) => call.startsWith('open:')), isEmpty);
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File('$outputDirectory/$name.png')
            .writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  }
}
