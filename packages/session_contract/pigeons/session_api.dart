import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    swiftOut: '../session_engine/ios/session_engine/Sources/session_engine/Messages.g.swift',
    kotlinOut: '../session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'dev.profiledesk.session_engine'),
    dartPackageName: 'session_contract',
  ),
)
enum StoreState {
  allocating,
  available,
  removing,
  cleanupPending,
  missing,
  quarantined,
}

enum AuthObservation { unknown, userConfirmed, relinkRequested }

enum EngineEventKind {
  viewReady,
  viewFailed,
  profilesChanged,
  cleanupChanged,
  privacyChanged,
  transferChanged,
  unlockRequested,
  networkChanged,
}

enum NetworkObservation { unknown, offline, reachable }

enum HelpTopic { linking, remoteUnlink, serviceHelp }

enum WorkspaceLayout { phone, original }

// Structural presentation only; no website content is returned.
enum WorkspacePresentation { original, list, menu, detail, unavailable }

class AccountProfile {
  AccountProfile({
    required this.id,
    required this.platformProfileId,
    required this.alias,
    required this.color,
    required this.orderIndex,
    required this.createdAt,
    this.lastOpenedAt,
    required this.state,
    required this.observation,
    this.cleanupOperationId,
    this.cleanupStage,
  });
  String id;
  String platformProfileId;
  String alias;
  int color;
  int orderIndex;
  int createdAt;
  int? lastOpenedAt;
  StoreState state;
  AuthObservation observation;
  String? cleanupOperationId;
  String? cleanupStage;
}

class EngineCapabilities {
  EngineCapabilities({
    required this.supported,
    required this.platform,
    required this.osVersion,
    required this.providerVersion,
    required this.multiProfile,
    required this.scopedDeletion,
    required this.authenticationAvailable,
    required this.downloadsSupported,
    required this.captureSupported,
    this.reason,
  });
  bool supported;
  String platform;
  String osVersion;
  String providerVersion;
  bool multiProfile;
  bool scopedDeletion;
  bool authenticationAvailable;
  bool downloadsSupported;
  bool captureSupported;
  String? reason;
}

class AppPreferences {
  AppPreferences({
    required this.lockEnabled,
    required this.welcomeSeen,
    required this.switchWarningSeen,
    required this.theme,
  });
  bool lockEnabled;
  bool welcomeSeen;
  bool switchWarningSeen;
  String theme;
}

class EngineSnapshot {
  EngineSnapshot({
    required this.capabilities,
    required this.profiles,
    required this.preferences,
    required this.locked,
    required this.transferActive,
    this.network,
  });
  EngineCapabilities capabilities;
  List<AccountProfile> profiles;
  AppPreferences preferences;
  bool locked;
  bool transferActive;
  NetworkObservation? network;
}

class ViewHandle {
  ViewHandle({
    required this.profileId,
    required this.viewInstanceId,
    required this.operationId,
    required this.selectionGeneration,
  });
  String profileId;
  String viewInstanceId;
  String operationId;
  int selectionGeneration;
}

class EngineEvent {
  EngineEvent({
    required this.kind,
    this.profileId,
    this.view,
    this.cleanupOperationId,
    this.cleanupStage,
    this.errorCode,
    this.locked,
    this.transferActive,
    this.network,
    this.progress,
  });
  EngineEventKind kind;
  String? profileId;
  ViewHandle? view;
  String? cleanupOperationId;
  String? cleanupStage;
  String? errorCode;
  bool? locked;
  bool? transferActive;
  NetworkObservation? network;
  // Fraction of a native transfer; null means the byte total is not known.
  double? progress;
}

// Native SQLite owns metadata, capacity and lifecycle. All mutations are serialized.
// A platform-view host is registered as profile_desk/session; openProfile binds
// one WebView into that host. A viewReady event means navigation, never login.
@HostApi()
abstract class SessionHostApi {
  @async
  EngineSnapshot initialize();
  @async
  EngineCapabilities queryCapabilities();
  @async
  List<AccountProfile> listProfiles();
  @async
  AccountProfile allocateProfile(String alias, int color);
  @async
  void renameProfile(String profileId, String alias, int color);
  @async
  void reorderProfiles(List<String> profileIds);
  @async
  void setObservation(String profileId, AuthObservation observation);
  @async
  ViewHandle openProfile(
    String profileId,
    String operationId,
    int selectionGeneration,
  );
  @async
  void disposeView(ViewHandle view);
  @async
  void reloadProfileView(ViewHandle view);
  @async
  void setWorkspaceLayout(ViewHandle view, WorkspaceLayout layout);
  @async
  void showWorkspaceList(ViewHandle view);
  @async
  WorkspacePresentation getWorkspacePresentation(ViewHandle view);
  @async
  void requestLocalRemoval(String profileId, String cleanupOperationId);
  @async
  void retryPendingCleanup();
  // Revealing requires the exact eligible current view and an unlocked app.
  @async
  void setPrivacyCover(bool visible, ViewHandle? owner);
  @async
  void cancelTransfer();
  @async
  bool authenticate();
  @async
  void lockApp();
  @async
  void setPreferences(AppPreferences preferences);
  @async
  void resetProfilePermissions(String profileId);
  @async
  void openHelp(HelpTopic topic);
  @async
  void exportDiagnostics();
  // Bounded account metadata only; never browser storage or signed-in sessions.
  @async
  String? pickAccountSetupArchive();
  @async
  bool exportAccountSetupArchive();
  @async
  List<AccountProfile> importAccountSetupArchive(
    String archive,
    bool applyAppearance,
  );
}

@FlutterApi()
abstract class SessionFlutterApi {
  void onEvent(EngineEvent event);
}
