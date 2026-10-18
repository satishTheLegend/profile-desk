import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_desk/app/design.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/features/workspace/workspace_layout_controls.dart';
import 'package:profile_desk/l10n/app_localizations.dart';
import 'package:session_contract/session_contract.dart';

import '../../../packages/session_contract/test/support/fake_engine.dart';

ViewHandle _view([int generation = 1]) => ViewHandle(
  profileId: 'work',
  viewInstanceId: 'view-$generation',
  operationId: 'op-$generation',
  selectionGeneration: generation,
);

class _CommandEngine extends FakeSessionEngine {
  Completer<void>? listGate;
  @override
  Future<void> showWorkspaceList(ViewHandle view) async {
    await super.showWorkspaceList(view);
    await listGate?.future;
  }
}

Widget _app(
  FakeSessionEngine engine,
  ViewHandle view, {
  bool show = true,
  GlobalKey<NavigatorState>? navigator,
}) => ProviderScope(
  overrides: [engineProvider.overrideWithValue(engine)],
  child: MaterialApp(
    navigatorKey: navigator,
    theme: deskTheme(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      bottomNavigationBar: show ? WorkspaceLayoutControls(view: view) : null,
    ),
  ),
);

void main() {
  testWidgets(
    'layout controls query only after explicit commands for exact owner',
    (tester) async {
      final engine = FakeSessionEngine()
        ..presentation = WorkspacePresentation.original;
      final view = _view();
      await tester.pumpWidget(_app(engine, view));
      await tester.pumpAndSettle();
      expect(engine.calls, isEmpty);
      await tester.tap(find.text('Original layout'));
      await tester.pumpAndSettle();
      expect(engine.calls, ['layout:work:original', 'presentation:work']);
      expect(find.text('Original layout selected.'), findsOneWidget);
      final queried = engine.presentationCalls.single;
      expect(
        [
          queried.profileId,
          queried.viewInstanceId,
          queried.operationId,
          queried.selectionGeneration,
        ],
        ['work', 'view-1', 'op-1', 1],
      );
      engine.presentation = WorkspacePresentation.list;
      await tester.tap(find.text('Chats & menu'));
      await tester.pumpAndSettle();
      expect(engine.calls.skip(2), ['show_list:work', 'presentation:work']);
      expect(find.text('Chat list opened.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 9));
      expect(find.text('Chat list opened.'), findsNothing);
      expect(engine.presentationCalls, hasLength(2));
      expect(engine.calls.any((call) => call.startsWith('open:')), isFalse);
    },
  );

  for (final presentation in [
    WorkspacePresentation.menu,
    WorkspacePresentation.detail,
    WorkspacePresentation.unavailable,
  ]) {
    testWidgets(
      '$presentation feedback does not claim that chats were opened',
      (tester) async {
        final engine = FakeSessionEngine()..presentation = presentation;
        await tester.pumpWidget(_app(engine, _view()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chats & menu'));
        await tester.pumpAndSettle();
        expect(find.text('Chat list opened.'), findsNothing);
        final message = switch (presentation) {
          WorkspacePresentation.menu =>
            'Use Back inside the open WhatsApp panel to return to chats.',
          WorkspacePresentation.detail => 'This conversation is still open. Try Original layout to reach its controls.',
          _ => 'Phone layout is unavailable for this page. Use Original layout to continue.',
        };
        expect(find.text(message), findsOneWidget);
        if (presentation != WorkspacePresentation.menu) {
          engine.presentation = WorkspacePresentation.original;
          await tester.tap(find.text('Use Original layout'));
          await tester.pumpAndSettle();
          expect(engine.calls, contains('layout:work:original'));
          expect(find.text('Original layout selected.'), findsOneWidget);
        }
      },
    );
  }

  testWidgets(
    'duplicate taps are single-flight and late state cannot affect a new view',
    (tester) async {
      final pending = Completer<WorkspacePresentation>();
      final engine = FakeSessionEngine()..presentationReply = pending.future;
      await tester.pumpWidget(_app(engine, _view()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chats & menu'));
      await tester.tap(find.text('Chats & menu'));
      await tester.pump();
      expect(
        engine.calls.where((call) => call == 'show_list:work'),
        hasLength(1),
      );
      await tester.pumpWidget(_app(engine, _view(2)));
      pending.complete(WorkspacePresentation.menu);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Use Back inside the open WhatsApp panel to return to chats.',
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Original layout'),
            )
            .onPressed,
        isNotNull,
      );
      engine.presentationReply = null;
      engine.presentation = WorkspacePresentation.original;
      await tester.tap(find.text('Original layout'));
      await tester.pumpAndSettle();
      expect(engine.presentationCalls.last.selectionGeneration, 2);
    },
  );

  testWidgets('disposed controls do not query after a delayed command', (
    tester,
  ) async {
    final engine = _CommandEngine()..listGate = Completer<void>();
    await tester.pumpWidget(_app(engine, _view()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chats & menu'));
    await tester.pump();
    await tester.pumpWidget(_app(engine, _view(), show: false));
    engine.listGate!.complete();
    await tester.pumpAndSettle();
    expect(engine.presentationCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bounded query failure offers reachable original-layout recovery',
    (tester) async {
      final pending = Completer<WorkspacePresentation>();
      final engine = FakeSessionEngine()..presentationReply = pending.future;
      await tester.pumpWidget(_app(engine, _view()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chats & menu'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(
        find.text('The page layout could not be checked. Try Original layout.'),
        findsOneWidget,
      );
      engine.presentationReply = null;
      engine.presentation = WorkspacePresentation.original;
      await tester.tap(find.text('Use Original layout'));
      await tester.pumpAndSettle();
      pending.complete(WorkspacePresentation.menu);
      await tester.pumpAndSettle();
      expect(find.text('Original layout selected.'), findsOneWidget);
      expect(
        find.text(
          'Use Back inside the open WhatsApp panel to return to chats.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'a hidden route drops pending feedback and remains usable on return',
    (tester) async {
      final pending = Completer<WorkspacePresentation>();
      final navigator = GlobalKey<NavigatorState>();
      final engine = FakeSessionEngine()..presentationReply = pending.future;
      await tester.pumpWidget(_app(engine, _view(), navigator: navigator));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chats & menu'));
      await tester.pump();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other route')),
        ),
      );
      await tester.pumpAndSettle();
      pending.complete(WorkspacePresentation.menu);
      await tester.pumpAndSettle();
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Use Back inside the open WhatsApp panel to return to chats.',
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Original layout'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('push/pop round trip cannot restore stale layout feedback', (
    tester,
  ) async {
    final pending = Completer<WorkspacePresentation>();
    final engine = FakeSessionEngine()..presentationReply = pending.future;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(engine, _view(), navigator: navigator));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chats & menu'));
    await tester.pump();
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Temporary route')),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    pending.complete(WorkspacePresentation.menu);
    await tester.pumpAndSettle();
    expect(
      find.text('Use Back inside the open WhatsApp panel to return to chats.'),
      findsNothing,
    );
    engine.presentationReply = null;
    engine.presentation = WorkspacePresentation.original;
    await tester.tap(find.text('Original layout'));
    await tester.pumpAndSettle();
    expect(find.text('Original layout selected.'), findsOneWidget);
    expect(engine.presentationCalls, hasLength(2));
  });

  testWidgets('narrow large-text feedback and controls stay reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final engine = FakeSessionEngine()
      ..presentation = WorkspacePresentation.unavailable;
    await tester.pumpWidget(_app(engine, _view()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chats & menu'));
    await tester.pumpAndSettle();
    expect(find.text('Chats & menu').hitTestable(), findsOneWidget);
    expect(find.text('Original layout').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    engine.presentation = WorkspacePresentation.original;
    await tester.tap(find.text('Original layout'));
    await tester.pumpAndSettle();
    expect(find.text('Original layout selected.'), findsOneWidget);
  });
}
