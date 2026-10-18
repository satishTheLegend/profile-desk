import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/design.dart';
import '../../app/localization.dart';
import '../../app/motion.dart';
import 'native_messaging_controller.dart';
import 'native_messaging_models.dart';
import 'native_messaging_port.dart';

/// A real Flutter messaging surface, intended below the account-level app bar.
/// The enclosing Scaffold must resize for the keyboard. [active] is a display
/// guard; the host still owns synchronous native-window privacy protection.
class NativeMessagingWorkspace extends StatefulWidget {
  const NativeMessagingWorkspace({
    super.key,
    required this.port,
    required this.scope,
    required this.onOpenOfficial,
    this.active = true,
    this.refreshRevision = 0,
  });

  final NativeMessagingPort port;
  final MessagingScope scope;
  final VoidCallback onOpenOfficial;
  final bool active;

  /// Advance only while this exact native host is foreground and unlocked.
  /// No polling is scheduled by this widget.
  final int refreshRevision;

  @override
  State<NativeMessagingWorkspace> createState() =>
      _NativeMessagingWorkspaceState();
}

class _NativeMessagingWorkspaceState extends State<NativeMessagingWorkspace> {
  late NativeMessagingController _controller;
  final _draft = TextEditingController();
  final _search = TextEditingController();
  final _composerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    _controller = NativeMessagingController(
      port: widget.port,
      scope: widget.scope,
    );
    _controller.addListener(_changed);
    if (widget.active) {
      unawaited(_controller.loadChats());
    } else {
      _controller.suspend();
    }
  }

  @override
  void didUpdateWidget(NativeMessagingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.port, widget.port)) {
      _controller.removeListener(_changed);
      _controller.dispose();
      _createController();
      return;
    }
    if (oldWidget.scope != widget.scope) {
      _composerFocus.unfocus();
      _controller.setScope(widget.scope);
      if (widget.active) unawaited(_controller.loadChats());
    }
    if (oldWidget.scope == widget.scope &&
        oldWidget.active == widget.active &&
        widget.active &&
        oldWidget.refreshRevision != widget.refreshRevision) {
      unawaited(_controller.refresh());
    }
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _controller.resume();
        unawaited(_controller.loadChats());
      } else {
        _composerFocus.unfocus();
        _controller.suspend();
      }
    }
  }

  void _changed() {
    if (!mounted) return;
    if (!_controller.active ||
        _controller.availability != MessagingAvailability.ready ||
        _controller.composerStatus == ComposerStatus.uncertain) {
      _composerFocus.unfocus();
    }
    if (_draft.text != _controller.draft) {
      _draft.value = TextEditingValue(
        text: _controller.draft,
        selection: TextSelection.collapsed(offset: _controller.draft.length),
      );
    }
    if (_search.text != _controller.query) {
      _search.value = TextEditingValue(text: _controller.query);
    }
    setState(() {});
  }

  void _back() {
    _composerFocus.unfocus();
    _controller.backToChats();
  }

  void _official() {
    _composerFocus.unfocus();
    // Clear before navigation: the owner may defer attaching the official view.
    // Returning requires an explicit active=false → true lifecycle transition.
    _controller.suspend();
    widget.onOpenOfficial();
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    _draft.dispose();
    _search.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = _controller.selectedChat;
    return PopScope<Object?>(
      canPop: chat == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && chat != null) _back();
      },
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: !widget.active
            ? _status(MessagingAvailability.locked)
            : Column(
                children: [
                  _header(chat),
                  Expanded(
                    child: chat == null ? _chatList() : _conversation(chat),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header(NativeChatSummary? chat) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
    child: Row(
      children: [
        if (chat != null)
          IconButton(
            key: const ValueKey('native-messaging-back'),
            tooltip: context.l10n.nativeMessagingBack,
            onPressed: _back,
            icon: Transform.rotate(
              angle: math.pi,
              child: const DeskIcon('arrow-right'),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              header: true,
              child: Text(
                chat?.title ?? context.l10n.nativeMessagingChats,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
        if (chat == null)
          IconButton(
            tooltip: context.l10n.nativeMessagingRefresh,
            onPressed: _controller.chatsState == MessagingLoadState.loading
                ? null
                : _controller.loadChats,
            icon: const DeskAnimatedIcon('refresh'),
          ),
        IconButton(
          tooltip: context.l10n.nativeMessagingOfficial,
          onPressed: _official,
          icon: const DeskAnimatedIcon('external-link'),
        ),
      ],
    ),
  );

  Widget _chatList() {
    if (_controller.chatsState == MessagingLoadState.loading &&
        _controller.chats.isEmpty) {
      return _loading(context.l10n.nativeMessagingLoading);
    }
    if (_controller.chatsState == MessagingLoadState.failed) {
      return _notice(
        context.l10n.nativeMessagingLoadFailed,
        action: _controller.loadChats,
      );
    }
    if (_controller.availability != MessagingAvailability.ready) {
      return _status(_controller.availability);
    }
    final chats = _controller.filteredChats;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            key: const ValueKey('native-messaging-search'),
            controller: _search,
            maxLength: MessagingLimits.title,
            decoration: InputDecoration(
              labelText: context.l10n.nativeMessagingSearch,
              counterText: '',
            ),
            onChanged: _controller.setQuery,
            textInputAction: TextInputAction.search,
          ),
        ),
        if (_controller.chatsState == MessagingLoadState.loading)
          const LinearProgressIndicator(),
        Expanded(
          child: chats.isEmpty
              ? _notice(
                  _controller.query.isEmpty
                      ? context.l10n.nativeMessagingEmpty
                      : context.l10n.nativeMessagingNoResults,
                  detail: _controller.query.isEmpty
                      ? context.l10n.nativeMessagingEmptyDetail
                      : context.l10n.nativeMessagingNoResultsDetail,
                  illustration: true,
                )
              : ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: chats.length,
                  separatorBuilder: (_, index) =>
                      const Divider(height: 1, indent: 76, endIndent: 16),
                  itemBuilder: (context, index) => _chatTile(chats[index]),
                ),
        ),
      ],
    );
  }

  Widget _chatTile(NativeChatSummary chat) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      key: ValueKey('native-chat-${chat.id}'),
      minVerticalPadding: 14,
      leading: ProfileMark(
        alias: chat.title,
        color: colors.primary.toARGB32(),
        size: 44,
      ),
      title: Text(chat.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: chat.preview == null
          ? null
          : Text(chat.preview!, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: chat.unreadCount == 0
          ? null
          : Semantics(
              label: context.l10n.nativeMessagingUnread,
              value: chat.unreadCount.toString(),
              child: ExcludeSemantics(
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ),
              ),
            ),
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        unawaited(_controller.selectChat(chat.id));
      },
    );
  }

  Widget _conversation(NativeChatSummary chat) => LayoutBuilder(
    builder: (context, constraints) => Column(
      children: [
        Expanded(child: _messageList()),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight * .65),
          child: SingleChildScrollView(
            key: const ValueKey('native-messaging-composer-scroll'),
            child: !chat.canSend
                ? _composerNotice(
                    context.l10n.nativeMessagingReadOnly,
                    official: true,
                  )
                : _composer(),
          ),
        ),
      ],
    ),
  );

  Widget _messageList() {
    if (_controller.messagesState == MessagingLoadState.loading) {
      return _loading(context.l10n.nativeMessagingLoadingMessages);
    }
    if (_controller.messagesState == MessagingLoadState.failed) {
      return _notice(
        context.l10n.nativeMessagingMessageFailed,
        action: _controller.loadMessages,
      );
    }
    final messages = _controller.messages;
    return ListView(
      key: ValueKey(('native-messages', _controller.selectedChat?.id)),
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      children: [
        ...messages.reversed.map(_bubble),
        if (messages.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              context.l10n.nativeMessagingNoMessages,
              textAlign: TextAlign.center,
            ),
          ),
        if (_controller.beforeCursor != null)
          TextButton(
            onPressed: _controller.loadingEarlier
                ? null
                : () => _controller.loadMessages(earlier: true),
            child: Text(context.l10n.nativeMessagingHistory),
          ),
        if (_controller.loadingEarlier) const LinearProgressIndicator(),
        if (_controller.earlierFailed)
          Text(
            context.l10n.nativeMessagingHistoryFailed,
            textAlign: TextAlign.center,
          ),
        if (_controller.partialHistory)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Text(
              context.l10n.nativeMessagingPartialHistory,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _bubble(NativeMessage message) {
    final colors = Theme.of(context).colorScheme;
    final delivery = switch (message.delivery) {
      NativeDeliveryState.unknown => null,
      NativeDeliveryState.pending => context.l10n.nativeMessagingPending,
      NativeDeliveryState.sent => context.l10n.nativeMessagingSent,
      NativeDeliveryState.delivered => context.l10n.nativeMessagingDelivered,
      NativeDeliveryState.read => context.l10n.nativeMessagingRead,
      NativeDeliveryState.failed => context.l10n.nativeMessagingFailed,
    };
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(message.sentAt.toLocal()));
    return Align(
      alignment: message.outgoing
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: .92,
        child: Align(
          alignment: message.outgoing
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            key: ValueKey('native-message-${message.id}'),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.outgoing
                  ? colors.primaryContainer
                  : colors.surfaceContainerLowest,
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .65),
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.kind == NativeMessageKind.text)
                  SelectableText(
                    message.body!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                else
                  TextButton(
                    onPressed: _official,
                    child: Text(context.l10n.nativeMessagingUnsupportedMessage),
                  ),
                const SizedBox(height: 4),
                Text(
                  [
                    time,
                    if (message.outgoing && delivery != null) delivery,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    final status = _controller.composerStatus;
    final notice = switch (status) {
      ComposerStatus.editing => null,
      ComposerStatus.sending => context.l10n.nativeMessagingSending,
      ComposerStatus.rejected => context.l10n.nativeMessagingRejected,
      ComposerStatus.uncertain => context.l10n.nativeMessagingUncertain,
      ComposerStatus.accepted => context.l10n.nativeMessagingAccepted,
    };
    // On very short keyboard viewports keep feedback in the scrollable history,
    // and reserve the bottom area for the reachable native input/action.
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (notice != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: _composerNotice(
                    notice,
                    official: status == ComposerStatus.uncertain,
                  ),
                ),
              ),
            if (status == ComposerStatus.uncertain)
              TextButton(
                onPressed: _controller.clearUncertainDraft,
                child: Text(context.l10n.nativeMessagingClearUncertain),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('native-messaging-composer'),
                      controller: _draft,
                      focusNode: _composerFocus,
                      enabled: _controller.canCompose,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: MessagingLimits.draft,
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) =>
                              newValue.text.length <= MessagingLimits.draft
                              ? newValue
                              : oldValue,
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: context.l10n.nativeMessagingMessage,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      enableSuggestions: false,
                      autocorrect: false,
                      enableIMEPersonalizedLearning: false,
                      onChanged: _controller.setDraft,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    key: const ValueKey('native-messaging-send'),
                    tooltip: context.l10n.nativeMessagingSend,
                    onPressed: _controller.canSend ? _controller.send : null,
                    icon: const DeskAnimatedIcon('arrow-up'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerNotice(String text, {bool official = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
        if (official)
          TextButton(
            onPressed: _official,
            child: Text(context.l10n.nativeMessagingOfficial),
          ),
      ],
    ),
  );

  Widget _loading(String label) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    ),
  );

  Widget _status(MessagingAvailability availability) => switch (availability) {
    MessagingAvailability.ready => const SizedBox.shrink(),
    MessagingAvailability.linkRequired => _notice(
      context.l10n.nativeMessagingLink,
      detail: context.l10n.nativeMessagingLinkDetail,
      official: true,
    ),
    MessagingAvailability.locked => _notice(
      context.l10n.nativeMessagingLocked,
      detail: context.l10n.nativeMessagingLockedDetail,
    ),
    MessagingAvailability.offline => _notice(
      context.l10n.nativeMessagingOffline,
      detail: context.l10n.nativeMessagingOfflineDetail,
      action: _controller.loadChats,
    ),
    MessagingAvailability.unsupported => _notice(
      context.l10n.nativeMessagingUnsupported,
      detail: context.l10n.nativeMessagingUnsupportedDetail,
      official: true,
    ),
  };

  Widget _notice(
    String title, {
    String? detail,
    VoidCallback? action,
    bool official = false,
    bool illustration = false,
  }) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration)
              const DeskScene(kind: DeskSceneKind.accounts, size: 112),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(detail, textAlign: TextAlign.center),
              ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: action,
                  child: Text(context.l10n.nativeMessagingTryAgain),
                ),
              ),
            if (official)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(
                  onPressed: _official,
                  child: Text(context.l10n.nativeMessagingOfficial),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
