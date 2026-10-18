import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_desk/app/design.dart';
import 'package:profile_desk/features/messaging/native_messaging_controller.dart';
import 'package:profile_desk/features/messaging/native_messaging_models.dart';
import 'package:profile_desk/features/messaging/native_messaging_port.dart';
import 'package:profile_desk/features/messaging/native_messaging_workspace.dart';
import 'package:profile_desk/l10n/app_localizations.dart';

// Entirely fictional data. This fixture is never registered in the app.
final _alpha = MessagingScope(
  profileId: 'fictional-alpha',
  viewInstanceId: 'view-a',
  selectionGeneration: 1,
);
final _beta = MessagingScope(
  profileId: 'fictional-beta',
  viewInstanceId: 'view-b',
  selectionGeneration: 2,
);
final _time = DateTime.utc(2026, 10, 19, 10, 30);
NativeChatSummary _chat({String id = 'tea', bool canSend = true}) =>
    NativeChatSummary(
      id: id,
      title: id == 'tea' ? 'Garden Club' : 'Studio notices',
      canSend: canSend,
      preview: id == 'tea' ? 'Bring your favourite notebook.' : null,
      unreadCount: id == 'tea' ? 2 : 0,
    );
NativeMessage _text(String id, String body, {bool outgoing = false}) =>
    NativeMessage.text(
      id: id,
      text: body,
      outgoing: outgoing,
      sentAt: _time,
      delivery: outgoing
          ? NativeDeliveryState.delivered
          : NativeDeliveryState.unknown,
    );

class _FixturePort implements NativeMessagingPort {
  Future<NativeChatSnapshot> Function(MessagingScope)? onChats;
  Future<NativeMessagePage> Function(MessagingScope, String, String?)?
  onMessages;
  Future<NativeSendResult> Function(MessagingScope, String, String, String)?
  onSend;
  final sends =
      <({MessagingScope scope, String chatId, String text, String actionId})>[];
  final pages = <String?>[];
  MessagingAvailability availability = MessagingAvailability.ready;

  @override
  Future<NativeChatSnapshot> loadChats(MessagingScope scope) async =>
      onChats != null
      ? onChats!(scope)
      : NativeChatSnapshot(
          scope: scope,
          availability: availability,
          chats: availability == MessagingAvailability.ready
              ? [_chat(), _chat(id: 'notice', canSend: false)]
              : [],
        );

  @override
  Future<NativeMessagePage> loadMessages(
    MessagingScope scope, {
    required String chatId,
    String? beforeCursor,
  }) async {
    pages.add(beforeCursor);
    if (onMessages != null) return onMessages!(scope, chatId, beforeCursor);
    return NativeMessagePage(
      scope: scope,
      chatId: chatId,
      messages: [
        _text('hello', 'The garden sketch is ready.'),
        _text('reply', 'I will bring the pencils.', outgoing: true),
        NativeMessage.unsupported(id: 'photo', outgoing: false, sentAt: _time),
      ],
    );
  }

  @override
  Future<NativeSendResult> sendText(
    MessagingScope scope, {
    required String chatId,
    required String text,
    required String actionId,
  }) async {
    sends.add((scope: scope, chatId: chatId, text: text, actionId: actionId));
    return onSend != null
        ? onSend!(scope, chatId, text, actionId)
        : NativeSendResult(
            scope: scope,
            chatId: chatId,
            actionId: actionId,
            outcome: NativeSendOutcome.accepted,
          );
  }
}

Future<NativeMessagingController> _ready(_FixturePort port) async {
  final controller = NativeMessagingController(port: port, scope: _alpha);
  await controller.loadChats();
  await controller.selectChat('tea');
  return controller;
}

Widget _app(
  _FixturePort port, {
  MessagingScope? scope,
  VoidCallback? official,
  bool active = true,
  bool reduceMotion = false,
  int refreshRevision = 0,
  Key? repaintKey,
}) => MaterialApp(
  theme: deskTheme(Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(
        body: RepaintBoundary(
          key: repaintKey,
          child: NativeMessagingWorkspace(
            port: port,
            scope: scope ?? _alpha,
            active: active,
            refreshRevision: refreshRevision,
            onOpenOfficial: official ?? () {},
          ),
        ),
      ),
    ),
  ),
);

Finder get _composer => find.byKey(const ValueKey('native-messaging-composer'));
Finder get _send => find.byKey(const ValueKey('native-messaging-send'));
Finder get _back => find.byKey(const ValueKey('native-messaging-back'));

void main() {
  test(
    'display models reject oversized, duplicate and unavailable payloads',
    () {
      expect(
        () => NativeMessage.text(
          id: 'id',
          text: 'x' * (MessagingLimits.body + 1),
          outgoing: false,
          sentAt: _time,
        ),
        throwsArgumentError,
      );
      expect(
        () => NativeChatSnapshot(
          scope: _alpha,
          availability: MessagingAvailability.locked,
          chats: [_chat()],
        ),
        throwsArgumentError,
      );
      expect(
        () => NativeChatSnapshot(
          scope: _alpha,
          availability: MessagingAvailability.ready,
          chats: [_chat(), _chat()],
        ),
        throwsArgumentError,
      );
      expect(
        () => NativeMessagePage(
          scope: _alpha,
          chatId: 'tea',
          messages: [_text('same', 'One'), _text('same', 'Two')],
        ),
        throwsArgumentError,
      );
      expect(
        NativeMessage.unsupported(
          id: 'private',
          outgoing: false,
          sentAt: _time,
        ).body,
        isNull,
      );
      expect(
        _text('id', 'FICTIONAL_PRIVATE_BODY').toString(),
        isNot(contains('FICTIONAL_PRIVATE_BODY')),
      );
      expect(
        const NativeMessagingException(MessagingFailure.incompatible)
            .toString(),
        'Native messaging operation unavailable.',
      );
    },
  );

  test('late chat snapshot cannot cross a profile generation', () async {
    final pending = Completer<NativeChatSnapshot>();
    final port = _FixturePort()
      ..onChats = (scope) async => scope == _alpha
          ? pending.future
          : NativeChatSnapshot(
              scope: scope,
              availability: MessagingAvailability.ready,
              chats: [_chat(id: 'notice')],
            );
    final controller = NativeMessagingController(port: port, scope: _alpha);
    addTearDown(controller.dispose);
    final oldLoad = controller.loadChats();
    controller.setScope(_beta);
    await controller.loadChats();
    pending.complete(
      NativeChatSnapshot(
        scope: _alpha,
        availability: MessagingAvailability.ready,
        chats: [_chat()],
      ),
    );
    await oldLoad;
    expect(controller.scope, _beta);
    expect(controller.chats.single.id, 'notice');
  });

  test(
    'wrong response ownership fails closed for list and message pages',
    () async {
      final port = _FixturePort()
        ..onChats = (_) async => NativeChatSnapshot(
          scope: _beta,
          availability: MessagingAvailability.ready,
          chats: [_chat()],
        );
      final controller = NativeMessagingController(port: port, scope: _alpha);
      addTearDown(controller.dispose);
      await controller.loadChats();
      expect(controller.chats, isEmpty);
      expect(controller.chatsState, MessagingLoadState.failed);
      port.onChats = null;
      await controller.loadChats();
      port.onMessages = (scope, chat, cursor) async => NativeMessagePage(
        scope: _beta,
        chatId: chat,
        messages: [_text('wrong', 'Must stay hidden')],
      );
      await controller.selectChat('tea');
      expect(controller.messages, isEmpty);
      expect(controller.messagesState, MessagingLoadState.failed);
    },
  );

  test(
    'late history cannot replace another conversation or disposed state',
    () async {
      final pending = Completer<NativeMessagePage>();
      final port = _FixturePort()
        ..onMessages = (scope, chat, cursor) async => chat == 'tea'
            ? pending.future
            : NativeMessagePage(
                scope: scope,
                chatId: chat,
                messages: [_text('notice', 'Studio is open.')],
              );
      final controller = NativeMessagingController(port: port, scope: _alpha);
      await controller.loadChats();
      final oldLoad = controller.selectChat('tea');
      await controller.selectChat('notice');
      pending.complete(
        NativeMessagePage(
          scope: _alpha,
          chatId: 'tea',
          messages: [_text('late', 'Old chat')],
        ),
      );
      await oldLoad;
      expect(controller.messages.single.id, 'notice');
      final pendingDispose = Completer<NativeChatSnapshot>();
      port.onChats = (_) => pendingDispose.future;
      final disposedLoad = controller.loadChats();
      controller.dispose();
      pendingDispose.complete(
        NativeChatSnapshot(
          scope: _alpha,
          availability: MessagingAvailability.ready,
          chats: [_chat()],
        ),
      );
      await disposedLoad;
      expect(controller.messages, isEmpty);
      expect(controller.chats, isEmpty);
    },
  );

  test(
    'drafts follow profile and chat; lock discards all private content',
    () async {
      final port = _FixturePort();
      final controller = await _ready(port);
      addTearDown(controller.dispose);
      controller.setDraft('Fictional alpha draft');
      controller.backToChats();
      await controller.selectChat('tea');
      expect(controller.draft, 'Fictional alpha draft');
      controller.setScope(_beta);
      await controller.loadChats();
      await controller.selectChat('tea');
      expect(controller.draft, isEmpty);
      controller.setDraft('Fictional beta draft');
      controller.setScope(_alpha);
      await controller.loadChats();
      await controller.selectChat('tea');
      expect(controller.draft, 'Fictional alpha draft');
      controller.suspend();
      expect(controller.messages, isEmpty);
      expect(controller.chats, isEmpty);
      expect(controller.draft, isEmpty);
      controller.resume();
      await controller.loadChats();
      await controller.selectChat('tea');
      expect(controller.draft, isEmpty);
    },
  );

  test(
    'single flight, explicit rejection and uncertain result preserve drafts',
    () async {
      final pending = Completer<NativeSendResult>();
      final port = _FixturePort()..onSend = (_, _, _, _) => pending.future;
      final controller = await _ready(port);
      addTearDown(controller.dispose);
      controller.setDraft('Bring blue pencils.');
      final sending = controller.send();
      await controller.send();
      expect(port.sends, hasLength(1));
      expect(controller.composerStatus, ComposerStatus.sending);
      final request = port.sends.single;
      pending.complete(
        NativeSendResult(
          scope: request.scope,
          chatId: request.chatId,
          actionId: request.actionId,
          outcome: NativeSendOutcome.rejected,
        ),
      );
      await sending;
      expect(controller.draft, 'Bring blue pencils.');
      expect(controller.composerStatus, ComposerStatus.rejected);
      port.onSend = (_, _, _, _) => Future.error(StateError('synthetic only'));
      await controller.send();
      expect(controller.composerStatus, ComposerStatus.uncertain);
      expect(controller.draft, 'Bring blue pencils.');
      await controller.send();
      expect(port.sends, hasLength(2));
      expect(controller.canCompose, isFalse);
      controller.clearUncertainDraft();
      expect(controller.draft, isEmpty);
      expect(controller.canCompose, isTrue);
    },
  );

  test(
    'scope switch marks in-flight draft uncertain and ignores late success',
    () async {
      final pending = Completer<NativeSendResult>();
      final port = _FixturePort()..onSend = (_, _, _, _) => pending.future;
      final controller = await _ready(port);
      addTearDown(controller.dispose);
      controller.setDraft('Fictional in-flight draft');
      final sending = controller.send();
      final request = port.sends.single;
      controller.setScope(_beta);
      await controller.loadChats();
      await controller.selectChat('tea');
      controller.setDraft('New account draft');
      pending.complete(
        NativeSendResult(
          scope: request.scope,
          chatId: request.chatId,
          actionId: request.actionId,
          outcome: NativeSendOutcome.accepted,
        ),
      );
      await sending;
      expect(controller.draft, 'New account draft');
      controller.setScope(_alpha);
      await controller.loadChats();
      await controller.selectChat('tea');
      expect(controller.composerStatus, ComposerStatus.uncertain);
      expect(controller.draft, 'Fictional in-flight draft');
      await controller.send();
      expect(port.sends, hasLength(1));
    },
  );

  test(
    'send timeout and mismatched action never claim success or replay',
    () async {
      final port = _FixturePort()
        ..onSend = (_, _, _, _) => Completer<NativeSendResult>().future;
      final controller = NativeMessagingController(
        port: port,
        scope: _alpha,
        sendTimeout: const Duration(milliseconds: 1),
      );
      addTearDown(controller.dispose);
      await controller.loadChats();
      await controller.selectChat('tea');
      controller.setDraft('Fictional timeout');
      await controller.send();
      expect(controller.composerStatus, ComposerStatus.uncertain);
      await controller.send();
      expect(port.sends, hasLength(1));
      controller.clearUncertainDraft();
      controller.setDraft('Fictional mismatch');
      port.onSend = (scope, chatId, text, actionId) async => NativeSendResult(
        scope: scope,
        chatId: chatId,
        actionId: 'wrong-action',
        outcome: NativeSendOutcome.accepted,
      );
      await controller.send();
      expect(controller.composerStatus, ComposerStatus.uncertain);
      expect(controller.draft, 'Fictional mismatch');
    },
  );

  test(
    'history pagination merges IDs, bounds memory and rejects stuck cursors',
    () async {
      final port = _FixturePort()
        ..onMessages = (scope, chatId, cursor) async => NativeMessagePage(
          scope: scope,
          chatId: chatId,
          beforeCursor: cursor == null ? 'older' : 'oldest',
          messages: cursor == null
              ? [_text('recent', 'Recent')]
              : [_text('old', 'Earlier'), _text('recent', 'Recent')],
        );
      final controller = await _ready(port);
      addTearDown(controller.dispose);
      await controller.loadMessages(earlier: true);
      expect(controller.messages.map((message) => message.id), [
        'old',
        'recent',
      ]);
      expect(controller.partialHistory, isTrue);
      await controller.loadMessages(earlier: true);
      expect(controller.earlierFailed, isTrue);
      expect(controller.messages.map((message) => message.id), [
        'old',
        'recent',
      ]);
      port.onMessages = (scope, chatId, cursor) async => NativeMessagePage(
        scope: scope,
        chatId: chatId,
        messages: List.generate(
          100,
          (index) => _text('page-$index', 'Fictional $index'),
        ),
      );
      await controller.loadMessages(earlier: true);
      expect(controller.messages, hasLength(100));
    },
  );

  test(
    'send ownership survives chat navigation and disposal without replay',
    () async {
      final pending = Completer<NativeSendResult>();
      final port = _FixturePort()..onSend = (_, _, _, _) => pending.future;
      final controller = await _ready(port);
      controller.setDraft('Fictional pending text');
      final sending = controller.send();
      final request = port.sends.single;
      controller.backToChats();
      await controller.selectChat('tea');
      await controller.send();
      expect(port.sends, hasLength(1));
      controller.dispose();
      pending.complete(
        NativeSendResult(
          scope: request.scope,
          chatId: request.chatId,
          actionId: request.actionId,
          outcome: NativeSendOutcome.accepted,
        ),
      );
      await sending;
      expect(controller.chats, isEmpty);
      expect(controller.messages, isEmpty);
      expect(controller.draft, isEmpty);
      port.onSend = null;
      final reopened = await _ready(port);
      addTearDown(reopened.dispose);
      reopened.setDraft('A separately initiated fictional message');
      await reopened.send();
      expect(port.sends.last.actionId, isNot(request.actionId));
    },
  );

  for (final operation in ['list', 'messages', 'pagination', 'send']) {
    test(
      'typed lock from $operation purges all content and invalidates pending work',
      () async {
        final port = _FixturePort()
          ..onMessages = (scope, chatId, cursor) async => NativeMessagePage(
            scope: scope,
            chatId: chatId,
            beforeCursor: 'older',
            messages: [_text('visible', 'Fictional protected message')],
          );
        final controller = await _ready(port);
        addTearDown(controller.dispose);
        controller.setDraft('Fictional alpha draft');
        controller.setScope(_beta);
        await controller.loadChats();
        await controller.selectChat('tea');
        controller.setDraft('Fictional beta draft');
        controller.setScope(_alpha);
        await controller.loadChats();
        await controller.selectChat('tea');
        controller.setQuery('Garden');
        final pendingSend = Completer<NativeSendResult>();
        final pendingRead = Completer<NativeMessagePage>();
        late Future<void> lateOperation;
        if (operation == 'send') {
          port.onMessages = (_, _, _) => pendingRead.future;
          lateOperation = controller.loadMessages(refresh: true);
          port.onSend = (_, _, _, _) async =>
              throw const NativeMessagingException(MessagingFailure.locked);
          await controller.send();
        } else {
          port.onSend = (_, _, _, _) => pendingSend.future;
          lateOperation = controller.send();
          if (operation == 'list') {
            port.onChats = (_) async =>
                throw const NativeMessagingException(MessagingFailure.locked);
            await controller.loadChats();
          } else {
            port.onMessages = (_, _, _) async =>
                throw const NativeMessagingException(MessagingFailure.locked);
            await controller.loadMessages(
              earlier: operation == 'pagination',
              refresh: operation == 'messages',
            );
          }
        }
        void expectPurged() {
          expect(controller.availability, MessagingAvailability.locked);
          expect(controller.chats, isEmpty);
          expect(controller.messages, isEmpty);
          expect(controller.selectedChat, isNull);
          expect(controller.query, isEmpty);
          expect(controller.draft, isEmpty);
          expect(controller.beforeCursor, isNull);
          expect(controller.loadingEarlier, isFalse);
          expect(controller.canSend, isFalse);
        }

        expectPurged();
        final pageCallsAtLock = port.pages.length;
        if (operation == 'send') {
          pendingRead.complete(
            NativeMessagePage(
              scope: _alpha,
              chatId: 'tea',
              messages: [_text('late', 'Must remain hidden')],
            ),
          );
        } else {
          final request = port.sends.single;
          pendingSend.complete(
            NativeSendResult(
              scope: request.scope,
              chatId: request.chatId,
              actionId: request.actionId,
              outcome: NativeSendOutcome.accepted,
            ),
          );
        }
        await lateOperation;
        expectPurged();
        expect(port.pages.length, pageCallsAtLock);
        expect(port.sends, hasLength(1));
        port.onChats = null;
        port.onMessages = null;
        port.onSend = null;
        await controller.loadChats();
        await controller.selectChat('tea');
        expect(controller.draft, isEmpty);
        controller.setScope(_beta);
        await controller.loadChats();
        await controller.selectChat('tea');
        expect(controller.draft, isEmpty);
      },
    );
  }

  test(
    'locked snapshots also advance the epoch and reject a pending page',
    () async {
      final port = _FixturePort();
      final controller = await _ready(port);
      addTearDown(controller.dispose);
      controller.setDraft('Fictional draft before lock');
      controller.setQuery('Garden');
      final pending = Completer<NativeMessagePage>();
      port.onMessages = (_, _, _) => pending.future;
      final read = controller.loadMessages(refresh: true);
      port.availability = MessagingAvailability.locked;
      await controller.loadChats();
      pending.complete(
        NativeMessagePage(
          scope: _alpha,
          chatId: 'tea',
          messages: [_text('late', 'Do not restore')],
        ),
      );
      await read;
      expect(controller.availability, MessagingAvailability.locked);
      expect(controller.selectedChat, isNull);
      expect(controller.query, isEmpty);
      expect(controller.messages, isEmpty);
      expect(controller.draft, isEmpty);
    },
  );

  test(
    'a delayed lock failure from an old scope cannot lock the new account',
    () async {
      final port = _FixturePort();
      final controller = await _ready(port);
      addTearDown(controller.dispose);
      final pending = Completer<NativeMessagePage>();
      port.onMessages = (_, _, _) => pending.future;
      final oldRead = controller.loadMessages(refresh: true);
      controller.setScope(_beta);
      port.onMessages = null;
      await controller.loadChats();
      await controller.selectChat('tea');
      controller.setDraft('Fictional new-account draft');
      pending.completeError(
        const NativeMessagingException(MessagingFailure.locked),
      );
      await oldRead;
      expect(controller.scope, _beta);
      expect(controller.availability, MessagingAvailability.ready);
      expect(controller.messages, isNotEmpty);
      expect(controller.draft, 'Fictional new-account draft');
    },
  );

  testWidgets(
    'service lock error removes native titles, messages and draft fields',
    (tester) async {
      final port = _FixturePort();
      await tester.pumpWidget(_app(port));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Fictional displayed draft');
      port.onMessages = (_, _, _) async =>
          throw const NativeMessagingException(MessagingFailure.locked);
      await tester.pumpWidget(_app(port, refreshRevision: 1));
      await tester.pumpAndSettle();
      expect(find.text('Your conversation is protected'), findsOneWidget);
      expect(find.text('Garden Club'), findsNothing);
      expect(find.byType(SelectableText), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'loading, empty, no-results, link and offline states are explicit',
    (tester) async {
      final pending = Completer<NativeChatSnapshot>();
      final port = _FixturePort()..onChats = (_) => pending.future;
      await tester.pumpWidget(_app(port));
      expect(find.text('Loading chats…'), findsOneWidget);
      pending.complete(
        NativeChatSnapshot(
          scope: _alpha,
          availability: MessagingAvailability.ready,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No chats to show'), findsOneWidget);
      port.onChats = null;
      await tester.tap(find.byTooltip('Refresh chats'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('native-messaging-search')),
        'No matching fictional name',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching chats'), findsOneWidget);
      for (final state in [
        MessagingAvailability.linkRequired,
        MessagingAvailability.offline,
        MessagingAvailability.locked,
      ]) {
        port.availability = state;
        await tester.tap(find.byTooltip('Refresh chats'));
        await tester.pumpAndSettle();
        expect(find.text('Garden Club'), findsNothing);
        expect(
          find.text(switch (state) {
            MessagingAvailability.linkRequired => 'Link your account',
            MessagingAvailability.offline => 'You are offline',
            _ => 'Your conversation is protected',
          }),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'native history action and system Back preserve conversation draft',
    (tester) async {
      final port = _FixturePort()
        ..onMessages = (scope, chatId, cursor) async => NativeMessagePage(
          scope: scope,
          chatId: chatId,
          beforeCursor: cursor == null ? 'older' : null,
          messages: [
            _text(
              cursor == null ? 'new' : 'old',
              cursor == null
                  ? 'Newer fictional message'
                  : 'Earlier fictional message',
            ),
          ],
        );
      await tester.pumpWidget(_app(port));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load earlier messages'));
      await tester.pumpAndSettle();
      expect(port.pages, [null, 'older']);
      expect(find.text('Earlier fictional message'), findsOneWidget);
      await tester.enterText(_composer, 'Fictional system-back draft');
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Chats'), findsOneWidget);
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'Fictional system-back draft',
      );
    },
  );

  testWidgets(
    'host refresh updates messages without replacing conversation or draft',
    (tester) async {
      final pending = Completer<NativeMessagePage>();
      final port = _FixturePort();
      await tester.pumpWidget(_app(port));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Fictional draft survives refresh');
      await tester.pump();
      port.onMessages = (_, _, _) => pending.future;
      await tester.pumpWidget(_app(port, refreshRevision: 1));
      await tester.pump();
      expect(find.text('The garden sketch is ready.'), findsOneWidget);
      expect(tester.widget<TextField>(_composer).enabled, isTrue);
      pending.complete(
        NativeMessagePage(
          scope: _alpha,
          chatId: 'tea',
          messages: [_text('new-live', 'New fictional arrival')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('New fictional arrival'), findsOneWidget);
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'Fictional draft survives refresh',
      );
      expect(_back, findsOneWidget);
      expect(port.sends, isEmpty);
    },
  );

  testWidgets(
    'native interactive targets are labeled and meet phone touch sizes',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final port = _FixturePort();
      await tester.pumpWidget(_app(port, reduceMotion: true));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    },
  );

  testWidgets(
    'native search, selection, drafts, back, send and official fallback',
    (tester) async {
      var official = 0;
      final pending = Completer<NativeSendResult>();
      final port = _FixturePort()..onSend = (_, _, _, _) => pending.future;
      await tester.pumpWidget(_app(port, official: () => official++));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('native-messaging-search')),
        'Garden',
      );
      await tester.pumpAndSettle();
      expect(find.text('Studio notices'), findsNothing);
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsNWidgets(2));
      expect(
        find.text('View this content in the official interface'),
        findsOneWidget,
      );
      await tester.enterText(_composer, 'A fictional draft');
      await tester.tap(_back);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'A fictional draft',
      );
      await tester.tap(_send);
      await tester.pump();
      await tester.tap(_send);
      expect(port.sends, hasLength(1));
      final request = port.sends.single;
      pending.complete(
        NativeSendResult(
          scope: request.scope,
          chatId: request.chatId,
          actionId: request.actionId,
          outcome: NativeSendOutcome.accepted,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_composer).controller!.text, isEmpty);
      expect(
        find.text('Submitted to WhatsApp. Delivery is not yet confirmed.'),
        findsOneWidget,
      );
      await tester.tap(
        find.text('View this content in the official interface'),
      );
      await tester.pump();
      expect(official, 1);
      expect(find.byType(SelectableText), findsNothing);
      expect(_composer, findsNothing);
      expect(find.text('Your conversation is protected'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'read-only conversation and unavailable state expose honest fallback',
    (tester) async {
      var official = 0;
      final port = _FixturePort();
      await tester.pumpWidget(_app(port, official: () => official++));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Studio notices'));
      await tester.pumpAndSettle();
      expect(_composer, findsNothing);
      expect(_send, findsNothing);
      expect(
        find.text(
          'This conversation is read-only here. Open the official interface for available actions.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Open official interface'));
      expect(official, 1);
      port.availability = MessagingAvailability.unsupported;
      await tester.pumpWidget(
        _app(port, active: false, official: () => official++),
      );
      await tester.pump();
      await tester.pumpWidget(
        _app(port, scope: _beta, official: () => official++),
      );
      await tester.pumpAndSettle();
      expect(find.text('Native chats are unavailable'), findsOneWidget);
      expect(find.text('Garden Club'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'uncertain outcome has no resend action; deliberate check clears draft',
    (tester) async {
      final port = _FixturePort()
        ..onSend = (scope, chatId, text, actionId) async => NativeSendResult(
          scope: scope,
          chatId: chatId,
          actionId: actionId,
          outcome: NativeSendOutcome.uncertain,
        );
      await tester.pumpWidget(_app(port));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Fictional uncertainty');
      await tester.pump();
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(_send).onPressed, isNull);
      expect(tester.widget<TextField>(_composer).enabled, isFalse);
      expect(
        tester.widget<TextField>(_composer).controller!.text,
        'Fictional uncertainty',
      );
      await tester.tap(find.text('I checked · clear draft'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_composer).controller!.text, isEmpty);
      expect(port.sends, hasLength(1));
    },
  );

  testWidgets(
    'privacy deactivation removes message and draft semantics immediately',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final port = _FixturePort();
      await tester.pumpWidget(_app(port));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Fictional private draft');
      await tester.pumpWidget(_app(port, active: false));
      expect(find.byType(SelectableText), findsNothing);
      expect(find.text('Your conversation is protected'), findsOneWidget);
      expect(
        tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!
            .toStringDeep(),
        isNot(contains('Fictional private draft')),
      );
      expect(
        tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!
            .toStringDeep(),
        isNot(contains('The garden sketch')),
      );
      semantics.dispose();
    },
  );

  for (final width in [320.0, 440.0]) {
    testWidgets('native content fits $width width, double text and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final port = _FixturePort();
      await tester.pumpWidget(_app(port, reduceMotion: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 216);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Fictional keyboard draft');
      await tester.pumpAndSettle();
      expect(tester.getRect(_send).bottom, lessThanOrEqualTo(352));
      expect(tester.getSize(_send).shortestSide, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      port.onSend = (scope, chatId, text, actionId) async => NativeSendResult(
        scope: scope,
        chatId: chatId,
        actionId: actionId,
        outcome: NativeSendOutcome.uncertain,
      );
      await tester.tap(_send);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(_back);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('native-messaging-search')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Studio notices'),
        120,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Studio notices'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 216);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This conversation is read-only here. Open the official interface for available actions.',
        ),
        findsOneWidget,
      );
      expect(_composer, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(568, 320), const Size(1024, 768)]) {
    testWidgets('native conversation remains reachable at $size and 2× text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final port = _FixturePort();
      await tester.pumpWidget(_app(port, reduceMotion: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      await tester.enterText(_composer, 'Fictional landscape or tablet draft');
      await tester.pumpAndSettle();
      expect(_send.hitTestable(), findsOneWidget);
      expect(_back.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'fictional native previews render without motion or remote assets',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (const bool.fromEnvironment('NATIVE_MESSAGING_CAPTURE')) {
        await tester.runAsync(() async {
          // Optional previews use existing local project/SDK fonts only. Tests
          // remain dependency-free, and no remote font request is performed.
          final manrope = FontLoader('Manrope')
            ..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
          await manrope.load();
          const fontRoot = String.fromEnvironment('NATIVE_MESSAGING_FONT_ROOT');
          if (fontRoot.isNotEmpty) {
            final roboto = FontLoader('Roboto')
              ..addFont(
                File('$fontRoot/Roboto-Regular.ttf')
                    .readAsBytes()
                    .then(ByteData.sublistView),
              );
            await roboto.load();
          }
        });
      }
      final boundary = GlobalKey();
      final port = _FixturePort();
      await tester.pumpWidget(
        _app(port, reduceMotion: true, repaintKey: boundary),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('NATIVE_MESSAGING_CAPTURE')) return;
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('test/fixtures/native_messaging/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('fictional-chat-list');
      await tester.tap(find.text('Garden Club'));
      await tester.pumpAndSettle();
      await capture('fictional-conversation');
      expect(tester.takeException(), isNull);
    },
  );
}
