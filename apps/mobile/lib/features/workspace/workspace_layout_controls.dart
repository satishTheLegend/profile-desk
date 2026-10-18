import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:session_contract/session_contract.dart';

import '../../app/design.dart';
import '../../app/localization.dart';
import '../../app/providers.dart';
import 'workspace_back_handler.dart';

/// Recreated for each owned view. Commands contain no webpage script or content.
/// Feedback describes a completed action and expires; it is not a live status.
class WorkspaceLayoutControls extends ConsumerStatefulWidget {
  const WorkspaceLayoutControls({super.key, required this.view});
  final ViewHandle view;

  @override
  ConsumerState<WorkspaceLayoutControls> createState() =>
      _WorkspaceLayoutControlsState();
}

class _WorkspaceLayoutControlsState
    extends ConsumerState<WorkspaceLayoutControls> {
  bool _busy = false;
  int _request = 0;
  String? _feedback;
  bool _offerOriginal = false;
  Timer? _feedbackTimer;
  late WorkspaceViewIdentity _owner;
  bool _routeCurrent = false;

  @override
  void initState() {
    super.initState();
    _owner = workspaceViewIdentity(widget.view);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) == true;
    if (_routeCurrent && !current) {
      // Returning to this route cannot make an old command result eligible.
      _request++;
      _busy = false;
      _feedback = null;
      _offerOriginal = false;
      _feedbackTimer?.cancel();
    }
    _routeCurrent = current;
  }

  @override
  void didUpdateWidget(WorkspaceLayoutControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    final owner = workspaceViewIdentity(widget.view);
    if (owner != _owner) {
      _owner = owner;
      _request++;
      _busy = false;
      _feedback = null;
      _offerOriginal = false;
      _feedbackTimer?.cancel();
    }
  }

  bool _owns(int request, WorkspaceViewIdentity owner) =>
      mounted &&
      request == _request &&
      owner == workspaceViewIdentity(widget.view) &&
      _routeCurrent &&
      ModalRoute.isCurrentOf(context) == true;

  void _showFeedback(WorkspacePresentation? presentation) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedback = switch (presentation) {
        WorkspacePresentation.original =>
          context.l10n.workspacePresentationOriginalSelected,
        WorkspacePresentation.list =>
          context.l10n.workspacePresentationListShown,
        WorkspacePresentation.menu =>
          context.l10n.workspacePresentationMenuBackHint,
        WorkspacePresentation.detail =>
          context.l10n.workspacePresentationDetailUnchanged,
        WorkspacePresentation.unavailable =>
          context.l10n.workspacePresentationUnavailable,
        null => context.l10n.workspacePresentationCheckFailed,
      };
      _offerOriginal =
          presentation == null ||
          presentation == WorkspacePresentation.unavailable ||
          presentation == WorkspacePresentation.detail;
    });
    _feedbackTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _feedback = null;
          _offerOriginal = false;
        });
      }
    });
  }

  Future<void> _command({required bool original}) async {
    if (_busy || ModalRoute.of(context)?.isCurrent != true) return;
    final view = copyWorkspaceView(widget.view);
    final owner = workspaceViewIdentity(view);
    final request = ++_request;
    final engine = ref.read(engineProvider);
    _feedbackTimer?.cancel();
    setState(() {
      _busy = true;
      _feedback = null;
      _offerOriginal = false;
    });
    try {
      if (original) {
        await engine
            .setWorkspaceLayout(view, WorkspaceLayout.original)
            .timeout(const Duration(seconds: 3));
      } else {
        await engine
            .showWorkspaceList(view)
            .timeout(const Duration(seconds: 3));
      }
      if (!_owns(request, owner)) return;
      final presentation = await engine
          .getWorkspacePresentation(view)
          .timeout(const Duration(seconds: 3));
      if (!_owns(request, owner)) return;
      _showFeedback(presentation);
    } catch (_) {
      if (_owns(request, owner)) _showFeedback(null);
    } finally {
      if (mounted &&
          request == _request &&
          owner == workspaceViewIdentity(widget.view)) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _request++;
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_feedback != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 132),
                child: SingleChildScrollView(
                  child: Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_feedback!),
                          if (_offerOriginal)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _command(original: true),
                              child: Text(
                                context.l10n.workspacePresentationUseOriginal,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : () => _command(original: false),
                  icon: const RotatedBox(
                    quarterTurns: 2,
                    child: DeskIcon('arrow-right', size: 20),
                  ),
                  label: Text(context.l10n.workspaceChatsMenu),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _command(original: true),
                  child: Text(context.l10n.workspaceOriginalLayout),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
