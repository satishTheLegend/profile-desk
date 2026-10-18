import Flutter
import UIKit
import WebKit

@MainActor
final class SessionHostView: UIView {
    private let cover = UIView()
    var covered = true { didSet { cover.isHidden = !covered; if covered { bringSubviewToFront(cover) }; accessibilityElementsHidden = covered } }
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        clipsToBounds = true
        cover.backgroundColor = .systemBackground
        cover.isOpaque = true
        cover.isUserInteractionEnabled = true
        cover.accessibilityLabel = "Account content protected"
        addSubview(cover)
    }
    convenience init() { self.init(frame: .zero) }
    required init?(coder: NSCoder) { fatalError("Storyboard initialization is unsupported") }
    override func layoutSubviews() {
        super.layoutSubviews()
        for child in subviews {
            if let workspace = child as? WorkspaceWebView { workspace.fit(in: bounds) }
            else { child.frame = bounds }
        }
        bringSubviewToFront(cover)
    }
    func attach(_ web: WKWebView) {
        insertSubview(web, belowSubview: cover)
        if let workspace = web as? WorkspaceWebView { workspace.fit(in: bounds) }
        else { web.frame = bounds; web.autoresizingMask = [.flexibleWidth,.flexibleHeight] }
    }
}

@MainActor
private final class HostPlatformView: NSObject, FlutterPlatformView {
    private let host: UIView
    init(host: UIView) { self.host = host }
    nonisolated func view() -> UIView { MainActor.assumeIsolated { host } }
}

@MainActor
final class SessionHostFactory: NSObject, FlutterPlatformViewFactory {
    private let engine: SessionEnginePlugin
    init(engine: SessionEnginePlugin) { self.engine = engine }
    nonisolated func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        MainActor.assumeIsolated {
        engine.host.frame = frame
        return HostPlatformView(host: engine.host)
        }
    }
}

@MainActor
final class BoundWebSession: NSObject, WKNavigationDelegate, WKUIDelegate {
    let handle: ViewHandle
    let webView: WKWebView
    var ready = false
    private weak var engine: SessionEnginePlugin?
    private var disposed = false
    private var activeNavigation: WKNavigation?

    init(handle: ViewHandle, webView: WKWebView, engine: SessionEnginePlugin) {
        self.handle = handle; self.webView = webView; self.engine = engine
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.keyboardDismissMode = .interactive
    }
    func load(_ request: URLRequest) { ready = false; activeNavigation = webView.load(request) }
    func reload() { ready = false; activeNavigation = webView.reload() }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activeNavigation = navigation; ready = false
        (webView as? WorkspaceWebView)?.navigationStarted()
    }
    func dispose() {
        guard !disposed else { return }; disposed = true
        (webView as? WorkspaceWebView)?.stopFitting()
        webView.stopLoading()
        webView.closeAllMediaPresentations(completionHandler: nil)
        webView.setAllMediaPlaybackSuspended(true, completionHandler: nil)
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView.removeFromSuperview()
        engine = nil
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !disposed, navigation === activeNavigation, let url = webView.url, WorkspaceURLPolicy.isWorkspace(url) else { return }
        Task { @MainActor [weak self] in
            guard let self, !self.disposed else { return }
            do {
                if let workspace = webView as? WorkspaceWebView { try await workspace.applyPresentationLayout() }
                guard !self.disposed, navigation === self.activeNavigation else { return }
                self.engine?.sessionReady(self)
            } catch {
                guard !self.disposed, navigation === self.activeNavigation else { return }
                self.engine?.sessionFailed(self, code: "layoutUnavailable")
            }
        }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { if navigation === activeNavigation { failed(error) } }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { if navigation === activeNavigation { failed(error) } }
    private func failed(_ error: Error) {
        guard !disposed, (error as NSError).code != NSURLErrorCancelled else { return }
        engine?.sessionFailed(self, code: "navigationFailed")
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { engine?.sessionFailed(self, code: "rendererTerminated") }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard !disposed, engine?.owns(handle) == true, let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if navigationAction.shouldPerformDownload, engine?.isUsable(handle) == true,
           let currentURL = webView.url, WorkspaceURLPolicy.isWorkspace(currentURL),
           ["https","blob"].contains(url.scheme?.lowercased() ?? "") {
            decisionHandler(.download); return
        }
        if navigationAction.targetFrame?.isMainFrame == false {
            decisionHandler(["https","about","blob"].contains(url.scheme?.lowercased() ?? "") ? .allow : .cancel); return
        }
        if WorkspaceURLPolicy.isWorkspace(url) {
            if navigationAction.targetFrame == nil { load(navigationAction.request); decisionHandler(.cancel) }
            else { decisionHandler(.allow) }
            return
        }
        if navigationAction.navigationType == .linkActivated, engine?.isUsable(handle) == true, WorkspaceURLPolicy.isExternal(url) {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard !disposed, engine?.owns(handle) == true else { decisionHandler(.cancel); return }
        if !navigationResponse.canShowMIMEType {
            decisionHandler(engine?.isUsable(handle) == true && navigationResponse.response.url?.scheme == "https" ? .download : .cancel)
        } else { decisionHandler(.allow) }
    }
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) { engine?.beginDownload(download, session: self) }
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) { engine?.beginDownload(download, session: self) }
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Platform trust validation remains enabled; no certificate or HTTP credential override.
        completionHandler(.performDefaultHandling, nil)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? { nil }
    func webViewDidClose(_ webView: WKWebView) { engine?.sessionFailed(self, code: "windowClosed") }

    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // Conditional capture remains disabled until device/service evidence clears its gate.
        decisionHandler(.deny)
    }
    func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) { decisionHandler(.deny) }

    @available(iOS 18.4, *)
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        guard !disposed, engine?.isUsable(handle) == true,
              frame.isMainFrame, frame.securityOrigin.protocol == "https", frame.securityOrigin.host == "web.whatsapp.com", frame.securityOrigin.port == 0 || frame.securityOrigin.port == 443 else { completionHandler(nil); return }
        engine?.pickFiles(session: self, parameters: parameters, completion: completionHandler)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // Do not promote untrusted page text into native account/permission UI.
        completionHandler()
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) { completionHandler(false) }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) { completionHandler(nil) }
}
