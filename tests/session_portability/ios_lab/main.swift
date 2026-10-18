import Foundation
import UIKit
import WebKit

private let labBundle = "dev.profiledesk.sessionPortabilityLab"
private let workspaceURL = URL(string: "https://web.whatsapp.com/")!
private let classifierWorld = WKContentWorld.world(name: "ProfileDeskSessionLabCounts")

// The only persistent identifier this lab can use is the random identifier it
// created in its own bundle's sandbox. It never enumerates existing stores.
private final class LabIdentity {
    private struct Record: Codable { let version: Int; let bundle: String; let id: UUID }
    private let file: URL
    private(set) var id: UUID

    init() throws {
        guard Bundle.main.bundleIdentifier == labBundle else { throw CocoaError(.fileReadNoPermission) }
        var directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true).appendingPathComponent("OwnedLab", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        var excluded = URLResourceValues(); excluded.isExcludedFromBackup = true
        try directory.setResourceValues(excluded)
        file = directory.appendingPathComponent("identity.json")
        if FileManager.default.fileExists(atPath: file.path) {
            let data = try Data(contentsOf: file)
            guard data.count <= 1024 else { throw CocoaError(.fileReadCorruptFile) }
            let record = try JSONDecoder().decode(Record.self, from: data)
            guard record.version == 1, record.bundle == labBundle else { throw CocoaError(.fileReadCorruptFile) }
            id = record.id
        } else {
            id = UUID()
            try persist()
        }
    }
    private func persist() throws {
        let record = Record(version: 1, bundle: labBundle, id: id)
        try JSONEncoder().encode(record).write(to: file, options: [.atomic, .completeFileProtection])
        var ownedFile = file
        var excluded = URLResourceValues(); excluded.isExcludedFromBackup = true
        try ownedFile.setResourceValues(excluded)
    }
    func replaceAfterClearing(_ cleared: UUID) throws {
        guard id == cleared else { throw CocoaError(.fileWriteNoPermission) }
        let previous = id
        id = UUID()
        do { try persist() } catch { id = previous; throw error }
    }
}

private struct CountsReport: Decodable {
    let schemaVersion: Int
    let status: String
    let reason: String
    let counts: [String: Int]
    let progress: [String: Int]
    let keyMetadata: [String: [Int]]

    static let fields: Set<String> = ["localStorage", "sessionStorage", "nodes",
        "primitive", "array", "object", "arrayBuffer", "typedArray", "date", "map", "set", "blob",
        "extractableKeys", "nonextractableKeys", "unsupported", "repeatedReferences"]
    static let progressFields: Set<String> = ["databasesDiscovered", "databasesInventoried", "databasesStarted", "databasesCompleted",
        "storesDiscovered", "storesInventoried", "storesStarted", "storesCompleted", "storesSampled", "storesSkipped",
        "recordsInventoried", "recordsDiscovered", "recordsStarted", "recordsCompleted",
        "inventoryTruncated", "inventoryChanges", "countChanges", "inventoryFailures"]
    static let algorithmLabels = ["Other", "AES-GCM", "AES-CBC", "AES-CTR", "AES-KW", "HMAC", "HKDF", "PBKDF2",
        "RSA-OAEP", "RSA-PSS", "RSASSA-PKCS1-v1_5", "ECDSA", "ECDH", "Ed25519", "X25519"]
    static let typeLabels = ["Other", "Secret", "Public", "Private"]
    static let usageLabels = ["Other", "Encrypt", "Decrypt", "Sign", "Verify", "Derive key", "Derive bits", "Wrap key", "Unwrap key"]
    static let reasons: Set<String> = ["origin", "apiUnavailable", "scanLimit", "deadline", "unsupportedType",
        "cancelled", "readFailure", "observedTypesOnly", "inventoryChanged", "countChanged", "coverageLimited"]
    static func parse(_ value: Any?) throws -> CountsReport {
        guard let dictionary = value as? [String: Any], Set(dictionary.keys) == ["schemaVersion", "status", "reason", "counts", "progress", "keyMetadata"] else {
            throw CocoaError(.coderInvalidValue)
        }
        let bytes = try JSONSerialization.data(withJSONObject: dictionary)
        guard bytes.count < 4096 else { throw CocoaError(.coderInvalidValue) }
        let report = try JSONDecoder().decode(CountsReport.self, from: bytes)
        guard report.schemaVersion == 3, ["complete", "inconclusive", "refused"].contains(report.status),
              reasons.contains(report.reason), Set(report.counts.keys) == fields,
              report.counts.values.allSatisfy({ $0 >= 0 && $0 <= 1_000_000 }),
              Set(report.progress.keys) == progressFields,
              report.progress.values.allSatisfy({ $0 >= 0 && $0 <= 9_007_199_254_740_991 }),
              Set(report.keyMetadata.keys) == ["algorithms", "types", "usages"] else { throw CocoaError(.coderInvalidValue) }
        for (field, labels) in [("algorithms", algorithmLabels), ("types", typeLabels), ("usages", usageLabels)] {
            guard let values = report.keyMetadata[field], values.count == labels.count,
                  values.allSatisfy({ $0 >= 0 && $0 <= 20_000 }) else { throw CocoaError(.coderInvalidValue) }
        }
        let keyObservations = report.counts["extractableKeys", default: 0] + report.counts["nonextractableKeys", default: 0]
        guard report.keyMetadata["algorithms"]!.reduce(0, +) == keyObservations,
              report.keyMetadata["types"]!.reduce(0, +) == keyObservations,
              report.keyMetadata["usages"]!.reduce(0, +) <= keyObservations * 8 else { throw CocoaError(.coderInvalidValue) }
        for prefix in ["databases", "stores", "records"] {
            guard report.progress[prefix + "Completed"]! <= report.progress[prefix + "Started"]!,
                  report.progress[prefix + "Started"]! <= report.progress[prefix + "Discovered"]! else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        let p = report.progress
        guard p["databasesInventoried"]! <= min(12, p["databasesDiscovered"]!), p["databasesStarted"]! <= 12,
              p["databasesCompleted"]! <= p["databasesInventoried"]!,
              p["storesInventoried"]! <= min(64, p["storesDiscovered"]!), p["storesStarted"]! <= p["storesInventoried"]!,
              p["storesCompleted"]! + p["storesSampled"]! <= p["storesStarted"]!,
              p["storesSkipped"]! == p["storesDiscovered"]! - p["storesStarted"]!,
              p["recordsStarted"]! <= 2_000, report.counts["nodes"]! <= 20_000,
              p["inventoryTruncated"]! <= 1, p["inventoryChanges"]! <= 12, p["inventoryFailures"]! <= 12,
              p["countChanges"]! <= p["storesStarted"]! else { throw CocoaError(.coderInvalidValue) }
        if report.status == "complete" {
            guard report.reason == "observedTypesOnly", p["databasesCompleted"]! == p["databasesDiscovered"]!,
                  p["storesCompleted"]! == p["storesDiscovered"]!, p["recordsCompleted"]! == p["recordsDiscovered"]!,
                  p["storesSampled"]! == 0, p["inventoryTruncated"]! == 0, p["inventoryChanges"]! == 0,
                  p["countChanges"]! == 0, p["inventoryFailures"]! == 0, report.counts["unsupported"]! == 0 else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        return report
    }
    private func histogram(_ name: String, labels: [String]) -> String {
        let values = keyMetadata[name, default: []]
        let parts = zip(labels, values).compactMap { label, value in value > 0 ? "\(label): \(value)" : nil }
        return parts.isEmpty ? "None observed" : parts.joined(separator: "; ")
    }
    var display: String {
        let nonextractable = counts["nonextractableKeys", default: 0]
        let heading: String
        if status != "complete" { heading = "Inconclusive scan (\(reason))." }
        else if nonextractable > 0 { heading = "Scan complete. Nonextractable key observations were recorded." }
        else { heading = "Scan complete. No nonextractable key was observed in the scanned records." }
        return """
        \(heading)

        Coverage (discovered so far):
        DBs: \(progress["databasesCompleted", default: 0]) full / \(progress["databasesStarted", default: 0]) visited / \(progress["databasesInventoried", default: 0]) inventoried / \(progress["databasesDiscovered", default: 0]) discovered
        Stores: \(progress["storesCompleted", default: 0]) full, \(progress["storesSampled", default: 0]) sampled, \(progress["storesSkipped", default: 0]) skipped
        Stores: \(progress["storesStarted", default: 0]) visited / \(progress["storesInventoried", default: 0]) inventoried / \(progress["storesDiscovered", default: 0]) discovered
        Records: \(progress["recordsCompleted", default: 0]) complete / \(progress["recordsStarted", default: 0]) started
        Records counted: \(progress["recordsDiscovered", default: 0]) at visits / \(progress["recordsInventoried", default: 0]) in inventory
        Schema/version changes: \(progress["inventoryChanges", default: 0]); count changes: \(progress["countChanges", default: 0])
        Inventory capped: \(progress["inventoryTruncated", default: 0]); read failures: \(progress["inventoryFailures", default: 0])
        Extractable key observations: \(counts["extractableKeys", default: 0])
        Nonextractable key observations: \(nonextractable)
        Unknown types: \(counts["unsupported", default: 0])
        LocalStorage entries: \(counts["localStorage", default: 0])
        SessionStorage entries: \(counts["sessionStorage", default: 0])

        Key algorithm counts: \(histogram("algorithms", labels: Self.algorithmLabels))
        Key type counts: \(histogram("types", labels: Self.typeLabels))
        Permitted usage counts: \(histogram("usages", labels: Self.usageLabels))

        Sampled stores contain unread records. Interrupted visits are not full scans. Counts can change between inventory and visits; this is not one stable snapshot.

        Key observations are not unique keys or proof of an authentication role. No key was used or exported. Even a full scan does not prove that login can be restored; other storage and server-side state are not covered.
        """
    }
}

@MainActor
private final class LabController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var identity: LabIdentity?
    private var web: WKWebView?
    private var generation = 0
    private var scanning = false
    private var activeScanToken: String?
    private var scanWatchdog: Task<Void, Never>?
    private var clearing = false
    private var cleanupRequired = false
    private let status = UILabel()
    private let openButton = UIButton(type: .system)
    private let scanButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let webContainer = UIView()
    private let cover = UIView()
    private var active: Bool { view.window?.windowScene?.activationState == .foregroundActive }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        webContainer.clipsToBounds = true
        let title = UILabel()
        title.text = "Session portability lab"
        title.font = .preferredFont(forTextStyle: .title2)
        title.adjustsFontForContentSizeCategory = true
        let explanation = UILabel()
        explanation.text = "Separate test workspace. Manually link a test account, then inspect storage type counts. This app cannot back up or restore a login."
        explanation.numberOfLines = 0
        explanation.font = .preferredFont(forTextStyle: .footnote)
        explanation.adjustsFontForContentSizeCategory = true
        status.numberOfLines = 0
        status.font = .preferredFont(forTextStyle: .footnote)
        status.textColor = .secondaryLabel
        button(openButton, "Open WhatsApp test workspace", #selector(openWorkspace))
        button(scanButton, "Run extended scan", #selector(scanStorage))
        button(clearButton, "Clear lab account", #selector(confirmClear))
        clearButton.tintColor = .systemRed
        let stack = UIStackView(arrangedSubviews: [title, explanation, openButton, scanButton, clearButton, status, webContainer])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            webContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
        ])
        cover.backgroundColor = .systemBackground
        cover.translatesAutoresizingMaskIntoConstraints = false
        let hidden = UILabel()
        hidden.text = "Session lab is covered"
        hidden.font = .preferredFont(forTextStyle: .headline)
        hidden.translatesAutoresizingMaskIntoConstraints = false
        cover.addSubview(hidden)
        view.addSubview(cover)
        NSLayoutConstraint.activate([
            cover.leadingAnchor.constraint(equalTo: view.leadingAnchor), cover.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cover.topAnchor.constraint(equalTo: view.topAnchor), cover.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hidden.centerXAnchor.constraint(equalTo: cover.centerXAnchor), hidden.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
        ])
        cover.isHidden = true
        do { identity = try LabIdentity(); status.text = "No account has been opened in this app session." }
        catch { status.text = "The lab identity is unavailable. No browser profile was opened." }
        updateButtons()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fitWorkspace()
    }
    private func fitWorkspace() {
        guard let web else { return }
        let host = webContainer.bounds
        guard host.width > 1, host.height > 0 else { return }
        let scale = min(1, host.width / 980)
        // Native desktop fit keeps the complete QR/linking page within bounds.
        // Never modify pageZoom/scrollView.zoomScale; WebKit retains pinch zoom.
        web.bounds = CGRect(x: 0, y: 0, width: host.width / scale, height: host.height / scale)
        web.center = CGPoint(x: host.midX, y: host.midY)
        web.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    private func button(_ button: UIButton, _ title: String, _ selector: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addTarget(self, action: selector, for: .touchUpInside)
    }
    private func allowed(_ url: URL?) -> Bool {
        guard let url else { return false }
        return url.scheme == "https" && url.host == "web.whatsapp.com" && (url.port == nil || url.port == 443) && url.user == nil && url.password == nil
    }
    private func updateButtons() {
        openButton.isEnabled = identity != nil && !scanning && !clearing && !cleanupRequired && web == nil
        scanButton.setTitle(scanning ? "Cancel scan" : "Run extended scan", for: .normal)
        scanButton.isEnabled = !clearing && active && (scanning || web?.isLoading == false && allowed(web?.url))
        clearButton.isEnabled = identity != nil && !scanning && !clearing
    }
    @objc private func openWorkspace() {
        guard active, !scanning, !clearing, !cleanupRequired, web == nil, let identity else { return }
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: identity.id)
        configuration.limitsNavigationsToAppBoundDomains = true
        configuration.ignoresViewportScaleLimits = true
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        let os = ProcessInfo.processInfo.operatingSystemVersion
        // Same explicitly approved Safari-compatible identification experiment as
        // the development app. This lab does not claim to be the Safari app.
        configuration.applicationNameForUserAgent = "Version/\(os.majorVersion).\(os.minorVersion) Safari/605.1.15"
        let browser = WKWebView(frame: .zero, configuration: configuration)
        browser.isInspectable = false
        browser.navigationDelegate = self
        browser.uiDelegate = self
        browser.scrollView.contentInsetAdjustmentBehavior = .never
        webContainer.addSubview(browser)
        web = browser
        fitWorkspace()
        status.text = "Link a separate test account manually. Scanning never starts automatically."
        browser.load(URLRequest(url: workspaceURL))
        updateButtons()
    }
    @objc private func scanStorage() {
        if active, scanning {
            invalidateScan()
            status.text = "Scan cancelled and its report discarded. A pending WebKit read may still finish."
            updateButtons()
            return
        }
        guard active, !scanning, !clearing, let web, !web.isLoading, allowed(web.url),
              let scriptURL = Bundle.main.url(forResource: "StorageClassifier", withExtension: "js"),
              let script = try? String(contentsOf: scriptURL, encoding: .utf8) else { return }
        scanning = true
        generation += 1
        let ticket = generation
        let scanToken = UUID().uuidString
        activeScanToken = scanToken
        status.text = "Manual extended scan: inventory, then small stores and bounded prefixes. Same 30-second target and record limits. Tap Cancel scan to discard it."
        updateButtons()
        Task { @MainActor [weak self, weak web] in
            guard let self, let web else { return }
            guard self.generation == ticket, self.activeScanToken == scanToken,
                  self.active, self.web === web, !web.isLoading, self.allowed(web.url) else {
                if self.generation == ticket { self.invalidateScan(); self.updateButtons() }
                return
            }
            self.scanWatchdog = Task { @MainActor [weak self] in
                do { try await Task.sleep(for: .seconds(35)) } catch { return }
                guard !Task.isCancelled, let self, self.generation == ticket else { return }
                self.invalidateScan()
                self.status.text = "Scan timed out and was discarded. A pending WebKit read may still finish; no result will be shown or saved."
                self.updateButtons()
            }
            do {
                let value = try await web.callAsyncJavaScript(script, arguments: ["scanToken": scanToken], in: nil, contentWorld: classifierWorld)
                guard self.generation == ticket, self.active, self.web === web, self.allowed(web.url) else { return }
                let report = try CountsReport.parse(value)
                self.status.text = report.status == "complete" ? "Counts scan finished. Session restoration is still unproven." : "Scan was inconclusive. Session restoration is still unproven."
                let alert = UIAlertController(title: "Storage observations", message: report.display, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Done", style: .default))
                self.present(alert, animated: true)
            } catch {
                guard self.generation == ticket, self.active else { return }
                self.status.text = "Scan inconclusive. The page may have changed or a storage API was unavailable."
            }
            guard self.generation == ticket else { return }
            self.scanning = false
            self.activeScanToken = nil
            self.scanWatchdog?.cancel()
            self.scanWatchdog = nil
            self.updateButtons()
        }
    }
    private func invalidateScan() {
        let token = activeScanToken
        generation += 1
        scanning = false
        activeScanToken = nil
        scanWatchdog?.cancel()
        scanWatchdog = nil
        if let token, let web {
            // token is generated locally by UUID, never obtained from page data.
            web.evaluateJavaScript("if (globalThis.__profileDeskPortabilityToken === '\(token)') globalThis.__profileDeskPortabilityToken = null; void 0;", in: nil,
                                   in: classifierWorld, completionHandler: nil)
        }
    }
    func coverForBackground() {
        cover.isHidden = false
        view.bringSubviewToFront(cover)
        presentedViewController?.dismiss(animated: false)
        invalidateScan()
        status.text = "Workspace covered. Any unfinished scan was discarded."
        updateButtons()
    }
    func uncoverForForeground() { cover.isHidden = false; updateButtons() }
    func becameActive() { cover.isHidden = true; updateButtons() }
    @objc private func confirmClear() {
        guard active, !scanning, !clearing, identity != nil else { return }
        let alert = UIAlertController(title: "Clear this lab account?", message: "This removes only the browser profile created by Session Lab. Link the test account again to use it. Profile Desk accounts are separate.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear lab account", style: .destructive) { [weak self] _ in self?.clearOwnedAccount() })
        present(alert, animated: true)
    }
    private func clearOwnedAccount() {
        guard active, !scanning, !clearing, let identity else { return }
        let ownedID = identity.id
        invalidateScan()
        web?.stopLoading(); web?.navigationDelegate = nil; web?.uiDelegate = nil
        web?.removeFromSuperview(); web = nil
        clearing = true
        cleanupRequired = true
        status.text = "Clearing this lab's account…"
        updateButtons()
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await WKWebsiteDataStore.remove(forIdentifier: ownedID)
                try identity.replaceAfterClearing(ownedID)
                self.cleanupRequired = false
                self.status.text = "Lab account cleared. A new, empty lab profile will be used next."
            } catch { self.status.text = "Lab cleanup did not finish. Retry Clear lab account before opening another workspace." }
            self.clearing = false
            self.updateButtons()
        }
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { invalidateScan(); updateButtons() }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { updateButtons() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { status.text = "The workspace could not load."; updateButtons() }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { status.text = "The workspace could not load."; updateButtons() }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(action.targetFrame != nil && allowed(action.request.url) ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(response.canShowMIMEType && allowed(response.response.url) ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? { nil }
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) { decisionHandler(.deny) }
}

@MainActor
final class LabSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var controller: LabController?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        let controller = LabController()
        window.rootViewController = controller
        self.controller = controller
        self.window = window
        window.makeKeyAndVisible()
    }
    func sceneWillResignActive(_ scene: UIScene) { controller?.coverForBackground() }
    func sceneDidEnterBackground(_ scene: UIScene) { controller?.coverForBackground() }
    func sceneWillEnterForeground(_ scene: UIScene) { controller?.uncoverForForeground() }
    func sceneDidBecomeActive(_ scene: UIScene) { controller?.becameActive() }
}

@MainActor
final class LabAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Lab", sessionRole: session.role)
        configuration.delegateClass = LabSceneDelegate.self
        return configuration
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(LabAppDelegate.self))
