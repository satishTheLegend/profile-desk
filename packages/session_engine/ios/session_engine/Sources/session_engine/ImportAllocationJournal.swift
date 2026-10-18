import Foundation
import Darwin

/// Only fresh IDs reserved by an explicit setup import enter this excluded file.
/// It outlives a rolled-back SQLite transaction, permitting narrowly scoped
/// cleanup after a crash between native store creation and metadata commit.
final class ImportAllocationJournal {
    private let url: URL
    private let nonce: String
    init(directory: URL, bindingNonce: String) {
        url = directory.appendingPathComponent("import-allocation.json")
        nonce = bindingNonce
    }

    func pending() throws -> [String] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true, let size = values.fileSize, size <= 4096 else { throw SessionFailure.storage }
        let data = try Data(contentsOf: url)
        guard data.count <= 4096,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(object.keys) == ["version", "bindingNonce", "identifiers"],
              object["version"] as? Int == 1,
              let binding = object["bindingNonce"] as? String,
              let ids = object["identifiers"] as? [String], ids.count <= 10,
              Set(ids).count == ids.count,
              ids.allSatisfy({ UUID(uuidString: $0)?.uuidString.lowercased() == $0 })
        else { throw SessionFailure.storage }
        guard !nonce.isEmpty, binding == nonce else {
            // A restored journal is never deletion authority for this install.
            try clear()
            return []
        }
        return ids
    }

    func record(_ identifiers: [String]) throws {
        guard !nonce.isEmpty, !identifiers.isEmpty, identifiers.count <= 10,
              Set(identifiers).count == identifiers.count,
              identifiers.allSatisfy({ UUID(uuidString: $0)?.uuidString.lowercased() == $0 }),
              try pending().isEmpty else { throw SessionFailure.archiveRecoveryRequired }
        try write(identifiers)
    }

    func completed(_ identifier: String) throws {
        let remaining = try pending().filter { $0 != identifier }
        if remaining.isEmpty { try clear() } else { try write(remaining) }
    }

    func unassigned(knownIdentifiers: Set<String>) throws -> [String] {
        let identifiers = try pending()
        for id in identifiers where knownIdentifiers.contains(id) { try completed(id) }
        return identifiers.filter { !knownIdentifiers.contains($0) }
    }

    private func write(_ identifiers: [String]) throws {
        let data = try JSONSerialization.data(withJSONObject: ["version": 1, "bindingNonce": nonce, "identifiers": identifiers], options: [.sortedKeys])
        try data.write(to: url, options: .atomic)
        var excluded = url
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try excluded.setResourceValues(values)
        #if os(iOS)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.path)
        #endif
        let file = try FileHandle(forWritingTo: url)
        defer { try? file.close() }
        try file.synchronize()
        try syncDirectory()
    }

    private func clear() throws {
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url); try syncDirectory() }
    }

    private func syncDirectory() throws {
        let descriptor = open(url.deletingLastPathComponent().path, O_RDONLY)
        guard descriptor >= 0 else { throw SessionFailure.storage }
        defer { close(descriptor) }
        guard fsync(descriptor) == 0 else { throw SessionFailure.storage }
    }
}
