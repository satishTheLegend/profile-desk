import '../../app/localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/motion.dart';
import '../../app/providers.dart';

/// Covers every route, including account metadata and settings, on native lock.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(sessionProvider).value?.locked ?? false;
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: locked,
          child: TickerMode(
            enabled: !locked,
            child: AbsorbPointer(absorbing: locked, child: widget.child),
          ),
        ),
        if (locked)
          Positioned.fill(
            child: Material(
              // This cover is immediate and opaque. Animate only its decorative
              // illustration, never the surface that protects the route below.
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: DeskScene(
                              kind: DeskSceneKind.privacy,
                              size: 160,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Semantics(
                            header: true,
                            child: Text(
                              context.l10n.yourAccountsAreLocked,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.useDeviceAuthenticationToReturnTo,
                            textAlign: TextAlign.center,
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 28),
                          FilledButton.icon(
                            icon: const DeskIcon('lock'),
                            onPressed: _busy
                                ? null
                                : () async {
                                    setState(() {
                                      _busy = true;
                                      _error = null;
                                    });
                                    try {
                                      final success = await ref
                                          .read(coordinatorProvider)
                                          .unlock();
                                      if (mounted && !success) {
                                        setState(
                                          () => _error = context
                                              .l10n
                                              .authenticationDidNotCompleteYourAccounts,
                                        );
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        setState(
                                          () => _error = context
                                              .l10n
                                              .authenticationIsUnavailableCheckDeviceSettings,
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _busy = false);
                                      }
                                    }
                                  },
                            label: Text(
                              _busy
                                  ? context.l10n.authenticating
                                  : context.l10n.unlock,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
