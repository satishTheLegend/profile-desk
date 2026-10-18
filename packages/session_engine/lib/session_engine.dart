import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:session_contract/session_contract.dart';

/// Production control adapter. No fake engine or arbitrary URL injection.
class NativeSessionEngine implements SessionEngine, SessionFlutterApi {
  NativeSessionEngine() {
    SessionFlutterApi.setUp(this);
  }
  final SessionHostApi _api = SessionHostApi();
  final _events = StreamController<EngineEvent>.broadcast(sync: true);
  @override
  Stream<EngineEvent> get events => _events.stream;
  @override
  void onEvent(EngineEvent event) => _events.add(event);
  // Keep native futures alive: the coordinator owns deadlines and reconciles
  // late mutations. A second timeout here would discard a late view handle.
  Future<T> _call<T>(Future<T> call) => call;
  @override
  Future<EngineSnapshot> initialize() => _call(_api.initialize());
  @override
  Future<EngineCapabilities> queryCapabilities() =>
      _call(_api.queryCapabilities());
  @override
  Future<List<AccountProfile>> listProfiles() => _call(_api.listProfiles());
  @override
  Future<AccountProfile> allocateProfile(String alias, int color) =>
      _call(_api.allocateProfile(alias, color));
  @override
  Future<void> renameProfile(String id, String alias, int color) =>
      _call(_api.renameProfile(id, alias, color));
  @override
  Future<void> reorderProfiles(List<String> ids) =>
      _call(_api.reorderProfiles(ids));
  @override
  Future<void> setObservation(String id, AuthObservation observation) =>
      _call(_api.setObservation(id, observation));
  @override
  Future<ViewHandle> openProfile(String id, String operation, int generation) =>
      _call(_api.openProfile(id, operation, generation));
  @override
  Future<void> disposeView(ViewHandle view) => _call(_api.disposeView(view));
  @override
  Future<void> reloadProfileView(ViewHandle view) =>
      _call(_api.reloadProfileView(view));
  @override
  Future<void> setWorkspaceLayout(ViewHandle view, WorkspaceLayout layout) =>
      _call(_api.setWorkspaceLayout(view, layout));
  @override
  Future<void> showWorkspaceList(ViewHandle view) =>
      _call(_api.showWorkspaceList(view));
  @override
  Future<WorkspacePresentation> getWorkspacePresentation(ViewHandle view) =>
      _call(_api.getWorkspacePresentation(view));
  @override
  Future<void> requestLocalRemoval(String id, String operation) =>
      _call(_api.requestLocalRemoval(id, operation));
  @override
  Future<void> retryPendingCleanup() => _call(_api.retryPendingCleanup());
  @override
  Future<void> setPrivacyCover(bool visible, ViewHandle? owner) =>
      _call(_api.setPrivacyCover(visible, owner));
  @override
  Future<void> cancelTransfer() => _call(_api.cancelTransfer());
  @override
  Future<bool> authenticate() => _call(_api.authenticate());
  @override
  Future<void> lockApp() => _call(_api.lockApp());
  @override
  Future<void> setPreferences(AppPreferences preferences) =>
      _call(_api.setPreferences(preferences));
  @override
  Future<void> resetProfilePermissions(String id) =>
      _call(_api.resetProfilePermissions(id));
  @override
  Future<void> openHelp(HelpTopic topic) => _call(_api.openHelp(topic));
  @override
  Future<void> exportDiagnostics() => _call(_api.exportDiagnostics());
  @override
  Future<String?> pickAccountSetupArchive() =>
      _call(_api.pickAccountSetupArchive());
  @override
  Future<bool> exportAccountSetupArchive() =>
      _call(_api.exportAccountSetupArchive());
  @override
  Future<List<AccountProfile>> importAccountSetupArchive(
    String archive,
    bool applyAppearance,
  ) => _call(_api.importAccountSetupArchive(archive, applyAppearance));
}

class NativeSessionView extends StatelessWidget {
  const NativeSessionView({super.key});
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => const UiKitView(
        viewType: 'profile_desk/session',
        layoutDirection: TextDirection.ltr,
        creationParamsCodec: StandardMessageCodec(),
      ),
      TargetPlatform.android => const AndroidView(
        viewType: 'profile_desk/session',
        layoutDirection: TextDirection.ltr,
        creationParamsCodec: StandardMessageCodec(),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
