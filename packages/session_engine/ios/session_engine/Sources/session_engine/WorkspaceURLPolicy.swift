import Foundation

/// Canonical exact-host policy. CDN/iframe resources are not granted native privileges.
enum WorkspaceURLPolicy {
    static func isWorkspace(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host?.lowercased() == "web.whatsapp.com" && (url.port == nil || url.port == 443) && url.user == nil && url.password == nil
    }
    static func isExternal(_ url: URL) -> Bool { ["http", "https", "tel", "mailto"].contains(url.scheme?.lowercased() ?? "") }
}
