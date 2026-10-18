import Flutter
import UIKit
import WebKit
import LocalAuthentication
import Network

@MainActor
public final class SessionEnginePlugin: NSObject, FlutterPlugin, SessionHostApi, NativeTransferHost, AccountArchiveHost {
    private static var registeredEngine: SessionEnginePlugin?
    private static var detachment: Task<Void, Never>?
    let host = SessionHostView()
    private let windowCover = WindowPrivacyCover(frame: .zero)
    private var registry: ProfileRegistry?
    private var initialized = false
    private var detached = false
    private var initialization: Task<Void, Error>?
    private var current: BoundWebSession?
    private var latestGeneration: Int64 = -1
    private var lockAuthority = NativeLockState()
    private var locked: Bool { lockAuthority.locked }
    private var explicitCover = true
    private var inBackground = false
    private var authenticating = false
    private var cleanupRunning = Set<String>()
    private var cleanupPasses = 0
    private var cleanupWaiters = [CheckedContinuation<Void, Never>]()
    private var authenticationContext: LAContext?
    private let registrar: FlutterPluginRegistrar
    private var presenter: UIViewController? { registrar.viewController ?? host.window?.rootViewController }
    private let events: SessionFlutterApi
    private var observers = [NSObjectProtocol]()
    private var rootDirectory: URL
    private var transfers: NativeTransfers!
    private var archives: NativeAccountArchives!
    private var importAllocations: ImportAllocationJournal?
    private let pathMonitor = NWPathMonitor()
    private var networkObservation: NetworkObservation = .unknown

    private init(registrar: FlutterPluginRegistrar) {
        events = SessionFlutterApi(binaryMessenger: registrar.messenger())
        self.registrar = registrar
        rootDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("ProfileDesk", isDirectory: true)
        super.init()
        transfers = NativeTransfers(engine: self)
        archives = NativeAccountArchives(host: self)
        windowCover.unlock = { [weak self] in self?.emit(EngineEvent(kind: .unlockRequested)) }
        observeLifecycle()
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let observation: NetworkObservation = path.status == .satisfied ? .reachable : .offline
            Task { @MainActor [weak self] in
                guard let self, self.networkObservation != observation else { return }
                self.networkObservation = observation
                self.emit(EngineEvent(kind: .networkChanged, network: observation))
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "dev.profiledesk.network-path"))
    }

    public nonisolated static func register(with registrar: FlutterPluginRegistrar) {
        MainActor.assumeIsolated {
        // Only one engine may own a WKWebView, including accidental additional scenes.
        guard registeredEngine == nil else { return }
        let plugin = SessionEnginePlugin(registrar: registrar)
        registeredEngine = plugin
        // Flutter only delivers detachFromEngine to a published plugin instance.
        registrar.publish(plugin)
        SessionHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin)
        registrar.register(SessionHostFactory(engine: plugin), withId: "profile_desk/session")
        }
    }

    public nonisolated func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        MainActor.assumeIsolated {
            // A late detach from another registrar must never release this owner.
            guard self.registrar === registrar, !detached, Self.registeredEngine === self else { return }
            detached = true
            explicitCover = true; host.covered = true
            lockAuthority.lock(); authenticationContext?.invalidate()
            let pendingInitialization = initialization
            pendingInitialization?.cancel()
            transfers.cancel()
            archives.cancel()
            disposeCurrent()
            windowCover.removeFromSuperview(); host.removeFromSuperview()
            observers.forEach { NotificationCenter.default.removeObserver($0) }
            observers.removeAll()
            pathMonitor.cancel()
            SessionHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
            let previous = Self.detachment
            Self.detachment = Task { @MainActor [self] in
                await previous?.value
                await transfers.waitForCancellation()
                // Public deletion may complete after Flutter detaches. Let its
                // durable journal settle before another engine reconciles it.
                _ = await pendingInitialization?.result
                if cleanupPasses > 0 {
                    await withCheckedContinuation { cleanupWaiters.append($0) }
                }
            }
            Self.registeredEngine = nil
        }
    }

    private func safe<T>(_ operation: () async throws -> T) async throws -> T {
        guard !detached else { throw PigeonError(code: "unavailable", message: "The native engine has detached.", details: nil) }
        do { return try await operation() }
        catch let failure as SessionFailure { throw PigeonError(code: failure.code, message: "The operation could not complete. Use the account recovery controls.", details: nil) }
        catch let failure as PigeonError { throw failure }
        catch { throw PigeonError(code: "nativeFailure", message: "The operation could not complete safely.", details: nil) }
    }

    private func database() throws -> ProfileRegistry {
        guard !detached, let registry else { throw SessionFailure.unavailable }; return registry
    }

    private func prepare() async throws {
        guard !detached else { throw SessionFailure.unavailable }
        if initialized { return }
        if let initialization {
            try await initialization.value
            guard !detached else { throw SessionFailure.unavailable }
            return
        }
        let previousDetachment = Self.detachment
        let task = Task { @MainActor in
            // Old transfer workers must finish cancellation before startup may
            // clean staging or bind a replacement engine's account view.
            await previousDetachment?.value
            try Task.checkCancellation()
            let registry = try ProfileRegistry(url: rootDirectory.appendingPathComponent("registry.sqlite3"))
            self.registry = registry
            try InstallationBinding().verifyOrQuarantine(registry: registry, directory: rootDirectory)
            self.importAllocations = ImportAllocationJournal(directory: rootDirectory,
                bindingNonce: try registry.preference("installationNonce", fallback: ""))
            self.lockAuthority = NativeLockState(locked: try registry.preference("lockEnabled", fallback: "false") == "true")
            // Initialize WebKit's main run loop without loading any persistent profile.
            // Cold inventory before initialization crashes affected system WebKit builds.
            WebKitBootstrap.initialize()
            // Failures leave only journal-owned empty orphans quarantined. They
            // must not prevent ordinary existing accounts from being recovered.
            try? await self.recoverImportAllocations()
            // Honor all tombstones before any named-store constructor or view can run.
            try await self.performCleanup()
            try Task.checkCancellation()
            let inventory = await WKWebsiteDataStore.allDataStoreIdentifiers
            try Task.checkCancellation()
            try registry.reconcile(inventory: Set(inventory.map { $0.uuidString.lowercased() }))
            // Transfers cannot survive process death; no callback owns restored files.
            let staging = rootDirectory.appendingPathComponent("Transfers", isDirectory: true)
            if FileManager.default.fileExists(atPath: staging.path) { try FileManager.default.removeItem(at: staging) }
            let archives = rootDirectory.appendingPathComponent("AccountArchives", isDirectory: true)
            if FileManager.default.fileExists(atPath: archives.path) { try FileManager.default.removeItem(at: archives) }
            self.initialized = true
            self.refreshCover()
        }
        initialization = task
        do {
            try await task.value; initialization = nil
            guard !detached else { throw SessionFailure.unavailable }
        }
        catch { initialization = nil; throw error }
    }

    func initialize() async throws -> EngineSnapshot {
        try await safe {
            try await prepare()
            return EngineSnapshot(capabilities: capabilities(), profiles: try profiles(), preferences: try preferences(), locked: locked, transferActive: transfers.active, network: networkObservation)
        }
    }

    func queryCapabilities() async throws -> EngineCapabilities { try await safe { capabilities() } }

    private func capabilities() -> EngineCapabilities {
        let context = LAContext()
        let available = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return EngineCapabilities(supported: true, platform: "iOS", osVersion: UIDevice.current.systemVersion, providerVersion: "System WebKit", multiProfile: true, scopedDeletion: true, authenticationAvailable: available, downloadsSupported: true, captureSupported: false, reason: "Official website compatibility and media require device validation. Camera, microphone and calls are disabled.")
    }

    private func profiles() throws -> [AccountProfile] {
        let db = try database()
        let journal = try db.cleanups()
        return try db.list().map { item in
            let cleanup = journal.first { $0.profileId == item.id }
            let state: StoreState
            switch item.lifecycle {
            case "available": state = .available
            case "removing": state = .removing
            case "cleanupPending": state = .cleanupPending
            case "missing": state = .missing
            case "quarantined": state = .quarantined
            default: state = .allocating
            }
            let observation: AuthObservation = item.observation == "userConfirmed" ? .userConfirmed : item.observation == "relinkRequested" ? .relinkRequested : .unknown
            return AccountProfile(id: item.id, platformProfileId: item.id, alias: item.alias, color: item.color, orderIndex: item.order, createdAt: item.createdAt, lastOpenedAt: item.lastOpenedAt, state: state, observation: observation, cleanupOperationId: cleanup?.operationId, cleanupStage: cleanup?.stage)
        }
    }

    func listProfiles() async throws -> [AccountProfile] { try await safe { try await prepare(); return try profiles() } }

    func allocateProfile(alias: String, color: Int64) async throws -> AccountProfile {
        try await safe {
            try await prepare()
            let db = try database()
            let item = try db.reserve(alias: alias, color: color)
            // The store handle is intentionally not retained and never substitutes a default store.
            _ = WKWebsiteDataStore(forIdentifier: UUID(uuidString: item.id)!)
            try db.setLifecycle(item.id, "available")
            emit(EngineEvent(kind: .profilesChanged))
            return try profiles().first { $0.id == item.id }!
        }
    }

    func renameProfile(profileId: String, alias: String, color: Int64) async throws {
        try await safe { try await prepare(); try database().rename(profileId, alias: alias, color: color); emit(EngineEvent(kind: .profilesChanged)) }
    }
    func reorderProfiles(profileIds: [String]) async throws {
        try await safe { try await prepare(); try database().reorder(profileIds); emit(EngineEvent(kind: .profilesChanged)) }
    }
    func setObservation(profileId: String, observation: AuthObservation) async throws {
        try await safe {
            try await prepare()
            try database().observe(profileId, value: observation == .userConfirmed ? "userConfirmed" : observation == .relinkRequested ? "relinkRequested" : "unknown")
            emit(EngineEvent(kind: .profilesChanged))
        }
    }

    func openProfile(profileId: String, operationId: String, selectionGeneration: Int64) async throws -> ViewHandle {
        try await safe {
            try await prepare()
            if let current, current.handle.profileId == profileId, current.handle.operationId == operationId, current.handle.selectionGeneration == selectionGeneration { return current.handle }
            guard selectionGeneration > latestGeneration else { throw SessionFailure.staleOperation }
            guard !locked else { throw SessionFailure.authentication }
            guard !inBackground, UIApplication.shared.applicationState == .active else { throw SessionFailure.blocked }
            guard !transfers.active, !archives.active, !hasPresentedController else { throw SessionFailure.busy }
            let record = try database().profile(profileId)
            guard record.lifecycle == "available", let storeId = UUID(uuidString: record.id) else { throw SessionFailure.blocked }
            latestGeneration = selectionGeneration
            explicitCover = true; refreshCover()
            disposeCurrent()
            let inventory = await WKWebsiteDataStore.allDataStoreIdentifiers
            guard !detached, selectionGeneration == latestGeneration, !locked, !inBackground, UIApplication.shared.applicationState == .active,
                  !transfers.active, !archives.active, !hasPresentedController,
                  try database().profile(profileId).lifecycle == "available" else { throw SessionFailure.staleOperation }
            guard inventory.contains(storeId) else {
                try database().observe(profileId, value: "unknown")
                try database().setLifecycle(profileId, "missing")
                emit(EngineEvent(kind: .profilesChanged))
                throw SessionFailure.missingProfile
            }
            let handle = ViewHandle(profileId: profileId, viewInstanceId: UUID().uuidString.lowercased(), operationId: operationId, selectionGeneration: selectionGeneration)
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: storeId)
            configuration.defaultWebpagePreferences.preferredContentMode = .desktop
            configuration.applicationNameForUserAgent = WorkspaceBrowserPolicy.applicationName(
                bundleIdentifier: Bundle.main.bundleIdentifier,
                operatingSystem: ProcessInfo.processInfo.operatingSystemVersion
            )
            configuration.limitsNavigationsToAppBoundDomains = true
            configuration.allowsInlineMediaPlayback = false
            configuration.mediaTypesRequiringUserActionForPlayback = .all
            let web = WorkspaceWebView(frame: host.bounds, configuration: configuration)
            guard web.hasLayoutAdapter else { throw SessionFailure.unavailable }
            web.isInspectable = false
            let session = BoundWebSession(handle: handle, webView: web, engine: self)
            current = session
            web.canObserveLayout = { [weak self, weak web] in
                guard let self, let web else { return false }
                return self.isUsable(handle) && self.current?.webView === web && self.current?.ready == true
            }
            host.attach(web)
            try database().opened(profileId)
            session.load(URLRequest(url: URL(string: "https://web.whatsapp.com/")!))
            return handle
        }
    }

    func disposeView(view: ViewHandle) async throws {
        try await safe { if current?.handle == view { explicitCover = true; refreshCover(); disposeCurrent() } }
    }
    func reloadProfileView(view: ViewHandle) async throws {
        try await safe {
            guard owns(view), !locked, !transfers.active, !archives.active, !hasPresentedController else { throw SessionFailure.blocked }
            explicitCover = true; current?.ready = false; refreshCover()
            (current?.webView as? WorkspaceWebView)?.setPresentationLayout(.phone)
            current?.reload()
        }
    }

    func setWorkspaceLayout(view: ViewHandle, layout: WorkspaceLayout) async throws {
        try await safe {
            guard isUsable(view), current?.ready == true, let web = current?.webView as? WorkspaceWebView,
                  let url = web.url, WorkspaceURLPolicy.isWorkspace(url) else { throw SessionFailure.staleOperation }
            web.setPresentationLayout(layout)
            try await web.applyPresentationLayout()
            guard isUsable(view), current?.webView === web else { throw SessionFailure.staleOperation }
        }
    }

    func showWorkspaceList(view: ViewHandle) async throws {
        try await safe {
            guard isUsable(view), current?.ready == true, let web = current?.webView as? WorkspaceWebView else { throw SessionFailure.staleOperation }
            try await web.showList()
            guard isUsable(view), current?.webView === web else { throw SessionFailure.staleOperation }
        }
    }

    func getWorkspacePresentation(view: ViewHandle) async throws -> WorkspacePresentation {
        try await safe {
            guard isUsable(view), current?.ready == true, let web = current?.webView as? WorkspaceWebView,
                  let url = web.url, WorkspaceURLPolicy.isWorkspace(url) else { throw SessionFailure.staleOperation }
            let result = try await web.workspacePresentation()
            guard isUsable(view), current?.ready == true, current?.webView === web,
                  let url = web.url, WorkspaceURLPolicy.isWorkspace(url) else { throw SessionFailure.staleOperation }
            return result
        }
    }

    func requestLocalRemoval(profileId: String, cleanupOperationId: String) async throws {
        try await safe {
            try await prepare()
            guard !cleanupOperationId.isEmpty else { throw SessionFailure.staleOperation }
            _ = try database().requestRemoval(profileId, operationId: cleanupOperationId)
            if current?.handle.profileId == profileId { explicitCover = true; refreshCover(); transfers.cancel(); disposeCurrent() }
            emit(EngineEvent(kind: .profilesChanged))
            try await performCleanup()
        }
    }

    func retryPendingCleanup() async throws {
        try await safe { try await prepare(); try await performCleanup(); try await recoverImportAllocations() }
    }

    private func recoverImportAllocations() async throws {
        guard let journal = importAllocations else { throw SessionFailure.storage }
        let db = try database()
        let knownIdentifiers = Set(try db.list(includeRemoved: true).map(\.id))
        for id in try journal.unassigned(knownIdentifiers: knownIdentifiers) {
            // A committed row (including a tombstone) always outranks this
            // allocation journal. Never target an existing account's store.
            if try db.list(includeRemoved: true).contains(where: { $0.id == id }) {
                try journal.completed(id)
                continue
            }
            guard let identifier = UUID(uuidString: id) else { throw SessionFailure.storage }
            let inventory = await WKWebsiteDataStore.allDataStoreIdentifiers
            guard !detached, !Task.isCancelled else { throw SessionFailure.unavailable }
            // Recheck durable ownership after the await before public deletion.
            guard try db.list(includeRemoved: true).allSatisfy({ $0.id != id }) else { continue }
            if inventory.contains(identifier) { try await WKWebsiteDataStore.remove(forIdentifier: identifier) }
            guard !detached, !Task.isCancelled else { throw SessionFailure.unavailable }
            try db.clearQuarantinedImportStore(id)
            try journal.completed(id)
        }
    }

    private func performCleanup() async throws {
        cleanupPasses += 1
        defer {
            cleanupPasses -= 1
            if cleanupPasses == 0 {
                let waiters = cleanupWaiters; cleanupWaiters.removeAll()
                waiters.forEach { $0.resume() }
            }
        }
        let db = try database()
        for record in try db.cleanups() {
            guard !cleanupRunning.contains(record.profileId) else { continue }
            cleanupRunning.insert(record.profileId)
            defer { cleanupRunning.remove(record.profileId) }
            do {
                if current?.handle.profileId == record.profileId { explicitCover = true; refreshCover(); transfers.cancel(); disposeCurrent() }
                await transfers.waitForCancellation()
                try db.cleanupStage(record.profileId, "clientsDisposed")
                guard let identifier = UUID(uuidString: record.profileId) else { throw SessionFailure.storage }
                // Public inventory prevents accidentally creating a tombstoned missing store.
                if await WKWebsiteDataStore.allDataStoreIdentifiers.contains(identifier) {
                    try db.cleanupStage(record.profileId, "websiteWipePending")
                    try await WKWebsiteDataStore.remove(forIdentifier: identifier)
                }
                try db.cleanupStage(record.profileId, "appDataCleanupPending")
                try transfers.removeFiles(profileId: record.profileId)
                try db.cleanupStage(record.profileId, "complete")
                emit(EngineEvent(kind: .cleanupChanged, profileId: record.profileId, cleanupOperationId: record.operationId, cleanupStage: "complete"))
            } catch {
                try db.cleanupStage(record.profileId, "websiteWipePending", error: "cleanupFailed")
                emit(EngineEvent(kind: .cleanupChanged, profileId: record.profileId, cleanupOperationId: record.operationId, cleanupStage: "websiteWipePending", errorCode: "cleanupPending"))
            }
        }
    }

    func setPrivacyCover(visible: Bool, owner: ViewHandle?) async throws {
        try await safe {
            if visible { explicitCover = true; refreshCover(); return }
            guard let owner, owns(owner), current?.ready == true, !locked, !inBackground, UIApplication.shared.applicationState == .active,
                  try database().profile(owner.profileId).lifecycle == "available" else { throw SessionFailure.blocked }
            explicitCover = false; refreshCover()
        }
    }

    func cancelTransfer() async throws {
        try await safe {
            let presented = presenter?.presentedViewController
            transfers.cancel()
            archives.cancel()
            await transfers.waitForCancellation()
            guard !detached else { throw SessionFailure.unavailable }
            if let presented, presenter?.presentedViewController === presented { presented.dismiss(animated: false) }
        }
    }

    func authenticate() async throws -> Bool {
        try await safe {
            try await prepare()
            guard !detached else { throw SessionFailure.unavailable }
            guard !authenticating else { throw SessionFailure.busy }
            let context = LAContext()
            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { windowCover.authenticationFailed(); throw SessionFailure.authentication }
            let ticket = lockAuthority.beginAuthentication()
            authenticating = true; authenticationContext = context
            refreshCover()
            defer { authenticating = false; authenticationContext = nil; refreshCover() }
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your saved account profiles")
                guard lockAuthority.finishAuthentication(ticket, success:success, foreground:!inBackground && UIApplication.shared.applicationState == .active) else { windowCover.authenticationFailed(); return false }
                current?.webView.setAllMediaPlaybackSuspended(false, completionHandler: nil)
                refreshCover(); emit(EngineEvent(kind: .privacyChanged, locked: false))
                return true
            } catch { windowCover.authenticationFailed(); _ = lockAuthority.finishAuthentication(ticket, success:false, foreground:!inBackground && UIApplication.shared.applicationState == .active); refreshCover(); if locked { emit(EngineEvent(kind: .privacyChanged, locked: true)) }; return false }
        }
    }

    func lockApp() async throws {
        try await safe {
            try await prepare()
            guard try preferences().lockEnabled else { throw SessionFailure.authentication }
            lockAuthority.lock()
            authenticationContext?.invalidate()
            explicitCover = true
            refreshCover()
            transfers.cancel()
            archives.cancel()
            current?.webView.setAllMediaPlaybackSuspended(true, completionHandler: nil)
            emit(EngineEvent(kind: .privacyChanged, locked: true))
        }
    }

    private func preferences() throws -> AppPreferences {
        let db = try database()
        return AppPreferences(lockEnabled: try db.preference("lockEnabled", fallback: "false") == "true", welcomeSeen: try db.preference("welcomeSeen", fallback: "false") == "true", switchWarningSeen: try db.preference("switchWarningSeen", fallback: "false") == "true", theme: try db.preference("theme", fallback: "system"))
    }

    func setPreferences(preferences value: AppPreferences) async throws {
        try await safe {
            try await prepare()
            guard ["system","light","dark"].contains(value.theme) else { throw SessionFailure.invalidPreference }
            let old = try preferences()
            if old.lockEnabled != value.lockEnabled {
                guard try await authenticate() else { throw SessionFailure.authentication }
            }
            guard !detached else { throw SessionFailure.unavailable }
            let db = try database()
            try db.setPreference("lockEnabled", String(value.lockEnabled))
            try db.setPreference("welcomeSeen", String(value.welcomeSeen))
            try db.setPreference("switchWarningSeen", String(value.switchWarningSeen))
            try db.setPreference("theme", value.theme)
            emit(EngineEvent(kind: .profilesChanged))
        }
    }

    func resetProfilePermissions(profileId: String) async throws {
        try await safe { try await prepare(); try database().resetPermissions(profileId) }
    }

    func openHelp(topic: HelpTopic) async throws {
        try await safe {
            let path: String
            switch topic { case .linking: path = "https://faq.whatsapp.com/378279804439436/"; case .remoteUnlink: path = "https://faq.whatsapp.com/378279804439436/"; case .serviceHelp: path = "https://faq.whatsapp.com/" }
            _ = await UIApplication.shared.open(URL(string: path)!)
        }
    }

    func exportDiagnostics() async throws {
        try await safe {
            try await prepare()
            let profiles = try database().list()
            let pending = try database().cleanups().count
            let quarantine = try database().quarantinedCount()
            let report = NativeDiagnostics.render(osVersion: UIDevice.current.systemVersion, profiles: profiles, pendingCleanupCount: pending, quarantinedStoreCount: quarantine)
            presentShare(items: [report])
        }
    }

    var archiveUsable: Bool { !detached && !locked && !inBackground && UIApplication.shared.applicationState == .active && !transfers.active }
    var archiveRoot: URL { rootDirectory.appendingPathComponent("AccountArchives", isDirectory: true) }

    func pickAccountSetupArchive() async throws -> String? {
        try await safe {
            try await prepare()
            guard archiveUsable, !archives.active, !hasPresentedController else { throw SessionFailure.busy }
            let result = try await archives.pick()
            guard !detached, !locked, !inBackground else { throw SessionFailure.staleOperation }
            return result
        }
    }

    func exportAccountSetupArchive() async throws -> Bool {
        try await safe {
            try await prepare()
            guard archiveUsable, !archives.active, !hasPresentedController else { throw SessionFailure.busy }
            let result = try await archives.export(try database().exportSetup())
            guard !detached, !locked, !inBackground else { throw SessionFailure.staleOperation }
            return result
        }
    }

    func importAccountSetupArchive(archive: String, applyAppearance: Bool) async throws -> [AccountProfile] {
        try await safe {
            try await prepare()
            guard archiveUsable, !archives.active, !hasPresentedController else { throw SessionFailure.busy }
            let decoded = try AccountSetupArchive.decode(archive)
            try await recoverImportAllocations()
            guard archiveUsable, !archives.active, !hasPresentedController, let journal = importAllocations else { throw SessionFailure.busy }
            let imported = try database().importSetup(decoded, applyAppearance: applyAppearance, prepareStores: journal.record) { id in
                // Fresh identifiers only. No browser bytes, original identifiers,
                // installation secrets or permissions are accepted from the file.
                _ = WKWebsiteDataStore(forIdentifier: UUID(uuidString: id)!)
            }
            // A failed journal clear is recoverable: startup sees the committed
            // rows and clears their journal entries without deleting their stores.
            for item in imported { try? journal.completed(item.id) }
            emit(EngineEvent(kind: .profilesChanged))
            let ids = Set(imported.map(\.id))
            return try profiles().filter { ids.contains($0.id) }
        }
    }

    func owns(_ handle: ViewHandle) -> Bool { !detached && current?.handle == handle && handle.selectionGeneration == latestGeneration }
    func isUsable(_ handle: ViewHandle) -> Bool { owns(handle) && !locked && !inBackground && UIApplication.shared.applicationState == .active }
    var hasPresentedController: Bool { presenter?.presentedViewController != nil }
    var transferRoot: URL { rootDirectory.appendingPathComponent("Transfers", isDirectory: true) }

    func sessionReady(_ session: BoundWebSession) {
        guard owns(session.handle) else { return }
        session.ready = true
        emit(EngineEvent(kind: .viewReady, profileId: session.handle.profileId, view: session.handle))
    }
    func sessionFailed(_ session: BoundWebSession, code: String) {
        guard owns(session.handle) else { return }
        explicitCover = true; refreshCover()
        emit(EngineEvent(kind: .viewFailed, profileId: session.handle.profileId, view: session.handle, errorCode: code))
        if code == "rendererTerminated" { disposeCurrent() }
    }
    func beginDownload(_ download: WKDownload, session: BoundWebSession) {
        guard !archives.active else { download.cancel { _ in }; return }
        transfers.begin(download, owner: session.handle)
    }
    func transferState() { emit(EngineEvent(kind: .transferChanged, profileId: current?.handle.profileId, view: current?.handle, transferActive: transfers.active, progress: transfers.progress)) }
    func transferFailed(_ owner: ViewHandle, code: String) { emit(EngineEvent(kind: .transferChanged, profileId: owner.profileId, view: owner, errorCode: code, transferActive: transfers.active)) }
    func present(_ controller: UIViewController) -> Bool {
        guard !detached, !locked, !inBackground, let presenter, presenter.presentedViewController == nil else { return false }
        presenter.present(controller, animated: true); return true
    }
    func presentShare(items: [Any], completion: (() -> Void)? = nil) {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _,_,_,_ in completion?() }
        controller.popoverPresentationController?.sourceView = host
        controller.popoverPresentationController?.sourceRect = CGRect(x: host.bounds.midX, y: host.bounds.midY, width: 1, height: 1)
        if !present(controller) { completion?() }
    }
    @available(iOS 18.4, *)
    func pickFiles(session: BoundWebSession, parameters: WKOpenPanelParameters, completion: @escaping ([URL]?) -> Void) {
        guard !archives.active else { completion(nil); return }
        transfers.pick(owner: session.handle, multiple: parameters.allowsMultipleSelection, completion: completion)
    }

    private func disposeCurrent() {
        guard let session = current else { return }
        transfers.cancel(owner: session.handle)
        session.dispose()
        if !transfers.active { try? transfers.removeFiles(profileId: session.handle.profileId) }
        current = nil
    }
    private func emit(_ event: EngineEvent) {
        guard !detached else { return }
        Task { @MainActor [weak self] in
            guard let self, !self.detached else { return }
            try? await self.events.onEvent(event: event)
        }
    }
    private func refreshCover() {
        guard !detached else { return }
        let foreground = UIApplication.shared.applicationState == .active && !inBackground
        let covered = explicitCover || locked || !foreground
        if covered { (current?.webView as? WorkspaceWebView)?.invalidatePresentationEligibility() }
        host.covered = covered
        if !foreground || locked {
            windowCover.show(in: presenter?.view.window ?? host.window, allowUnlock: foreground && locked, authenticating: authenticating)
        } else { windowCover.removeFromSuperview() }
    }
    private func observeLifecycle() {
        let center = NotificationCenter.default
        for name in [UIApplication.willResignActiveNotification, UIScene.willDeactivateNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, !self.detached else { return }
                    (self.current?.webView as? WorkspaceWebView)?.invalidatePresentationEligibility()
                    self.host.covered = true
                    self.windowCover.show(in: self.presenter?.view.window ?? self.host.window, allowUnlock: false, authenticating: self.authenticating)
                    self.current?.webView.setAllMediaPlaybackSuspended(true, completionHandler: nil)
                }
            })
        }
        for name in [UIApplication.didEnterBackgroundNotification, UIScene.didEnterBackgroundNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, !self.detached else { return }
                    self.inBackground = true
                    if (try? self.preferences().lockEnabled) ?? true { self.lockAuthority.lock() }
                    else { self.lockAuthority.invalidateAuthentication() }
                    self.authenticationContext?.invalidate()
                    self.transfers.cancel()
                    self.archives.cancel()
                    self.refreshCover()
                    if self.locked { self.emit(EngineEvent(kind: .privacyChanged, locked: true)) }
                }
            })
        }
        for name in [UIApplication.didBecomeActiveNotification, UIScene.didActivateNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, !self.detached else { return }
                    self.inBackground = false; self.refreshCover()
                    if !self.locked { self.current?.webView.setAllMediaPlaybackSuspended(false, completionHandler: nil) }
                    self.emit(EngineEvent(kind: .privacyChanged, locked: self.locked))
                }
            })
        }
    }
}
