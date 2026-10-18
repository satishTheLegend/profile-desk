import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_registry/local_registry.dart';
import 'package:session_contract/session_contract.dart';

import '../../app/actions.dart';
import '../../app/design.dart';
import '../../app/localization.dart';
import '../../app/providers.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});
  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  AccountSetupArchive? _archive;
  final _names = <TextEditingController>[];
  bool _busy = false;
  bool _applyAppearance = false;
  String? _message;
  String? _error;

  void _clearPreview() {
    for (final name in _names) {
      name.dispose();
    }
    _names.clear();
    _archive = null;
    _applyAppearance = false;
  }

  @override
  void dispose() {
    _clearPreview();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is FormatException
              ? context.l10n.accountSetupInvalidFile
              : friendlyError(context, error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() => _run(() async {
    final source = await ref.read(engineProvider).pickAccountSetupArchive();
    if (!mounted || source == null) return;
    final archive = AccountSetupArchive.decode(source);
    if (ref.read(coordinatorProvider).state.locked) return;
    setState(() {
      _clearPreview();
      _archive = archive;
      _names.addAll(
        archive.accounts.map((a) => TextEditingController(text: a.alias)),
      );
    });
  });

  String? _nameError(int index, List<AccountProfile> profiles) {
    final value = _names[index].text.trim();
    if (!AccountSetupArchive.validAlias(value)) {
      return context.l10n.useANameBetweenAndCharacters;
    }
    final normalized = value.toLowerCase();
    if (_names.indexWhere((n) => n.text.trim().toLowerCase() == normalized) !=
            index ||
        profiles.any((p) => p.alias.trim().toLowerCase() == normalized)) {
      return context.l10n.chooseADifferentNameThatAccount;
    }
    return null;
  }

  Future<void> _import() => _run(() async {
    final archive = _archive!;
    final edited = AccountSetupArchive(
      accounts: [
        for (var i = 0; i < _names.length; i++)
          AccountSetupEntry(
            alias: _names[i].text.trim(),
            color: archive.accounts[i].color,
          ),
      ],
      theme: archive.theme,
    );
    final result = await ref
        .read(accountsProvider)
        .importSetup(edited, applyAppearance: _applyAppearance);
    if (!mounted) return;
    setState(() {
      _clearPreview();
      _message = context.l10n.accountSetupImported(result.length.toString());
    });
  });

  @override
  Widget build(BuildContext context) {
    final profiles =
        ref.watch(profilesProvider).value ??
        ref.read(accountsProvider).profiles;
    final reserved = profiles
        .where(
          (p) =>
              !(p.state == StoreState.cleanupPending &&
                  p.cleanupStage == 'containerDeletionPending'),
        )
        .toList();
    final free = (10 - reserved.length).clamp(0, 10);
    final archive = _archive;
    final capacityOk = archive == null || archive.accounts.length <= free;
    final valid =
        archive != null &&
        archive.accounts.isNotEmpty &&
        capacityOk &&
        List.generate(
          _names.length,
          (i) => _nameError(i, reserved),
        ).every((e) => e == null);
    final locked =
        (ref.watch(sessionProvider).value ??
                ref.read(coordinatorProvider).state)
            .locked;
    final enabled =
        !_busy && !locked && !ref.read(accountsProvider).requiresReconciliation;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.accountSetupBackup)),
      body: ContentColumn(
        children: [
          Semantics(
            header: true,
            child: Text(
              context.l10n.accountSetupHeading,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 12),
          Text(context.l10n.accountSetupDisclosure),
          const SizedBox(height: 24),
          if (_busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          if (_error != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_message != null) ...[
            Semantics(
              liveRegion: true,
              child: DeskSurface(child: Text(_message!)),
            ),
            const SizedBox(height: 16),
          ],
          if (archive == null) ...[
            DeskSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.exportAccountSetup,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(context.l10n.accountSetupExportNote),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: enabled
                        ? () => _run(() async {
                            final saved = await ref
                                .read(engineProvider)
                                .exportAccountSetupArchive();
                            if (mounted && saved) {
                              setState(
                                () => _message =
                                    context.l10n.accountSetupExported,
                              );
                            }
                          })
                        : null,
                    icon: const DeskIcon('file-download'),
                    label: Text(context.l10n.exportAccountSetup),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DeskSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.importAccountSetup,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(context.l10n.accountSetupImportNote),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: enabled ? _pick : null,
                    child: Text(context.l10n.accountSetupChooseFile),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              context.l10n.accountSetupPreview,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.accountSetupSlots(
                archive.accounts.length.toString(),
                free.toString(),
              ),
            ),
            if (!capacityOk)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.accountSetupCapacity,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (archive.accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(context.l10n.accountSetupEmpty),
              ),
            const SizedBox(height: 16),
            for (var i = 0; i < archive.accounts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _names[i],
                  enabled: enabled,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: context.l10n.accountSetupName(
                      (i + 1).toString(),
                    ),
                    errorText: _nameError(i, reserved),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ProfileMark(
                        alias: _names[i].text,
                        color: archive.accounts[i].color,
                        size: 28,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            CheckboxListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.accountSetupApplyAppearance),
              subtitle: Text(context.l10n.accountSetupKeepLock),
              value: _applyAppearance,
              onChanged: enabled
                  ? (v) => setState(() => _applyAppearance = v ?? false)
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: enabled && valid ? _import : null,
              child: Text(context.l10n.accountSetupImportAccounts),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: enabled ? () => setState(_clearPreview) : null,
              child: Text(context.l10n.cancel),
            ),
          ],
        ],
      ),
    );
  }
}
