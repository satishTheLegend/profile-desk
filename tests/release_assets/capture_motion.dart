// Deterministic preview of the actual local Lottie compositions used by
// DeskScene. This helper never opens the app engine, a service, or account data.
// Run from apps/mobile with PREVIEW_FONT_DIR and MOTION_OUTPUT_DIR dart defines.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fontDirectory = String.fromEnvironment('PREVIEW_FONT_DIR');
  const outputDirectory = String.fromEnvironment('MOTION_OUTPUT_DIR');
  const framesPerSecond = 15;
  const frameCount = 30;
  const size = Size(1080, 480);
  const labels = {
    'accounts': 'Separate profiles',
    'opening': 'Opening a workspace',
    'privacy': 'Privacy',
  };
  final compositions = <String, LottieComposition>{};

  setUpAll(() async {
    if (fontDirectory.isEmpty || outputDirectory.isEmpty) {
      throw StateError('Provide PREVIEW_FONT_DIR and MOTION_OUTPUT_DIR.');
    }
    final font = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      font.addFont(
        File('$fontDirectory/Roboto-$weight.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await font.load();
    for (final name in labels.keys) {
      compositions[name] = await AssetLottie('assets/animations/$name.json')
          .load();
    }
    await Directory('$outputDirectory/frames').create(recursive: true);
  });

  testWidgets('capture two seconds of original local Lottie motion', (
    tester,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    final elapsedSeconds = ValueNotifier<double>(0);
    addTearDown(elapsedSeconds.dispose);

    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xff184e48),
              fontSize: 18,
            ),
            child: ColoredBox(
              color: const Color(0xfff8f8f3),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Text(
                    'Profile Desk · Motion preview',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Original local artwork · Synthetic preview · No account data',
                    style: TextStyle(fontSize: 16, color: Color(0xff60766d)),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<double>(
                    valueListenable: elapsedSeconds,
                    builder: (context, elapsed, child) => Row(
                      children: [
                        for (final item in compositions.entries)
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox.square(
                                  dimension: 300,
                                  child: Lottie(
                                    composition: item.value,
                                    controller: AlwaysStoppedAnimation(
                                      (elapsed /
                                              (item
                                                      .value
                                                      .duration
                                                      .inMicroseconds /
                                                  Duration
                                                      .microsecondsPerSecond))
                                          .clamp(0.0, 1.0),
                                    ),
                                    repeat: false,
                                    frameRate: FrameRate.composition,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Text(
                                  labels[item.key]!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Plays once, then rests. Reduced motion shows the finished artwork.',
                    style: TextStyle(fontSize: 15, color: Color(0xff60766d)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (var frame = 0; frame < frameCount; frame++) {
      elapsedSeconds.value = frame / framesPerSecond;
      await tester.pump();
      expect(tester.takeException(), isNull);
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final index = frame.toString().padLeft(3, '0');
          await File('$outputDirectory/frames/frame-$index.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    }

    await tester.runAsync(() async {
      await File('$outputDirectory/capture.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert({
          'kind': 'deterministic_flutter_lottie_preview',
          'source': 'tests/release_assets/capture_motion.dart',
          'width': size.width.toInt(),
          'height': size.height.toInt(),
          'frames_per_second': framesPerSecond,
          'frame_count': frameCount,
          'encoded_duration_seconds': frameCount / framesPerSecond,
          'last_frame_time_seconds': (frameCount - 1) / framesPerSecond,
          'compositions': {
            for (final item in compositions.entries) item.key: {'asset': 'apps/mobile/assets/animations/${item.key}.json', 'duration_ms': item.value.duration.inMilliseconds},
          },
          'account_data': false,
          'native_engine_opened': false,
        })}\n',
      );
    });
    expect(tester.binding.hasScheduledFrame, isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
