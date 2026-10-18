import XCTest
@testable import ProfileRegistry

final class DiagnosticsTests: XCTestCase {
    func testSeededMetadataNeverAppearsInActualExportPayload() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let registry = try ProfileRegistry(url: directory.appendingPathComponent("registry.sqlite3"))
        let markers = ["cookie-secret-marker", "token-secret-marker", "pairing-secret-marker", "/private/secret-file.txt", "https://secret.invalid/path"]
        for marker in markers { _ = try registry.reserve(alias: marker, color: 1) }
        let profiles = try registry.list()
        let payload = NativeDiagnostics.render(osVersion: "27.0", profiles: profiles, pendingCleanupCount: 0, quarantinedStoreCount: 0)
        for marker in markers { XCTAssertFalse(payload.contains(marker)) }
        for profile in profiles { XCTAssertFalse(payload.contains(profile.id)) }
        XCTAssertTrue(payload.contains("Profile count: 5"))
        XCTAssertFalse(payload.contains(directory.path))
    }
    func testVersionFieldCannotAddUnallowlistedExportLines() {
        let payload = NativeDiagnostics.render(osVersion: "27.0\nsecret-token", profiles: [], pendingCleanupCount: 0, quarantinedStoreCount: 0)
        XCTAssertTrue(payload.contains("OS: unknown"))
        XCTAssertFalse(payload.contains("secret-token"))
    }
}
