import UIKit
import WebKit

@MainActor
final class Checks {
    var measurements = [[String: Any]]()
    func pause() async { try? await Task.sleep(for: .milliseconds(1500)) }
    func measure(_ web: WKWebView, _ name: String) async {
        await pause()
        let js = "({innerWidth:innerWidth,scrollWidth:document.documentElement.scrollWidth,visualWidth:visualViewport.width,visualScale:visualViewport.scale})"
        let document = try? await web.evaluateJavaScript(js)
        measurements.append(["name": name, "width": web.bounds.width, "contentWidth": web.scrollView.contentSize.width, "zoomScale": web.scrollView.zoomScale, "pageZoom": web.pageZoom, "document": document ?? "unavailable"])
    }
    func run(in host: UIView) async {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.defaultWebpagePreferences.preferredContentMode = .desktop
        config.ignoresViewportScaleLimits = true
        let web = WKWebView(frame: CGRect(x: 0, y: 0, width: 440, height: 700), configuration: config)
        host.addSubview(web)
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.loadHTMLString("<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no'><style>body{margin:0}main{width:1000px;height:300px;background:linear-gradient(90deg,red,blue)}</style><main>Fixed width fixture</main>", baseURL: nil)
        for _ in 0..<50 {
            if !web.isLoading && web.scrollView.contentSize.width > 0 { break }
            try? await Task.sleep(for: .milliseconds(200))
        }
        await measure(web, "baseline-fixed-440")
        web.pageZoom = 0.44
        await measure(web, "manual-pageZoom-0.44")
        web.frame.size.width = 880
        await measure(web, "rotated-880-same-pageZoom")
        web.pageZoom = 0.88
        await measure(web, "manual-pageZoom-0.88")
        let value: [String: Any] = ["result": "PASS", "measurements": measurements, "os": UIDevice.current.systemVersion, "scope": "Controlled local HTML only; geometry and test-only DOM measurements."]
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
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene); window.rootViewController = UIViewController(); window.makeKeyAndVisible(); self.window = window
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !started, let host = window?.rootViewController?.view else { return }; started = true
        Task { @MainActor in await Checks().run(in: host) }
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
