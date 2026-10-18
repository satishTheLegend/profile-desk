import XCTest
@testable import ProfileRegistry

final class TransferFilesTests: XCTestCase {
    private final class ProgressLog: @unchecked Sendable {
        private let lock = NSLock()
        private var values = [(Int64, Int64?)]()
        func append(_ copied: Int64, _ total: Int64?) { lock.lock(); defer { lock.unlock() }; values.append((copied, total)) }
        var snapshot: [(Int64, Int64?)] { lock.lock(); defer { lock.unlock() }; return values }
    }
    func testMultibyteFilenameHasSafeByteBudgetAndExtension() {
        let name = TransferFiles.safeFilename(String(repeating: "👩🏽‍💻", count: 120) + ".pdf")
        XCTAssertLessThanOrEqual((UUID().uuidString + "-" + name).utf8.count, 255)
        XCTAssertTrue(name.hasSuffix(".pdf"))
        XCTAssertFalse(TransferFiles.safeFilename("../a\\b:c\n.txt").contains("/"))
    }
    func testFailedSecondCopyRemovesEarlierOutput() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source.txt")
        try Data("synthetic".utf8).write(to: source)
        let destination = root.appendingPathComponent("staging")
        let task = Task.detached { try TransferFiles.importFiles([source, root.appendingPathComponent("absent.txt")], into: destination) }
        do { _ = try await task.value; XCTFail("Missing input must fail") } catch {}
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: source), "synthetic")
    }
    func testCanceledImportRemovesDirectoryBeforeReturning() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("partial".utf8).write(to: directory.appendingPathComponent("partial.bin"))
        let task = Task.detached {
            try? await Task.sleep(nanoseconds: 20_000_000)
            return try TransferFiles.importFiles([], into: directory)
        }
        task.cancel()
        do { _ = try await task.value; XCTFail("Cancelled import must fail") } catch is CancellationError {} catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }
    func testDetachedChunkCopyPreservesContent() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source.bin")
        let expected = Data(repeating: 42, count: 180_000)
        try expected.write(to: source)
        let paths = try await Task.detached { try TransferFiles.importFiles([source], into: root.appendingPathComponent("staging")) }.value
        XCTAssertEqual(paths.count, 1)
        XCTAssertEqual(try Data(contentsOf: paths[0]), expected)
    }
    func testImportProgressCountsBytesAcrossFiles() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = root.appendingPathComponent("first.bin")
        let second = root.appendingPathComponent("second.bin")
        try Data(repeating: 1, count: 180_000).write(to: first)
        try Data(repeating: 2, count: 90_000).write(to: second)
        let log = ProgressLog()
        _ = try await Task.detached {
            try TransferFiles.importFiles([first, second], into: root.appendingPathComponent("staging")) { log.append($0, $1) }
        }.value
        let values = log.snapshot
        XCTAssertEqual(values.first?.0, 0)
        XCTAssertEqual(values.last?.0, 270_000)
        XCTAssertTrue(values.allSatisfy { $0.1 == 270_000 })
        XCTAssertEqual(values.map { $0.0 }, values.map { $0.0 }.sorted())
    }
}
