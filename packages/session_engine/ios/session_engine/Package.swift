// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

// SwiftPM preserves resource symlinks, which would break inside a device bundle.
// Keep a regular generated resource and reject a stale copy at manifest time.
// Resolve Flutter's package symlink before locating the canonical shared source.
let packageDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().resolvingSymlinksInPath()
let canonicalLayout = packageDirectory.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("layout/workspace_layout.js")
let packagedLayout = packageDirectory.appendingPathComponent("Sources/session_engine/workspace_layout.js")
guard let canonicalBytes = try? Data(contentsOf: canonicalLayout),
      let packagedBytes = try? Data(contentsOf: packagedLayout),
      canonicalBytes == packagedBytes,
      (try? packagedLayout.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == false else {
    fatalError("SPM layout resource is missing or stale. Run ios/NativeTests/sync-layout-resource.sh from the session_engine plugin.")
}

let package = Package(
    name: "session_engine",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .library(name: "session-engine", targets: ["session_engine"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "session_engine",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
                // Generated from the shared source; equality is enforced above.
                .copy("workspace_layout.js")
            ],
            linkerSettings: [.linkedLibrary("sqlite3")]

        )
    ]
)
