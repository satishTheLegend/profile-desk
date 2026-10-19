import Foundation
import UIKit
import WebKit

private let fixtureURL = URL(string: "https://bootstrap.profiledesk.invalid/")!
private let ruleIdentifier = "dev.profiledesk.synthetic-origin-bootstrap.block-all"
private let inertHTML = """
<!doctype html><html><head><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'none'; connect-src 'none'; worker-src 'none'; frame-src 'none'; img-src 'none'; style-src 'none'; base-uri 'none'; form-action 'none'">
<title>Synthetic empty-origin probe</title></head><body>Fictional fixture only.</body></html>
"""

@MainActor
final class PendingResult<Value> {
    var continuation: CheckedContinuation<Value, Error>?
    var deadline: Task<Void, Never>?
    func finish(_ result: Result<Value, Error>) {
        guard let pending = continuation else { return }
        continuation = nil
        deadline?.cancel(); deadline = nil
        pending.resume(with: result)
    }
}

@MainActor
func bounded<Value>(_ start: (@escaping (Result<Value, Error>) -> Void) -> Void) async throws -> Value {
    let pending = PendingResult<Value>()
    defer { pending.deadline?.cancel() }
    return try await withCheckedThrowingContinuation { continuation in
        pending.continuation = continuation
        pending.deadline = Task { @MainActor [weak pending] in
            do { try await Task.sleep(for: .seconds(15)) } catch { return }
            pending?.finish(.failure(NSError(domain: "SyntheticWebKitDeadline", code: 1)))
        }
        start { [weak pending] result in pending?.finish(result) }
    }
}

@MainActor
final class NavigationWaiter: NSObject, WKNavigationDelegate {
    var finish: ((Result<Void, Error>) -> Void)?
    var unexpectedNavigationCount = 0
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finish?(.success(())) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { finish?(.failure(error)) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { finish?(.failure(error)) }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // loadHTMLString can internally name its initial navigation about:blank.
        // That is allowed only to measure it; environment assertions still
        // require the exact HTTPS location and origin, without coercion.
        let initial = action.targetFrame?.isMainFrame == true &&
            (action.request.url == fixtureURL || action.request.url?.absoluteString == "about:blank")
        if !initial { unexpectedNavigationCount += 1 }
        decisionHandler(initial ? .allow : .cancel)
    }
}

@MainActor
final class OriginBootstrapProbe: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    var waiter: NavigationWaiter?
    var rule: WKContentRuleList?
    // A WebView replacement must not also release the native data-store session.
    // Cold phases deliberately create new instances in separate app processes.
    var stores = [UUID: WKWebsiteDataStore]()
    var checks = [[String: Any]]()
    var observations = [[String: Any]]()
    var openedLabels = [String]()
    var stage = "initialize"
    let processInstanceID = UUID().uuidString
    var documents: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    var phase: String { CommandLine.arguments.first { $0.hasPrefix("--phase=") }?.replacingOccurrences(of: "--phase=", with: "") ?? "invalid" }

    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Probe", sessionRole: session.role)
        configuration.delegateClass = ProbeSceneDelegate.self
        return configuration
    }
    func start(_ scene: UIWindowScene) {
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible(); self.window = window
        Task { await run() }
    }
    func progress(_ value: String) {
        stage = value
        write(["phase": phase, "stage": stage, "assertions": checks.count], to: "progress.json")
    }
    func write(_ value: [String: Any], to filename: String) {
        if let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: documents.appendingPathComponent(filename), options: .atomic)
        }
    }
    func require(_ value: Bool, _ name: String) throws {
        checks.append(["name": name, "pass": value])
        if !value { throw NSError(domain: "SyntheticOriginAssertion", code: 1) }
    }
    func dispose() {
        webView?.stopLoading(); webView?.navigationDelegate = nil
        webView?.configuration.userContentController.removeAllUserScripts()
        webView?.removeFromSuperview(); webView = nil; waiter = nil
    }
    func ownedID(_ label: String, create: Bool = false) throws -> UUID {
        let url = documents.appendingPathComponent(label + "-ownership.json")
        if create {
            guard !FileManager.default.fileExists(atPath: url.path) else { throw NSError(domain: "SyntheticOwnershipExists", code: 1) }
            let identifier = UUID()
            try JSONSerialization.data(withJSONObject: ["id": identifier.uuidString]).write(to: url, options: .atomic)
            return identifier
        }
        let value = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: String]
        guard let text = value?["id"], let identifier = UUID(uuidString: text) else { throw NSError(domain: "SyntheticOwnershipInvalid", code: 1) }
        return identifier
    }
    func compileRule() async throws {
        let store = WKContentRuleListStore.default()!
        rule = try await bounded { finish in
            store.compileContentRuleList(forIdentifier: ruleIdentifier,
                encodedContentRuleList: #"[{"trigger":{"url-filter":".*"},"action":{"type":"block"}}]"#) { value, error in
                if let error { finish(.failure(error)) }
                else if let value { finish(.success(value)) }
                else { finish(.failure(NSError(domain: "SyntheticRuleMissing", code: 1))) }
            }
        }
    }
    func open(_ identifier: UUID, label: String) async throws {
        dispose(); openedLabels.append(label)
        let configuration = WKWebViewConfiguration()
        let store: WKWebsiteDataStore
        if let existing = stores[identifier] { store = existing }
        else { store = WKWebsiteDataStore(forIdentifier: identifier); stores[identifier] = store }
        configuration.websiteDataStore = store
        configuration.limitsNavigationsToAppBoundDomains = true
        guard let rule else { throw NSError(domain: "SyntheticRuleNotReady", code: 1) }
        configuration.userContentController.add(rule)
        let web = WKWebView(frame: window!.bounds, configuration: configuration)
        web.isInspectable = false
        webView = web; window?.rootViewController?.view.addSubview(web)
        let waiter = NavigationWaiter(); self.waiter = waiter; web.navigationDelegate = waiter
        try await bounded { finish in
            waiter.finish = finish
            web.loadHTMLString(inertHTML, baseURL: fixtureURL)
        }
        waiter.finish = nil
        let environment = try await evaluate("return await originBootstrapProbe.environment();", install: true)
        observations.append(["stage": stage, "environment": environment])
        for field in ["locationMatches", "originMatches", "effectiveOriginMatches", "baseURIMatches", "secureContext", "cryptoAvailable", "serviceWorkerRegistrationReadSucceeded"] {
            try require(environment[field] as? Bool == true, label + " exact bootstrap environment: " + field)
        }
        for field in ["serviceWorkerRegistrationCount", "resourceCount", "scriptElementCount", "childFrameCount"] {
            try require(environment[field] as? Int == 0, label + " inert bootstrap environment: " + field)
        }
        try require(waiter.unexpectedNavigationCount == 0, label + " has no unexpected navigation")
    }
    func evaluate(_ body: String, arguments: [String: Any] = [:], install: Bool = false) async throws -> [String: Any] {
        guard let web = webView else { throw NSError(domain: "SyntheticViewMissing", code: 1) }
        let library: String
        if install {
            guard let url = Bundle.main.url(forResource: "probe", withExtension: "js") else { throw NSError(domain: "SyntheticLibraryMissing", code: 1) }
            library = try String(contentsOf: url, encoding: .utf8)
        } else { library = "" }
        let script = """
        const allowed = new Set(['Error','TypeError','SecurityError','DataCloneError','InvalidAccessError','NotSupportedError','AbortError']);
        try { \(library) \(body) }
        catch (error) { return {fixtureFailure:true,errorName:allowed.has(error.name)?error.name:'OtherError'}; }
        """
        let value: Any = try await bounded { finish in
            web.callAsyncJavaScript(script, arguments: arguments, in: nil, in: .page) { result in finish(result) }
        }
        guard let result = value as? [String: Any] else { throw NSError(domain: "SyntheticResultInvalid", code: 1) }
        if result["fixtureFailure"] as? Bool == true {
            observations.append(["stage": stage, "errorName": result["errorName"] as? String ?? "UnknownError"])
            throw NSError(domain: "SyntheticJavaScriptFailure", code: 1)
        }
        return result
    }
    func verify(_ state: [String: Any], label: String, source: Bool) throws {
        observations.append(["stage": stage, "verification": state])
        try require(state["recordCount"] as? Int == 1, label + " contains one fictional record")
        for field in ["plaintextMatches", "typedDataMatches", "localStorageMatches", "keyMatches", "originalKeyExportRejected"] {
            try require(state[field] as? Bool == true, label + " verifies " + field)
        }
        try require(state["sourceSentinelPresent"] as? Bool == source, label + " source-only sentinel isolation")
        for field in ["ciphertextDigest", "typedDataDigest"] {
            let text = state[field] as? String ?? ""
            try require(text.count == 64 && text.allSatisfy { $0.isHexDigit }, label + " bounded " + field)
        }
    }
    func bootstrap() async throws {
        let source = try ownedID("source", create: true)
        let destination = try ownedID("destination", create: true)
        try require(source != destination, "Source and destination use independent named stores")
        progress("source-empty-origin")
        try await open(source, label: "source")
        let sourceEmpty = try await evaluate("return await originBootstrapProbe.empty();")
        try require(["databaseCount", "localStorageCount", "cookieCount"].allSatisfy { sourceEmpty[$0] as? Int == 0 }, "Source begins empty before writes")
        progress("source-seed-fictional-data")
        let seeded = try await evaluate("return await originBootstrapProbe.seed();")
        try verify(seeded, label: "Source", source: true)
        observations.append(["sourceState": seeded])
        let sourceDigest = seeded["ciphertextDigest"] as? String ?? ""
        write(["sourceCiphertextDigest": sourceDigest], to: "expected-digests.json")
        var transfer = try await evaluate("return await originBootstrapProbe.transfer();")
        try require(Set(transfer.keys) == Set(["plaintext", "typed", "buffer", "date", "map", "preference"]), "Only bounded fictional values cross the in-memory transfer")
        progress("destination-empty-origin")
        try await open(destination, label: "destination")
        let empty = try await evaluate("return await originBootstrapProbe.empty();")
        try require(["databaseCount", "localStorageCount", "cookieCount"].allSatisfy { empty[$0] as? Int == 0 }, "Independent destination begins empty before import")
        progress("destination-import-before-remote-client")
        let restored = try await evaluate("return await originBootstrapProbe.restore(transfer);", arguments: ["transfer": transfer])
        transfer.removeAll(keepingCapacity: false)
        try verify(restored, label: "Destination", source: false)
        try require(restored["ciphertextDigest"] as? String != sourceDigest, "Destination ciphertext differs after fresh-key wrapping")
        observations.append(["destinationState": restored])
        progress("destination-fresh-view")
        try await open(destination, label: "destination")
        try verify(try await evaluate("return await originBootstrapProbe.verify();"), label: "Fresh-view destination", source: false)
        progress("source-preservation-fresh-view")
        try await open(source, label: "source")
        let preserved = try await evaluate("return await originBootstrapProbe.verify();")
        try verify(preserved, label: "Preserved source", source: true)
        try require(preserved["ciphertextDigest"] as? String == sourceDigest, "Source encrypted bytes are unchanged after restore")
    }
    func cold(_ label: String) async throws {
        let identifier = try ownedID(label)
        progress("cold-" + label)
        try await open(identifier, label: label)
        let state = try await evaluate("return await originBootstrapProbe.verify();")
        try verify(state, label: "Cold " + label, source: label == "source")
        if label == "source" {
            let expected = try JSONSerialization.jsonObject(with: Data(contentsOf: documents.appendingPathComponent("expected-digests.json"))) as? [String: String]
            try require(state["ciphertextDigest"] as? String == expected?["sourceCiphertextDigest"], "Cold source encrypted bytes remain unchanged")
        }
        try require(openedLabels == [label], "Cold process opens only its designated named store")
        observations.append(["coldState": state])
    }
    func cleanup() async throws {
        dispose()
        for label in ["source", "destination"] {
            let metadata = documents.appendingPathComponent(label + "-ownership.json")
            if !FileManager.default.fileExists(atPath: metadata.path) { continue }
            let identifier = try ownedID(label)
            let _: Void = try await bounded { finish in
                WKWebsiteDataStore.remove(forIdentifier: identifier) { error in
                    if let error { finish(.failure(error)) } else { finish(.success(())) }
                }
            }
            try FileManager.default.removeItem(at: metadata)
            try require(true, "Owned " + label + " store removed through public API")
        }
        let _: Void = try await bounded { finish in
            WKContentRuleListStore.default()!.removeContentRuleList(forIdentifier: ruleIdentifier) { error in
                if let error { finish(.failure(error)) } else { finish(.success(())) }
            }
        }
        try require(true, "Only owned content-rule identifier removed")
    }
    func run() async {
        var success = false
        do {
            // Initialize WebKit's ordinary UI run loop before public store-only
            // cleanup, matching the independently passing registration fixture.
            autoreleasepool {
                let configuration = WKWebViewConfiguration()
                configuration.websiteDataStore = .nonPersistent()
                let ephemeral = WKWebView(frame: .zero, configuration: configuration)
                ephemeral.stopLoading()
            }
            if phase != "cleanup" { try await compileRule() }
            switch phase {
            case "bootstrap": try await bootstrap()
            case "cold-destination": try await cold("destination")
            case "cold-source": try await cold("source")
            case "cleanup": try await cleanup()
            default: throw NSError(domain: "SyntheticPhaseInvalid", code: 1)
            }
            success = true
        } catch {
            let error = error as NSError
            observations.append(["failureStage": stage, "errorDomain": error.domain, "errorCode": error.code])
        }
        dispose()
        write(["phase": phase, "result": success ? "PASS" : "FAIL", "assertions": checks.count,
               "checks": checks, "observations": observations, "processIdentifier": ProcessInfo.processInfo.processIdentifier,
               "processInstanceID": processInstanceID,
               "openedStoreLabels": openedLabels, "syntheticOnly": true, "remoteClientLoaded": false,
               "originalKeyExported": false, "transferPersisted": false], to: phase + "-result.json")
    }
}

@MainActor
final class ProbeSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene, let app = UIApplication.shared.delegate as? OriginBootstrapProbe else { return }
        app.start(scene)
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(OriginBootstrapProbe.self))
