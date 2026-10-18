import Foundation

enum TransferFiles {
    /// Leave room for the random import prefix within common 255-byte limits.
    static func safeFilename(_ value: String) -> String {
        let illegal = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: "/\\:"))
        let filtered = value.unicodeScalars.map { illegal.contains($0) ? "_" : String($0) }.joined().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !filtered.isEmpty, filtered != ".", filtered != ".." else { return "download" }
        let extensionValue = (filtered as NSString).pathExtension
        let suffix = !extensionValue.isEmpty && extensionValue.utf8.count <= 32 ? "." + extensionValue : ""
        let base = suffix.isEmpty ? filtered : String(filtered.dropLast(suffix.count))
        var result = ""
        for scalar in base.unicodeScalars {
            let next = String(scalar)
            if result.utf8.count + next.utf8.count + suffix.utf8.count > 180 { break }
            result += next
        }
        return (result.isEmpty ? "download" : result) + suffix
    }

    /// Runs off the main actor. Cancellation is checked between bounded chunks.
    /// Partial output is removed before a failure or cancellation returns.
    static func importFiles(_ urls: [URL], into directory: URL, progress: @Sendable (Int64, Int64?) -> Void = { _, _ in }) throws -> [URL] {
        var completed = false
        defer { if !completed { try? FileManager.default.removeItem(at: directory) } }
        try Task.checkCancellation()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var totalBytes: Int64? = 0
        for source in urls {
            try Task.checkCancellation()
            let access = source.startAccessingSecurityScopedResource()
            defer { if access { source.stopAccessingSecurityScopedResource() } }
            let values = try source.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard values.isRegularFile == true else { throw CocoaError(.fileReadUnsupportedScheme) }
            if let size = values.fileSize, let total = totalBytes {
                let (sum, overflow) = total.addingReportingOverflow(Int64(size))
                totalBytes = overflow ? nil : sum
            } else { totalBytes = nil }
        }
        var copiedBytes: Int64 = 0
        var lastProgress = Date.distantPast
        progress(0, totalBytes)
        var copies = [URL]()
        for source in urls {
            try Task.checkCancellation()
            let access = source.startAccessingSecurityScopedResource()
            defer { if access { source.stopAccessingSecurityScopedResource() } }
            let values = try source.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { throw CocoaError(.fileReadUnsupportedScheme) }
            let destination = directory.appendingPathComponent(UUID().uuidString + "-" + safeFilename(source.lastPathComponent))
            guard FileManager.default.createFile(atPath: destination.path, contents: nil) else { throw CocoaError(.fileWriteUnknown) }
            let input = try FileHandle(forReadingFrom: source)
            defer { try? input.close() }
            let output = try FileHandle(forWritingTo: destination)
            defer { try? output.close() }
            while true {
                try Task.checkCancellation()
                guard let chunk = try input.read(upToCount: 64 * 1024), !chunk.isEmpty else { break }
                try output.write(contentsOf: chunk)
                copiedBytes += Int64(chunk.count)
                if Date().timeIntervalSince(lastProgress) >= 0.1 {
                    progress(copiedBytes, totalBytes)
                    lastProgress = Date()
                }
            }
            try output.synchronize()
            copies.append(destination)
        }
        try Task.checkCancellation()
        progress(copiedBytes, totalBytes)
        completed = true
        return copies
    }
}
