import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_desk/app/design.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/features/workspace/workspace_back_handler.dart';
import 'package:profile_desk/features/workspace/workspace_screen.dart';
import 'package:profile_desk/l10n/app_localizations.dart';
import 'package:session_contract/session_contract.dart';

import '../../../packages/session_contract/test/support/fake_engine.dart';

ViewHandle _view([int generation = 1]) => ViewHandle(
  profileId: 'work',
  viewInstanceId: 'view-$generation',
  operationId: 'op-$generation',
  selectionGeneration: generation,
);

Widget _app(
  FakeSessionEngine engine, {
  ViewHandle? view,
  TargetPlatform platform = TargetPlatform.android,
  GlobalKey<NavigatorState>? navigator,
  Widget? child,
}) => ProviderScope(
  overrides: [engineProvider.overrideWithValue(engine)],
  child: MaterialApp(
    navigatorKey: navigator,
    theme: deskTheme(Brightness.light).copyWith(platform: platform),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: WorkspaceBackHandler(
      view: view,
      child: child ?? const Scaffold(body: Text('Workspace')),
    ),
  ),
);

class _MountedChild extends StatefulWidget {
  const _MountedChild({required this.onMount, required this.onDispose});
  final VoidCallback onMount, onDispose;
  @override
  State<_MountedChild> createState() => _MountedChildState();
}

class _MountedChildState extends State<_MountedChild> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Stable native host'));
}

void main() {
  final systemCalls = <String>[];
  final inputCalls = <String>[];
  setUp(() {
    systemCalls.clear();
    inputCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          systemCalls.add(call.method);
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, (call) async {
          inputCalls.add(call.method);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, null);
  });

  testWidgets('Android Back returns a detail pane to its exact owned list', (
    tester,
  ) async {
    final engine = FakeSessionEngine()
      ..presentation = WorkspacePresentation.detail;
    await tester.pumpWidget(_app(engine, view: _view()));
    await tester.pumpAndSettle();
    expect(engine.presentationCalls, isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(engine.calls, ['presentation:work', 'show_list:work']);
    expect(workspaceViewIdentity(engine.presentationCalls.single), (
      'work',
      'view-1',
      'op-1',
      1,
    ));
    expect(systemCalls.where((call) => call == 'SystemNavigator.pop'), isEmpty);
  });

  testWidgets(
    'menu Back keeps the panel visible and supplies its own Back hint',
    (tester) async {
      final engine = FakeSessionEngine()
        ..presentation = WorkspacePresentation.menu;
      await tester.pumpWidget(_app(engine, view: _view()));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Use Back inside the open WhatsApp panel to return to chats.',
        ),
        findsOneWidget,
      );
      expect(
        engine.calls.where((call) => call.startsWith('show_list')),
        isEmpty,
      );
      expect(
        systemCalls.where((call) => call == 'SystemNavigator.pop'),
        isEmpty,
      );
      await tester.pump(const Duration(seconds: 7));
      expect(
        find.text(
          'Use Back inside the open WhatsApp panel to return to chats.',
        ),
        findsNothing,
      );
      expect(engine.presentationCalls, hasLength(1));
    },
  );

  for (final presentation in [
    WorkspacePresentation.list,
    WorkspacePresentation.original,
    WorkspacePresentation.unavailable,
  ]) {
    testWidgets(
      '$presentation follows explicit root Back to normal system exit',
      (tester) async {
        final engine = FakeSessionEngine()..presentation = presentation;
        await tester.pumpWidget(_app(engine, view: _view()));
        await tester.pumpAndSettle();
        expect(
          systemCalls.where((call) => call == 'SystemNavigator.pop'),
          isEmpty,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          systemCalls.where((call) => call == 'SystemNavigator.pop'),
          hasLength(1),
        );
        expect(engine.calls, ['presentation:work']);
      },
    );
  }

  testWidgets(
    'normal Back pops a nested route without exiting the application',
    (tester) async {
      final engine = FakeSessionEngine()
        ..presentation = WorkspacePresentation.list;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_app(engine, navigator: navigator));
      await tester.pumpAndSettle();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => WorkspaceBackHandler(
            view: _view(),
            child: const Scaffold(body: Text('Nested workspace')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Nested workspace'), findsNothing);
      expect(find.text('Workspace'), findsOneWidget);
      expect(
        systemCalls.where((call) => call == 'SystemNavigator.pop'),
        isEmpty,
      );
    },
  );

  testWidgets('keyboard Back hides the IME before any layout query or exit', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    final engine = FakeSessionEngine()
      ..presentation = WorkspacePresentation.detail;
    await tester.pumpWidget(_app(engine, view: _view()));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.testTextInput.log.map((call) => call.method),
      contains('TextInput.hide'),
    );
    expect(engine.calls, isEmpty);
    expect(systemCalls.where((call) => call == 'SystemNavigator.pop'), isEmpty);
  });

  testWidgets(
    'duplicate Back is single-flight and stale view results cannot command another profile',
    (tester) async {
      final pending = Completer<WorkspacePresentation>();
      final engine = FakeSessionEngine()..presentationReply = pending.future;
      await tester.pumpWidget(_app(engine, view: _view()));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(engine.presentationCalls, hasLength(1));
      await tester.pumpWidget(_app(engine, view: _view(2)));
      pending.complete(WorkspacePresentation.detail);
      await tester.pumpAndSettle();
      expect(
        engine.calls.where((call) => call.startsWith('show_list')),
        isEmpty,
      );
      expect(
        systemCalls.where((call) => call == 'SystemNavigator.pop'),
        isEmpty,
      );
      engine.presentationReply = null;
      engine.presentation = WorkspacePresentation.detail;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(engine.presentationCalls.last.selectionGeneration, 2);
      expect(
        engine.calls.where((call) => call.startsWith('show_list')),
        hasLength(1),
      );
    },
  );

  for (final reason in ['lock', 'cover', 'dispose']) {
    testWidgets(
      '$reason removes Back ownership and ignores pending results without remounting host',
      (tester) async {
        final pending = Completer<WorkspacePresentation>();
        final engine = FakeSessionEngine()..presentationReply = pending.future;
        var mounts = 0, disposals = 0;
        final child = _MountedChild(
          onMount: () => mounts++,
          onDispose: () => disposals++,
        );
        await tester.pumpWidget(_app(engine, view: _view(), child: child));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pump();
        if (reason == 'dispose') {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          await tester.pumpWidget(_app(engine, child: child));
        }
        pending.complete(WorkspacePresentation.detail);
        await tester.pumpAndSettle();
        expect(
          engine.calls.where((call) => call.startsWith('show_list')),
          isEmpty,
        );
        expect(
          systemCalls.where((call) => call == 'SystemNavigator.pop'),
          isEmpty,
        );
        expect(mounts, 1);
        expect(disposals, reason == 'dispose' ? 1 : 0);
      },
    );
  }

  testWidgets(
    'query failure keeps the route and exposes a bounded retry hint',
    (tester) async {
      final pending = Completer<WorkspacePresentation>();
      final engine = FakeSessionEngine()..presentationReply = pending.future;
      await tester.pumpWidget(_app(engine, view: _view()));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(
        find.text('The page could not be checked. Try Back again.'),
        findsOneWidget,
      );
      expect(
        systemCalls.where((call) => call == 'SystemNavigator.pop'),
        isEmpty,
      );
      pending.complete(WorkspacePresentation.list);
      await tester.pumpAndSettle();
      expect(
        systemCalls.where((call) => call == 'SystemNavigator.pop'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'a route opened during a Back query cannot be popped by its late result',
    (tester) async {
      final pending = Completer<WorkspacePresentation>();
      final engine = FakeSessionEngine()..presentationReply = pending.future;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _app(engine, view: _view(), navigator: navigator),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pump();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Settings route')),
        ),
      );
      await tester.pumpAndSettle();
      pending.complete(WorkspacePresentation.list);
      await tester.pumpAndSettle();
      expect(find.text('Settings route'), findsOneWidget);
      expect(
        systemCalls.where((call) => call == 'SystemNavigator.pop'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'push/pop round trip permanently invalidates an earlier Back query',
    (tester) async {
      final pending = Completer<WorkspacePresentation>();
      final engine = FakeSessionEngine()..presentationReply = pending.future;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _app(engine, view: _view(), navigator: navigator),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pump();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Temporary route')),
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      pending.complete(WorkspacePresentation.list);
      await tester.pumpAndSettle();
      expect(find.text('Workspace'), findsOneWidget);
      expect(
        systemCalls.where((call) => call == 'SystemNavigator.pop'),
        isEmpty,
      );
      expect(
        engine.calls.where((call) => call.startsWith('show_list')),
        isEmpty,
      );
      engine.presentationReply = null;
      engine.presentation = WorkspacePresentation.detail;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(engine.presentationCalls, hasLength(2));
      expect(
        engine.calls.where((call) => call.startsWith('show_list')),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'iOS uses its ordinary route navigation without presentation queries',
    (tester) async {
      final engine = FakeSessionEngine();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _app(
          engine,
          view: _view(),
          platform: TargetPlatform.iOS,
          navigator: navigator,
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => WorkspaceBackHandler(
            view: _view(),
            child: const Scaffold(body: Text('iOS route')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('iOS route'), findsNothing);
      expect(engine.presentationCalls, isEmpty);
    },
  );

  testWidgets(
    'workspace integration removes Back ownership immediately on app lock',
    (tester) async {
      final engine = FakeSessionEngine()..readyBeforeOpenReturns = true;
      engine.seed('work');
      final container = ProviderContainer(
        overrides: [engineProvider.overrideWithValue(engine)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: deskTheme(Brightness.light)
                .copyWith(platform: TargetPlatform.android),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WorkspaceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await container.read(coordinatorProvider).select('work');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<WorkspaceBackHandler>(find.byType(WorkspaceBackHandler))
            .view,
        isNotNull,
      );
      final pending = Completer<WorkspacePresentation>();
      engine.presentationReply = pending.future;
      await tester.binding.handlePopRoute();
      await tester.pump();
      await container.read(coordinatorProvider).lock();
      await tester.pump();
      expect(
        tester
            .widget<WorkspaceBackHandler>(find.byType(WorkspaceBackHandler))
            .view,
        isNull,
      );
      pending.complete(WorkspacePresentation.detail);
      await tester.pumpAndSettle();
      expect(
        engine.calls.where((call) => call.startsWith('show_list')),
        isEmpty,
      );
      expect(
        systemCalls.where((call) => call == 'SystemNavigator.pop'),
        isEmpty,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
