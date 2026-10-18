import 'dart:async';
import 'dart:convert';

import 'package:session_contract/session_contract.dart';

/// Test-only engine. Production has no export or injection path to this file.
class FakeSessionEngine implements SessionEngine {
  final eventController = StreamController<EngineEvent>.broadcast(sync: true);
  final calls = <String>[];
  final records = <String, AccountProfile>{};
  final pendingOpens = <String, Completer<void>>{};
  final pendingDisposals = <String, Completer<void>>{};
  final pendingRemovals = <String, Completer<void>>{};
  Completer<void>? coverGate;
  Object? openError;
  Object? disposeError;
  Object? removalError;
  final removalFailures = <String>{};
  Object? allocationError;
  Object? lockError;
  Completer<void>? authenticationGate;
  Completer<void>? revealGate;
  Completer<void>? allocationGate;
  Future<List<AccountProfile>> Function()? profilesResponse;
  bool authenticated = true;
  bool locked = false;
  bool covered = true;
  bool cleanupAvailable = true;
  bool deferContainerDeletion = false;
  bool readyBeforeOpenReturns = false;
  int nextProfile = 0;
  int nextView = 0;
  ViewHandle? active;
  WorkspacePresentation presentation = WorkspacePresentation.list;
  Future<WorkspacePresentation>? presentationReply;
  final presentationCalls = <ViewHandle>[];
  String? setupArchiveToPick;
  bool setupExportCompleted = true;
  Object? setupImportError;
  Completer<void>? setupImportGate;
  AppPreferences preferences = AppPreferences(
    lockEnabled: false,
    welcomeSeen: true,
    switchWarningSeen: true,
    theme: 'system',
  );

  @override
  Stream<EngineEvent> get events => eventController.stream;

  AccountProfile seed(
    String id, {
    String? alias,
    StoreState state = StoreState.available,
  }) {
    final profile = AccountProfile(
      id: id,
      platformProfileId: 'store-$id',
      alias: alias ?? id,
      color: 0,
      orderIndex: records.length,
      createdAt: 1,
      state: state,
      observation: AuthObservation.unknown,
    );
    records[id] = profile;
    return profile;
  }

  void emit(EngineEvent event) => eventController.add(event);
  void ready(ViewHandle view) => emit(
    EngineEvent(
      kind: EngineEventKind.viewReady,
      profileId: view.profileId,
      view: view,
    ),
  );

  @override
  Future<EngineSnapshot> initialize() async => EngineSnapshot(
    capabilities: await queryCapabilities(),
    profiles: await listProfiles(),
    preferences: preferences,
    locked: locked,
    transferActive: false,
  );
  @override
  Future<EngineCapabilities> queryCapabilities() async => EngineCapabilities(
    supported: true,
    platform: 'test',
    osVersion: 'synthetic',
    providerVersion: 'synthetic',
    multiProfile: true,
    scopedDeletion: cleanupAvailable,
    authenticationAvailable: true,
    downloadsSupported: false,
    captureSupported: false,
  );
  @override
  Future<List<AccountProfile>> listProfiles() async =>
      profilesResponse == null ? records.values.toList() : profilesResponse!();

  @override
  Future<AccountProfile> allocateProfile(String alias, int color) async {
    calls.add('allocate');
    if (allocationError != null) throw allocationError!;
    final eligible = records.values
        .where(
          (p) =>
              p.state != StoreState.removing &&
              p.state != StoreState.cleanupPending,
        )
        .toList();
    if (eligible.length >= 10) throw const SessionFailure('capacity_reached');
    if (eligible.any(
      (p) => p.alias.trim().toLowerCase() == alias.trim().toLowerCase(),
    ))
      throw const SessionFailure('alias_duplicate');
    final profile = seed('allocated-${++nextProfile}', alias: alias)
      ..color = color;
    if (allocationGate != null) await allocationGate!.future;
    emit(EngineEvent(kind: EngineEventKind.profilesChanged));
    return profile;
  }

  @override
  Future<void> renameProfile(String profileId, String alias, int color) async {
    calls.add('rename:$profileId');
    final profile = records[profileId]!;
    if (records.values.any(
      (p) => p.id != profileId && p.alias.toLowerCase() == alias.toLowerCase(),
    ))
      throw const SessionFailure('alias_duplicate');
    profile.alias = alias;
    profile.color = color;
  }

  @override
  Future<void> reorderProfiles(List<String> profileIds) async {
    calls.add('reorder');
    for (var i = 0; i < profileIds.length; i++)
      records[profileIds[i]]!.orderIndex = i;
  }

  @override
  Future<void> setObservation(
    String profileId,
    AuthObservation observation,
  ) async => records[profileId]!.observation = observation;

  @override
  Future<ViewHandle> openProfile(
    String profileId,
    String operationId,
    int selectionGeneration,
  ) async {
    calls.add('open:$profileId');
    await pendingOpens[profileId]?.future;
    if (openError != null) throw openError!;
    if (records[profileId]?.state != StoreState.available)
      throw const SessionFailure('profile_unavailable');
    if (active != null) throw const SessionFailure('second_live_view');
    final view = ViewHandle(
      profileId: profileId,
      viewInstanceId: 'view-${++nextView}',
      operationId: operationId,
      selectionGeneration: selectionGeneration,
    );
    active = view;
    if (readyBeforeOpenReturns) ready(view);
    return view;
  }

  @override
  Future<void> disposeView(ViewHandle view) async {
    calls.add('dispose:${view.profileId}');
    await pendingDisposals[view.profileId]?.future;
    if (disposeError != null) throw disposeError!;
    if (active?.viewInstanceId == view.viewInstanceId) active = null;
  }

  @override
  Future<void> reloadProfileView(ViewHandle view) async =>
      calls.add('reload:${view.profileId}');

  @override
  Future<void> requestLocalRemoval(
    String profileId,
    String cleanupOperationId,
  ) async {
    calls.add('remove:$profileId');
    final profile = records[profileId];
    if (profile == null) return;
    profile.state = StoreState.removing;
    profile.cleanupOperationId ??= cleanupOperationId;
    profile.cleanupStage = 'requested';
    if (active?.profileId == profileId) active = null;
    await pendingRemovals[profileId]?.future;
    if (removalError != null) throw removalError!;
    if (removalFailures.contains(profileId))
      throw const SessionFailure('wipe_failed');
    if (!cleanupAvailable || deferContainerDeletion) {
      profile.state = StoreState.cleanupPending;
      profile.cleanupStage = cleanupAvailable
          ? 'containerDeletionPending'
          : 'websiteWipePending';
    } else {
      profile.cleanupStage = 'complete';
      records.remove(profileId);
    }
    emit(
      EngineEvent(
        kind: EngineEventKind.cleanupChanged,
        profileId: profileId,
        cleanupOperationId: profile.cleanupOperationId,
        cleanupStage: profile.cleanupStage,
      ),
    );
  }

  @override
  Future<void> retryPendingCleanup() async {
    for (final profile in records.values.toList()) {
      if (profile.state == StoreState.cleanupPending ||
          profile.state == StoreState.removing) {
        await requestLocalRemoval(profile.id, profile.cleanupOperationId!);
      }
    }
  }

  @override
  Future<void> setPrivacyCover(bool visible, ViewHandle? owner) async {
    calls.add('cover:$visible');
    await coverGate?.future;
    if (!visible) await revealGate?.future;
    if (!visible &&
        (locked ||
            active == null ||
            active!.viewInstanceId != owner?.viewInstanceId))
      throw const SessionFailure('invalid_reveal');
    covered = visible;
  }

  @override
  Future<void> cancelTransfer() async => calls.add('cancel_transfer');
  @override
  Future<void> lockApp() async {
    calls.add('lock');
    covered = true;
    if (lockError != null) throw lockError!;
    locked = true;
  }

  @override
  Future<bool> authenticate() async {
    calls.add('authenticate');
    await authenticationGate?.future;
    locked = !authenticated;
    return authenticated;
  }

  @override
  Future<void> setPreferences(AppPreferences value) async {
    preferences = value;
  }

  @override
  Future<void> resetProfilePermissions(String profileId) async =>
      calls.add('reset_permissions:$profileId');
  @override
  Future<void> openHelp(HelpTopic topic) async {}
  @override
  Future<void> exportDiagnostics() async {}
  @override
  Future<void> setWorkspaceLayout(
    ViewHandle view,
    WorkspaceLayout layout,
  ) async => calls.add('layout:${view.profileId}:${layout.name}');
  @override
  Future<void> showWorkspaceList(ViewHandle view) async =>
      calls.add('show_list:${view.profileId}');
  @override
  Future<WorkspacePresentation> getWorkspacePresentation(
    ViewHandle view,
  ) async {
    calls.add('presentation:${view.profileId}');
    presentationCalls.add(view);
    return await presentationReply ?? presentation;
  }

  @override
  Future<String?> pickAccountSetupArchive() async {
    calls.add('pick_setup');
    return setupArchiveToPick;
  }

  @override
  Future<bool> exportAccountSetupArchive() async {
    calls.add('export_setup');
    return setupExportCompleted;
  }

  @override
  Future<List<AccountProfile>> importAccountSetupArchive(
    String archive,
    bool applyAppearance,
  ) async {
    calls.add('import_setup');
    if (setupImportError != null) throw setupImportError!;
    final decoded = jsonDecode(archive) as Map<String, dynamic>;
    final rows = decoded['accounts'] as List;
    if (rows.length + records.length > 10)
      throw const SessionFailure('capacity');
    final names = records.values.map((p) => p.alias.toLowerCase()).toSet();
    for (final row in rows) {
      if (!names.add((row['alias'] as String).toLowerCase())) {
        throw const SessionFailure('duplicateAlias');
      }
    }
    await setupImportGate?.future;
    final imported = <AccountProfile>[];
    for (final row in rows) {
      imported.add(
        seed('imported-${++nextProfile}', alias: row['alias'] as String)
          ..color = row['color'] as int,
      );
    }
    if (applyAppearance)
      preferences.theme = decoded['appearance']['theme'] as String;
    emit(EngineEvent(kind: EngineEventKind.profilesChanged));
    return imported;
  }

  Future<void> close() => eventController.close();
}
