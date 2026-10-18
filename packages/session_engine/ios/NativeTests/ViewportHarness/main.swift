import UIKit
import WebKit

// Only controlled local HTML is evaluated here. Production's layout adapter
// observes structural booleans, while this harness alone measures fixture DOM.
@MainActor
final class Checks: NSObject, WKNavigationDelegate {
    var tests = [[String: Any]]()
    var measurements = [[String: Any]]()
    var identityMeasurement = [String: Any]()
    func expect(_ condition: Bool, _ name: String) { tests.append(["name": name, "pass": condition]) }
    func pause(_ milliseconds: Int = 600) async { try? await Task.sleep(for: .milliseconds(milliseconds)) }
    func configuration() -> WKWebViewConfiguration {
        let value = WKWebViewConfiguration()
        value.websiteDataStore = .nonPersistent()
        value.defaultWebpagePreferences.preferredContentMode = .desktop
        value.ignoresViewportScaleLimits = true
        return value
    }
    func html(hidden: Bool = false, responsive: Bool = false) -> String {
        """
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <style>html,body{margin:0;width:100vw;height:100%;\(hidden ? "overflow:hidden" : "")}
        main{width:\(responsive ? "100%" : "980px");height:300px;background:linear-gradient(90deg,red,blue)}</style>
        <main id="fixture">Controlled desktop workspace fixture</main>
        """
    }
    func load(_ web: WKWebView, html: String, baseURL: URL? = nil) async {
        web.loadHTMLString(html, baseURL: baseURL)
        for _ in 0..<75 {
            if !web.isLoading && web.scrollView.contentSize.width > 0 { break }
            await pause(200)
        }
        await pause()
    }
    func measure(_ web: WKWebView, _ name: String) async -> (width: Double, right: Double) {
        await pause()
        let value = (try? await web.evaluateJavaScript("({width:innerWidth,right:document.getElementById('fixture').getBoundingClientRect().right})")) as? [String: Double] ?? [:]
        measurements.append(["name": name, "width": web.bounds.width, "height": web.bounds.height,
            "contentWidth": web.scrollView.contentSize.width, "zoomScale": web.scrollView.zoomScale,
            "minimumZoomScale": web.scrollView.minimumZoomScale, "maximumZoomScale": web.scrollView.maximumZoomScale,
            "pageZoom": web.pageZoom, "fitScale": web.transform.a, "renderedWidth": web.bounds.width * web.transform.a, "document": value])
        return (value["width"] ?? -1, value["right"] ?? -2)
    }
    func phoneLayout(in host: UIView) async {
        let native = SessionHostView(frame: CGRect(x: 0, y: 0, width: 440, height: 700))
        host.addSubview(native)
        let web = WorkspaceWebView(frame: .zero, configuration: configuration())
        native.attach(web)
        native.covered = false
        expect(web.hasLayoutAdapter, "fixture bundles the identical production layout resource")
        let fixture = """
        <!doctype html><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>html,body{margin:0;height:100%;font-size:16px}#app{display:flex;min-width:980px;height:100vh}
        #side{width:400px;min-width:400px}#pane-side{height:100%}#main{flex:1;min-width:580px}</style>
        <div id="app"><div id="side"><div id="pane-side"><div role="row"><button>Fixture account row</button></div></div></div><div id="main"><p>Fixture detail pane</p></div></div>
        """
        // Supplied local HTML only; no service request, account or message data.
        await load(web, html: fixture, baseURL: URL(string: "https://web.whatsapp.com/")!)
        do { try await web.applyPresentationLayout() }
        catch { expect(false, "phone adapter activation completes") }
        await pause()
        expect(web.bounds.width == 440 && web.transform == .identity,
               "recognized phone panes use actual native width without shrinking text")
        let isolated = try? await web.evaluateJavaScript("typeof globalThis.__profileDeskLayout")
        expect(isolated as? String == "undefined", "page JavaScript cannot see the isolated-world layout API")
        let phone = (try? await web.evaluateJavaScript("({width:document.documentElement.clientWidth,side:document.getElementById('side').getBoundingClientRect().width,main:getComputedStyle(document.getElementById('main')).visibility,font:parseFloat(getComputedStyle(document.body).fontSize)})")) as? [String: Any] ?? [:]
        expect(phone["width"] as? Double == 440 && phone["side"] as? Double == 440 && phone["font"] as? Double == 16,
               "fixture list fills phone width and its 16px text remains native size")
        expect(phone["main"] as? String == "hidden", "recognized phone workspace starts with list rather than detail")
        for width: CGFloat in [320, 375, 440] {
            native.frame.size.width = width
            native.setNeedsLayout(); native.layoutIfNeeded()
            await pause()
            expect(web.bounds.width == width && web.transform == .identity,
                   "recognized phone bounds follow host width \(Int(width))")
        }
        for width: CGFloat in [375, 852, 375, 280, 1366, 440] {
            native.frame.size.width = width
            native.setNeedsLayout(); native.layoutIfNeeded()
            await pause()
            let expectedScale: CGFloat = (320...600).contains(width) ? 1 : min(1, width / 980)
            expect(abs(web.transform.a - expectedScale) < 0.001 && abs(web.bounds.width * web.transform.a - width) < 0.01,
                   "rotation and split width \(Int(width)) preserve the complete native presentation")
            let target = CGPoint(x: width - 10, y: 100)
            let hit = native.hitTest(target, with: nil)
            expect(hit === web || hit?.isDescendant(of: web) == true,
                   "right-edge hit testing remains aligned at width \(Int(width))")
            native.covered = true
            native.setNeedsLayout(); native.layoutIfNeeded()
            let cover = native.subviews.last!
            expect(cover.frame == native.bounds && cover.transform == .identity && native.hitTest(target, with: nil) === cover,
                   "rotation cover blocks the complete native host at width \(Int(width))")
            native.covered = false
        }
        native.frame.size = CGSize(width: 440, height: 350)
        native.setNeedsLayout(); native.layoutIfNeeded()
        expect(web.bounds.size == native.bounds.size && web.transform == .identity,
               "recognized workspace respects keyboard-height resize at native scale")
        web.canObserveLayout = { true }
        _ = try? await web.evaluateJavaScript("window.savedSide=document.getElementById('side');savedSide.remove();void 0")
        await pause(1400)
        expect(web.bounds.width == 980, "unknown replacement layout regains complete desktop fit instead of clipping")
        web.setPresentationLayout(.original)
        try? await web.applyPresentationLayout()
        expect(web.bounds.width == 980 && abs(web.transform.a - 440.0 / 980.0) < 0.001,
               "explicit Original layout restores desktop fit")
        let cleaned = try? await web.evaluateJavaScript("document.querySelector('style[data-profile-desk-layout]') === null")
        expect(cleaned as? Bool == true, "Original layout removes adapter presentation styles")
        do { try await web.showList() }
        catch { expect(false, "Original to Chats command completes") }
        expect(web.presentationLayout == .phone && web.bounds.width == 980,
               "Chats command keeps unknown structure fully fitted")
        _ = try? await web.evaluateJavaScript("document.getElementById('app').prepend(window.savedSide);void 0")
        await pause(1400)
        expect(web.presentationLayout == .phone && web.bounds.width == 440 && web.transform == .identity,
               "restored recognized structure recovers native-size phone presentation")
        web.stopFitting(); web.stopLoading(); web.removeFromSuperview(); native.removeFromSuperview()

        let waitingHost = SessionHostView(frame: CGRect(x: 0, y: 0, width: 440, height: 700))
        host.addSubview(waitingHost)
        let waiting = WorkspaceWebView(frame: .zero, configuration: configuration())
        waitingHost.attach(waiting)
        waiting.canObserveLayout = { false }
        await load(waiting, html: "<!doctype html><meta name=viewport content='width=device-width,initial-scale=1'><style>html,body{margin:0;height:100%}</style><div id=app></div>", baseURL: URL(string: "https://web.whatsapp.com/")!)
        try? await waiting.applyPresentationLayout()
        expect(waiting.bounds.width == 980, "unrecognized preauthentication page remains fully fitted")
        _ = try? await waiting.evaluateJavaScript("document.getElementById('app').innerHTML='<div id=side><div id=pane-side></div></div><div id=main></div>';void 0")
        await pause(1400)
        expect(waiting.bounds.width == 980, "ineligible foreground/lock ownership blocks structural polling")
        waiting.canObserveLayout = { true }
        await pause(1600)
        expect(waiting.bounds.width == 440 && waiting.transform == .identity,
               "eligible late-arriving structural hooks activate phone width without extracting content")
        waitingHost.covered = true
        waitingHost.setNeedsLayout(); waitingHost.layoutIfNeeded()
        let cover = waitingHost.subviews.last!
        expect(cover.transform == .identity && cover.frame == waitingHost.bounds,
               "phone fallback transition leaves privacy cover in native coordinates")
        waiting.stopFitting(); waiting.stopLoading(); waiting.removeFromSuperview(); waitingHost.removeFromSuperview()
    }
    func presentationStatus(in host: UIView) async {
        let native = SessionHostView(frame: CGRect(x: 0, y: 0, width: 440, height: 700))
        host.addSubview(native)
        let web = WorkspaceWebView(frame: .zero, configuration: configuration())
        native.attach(web)
        native.covered = false
        web.canObserveLayout = { true }
        let fixture = """
        <!doctype html><meta name=viewport content='width=device-width,initial-scale=1'>
        <style>html,body{margin:0;height:100%}#app{display:flex;min-width:980px;height:100vh}
        #side{width:400px;min-width:400px}#pane-side{height:100%}#main{flex:1;min-width:580px}</style>
        <div id=app><div id=side><div id=pane-side></div></div><div id=main></div></div>
        """
        await load(web, html: fixture, baseURL: URL(string: "https://web.whatsapp.com/")!)
        try? await web.applyPresentationLayout()
        // As in phoneLayout(), allow WebKit to commit the new 440px viewport
        // after native fitting before asserting a steady presentation state.
        await pause()
        let first = try? await web.workspacePresentation()
        let second = try? await web.workspacePresentation()
        measurements.append(["name": "presentation-status-initial", "width": web.bounds.width,
            "first": first.map { String(describing: $0) } ?? "rejected",
            "second": second.map { String(describing: $0) } ?? "rejected"])
        expect(first == .list && second == .list && web.presentationLayout == .phone,
               "presentation query returns the existing structural state without changing mode")
        web.setPresentationLayout(.original)
        try? await web.applyPresentationLayout()
        let original = try? await web.workspacePresentation()
        expect(original == .original, "presentation query reports explicit Original layout")

        // These overrides exist only in the controlled fixture's isolated world.
        // Production exposes no evaluator, handler or page-to-native bridge.
        let world = WKContentWorld.world(name: "dev.profiledesk.workspace-layout")
        func reply(_ expression: String, delayMilliseconds: Int = 0) async {
            let delay = delayMilliseconds > 0 ? "const end=performance.now()+\(delayMilliseconds);while(performance.now()<end){};" : ""
            _ = try? await web.evaluateJavaScript("""
                Object.defineProperty(globalThis,'__profileDeskLayout',{configurable:true,value:Object.freeze({
                  presentation(){\(delay)return Object.freeze({state:\(expression)});}
                })});void 0;
                """, in: nil, contentWorld: world)
        }
        let states: [(String, WorkspacePresentation)] = [("'original'", .original), ("'list'", .list),
            ("'menu'", .menu), ("'detail'", .detail), ("'unavailable'", .unavailable)]
        for (expression, expected) in states {
            await reply(expression)
            let result = try? await web.workspacePresentation()
            expect(result == expected, "presentation accepts the fixed structural enum \(expected)")
        }
        for expression in ["null", "42", "({state:'detail'})", "'unexpected fixture text'"] {
            await reply(expression)
            let result = try? await web.workspacePresentation()
            expect(result == .unavailable, "malformed fixture presentation is reduced to unavailable")
        }
        web.canObserveLayout = { false }
        do { _ = try await web.workspacePresentation(); expect(false, "ineligible ownership rejects presentation before evaluation") }
        catch { expect(true, "ineligible ownership rejects presentation before evaluation") }
        web.canObserveLayout = { true }
        await reply("'detail'", delayMilliseconds: 300)
        let changedEligibility = Task { @MainActor in
            do { _ = try await web.workspacePresentation(); return false } catch { return true }
        }
        await pause(30)
        web.canObserveLayout = { false }
        expect(await changedEligibility.value, "lock or foreground ownership loss discards the pending presentation")
        web.canObserveLayout = { true }
        let changedMode = Task { @MainActor in
            do { _ = try await web.workspacePresentation(); return false } catch { return true }
        }
        await pause(30)
        web.setPresentationLayout(.phone)
        expect(await changedMode.value, "mode revision discards an older presentation reply")
        for transition in ["background and foreground", "lock and unlock", "cover and reveal"] {
            await reply("'detail'", delayMilliseconds: 300)
            let roundTrip = Task { @MainActor in
                do { _ = try await web.workspacePresentation(); return false } catch { return true }
            }
            await pause(30)
            web.canObserveLayout = { false }
            // Production calls this from the synchronous lifecycle/privacy
            // hooks before the same view can become eligible again.
            web.invalidatePresentationEligibility()
            web.canObserveLayout = { true }
            expect(await roundTrip.value, "\(transition) round trip cannot restore an earlier query's ownership")
        }
        await reply("'detail'", delayMilliseconds: 300)
        let navigationRoundTrip = Task { @MainActor in
            do { _ = try await web.workspacePresentation(); return false } catch { return true }
        }
        await pause(30)
        // The production navigation delegate invokes this before any new page
        // can become ready, including a return to the same trusted origin.
        web.navigationStarted()
        expect(await navigationRoundTrip.value, "navigation round trip cannot restore an older presentation query")
        await reply("'detail'", delayMilliseconds: 300)
        let canceled = Task { @MainActor in
            do { _ = try await web.workspacePresentation(); return false }
            catch is CancellationError { return true }
            catch { return false }
        }
        await pause(30)
        canceled.cancel()
        expect(await canceled.value, "task cancellation drops the pending presentation continuation")
        await reply("'detail'", delayMilliseconds: 3000)
        let started = Date()
        let timedOut = try? await web.workspacePresentation()
        let elapsed = Date().timeIntervalSince(started)
        expect(timedOut == .unavailable && elapsed >= 1.8 && elapsed < 2.8,
               "blocked fixture query resolves unavailable at the two-second native deadline")
        // Let the renderer's old completion arrive. It must neither resume the
        // completed continuation twice nor contaminate a subsequent query.
        await pause(1400)
        await reply("'menu'")
        let next = try? await web.workspacePresentation()
        expect(timedOut == .unavailable && next == .menu,
               "late fixture reply is ignored and the next presentation query works")
        await load(web, html: fixture, baseURL: URL(string: "https://harness.profiledesk.invalid/")!)
        do { _ = try await web.workspacePresentation(); expect(false, "untrusted origin rejects presentation before evaluation") }
        catch { expect(true, "untrusted origin rejects presentation before evaluation") }
        web.stopFitting()
        do { _ = try await web.workspacePresentation(); expect(false, "stopped view rejects presentation") }
        catch { expect(true, "stopped view rejects presentation") }
        web.stopLoading(); web.removeFromSuperview(); native.removeFromSuperview()
    }
    func run(in host: UIView) async {
        await presentationStatus(in: host)
        if let window = host.window {
            let input = UITextField(frame: CGRect(x: 20, y: 20, width: 240, height: 48))
            input.text = "Owned unsent native draft"
            host.addSubview(input)
            expect(input.becomeFirstResponder(), "fictional native input can take keyboard focus")
            let privacy = WindowPrivacyCover(frame: .zero)
            privacy.show(in: window, allowUnlock: true, authenticating: false)
            expect(!input.isFirstResponder && privacy.isFirstResponder,
                   "whole-window privacy cover ends input and owns hardware-key focus")
            expect(input.text == "Owned unsent native draft",
                   "privacy input dismissal preserves the unsent native draft")
            expect(privacy.superview === window && privacy.frame == window.bounds && privacy.accessibilityViewIsModal,
                   "privacy cover protects the full window and accessibility tree")
            privacy.removeFromSuperview(); input.removeFromSuperview()
        } else { expect(false, "native privacy fixture has a visible window") }
        let os = ProcessInfo.processInfo.operatingSystemVersion
        for bundle in [nil, "dev.profiledesk.profileDesk", "dev.profiledesk.profileDesk.qa"] as [String?] {
            expect(WorkspaceBrowserPolicy.applicationName(bundleIdentifier: bundle, operatingSystem: os) == nil,
                   "non-development identity remains unchanged: \(bundle ?? "missing bundle")")
        }
        let compatibility = WorkspaceBrowserPolicy.applicationName(
            bundleIdentifier: "dev.profiledesk.profileDesk.development", operatingSystem: os)
        let compatibilityConfiguration = configuration()
        compatibilityConfiguration.applicationNameForUserAgent = compatibility
        let identityView = WorkspaceWebView(frame: CGRect(x: 0, y: 0, width: 980, height: 700), configuration: compatibilityConfiguration)
        host.addSubview(identityView)
        // A concrete URL lets WebKit apply the requested desktop content mode.
        // This reserved fixture origin loads only the supplied HTML, with no
        // external resources or service request.
        let identityURL = URL(string: "https://harness.profiledesk.invalid/")!
        await load(identityView, html: html(), baseURL: identityURL)
        var observedIdentity = ""
        var identityError: String?
        do {
            if let value = try await identityView.evaluateJavaScript("navigator.userAgent") as? String {
                observedIdentity = value
            } else { identityError = "navigator.userAgent returned a non-string value" }
        } catch { identityError = String(describing: error) }
        let expectedSuffix = "Version/\(os.majorVersion).\(os.minorVersion) Safari/605.1.15"
        identityMeasurement = ["baseURL": identityURL.absoluteString, "observedIdentity": observedIdentity,
            "expectedSuffix": expectedSuffix, "operatingSystemVersion": "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            "configuredApplicationName": compatibility ?? "", "hasCustomUserAgent": identityView.customUserAgent != nil,
            "customUserAgentValue": identityView.customUserAgent as Any? ?? NSNull(),
            "evaluationError": identityError as Any? ?? NSNull()]
        // The getter need not be nil when the app has not assigned a UA.
        // Validate the configured suffix and the observed navigator identity.
        expect(identityView.configuration.applicationNameForUserAgent == expectedSuffix && observedIdentity.hasPrefix("Mozilla/5.0") &&
               observedIdentity.hasSuffix(expectedSuffix),
               "development uses the configured compatibility suffix with WebKit's own desktop identity")
        identityView.stopFitting(); identityView.stopLoading(); identityView.removeFromSuperview()

        let baseline = WKWebView(frame: CGRect(x: 0, y: 0, width: 440, height: 700), configuration: configuration())
        baseline.scrollView.contentInsetAdjustmentBehavior = .never
        host.addSubview(baseline)
        await load(baseline, html: html(hidden: true))
        let before = await measure(baseline, "baseline-hidden-overflow-440")
        expect(abs(baseline.scrollView.contentSize.width - 440) < 1 && before.right > before.width + 200,
               "baseline reproduces clipped fixed child despite native contentSize matching host width")
        baseline.stopLoading(); baseline.removeFromSuperview()

        let viewportHost = SessionHostView(frame: CGRect(x: 0, y: 0, width: 440, height: 700))
        host.addSubview(viewportHost)
        viewportHost.covered = false
        expect(viewportHost.clipsToBounds, "host clips transformed or pinched content to the privacy-cover area")
        var web: WorkspaceWebView? = WorkspaceWebView(frame: .zero, configuration: configuration())
        viewportHost.attach(web!)
        viewportHost.layoutIfNeeded()
        expect(web!.bounds.width == 980 && abs(web!.transform.a - 440.0 / 980.0) < 0.001,
               "real desktop viewport is fitted before initial navigation")
        expect(web!.configuration.ignoresViewportScaleLimits, "site scale restrictions do not disable native pinch")
        expect(web!.scrollView.contentInsetAdjustmentBehavior == .never, "Flutter safe area is not applied a second time")
        await load(web!, html: html(hidden: true))
        let after = await measure(web!, "fitted-hidden-overflow-440")
        expect(after.width > 0 && after.right <= after.width + 1, "hidden fixed child fits phone without page inspection in production")
        expect(abs(web!.scrollView.contentSize.width * web!.transform.a - 440) < 1, "fitted phone content fills the host width")
        let target = CGPoint(x: 430, y: 100)
        let nativePoint = web!.convert(target, from: viewportHost)
        expect(abs(nativePoint.x - target.x / web!.transform.a) < 0.01,
               "UIKit converts touch coordinates into the desktop viewport")
        let hit = viewportHost.hitTest(target, with: nil)
        expect(hit === web || hit?.isDescendant(of: web!) == true,
               "right-edge native hit testing reaches transformed web view")

        for width: CGFloat in [880, 1366, 320, 440] {
            viewportHost.frame.size.width = width
            viewportHost.setNeedsLayout(); viewportHost.layoutIfNeeded()
            web!.setNeedsLayout(); web!.layoutIfNeeded()
            let geometry = await measure(web!, "fitted-width-\(Int(width))")
            expect(web!.pageZoom == 1 && abs(web!.bounds.width * web!.transform.a - width) < 0.01,
                   "native desktop viewport fits actual available width \(Int(width))")
            expect(geometry.width > 0 && geometry.right <= geometry.width + 1, "fixed child fits rotation/tablet/split width \(Int(width))")
        }
        let stableZoom = web!.pageZoom
        let stableFit = web!.transform
        for _ in 0..<40 { viewportHost.setNeedsLayout(); viewportHost.layoutIfNeeded(); web!.setNeedsLayout(); web!.layoutIfNeeded() }
        await pause()
        expect(web!.pageZoom == stableZoom && web!.transform == stableFit, "repeated native layouts do not recursively shrink the view")
        expect(web!.scrollView.maximumZoomScale > web!.scrollView.minimumZoomScale,
               "native zoom range remains available on user-scalable=no fixture")
        let requested = min(web!.scrollView.maximumZoomScale, web!.scrollView.minimumZoomScale * 2)
        web!.scrollView.setZoomScale(requested, animated: false)
        await pause()
        let userScale = web!.scrollView.zoomScale
        expect(userScale > web!.scrollView.minimumZoomScale, "programmatic native zoom actually increases scale")
        viewportHost.frame.size.height = 350
        viewportHost.setNeedsLayout(); viewportHost.layoutIfNeeded()
        expect(web!.pageZoom == stableZoom && abs(web!.scrollView.zoomScale - userScale) < 0.01,
               "host fitter does not synchronously overwrite native zoom on height-only resize")
        web!.setNeedsLayout(); web!.layoutIfNeeded()
        await pause()
        expect(web!.transform == stableFit && abs(web!.bounds.height * web!.transform.a - 350) < 0.01,
               "height-only resize fits new keyboard-sized host without changing width scale")
        _ = await measure(web!, "height-resize-after-programmatic-zoom-WebKit-may-reset")
        web!.scrollView.setZoomScale(web!.scrollView.minimumZoomScale, animated: false)
        await load(web!, html: html(responsive: true))
        let responsive = await measure(web!, "responsive-with-desktop-viewport")
        expect(responsive.width > 0 && abs(responsive.right - responsive.width) <= 1,
               "responsive document fills the explicit desktop viewport without overflow")
        viewportHost.covered = true
        viewportHost.setNeedsLayout(); viewportHost.layoutIfNeeded()
        let cover = viewportHost.subviews.last!
        expect(cover.frame == viewportHost.bounds && cover.transform == .identity,
               "privacy cover stays untransformed and fills physical host bounds")
        expect(viewportHost.hitTest(CGPoint(x: 430, y: 100), with: nil) === cover,
               "privacy cover intercepts input across transformed workspace")
        web!.stopFitting()
        let stoppedBounds = web!.bounds
        viewportHost.frame.size.width = 600
        viewportHost.setNeedsLayout(); viewportHost.layoutIfNeeded()
        web!.setNeedsLayout(); web!.layoutIfNeeded()
        expect(web!.bounds == stoppedBounds, "disposed fitting ignores later geometry changes")
        weak var releasedView: WorkspaceWebView?
        releasedView = web
        web!.navigationDelegate = nil; web!.stopLoading(); web!.removeFromSuperview(); web = nil
        await pause()
        expect(releasedView == nil, "fitting retains no observer/task that leaks disposed web view")

        await phoneLayout(in: host)

        let value: [String: Any] = ["result": tests.allSatisfy { $0["pass"] as? Bool == true } ? "PASS" : "FAIL",
            "count": tests.count, "tests": tests, "measurements": measurements, "identityMeasurement": identityMeasurement, "os": UIDevice.current.systemVersion,
            "scope": "Actual production WorkspaceWebView and SessionHostView with controlled local HTML and test-only DOM geometry. No service account, actual touch pinch, physical keyboard or device rotation.",
            "limits": "WebKit resets programmatic zoom after processing a height resize in this fixture. The synchronous fitter does not write zoom; actual pinch plus keyboard behavior remains a physical-device check."]
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("result.json")
        try! JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Viewport regression", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var started = false
    private let checks = Checks()
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene); window.rootViewController = UIViewController(); window.makeKeyAndVisible(); self.window = window
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !started, let host = window?.rootViewController?.view else { return }; started = true
        Task { @MainActor in await checks.run(in: host) }
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
