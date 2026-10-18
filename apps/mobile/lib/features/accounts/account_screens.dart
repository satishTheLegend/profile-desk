import '../../app/localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:session_contract/session_contract.dart';

import '../../app/actions.dart';
import '../../app/design.dart';
import '../../app/motion.dart';
import '../../app/providers.dart';

int reservedSlots(List<AccountProfile> profiles) => profiles
    .where(
      (p) =>
          !(p.state == StoreState.cleanupPending &&
              p.cleanupStage == 'containerDeletionPending'),
    )
    .length;

String profileStatus(BuildContext context, AccountProfile profile) =>
    switch (profile.state) {
      StoreState.allocating => context.l10n.settingUp,
      StoreState.removing ||
      StoreState.cleanupPending => context.l10n.removalPending,
      StoreState.missing => context.l10n.storageUnavailable,
      StoreState.quarantined => context.l10n.needsReview,
      StoreState.available => switch (profile.observation) {
        AuthObservation.userConfirmed => context.l10n.userConfirmed,
        AuthObservation.relinkRequested => context.l10n.relinkRequested,
        _ => context.l10n.savedLinkingMayBeNeeded,
      },
    };
Future<void> showAccountForm(
  BuildContext context,
  WidgetRef ref, {
  AccountProfile? profile,
}) async {
  final created = await showModalBottomSheet<AccountProfile>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    useSafeArea: true,
    builder: (context) => AccountForm(profile: profile),
  );
  if (created != null && context.mounted) {
    await guardAction(context, () => selectAccount(context, ref, created));
  }
}

class AccountForm extends ConsumerStatefulWidget {
  const AccountForm({super.key, this.profile});
  final AccountProfile? profile;
  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile?.alias ?? '');
  late int _color = widget.profile?.color ?? 0xff21675e;
  bool _busy = false;
  String? _error;
  static const colors = [
    0xff21675e,
    0xff3557a2,
    0xff9d552c,
    0xff805395,
    0xff576549,
  ];
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = ref.read(accountsProvider);
      if (widget.profile case final profile?) {
        await service.rename(profile.id, _name.text, _color);
        if (mounted) Navigator.pop(context);
      } else {
        final profile = await service.add(_name.text, _color);
        if (!mounted) return;
        Navigator.pop(context, profile);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = friendlyError(context, error);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _name,
                        builder: (context, value, _) => ProfileMark(
                          alias: value.text.trim().isEmpty
                              ? context.l10n.accountName
                              : value.text.trim(),
                          color: _color,
                          size: 54,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.profile == null
                              ? context.l10n.addAnAccount
                              : context.l10n.editAccountLabel,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    widget.profile == null
                        ? context.l10n.giveThisProfileANameYou
                        : context.l10n.changingThisLabelKeepsTheSame,
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    autofocus: true,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.l10n.accountName,
                      hintText: context.l10n.forExampleWorkOrPersonal,
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) return context.l10n.enterAnAccountName;
                      if (name.runes.length > 40) {
                        return context.l10n.useCharactersOrFewer;
                      }
                      final duplicate = ref
                          .read(accountsProvider)
                          .profiles
                          .any(
                            (p) =>
                                p.id != widget.profile?.id &&
                                !(p.state == StoreState.cleanupPending &&
                                    p.cleanupStage ==
                                        'containerDeletionPending') &&
                                p.alias.trim().toLowerCase() ==
                                    name.toLowerCase(),
                          );
                      return duplicate
                          ? context.l10n.thatNameIsAlreadyInUse
                          : null;
                    },
                    onFieldSubmitted: (_) {
                      if (!_busy) submit();
                    },
                  ),
                  SizedBox(height: 12),
                  Text(
                    context.l10n.profileColor,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < colors.length; i++)
                        Semantics(
                          label: context.l10n.colorValue((i + 1).toString()),
                          selected: colors[i] == _color,
                          child: IconButton(
                            tooltip: context.l10n.colorValue(
                              (i + 1).toString(),
                            ),
                            onPressed: _busy
                                ? null
                                : () => setState(() => _color = colors[i]),
                            style: IconButton.styleFrom(
                              backgroundColor: Color(colors[i])
                                  .withValues(alpha: .2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colors[i] == _color
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            icon: colors[i] == _color
                                ? DeskAnimatedIcon('check', active: true)
                                : SizedBox(width: 22, height: 22),
                          ),
                        ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  SizedBox(height: 24),
                  DeskTapFeedback(
                    enabled: !_busy,
                    child: FilledButton(
                      onPressed: _busy ? null : submit,
                      child: Text(
                        _busy
                            ? context.l10n.saving
                            : widget.profile == null
                            ? context.l10n.createAndLinkAccount
                            : context.l10n.saveLabel,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(context.l10n.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AccountManagerScreen extends ConsumerWidget {
  const AccountManagerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles =
        ref.watch(profilesProvider).value ??
        ref.read(accountsProvider).profiles;
    final active = ref.watch(sessionProvider).value?.selectedProfileId;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.yourAccounts)),
      body: ContentColumn(
        maxWidth: 960,
        children: [
          DeskEntrance(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.valueOfAccounts(
                          reservedSlots(profiles).toString(),
                        ),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.labelsHelpYouFindYourAccounts,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: DeskAnimatedIcon('apps', active: true, size: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (profiles.isEmpty)
            DeskSurface(
              child: Column(
                children: [
                  const DeskScene(kind: DeskSceneKind.accounts, size: 160),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.noSavedAccountsYet,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns =
                    constraints.maxWidth >= 720 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 20.8;
                final width = twoColumns
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (var index = 0; index < profiles.length; index++)
                      SizedBox(
                        width: width,
                        child: DeskEntrance(
                          key: ValueKey(profiles[index].id),
                          order: index.clamp(0, 3),
                          child: _AccountTile(
                            profile: profiles[index],
                            profiles: profiles,
                            active: profiles[index].id == active,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          DeskTapFeedback(
            enabled: reservedSlots(profiles) < 10,
            child: FilledButton.icon(
              onPressed: reservedSlots(profiles) >= 10
                  ? null
                  : () => showAccountForm(context, ref),
              icon: const DeskIcon('plus'),
              label: Text(context.l10n.addAccount),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => guardAction(
              context,
              () => ref.read(accountsProvider).retryCleanup(),
            ),
            icon: const DeskIcon('refresh'),
            label: Text(context.l10n.retryPendingCleanup),
          ),
          if (profiles.isNotEmpty)
            TextButton(
              onPressed: () async {
                if (await confirmAction(
                      context,
                      title: context.l10n.removeAllLocalProfiles,
                      message: context.l10n.thisBlocksAccessAndRemovesSaved,
                      action: context.l10n.removeAll,
                      destructive: true,
                    ) &&
                    context.mounted) {
                  await guardAction(
                    context,
                    () => ref.read(accountsProvider).removeAll(),
                  );
                }
              },
              child: Text(
                context.l10n.removeAllLocalProfiles116,
                style: TextStyle(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({
    required this.profile,
    required this.profiles,
    required this.active,
  });
  final AccountProfile profile;
  final List<AccountProfile> profiles;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final movableProfiles = profiles
        .where(
          (p) =>
              p.state != StoreState.removing &&
              p.state != StoreState.cleanupPending,
        )
        .toList();
    final position = movableProfiles.indexWhere((p) => p.id == profile.id);
    return Material(
      color: active
          ? colors.primaryContainer.withValues(alpha: .4)
          : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: active ? colors.primary : colors.outlineVariant,
          width: active ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ProfileSettingsScreen(profileId: profile.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 4, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileMark(
                          alias: profile.alias,
                          color: profile.color,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.alias,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${profileStatus(context, profile)}${active ? context.l10n.selected : ''}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                child: IconButton(
                  tooltip: context.l10n.editValue(profile.alias),
                  icon: const DeskIcon('pencil'),
                  onPressed: () =>
                      showAccountForm(context, ref, profile: profile),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: colors.outlineVariant),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: context.l10n.moveValueUp(profile.alias),
                  onPressed: position <= 0
                      ? null
                      : () => _move(context, ref, -1),
                  icon: const DeskIcon('arrow-up'),
                ),
                IconButton(
                  tooltip: context.l10n.moveValueDown(profile.alias),
                  onPressed:
                      position < 0 || position >= movableProfiles.length - 1
                      ? null
                      : () => _move(context, ref, 1),
                  icon: const DeskIcon('arrow-down'),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: DeskTapFeedback(
                      enabled: profile.state == StoreState.available,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          visualDensity: VisualDensity.standard,
                        ),
                        onPressed: profile.state != StoreState.available
                            ? null
                            : () => guardAction(context, () async {
                                await selectAccount(context, ref, profile);
                                if (context.mounted) Navigator.pop(context);
                              }),
                        icon: DeskAnimatedIcon(
                          active ? 'check' : 'arrow-right',
                          active: active,
                          color: profile.state == StoreState.available
                              ? colors.primary
                              : colors.onSurface.withValues(alpha: .38),
                          size: 18,
                        ),
                        label: Text(context.l10n.open),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _move(BuildContext context, WidgetRef ref, int delta) =>
      guardAction(context, () async {
        final ids = profiles
            .where(
              (p) =>
                  p.state != StoreState.removing &&
                  p.state != StoreState.cleanupPending,
            )
            .map((p) => p.id)
            .toList();
        final position = ids.indexOf(profile.id);
        if (position < 0 ||
            position + delta < 0 ||
            position + delta >= ids.length) {
          return;
        }
        final id = ids.removeAt(position);
        ids.insert(position + delta, id);
        await ref.read(accountsProvider).reorder(ids);
      });
}

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key, required this.profileId});
  final String profileId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles =
        ref.watch(profilesProvider).value ??
        ref.read(accountsProvider).profiles;
    final matches = profiles.where((p) => p.id == profileId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.accountRemoved)),
        body: Center(child: Text(context.l10n.thisLocalProfileHasBeenRemoved)),
      );
    }
    final profile = matches.first;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.accountDetails)),
      body: ContentColumn(
        children: [
          DeskEntrance(
            child: DeskSurface(
              emphasized: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileMark(
                        alias: profile.alias,
                        color: profile.color,
                        size: 56,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.alias,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(profileStatus(context, profile)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (profile.cleanupStage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        context.l10n.localCleanupIsBeingTrackedAccess,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          if (profile.state == StoreState.missing ||
              profile.state == StoreState.quarantined)
            ListTile(
              leading: DeskIcon('refresh'),
              title: Text(context.l10n.replaceUnavailableProfile),
              subtitle: Text(context.l10n.createAFreshStoreAfterCleanup),
              onTap: () async {
                if (await confirmAction(
                      context,
                      title: context.l10n.replaceValue(
                        (profile.alias).toString(),
                      ),
                      message: context.l10n.theUnavailableLocalStoreWillBe,
                      action: context.l10n.replaceAndKeepLabel,
                      destructive: true,
                    ) &&
                    context.mounted) {
                  await guardAction(context, () async {
                    await ref
                        .read(accountsProvider)
                        .replaceUnavailable(profile.id, keepAlias: true);
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  });
                }
              },
            ),
          if (profile.state == StoreState.available &&
              profile.observation != AuthObservation.userConfirmed)
            ListTile(
              leading: DeskIcon('device-mobile'),
              title: Text(context.l10n.pauseAccountSetup),
              subtitle: Text(context.l10n.keepTheReservedProfileForLater),
              onTap: () => pauseAccountSetup(context, ref, profile),
            ),
          ListTile(
            leading: DeskIcon('pencil'),
            title: Text(context.l10n.renameOrChangeColor),
            onTap: () => showAccountForm(context, ref, profile: profile),
          ),
          ListTile(
            leading: DeskAnimatedIcon(
              'check',
              active: profile.observation == AuthObservation.userConfirmed,
            ),
            title: Text(context.l10n.confirmTheLinkedAccount),
            subtitle: Text(context.l10n.onlyAfterCheckingTheAccountShown),
            onTap: () async {
              if (await confirmAction(
                    context,
                    title: context.l10n.haveYouCheckedTheAccount,
                    message: context.l10n.confirmThatTheOfficialWebsiteShows(
                      (profile.alias).toString(),
                    ),
                    action: context.l10n.iCheckedTheAccount,
                  ) &&
                  context.mounted) {
                await guardAction(
                  context,
                  () => ref.read(accountsProvider).confirmAccount(profile.id),
                );
              }
            },
          ),
          ListTile(
            leading: DeskIcon('refresh'),
            title: Text(context.l10n.openToRelink),
            subtitle: Text(context.l10n.usesTheExistingProfileWithoutClearing),
            onTap: () => guardAction(context, () async {
              await ref.read(accountsProvider).requestRelink(profile.id);
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            }),
          ),
          ListTile(
            leading: DeskIcon('shield-lock'),
            title: Text(context.l10n.resetLocalPermissions),
            onTap: () => guardAction(
              context,
              () =>
                  ref.read(engineProvider).resetProfilePermissions(profile.id),
            ),
          ),
          Divider(height: 40),
          Text(context.l10n.removingThisProfileAffectsLocalAccess),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              if (await confirmAction(
                    context,
                    title: context.l10n.removeValue((profile.alias).toString()),
                    message: context.l10n.theLocalSessionWillBeBlocked,
                    action: context.l10n.removeLocalProfile,
                    destructive: true,
                  ) &&
                  context.mounted) {
                await guardAction(
                  context,
                  () => ref.read(accountsProvider).remove(profile.id),
                );
              }
            },
            icon: DeskIcon('trash'),
            label: Text(context.l10n.removeLocalProfile),
          ),
        ],
      ),
    );
  }
}

Future<void> pauseAccountSetup(
  BuildContext context,
  WidgetRef ref,
  AccountProfile profile,
) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.pauseThisSetup),
      content: Text(context.l10n.keepForLaterReservesThisAccount),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.keepForLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.removeLocalSetup),
        ),
      ],
    ),
  );
  if (remove == null || !context.mounted) return;
  await guardAction(context, () async {
    if (remove) {
      await ref.read(accountsProvider).remove(profile.id);
    } else if (ref.read(coordinatorProvider).state.selectedProfileId ==
        profile.id) {
      await ref.read(coordinatorProvider).detach();
    }
    if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
  });
}
