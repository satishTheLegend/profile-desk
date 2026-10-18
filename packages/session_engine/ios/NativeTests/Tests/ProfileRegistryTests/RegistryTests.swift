import XCTest
import SQLite3
@testable import ProfileRegistry

final class RegistryTests: XCTestCase {
    var directory: URL!
    var registry: ProfileRegistry!
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        registry = try ProfileRegistry(url: directory.appendingPathComponent("registry.sqlite3"))
    }
    override func tearDownWithError() throws { registry = nil; try FileManager.default.removeItem(at: directory) }

    private func corruptFixture(_ sql: String) throws {
        var database: OpaquePointer?
        XCTAssertEqual(sqlite3_open(directory.appendingPathComponent("registry.sqlite3").path, &database), SQLITE_OK)
        defer { sqlite3_close(database) }
        XCTAssertEqual(sqlite3_exec(database, sql, nil, nil, nil), SQLITE_OK)
    }
    func testMalformedNumericProfileRowFailsClosed() throws {
        _ = try registry.reserve(alias: "Fixture", color: 1)
        try corruptFixture("UPDATE profiles SET color='malformed'")
        XCTAssertThrowsError(try registry.list()) { error in XCTAssertEqual((error as? SessionFailure)?.code, "storage") }
    }
    func testMalformedCleanupIdentityFailsBeforeStoreAccess() throws {
        let item = try registry.reserve(alias: "Fixture", color: 1)
        _ = try registry.requestRemoval(item.id)
        try corruptFixture("UPDATE cleanup SET profile_id='../default'")
        XCTAssertThrowsError(try registry.cleanups()) { error in XCTAssertEqual((error as? SessionFailure)?.code, "storage") }
    }
    func testCleanupCannotRetargetAvailableProfile() throws {
        let removed = try registry.reserve(alias: "Removing", color: 1)
        let retained = try registry.reserve(alias: "Retained", color: 1)
        try registry.setLifecycle(retained.id, "available")
        _ = try registry.requestRemoval(removed.id)
        try corruptFixture("UPDATE cleanup SET profile_id='\(retained.id)'")
        XCTAssertThrowsError(try registry.cleanups()) { error in XCTAssertEqual((error as? SessionFailure)?.code, "storage") }
        XCTAssertEqual(try registry.profile(retained.id).lifecycle, "available")
    }

    func testCapacityIncludesReservationsAndPendingCleanup() throws {
        for number in 0..<10 { _ = try registry.reserve(alias: "Account \(number)", color: 0) }
        XCTAssertThrowsError(try registry.reserve(alias: "Eleventh", color: 0))
        let first = try registry.list()[0]
        _ = try registry.requestRemoval(first.id)
        XCTAssertThrowsError(try registry.reserve(alias: "Still full", color: 0))
        try registry.cleanupStage(first.id, "complete")
        let replacement = try registry.reserve(alias: first.alias, color: 0)
        XCTAssertNotEqual(first.id, replacement.id)
        XCTAssertEqual(try registry.list().count, 10)
    }
    func testNormalizationAndRenameKeepBackingIdentity() throws {
        let account = try registry.reserve(alias: "  Wörk  ", color: 7)
        XCTAssertEqual(account.alias,"Wörk")
        XCTAssertThrowsError(try registry.reserve(alias: "WÖRK", color: 0))
        try registry.setLifecycle(account.id, "available")
        try registry.rename(account.id, alias: "Personal", color: 8)
        XCTAssertEqual(try registry.profile(account.id).id,account.id)
        XCTAssertEqual(try registry.profile(account.id).alias,"Personal")
        XCTAssertThrowsError(try registry.reserve(alias: "\n", color: 0))
        XCTAssertThrowsError(try registry.reserve(alias: String(repeating:"a",count:41), color:0))
        XCTAssertThrowsError(try registry.reserve(alias: "hidden\u{0001}", color:0))
    }
    func testOrderRejectsDuplicatesWithoutPartialMutation() throws {
        let a = try registry.reserve(alias:"A",color:0)
        let b = try registry.reserve(alias:"B",color:0)
        XCTAssertThrowsError(try registry.reorder([b.id,b.id]))
        XCTAssertEqual(try registry.list().map(\.id),[a.id,b.id])
        try registry.reorder([b.id,a.id])
        XCTAssertEqual(try registry.list().map(\.id),[b.id,a.id])
    }
    func testTombstoneAndJournalSurviveRestartAndAreIdempotent() throws {
        let a = try registry.reserve(alias:"A",color:0)
        let b = try registry.reserve(alias:"B",color:0)
        try registry.setLifecycle(a.id,"available")
        try registry.setLifecycle(b.id,"available")
        let cleanup = try registry.requestRemoval(a.id, operationId:"operation-one")
        XCTAssertEqual(try registry.requestRemoval(a.id,operationId:"operation-two").operationId,cleanup.operationId)
        try registry.cleanupStage(a.id,"containerDeletionPending",error:"cleanupFailed")
        registry = nil
        registry = try ProfileRegistry(url:directory.appendingPathComponent("registry.sqlite3"))
        XCTAssertEqual(try registry.cleanups().first?.operationId,"operation-one")
        XCTAssertEqual(try registry.cleanups().first?.attempts,1)
        try registry.reconcile(inventory:[a.id,b.id])
        XCTAssertEqual(try registry.profile(a.id).lifecycle,"cleanupPending")
        XCTAssertEqual(try registry.profile(b.id).lifecycle,"available")
        try registry.cleanupStage(a.id,"complete")
        XCTAssertEqual(try registry.requestRemoval(a.id).stage,"complete")
    }
    func testMissingAndUnknownStoresNeverBecomeAuthenticatedProfiles() throws {
        let existing = try registry.reserve(alias:"Existing",color:0)
        let reservation = try registry.reserve(alias:"Interrupted",color:0)
        try registry.setLifecycle(existing.id,"available")
        let orphan = UUID().uuidString.lowercased()
        try registry.reconcile(inventory:[orphan])
        XCTAssertEqual(try registry.profile(existing.id).lifecycle,"missing")
        XCTAssertEqual(try registry.profile(reservation.id).lifecycle,"quarantined")
        XCTAssertEqual(try registry.quarantinedCount(),1)
        XCTAssertFalse(try registry.list().contains { $0.id == orphan })
        XCTAssertThrowsError(try registry.observe(existing.id,value:"userConfirmed"))
    }
    func testReorderExcludesCleanupRows() throws {
        let a = try registry.reserve(alias:"A",color:0)
        let b = try registry.reserve(alias:"B",color:0)
        _ = try registry.requestRemoval(a.id)
        try registry.reorder([b.id])
        XCTAssertEqual(try registry.profile(b.id).order,0)
        XCTAssertEqual(try registry.profile(a.id).lifecycle,"removing")
    }
    func testVersionOneReopenPreservesPreferencesAndObservation() throws {
        let a = try registry.reserve(alias:"A",color:1)
        try registry.setLifecycle(a.id,"available")
        try registry.observe(a.id,value:"userConfirmed")
        try registry.setPreference("lockEnabled","true")
        registry = nil
        registry = try ProfileRegistry(url:directory.appendingPathComponent("registry.sqlite3"))
        XCTAssertEqual(try registry.preference("lockEnabled",fallback:"false"),"true")
        XCTAssertEqual(try registry.profile(a.id).observation,"userConfirmed")
        XCTAssertEqual(try registry.profile(a.id).createdAt,a.createdAt)
    }
}

final class NavigationPolicyTests: XCTestCase {
    func testWorkspaceOnlyAcceptsExactSecureOrigin() {
        XCTAssertTrue(WorkspaceURLPolicy.isWorkspace(URL(string:"https://web.whatsapp.com/")!))
        XCTAssertTrue(WorkspaceURLPolicy.isWorkspace(URL(string:"https://WEB.WHATSAPP.COM:443/")!))
        for value in ["http://web.whatsapp.com", "https://web.whatsapp.com.evil.test", "https://evilweb.whatsapp.com", "https://web.whatsapp.com:8443", "https://web.whatsapp.com@evil.test", "https://user@web.whatsapp.com", "file:///web.whatsapp.com", "javascript:alert(1)"] {
            XCTAssertFalse(WorkspaceURLPolicy.isWorkspace(URL(string:value)!),value)
        }
    }
    func testOnlyExplicitExternalSchemesAreRoutable() {
        XCTAssertTrue(WorkspaceURLPolicy.isExternal(URL(string:"https://example.org")!))
        XCTAssertTrue(WorkspaceURLPolicy.isExternal(URL(string:"tel:+10000000000")!))
        XCTAssertFalse(WorkspaceURLPolicy.isExternal(URL(string:"intent://arbitrary")!))
        XCTAssertFalse(WorkspaceURLPolicy.isExternal(URL(string:"javascript:alert(1)")!))
    }
}

final class InstallationBindingTests: XCTestCase {
    var directory: URL!
    var registry: ProfileRegistry!
    let deviceA = Data(repeating:17,count:32)
    let deviceB = Data(repeating:23,count:32)
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        registry = try ProfileRegistry(url:directory.appendingPathComponent("registry.sqlite3"))
    }
    override func tearDownWithError() throws { registry = nil; try FileManager.default.removeItem(at:directory) }
    func testOrdinaryUpgradeKeepsVerifiedInstallation() throws {
        let binding = InstallationBinding(secretLoader:{ self.deviceA })
        try binding.verifyOrQuarantine(registry:registry,directory:directory)
        let a = try registry.reserve(alias:"A",color:1)
        try registry.setLifecycle(a.id,"available")
        registry = nil
        registry = try ProfileRegistry(url:directory.appendingPathComponent("registry.sqlite3"))
        try binding.verifyOrQuarantine(registry:registry,directory:directory)
        XCTAssertEqual(try registry.profile(a.id).lifecycle,"available")
    }
    func testCopiedRegistryAndAnchorCannotMigrateDeviceSecret() throws {
        try InstallationBinding(secretLoader:{ self.deviceA }).verifyOrQuarantine(registry:registry,directory:directory)
        let a = try registry.reserve(alias:"A",color:1)
        try registry.setLifecycle(a.id,"available")
        try registry.observe(a.id,value:"userConfirmed")
        _ = try registry.requestRemoval(a.id)
        try InstallationBinding(secretLoader:{ self.deviceB }).verifyOrQuarantine(registry:registry,directory:directory)
        XCTAssertEqual(try registry.profile(a.id).lifecycle,"quarantined")
        XCTAssertEqual(try registry.profile(a.id).observation,"unknown")
        XCTAssertTrue(try registry.cleanups().isEmpty)
        // A new explicit local removal is still possible after quarantine.
        XCTAssertEqual(try registry.requestRemoval(a.id).stage,"requested")
    }
    func testReinstallWithoutExcludedAnchorQuarantinesMatchingUUIDs() throws {
        let binding = InstallationBinding(secretLoader:{ self.deviceA })
        try binding.verifyOrQuarantine(registry:registry,directory:directory)
        let a = try registry.reserve(alias:"A",color:1)
        try registry.setLifecycle(a.id,"available")
        try FileManager.default.removeItem(at:directory.appendingPathComponent("installation.anchor"))
        try binding.verifyOrQuarantine(registry:registry,directory:directory)
        try registry.reconcile(inventory:[a.id])
        XCTAssertEqual(try registry.profile(a.id).lifecycle,"quarantined")
    }
    func testCompletedRemovalRedactsMetadataButKeepsMinimalIdentityTombstone() throws {
        let a = try registry.reserve(alias:"Sensitive removed alias",color:0xff123456)
        let b = try registry.reserve(alias:"Retained",color:12)
        try registry.setLifecycle(a.id,"available")
        try registry.observe(a.id,value:"userConfirmed")
        _ = try registry.requestRemoval(a.id)
        try registry.cleanupStage(a.id,"complete")
        let removed = try registry.profile(a.id)
        XCTAssertEqual(removed.id,a.id)
        XCTAssertEqual(removed.lifecycle,"removed")
        XCTAssertEqual(removed.alias,"")
        XCTAssertEqual(removed.color,0)
        XCTAssertEqual(removed.createdAt,0)
        XCTAssertEqual(removed.observation,"unknown")
        XCTAssertNil(removed.observedAt)
        XCTAssertEqual(try registry.profile(b.id).alias,"Retained")
    }
}

final class NativeLockStateTests: XCTestCase {
    func testLateSuccessCannotUndoNewerManualLock() {
        var state = NativeLockState(locked:true)
        let ticket = state.beginAuthentication()
        state.lock()
        XCTAssertFalse(state.finishAuthentication(ticket,success:true,foreground:true))
        XCTAssertTrue(state.locked)
    }
    func testLateFailureFromUnlockedSetupCannotUndoNewerBackgroundLock() {
        var state = NativeLockState(locked:false)
        let ticket = state.beginAuthentication()
        state.lock()
        XCTAssertFalse(state.finishAuthentication(ticket,success:false,foreground:true))
        XCTAssertTrue(state.locked)
    }
    func testOnlyCurrentForegroundAuthenticationUnlocks() {
        var state = NativeLockState(locked:true)
        let ticket = state.beginAuthentication()
        XCTAssertFalse(state.finishAuthentication(ticket,success:true,foreground:false))
        XCTAssertTrue(state.locked)
        XCTAssertFalse(state.finishAuthentication(ticket,success:true,foreground:true))
        XCTAssertTrue(state.finishAuthentication(state.beginAuthentication(),success:true,foreground:true))
        XCTAssertFalse(state.locked)
    }
    func testCancelSetupDoesNotEnableLockAndInactiveInvalidatesTicket() {
        var state = NativeLockState(locked:false)
        XCTAssertFalse(state.finishAuthentication(state.beginAuthentication(),success:false,foreground:true))
        XCTAssertFalse(state.locked)
        let ticket = state.beginAuthentication()
        state.invalidateAuthentication()
        XCTAssertFalse(state.finishAuthentication(ticket,success:true,foreground:true))
    }
}
