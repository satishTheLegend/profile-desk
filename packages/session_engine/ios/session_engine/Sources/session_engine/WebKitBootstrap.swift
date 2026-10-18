import WebKit

@MainActor
enum WebKitBootstrap {
    /// System WebKit can crash when static inventory is the first WebKit operation.
    /// A blank ephemeral view initializes its run loop without opening any profile.
    /// It is released before cleanup or construction of the one account view.
    static func initialize() {
        precondition(Thread.isMainThread)
        autoreleasepool {
            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .nonPersistent()
            let view = WKWebView(frame: .zero, configuration: configuration)
            view.stopLoading()
        }
    }
}
