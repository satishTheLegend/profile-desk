import 'localization.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:session_contract/session_contract.dart';

import 'providers.dart';

String friendlyError(BuildContext context, Object error) {
  final rawCode = error is PlatformException
      ? error.code
      : error is SessionFailure
      ? error.code
      : '';
  final code = rawCode
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]}_${match[2]}',
      )
      .toLowerCase();
  return switch (code) {
    'invalid_archive' => context.l10n.accountSetupInvalidFile,
    'archive_too_large' => context.l10n.accountSetupFileTooLarge,
    'archive_unavailable' => context.l10n.accountSetupFileUnavailable,
    'capacity' || 'capacity_reached' => context.l10n.allProfileSlotsAreInUse,
    'duplicate_alias' ||
    'alias_duplicate' => context.l10n.chooseADifferentNameThatAccount,
    'invalid_alias' ||
    'alias_empty' ||
    'alias_too_long' ||
    'alias_invalid' => context.l10n.useANameBetweenAndCharacters,
    'unsupported' ||
    'unsupported_provider' => context.l10n.thisBrowserProviderDoesNotSupport,
    'locked' => context.l10n.unlockProfileDeskBeforeOpeningAn,
    'transfer_active' ||
    'transfer_in_progress' => context.l10n.finishOrCancelTheOpenFile,
    'profile_missing' ||
    'missing_profile' ||
    'missing_store' ||
    'profile_unavailable' ||
    'quarantined' => context.l10n.thisProfileSStorageIsUnavailable,
    'restore_quarantined' => context.l10n.restoreQuarantined,
    'registry_operation_timeout' ||
    'registry_reconciliation_required' ||
    'cleanup_timeout' => context.l10n.theOperationDidNotFinishIn,
    'profile_removing' ||
    'cleanup_pending' => context.l10n.localAccessIsBlockedCleanupIs,
    'authentication' || 'authentication_unavailable' =>
      context.l10n.setUpDeviceAuthenticationInSystem,
    _ =>
      error is TimeoutException
          ? context.l10n.theOperationDidNotFinishIn
          : context.l10n.thisActionCouldNotFinishYour,
  };
}

Future<void> guardAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(context, error)),
          duration: Duration(seconds: 6),
        ),
      );
    }
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Future<void> selectAccount(
  BuildContext context,
  WidgetRef ref,
  AccountProfile profile,
) async {
  final coordinator = ref.read(coordinatorProvider);
  if (coordinator.state.selectedProfileId == profile.id &&
      coordinator.state.phase == WorkspacePhase.visible) {
    return;
  }
  final prefs = ref.read(appProvider).requireValue.preferences;
  if (!prefs.switchWarningSeen && coordinator.state.selectedProfileId != null) {
    final proceed = await confirmAction(
      context,
      title: context.l10n.beforeYouSwitch,
      message: context.l10n.switchingClosesTheCurrentWebPage,
      action: context.l10n.switchAccount,
    );
    if (!proceed || !context.mounted) return;
    await ref
        .read(appProvider.notifier)
        .preferences(copyPreferences(prefs, switchWarningSeen: true));
  }
  var cancel = false;
  if (coordinator.state.transferActive) {
    if (!context.mounted) return;
    cancel = await confirmAction(
      context,
      title: context.l10n.aFileActionIsOpen,
      message: context.l10n.cancelTheCurrentFileActionBefore,
      action: context.l10n.cancelFileAndSwitch,
    );
    if (!cancel) return;
  }
  await coordinator.select(profile.id, cancelActiveTransfer: cancel);
}
