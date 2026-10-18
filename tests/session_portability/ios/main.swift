import Foundation
import UIKit
import WebKit

// Disposable feasibility probe. Never included in the production target.
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
        decisionHandler(url?.scheme == "https" && url?.host == "localhost" && url?.port == 8447 ? .allow : .cancel)
    }
}

@MainActor
final class ProbeDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var view: WKWebView?
    var waiter: NavigationWaiter?
    var checks = [[String: Any]]()
    var observations = [[String: Any]]()
    var limitations = [[String: String]]()
    var ownedIDs = [UUID]()
    var phase = "initializing"

    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Probe", sessionRole: session.role)
        configuration.delegateClass = ProbeSceneDelegate.self
        return configuration
    }
    func start(_ scene: UIWindowScene) {
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        self.window = window
        Task { await run() }
    }
    func check(_ condition: Bool, _ name: String) { checks.append(["name": name, "pass": condition]) }
    func dispose() {
        view?.stopLoading(); view?.navigationDelegate = nil; view?.removeFromSuperview()
        view = nil; waiter = nil
    }
    func open(_ store: WKWebsiteDataStore) async throws -> WKWebView {
        dispose()
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = store
        configuration.limitsNavigationsToAppBoundDomains = true
        let web = WKWebView(frame: window!.bounds, configuration: configuration)
        web.isInspectable = false
        view = web
        window?.rootViewController?.view.addSubview(web)
        let waiter = NavigationWaiter(); self.waiter = waiter
        web.navigationDelegate = waiter
        try await withCheckedThrowingContinuation { continuation in
            waiter.continuation = continuation
            web.load(URLRequest(url: URL(string: "https://localhost:8447/")!))
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(40))
                waiter.finish(NSError(domain: "ProbeNavigationTimeout", code: 1))
            }
        }
        return web
    }
    func evaluate(_ script: String, in web: WKWebView) async throws -> [String: Any] {
        let bounded = """
        let probeStep = 'starting';
        const allowedErrors = new Set(['Error','TypeError','SecurityError','DataCloneError','InvalidAccessError','NotSupportedError','AbortError']);
        return await Promise.race([(async () => {
          try { \(script) }
          catch (error) { return {fixtureFailure:true, step:probeStep, errorName:allowedErrors.has(error.name) ? error.name : 'OtherError'}; }
        })(), new Promise(resolve => setTimeout(() => resolve({fixtureFailure:true, step:probeStep, errorName:'TimeoutError'}), 10000))]);
        """
        let value = try await web.callAsyncJavaScript(bounded, arguments: [:], in: nil, contentWorld: .page)
        guard let value = value as? [String: Any] else { throw NSError(domain: "ProbeInvalidResult", code: 1) }
        if value["fixtureFailure"] as? Bool == true {
            observations.append(["phase": "fixtureFailure", "during": phase,
                                 "step": value["step"] as? String ?? "unknown", "errorName": value["errorName"] as? String ?? "unknown"])
            throw NSError(domain: "ProbeFixtureFailure", code: 1)
        }
        return value
    }
    func archive(_ store: WKWebsiteDataStore, types: Set<String>) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            store.fetchData(of: types) { data, error in
                if let error { continuation.resume(throwing: error) }
                else if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: NSError(domain: "ProbeMissingArchive", code: 1)) }
            }
        }
    }
    func restore(_ data: Data, to store: WKWebsiteDataStore) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.restoreData(data) { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }
    func isUnsupportedType(_ error: NSError, requested: Set<String>) -> Bool {
        // Match the public API's specific rejection, not arbitrary crashes,
        // missing-data failures, or a request that never reached WebKit.
        // Source: WebKit a11228658545f5a823a897cc3bdc2cd386e11492,
        // WKWebsiteDataStore.mm fetchDataOfTypes:completionHandler:.
        error.domain == WKErrorDomain && error.code == WKError.Code.unknown.rawValue &&
            requested.contains { error.localizedDescription == "This API does not support fetching: " + $0 }
    }
    func progress(_ phase: String) {
        self.phase = phase
        let value: [String: Any] = ["phase": phase, "assertions": checks.count]
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("progress.json")
        if let data = try? JSONSerialization.data(withJSONObject: value) { try? data.write(to: output, options: .atomic) }
    }
    func verify(_ web: WKWebView) async throws -> [String: Any] {
        try await evaluate("""
        probeStep = 'enumerateIndexedDB';
        const databases = await indexedDB.databases();
        const dbPresent = databases.some(entry => entry.name === 'synthetic-portability');
        const inspectKey = async key => {
          const result = {present:key instanceof CryptoKey, usable:false, nonextractable:false, exportRejected:false};
          if (!result.present) return result;
          result.nonextractable = key.extractable === false;
          try { await crypto.subtle.exportKey('raw', key); }
          catch (error) { result.exportRejected = error.name === 'InvalidAccessError'; }
          const iv = new Uint8Array(12);
          const plain = new TextEncoder().encode('owned-synthetic-probe');
          const encrypted = await crypto.subtle.encrypt({name:'AES-GCM', iv}, key, plain);
          const decrypted = await crypto.subtle.decrypt({name:'AES-GCM', iv}, key, encrypted);
          result.usable = new TextDecoder().decode(decrypted) === 'owned-synthetic-probe';
          return result;
        };
        let storedKey, recordPresent = false;
        if (dbPresent) {
          probeStep = 'reopenIndexedDB';
          const db = await new Promise((resolve, reject) => {
            const request = indexedDB.open('synthetic-portability');
            request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
          });
          probeStep = 'readStoredCryptoKey';
          storedKey = await new Promise((resolve, reject) => {
            const request = db.transaction('fixture', 'readonly').objectStore('fixture').get('key');
            request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
          });
          probeStep = 'readPlainIndexedDBRecord';
          recordPresent = (await new Promise((resolve, reject) => {
            const request = db.transaction('fixture', 'readonly').objectStore('fixture').get('record');
            request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
          })) === 'owned-synthetic-probe';
          db.close();
        }
        probeStep = 'verifyMemoryCryptoKey';
        const memoryKey = await inspectKey(globalThis.__syntheticProbeKey);
        probeStep = 'verifyOptionalStoredCryptoKey';
        const persistedKey = await inspectKey(storedKey);
        probeStep = 'verifyOtherStorage';
        let serviceWorkerPresent = false, serviceWorkerQueryAvailable = true;
        try { serviceWorkerPresent = (await navigator.serviceWorker.getRegistrations()).length > 0; }
        catch { serviceWorkerQueryAvailable = false; }
        return {
          secureContext: isSecureContext,
          localStoragePresent: localStorage.getItem('probe') === 'owned-synthetic-probe',
          sessionStoragePresent: sessionStorage.getItem('probe') === 'owned-synthetic-probe',
          cookiePresent: document.cookie.split('; ').includes('probe=owned-synthetic-probe'),
          indexedDBPresent: dbPresent, indexedDBRecordPresent: recordPresent,
          keyPresent:persistedKey.present, keyUsable:persistedKey.usable,
          keyNonextractable:persistedKey.nonextractable, exportRejected:persistedKey.exportRejected,
          memoryKeyPresent:memoryKey.present, memoryKeyUsable:memoryKey.usable,
          memoryKeyNonextractable:memoryKey.nonextractable, memoryExportRejected:memoryKey.exportRejected,
          cachePresent: (await caches.keys()).includes('synthetic-portability'),
          serviceWorkerPresent, serviceWorkerQueryAvailable
        };
        """, in: web)
    }
    func run() async {
        let started = Date()
        do {
            progress("ephemeralBootstrap")
            autoreleasepool {
                let configuration = WKWebViewConfiguration()
                configuration.websiteDataStore = .nonPersistent()
                let ephemeral = WKWebView(frame: .zero, configuration: configuration)
                ephemeral.stopLoading()
            }
            let rejectedType = WKWebsiteDataTypeIndexedDBDatabases
            check(isUnsupportedType(NSError(domain: WKErrorDomain, code: WKError.Code.unknown.rawValue,
                                           userInfo: [NSLocalizedDescriptionKey: "This API does not support fetching: " + rejectedType]), requested: [rejectedType]),
                  "Unsupported-type classifier accepts the known WebKit rejection")
            check(!isUnsupportedType(NSError(domain: "ProbeMissingArchive", code: 1), requested: [rejectedType]),
                  "Unsupported-type classifier rejects probe/runtime failures")
            check(!isUnsupportedType(NSError(domain: WKErrorDomain, code: WKError.Code.unknown.rawValue,
                                            userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred while fetching data."]), requested: [rejectedType]),
                  "Unsupported-type classifier rejects unrelated WebKit archive failures")
            let sourceID = UUID(), destinationID = UUID()
            ownedIDs = [sourceID, destinationID]
            let source = WKWebsiteDataStore(forIdentifier: sourceID)
            let destination = WKWebsiteDataStore(forIdentifier: destinationID)
            progress("sourceNavigation")
            var sourceWeb: WKWebView? = try await open(source)
            progress("seedSyntheticStorage")
            let seed = try await evaluate("""
            probeStep = 'writeSimpleStorage';
            localStorage.setItem('probe', 'owned-synthetic-probe');
            sessionStorage.setItem('probe', 'owned-synthetic-probe');
            document.cookie = 'probe=owned-synthetic-probe; Path=/; Secure; SameSite=Strict; Max-Age=3600';
            probeStep = 'generateNonextractableCryptoKey';
            const key = await crypto.subtle.generateKey({name:'AES-GCM', length:256}, false, ['encrypt','decrypt']);
            globalThis.__syntheticProbeKey = key;
            probeStep = 'createIndexedDB';
            const db = await new Promise((resolve, reject) => {
              const request = indexedDB.open('synthetic-portability', 1);
              request.onupgradeneeded = () => request.result.createObjectStore('fixture');
              request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
            });
            probeStep = 'storePlainIndexedDBRecord';
            await new Promise((resolve, reject) => {
              const transaction = db.transaction('fixture', 'readwrite');
              transaction.objectStore('fixture').put('owned-synthetic-probe', 'record');
              transaction.oncomplete = resolve; transaction.onerror = () => reject(transaction.error);
              transaction.onabort = () => reject(transaction.error);
            });
            probeStep = 'tryOptionalStoredCryptoKey';
            let keyCloneSupported = false, keyCloneError = 'none';
            try {
              await new Promise((resolve, reject) => {
                const transaction = db.transaction('fixture', 'readwrite');
                transaction.oncomplete = resolve;
                transaction.onerror = () => reject(transaction.error);
                transaction.onabort = () => reject(transaction.error);
                transaction.objectStore('fixture').put(key, 'key');
              });
              keyCloneSupported = true;
            } catch (error) {
              if (error.name !== 'DataCloneError') throw error;
              keyCloneError = 'DataCloneError';
            }
            db.close();
            probeStep = 'seedCacheStorage';
            await (await caches.open('synthetic-portability')).put('/synthetic', new Response('owned-synthetic-probe'));
            return {seeded:true, keyCloneSupported, keyCloneError};
            """, in: sourceWeb!)
            if seed["keyCloneSupported"] as? Bool != true {
                limitations.append(["capability": "storedCryptoKeyPositiveControl", "status": "UNAVAILABLE",
                                    "reason": "DataCloneError in this disposable ad-hoc simulator app; no persisted-key roundtrip was proven."])
            }
            observations.append(["phase": "optionalStoredCryptoKey", "keyCloneSupported": seed["keyCloneSupported"] as? Bool ?? false,
                                 "errorName": seed["keyCloneError"] as? String ?? "unknown"])
            progress("optionalServiceWorkerSeed")
            do {
                _ = try await evaluate("""
            probeStep = 'registerServiceWorker';
            const registration = await navigator.serviceWorker.register('/worker.js');
            probeStep = 'activateServiceWorker';
            await new Promise((resolve, reject) => {
              const worker = registration.installing || registration.waiting || registration.active;
              if (!worker) { reject(new Error('No fixture worker')); return; }
              const changed = () => {
                if (worker.state === 'activated') { worker.removeEventListener('statechange', changed); resolve(); }
                else if (worker.state === 'redundant') { worker.removeEventListener('statechange', changed); reject(new Error('Redundant fixture worker')); }
              };
              worker.addEventListener('statechange', changed); changed();
            });
            return {seeded:true};
            """, in: sourceWeb!)
            } catch {
                limitations.append(["capability": "serviceWorkerPositiveControl", "status": "UNAVAILABLE",
                                    "reason": "Registration or activation failed in the owned fixture; see sanitized phase diagnostics."])
            }
            progress("verifySyntheticStorage")
            let sourceState = try await verify(sourceWeb!)
            observations.append(["phase": "sourceSeeded", "state": sourceState])
            let sourceFields = ["secureContext", "localStoragePresent", "sessionStoragePresent", "cookiePresent", "indexedDBPresent", "indexedDBRecordPresent", "memoryKeyPresent", "memoryKeyUsable", "memoryKeyNonextractable", "memoryExportRejected", "cachePresent"]
            for field in sourceFields {
                check(sourceState[field] as? Bool == true, "Source positive control: \(field)")
            }
            guard sourceFields.allSatisfy({ sourceState[$0] as? Bool == true }) else {
                throw NSError(domain: "ProbePositiveControlFailure", code: 1)
            }
            if seed["keyCloneSupported"] as? Bool == true {
                check(sourceState["keyPresent"] as? Bool == true && sourceState["keyUsable"] as? Bool == true && sourceState["keyNonextractable"] as? Bool == true && sourceState["exportRejected"] as? Bool == true,
                      "Optional persisted CryptoKey remains usable and nonextractable")
            }
            if sourceState["serviceWorkerQueryAvailable"] as? Bool != true {
                limitations.append(["capability": "serviceWorkerQuery", "status": "UNAVAILABLE",
                                    "reason": "Public service-worker query was unavailable in the owned fixture."])
            }
            if sourceState["serviceWorkerPresent"] as? Bool == true {
                check(true, "Optional service-worker registration positive control is present")
            }
            progress("publicArchiveAPIs")
            let localArchive = try await archive(source, types: [WKWebsiteDataTypeLocalStorage])
            check(!localArchive.isEmpty, "Public LocalStorage archive produces a nonempty blob")
            for (name, types) in [
                ("IndexedDB", Set([WKWebsiteDataTypeIndexedDBDatabases])),
                ("ServiceWorker", Set([WKWebsiteDataTypeServiceWorkerRegistrations])),
                ("Cookies", Set([WKWebsiteDataTypeCookies])),
                ("LocalStorage+IndexedDB", Set([WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeIndexedDBDatabases])),
                ("AllWebsiteDataTypes", WKWebsiteDataStore.allWebsiteDataTypes())
            ] {
                do {
                    _ = try await archive(source, types: types)
                    check(false, "Public archive rejects unsupported requested type: \(name)")
                } catch {
                    let failure = error as NSError
                    let classified = isUnsupportedType(failure, requested: types)
                    observations.append(["phase": "unsupportedArchive", "type": name, "errorDomain": failure.domain,
                                         "errorCode": failure.code, "matchesKnownUnsupportedTypeRejection": classified])
                    check(classified, "Public archive rejects unsupported requested type: \(name)")
                }
            }
            let cookies = await source.httpCookieStore.allCookies()
            check(cookies.count == 1, "Source contains only one owned synthetic cookie")
            sourceWeb = nil; dispose()
            progress("restoreFreshDestination")
            try await restore(localArchive, to: destination)
            var restoredWeb: WKWebView? = try await open(destination)
            let restored = try await verify(restoredWeb!)
            observations.append(["phase": "afterLocalStorageRestore", "state": restored])
            check(restored["localStoragePresent"] as? Bool == true, "LocalStorage survives archive restore into a fresh named store")
            var omittedFields = ["sessionStoragePresent", "cookiePresent", "indexedDBPresent", "indexedDBRecordPresent", "cachePresent"]
            if sourceState["keyPresent"] as? Bool == true { omittedFields.append("keyPresent") }
            if sourceState["serviceWorkerPresent"] as? Bool == true { omittedFields.append("serviceWorkerPresent") }
            for field in omittedFields {
                check(restored[field] as? Bool == false, "LocalStorage archive does not transfer \(field)")
            }
            for cookie in cookies { await destination.httpCookieStore.setCookie(cookie) }
            check(await destination.httpCookieStore.allCookies().count == 1, "Public cookie API copies the owned cookie into the fresh store")
            restoredWeb = nil; dispose()
            progress("reopenDestination")
            let reopened = try await open(WKWebsiteDataStore(forIdentifier: destinationID))
            let reopenedState = try await verify(reopened)
            observations.append(["phase": "destinationClosedAndReopened", "state": reopenedState])
            check(reopenedState["localStoragePresent"] as? Bool == true, "Restored LocalStorage persists after closing and reopening destination view")
            check(reopenedState["cookiePresent"] as? Bool == true, "Separately copied cookie persists after closing and reopening destination view")
            check(reopenedState["indexedDBPresent"] as? Bool == false && reopenedState["indexedDBRecordPresent"] as? Bool == false,
                  "IndexedDB and its seeded plain record remain absent after destination reopen")
            check(reopenedState["cachePresent"] as? Bool == false, "Seeded cache remains absent after destination reopen")
            if sourceState["serviceWorkerPresent"] as? Bool == true {
                check(reopenedState["serviceWorkerPresent"] as? Bool == false, "Seeded service worker remains absent after destination reopen")
            }
        } catch {
            let failure = error as NSError
            observations.append(["phase": "unexpectedFailure", "during": phase, "errorDomain": failure.domain, "errorCode": failure.code])
            check(false, "Probe completed without an unexpected failure")
        }
        dispose()
        // No provider directories are read or copied. Public removal is scoped
        // to IDs allocated by this invocation; runner deletes its simulator too.
        progress("removeOwnedStores")
        for identifier in ownedIDs {
            var removed = false
            for _ in 0..<5 {
                do { try await WKWebsiteDataStore.remove(forIdentifier: identifier); removed = true; break }
                catch { try? await Task.sleep(for: .seconds(2)) }
            }
            check(removed, "Owned synthetic named store removed")
        }
        let passed = checks.allSatisfy { $0["pass"] as? Bool == true }
        let result = passed ? (limitations.isEmpty ? "PASS" : "PASS_WITH_LIMITATIONS") : "FAIL"
        let report: [String: Any] = [
            "result": result, "checks": checks, "assertions": checks.count, "limitations": limitations,
            "observations": observations, "durationSeconds": Date().timeIntervalSince(started),
            "recordedAt": ISO8601DateFormatter().string(from: Date()), "osVersion": UIDevice.current.systemVersion,
            "scope": "Synthetic owned localhost HTTPS data on disposable iOS simulator; no WhatsApp data or actual linked-session restore.",
            "productionImplementation": false, "archiveBytesPersisted": false, "keyBytesExported": false,
            "conclusion": passed
                ? "Observed LocalStorage plus separately copied cookies is incomplete browser-state migration. This is not a working signed-in session backup."
                : "Probe did not pass. Failed controls cannot establish archive capability or a working signed-in session backup."
        ]
        let data = try! JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("result.json")
        try! data.write(to: output, options: .atomic)
    }
}

@MainActor
final class ProbeSceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene, let app = UIApplication.shared.delegate as? ProbeDelegate else { return }
        app.start(scene)
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(ProbeDelegate.self))
