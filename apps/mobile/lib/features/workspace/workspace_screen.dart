import '../../app/localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:session_contract/session_contract.dart';
import 'package:session_engine/session_engine.dart';

import '../../app/actions.dart';
import '../../app/design.dart';
import '../../app/motion.dart';
import '../../app/providers.dart';
import '../accounts/account_screens.dart';
import '../help/help_screen.dart';
import '../privacy/privacy_screen.dart';
import '../backup/account_setup_screen.dart';
import 'workspace_layout_controls.dart';
import 'workspace_back_handler.dart';

class WorkspaceScreen extends ConsumerWidget {
  const WorkspaceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final session =
        ref.watch(sessionProvider).value ?? ref.read(coordinatorProvider).state;
    final profiles =
        ref.watch(profilesProvider).value ??
        ref.read(accountsProvider).profiles;
    final selected = profiles
        .where((p) => p.id == session.selectedProfileId)
        .firstOrNull;
    final ownsVisibleWorkspace =
        app.value?.preferences.welcomeSeen == true &&
        app.value?.capabilities.supported == true &&
        !session.locked &&
        !session.covered &&
        session.phase == WorkspacePhase.visible &&
        session.view != null;
    return WorkspaceBackHandler(
      view: ownsVisibleWorkspace ? session.view : null,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: app.value?.preferences.welcomeSeen != true || session.locked
              ? Text(context.l10n.profileDesk)
              : Builder(
                  builder: (anchorContext) => Semantics(
                    label: context.l10n.selectAccountValue(
                      (selected?.alias ?? context.l10n.noAccountSelected)
                          .toString(),
                    ),
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: session.locked
                          ? null
                          : () => _selector(
                              context,
                              ref,
                              profiles,
                              anchorContext: anchorContext,
                            ),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected != null)
                              ProfileMark(
                                alias: selected.alias,
                                color: selected.color,
                                size: 34,
                              )
                            else
                              DeskIcon('apps'),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                selected?.alias ?? context.l10n.yourAccounts,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            SizedBox(width: 8),
                            DeskIcon('chevron-down', size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          actions: [
            if (app.value?.preferences.lockEnabled == true && !session.locked)
              IconButton(
                tooltip: context.l10n.lockApp,
                icon: const DeskAnimatedIcon('lock'),
                onPressed: () => guardAction(
                  context,
                  () => ref.read(coordinatorProvider).lock(),
                ),
              ),
            PopupMenuButton<String>(
              tooltip: context.l10n.appMenu,
              enabled: !session.locked,
              icon: const DeskAnimatedIcon('dots-vertical'),
              onSelected: (value) {
                if (value == 'reload') {
                  guardAction(context, () async {
                    if (await confirmAction(
                          context,
                          title: context.l10n.reloadThisAccount,
                          message:
                              context.l10n.reloadingClosesTheCurrentPageAnd,
                          action: context.l10n.reload,
                        ) &&
                        context.mounted) {
                      await ref.read(coordinatorProvider).reload();
                    }
                  });
                  return;
                }
                final screen = switch (value) {
                  'accounts' => AccountManagerScreen(),
                  'privacy' => PrivacyScreen(),
                  'backup' => AccountSetupScreen(),
                  _ => HelpScreen(),
                };
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => screen),
                );
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: app.hasValue,
                  value: 'accounts',
                  child: _MenuLabel('apps', context.l10n.manageAccounts),
                ),
                PopupMenuItem(
                  value: 'reload',
                  enabled: selected != null,
                  child: _MenuLabel('refresh', context.l10n.reloadSelectedPage),
                ),
                PopupMenuItem(
                  enabled: app.hasValue,
                  value: 'privacy',
                  child: _MenuLabel(
                    'shield-lock',
                    context.l10n.privacyAppearance,
                  ),
                ),
                PopupMenuItem(
                  enabled: app.hasValue,
                  value: 'backup',
                  child: _MenuLabel(
                    'file-download',
                    context.l10n.accountSetupBackup,
                  ),
                ),
                PopupMenuItem(
                  value: 'help',
                  child: _MenuLabel(
                    'help-circle',
                    context.l10n.helpCompatibility,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ownsVisibleWorkspace)
              WorkspaceLayoutControls(
                key: ValueKey(workspaceViewIdentity(session.view!)),
                view: session.view!,
              ),
            if (!session.locked &&
                (session.network == NetworkObservation.offline ||
                    session.transferActive))
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (session.network == NetworkObservation.offline)
                          Semantics(
                            liveRegion: true,
                            child: Text(context.l10n.networkOffline),
                          ),
                        if (session.transferActive) ...[
                          LinearProgressIndicator(
                            value: session.transferProgress,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    session.transferProgress == null
                                        ? context.l10n.fileActionInProgress
                                        : context.l10n.fileProgress(
                                            (session.transferProgress! * 100)
                                                .round()
                                                .toString(),
                                          ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => guardAction(
                                  context,
                                  () =>
                                      ref.read(engineProvider).cancelTransfer(),
                                ),
                                child: Text(context.l10n.cancelFileAction),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: app.when(
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, _) => _StatePanel(
              icon: 'shield-lock',
              title: context.l10n.couldnTStartTheSessionEngine,
              body: friendlyError(context, error),
              action: context.l10n.tryAgain,
              onAction: () => ref.invalidate(appProvider),
            ),
            data: (snapshot) {
              if (!snapshot.preferences.welcomeSeen) {
                return _Welcome(
                  onContinue: () => guardAction(
                    context,
                    () => ref
                        .read(appProvider.notifier)
                        .preferences(
                          copyPreferences(
                            snapshot.preferences,
                            welcomeSeen: true,
                          ),
                        ),
                  ),
                );
              }
              return Stack(
                children: [
                  if (snapshot.capabilities.supported)
                    Positioned.fill(child: NativeSessionView()),
                  if (session.locked)
                    SizedBox.shrink()
                  else if (!snapshot.capabilities.supported)
                    Positioned.fill(
                      child: _StatePanel(
                        icon: 'device-mobile',
                        title: context.l10n.thisBrowserNeedsAnUpdate,
                        body:
                            snapshot.capabilities.reason ??
                            context.l10n.isolatedProfilesAndScopedCleanupAre,
                        action: context.l10n.compatibilityDetails,
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => HelpScreen()),
                        ),
                      ),
                    )
                  else if (selected == null)
                    Positioned.fill(
                      child: _Empty(
                        profiles: profiles,
                        onAdd: () => showAccountForm(context, ref),
                        onSelect: () => _selector(context, ref, profiles),
                        onOpen: (profile) => guardAction(
                          context,
                          () => selectAccount(context, ref, profile),
                        ),
                      ),
                    )
                  else if (session.phase == WorkspacePhase.failed)
                    Positioned.fill(
                      child: _StatePanel(
                        icon: 'refresh',
                        title: context.l10n.thisAccountNeedsAttention,
                        body: session.requiresReconciliation
                            ? context.l10n.anEarlierOperationIsStillBeing
                            : context.l10n.thePageCouldNotFinishOpening,
                        action: context.l10n.retryThisAccount,
                        onAction: () => guardAction(
                          context,
                          () =>
                              ref.read(coordinatorProvider).select(selected.id),
                        ),
                      ),
                    )
                  else if (session.covered)
                    Positioned.fill(
                      child: _StatePanel(
                        icon: 'shield-lock',
                        title: context.l10n.openingValue(
                          (selected.alias).toString(),
                        ),
                        body: context.l10n.preparingThisAccountSSeparateBrowser,
                        busy: true,
                        scene: DeskSceneKind.opening,
                      ),
                    ),
                  if (selected != null &&
                      !session.covered &&
                      selected.observation != AuthObservation.userConfirmed)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Material(
                        elevation: 3,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.linkWithYourPrimaryPhoneThen,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProfileSettingsScreen(
                                      profileId: selected.id,
                                    ),
                                  ),
                                ),
                                child: Text(context.l10n.details),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selector(
    BuildContext context,
    WidgetRef ref,
    List<AccountProfile> profiles, {
    BuildContext? anchorContext,
  }) async {
    final width = MediaQuery.sizeOf(context).width;
    final anchor = anchorContext?.findRenderObject();
    final origin = anchor is RenderBox
        ? anchor.localToGlobal(Offset.zero)
        : Offset.zero;
    final top = anchor is RenderBox
        ? origin.dy + anchor.size.height + 8
        : MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

    final selected = await (width >= 700
        ? showDialog<String>(
            context: context,
            builder: (context) => Dialog(
              alignment: Alignment.topLeft,
              insetPadding: EdgeInsets.fromLTRB(16, top, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400, maxHeight: 600),
                child: _Selector(
                  profiles: profiles,
                  selectedId: ref
                      .read(coordinatorProvider)
                      .state
                      .selectedProfileId,
                ),
              ),
            ),
          )
        : showModalBottomSheet<String>(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            builder: (_) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .8,
              ),
              child: _Selector(
                profiles: profiles,
                selectedId: ref
                    .read(coordinatorProvider)
                    .state
                    .selectedProfileId,
              ),
            ),
          ));
    if (!context.mounted || selected == null) return;
    if (selected == 'add') {
      await showAccountForm(context, ref);
      return;
    }
    final profile = profiles.where((p) => p.id == selected).firstOrNull;
    if (profile != null) {
      await guardAction(context, () => selectAccount(context, ref, profile));
    }
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel(this.icon, this.label);
  final String icon, label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      DeskIcon(icon, size: 20),
      const SizedBox(width: 12),
      Flexible(child: Text(label)),
    ],
  );
}

class _Selector extends StatelessWidget {
  const _Selector({required this.profiles, required this.selectedId});
  final List<AccountProfile> profiles;
  final String? selectedId;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.switchAccount,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${reservedSlots(profiles)}/10',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
    final tiles = [
      for (final p in profiles)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: DeskTapFeedback(
            enabled: p.state == StoreState.available,
            child: ListTile(
              enabled: p.state == StoreState.available,
              selectedTileColor: colors.primaryContainer,
              leading: ProfileMark(alias: p.alias, color: p.color, size: 46),
              title: Text(
                p.alias,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(profileStatus(context, p)),
              selected: selectedId == p.id,
              trailing: DeskAnimatedIcon(
                selectedId == p.id ? 'check' : 'arrow-right',
                active: selectedId == p.id,
                size: 20,
                color: colors.primary,
              ),
              onTap: () => Navigator.pop(context, p.id),
            ),
          ),
        ),
    ];
    final footer = Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: DeskTapFeedback(
          enabled: reservedSlots(profiles) < 10,
          child: FilledButton.icon(
            onPressed: reservedSlots(profiles) >= 10
                ? null
                : () => Navigator.pop(context, 'add'),
            icon: const DeskAnimatedIcon('plus'),
            label: Text(context.l10n.addAccount),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep every action reachable when larger type or a short viewport would
        // otherwise let the fixed header/footer consume the account list.
        if (MediaQuery.textScalerOf(context).scale(16) >= 24 ||
            constraints.maxHeight < 400) {
          return ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              header,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: tiles),
              ),
              footer,
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shrinkWrap: true,
                children: tiles,
              ),
            ),
            footer,
          ],
        );
      },
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onContinue});
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContentColumn(
      maxWidth: 760,
      children: [
        DeskSurface(
          emphasized: true,
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                context.l10n.yourAccountsKeptSeparate,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              );
              const scene = DeskScene(kind: DeskSceneKind.accounts, size: 168);
              return constraints.maxWidth >= 540 &&
                      MediaQuery.textScalerOf(context).scale(16) < 24
                  ? Row(
                      children: [
                        Expanded(child: title),
                        scene,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(alignment: Alignment.center, child: scene),
                        const SizedBox(height: 8),
                        title,
                      ],
                    );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.aQuietWorkspaceForUpTo,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        _Fact(
          'shield-lock',
          context.l10n.separateSessions,
          context.l10n.eachProfileHasItsOwnPersistent,
        ),
        _Fact(
          'device-mobile',
          context.l10n.linkWithYourPrimaryPhone,
          context.l10n.accountOwnersApproveLinkingInThe,
        ),
        _Fact(
          'refresh',
          context.l10n.oneAccountOpenAtATime,
          context.l10n.inactiveAccountsAreNotMonitoredSwitching,
        ),
        const SizedBox(height: 4),
        DeskTapFeedback(
          child: FilledButton.icon(
            onPressed: onContinue,
            icon: const DeskAnimatedIcon('arrow-right'),
            label: Text(context.l10n.setUpYourWorkspace),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context
              .l10n
              .independentCompanionPrototypeEmbeddedServiceCompatibility,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.title, this.body);
  final String icon, title, body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: DeskIcon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.profiles,
    required this.onAdd,
    required this.onSelect,
    required this.onOpen,
  });
  final List<AccountProfile> profiles;
  final VoidCallback onAdd, onSelect;
  final ValueChanged<AccountProfile> onOpen;
  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return _StatePanel(
        icon: 'apps',
        scene: DeskSceneKind.accounts,
        title: context.l10n.aPlaceForEveryAccount,
        body: context.l10n.startWithOneAccountGiveIt,
        action: context.l10n.linkYourFirstAccount,
        onAction: onAdd,
      );
    }
    final colors = Theme.of(context).colorScheme;
    // This surface is an immediate opaque cover above the native session host.
    // Only its decorative artwork animates; account data never cross-fades.
    return ColoredBox(
      color: colors.surface,
      child: ContentColumn(
        maxWidth: 840,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final intro = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.l10n.chooseYourWorkspace,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.yourSavedProfilesAreReadyTo,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              );
              return constraints.maxWidth >= 640 &&
                      MediaQuery.textScalerOf(context).scale(16) < 24
                  ? Row(
                      children: [
                        Expanded(child: intro),
                        const SizedBox(width: 24),
                        const DeskScene(
                          kind: DeskSceneKind.accounts,
                          size: 148,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DeskScene(
                          kind: DeskSceneKind.accounts,
                          size: 156,
                        ),
                        const SizedBox(height: 12),
                        intro,
                      ],
                    );
            },
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth >= 640 &&
                      MediaQuery.textScalerOf(context).scale(16) < 24
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in profiles)
                    SizedBox(
                      width: width,
                      child: _QuickAccount(profile: p, onOpen: () => onOpen(p)),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onSelect,
              icon: const DeskAnimatedIcon('apps'),
              label: Text(context.l10n.switchAccount),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccount extends StatelessWidget {
  const _QuickAccount({required this.profile, required this.onOpen});
  final AccountProfile profile;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final enabled = profile.state == StoreState.available;
    final colors = Theme.of(context).colorScheme;
    return DeskTapFeedback(
      enabled: enabled,
      child: Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          enabled: enabled,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          leading: ProfileMark(
            alias: profile.alias,
            color: profile.color,
            size: 48,
          ),
          title: Text(
            profile.alias,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(profileStatus(context, profile)),
          trailing: const DeskAnimatedIcon('arrow-right', size: 20),
          onTap: enabled ? onOpen : null,
        ),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.body,
    this.scene,
    this.action,
    this.onAction,
    this.busy = false,
  });
  final String icon, title, body;
  final DeskSceneKind? scene;
  final String? action;
  final VoidCallback? onAction;
  final bool busy;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (scene != null)
                      DeskScene(kind: scene!, size: 190)
                    else
                      DeskAnimatedIcon(
                        icon,
                        size: 44,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (busy)
                      Semantics(
                        liveRegion: true,
                        label: title,
                        child: const SizedBox.shrink(),
                      )
                    else if (action != null)
                      DeskTapFeedback(
                        child: FilledButton(
                          onPressed: onAction,
                          child: Text(action!),
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
  );
}
