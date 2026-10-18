import Foundation

/// The user approved Safari-compatible identification for the on-device
/// development trial. Keep the original browser identity in QA/production until
/// the service compatibility and release decision are separately verified.
enum WorkspaceBrowserPolicy {
    static func applicationName(
        bundleIdentifier: String?,
        operatingSystem: OperatingSystemVersion
    ) -> String? {
        guard bundleIdentifier == "dev.profiledesk.profileDesk.development" else { return nil }
        // WebKit supplies the rest of its own desktop UA. The standard Safari
        // suffix clears the service's version warning; adding a custom app token
        // was rejected in the physical-device comparison. This identifier is a
        // compatibility policy, not a claim that WKWebView is the Safari app.
        return "Version/\(operatingSystem.majorVersion).\(operatingSystem.minorVersion) Safari/605.1.15"
    }
}
