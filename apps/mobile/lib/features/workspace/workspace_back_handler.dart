import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:session_contract/session_contract.dart';

import '../../app/localization.dart';
import '../../app/providers.dart';

/// A value identity remains stable even if a generated ViewHandle is mutated.
typedef WorkspaceViewIdentity = (String, String, String, int);

WorkspaceViewIdentity workspaceViewIdentity(ViewHandle view) => (
  view.profileId,
  view.viewInstanceId,
  view.operationId,
  view.selectionGeneration,
);

ViewHandle copyWorkspaceView(ViewHandle view) => ViewHandle(
  profileId: view.profileId,
  viewInstanceId: view.viewInstanceId,
  operationId: view.operationId,
  selectionGeneration: view.selectionGeneration,
);

/// Owns Android Back only for the supplied visible, unlocked view. The separate
/// zero-content owner is removed when [view] is null without remounting [child]
/// (in particular, without detaching/recreating its platform WebView).
class WorkspaceBackHandler extends StatelessWidget {
  const WorkspaceBackHandler({super.key, required this.child, this.view});
  final ViewHandle? view;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      if (view != null && Theme.of(context).platform == TargetPlatform.android)
        Positioned.fill(
          child: _OwnedWorkspaceBack(
            key: ValueKey(workspaceViewIdentity(view!)),
            view: copyWorkspaceView(view!),
          ),
        ),
    ],
  );
}

class _OwnedWorkspaceBack extends ConsumerStatefulWidget {
  const _OwnedWorkspaceBack({super.key, required this.view});
  final ViewHandle view;

  @override
  ConsumerState<_OwnedWorkspaceBack> createState() =>
      _OwnedWorkspaceBackState();
}

class _OwnedWorkspaceBackState extends ConsumerState<_OwnedWorkspaceBack> {
  bool _busy = false;
  bool _allowRoutePop = false;
  int _request = 0;
  String? _hint;
  Timer? _hintTimer;
  bool _routeCurrent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) == true;
    if (_routeCurrent && !current) {
      // A push/pop round trip must not revive an earlier Back request.
      _request++;
      _busy = false;
      _allowRoutePop = false;
      _hint = null;
      _hintTimer?.cancel();
    }
    _routeCurrent = current;
  }

  bool _owns(int request, WorkspaceViewIdentity owner) =>
      mounted &&
      request == _request &&
      workspaceViewIdentity(widget.view) == owner &&
      _routeCurrent &&
      ModalRoute.isCurrentOf(context) == true;

  void _showHint(String hint) {
    _hintTimer?.cancel();
    setState(() => _hint = hint);
    _hintTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  Future<void> _handleBack() async {
    if (_busy || !mounted || ModalRoute.of(context)?.isCurrent != true) return;
    _busy = true;
    final request = ++_request;
    final view = copyWorkspaceView(widget.view);
    final owner = workspaceViewIdentity(view);
    _hintTimer?.cancel();
    setState(() => _hint = null);
    try {
      // Android normally consumes Back in the IME first. If the callback still
      // reaches Flutter while an inset is visible, hide that keyboard only.
      if (MediaQuery.viewInsetsOf(context).bottom > 0) {
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        return;
      }
      final engine = ref.read(engineProvider);
      final presentation = await engine
          .getWorkspacePresentation(view)
          .timeout(const Duration(seconds: 3));
      if (!mounted || !_owns(request, owner)) return;
      switch (presentation) {
        case WorkspacePresentation.detail:
          await engine
              .showWorkspaceList(view)
              .timeout(const Duration(seconds: 3));
        case WorkspacePresentation.menu:
          _showHint(context.l10n.workspacePresentationMenuBackHint);
        case WorkspacePresentation.original:
        case WorkspacePresentation.list:
        case WorkspacePresentation.unavailable:
          await _normalBack(request, owner);
      }
    } catch (_) {
      if (mounted && _owns(request, owner)) {
        _showHint(context.l10n.workspacePresentationBackCheckFailed);
      }
    } finally {
      if (mounted && request == _request) {
        _busy = false;
        if (_allowRoutePop) setState(() => _allowRoutePop = false);
      }
    }
  }

  Future<void> _normalBack(int request, WorkspaceViewIdentity owner) async {
    if (!_owns(request, owner)) return;
    final navigator = Navigator.of(context);
    setState(() => _allowRoutePop = true);
    // Register the new PopScope disposition before invoking ordinary routing.
    await WidgetsBinding.instance.endOfFrame;
    if (!_owns(request, owner)) return;
    final handled = await navigator.maybePop();
    if (!handled && _owns(request, owner)) {
      // This is reached only from the explicit Android Back gesture above.
      await SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _request++;
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _allowRoutePop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_handleBack());
    },
    child: _hint == null
        ? const SizedBox.shrink()
        : IgnorePointer(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    kToolbarHeight + 8,
                    16,
                    16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Material(
                      color: Theme.of(context).colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _hint!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onInverseSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
  );
}
