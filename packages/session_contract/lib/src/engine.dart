import 'messages.g.dart';

/// Control surface only. It cannot execute scripts or extract website data.
abstract interface class SessionEngine {
  Stream<EngineEvent> get events;
  Future<EngineSnapshot> initialize();
  Future<EngineCapabilities> queryCapabilities();
  Future<List<AccountProfile>> listProfiles();
  Future<AccountProfile> allocateProfile(String alias, int color);
  Future<void> renameProfile(String profileId, String alias, int color);
  Future<void> reorderProfiles(List<String> profileIds);
  Future<void> setObservation(String profileId, AuthObservation observation);
  Future<ViewHandle> openProfile(
    String profileId,
    String operationId,
    int selectionGeneration,
  );
  Future<void> disposeView(ViewHandle view);
  Future<void> reloadProfileView(ViewHandle view);
  Future<void> setWorkspaceLayout(ViewHandle view, WorkspaceLayout layout);
  Future<void> showWorkspaceList(ViewHandle view);
  Future<WorkspacePresentation> getWorkspacePresentation(ViewHandle view);
  Future<void> requestLocalRemoval(String profileId, String cleanupOperationId);
  Future<void> retryPendingCleanup();
  Future<void> setPrivacyCover(bool visible, ViewHandle? owner);
  Future<void> cancelTransfer();
  Future<bool> authenticate();
  Future<void> lockApp();
  Future<void> setPreferences(AppPreferences preferences);
  Future<void> resetProfilePermissions(String profileId);
  Future<void> openHelp(HelpTopic topic);
  Future<void> exportDiagnostics();
  Future<String?> pickAccountSetupArchive();
  Future<bool> exportAccountSetupArchive();
  Future<List<AccountProfile>> importAccountSetupArchive(
    String archive,
    bool applyAppearance,
  );
}
