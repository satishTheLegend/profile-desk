import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/design.dart';
import 'app/providers.dart';
import 'features/privacy/lock_gate.dart';
import 'features/workspace/workspace_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Manrope',
    ], await rootBundle.loadString('assets/fonts/Manrope-OFL.txt'));
  });
  runApp(const ProviderScope(child: ProfileDeskApp()));
}

class ProfileDeskApp extends ConsumerWidget {
  const ProfileDeskApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appProvider).value?.preferences.theme ?? 'system';
    return MaterialApp(
      title: 'Profile Desk',
      debugShowCheckedModeBanner: false,
      theme: deskTheme(Brightness.light),
      darkTheme: deskTheme(Brightness.dark),
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
      home: const WorkspaceScreen(),
    );
  }
}
