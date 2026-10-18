import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:profile_desk/app/design.dart';
import 'package:profile_desk/app/motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Warm the same local cache used by the production widget. No network or
    // device service is involved in this motion suite.
    for (final kind in DeskSceneKind.values) {
      await AssetLottie('assets/animations/${kind.name}.json').load();
    }
  });

  Widget shell(
    Widget child, {
    bool reduced = false,
    bool accessible = false,
    bool ticker = true,
  }) => MaterialApp(
    theme: deskTheme(Brightness.light),
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        accessibleNavigation: accessible,
      ),
      child: TickerMode(
        enabled: ticker,
        child: Scaffold(body: child),
      ),
    ),
  );

  AnimationController sceneController(WidgetTester tester) =>
      tester.widget<LottieBuilder>(find.byType(LottieBuilder)).controller!
          as AnimationController;

  test(
    'authored assets parse without warnings and contain no remote media',
    () async {
      for (final kind in DeskSceneKind.values) {
        final bytes = await rootBundle.load(
          'assets/animations/${kind.name}.json',
        );
        final document = jsonDecode(
          utf8.decode(bytes.buffer.asUint8List()),
        ) as Map<String, dynamic>;
        final composition = await LottieComposition.fromByteData(bytes);
        expect(composition.warnings, isEmpty, reason: kind.name);
        expect(
          composition.duration.inMilliseconds,
          inInclusiveRange(1000, 1800),
        );
        expect(document['fr'], 30);
        expect(document['assets'], isEmpty);
        expect(document['layers'], isNotEmpty);
        expect(document.containsKey('fonts'), isFalse);
        expect(jsonEncode(document), isNot(contains('https://')));
      }
    },
  );

  testWidgets('scene finishes once and stops scheduling frames', (
    tester,
  ) async {
    await tester.pumpWidget(
      shell(const DeskScene(kind: DeskSceneKind.accounts)),
    );
    await tester.pump();
    final controller = sceneController(tester);
    expect(controller.isAnimating, isTrue);
    await tester.pumpAndSettle();
    expect(controller.value, 1);
    expect(controller.isAnimating, isFalse);
    await tester.pump(const Duration(seconds: 5));
    expect(controller.value, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final accessible in [false, true]) {
    testWidgets(
      '${accessible ? 'accessible navigation' : 'reduced motion'} shows completed artwork immediately',
      (tester) async {
        await tester.pumpWidget(
          shell(
            const DeskScene(kind: DeskSceneKind.privacy),
            reduced: !accessible,
            accessible: accessible,
          ),
        );
        await tester.pump();
        final controller = sceneController(tester);
        expect(controller.value, 1);
        expect(controller.isAnimating, isFalse);
        await tester.pumpAndSettle();
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );
  }

  testWidgets(
    'scene pauses while app is inactive and resumes remaining motion',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        shell(const DeskScene(kind: DeskSceneKind.opening)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      final controller = sceneController(tester);
      final pausedAt = controller.value;
      expect(pausedAt, greaterThan(0));
      expect(pausedAt, lessThan(1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.isAnimating, isFalse);
      expect(controller.value, pausedAt);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(controller.value, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hidden scene pauses and changing reduced motion completes it', (
    tester,
  ) async {
    const scene = DeskScene(kind: DeskSceneKind.accounts);
    await tester.pumpWidget(shell(scene));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final controller = sceneController(tester);
    await tester.pumpWidget(shell(scene, ticker: false));
    final pausedAt = controller.value;
    await tester.pump(const Duration(seconds: 2));
    expect(controller.value, pausedAt);
    expect(controller.isAnimating, isFalse);
    await tester.pumpWidget(shell(scene, ticker: false, reduced: true));
    expect(controller.value, 1);
    expect(controller.isAnimating, isFalse);
  });

  testWidgets('pointer feedback preserves button taps and resets on cancel', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      shell(
        Center(
          child: DeskTapFeedback(
            child: FilledButton(
              onPressed: () => taps++,
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    final button = find.text('Open');
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(taps, 1);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pumpAndSettle();
    final feedbackTransform = find
        .descendant(
          of: find.byType(DeskTapFeedback),
          matching: find.byType(Transform),
        )
        .first;
    expect(
      tester.widget<Transform>(feedbackTransform).transform.entry(0, 0),
      lessThan(1),
    );
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(
      tester.widget<Transform>(feedbackTransform).transform.entry(0, 0),
      1,
    );
    expect(taps, 1);
  });

  testWidgets(
    'reduced motion keeps entrance, icon selection, and press feedback static',
    (tester) async {
      Widget content(bool active) => Column(
        children: [
          DeskEntrance(order: 100, child: const Text('Always readable')),
          DeskAnimatedIcon('apps', active: active),
          DeskTapFeedback(
            child: FilledButton(onPressed: () {}, child: const Text('Open')),
          ),
        ],
      );
      await tester.pumpWidget(shell(content(false), reduced: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(shell(content(true), reduced: true));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Open')),
      );
      await tester.pump();
      final entranceOpacity = find.descendant(
        of: find.byType(DeskEntrance),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(entranceOpacity).opacity, 1);
      final transform = find
          .descendant(
            of: find.byType(DeskTapFeedback),
            matching: find.byType(Transform),
          )
          .first;
      expect(tester.widget<Transform>(transform).transform.entry(0, 0), 1);
      final iconTransforms = find.descendant(
        of: find.byType(DeskAnimatedIcon),
        matching: find.byType(Transform),
      );
      for (final match in iconTransforms.evaluate()) {
        expect(
          (match.widget as Transform).transform.entry(0, 0),
          closeTo(1, .000001),
        );
      }
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('every final illustration paints visible local vector artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      shell(
        RepaintBoundary(
          key: boundaryKey,
          child: ColoredBox(
            color: Colors.white,
            child: Row(
              children: [
                for (final kind in DeskSceneKind.values)
                  DeskScene(kind: kind, size: 360),
              ],
            ),
          ),
        ),
        reduced: true,
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = data!.buffer.asUint8List();
      for (var scene = 0; scene < 3; scene++) {
        var paintedPixels = 0;
        for (var y = 0; y < 360; y++) {
          for (var x = scene * 360; x < (scene + 1) * 360; x++) {
            final index = (y * 1080 + x) * 4;
            if (pixels[index] < 245 ||
                pixels[index + 1] < 245 ||
                pixels[index + 2] < 245) {
              paintedPixels++;
            }
          }
        }
        expect(
          paintedPixels,
          greaterThan(12000),
          reason: DeskSceneKind.values[scene].name,
        );
      }
      // Opt-in visual QA artifact; normal test runs do not write files.
      const previewPath = String.fromEnvironment('MOTION_PREVIEW_PATH');
      if (previewPath.isNotEmpty) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(previewPath).writeAsBytes(png!.buffer.asUint8List());
      }
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
