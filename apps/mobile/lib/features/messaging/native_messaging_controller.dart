import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'native_messaging_models.dart';
import 'native_messaging_port.dart';

enum MessagingLoadState { idle, loading, ready, failed }

enum ComposerStatus { editing, sending, rejected, uncertain, accepted }

class _Draft {
  String text = '';
  ComposerStatus status = ComposerStatus.editing;
}

/// Ephemeral screen state. Dispose/suspend clears content; no persistence,
/// diagnostics or background polling. The host must also synchronously cover
/// native content before OS snapshots (a Dart controller is not that boundary).
class NativeMessagingController extends ChangeNotifier {
  NativeMessagingController({
    required this._port,
    required this._scope,
    this.readTimeout = const Duration(seconds: 18),
    this.sendTimeout = const Duration(seconds: 25),
  });

  final NativeMessagingPort _port;
  final Duration readTimeout;
  final Duration sendTimeout;
  MessagingScope _scope;
  bool _disposed = false;
  bool _active = true;
  int _epoch = 0;
  int _chatRequest = 0;
  int _messageRequest = 0;
  int _actionSequence = 0;
  final String _actionNamespace = List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  bool _sending = false;
  final Map<(String, String), _Draft> _drafts = {};

  MessagingScope get scope => _scope;
  bool get active => _active;
  MessagingLoadState chatsState = MessagingLoadState.idle;
  MessagingLoadState messagesState = MessagingLoadState.idle;
  MessagingAvailability availability = MessagingAvailability.ready;
  List<NativeChatSummary> chats = const [];
  List<NativeMessage> messages = const [];
  NativeChatSummary? selectedChat;
  String? beforeCursor;
  bool loadingEarlier = false;
  bool earlierFailed = false;
  bool partialHistory = true;
  String query = '';

  _Draft? get _currentDraft => selectedChat == null
      ? null
      : _drafts[(_scope.profileId, selectedChat!.id)];
  String get draft => _currentDraft?.text ?? '';
  ComposerStatus get composerStatus =>
      _currentDraft?.status ?? ComposerStatus.editing;
  bool get canCompose =>
      _active &&
      availability == MessagingAvailability.ready &&
      selectedChat?.canSend == true &&
      messagesState == MessagingLoadState.ready &&
      composerStatus != ComposerStatus.sending &&
      composerStatus != ComposerStatus.uncertain;
  bool get canSend => canCompose && !_sending && draft.trim().isNotEmpty;
  List<NativeChatSummary> get filteredChats {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty
        ? chats
        : chats
              .where((chat) => chat.title.toLowerCase().contains(normalized))
              .toList(growable: false);
  }

  bool _owns(MessagingScope scope, int epoch) =>
      !_disposed && _active && _scope == scope && _epoch == epoch;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void setScope(MessagingScope scope) {
    if (_disposed || scope == _scope) return;
    _interruptSends();
    _sending = false;
    _scope = scope;
    _epoch++;
    _clearVisible();
    _notify();
  }

  /// Call before replacing this screen on lock, background or host detach.
  /// Retained drafts are intentionally discarded at this privacy boundary.
  void suspend() {
    if (_disposed) return;
    _purgeLocked(deactivate: true);
  }

  /// Service-lock discovery applies to the entire currently owned scope, even
  /// if another read in that same scope superseded the discovering request.
  /// Advancing the epoch prevents every outstanding read/send from restoring
  /// content. Native action ownership remains authoritative for unknown sends.
  void _purgeLocked({bool deactivate = false}) {
    _interruptSends();
    if (deactivate) _active = false;
    _sending = false;
    _epoch++;
    for (final draft in _drafts.values) {
      draft.text = '';
    }
    _drafts.clear();
    _clearVisible();
    availability = MessagingAvailability.locked;
    _notify();
  }

  bool _handleLockedFailure(Object error) {
    if (error is! NativeMessagingException ||
        error.failure != MessagingFailure.locked) {
      return false;
    }
    _purgeLocked();
    return true;
  }

  void resume() {
    if (_disposed || _active) return;
    _active = true;
    availability = MessagingAvailability.ready;
    _notify();
  }

  void _interruptSends() {
    for (final draft in _drafts.values) {
      if (draft.status == ComposerStatus.sending) {
        draft.status = ComposerStatus.uncertain;
      }
    }
  }

  void _clearVisible() {
    chats = const [];
    messages = const [];
    selectedChat = null;
    beforeCursor = null;
    query = '';
    chatsState = MessagingLoadState.idle;
    messagesState = MessagingLoadState.idle;
    loadingEarlier = false;
    earlierFailed = false;
    availability = MessagingAvailability.ready;
    _chatRequest++;
    _messageRequest++;
  }

  void setQuery(String value) {
    if (_disposed || !_active) return;
    query = value.length <= MessagingLimits.title
        ? value
        : value.substring(0, MessagingLimits.title);
    _notify();
  }

  /// A host-triggered refresh only. The native owner decides when foreground,
  /// unlocked refreshes are permitted; this controller never starts a poller.
  Future<void> refresh() async {
    final scope = _scope;
    final epoch = _epoch;
    final chatId = selectedChat?.id;
    await loadChats();
    if (!_owns(scope, epoch) || selectedChat?.id != chatId || chatId == null) {
      return;
    }
    await loadMessages(refresh: true);
  }

  Future<void> loadChats() async {
    if (_disposed || !_active) return;
    final scope = _scope;
    final epoch = _epoch;
    final request = ++_chatRequest;
    chatsState = MessagingLoadState.loading;
    _notify();
    try {
      final result = await _port.loadChats(scope).timeout(readTimeout);
      if (!_owns(scope, epoch)) return;
      if (result.scope != scope) {
        throw const NativeMessagingException(MessagingFailure.incompatible);
      }
      if (result.availability == MessagingAvailability.locked) {
        _purgeLocked();
        return;
      }
      if (request != _chatRequest) return;
      availability = result.availability;
      chats = result.chats;
      chatsState = MessagingLoadState.ready;
      if (availability != MessagingAvailability.ready) {
        _interruptSends();
        _clearConversation();
      } else if (selectedChat != null) {
        final replacement = chats
            .where((chat) => chat.id == selectedChat!.id)
            .firstOrNull;
        if (replacement == null) {
          _clearConversation();
        } else {
          selectedChat = replacement;
        }
      }
    } catch (error) {
      if (!_owns(scope, epoch)) return;
      if (_handleLockedFailure(error)) return;
      if (request != _chatRequest) return;
      chats = const [];
      _clearConversation();
      chatsState = MessagingLoadState.failed;
    }
    _notify();
  }

  Future<void> selectChat(String chatId) async {
    if (_disposed || !_active || availability != MessagingAvailability.ready) {
      return;
    }
    final chat = chats.where((chat) => chat.id == chatId).firstOrNull;
    if (chat == null) return;
    _clearConversation();
    selectedChat = chat;
    _drafts.putIfAbsent((_scope.profileId, chat.id), _Draft.new);
    await loadMessages();
  }

  void backToChats() {
    if (_disposed) return;
    _clearConversation();
    _notify();
  }

  void _clearConversation() {
    selectedChat = null;
    messages = const [];
    beforeCursor = null;
    messagesState = MessagingLoadState.idle;
    loadingEarlier = false;
    earlierFailed = false;
    _messageRequest++;
  }

  Future<void> loadMessages({
    bool earlier = false,
    bool refresh = false,
  }) async {
    final chat = selectedChat;
    if (_disposed ||
        !_active ||
        chat == null ||
        loadingEarlier ||
        (earlier &&
            (beforeCursor == null ||
                messagesState != MessagingLoadState.ready))) {
      return;
    }
    final scope = _scope;
    final epoch = _epoch;
    final request = ++_messageRequest;
    final cursor = earlier ? beforeCursor : null;
    if (earlier) {
      loadingEarlier = true;
      earlierFailed = false;
    } else if (!refresh || messagesState != MessagingLoadState.ready) {
      messagesState = MessagingLoadState.loading;
    }
    _notify();
    try {
      final page = await _port
          .loadMessages(scope, chatId: chat.id, beforeCursor: cursor)
          .timeout(readTimeout);
      if (!_owns(scope, epoch) ||
          request != _messageRequest ||
          selectedChat?.id != chat.id) {
        return;
      }
      if (page.scope != scope ||
          page.chatId != chat.id ||
          (earlier && page.beforeCursor == cursor)) {
        throw const NativeMessagingException(MessagingFailure.incompatible);
      }
      // Keep a finite window. Older pages replace the oldest portion beyond the
      // cap; no unbounded transcript accumulates in Dart memory.
      final merged = <String, NativeMessage>{};
      for (final message in [...page.messages, if (earlier) ...messages]) {
        merged[message.id] = message;
      }
      partialHistory =
          page.partialHistory ||
          earlier ||
          merged.length > MessagingLimits.messages;
      messages = List.unmodifiable(
        merged.values.take(MessagingLimits.messages),
      );
      beforeCursor = page.beforeCursor;
      messagesState = MessagingLoadState.ready;
      loadingEarlier = false;
    } catch (error) {
      if (!_owns(scope, epoch)) return;
      if (_handleLockedFailure(error)) return;
      if (request != _messageRequest || selectedChat?.id != chat.id) {
        return;
      }
      if (earlier) {
        earlierFailed = true;
        loadingEarlier = false;
      } else {
        messages = const [];
        messagesState = MessagingLoadState.failed;
      }
    }
    _notify();
  }

  void setDraft(String value) {
    if (!canCompose) return;
    if (value.length > MessagingLimits.draft) {
      _notify();
      return;
    }
    final current = _currentDraft;
    if (current == null) return;
    current.text = value;
    current.status = ComposerStatus.editing;
    _notify();
  }

  void clearUncertainDraft() {
    if (_disposed || !_active || composerStatus != ComposerStatus.uncertain) {
      return;
    }
    _currentDraft!.text = '';
    _currentDraft!.status = ComposerStatus.editing;
    _notify();
  }

  Future<void> send() async {
    if (!canSend) return;
    final scope = _scope;
    final epoch = _epoch;
    final chatId = selectedChat!.id;
    final current = _currentDraft!;
    final text = current.text;
    // Controller-local monotonic IDs are namespaced by the complete view scope.
    // Native implementations must bind their deduplication to that scope too.
    final actionId = '$_actionNamespace-${++_actionSequence}';
    _sending = true;
    current.status = ComposerStatus.sending;
    _notify();
    NativeSendOutcome outcome;
    try {
      final result = await _port
          .sendText(scope, chatId: chatId, text: text, actionId: actionId)
          .timeout(sendTimeout);
      outcome =
          result.scope == scope &&
              result.chatId == chatId &&
              result.actionId == actionId
          ? result.outcome
          : NativeSendOutcome.uncertain;
    } catch (error) {
      if (!_owns(scope, epoch)) return;
      if (_handleLockedFailure(error)) return;
      // Even an exception may occur after the official client submitted it.
      outcome = NativeSendOutcome.uncertain;
    }
    if (!_owns(scope, epoch)) return;
    _sending = false;
    current.status = switch (outcome) {
      NativeSendOutcome.accepted => ComposerStatus.accepted,
      NativeSendOutcome.rejected => ComposerStatus.rejected,
      NativeSendOutcome.uncertain => ComposerStatus.uncertain,
    };
    if (outcome == NativeSendOutcome.accepted) current.text = '';
    _notify();
    if (outcome == NativeSendOutcome.accepted && selectedChat?.id == chatId) {
      await loadMessages(refresh: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _drafts.clear();
    _clearVisible();
    super.dispose();
  }
}
