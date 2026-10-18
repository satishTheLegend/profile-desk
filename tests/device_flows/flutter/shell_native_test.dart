import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:profile_desk/app/providers.dart';
import 'package:profile_desk/features/accounts/account_screens.dart';
import 'package:profile_desk/features/workspace/workspace_screen.dart';
import 'package:profile_desk/l10n/app_localizations.dart';
import 'package:profile_desk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real native engine: cold shell, allocate, open, detach and scoped removal',
    (tester) async {
      app.main();
      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 120 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(
          ready(),
          isTrue,
          reason:
              'Native operation must complete within the bounded test window.',
        );
      }

      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceScreen)),
      );
      await until(
        () =>
            container.read(appProvider).hasValue ||
            container.read(appProvider).hasError,
      );
      final snapshot = container.read(appProvider).requireValue;
      expect(
        snapshot.capabilities.supported,
        isTrue,
        reason: 'Run on a declared supported test provider.',
      );
      await tester.pump();
      final labels = AppLocalizations.of(
        tester.element(find.byType(WorkspaceScreen)),
      );
      if (!snapshot.preferences.welcomeSeen) {
        await tester.scrollUntilVisible(
          find.text(labels.setUpYourWorkspace),
          200,
        );
        await tester.tap(find.text(labels.setUpYourWorkspace));
        await until(
          () =>
              container.read(appProvider).value?.preferences.welcomeSeen ==
              true,
        );
      }
      // Complete the welcome transition so the real platform host is mounted
      // before opening its first isolated workspace.
      await tester.pumpAndSettle();
      final accounts = container.read(accountsProvider);
      final coordinator = container.read(coordinatorProvider);
      final alias = 'Synthetic QA ${DateTime.now().millisecondsSinceEpoch}';
      String? createdId;
      try {
        final profile = await accounts.add(alias, 0xff21675e);
        createdId = profile.id;
        expect(profile.id, isNotEmpty);
        expect(
          accounts.profiles.where((p) => p.id == profile.id),
          hasLength(1),
        );
        // Opens only the fixed official URL. The fixture performs no DOM/QR
        // reading, extra page evaluation, account pairing, screenshots,
        // attachments or messaging. The app's structural layout adapter runs
        // normally; no content from the unlinked page is inspected by this test.
        await coordinator.select(profile.id);
        expect(coordinator.state.view?.profileId, profile.id);
        await coordinator.detach();
        expect(coordinator.state.view, isNull);
        await accounts.refresh();
        expect(accounts.profiles.any((p) => p.id == profile.id), isTrue);
        final context = tester.element(find.byType(Scaffold).first);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProfileSettingsScreen(profileId: profile.id),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(labels.pauseAccountSetup),
          200,
        );
        await tester.tap(find.text(labels.pauseAccountSetup));
        await tester.pumpAndSettle();
        await tester.tap(find.text(labels.keepForLater));
        await tester.pumpAndSettle();
        expect(accounts.profiles.any((p) => p.id == profile.id), isTrue);
        await accounts.remove(profile.id);
        await accounts.refresh();
        final remaining = accounts.profiles.where((p) => p.id == profile.id);
        expect(
          remaining.every((p) => p.cleanupOperationId != null),
          isTrue,
          reason: 'A native deferred container may remain tombstoned after access/data removal.',
        );
        expect(coordinator.state.selectedProfileId, isNull);
      } finally {
        if (createdId != null) {
          await coordinator.detach();
          await accounts.refresh();
          if (accounts.profiles.any((p) => p.id == createdId)) {
            await accounts.remove(createdId);
          }
        }
      }
    },
  );
}
