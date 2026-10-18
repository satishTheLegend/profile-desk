import Flutter
import UIKit
import WebKit

// This disposable simulator fixture compiles the production plugin and transfer
// callbacks unchanged. Only the Flutter messenger/registrar and presentation
// boundary are doubles; picker identity and file copying use actual UIKit/files.
final class Messenger: NSObject, FlutterBinaryMessenger {
    var handlers = [String: FlutterBinaryMessageHandler]()
    private var next: Int64 = 0
    func send(onChannel channel: String, message: Data?) {}
    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) { callback?(nil) }
    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> Int64 {
        handlers[channel] = handler; next += 1; return next
    }
    func cleanUpConnection(_ connection: Int64) {}
}

final class Textures: NSObject, FlutterTextureRegistry {
    func register(_ texture: FlutterTexture) -> Int64 { 0 }
    func textureFrameAvailable(_ textureId: Int64) {}
    func unregisterTexture(_ textureId: Int64) {}
}

final class Registrar: NSObject, FlutterPluginRegistrar {
    let bus = Messenger()
    let textureRegistry = Textures()
    var published: NSObject?
    var factory: FlutterPlatformViewFactory?
    var viewController: UIViewController?
    func messenger() -> FlutterBinaryMessenger { bus }
    func textures() -> FlutterTextureRegistry { textureRegistry }
    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) { self.factory = factory }
    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String, gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) { self.factory = factory }
    func publish(_ value: NSObject) { published = value }
    func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {}
    func addApplicationDelegate(_ delegate: FlutterPlugin) {}
    func addSceneDelegate(_ delegate: FlutterSceneLifeCycleDelegate) {}
    func lookupKey(forAsset asset: String) -> String { asset }
    func lookupKey(forAsset asset: String, fromPackage package: String) -> String { asset }
    func valuePublished(byPlugin pluginKey: String) -> NSObject? { published }
}

@MainActor
final class TransferHost: NativeTransferHost {
    var owner: ViewHandle
    let transferRoot: URL
    var presented: UIDocumentPickerViewController?
    init(owner: ViewHandle, root: URL) { self.owner = owner; transferRoot = root }
    func isUsable(_ handle: ViewHandle) -> Bool { handle == owner }
    func present(_ controller: UIViewController) -> Bool { presented = controller as? UIDocumentPickerViewController; return true }
    func presentShare(items: [Any], completion: (() -> Void)?) { completion?() }
    func transferState() {}
    func transferFailed(_ owner: ViewHandle, code: String) {}
}

@MainActor
final class ArchiveHost: AccountArchiveHost {
    var archiveUsable = true
    let archiveRoot: URL
    var presented: UIDocumentPickerViewController?
    init(root: URL) { archiveRoot = root }
    func present(_ controller: UIViewController) -> Bool { presented = controller as? UIDocumentPickerViewController; return true }
}

@MainActor
final class Checks {
    var results = [[String: Any]]()
    func expect(_ condition: Bool, _ name: String) { results.append(["name": name, "pass": condition]) }
    func handle(_ generation: Int64) -> ViewHandle {
        ViewHandle(profileId: UUID().uuidString.lowercased(), viewInstanceId: UUID().uuidString.lowercased(), operationId: "fixture-\(generation)", selectionGeneration: generation)
    }
    func pickerCallbacks() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("fixture.txt")
        try Data("synthetic-original-selection".utf8).write(to: source)
        for staleResult in [false, true] {
            let a = handle(1), b = handle(2)
            let host = TransferHost(owner: a, root: root.appendingPathComponent(UUID().uuidString))
            let transfers = NativeTransfers(engine: host)
            var firstCallbacks = 0, secondCallbacks = 0
            var secondURLs: [URL]?
            transfers.pick(owner: a, multiple: false) { _ in firstCallbacks += 1 }
            let oldPicker = host.presented!
            transfers.cancel(owner: a)
            expect(firstCallbacks == 1, "old picker cancellation completes exactly once")
            host.owner = b
            transfers.pick(owner: b, multiple: false) { secondCallbacks += 1; secondURLs = $0 }
            let newPicker = host.presented!
            if staleResult {
                transfers.documentPicker(oldPicker, didPickDocumentsAt: [source])
                await transfers.waitForCancellation()
            } else { transfers.documentPickerWasCancelled(oldPicker) }
            expect(secondCallbacks == 0 && transfers.active, staleResult ? "stale result cannot complete replacement owner" : "stale cancellation cannot cancel replacement owner")
            if secondCallbacks == 0 {
                transfers.documentPicker(newPicker, didPickDocumentsAt: [source])
                await transfers.waitForCancellation()
                expect(secondCallbacks == 1 && secondURLs?.count == 1, "current picker delivers one result")
                if let destination = secondURLs?.first {
                    expect(destination.path.contains(b.profileId), "current result stays in replacement profile staging")
                    expect(try Data(contentsOf: destination) == Data(contentsOf: source), "current file bytes preserved")
                }
                transfers.documentPickerWasCancelled(newPicker)
                expect(secondCallbacks == 1, "duplicate current callback cannot complete twice")
            }
            transfers.cancel()
            await transfers.waitForCancellation()
        }
    }
    func registration() async {
        let first = Registrar(), second = Registrar()
        SessionEnginePlugin.register(with: first)
        expect(!first.bus.handlers.isEmpty && first.factory != nil, "first engine registers channel and platform view")
        expect(first.published is SessionEnginePlugin, "plugin publishes instance for Flutter detach callback")
        SessionEnginePlugin.register(with: second)
        expect(second.bus.handlers.isEmpty, "second live engine cannot create another account view owner")
        if let plugin = first.published as? SessionEnginePlugin {
            // Invoke through Flutter's actual optional protocol entry point.
            (plugin as FlutterPlugin).detachFromEngine?(for: second)
            expect(!first.bus.handlers.isEmpty, "unrelated registrar cannot detach active engine")
            (plugin as FlutterPlugin).detachFromEngine?(for: first)
            expect(first.bus.handlers.isEmpty, "owned detach removes old channel handlers")
            do { _ = try await plugin.initialize(); expect(false, "detached old plugin rejects calls") }
            catch { expect(true, "detached old plugin rejects calls") }
            do { try await plugin.cancelTransfer(); expect(false, "detached transfer control rejects stale caller") }
            catch { expect(true, "detached transfer control rejects stale caller") }
            do { try await plugin.openHelp(topic: .serviceHelp); expect(false, "detached help request cannot open external UI") }
            catch { expect(true, "detached help request cannot open external UI") }
            do { _ = try await plugin.queryCapabilities(); expect(false, "detached capability request rejects stale caller") }
            catch { expect(true, "detached capability request rejects stale caller") }
            do { _ = try await plugin.pickAccountSetupArchive(); expect(false, "detached archive picker rejects stale caller") }
            catch { expect(true, "detached archive picker rejects stale caller") }
            do { _ = try await plugin.exportAccountSetupArchive(); expect(false, "detached archive export rejects stale caller") }
            catch { expect(true, "detached archive export rejects stale caller") }
            do { try await plugin.setWorkspaceLayout(view: handle(1), layout: .phone); expect(false, "detached layout control rejects stale caller") }
            catch { expect(true, "detached layout control rejects stale caller") }
            do { try await plugin.showWorkspaceList(view: handle(1)); expect(false, "detached list control rejects stale caller") }
            catch { expect(true, "detached list control rejects stale caller") }
            SessionEnginePlugin.register(with: second)
            expect(!second.bus.handlers.isEmpty && second.factory != nil && second.published is SessionEnginePlugin, "new engine registers after old engine detaches")
            (plugin as FlutterPlugin).detachFromEngine?(for: first)
            expect(!second.bus.handlers.isEmpty, "late old detach cannot clear new engine")
            (second.published as? FlutterPlugin)?.detachFromEngine?(for: second)
            expect(second.bus.handlers.isEmpty, "replacement engine detaches cleanly")
        }
    }
    func archiveCallbacks() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("fixture.json")
        let archive = AccountSetupArchive(accounts: [.init(alias: "Synthetic account", color: 4_280_371_038)], theme: "dark")
        let encoded = try archive.encoded()
        try Data(encoded.utf8).write(to: source)
        let host = ArchiveHost(root: root.appendingPathComponent("staging"))
        let files = NativeAccountArchives(host: host)
        let first = Task { @MainActor in try await files.pick() }
        await Task.yield()
        let stale = host.presented!
        files.cancel()
        expect(try await first.value == nil && !files.active, "archive cancellation completes once without metadata")
        let second = Task { @MainActor in try await files.pick() }
        await Task.yield()
        let current = host.presented!
        files.documentPicker(stale, didPickDocumentsAt: [source])
        files.documentPickerWasCancelled(stale)
        expect(files.active, "stale archive callbacks cannot finish replacement picker")
        files.documentPicker(current, didPickDocumentsAt: [source])
        expect(try await second.value == encoded, "current archive callback returns validated metadata only")
        expect(!files.active, "archive import releases its operation")
        let locked = Task { @MainActor in try await files.pick() }
        await Task.yield()
        let lockedPicker = host.presented!
        host.archiveUsable = false
        files.documentPicker(lockedPicker, didPickDocumentsAt: [source])
        expect(try await locked.value == nil, "locked archive callback cannot reveal preview metadata")
        host.archiveUsable = true
        let exported = Task { @MainActor in try await files.export(archive) }
        await Task.yield()
        let exportPicker = host.presented!
        let directories = try FileManager.default.contentsOfDirectory(at: host.archiveRoot, includingPropertiesForKeys: nil)
        expect(directories.count == 1, "archive export stages only one owned directory")
        let staged = directories[0].appendingPathComponent("ProfileDesk-Account-Setup.json")
        expect(try String(contentsOf: staged, encoding: .utf8) == encoded, "export stages the reviewed allowlisted JSON")
        files.documentPicker(exportPicker, didPickDocumentsAt: [source])
        expect(try await exported.value, "export success follows owned document-picker completion")
        expect(!FileManager.default.fileExists(atPath: directories[0].path), "successful export removes private staging")
        let cancelled = Task { @MainActor in try await files.export(archive) }
        await Task.yield()
        files.cancel()
        expect(try await !cancelled.value, "cancelled export reports false")
        expect(try FileManager.default.contentsOfDirectory(atPath: host.archiveRoot.path).isEmpty, "cancelled export removes private staging")
    }
    func run() async {
        await registration()
        do { try await pickerCallbacks() } catch { expect(false, "picker fixture threw \(type(of: error))") }
        do { try await archiveCallbacks() } catch { expect(false, "archive fixture threw \(type(of: error))") }
        let value: [String: Any] = ["result": results.allSatisfy { $0["pass"] as? Bool == true } ? "PASS" : "FAIL", "tests": results, "count": results.count, "os": UIDevice.current.systemVersion, "scope": "Actual production registration/detach and picker callbacks; registrar/presentation doubles; no service account or media delivery.", "timestamp": ISO8601DateFormatter().string(from: Date())]
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("result.json")
        try! JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Engine regression", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var started = false
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene); window.rootViewController = UIViewController(); window.makeKeyAndVisible(); self.window = window
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !started else { return }; started = true
        Task { @MainActor in await Checks().run() }
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
