import '../../app/localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:session_contract/session_contract.dart';

import '../../app/actions.dart';
import '../../app/design.dart';
import '../../app/motion.dart';
import '../../app/providers.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref.watch(appProvider).value?.capabilities;
    final network =
        ref.watch(sessionProvider).value?.network ?? NetworkObservation.unknown;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.helpCompatibility)),
      body: ContentColumn(
        children: [
          DeskEntrance(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DeskAnimatedIcon(
                    'device-mobile',
                    active: true,
                    size: 28,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text(
                    context.l10n.linkWithTheOfficialApp,
                    style: theme.textTheme.headlineLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DeskSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, step) in [
                  context.l10n.linkingStepCreateProfile,
                  context.l10n.linkingStepOpenDevices,
                  context.l10n.linkingStepScanProfile,
                  context.l10n.linkingStepConfirmLabel,
                ].indexed)
                  _LinkingStep(number: index + 1, text: step, last: index == 3),
                const SizedBox(height: 12),
                _HelpLink(
                  topic: HelpTopic.linking,
                  label: context.l10n.officialLinkingHelp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _HelpSection(
            icon: 'device-mobile',
            title: context.l10n.usingTheSamePhone,
            body: context.l10n.youCannotScanAQROn,
          ),
          _HelpSection(
            icon: 'apps',
            title: context.l10n.savedDoesNotMeanConnected,
            body: context.l10n.onlyTheSelectedAccountHasA,
          ),
          _HelpSection(
            icon: 'refresh',
            title: context.l10n.whenSomethingStopsWorking,
            body: context.l10n.checkYourConnectionAndReloadThe,
            action: _HelpLink(
              topic: HelpTopic.serviceHelp,
              label: context.l10n.officialConnectionHelp,
            ),
          ),
          _HelpSection(
            icon: 'shield-lock',
            title: context.l10n.removeAccessRemotely,
            body: context.l10n.inThePrimaryWhatsAppAppOpen,
            action: _HelpLink(
              topic: HelpTopic.remoteUnlink,
              label: context.l10n.officialLinkedDeviceHelp,
            ),
          ),
          const Divider(height: 32),
          Semantics(
            header: true,
            child: Text(
              context.l10n.thisDevice,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          DeskSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Detail(context.l10n.networkPath, switch (network) {
                  NetworkObservation.unknown => context.l10n.networkUnknown,
                  NetworkObservation.offline =>
                    context.l10n.networkDisconnected,
                  NetworkObservation.reachable =>
                    context.l10n.networkPathAvailable,
                }),
                if (capabilities != null) ...[
                  _Detail(
                    context.l10n.platform,
                    '${capabilities.platform} ${capabilities.osVersion}',
                  ),
                  _Detail(
                    context.l10n.browserProvider,
                    capabilities.providerVersion,
                  ),
                  _Detail(
                    context.l10n.isolatedProfiles,
                    capabilities.multiProfile
                        ? context.l10n.available
                        : context.l10n.unavailable,
                  ),
                  _Detail(
                    context.l10n.scopedCleanup,
                    capabilities.scopedDeletion
                        ? context.l10n.available
                        : context.l10n.unavailable,
                  ),
                  _Detail(
                    context.l10n.nativeDownloads,
                    capabilities.downloadsSupported
                        ? context.l10n.availablePathsRequireServiceValidation
                        : context.l10n.notSupportedByThisEngine,
                  ),
                  _Detail(
                    context.l10n.cameraMicrophoneAndCalls,
                    context.l10n.notEnabled,
                    last: true,
                  ),
                  if (capabilities.reason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(capabilities.reason!),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(context.l10n.profileDeskIsAnIndependentCompanion),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Profile Desk',
              applicationVersion: '0.1.0',
            ),
            child: Text(context.l10n.openSourceLicenses),
          ),
          DeskTapFeedback(
            child: TextButton.icon(
              onPressed: () => guardAction(
                context,
                () => ref.read(engineProvider).exportDiagnostics(),
              ),
              icon: const DeskIcon('file-download'),
              label: Text(context.l10n.shareSafeDiagnostics),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkingStep extends StatelessWidget {
  const _LinkingStep({
    required this.number,
    required this.text,
    required this.last,
  });
  final int number;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$number',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final String icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: DeskIcon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(body),
        if (action != null) ...[const SizedBox(height: 8), action!],
      ],
    ),
  );
}

class _HelpLink extends ConsumerWidget {
  const _HelpLink({required this.topic, required this.label});
  final HelpTopic topic;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DeskTapFeedback(
    child: TextButton.icon(
      onPressed: () =>
          guardAction(context, () => ref.read(engineProvider).openHelp(topic)),
      icon: const DeskIcon('external-link'),
      label: Text(label),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 8, bottom: last ? 0 : 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        SelectableText(value),
        if (!last) const Divider(height: 24),
      ],
    ),
  );
}
