import Foundation
import CoreFoundation

/// Account labels and appearance only. This format never contains browser state.
struct AccountSetupArchive: Equatable, Sendable {
    struct Account: Equatable, Sendable { let alias: String; let color: Int64 }
    static let maximumBytes = 64 * 1024
    static let format = "profile-desk-account-setup"
    let accounts: [Account]
    let theme: String

    static func decode(_ text: String) throws -> AccountSetupArchive {
        let data = Data(text.utf8)
        guard data.count <= maximumBytes else { throw SessionFailure.archiveTooLarge }
        try validateStructure(data)
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any],
              Set(root.keys) == ["format", "version", "requiresRelinking", "accounts", "appearance"],
              root["format"] as? String == format,
              integer(root["version"]) == 1,
              let relinking = root["requiresRelinking"] as? NSNumber,
              CFGetTypeID(relinking) == CFBooleanGetTypeID(), relinking.boolValue,
              let rawAccounts = root["accounts"] as? [Any], rawAccounts.count <= 10,
              let appearance = root["appearance"] as? [String: Any], Set(appearance.keys) == ["theme"],
              let theme = appearance["theme"] as? String, ["system", "light", "dark"].contains(theme)
        else { throw SessionFailure.invalidArchive }
        var names = Set<String>()
        let accounts = try rawAccounts.map { value -> Account in
            guard let entry = value as? [String: Any], Set(entry.keys) == ["alias", "color"],
                  let rawAlias = entry["alias"] as? String,
                  let color = integer(entry["color"]), color >= 0, color <= Int64(UInt32.max)
            else { throw SessionFailure.invalidArchive }
            let (alias, normalized) = try ProfileRegistry.validateAlias(rawAlias)
            guard names.insert(normalized).inserted else { throw SessionFailure.duplicateAlias }
            return Account(alias: alias, color: color)
        }
        return AccountSetupArchive(accounts: accounts, theme: theme)
    }

    private struct Scope { let object: Bool; var expectsKey: Bool; var keys = Set<String>() }
    private static func validateStructure(_ data: Data) throws {
        // Bound depth before Foundation parses, and reject duplicate keys rather
        // than allowing last-value-wins differences between platform decoders.
        // Escaped property names are decoded as strings before comparison.
        var scopes = [Scope]()
        var quoted = false, escaped = false
        var keyStart: Int?
        for (index, byte) in data.enumerated() {
            if quoted {
                if escaped { escaped = false }
                else if byte == 92 { escaped = true }
                else if byte == 34 {
                    quoted = false
                    if let start = keyStart {
                        guard !scopes.isEmpty,
                              let key = try? JSONSerialization.jsonObject(with: data.subdata(in: start..<(index + 1)), options: [.fragmentsAllowed]) as? String,
                              scopes[scopes.count - 1].keys.insert(key).inserted else { throw SessionFailure.invalidArchive }
                    }
                    keyStart = nil
                }
            } else if byte == 34 {
                quoted = true
                keyStart = scopes.last.map { $0.object && $0.expectsKey } == true ? index : nil
            } else if byte == 123 || byte == 91 {
                scopes.append(Scope(object: byte == 123, expectsKey: byte == 123))
                guard scopes.count <= 3 else { throw SessionFailure.invalidArchive }
            } else if byte == 125 || byte == 93 {
                guard let last = scopes.popLast(), last.object == (byte == 125) else { throw SessionFailure.invalidArchive }
            } else if byte == 58, !scopes.isEmpty { scopes[scopes.count - 1].expectsKey = false }
            else if byte == 44, !scopes.isEmpty { scopes[scopes.count - 1].expectsKey = scopes[scopes.count - 1].object }
        }
        guard scopes.isEmpty, !quoted else { throw SessionFailure.invalidArchive }
    }

    private static func integer(_ value: Any?) -> Int64? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
              !["f", "d"].contains(String(cString: number.objCType)) else { return nil }
        let result = number.int64Value
        return NSNumber(value: result) == number ? result : nil
    }

    func encoded() throws -> String {
        let value: [String: Any] = ["format": Self.format, "version": 1, "requiresRelinking": true,
            "accounts": accounts.map { ["alias": $0.alias, "color": $0.color] as [String: Any] },
            "appearance": ["theme": theme]]
        let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
        guard data.count <= Self.maximumBytes, let text = String(data: data, encoding: .utf8) else { throw SessionFailure.archiveTooLarge }
        // Native-generated exports satisfy the same rules as untrusted imports.
        _ = try Self.decode(text)
        return text
    }

    /// The picker grants a single URL. No path is accepted from Dart or a webpage.
    static func read(_ url: URL) throws -> String {
        guard url.isFileURL else { throw SessionFailure.invalidArchive }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var result: Result<String, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { selected in
            result = Result { try readCoordinated(selected) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw SessionFailure.archiveUnavailable }
        return try result.get()
    }

    private static func readCoordinated(_ url: URL) throws -> String {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true else { throw SessionFailure.invalidArchive }
        if let size = values.fileSize, size > maximumBytes { throw SessionFailure.archiveTooLarge }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        var data = Data()
        while true {
            try Task.checkCancellation()
            guard let chunk = try file.read(upToCount: min(4096, maximumBytes + 1 - data.count)), !chunk.isEmpty else { break }
            data.append(chunk)
            guard data.count <= maximumBytes else { throw SessionFailure.archiveTooLarge }
        }
        guard let text = String(data: data, encoding: .utf8) else { throw SessionFailure.invalidArchive }
        return try decode(text).encoded()
    }
}
