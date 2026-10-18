// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "ProfileDeskNative",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "ProfileRegistry", targets: ["ProfileRegistry"])],
    targets: [
        .target(name: "ProfileRegistry", linkerSettings: [.linkedLibrary("sqlite3")]),
        .testTarget(name: "ProfileRegistryTests", dependencies: ["ProfileRegistry"])
    ]
)
