import XCTest
@testable import ProfileRegistry

final class AccountSetupArchiveTests: XCTestCase {
    private func encoded(_ accounts: [[String: Any]] = [["alias": "Personal", "color": 4_280_371_038]],
                         extra: [String: Any] = [:]) throws -> String {
        var object: [String: Any] = ["format": AccountSetupArchive.format, "version": 1,
            "requiresRelinking": true, "accounts": accounts, "appearance": ["theme": "dark"]]
        object.merge(extra) { _, new in new }
        return String(data: try JSONSerialization.data(withJSONObject: object), encoding: .utf8)!
    }

    func testZeroOneAndTenRoundtripWithoutIdentityOrSessionFields() throws {
        for count in [0, 1, 10] {
            let value = try AccountSetupArchive.decode(encoded((0..<count).map { ["alias": "Account \($0)", "color": UInt32.max] }))
            XCTAssertEqual(value.accounts.count, count)
            XCTAssertEqual(try AccountSetupArchive.decode(value.encoded()), value)
            let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(value.encoded().utf8)) as? [String: Any])
            XCTAssertEqual(Set(object.keys), ["format", "version", "requiresRelinking", "accounts", "appearance"])
        }
    }

    func testRejectsExcludedKeysTypesAndUnsupportedVersions() throws {
        for extras: [String: Any] in [["cookies": "secret"], ["version": 2], ["version": true],
                                     ["requiresRelinking": false], ["requiresRelinking": 1],
                                     ["appearance": ["theme": "dark", "lockEnabled": false]],
                                     ["appearance": ["theme": "other"]]] {
            XCTAssertThrowsError(try AccountSetupArchive.decode(encoded(extra: extras)))
        }
        for entry: [String: Any] in [["alias": "A", "color": true], ["alias": "A", "color": -1],
                                    ["alias": "A", "color": UInt64(UInt32.max) + 1],
                                    ["alias": "A", "color": 1.5], ["alias": "A", "color": 1, "id": "old-store"],
                                    ["alias": String(repeating: "a", count: 41), "color": 1],
                                    ["alias": "a\u{001F}b", "color": 1], ["alias": "   ", "color": 1]] {
            XCTAssertThrowsError(try AccountSetupArchive.decode(encoded([entry])))
        }
        XCTAssertThrowsError(try AccountSetupArchive.decode(encoded((0..<11).map { ["alias": "A\($0)", "color": 1] })))
        XCTAssertThrowsError(try AccountSetupArchive.decode(encoded([["alias": "Work", "color": 1], ["alias": " work ", "color": 2]])))
        XCTAssertThrowsError(try AccountSetupArchive.decode(encoded([["alias": "café", "color": 1], ["alias": "cafe\u{0301}", "color": 2]])))
        XCTAssertThrowsError(try AccountSetupArchive.decode(String(repeating: " ", count: AccountSetupArchive.maximumBytes + 1)))
        XCTAssertThrowsError(try AccountSetupArchive.decode(String(repeating: "[", count: 20_000) + String(repeating: "]", count: 20_000)))
        let duplicate = try encoded().replacingOccurrences(of: "\"version\":1", with: "\"version\":1,\"version\":1")
        XCTAssertThrowsError(try AccountSetupArchive.decode(duplicate))
        let escapedDuplicate = try encoded().replacingOccurrences(of: "\"version\":1", with: "\"version\":1,\"\\u0076ersion\":1")
        XCTAssertThrowsError(try AccountSetupArchive.decode(escapedDuplicate))
        XCTAssertEqual(try AccountSetupArchive.decode(encoded([["alias": "{[ \"Quoted\" ]}", "color": 1]])).accounts.first?.alias, "{[ \"Quoted\" ]}")
    }

    func testPickerReaderIsBoundedAndRejectsInvalidUTF8() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("archive.json")
        let text = try encoded()
        try Data(text.utf8).write(to: file)
        XCTAssertEqual(try AccountSetupArchive.decode(AccountSetupArchive.read(file)), try AccountSetupArchive.decode(text))
        try Data([0xff, 0xfe, 0xff]).write(to: file)
        XCTAssertThrowsError(try AccountSetupArchive.read(file))
        try Data(repeating: 32, count: AccountSetupArchive.maximumBytes + 1).write(to: file)
        XCTAssertThrowsError(try AccountSetupArchive.read(file))
        XCTAssertThrowsError(try AccountSetupArchive.read(directory))
    }
}

final class AccountSetupImportTests: XCTestCase {
    private var root: URL!
    private var registry: ProfileRegistry!
    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        registry = try ProfileRegistry(url: root.appendingPathComponent("registry.sqlite3"))
    }
    override func tearDownWithError() throws { registry = nil; try FileManager.default.removeItem(at: root) }
    private func archive(_ names: [String]) -> AccountSetupArchive {
        AccountSetupArchive(accounts: names.map { .init(alias: $0, color: 4_280_371_038) }, theme: "dark")
    }

    func testFreshAppendResetsAuthenticationAndPreservesDestinationSecurity() throws {
        let retained = try registry.reserve(alias: "Existing", color: 1)
        try registry.setLifecycle(retained.id, "available")
        try registry.observe(retained.id, value: "userConfirmed")
        try registry.setPreference("lockEnabled", "true")
        try registry.setPreference("theme", "light")
        var allocated = [String]()
        let imported = try registry.importSetup(archive(["First", "Second"]), applyAppearance: false) { allocated.append($0) }
        XCTAssertEqual(imported.map(\.id), allocated)
        XCTAssertEqual(Set(allocated).count, 2)
        XCTAssertFalse(allocated.contains(retained.id))
        XCTAssertTrue(imported.allSatisfy { $0.observation == "unknown" && $0.lastOpenedAt == nil && $0.lifecycle == "available" })
        XCTAssertEqual(try registry.profile(retained.id).observation, "userConfirmed")
        XCTAssertEqual(try registry.preference("lockEnabled", fallback: "false"), "true")
        XCTAssertEqual(try registry.preference("theme", fallback: "system"), "light")
        XCTAssertEqual(try registry.list().map(\.alias), ["Existing", "First", "Second"])
        XCTAssertThrowsError(try registry.importSetup(archive(["First", "Second"]), applyAppearance: false) { _ in XCTFail("Repeated import must not allocate") })
    }

    func testBatchPreflightAndFailureCannotPartiallyMutateDestination() throws {
        let retained = try registry.reserve(alias: "Existing", color: 1)
        try registry.setLifecycle(retained.id, "available")
        try registry.setPreference("theme", "light")
        XCTAssertThrowsError(try registry.importSetup(archive(["New", "existing"]), applyAppearance: true) { _ in XCTFail("Conflict must precede allocation") })
        XCTAssertEqual(try registry.list().count, 1)
        var attempts = [String]()
        XCTAssertThrowsError(try registry.importSetup(archive(["First", "Second"]), applyAppearance: true) { id in
            attempts.append(id)
            if attempts.count == 2 { throw SessionFailure.storage }
        })
        XCTAssertEqual(try registry.list().map(\.id), [retained.id])
        XCTAssertEqual(try registry.preference("theme", fallback: "system"), "light")
        XCTAssertEqual(try registry.quarantinedCount(), 2)
        // Simulate startup inventory after a transaction rolled back on failure.
        try registry.reconcile(inventory: Set(attempts + [retained.id]))
        XCTAssertEqual(try registry.list().map(\.id), [retained.id])
        XCTAssertEqual(try registry.profile(retained.id).lifecycle, "available")
    }

    func testCapacityIsRecheckedBeforeProvisioningAndAppearanceIsOptIn() throws {
        for index in 0..<9 { _ = try registry.reserve(alias: "Existing \(index)", color: 1) }
        XCTAssertThrowsError(try registry.importSetup(archive(["Tenth", "Eleventh"]), applyAppearance: false) { _ in XCTFail("Capacity must precede allocation") })
        XCTAssertEqual(try registry.list().count, 9)
        let imported = try registry.importSetup(archive(["Tenth"]), applyAppearance: true) { _ in }
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(try registry.list().count, 10)
        XCTAssertEqual(try registry.preference("theme", fallback: "system"), "dark")
    }

    func testExportOmitsRemovalAndTrustState() throws {
        let retained = try registry.reserve(alias: "Retained", color: 1)
        try registry.setLifecycle(retained.id, "available")
        try registry.observe(retained.id, value: "userConfirmed")
        let removed = try registry.reserve(alias: "Removing", color: 2)
        _ = try registry.requestRemoval(removed.id)
        let text = try registry.exportSetup().encoded()
        XCTAssertEqual(try AccountSetupArchive.decode(text).accounts.map(\.alias), ["Retained"])
        XCTAssertFalse(text.contains(retained.id))
        XCTAssertFalse(text.contains("userConfirmed"))
        XCTAssertFalse(text.contains("lockEnabled"))
    }

    func testProvisioningJournalSurvivesRollbackAndNeverReclaimsCommittedIDs() throws {
        let retained = try registry.reserve(alias: "Existing", color: 1)
        try registry.setLifecycle(retained.id, "available")
        let journal = ImportAllocationJournal(directory: root, bindingNonce: "fixture-installation")
        var attempted = [String]()
        XCTAssertThrowsError(try registry.importSetup(archive(["First", "Second"]), applyAppearance: false, prepareStores: journal.record) { id in
            XCTAssertTrue(try journal.pending().contains(id), "Journal must reach disk before provider allocation")
            attempted.append(id)
            if attempted.count == 2 { throw SessionFailure.storage }
        })
        let reopened = ImportAllocationJournal(directory: root, bindingNonce: "fixture-installation")
        XCTAssertEqual(try reopened.pending(), attempted)
        XCTAssertEqual(try reopened.unassigned(knownIdentifiers: Set(registry.list(includeRemoved: true).map(\.id))), attempted)
        XCTAssertFalse(try reopened.pending().contains(retained.id))
        for id in attempted { try reopened.completed(id) }
        let committed = try registry.importSetup(archive(["Committed"]), applyAppearance: false, prepareStores: reopened.record) { _ in }
        XCTAssertEqual(try reopened.pending(), committed.map(\.id))
        XCTAssertTrue(try reopened.unassigned(knownIdentifiers: Set(registry.list(includeRemoved: true).map(\.id))).isEmpty)
        XCTAssertTrue(try reopened.pending().isEmpty)
        XCTAssertEqual(try registry.profile(committed[0].id).lifecycle, "available")
    }

    func testRestoredOrMalformedJournalNeverAuthorizesStoreDeletion() throws {
        let first = ImportAllocationJournal(directory: root, bindingNonce: "old-installation")
        let id = UUID().uuidString.lowercased()
        try first.record([id])
        let restored = ImportAllocationJournal(directory: root, bindingNonce: "new-installation")
        XCTAssertTrue(try restored.pending().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("import-allocation.json").path))
        try Data("{\"version\":1,\"bindingNonce\":\"new-installation\",\"identifiers\":[\"../default\"]}".utf8)
            .write(to: root.appendingPathComponent("import-allocation.json"))
        XCTAssertThrowsError(try restored.pending())
        XCTAssertThrowsError(try restored.record([UUID().uuidString.lowercased()]))
        XCTAssertTrue(try registry.list().isEmpty)
    }
}
