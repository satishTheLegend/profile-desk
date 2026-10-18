import 'native_messaging_models.dart';

/// The native implementation must validate ownership, foreground/unlocked state,
/// exact origin, visibility, size limits and schema on every operation. These
/// methods do not grant a generic script/selector/network capability.
abstract interface class NativeMessagingPort {
  Future<NativeChatSnapshot> loadChats(MessagingScope scope);

  Future<NativeMessagePage> loadMessages(
    MessagingScope scope, {
    required String chatId,
    String? beforeCursor,
  });

  /// A unique action ID is supplied for one explicit user gesture. Implementors
  /// must not automatically replay an action or report a timeout as rejection.
  Future<NativeSendResult> sendText(
    MessagingScope scope, {
    required String chatId,
    required String text,
    required String actionId,
  });
}
