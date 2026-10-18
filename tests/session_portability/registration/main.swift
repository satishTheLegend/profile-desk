import Foundation
import Security
import UIKit
import WebKit

@MainActor
final class NavigationWaiter: NSObject, WKNavigationDelegate {
    var continuation: CheckedContinuation<Void, Error>?
    func finish(_ error: Error? = nil) {
        guard let pending = continuation else { return }
        continuation = nil
        if let error { pending.resume(throwing: error) } else { pending.resume() }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finish() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { finish(error) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { finish(error) }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        decisionHandler(url?.scheme == "https" && url?.host == "localhost" && url?.port == 8449 ? .allow : .cancel)
    }
}

@MainActor
final class RegistrationProbe: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var view: WKWebView?
    var waiter: NavigationWaiter?
    var checks = [[String: Any]]()
    var observations = [[String: Any]]()
    var openedLabels = [String]()
    var stage = "initialize"
    var documents: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    var mode: String { CommandLine.arguments.first(where: { $0.hasPrefix("--phase=") })?.replacingOccurrences(of: "--phase=", with: "") ?? "invalid" }

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
    func progress(_ stage: String) {
        self.stage = stage
        if let data = try? JSONSerialization.data(withJSONObject: ["phase": mode, "stage": stage, "assertions": checks.count]) {
            try? data.write(to: documents.appendingPathComponent("progress.json"), options: .atomic)
        }
    }
    func require(_ value: Bool, _ name: String) throws {
        checks.append(["name": name, "pass": value])
        if !value { throw NSError(domain: "SyntheticRegistrationAssertion", code: 1) }
    }
    func dispose() {
        view?.stopLoading(); view?.navigationDelegate = nil; view?.removeFromSuperview()
        view = nil; waiter = nil
    }
    func open(_ identifier: UUID, label: String) async throws -> WKWebView {
        dispose()
        openedLabels.append(label)
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: identifier)
        configuration.limitsNavigationsToAppBoundDomains = true
        let web = WKWebView(frame: window!.bounds, configuration: configuration)
        web.isInspectable = false
        view = web
        window?.rootViewController?.view.addSubview(web)
        let waiter = NavigationWaiter(); self.waiter = waiter
        web.navigationDelegate = waiter
        try await withCheckedThrowingContinuation { continuation in
            waiter.continuation = continuation
            web.load(URLRequest(url: URL(string: "https://localhost:8449/")!))
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(40))
                waiter.finish(NSError(domain: "SyntheticNavigationTimeout", code: 1))
            }
        }
        return web
    }
    func evaluate(_ script: String, arguments: [String: Any] = [:], in web: WKWebView) async throws -> [String: Any] {
        let bounded = """
        const allowedErrors = new Set(['Error','TypeError','SecurityError','DataCloneError','InvalidAccessError','NotSupportedError','AbortError']);
        return await Promise.race([(async () => {
          try { \(script) }
          catch (error) { return {fixtureFailure:true,errorName:allowedErrors.has(error.name)?error.name:'OtherError'}; }
        })(), new Promise(resolve => setTimeout(() => resolve({fixtureFailure:true,errorName:'TimeoutError'}), 10000))]);
        """
        let value = try await web.callAsyncJavaScript(bounded, arguments: arguments, in: nil, contentWorld: .page)
        guard let value = value as? [String: Any] else { throw NSError(domain: "SyntheticInvalidResult", code: 1) }
        if value["fixtureFailure"] as? Bool == true {
            observations.append(["stage": stage, "errorName": value["errorName"] as? String ?? "UnknownError"])
            throw NSError(domain: "SyntheticFixtureFailure", code: 1)
        }
        return value
    }
    func ownedID(_ label: String, create: Bool = false) throws -> UUID {
        let url = documents.appendingPathComponent(label + "-id.json")
        if create {
            guard !FileManager.default.fileExists(atPath: url.path) else { throw NSError(domain: "SyntheticOwnershipAlreadyExists", code: 1) }
            let identifier = UUID()
            // Only ownership metadata reaches this file. No payload/key bytes.
            let data = try JSONSerialization.data(withJSONObject: ["id": identifier.uuidString])
            try data.write(to: url, options: .atomic)
            return identifier
        }
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: String]
        guard let text = object?["id"], let identifier = UUID(uuidString: text) else { throw NSError(domain: "SyntheticOwnershipInvalid", code: 1) }
        return identifier
    }
    func remove(_ identifier: UUID) async -> Bool {
        for _ in 0..<5 {
            do { try await WKWebsiteDataStore.remove(forIdentifier: identifier); return true }
            catch { try? await Task.sleep(for: .seconds(2)) }
        }
        return false
    }
    func canary() -> [String: Any] {
        // Never query WebKit's master-key account. This is one disposable item
        // with a fresh account identifier in this owned simulator app only.
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: "dev.profiledesk.synthetic-registration.canary",
                                   kSecAttrAccount as String: UUID().uuidString,
                                   kSecAttrSynchronizable as String: false]
        var add = query
        add[kSecValueData as String] = Data([1, 2, 3, 4])
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        var read = query
        read[kSecReturnData as String] = true
        var value: CFTypeRef?
        let readStatus = SecItemCopyMatching(read as CFDictionary, &value)
        let matched = value as? Data == Data([1, 2, 3, 4])
        let deleteStatus = SecItemDelete(query as CFDictionary)
        return ["addStatus": Int(addStatus), "readStatus": Int(readStatus), "deleteStatus": Int(deleteStatus), "valueMatched": matched]
    }
    func verifyState(_ state: [String: Any], label: String) throws {
        let records = state["states"] as? [[String: Any]] ?? []
        try require(records.count == 2, label + " contains exactly two wrapper envelopes")
        for (index, record) in records.enumerated() {
            for field in ["shape", "nonextractable", "exportRejected", "algorithmMatches", "usagesMatch", "plaintextMatches"] {
                try require(record[field] as? Bool == true, "\(label) wrapper \(index): \(field)")
            }
        }
        try require(state["differentKeys"] as? Bool == true, label + " uses distinct per-payload wrapper keys")
    }
    func diagnose() async throws {
        progress("public-keychain-canary")
        let statuses = canary()
        observations.append(["keychain": statuses])
        let identifier = UUID()
        progress("cryptokey-structured-clone-control")
        var web: WKWebView? = try await open(identifier, label: "control")
        let state = try await evaluate("return await registrationProbe.diagnose();", in: web!)
        observations.append(state)
        try require(state["secureContext"] as? Bool == true, "Control uses a secure owned HTTPS context")
        web = nil; dispose()
        try require(await remove(identifier), "Control named store is removed through the public API")
        if mode == "identity" {
            try require(statuses["addStatus"] as? Int == 0 && statuses["readStatus"] as? Int == 0 && statuses["deleteStatus"] as? Int == 0 && statuses["valueMatched"] as? Bool == true,
                        "Identity-configured simulator app can add, read and delete its own Keychain canary")
            for field in ["aesGCM", "aesCTR"] {
                let value = state[field] as? [String: Any] ?? [:]
                try require(value["persisted"] as? Bool == true, "Identity-configured \(field) CryptoKey persists without DataCloneError")
            }
        }
    }
    func migrate() async throws {
        let sourceID = try ownedID("source", create: true)
        let destinationID = try ownedID("destination", create: true)
        try require(sourceID != destinationID, "Source and destination use different named persistent stores")
        progress("source-seed")
        var source: WKWebView? = try await open(sourceID, label: "source")
        let seeded = try await evaluate("return await registrationProbe.seed();", in: source!)
        try verifyState(seeded, label: "Source persisted")
        let originalCiphertexts = seeded["envelopes"] as? [[Int]] ?? []
        try require(originalCiphertexts.count == 2 && originalCiphertexts.allSatisfy { $0.count == 32 }, "Source has two bounded synthetic ciphertexts")
        progress("source-malformed-input-controls")
        let faults = try await evaluate("return await registrationProbe.faults();", in: source!)
        let faultCases = faults["cases"] as? [[String: Any]] ?? []
        try require(faultCases.count == 30, "All thirty malformed-wrapper/payload controls execute")
        for test in faultCases {
            try require(test["rejected"] as? Bool == true, "Invalid input rejected: " + (test["name"] as? String ?? "missing-name"))
        }
        try require(faults["preserved"] as? Bool == true && faults["validStillReadable"] as? Bool == true,
                    "Rejected inputs preserve original encrypted bytes and readability")
        try require(faults["unsafeCounterReusePerformed"] as? Bool == false,
                    "Fault controls never encrypt two plaintexts using one CTR key/counter")
        progress("source-decrypt-to-memory")
        var transfer = try await evaluate("return await registrationProbe.transfer();", in: source!)
        try require(Set(transfer.keys) == Set(["publicBytes", "privateBytes"]), "In-memory transfer contains only synthetic identity payloads, no wrapper CryptoKeys")
        source = nil; dispose()
        progress("fresh-destination-before-restore")
        var destination: WKWebView? = try await open(destinationID, label: "destination")
        let empty = try await evaluate("return await registrationProbe.empty();", in: destination!)
        try require(empty["databaseAbsent"] as? Bool == true && empty["sourceSentinelAbsent"] as? Bool == true,
                    "Fresh destination cannot read source IndexedDB or source-only LocalStorage")
        progress("destination-rewrap-and-persist")
        let restored = try await evaluate("return await registrationProbe.restore(transfer);", arguments: ["transfer": transfer], in: destination!)
        transfer.removeAll(keepingCapacity: false)
        try verifyState(restored, label: "Destination persisted")
        let destinationCiphertexts = restored["envelopes"] as? [[Int]] ?? []
        try require(destinationCiphertexts.count == 2 && zip(originalCiphertexts, destinationCiphertexts).allSatisfy { $0.0 != $0.1 }, "Destination ciphertexts differ while underlying synthetic identity bytes match")
        let different = try await evaluate("return await registrationProbe.against(ciphertexts);", arguments: ["ciphertexts": originalCiphertexts], in: destination!)
        try require(different["comparisons"] as? Int == 4 && different["allKeysDifferent"] as? Bool == true,
                    "Both fresh destination keys differ from both source keys through four wrong-key decryption controls")
        try require(restored["sourceSentinelAbsent"] as? Bool == true, "Destination still cannot read source-only state after restore")
        destination = nil; dispose()
        progress("verify-source-preserved")
        var preserved: WKWebView? = try await open(sourceID, label: "source")
        let sourceAfter = try await evaluate("return await registrationProbe.verify();", in: preserved!)
        try verifyState(sourceAfter, label: "Preserved source")
        try require(sourceAfter["envelopes"] as? [[Int]] == originalCiphertexts, "Source encrypted envelope bytes remain unchanged")
        try require(sourceAfter["sourceSentinelAbsent"] as? Bool == false, "Source-only sentinel remains in source")
        preserved = nil; dispose()
    }
    func verifyCold(_ label: String) async throws {
        // The destination phase reads only destination ownership metadata and
        // constructs only the destination WKWebsiteDataStore. No transfer bytes
        // or live source web view survive the prior process termination/reboot.
        let identifier = try ownedID(label)
        progress("cold-" + label + "-reopen")
        var web: WKWebView? = try await open(identifier, label: label)
        let state = try await evaluate("return await registrationProbe.verify();", in: web!)
        try verifyState(state, label: "Cold " + label)
        try require(state["sourceSentinelAbsent"] as? Bool == (label == "destination"), "Cold " + label + " preserves the expected source-sentinel isolation")
        try require(openedLabels == [label], "Cold verification opens exactly the requested store and no other store")
        web = nil; dispose()
    }
    func run() async {
        let started = Date()
        var successful = false
        do {
            autoreleasepool {
                let configuration = WKWebViewConfiguration()
                configuration.websiteDataStore = .nonPersistent()
                let ephemeral = WKWebView(frame: .zero, configuration: configuration)
                ephemeral.stopLoading()
            }
            switch mode {
            case "baseline", "identity": try await diagnose()
            case "migrate": try await migrate()
            case "cold-destination": try await verifyCold("destination")
            case "cold-source": try await verifyCold("source")
            case "cleanup":
                for label in ["source", "destination"] {
                    let identifier = try ownedID(label)
                    try require(await remove(identifier), "Owned " + label + " named store removed")
                    try FileManager.default.removeItem(at: documents.appendingPathComponent(label + "-id.json"))
                }
            default: throw NSError(domain: "SyntheticInvalidPhase", code: 1)
            }
            successful = true
        } catch {
            let error = error as NSError
            observations.append(["failureStage": stage, "errorDomain": error.domain, "errorCode": error.code])
        }
        dispose()
        let report: [String: Any] = ["result": successful ? "PASS" : "FAIL", "phase": mode,
                                   "assertions": checks.count, "checks": checks, "observations": observations,
                                   "openedStoreLabels": openedLabels, "processIdentifier": ProcessInfo.processInfo.processIdentifier,
                                   "durationSeconds": Date().timeIntervalSince(started), "osVersion": UIDevice.current.systemVersion,
                                   "recordedAt": ISO8601DateFormatter().string(from: Date()), "syntheticOnly": true,
                                   "realServiceAccessed": false, "payloadOrKeyBytesInReport": false]
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: documents.appendingPathComponent(mode + "-result.json"), options: .atomic)
        }
    }
}

@MainActor
final class ProbeSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene, let app = UIApplication.shared.delegate as? RegistrationProbe else { return }
        app.start(scene)
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(RegistrationProbe.self))
