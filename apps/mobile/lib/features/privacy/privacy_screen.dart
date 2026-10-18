import '../../app/localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/design.dart';
import '../../app/motion.dart';
import '../../app/providers.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appProvider).requireValue;
    final prefs = snapshot.preferences;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyAppearance)),
      body: ContentColumn(
        children: [
          DeskEntrance(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final heading = Semantics(
                  header: true,
                  child: Text(
                    context.l10n.localAccessYourControl,
                    style: theme.textTheme.headlineLarge,
                  ),
                );
                if (constraints.maxWidth >= 500 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 21) {
                  return Row(
                    children: [
                      Expanded(child: heading),
                      const DeskScene(kind: DeskSceneKind.privacy, size: 144),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DeskScene(kind: DeskSceneKind.privacy, size: 120),
                    const SizedBox(height: 12),
                    heading,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.anyoneWhoCanUnlockThisApp),
          const SizedBox(height: 28),
          DeskSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DeskAnimatedIcon(
                    'shield-lock',
                    active: prefs.lockEnabled,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.requireDeviceAuthentication),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      snapshot.capabilities.authenticationAvailable
                          ? context.l10n.lockWhenTheAppLeavesThe
                          : context.l10n.setUpSupportedAuthenticationInDevice,
                    ),
                  ),
                  value: prefs.lockEnabled,
                  onChanged: (value) => guardAction(context, () async {
                    await ref
                        .read(appProvider.notifier)
                        .preferences(
                          copyPreferences(prefs, lockEnabled: value),
                        );
                  }),
                ),
                const Divider(height: 32),
                Semantics(
                  header: true,
                  child: Text(
                    context.l10n.appearance,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in {
                      'system': context.l10n.deviceSetting,
                      'light': context.l10n.light,
                      'dark': context.l10n.dark,
                    }.entries)
                      ChoiceChip(
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        label: Text(entry.value),
                        selected: prefs.theme == entry.key,
                        onSelected: (_) => guardAction(
                          context,
                          () => ref
                              .read(appProvider.notifier)
                              .preferences(
                                copyPreferences(prefs, theme: entry.key),
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _PrivacyNote(
            icon: 'device-mobile',
            title: context.l10n.whatStaysOnThisDevice,
            body: context.l10n.profileNamesPreferencesAndBrowserSessions,
          ),
          _PrivacyNote(
            icon: 'lock',
            title: context.l10n.backgroundProtection,
            body: context.l10n.aNativePrivacyCoverHidesAccount,
          ),
          _PrivacyNote(
            icon: 'file-download',
            title: context.l10n.permissionsAndFiles,
            body: context.l10n.fileAccessIsRequestedWhenYou,
          ),
          const Divider(height: 16),
          const SizedBox(height: 8),
          DeskTapFeedback(
            child: TextButton.icon(
              onPressed: () => guardAction(
                context,
                () => ref.read(engineProvider).exportDiagnostics(),
              ),
              icon: const DeskIcon('file-download'),
              label: Text(context.l10n.reviewAndShareSafeDiagnostics),
            ),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.diagnosticsContainTechnicalVersionsCapabilityFlags),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

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
      ],
    ),
  );
}
