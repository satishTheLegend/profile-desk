import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_registry/local_registry.dart';
import 'package:session_contract/session_contract.dart';
import 'package:session_engine/session_engine.dart';

final engineProvider = Provider<SessionEngine>((ref) => NativeSessionEngine());
final coordinatorProvider = Provider((ref) {
  final value = SessionCoordinator(ref.watch(engineProvider));
  ref.onDispose(() {
    unawaited(value.dispose());
  });
  return value;
});
final accountsProvider = Provider((ref) {
  final service = AccountService(
    ref.watch(engineProvider),
    ref.watch(coordinatorProvider),
    onSetupCommitted: () => ref.read(appProvider.notifier).refreshPreferences(),
  );
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
final sessionProvider = StreamProvider<SessionState>((ref) async* {
  final coordinator = ref.watch(coordinatorProvider);
  yield coordinator.state;
  yield* coordinator.states;
});
final profilesProvider = StreamProvider<List<AccountProfile>>((ref) async* {
  final service = ref.watch(accountsProvider);
  yield service.profiles;
  yield* service.changes;
});
final appProvider = AsyncNotifierProvider<AppController, EngineSnapshot>(
  AppController.new,
);

class AppController extends AsyncNotifier<EngineSnapshot> {
  @override
  Future<EngineSnapshot> build() async {
    final snapshot = await ref.read(coordinatorProvider).initialize();
    await ref.read(accountsProvider).refresh();
    return snapshot;
  }

  Future<void> preferences(AppPreferences next) async {
    await ref.read(engineProvider).setPreferences(next);
    final old = state.requireValue;
    state = AsyncData(
      EngineSnapshot(
        capabilities: old.capabilities,
        profiles: old.profiles,
        preferences: next,
        locked: old.locked,
        transferActive: old.transferActive,
        network: old.network,
      ),
    );
  }

  // Re-read committed preferences even after the initiating route has closed.
  Future<void> refreshPreferences() async {
    final snapshot = await ref.read(engineProvider).initialize();
    if (!ref.mounted || !state.hasValue) return;
    final old = state.requireValue;
    state = AsyncData(
      EngineSnapshot(
        capabilities: old.capabilities,
        profiles: old.profiles,
        preferences: snapshot.preferences,
        locked: old.locked,
        transferActive: old.transferActive,
        network: old.network,
      ),
    );
  }
}

AppPreferences copyPreferences(
  AppPreferences old, {
  bool? lockEnabled,
  bool? welcomeSeen,
  bool? switchWarningSeen,
  String? theme,
}) => AppPreferences(
  lockEnabled: lockEnabled ?? old.lockEnabled,
  welcomeSeen: welcomeSeen ?? old.welcomeSeen,
  switchWarningSeen: switchWarningSeen ?? old.switchWarningSeen,
  theme: theme ?? old.theme,
);
