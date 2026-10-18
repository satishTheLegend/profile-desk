import Foundation
import UIKit
import WebKit
import Darwin

@MainActor
final class NavigationWaiter: NSObject, WKNavigationDelegate {
    var continuation: CheckedContinuation<Void, Error>?
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { continuation?.resume(); continuation = nil }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { continuation?.resume(throwing:error); continuation = nil }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { continuation?.resume(throwing:error); continuation = nil }
}

@MainActor
final class ScriptWaiter { var continuation: CheckedContinuation<Any, Error>? }

@MainActor
final class HarnessDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var webView: WKWebView?
    var waiter: NavigationWaiter?
    var assertions = 0
    var created = [UUID]()
    var report = [String:Any]()

    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name:"Synthetic", sessionRole:session.role)
        configuration.delegateClass = HarnessSceneDelegate.self
        return configuration
    }
    func start(windowScene: UIWindowScene) {
        let window = UIWindow(windowScene:windowScene)
        window.rootViewController = UIViewController()
        window.rootViewController?.view.backgroundColor = .systemBackground
        window.makeKeyAndVisible(); self.window = window
        Task { await run() }
    }
    func check(_ condition: Bool, _ message: String) throws {
        guard condition else { throw NSError(domain:"HarnessAssertion",code:1,userInfo:[NSLocalizedDescriptionKey:message]) }
        assertions += 1
    }
    func open(_ identifier: UUID, fixturePath: String = "/") async throws {
        dispose()
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier:identifier)
        configuration.limitsNavigationsToAppBoundDomains = true
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        let web = WKWebView(frame:window!.bounds,configuration:configuration)
        web.isInspectable = false
        try check(web.configuration.websiteDataStore.identifier == identifier, "Wrong named-store binding")
        webView = web
        window?.rootViewController?.view.addSubview(web)
        let waiter = NavigationWaiter(); self.waiter = waiter; web.navigationDelegate = waiter
        try await withCheckedThrowingContinuation { continuation in
            waiter.continuation = continuation
            web.load(URLRequest(url:URL(string:"https://localhost:8445" + fixturePath)!))
            Task { @MainActor in
                try? await Task.sleep(nanoseconds:30_000_000_000)
                if let pending = waiter.continuation { waiter.continuation = nil; pending.resume(throwing:NSError(domain:"HarnessTimeout",code:1)) }
            }
        }
    }
    func dispose() {
        webView?.stopLoading(); webView?.navigationDelegate = nil; webView?.uiDelegate = nil
        webView?.removeFromSuperview(); webView = nil; waiter = nil
    }
    func verify(_ marker: String, seed: Bool = false) async throws -> [String:Any] {
        guard let webView else { throw NSError(domain:"HarnessMissingView",code:1) }
        let script = "document.querySelector('#marker').value = marker; return await Promise.race([(async () => { \(seed ? "await seed();" : "") return await verify(); })(), new Promise((_, reject) => setTimeout(() => reject(new Error('bounded harness timeout')), 15000))]);"
        let scriptWaiter = ScriptWaiter()
        let result: Any = try await withCheckedThrowingContinuation { continuation in
            scriptWaiter.continuation = continuation
            webView.callAsyncJavaScript(script, arguments:["marker":marker], in:nil, in:.page) { result in
                scriptWaiter.continuation?.resume(with: result); scriptWaiter.continuation = nil
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds:20_000_000_000)
                if let pending = scriptWaiter.continuation { scriptWaiter.continuation = nil; pending.resume(throwing:NSError(domain:"HarnessScriptTimeout",code:1)) }
            }
        }
        guard let report = result as? [String:Any] else { throw NSError(domain:"HarnessInvalidResult",code:1) }
        return report
    }
    func progress(_ phase: String, _ index: Int) {
        let directory = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
        let value:[String:Any] = ["phase":phase,"index":index,"assertions":assertions]
        if let data = try? JSONSerialization.data(withJSONObject:value) { try? data.write(to:directory.appendingPathComponent("progress.json"), options: .atomic) }
    }
    func enteredBackground() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let value: [String: Any] = ["event": "sceneDidEnterBackground", "viewAttached": webView?.superview != nil,
                                   "recordedAt": ISO8601DateFormatter().string(from: Date())]
        if let data = try? JSONSerialization.data(withJSONObject: value) {
            try? data.write(to: directory.appendingPathComponent("background.json"), options: .atomic)
        }
    }
    func evaluate(_ source: String, in view: WKWebView) async throws -> Any {
        let waiter = ScriptWaiter()
        return try await withCheckedThrowingContinuation { continuation in
            waiter.continuation = continuation
            view.callAsyncJavaScript(source, arguments: [:], in: nil, in: .page) { result in
                waiter.continuation?.resume(with: result); waiter.continuation = nil
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if let pending = waiter.continuation { waiter.continuation = nil; pending.resume(throwing: NSError(domain: "HarnessScriptTimeout", code: 2)) }
            }
        }
    }
    /// This test-only peer is never part of the production platform-view engine.
    func peer(_ identifier: UUID) async throws -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: identifier)
        configuration.limitsNavigationsToAppBoundDomains = true
        let view = WKWebView(frame: window!.bounds, configuration: configuration)
        window?.rootViewController?.view.insertSubview(view, at: 0)
        let waiter = NavigationWaiter(); view.navigationDelegate = waiter
        try await withCheckedThrowingContinuation { continuation in
            waiter.continuation = continuation
            view.load(URLRequest(url: URL(string: "https://localhost:8445/")!))
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                if let pending = waiter.continuation { waiter.continuation = nil; pending.resume(throwing: NSError(domain: "HarnessNavigationTimeout", code: 2)) }
            }
        }
        view.navigationDelegate = nil
        return view
    }
    func verifyMessaging(first: UUID, second: UUID) async throws -> [String: Any] {
        try await open(first)
        let receiver = webView!
        var sender: WKWebView? = try await peer(first)
        defer { sender?.stopLoading(); sender?.removeFromSuperview(); sender = nil }
        let broadcast = try await evaluate("return typeof BroadcastChannel === 'function';", in: receiver) as? Bool == true
        try check(broadcast, "BroadcastChannel unsupported; positive control cannot run")
        _ = try await evaluate("window.testMessages=[]; window.testChannel=new BroadcastChannel('synthetic-isolation'); testChannel.onmessage=e=>testMessages.push(e.data); return true;", in: receiver)
        _ = try await evaluate("window.testChannel=new BroadcastChannel('synthetic-isolation'); testChannel.postMessage('same-profile'); return true;", in: sender!)
        let positive = try await evaluate("await new Promise(r=>setTimeout(r,600)); return testMessages.includes('same-profile');", in: receiver) as? Bool == true
        try check(positive, "BroadcastChannel same-profile positive control failed")
        let sharedWorker = try await evaluate("return typeof SharedWorker === 'function';", in: receiver) as? Bool == true
        if sharedWorker {
            let firstProbe = try await workerProbe(in: receiver, create: true)
            let sameProbe = try await workerProbe(in: sender!, create: true)
            let positiveProbe = try await workerProbe(in: receiver, create: false)
            try check(firstProbe["connections"] as? Int == 1 && sameProbe["connections"] as? Int == 2 && positiveProbe["connections"] as? Int == 2, "SharedWorker same-profile positive control failed")
            _ = try await evaluate("testWorker.port.close(); window.testWorker=null; return true;", in: sender!)
        }
        _ = try await evaluate("testChannel.close(); window.testChannel=null; return true;", in: sender!)
        sender?.stopLoading(); sender?.removeFromSuperview(); sender = nil
        sender = try await peer(second)
        _ = try await evaluate("window.testChannel=new BroadcastChannel('synthetic-isolation'); testChannel.postMessage('other-profile'); return true;", in: sender!)
        let leaked = try await evaluate("await new Promise(r=>setTimeout(r,800)); return testMessages.includes('other-profile');", in: receiver) as? Bool == true
        try check(!leaked, "BroadcastChannel crossed named stores")
        if sharedWorker {
            let otherProbe = try await workerProbe(in: sender!, create: true)
            let originalProbe = try await workerProbe(in: receiver, create: false)
            try check(otherProbe["connections"] as? Int == 1 && originalProbe["connections"] as? Int == 2, "SharedWorker crossed named stores")
            _ = try await evaluate("testWorker.port.close(); window.testWorker=null; return true;", in: sender!)
            _ = try await evaluate("testWorker.port.close(); window.testWorker=null; return true;", in: receiver)
        }
        _ = try await evaluate("testChannel.close(); window.testChannel=null; return true;", in: receiver)
        _ = try await evaluate("testChannel.close(); window.testChannel=null; return true;", in: sender!)
        return ["broadcastChannel":"PASS", "sameProfilePositiveControl":true, "crossProfileDelivery":false, "sharedWorkerSupported":sharedWorker, "sharedWorker":sharedWorker ? "PASS" : "UNSUPPORTED"]
    }
    func workerProbe(in view: WKWebView, create: Bool) async throws -> [String: Any] {
        let script = "\(create ? "window.testWorker=new SharedWorker('/shared-worker.js',{name:'synthetic-isolation'}); testWorker.port.start();" : "") const token=crypto.randomUUID(); return await new Promise((resolve,reject)=> { const timer=setTimeout(()=>reject(new Error('SharedWorker probe timeout')),5000); testWorker.port.onmessage=e=>{if(e.data.token===token){clearTimeout(timer);resolve(e.data);}}; testWorker.port.postMessage({type:'probe',token}); });"
        guard let result = try await evaluate(script, in: view) as? [String: Any] else { throw NSError(domain: "HarnessInvalidWorkerResult", code: 1) }
        return result
    }
    func appResidentBytes() -> UInt64? {
        var info = mach_task_basic_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.resident_size : nil
    }
    func runStress() async throws -> [String: Any] {
        let seed: UInt64 = 0x50524f46494c45
        var random = seed
        var previous = 9
        var samples = [[String: Any]]()
        var durations = [Double]()
        var sequence = [Int]()
        var maxAttachedViews = 0
        report["mode"] = "stress"
        report["selectionSeedHex"] = String(seed, radix: 16)
        report["completedSwitches"] = 0
        if let bytes = appResidentBytes() { samples.append(["completedSwitches": 0, "residentBytes": bytes]) }
        for step in 0..<200 {
            random = random &* 6364136223846793005 &+ 1442695040888963407
            var index = Int((random >> 32) % 10)
            if index == previous { index = (index + 1) % 10 }
            progress("stress", step)
            let start = ProcessInfo.processInfo.systemUptime
            try await open(created[index])
            let restored = try await verify("synthetic-\(index)")
            report["selectedProfileIndex"] = index
            report["lastStorageResult"] = restored
            try check(restored["result"] as? String == "MATCH", "Stress selection \(step) mismatched profile \(index)")
            let attached = window?.rootViewController?.view.subviews.filter { $0 is WKWebView }.count ?? 0
            maxAttachedViews = max(maxAttachedViews, attached)
            try check(attached == 1, "Stress selection had multiple attached web views")
            durations.append(ProcessInfo.processInfo.systemUptime - start)
            sequence.append(index)
            previous = index
            if (step + 1) % 10 == 0, let bytes = appResidentBytes() {
                samples.append(["completedSwitches": step + 1, "residentBytes": bytes])
            }
            report["completedSwitches"] = step + 1
            report["selectionSequence"] = sequence
            report["switchSeconds"] = durations
            report["appProcessResidentSamples"] = samples
        }
        let sorted = durations.sorted()
        return ["result": "PASS", "assertions": assertions, "mode": "stress", "profiles": 10,
                "completedSwitches": 200, "selectionSeedHex": String(seed, radix: 16), "selectionSequence": sequence,
                "oneOwnedView": true, "maxAttachedViews": maxAttachedViews,
                "stores": ["readableCookie", "serverVerifiedHttpOnlyCookie", "localStorage", "indexedDB", "cacheStorage", "serviceWorker"],
                "switchSeconds": durations, "medianSwitchSeconds": (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2,
                "p95SwitchSeconds": sorted[Int(Double(sorted.count - 1) * 0.95)],
                "appProcessResidentSamples": samples,
                "memoryScope": "Synthetic app process RSS only; excludes WebKit subprocesses, is not physical device memory or a leak proof."]
    }
    func runTransport() async throws -> [String: Any] {
        var probes = [[String: Any]]()
        for index in 0..<2 {
            progress("transport", index)
            try await open(created[index], fixturePath: "/transport/page")
            let marker = "synthetic-\(index)"
            let prime = try await evaluate("return await ProfileDeskTransport.cacheProbe('\(marker)', {cache:'\(index == 0 ? "reload" : "default")'});", in: webView!) as? [String: Any]
            try check(prime?["result"] as? String == "MATCH" && prime?["cacheHit"] as? Bool == false, "Profile \(index) inherited another HTTP cache entry")
            let repeated = try await evaluate("return await ProfileDeskTransport.cacheProbe('\(marker)');", in: webView!) as? [String: Any]
            try check(repeated?["result"] as? String == "MATCH" && repeated?["cacheHit"] as? Bool == true, "HTTP cache positive control did not hit for profile \(index)")
            let socket = try await evaluate("return await ProfileDeskTransport.websocketProbe('\(marker)');", in: webView!) as? [String: Any]
            try check(socket?["result"] as? String == "MATCH", "WSS handshake used the wrong profile cookie")
            let file = try await evaluate("return await ProfileDeskTransport.fileProbe('\(marker)');", in: webView!) as? [String: Any]
            try check(file?["result"] as? String == "MATCH", "Synthetic fetch file bytes or profile identity mismatched")
            probes.append(["profileIndex": index, "httpCacheFirst": prime ?? [:], "httpCacheRepeat": repeated ?? [:], "websocket": socket ?? [:], "fetchFile": file ?? [:]])
        }
        for index in 0..<2 {
            try await open(created[index], fixturePath: "/transport/page")
            let reopened = try await evaluate("return await ProfileDeskTransport.cacheProbe('synthetic-\(index)');", in: webView!) as? [String: Any]
            try check(reopened?["result"] as? String == "MATCH" && reopened?["cacheHit"] as? Bool == true, "HTTP cache did not retain its own marker after reopening profile \(index)")
        }
        return ["result": "PASS", "mode": "transport", "assertions": assertions, "profiles": 2, "probes": probes,
                "httpCacheSameUrlAcrossProfiles": true, "httpCachePositiveControl": true,
                "wssHandshakeProfileCookies": true, "oneOwnedView": true,
                "fileScope": "JavaScript fetch byte/hash roundtrip only; not native picker, WKDownload or actual service media."]
    }
    private var persistenceFile: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("persistence-profile-ids.json")
    }
    func verifyPersistence(stage: String) async throws -> [String: Any] {
        report["mode"] = "persistence"
        report["stage"] = stage
        let identifiers = try JSONDecoder().decode([UUID].self, from: Data(contentsOf: persistenceFile))
        try check(identifiers.count == 2, "Persistence fixture must retain exactly two named profile identities")
        let inventory = await WKWebsiteDataStore.allDataStoreIdentifiers
        try check(Set(identifiers).isSubset(of: Set(inventory)), "A seeded named store disappeared before relaunch validation")
        created = identifiers
        var checks = [[String: Any]]()
        for (index, identifier) in identifiers.enumerated() {
            progress(stage, index)
            try await open(identifier)
            let result = try await verify("synthetic-\(index)")
            checks.append(["profileIndex": index, "storageResult": result])
            report["persistenceChecks"] = checks
            try check(result["result"] as? String == "MATCH", "Persistence \(stage) marker mismatch for profile \(index)")
        }
        return ["result": "PASS", "mode": "persistence", "stage": stage, "profiles": 2, "assertions": assertions,
                "persistenceChecks": checks,
                "testIds": ["IOS-SYNTH-PROCESS-01", "IOS-SYNTH-REBOOT-01"],
                "stores": ["readableCookie", "serverVerifiedHttpOnlyCookie", "localStorage", "indexedDB", "cacheStorage", "serviceWorker"],
                "oneOwnedView": true]
    }
    func run() async {
        let start = Date()
        report["requestedMode"] = CommandLine.arguments.dropFirst().first ?? "--full"
        do {
            WebKitBootstrap.initialize()
            if CommandLine.arguments.contains("--persistence-process") || CommandLine.arguments.contains("--persistence-reboot") {
                report = try await verifyPersistence(stage: CommandLine.arguments.contains("--persistence-process") ? "process_relaunch" : "simulator_reboot")
            } else {
            let coldInventory = await WKWebsiteDataStore.allDataStoreIdentifiers
            try check(coldInventory.isEmpty, "Disposable simulator must start without named stores")
            let shortMode = CommandLine.arguments.contains("--messaging") || CommandLine.arguments.contains("--transport") || CommandLine.arguments.contains("--persistence-seed")
            created = (0..<(shortMode ? 2 : 10)).map { _ in UUID() }
            for (index,id) in created.enumerated() {
                progress("open",index)
                try await open(id)
                progress("verifyEmpty",index)
                let empty = try await verify("synthetic-\(index)")
                try check(empty["result"] as? String == "EMPTY", "New profile was not empty at index \(index)")
                progress("seed",index)
                let seeded = try await verify("synthetic-\(index)", seed:true)
                try check(seeded["result"] as? String == "MATCH", "Six-store seed mismatch at index \(index)")
            }
            if CommandLine.arguments.contains("--persistence-seed") {
                try JSONEncoder().encode(created).write(to: persistenceFile, options: .atomic)
                report = ["result": "PASS", "mode": "persistence", "stage": "seed", "profiles": 2, "assertions": assertions,
                          "testIds": ["IOS-SYNTH-PROCESS-01", "IOS-SYNTH-REBOOT-01"]]
            } else if CommandLine.arguments.contains("--stress") {
                report = try await runStress()
            } else if CommandLine.arguments.contains("--messaging") {
                let messaging = try await verifyMessaging(first: created[0], second: created[1])
                report = ["result": "PASS", "mode": "messaging", "assertions": assertions, "profiles": 2, "messaging": messaging, "testOnlyMessagingViews": 2]
            } else if CommandLine.arguments.contains("--transport") {
                report = try await runTransport()
            } else {
            for (index,id) in created.enumerated() {
                progress("open",index)
                try await open(id)
                let restored = try await verify("synthetic-\(index)")
                try check(restored["result"] as? String == "MATCH", "Reopened profile mismatch at index \(index)")
            }
            progress("messaging", 0)
            let messaging = try await verifyMessaging(first: created[0], second: created[1])
            report["messaging"] = messaging
            // Remove a profile while its service worker still has queued writes.
            try await open(created[4])
            let burstStarted = try await evaluate("workerMessage('burst','synthetic-removal-burst').catch(()=>{}); const end=Date.now()+2000; while(Date.now()<end) { const c=await caches.open('synthetic-profile-worker-v1'); const r=await c.match('/synthetic-worker-marker'); if(r && await r.text()==='synthetic-removal-burst') return true; await new Promise(r=>setTimeout(r,50)); } return false;", in: webView!) as? Bool == true
            try check(burstStarted, "Service-worker concurrent writes never started")
            dispose()
            var cleanupInitiallyPending = false
            var cleanupAttempts = 0
            for attempt in 0..<6 {
                cleanupAttempts += 1
                do { try await WKWebsiteDataStore.remove(forIdentifier:created[4]); break }
                catch {
                    cleanupInitiallyPending = true
                    let pendingInventory = await WKWebsiteDataStore.allDataStoreIdentifiers
                    try check(pendingInventory.contains(created[4]), "Failed removal lost its pending store")
                    if attempt == 5 { throw error }
                    // Production persists websiteWipePending and exposes retry.
                    // Test repeated explicit retries without a fixed latency claim.
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                }
            }
            try await Task.sleep(nanoseconds: 4_500_000_000)
            let inventory = await WKWebsiteDataStore.allDataStoreIdentifiers
            try check(!inventory.contains(created[4]), "Removed store still enumerates")
            for (index,id) in created.enumerated() where index != 4 {
                try await open(id)
                let restored = try await verify("synthetic-\(index)")
                try check(restored["result"] as? String == "MATCH", "Middle removal affected index \(index)")
            }
            let replacement = UUID(); created.append(replacement)
            try await open(replacement)
            let fresh = try await verify("synthetic-replacement")
            try check(fresh["result"] as? String == "EMPTY", "Replacement inherited removed data")
            report = ["result":"PASS", "assertions":assertions, "profiles":10,"stores":["readableCookie","serverVerifiedHttpOnlyCookie","localStorage","indexedDB","cacheStorage","serviceWorker"],"oneLiveViewInStorageScenario":true,"testOnlyMessagingViews":2,"messaging":messaging,"deletionDuringServiceWorkerWrites":true,"cleanupInitiallyPending":cleanupInitiallyPending,"cleanupAttempts":cleanupAttempts,"coldInventoryAfterEphemeralBootstrap":true]
            }
            }
        } catch {
            report.merge(["result":"FAIL", "assertions":assertions, "error":String(describing:error)], uniquingKeysWith: { _,new in new })
        }
        if !CommandLine.arguments.contains("--normal-lifecycle") { dispose() }
        // Preserve assertion failures before fixture teardown; the runner deletes
        // its entire disposable simulator. Teardown must not mask a primary error.
        report["fixtureTeardown"] = "Runner shuts down and deletes its disposable simulator."
        report["durationSeconds"] = Date().timeIntervalSince(start)
        report["recordedAt"] = ISO8601DateFormatter().string(from:Date())
        report["osVersion"] = UIDevice.current.systemVersion
        report["context"] = "synthetic iOS simulator; no actual service accounts"
        if CommandLine.arguments.contains("--normal-lifecycle") { report["terminationPath"] = "UIKit background event before process termination" }
        let data = try! JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys])
        let output = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent("result.json")
        try! data.write(to:output,options:.atomic)
    }
}

@MainActor
final class HarnessSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene, let app = UIApplication.shared.delegate as? HarnessDelegate else { return }
        app.start(windowScene:windowScene)
    }
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? HarnessDelegate)?.enteredBackground()
    }
}

UIApplicationMain(CommandLine.argc,CommandLine.unsafeArgv,nil,NSStringFromClass(HarnessDelegate.self))
