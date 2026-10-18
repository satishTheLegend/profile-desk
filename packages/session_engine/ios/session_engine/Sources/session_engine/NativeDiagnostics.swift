import Foundation

/// Explicitly allowlisted export. Profile metadata is used only for aggregate count.
enum NativeDiagnostics {
    static func render(osVersion: String, profiles: [StoredProfile], pendingCleanupCount: Int, quarantinedStoreCount: Int) -> String {
        let allowedVersion = !osVersion.isEmpty && osVersion.count <= 32 && osVersion.unicodeScalars.allSatisfy {
            CharacterSet(charactersIn: "0123456789.").contains($0)
        }
        let version = allowedVersion ? osVersion : "unknown"
        return "Profile Desk diagnostics\nPlatform: iOS\nOS: \(version)\nProvider: System WebKit\nNamed profiles: supported\nScoped removal: supported\nCapture: disabled\nProfile count: \(profiles.count)\nPending cleanup count: \(max(0, pendingCleanupCount))\nQuarantined stores: \(max(0, quarantinedStoreCount))\n"
    }
}
