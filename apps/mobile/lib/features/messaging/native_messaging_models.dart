/// Display-only values. Never add credentials, remote media URLs or raw client
/// objects here. Visibility filtering belongs to the reviewed native adapter.
library;

import 'package:flutter/foundation.dart';

abstract final class MessagingLimits {
  static const chats = 200;
  static const messages = 100;
  static const identifier = 256;
  static const title = 256;
  static const preview = 512;
  static const body = 16384;
  static const draft = 4096;
}

void _bounded(String value, int limit, {bool allowEmpty = false}) {
  if ((!allowEmpty && value.isEmpty) || value.length > limit) {
    throw ArgumentError('Invalid native messaging field.');
  }
}

@immutable
class MessagingScope {
  MessagingScope({
    required this.profileId,
    required this.viewInstanceId,
    required this.selectionGeneration,
  }) {
    _bounded(profileId, MessagingLimits.identifier);
    _bounded(viewInstanceId, MessagingLimits.identifier);
    if (selectionGeneration < 0) {
      throw ArgumentError('Invalid native messaging generation.');
    }
  }

  final String profileId;
  final String viewInstanceId;
  final int selectionGeneration;

  @override
  bool operator ==(Object other) =>
      other is MessagingScope &&
      profileId == other.profileId &&
      viewInstanceId == other.viewInstanceId &&
      selectionGeneration == other.selectionGeneration;
  @override
  int get hashCode =>
      Object.hash(profileId, viewInstanceId, selectionGeneration);
}

enum MessagingAvailability { ready, linkRequired, locked, offline, unsupported }

enum NativeDeliveryState { unknown, pending, sent, delivered, read, failed }

enum NativeMessageKind { text, unsupported }

@immutable
class NativeChatSummary {
  NativeChatSummary({
    required this.id,
    required this.title,
    required this.canSend,
    this.preview,
    this.unreadCount = 0,
    this.updatedAt,
  }) {
    _bounded(id, MessagingLimits.identifier);
    _bounded(title, MessagingLimits.title);
    if (preview != null) {
      _bounded(preview!, MessagingLimits.preview, allowEmpty: true);
    }
    if (unreadCount < 0 || unreadCount > 999999) {
      throw ArgumentError('Invalid native messaging count.');
    }
  }

  final String id;
  final String title;
  final String? preview;
  final bool canSend;
  final int unreadCount;
  final DateTime? updatedAt;
}

@immutable
class NativeMessage {
  NativeMessage.text({
    required this.id,
    required String text,
    required this.outgoing,
    required this.sentAt,
    this.delivery = NativeDeliveryState.unknown,
  }) : kind = NativeMessageKind.text,
       body = text {
    _bounded(id, MessagingLimits.identifier);
    _bounded(text, MessagingLimits.body, allowEmpty: true);
  }

  /// Unsupported content deliberately cannot carry body/caption/media data.
  NativeMessage.unsupported({
    required this.id,
    required this.outgoing,
    required this.sentAt,
    this.delivery = NativeDeliveryState.unknown,
  }) : kind = NativeMessageKind.unsupported,
       body = null {
    _bounded(id, MessagingLimits.identifier);
  }

  final String id;
  final NativeMessageKind kind;
  final String? body;
  final bool outgoing;
  final DateTime sentAt;
  final NativeDeliveryState delivery;
}

@immutable
class NativeChatSnapshot {
  NativeChatSnapshot({
    required this.scope,
    required this.availability,
    List<NativeChatSummary> chats = const [],
  }) : chats = List.unmodifiable(chats) {
    if (chats.length > MessagingLimits.chats ||
        chats.map((chat) => chat.id).toSet().length != chats.length ||
        (availability != MessagingAvailability.ready && chats.isNotEmpty)) {
      throw ArgumentError('Invalid native chat snapshot.');
    }
  }

  final MessagingScope scope;
  final MessagingAvailability availability;
  final List<NativeChatSummary> chats;
}

@immutable
class NativeMessagePage {
  NativeMessagePage({
    required this.scope,
    required this.chatId,
    required List<NativeMessage> messages,
    this.beforeCursor,
    this.partialHistory = true,
  }) : messages = List.unmodifiable(messages) {
    _bounded(chatId, MessagingLimits.identifier);
    if (beforeCursor != null) {
      _bounded(beforeCursor!, MessagingLimits.identifier);
    }
    if (messages.length > MessagingLimits.messages ||
        messages.map((message) => message.id).toSet().length !=
            messages.length) {
      throw ArgumentError('Invalid native message page.');
    }
  }

  final MessagingScope scope;
  final String chatId;

  /// Oldest to newest; the adapter must filter before constructing this page.
  final List<NativeMessage> messages;
  final String? beforeCursor;

  /// True for filtered/windowed history; never imply a full conversation export.
  final bool partialHistory;
}

/// Accepted means the official client accepted the action, never delivered/read.
enum NativeSendOutcome { accepted, rejected, uncertain }

@immutable
class NativeSendResult {
  NativeSendResult({
    required this.scope,
    required this.chatId,
    required this.actionId,
    required this.outcome,
  }) {
    _bounded(chatId, MessagingLimits.identifier);
    _bounded(actionId, MessagingLimits.identifier);
  }

  final MessagingScope scope;
  final String chatId;
  final String actionId;
  final NativeSendOutcome outcome;
}

enum MessagingFailure { unavailable, offline, locked, incompatible }

/// Safe fixed errors only: no client exceptions or private text in diagnostics.
class NativeMessagingException implements Exception {
  const NativeMessagingException(this.failure);
  final MessagingFailure failure;
  @override
  String toString() => 'Native messaging operation unavailable.';
}
