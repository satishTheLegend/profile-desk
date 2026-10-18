import Foundation
import SQLite3

enum SessionFailure: Error {
    case invalidAlias, duplicateAlias, capacity, missingProfile, unavailable, blocked, staleOperation, busy
    case storage, authentication, invalidOrder, invalidPreference, invalidArchive, archiveTooLarge, archiveUnavailable, archiveRecoveryRequired

    var code: String { String(describing: self) }
}

struct StoredProfile {
    let id: String
    let alias: String
    let color: Int64
    let order: Int64
    let createdAt: Int64
    let lastOpenedAt: Int64?
    let lifecycle: String
    let observation: String
    let observedAt: Int64?
}

struct StoredCleanup {
    let profileId: String
    let operationId: String
    let stage: String
    let attempts: Int64
}

/// The one durable authority for allocation, metadata and cleanup; callers run on the main thread.
/// No website content, URLs, credentials, or attachment names enter this database.
final class ProfileRegistry {
    private var database: OpaquePointer?
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    static var now: Int64 { Int64(Date().timeIntervalSince1970 * 1000) }

    init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open_v2(url.path, &database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else { throw SessionFailure.storage }
        do {
            try execute("PRAGMA journal_mode=WAL")
            try execute("PRAGMA foreign_keys=ON")
            try execute("PRAGMA synchronous=FULL")
            try migrate()
            var directory = url.deletingLastPathComponent()
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try directory.setResourceValues(values)
            #if os(iOS)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: directory.path)
            #endif
        } catch { sqlite3_close(database); database = nil; throw error }
    }

    deinit { sqlite3_close(database) }

    private func migrate() throws {
        let version = try rows("PRAGMA user_version").first?.first ?? "0"
        guard version == "0" || version == "1" else { throw SessionFailure.storage }
        if version == "1" { return }
        try transaction {
            try execute("CREATE TABLE profiles (id TEXT PRIMARY KEY, alias TEXT NOT NULL, normalized_alias TEXT NOT NULL, color INTEGER NOT NULL, order_index INTEGER NOT NULL, created_at INTEGER NOT NULL, last_opened_at INTEGER, lifecycle TEXT NOT NULL, observation TEXT NOT NULL DEFAULT 'unknown', observed_at INTEGER)")
            try execute("CREATE UNIQUE INDEX live_alias ON profiles(normalized_alias) WHERE lifecycle != 'removed'")
            try execute("CREATE TABLE cleanup (profile_id TEXT PRIMARY KEY REFERENCES profiles(id), operation_id TEXT NOT NULL UNIQUE, stage TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, error_class TEXT, updated_at INTEGER NOT NULL)")
            try execute("CREATE TABLE preferences (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
            try execute("CREATE TABLE quarantined_stores (id TEXT PRIMARY KEY, detected_at INTEGER NOT NULL)")
            try execute("CREATE TABLE permissions (profile_id TEXT NOT NULL REFERENCES profiles(id), origin TEXT NOT NULL, capability TEXT NOT NULL, decision TEXT NOT NULL, updated_at INTEGER NOT NULL, PRIMARY KEY(profile_id,origin,capability))")
            try execute("CREATE TABLE migrations (version INTEGER PRIMARY KEY, applied_at INTEGER NOT NULL)")
            try execute("INSERT INTO migrations VALUES (1, ?)", [Self.now])
            try execute("PRAGMA user_version=1")
        }
    }

    static func validateAlias(_ value: String) throws -> (String, String) {
        let alias = value.trimmingCharacters(in: .whitespacesAndNewlines).precomposedStringWithCanonicalMapping
        guard !alias.isEmpty, alias.unicodeScalars.count <= 40, !alias.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { throw SessionFailure.invalidAlias }
        return (alias, alias.lowercased(with: Locale(identifier: "en_US_POSIX")))
    }

    func reserve(alias: String, color: Int64) throws -> StoredProfile {
        let (label, normalized) = try Self.validateAlias(alias)
        return try transaction {
            guard try rows("SELECT id FROM profiles WHERE lifecycle != 'removed'").count < 10 else { throw SessionFailure.capacity }
            guard try rows("SELECT id FROM profiles WHERE normalized_alias=? AND lifecycle != 'removed'", [normalized]).isEmpty else { throw SessionFailure.duplicateAlias }
            let id = UUID().uuidString.lowercased()
            let order = Int64(try list().count)
            try execute("INSERT INTO profiles(id, alias, normalized_alias, color, order_index, created_at, lifecycle) VALUES(?,?,?,?,?,?,'reserving')", [id, label, normalized, color, order, Self.now])
            return try profile(id)
        }
    }

    /// All metadata is committed together. Store creation is an external side
    /// effect: a failed transaction leaves only quarantined empty orphan stores,
    /// never partially imported rows or altered existing profiles. A crash rolls
    /// back SQLite; normal startup inventory quarantines any created orphans.
    func importSetup(_ archive: AccountSetupArchive, applyAppearance: Bool,
                     prepareStores: ([String]) throws -> Void = { _ in },
                     provision: (String) throws -> Void) throws -> [StoredProfile] {
        guard !archive.accounts.isEmpty else { throw SessionFailure.invalidArchive }
        let checked = try AccountSetupArchive.decode(archive.encoded())
        var attemptedStores = [String]()
        do {
            return try transaction {
                let existing = try list()
                guard existing.count + checked.accounts.count <= 10 else { throw SessionFailure.capacity }
                let normalized = Set(try existing.map { try Self.validateAlias($0.alias).1 })
                guard try checked.accounts.allSatisfy({ !normalized.contains(try Self.validateAlias($0.alias).1) }) else { throw SessionFailure.duplicateAlias }
                let start = (existing.map(\.order).max() ?? -1) + 1
                var ids = [String]()
                for (index, entry) in checked.accounts.enumerated() {
                    let id = UUID().uuidString.lowercased()
                    let (label, key) = try Self.validateAlias(entry.alias)
                    try execute("INSERT INTO profiles(id,alias,normalized_alias,color,order_index,created_at,lifecycle,observation) VALUES(?,?,?,?,?,?,'reserving','unknown')", [id,label,key,entry.color,start + Int64(index),Self.now])
                    ids.append(id)
                }
                try prepareStores(ids)
                for id in ids {
                    attemptedStores.append(id)
                    try provision(id)
                }
                for id in ids { try setLifecycle(id, "available") }
                if applyAppearance { try setPreference("theme", checked.theme) }
                return try ids.map { try profile($0) }
            }
        } catch {
            for id in attemptedStores {
                // An allocation may fail after creating a store. Keeping its ID
                // quarantined is harmless if absent and prevents reassignment.
                try? execute("INSERT OR IGNORE INTO quarantined_stores VALUES(?,?)", [id, Self.now])
            }
            throw error
        }
    }

    func exportSetup() throws -> AccountSetupArchive {
        let entries = try list().filter { !["removing", "cleanupPending"].contains($0.lifecycle) }
        return AccountSetupArchive(accounts: entries.map { .init(alias: $0.alias, color: $0.color) },
                                   theme: try preference("theme", fallback: "system"))
    }

    func profile(_ id: String) throws -> StoredProfile {
        guard let result = try list(includeRemoved: true).first(where: { $0.id == id }) else { throw SessionFailure.missingProfile }
        return result
    }

    func list(includeRemoved: Bool = false) throws -> [StoredProfile] {
        try rows("SELECT id,alias,color,order_index,created_at,last_opened_at,lifecycle,observation,observed_at FROM profiles \(includeRemoved ? "" : "WHERE lifecycle != 'removed'") ORDER BY order_index,created_at").map { row in
            guard row.count == 9, let id = row[0], UUID(uuidString: id)?.uuidString.lowercased() == id,
                  let alias = row[1], let color = row[2].flatMap(Int64.init), let order = row[3].flatMap(Int64.init),
                  let created = row[4].flatMap(Int64.init), let lifecycle = row[6], let observation = row[7],
                  ["reserving", "available", "removing", "cleanupPending", "missing", "quarantined", "removed"].contains(lifecycle),
                  ["unknown", "userConfirmed", "relinkRequested"].contains(observation),
                  row[5] == nil || row[5].flatMap(Int64.init) != nil,
                  row[8] == nil || row[8].flatMap(Int64.init) != nil else { throw SessionFailure.storage }
            return StoredProfile(id: id, alias: alias, color: color, order: order, createdAt: created,
                                 lastOpenedAt: row[5].flatMap(Int64.init), lifecycle: lifecycle,
                                 observation: observation, observedAt: row[8].flatMap(Int64.init))
        }
    }

    func rename(_ id: String, alias: String, color: Int64) throws {
        let (label, normalized) = try Self.validateAlias(alias)
        try transaction {
            let item = try profile(id)
            guard item.lifecycle != "removed" && item.lifecycle != "removing" && item.lifecycle != "cleanupPending" else { throw SessionFailure.blocked }
            guard try rows("SELECT id FROM profiles WHERE normalized_alias=? AND id!=? AND lifecycle!='removed'", [normalized,id]).isEmpty else { throw SessionFailure.duplicateAlias }
            try execute("UPDATE profiles SET alias=?,normalized_alias=?,color=? WHERE id=?", [label, normalized,color,id])
        }
    }

    func reorder(_ ids: [String]) throws {
        try transaction {
            let existing = try list().filter { $0.lifecycle != "removing" && $0.lifecycle != "cleanupPending" }.map(\.id)
            guard Set(ids) == Set(existing), ids.count == existing.count else { throw SessionFailure.invalidOrder }
            for (index,id) in ids.enumerated() { try execute("UPDATE profiles SET order_index=? WHERE id=?", [index,id]) }
        }
    }

    func setLifecycle(_ id: String, _ state: String) throws {
        try execute("UPDATE profiles SET lifecycle=? WHERE id=?", [state,id])
    }

    func opened(_ id: String) throws { try execute("UPDATE profiles SET last_opened_at=? WHERE id=?", [Self.now,id]) }
    func observe(_ id: String, value: String) throws {
        guard try profile(id).lifecycle == "available", ["unknown", "userConfirmed", "relinkRequested"].contains(value) else { throw SessionFailure.blocked }
        try execute("UPDATE profiles SET observation=?,observed_at=? WHERE id=?", [value,Self.now,id])
    }

    func requestRemoval(_ id: String, operationId: String = UUID().uuidString.lowercased()) throws -> StoredCleanup {
        try transaction {
            _ = try profile(id)
            if let row = try rows("SELECT profile_id,operation_id,stage,attempts FROM cleanup WHERE profile_id=?", [id]).first {
                if row[2] == "restoreQuarantined" { try execute("DELETE FROM cleanup WHERE profile_id=?", [id]) }
                else { return try Self.decodeCleanup(row) }
            }
            try execute("UPDATE profiles SET lifecycle='removing' WHERE id=?", [id])
            try execute("INSERT INTO cleanup(profile_id,operation_id,stage,updated_at) VALUES(?,?,'requested',?)", [id,operationId,Self.now])
            guard let cleanup = try cleanups().first(where: { $0.profileId == id }) else { throw SessionFailure.storage }
            return cleanup
        }
    }

    func cleanups() throws -> [StoredCleanup] {
        let pending = try rows("SELECT profile_id,operation_id,stage,attempts FROM cleanup WHERE stage NOT IN ('complete','restoreQuarantined')").map(Self.decodeCleanup)
        let profiles = try list(includeRemoved: true)
        for cleanup in pending {
            guard let profile = profiles.first(where: { $0.id == cleanup.profileId }),
                  ["removing", "cleanupPending"].contains(profile.lifecycle) else { throw SessionFailure.storage }
        }
        return pending
    }

    private static func decodeCleanup(_ row: [String?]) throws -> StoredCleanup {
        guard row.count == 4, let id = row[0], UUID(uuidString: id)?.uuidString.lowercased() == id,
              let operation = row[1], !operation.isEmpty, let stage = row[2], !stage.isEmpty,
              let attempts = row[3].flatMap(Int64.init), attempts >= 0 else { throw SessionFailure.storage }
        return StoredCleanup(profileId: id, operationId: operation, stage: stage, attempts: attempts)
    }

    func cleanupStage(_ id: String, _ stage: String, error: String? = nil) throws {
        try transaction {
            try execute("UPDATE cleanup SET stage=?,error_class=?,attempts=attempts+?,updated_at=? WHERE profile_id=?", [stage,error,error == nil ? 0 : 1,Self.now,id])
            try setLifecycle(id, stage == "complete" ? "removed" : "cleanupPending")
            if stage == "complete" {
                try execute("DELETE FROM permissions WHERE profile_id=?", [id])
                try execute("UPDATE profiles SET alias='',normalized_alias='',color=0,order_index=0,created_at=0,last_opened_at=NULL,observation='unknown',observed_at=NULL WHERE id=?", [id])
            }
        }
    }

    func reconcile(inventory: Set<String>) throws {
        try transaction {
            let known = try list(includeRemoved: true)
            for profile in known where profile.lifecycle == "available" || profile.lifecycle == "reserving" {
                if inventory.contains(profile.id) { try setLifecycle(profile.id, "available") }
                else { try setLifecycle(profile.id, profile.lifecycle == "reserving" ? "quarantined" : "missing") }
            }
            for id in inventory where !known.contains(where: { $0.id == id && $0.lifecycle != "removed" }) {
                try execute("INSERT OR IGNORE INTO quarantined_stores VALUES(?,?)", [id,Self.now])
            }
        }
    }

    func preference(_ key: String, fallback: String) throws -> String { try rows("SELECT value FROM preferences WHERE key=?", [key]).first?.first.flatMap { $0 } ?? fallback }
    func setPreference(_ key: String, _ value: String) throws { try execute("INSERT INTO preferences VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value", [key,value]) }
    func quarantineUntrustedRestore() throws {
        try transaction {
            try execute("UPDATE profiles SET lifecycle='quarantined',observation='unknown',observed_at=NULL WHERE lifecycle!='removed'")
            try execute("UPDATE cleanup SET stage='restoreQuarantined',error_class='untrustedRestore',updated_at=? WHERE stage!='complete'", [Self.now])
            try execute("DELETE FROM permissions")
        }
    }
    func setInstallationBinding(nonce: String, proof: String) throws {
        try transaction { try setPreference("installationNonce",nonce); try setPreference("installationProof",proof) }
    }
    func resetPermissions(_ id: String) throws { try execute("DELETE FROM permissions WHERE profile_id=?", [id]) }
    func quarantinedCount() throws -> Int { try rows("SELECT id FROM quarantined_stores").count }
    func clearQuarantinedImportStore(_ id: String) throws {
        guard UUID(uuidString: id)?.uuidString.lowercased() == id,
              try list(includeRemoved: true).allSatisfy({ $0.id != id }) else { throw SessionFailure.blocked }
        try execute("DELETE FROM quarantined_stores WHERE id=?", [id])
    }

    private func transaction<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do { let value = try body(); try execute("COMMIT"); return value }
        catch { try? execute("ROLLBACK"); throw error }
    }

    private func statement(_ sql: String, _ arguments: [Any?]) throws -> OpaquePointer {
        var pointer: OpaquePointer?
        guard sqlite3_prepare_v2(database,sql,-1,&pointer,nil) == SQLITE_OK, let stmt = pointer else { throw SessionFailure.storage }
        for (offset,value) in arguments.enumerated() {
            let index = Int32(offset+1)
            let status: Int32
            if let string = value as? String { status = sqlite3_bind_text(stmt,index,string,-1,transient) }
            else if let integer = value as? Int64 { status = sqlite3_bind_int64(stmt,index,integer) }
            else if let integer = value as? Int { status = sqlite3_bind_int64(stmt,index,Int64(integer)) }
            else if value == nil { status = sqlite3_bind_null(stmt,index) }
            else { sqlite3_finalize(stmt); throw SessionFailure.storage }
            guard status == SQLITE_OK else { sqlite3_finalize(stmt); throw SessionFailure.storage }
        }
        return stmt
    }

    private func execute(_ sql: String, _ arguments: [Any?] = []) throws {
        let stmt = try statement(sql,arguments); defer { sqlite3_finalize(stmt) }
        let status = sqlite3_step(stmt)
        guard status == SQLITE_DONE || status == SQLITE_ROW else { throw SessionFailure.storage }
    }

    private func rows(_ sql: String, _ arguments: [Any?] = []) throws -> [[String?]] {
        let stmt = try statement(sql,arguments); defer { sqlite3_finalize(stmt) }
        var result: [[String?]] = []
        while true {
            let status = sqlite3_step(stmt)
            if status == SQLITE_DONE { return result }
            guard status == SQLITE_ROW else { throw SessionFailure.storage }
            result.append((0..<sqlite3_column_count(stmt)).map { column in
                guard let value = sqlite3_column_text(stmt,column) else { return nil }
                return String(cString:value)
            })
        }
    }
}
