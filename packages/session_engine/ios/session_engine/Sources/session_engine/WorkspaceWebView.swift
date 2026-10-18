import UIKit
import WebKit

/// A renderer callback cannot keep a waiting task or its WebView alive after the
/// deadline. Every path drops the continuation before resuming it exactly once.
@MainActor
private final class WorkspacePresentationResult {
    private var continuation: CheckedContinuation<WorkspacePresentation, Error>?
    private var result: Result<WorkspacePresentation, Error>?
    private var deadline: Task<Void, Never>?

    func install(_ continuation: CheckedContinuation<WorkspacePresentation, Error>) {
        if let result { continuation.resume(with: result) }
        else { self.continuation = continuation }
    }

    func startDeadline() {
        guard result == nil else { return }
        deadline = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(2)) } catch { return }
            self?.finish(.success(.unavailable))
        }
    }

    func finish(_ result: Result<WorkspacePresentation, Error>) {
        guard self.result == nil else { return }
        self.result = result
        let pending = continuation
        continuation = nil
        deadline?.cancel(); deadline = nil
        pending?.resume(with: result)
    }
}

/// Phone mode uses the actual host width. Original mode retains the desktop
/// viewport fit as an explicit recovery path. The bundled isolated-world adapter
/// changes only structural layout; no page data is returned to the host.
@MainActor
final class WorkspaceWebView: WKWebView {
    static let desktopLayoutWidth: CGFloat = 980
    private var lastHostBounds: CGRect = .zero
    private var stopped = false
    private(set) var presentationLayout: WorkspaceLayout = .phone
    private(set) var hasLayoutAdapter = false
    private var recognizedPhoneStructure = false
    private var modeRevision = 0
    private var presentationEligibilityEpoch = 0
    private var structureTimer: Timer?
    private var structureProbe: Task<Void, Never>?
    private var structureProbeID: UUID?
    // The engine supplies current-view, foreground and lock ownership checks.
    var canObserveLayout: (() -> Bool)?
    private static let layoutWorld = WKContentWorld.world(name: "dev.profiledesk.workspace-layout")

    private static var bundledLayout: String? {
        #if SWIFT_PACKAGE
        if let script = Bundle.module.url(forResource: "workspace_layout", withExtension: "js"),
           let source = try? String(contentsOf: script, encoding: .utf8) { return source }
        #endif
        for container in [Bundle(for: WorkspaceWebView.self), Bundle.main] {
            if let url = container.url(forResource: "session_engine_layout", withExtension: "bundle"),
               let bundle = Bundle(url: url), let script = bundle.url(forResource: "workspace_layout", withExtension: "js"),
               let source = try? String(contentsOf: script, encoding: .utf8) { return source }
        }
        return nil
    }

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        configuration.ignoresViewportScaleLimits = true
        if let source = Self.bundledLayout {
            // The script itself repeats the origin check; the content world is
            // isolated from page JS and no native script-message handler exists.
            let code = source + "\n;globalThis.__profileDeskLayout?.setMode('phone');void 0;"
            configuration.userContentController.addUserScript(WKUserScript(source: code,
                injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: Self.layoutWorld))
            hasLayoutAdapter = true
        }
        super.init(frame: frame, configuration: configuration)
        // Flutter already provides safe-area and keyboard-adjusted host bounds.
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    required init?(coder: NSCoder) { fatalError("Storyboard initialization is unsupported") }

    func fit(in hostBounds: CGRect) {
        guard !stopped, hostBounds.width.isFinite, hostBounds.height.isFinite,
              hostBounds.width > 1, hostBounds.height > 0,
              hostBounds != lastHostBounds else { return }
        lastHostBounds = hostBounds
        // The structural adapter is intentionally restricted to phone widths.
        // Wider landscape/tablet and narrow split views retain a complete
        // desktop presentation instead of clipping its 980px minimum width.
        let phoneWidth = (320...600).contains(hostBounds.width)
        let desktopFit = presentationLayout == .original || !recognizedPhoneStructure || !phoneWidth
        let scale: CGFloat = desktopFit ? min(1, hostBounds.width / Self.desktopLayoutWidth) : 1
        // Set bounds and center, not frame: UIView.frame is undefined while its
        // transform is nonidentity. UIKit transforms input coordinates with the
        // view, and the privacy cover remains in untransformed host coordinates.
        bounds = CGRect(x: 0, y: 0, width: hostBounds.width / scale, height: hostBounds.height / scale)
        center = CGPoint(x: hostBounds.midX, y: hostBounds.midY)
        transform = CGAffineTransform(scaleX: scale, y: scale)
        // Never change pageZoom or UIScrollView.zoomScale. Native pinch and
        // any browser adjustments during resizing remain owned by WebKit.
    }

    func setPresentationLayout(_ layout: WorkspaceLayout) {
        guard !stopped else { return }
        presentationLayout = layout
        modeRevision += 1
        stopStructureObservation()
        refit()
    }

    private func refit() {
        let previous = lastHostBounds
        lastHostBounds = .zero
        fit(in: superview?.bounds ?? previous)
    }

    func navigationStarted() {
        guard !stopped else { return }
        invalidatePresentationEligibility()
        modeRevision += 1
        recognizedPhoneStructure = false
        stopStructureObservation()
        refit()
    }

    func applyPresentationLayout() async throws {
        guard !stopped, hasLayoutAdapter, let url, WorkspaceURLPolicy.isWorkspace(url) else { throw SessionFailure.blocked }
        let revision = modeRevision
        if presentationLayout == .phone {
            let supported = try await supportsPhoneStructure()
            guard !stopped, modeRevision == revision else { throw SessionFailure.staleOperation }
            if supported != recognizedPhoneStructure { recognizedPhoneStructure = supported; refit() }
        }
        let mode = presentationLayout == .phone ? "phone" : "original"
        // Only this fixed enum is interpolated. No selector, URL or source enters
        // from Flutter. Discard the adapter's bounded internal status object.
        _ = try await evaluateJavaScript("globalThis.__profileDeskLayout?.setMode('\(mode)');void 0;",
                                         in: nil, contentWorld: Self.layoutWorld)
        guard !stopped, modeRevision == revision else { throw SessionFailure.staleOperation }
        if presentationLayout == .phone { startStructureObservation() }
    }

    private func supportsPhoneStructure() async throws -> Bool {
        // A fixed boolean reports only structural availability, never page text,
        // HTML, identities, credentials or a serialized DOM.
        let value = try await evaluateJavaScript("globalThis.__profileDeskLayout?.supportsStructure() === true;",
                                                in: nil, contentWorld: Self.layoutWorld)
        return value as? Bool == true
    }

    private func startStructureObservation() {
        guard structureTimer == nil, !stopped, presentationLayout == .phone else { return }
        structureTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.probeStructureIfUsable() }
        }
    }

    private func probeStructureIfUsable() {
        guard !stopped, presentationLayout == .phone,
              canObserveLayout?() == true, structureProbe == nil,
              let url, WorkspaceURLPolicy.isWorkspace(url) else { return }
        let revision = modeRevision
        let probeID = UUID()
        structureProbeID = probeID
        structureProbe = Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                if self.structureProbeID == probeID { self.structureProbe = nil; self.structureProbeID = nil }
            }
            guard let supported = try? await self.supportsPhoneStructure(),
                  !Task.isCancelled, !self.stopped, self.modeRevision == revision,
                  self.canObserveLayout?() == true else { return }
            guard supported != self.recognizedPhoneStructure else { return }
            self.recognizedPhoneStructure = supported
            self.refit()
            // Apply only on a structural transition, preserving selection on
            // steady-state probes. Unknown layouts regain a complete fit.
            try? await self.applyPresentationLayout()
        }
    }

    private func stopStructureObservation() {
        structureTimer?.invalidate(); structureTimer = nil
        structureProbe?.cancel(); structureProbe = nil
        structureProbeID = nil
    }

    func showList() async throws {
        guard !stopped, hasLayoutAdapter,
              let url, WorkspaceURLPolicy.isWorkspace(url) else { throw SessionFailure.blocked }
        modeRevision += 1
        // Native input dismissal preserves the official client's draft contents.
        endEditing(true)
        if presentationLayout != .phone {
            setPresentationLayout(.phone)
            try await applyPresentationLayout()
        }
        guard !stopped, presentationLayout == .phone else { throw SessionFailure.staleOperation }
        _ = try await evaluateJavaScript("globalThis.__profileDeskLayout?.showList();void 0;", in: nil, contentWorld: Self.layoutWorld)
    }

    func workspacePresentation() async throws -> WorkspacePresentation {
        try Task.checkCancellation()
        guard !stopped, hasLayoutAdapter, canObserveLayout?() == true,
              let url, WorkspaceURLPolicy.isWorkspace(url) else { throw SessionFailure.staleOperation }
        let revision = modeRevision
        let eligibility = presentationEligibilityEpoch
        let pending = WorkspacePresentationResult()
        // The result is one structural enum. This fixed isolated-world expression
        // cannot return text, HTML, identities, selectors or serialized page data.
        let expression = """
            (() => {
              const state = globalThis.__profileDeskLayout?.presentation?.()?.state;
              return state === 'original' || state === 'list' || state === 'menu' ||
                state === 'detail' || state === 'unavailable' ? state : 'unavailable';
            })()
            """
        let result = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending.install(continuation)
                guard !Task.isCancelled else { pending.finish(.failure(CancellationError())); return }
                pending.startDeadline()
                // WebKit cannot cancel an in-flight evaluation. This callback
                // holds no WebView and loses its result box when the wait ends.
                evaluateJavaScript(expression, in: nil, in: Self.layoutWorld) { [weak pending] evaluation in
                    let value: String?
                    switch evaluation {
                    case .success(let response): value = response as? String
                    case .failure: value = nil
                    }
                    let state: WorkspacePresentation
                    switch value {
                    case "original": state = .original
                    case "list": state = .list
                    case "menu": state = .menu
                    case "detail": state = .detail
                    default: state = .unavailable
                    }
                    pending?.finish(.success(state))
                }
            }
        } onCancel: {
            Task { @MainActor in pending.finish(.failure(CancellationError())) }
        }
        try Task.checkCancellation()
        guard !stopped, modeRevision == revision, presentationEligibilityEpoch == eligibility,
              canObserveLayout?() == true,
              let url = self.url, WorkspaceURLPolicy.isWorkspace(url) else { throw SessionFailure.staleOperation }
        return result
    }

    /// Losing foreground, unlock or reveal eligibility permanently invalidates
    /// an earlier query, even if the same view becomes eligible before it replies.
    func invalidatePresentationEligibility() { presentationEligibilityEpoch += 1 }

    func stopFitting() {
        guard !stopped else { return }
        invalidatePresentationEligibility()
        stopped = true
        stopStructureObservation()
        canObserveLayout = nil
        if hasLayoutAdapter {
            evaluateJavaScript("globalThis.__profileDeskLayout?.dispose();void 0;", in: nil, in: Self.layoutWorld, completionHandler: nil)
        }
        configuration.userContentController.removeAllUserScripts()
    }
}
