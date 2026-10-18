import Foundation
import UIKit
import UniformTypeIdentifiers

@MainActor
protocol AccountArchiveHost: AnyObject {
    var archiveUsable: Bool { get }
    var archiveRoot: URL { get }
    func present(_ controller: UIViewController) -> Bool
}

/// App-owned setup files have no website ViewHandle and never enter web uploads.
/// Controller identity and an operation UUID reject stale system callbacks.
@MainActor
final class NativeAccountArchives: NSObject, UIDocumentPickerDelegate {
    private weak var host: (any AccountArchiveHost)?
    private enum Completion {
        case importing(CheckedContinuation<String?, Error>)
        case exporting(CheckedContinuation<Bool, Error>)
    }
    private var completion: Completion?
    private var picker: UIDocumentPickerViewController?
    private var operation: UUID?
    private var staging: URL?
    private var reader: Task<String, Error>?
    var active: Bool { completion != nil }

    init(host: any AccountArchiveHost) { self.host = host }

    func pick() async throws -> String? {
        guard !active, host?.archiveUsable == true else { throw SessionFailure.busy }
        return try await withCheckedThrowingContinuation { continuation in
            completion = .importing(continuation)
            operation = UUID()
            // Read only the scoped selected document; avoid an untracked Inbox copy.
            let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: false)
            controller.allowsMultipleSelection = false
            controller.delegate = self
            picker = controller
            if host?.present(controller) != true { finish(error: SessionFailure.archiveUnavailable) }
        }
    }

    func export(_ archive: AccountSetupArchive) async throws -> Bool {
        guard !active, let host, host.archiveUsable else { throw SessionFailure.busy }
        let data = Data(try archive.encoded().utf8)
        let directory = host.archiveRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var excluded = directory
            var values = URLResourceValues(); values.isExcludedFromBackup = true
            try excluded.setResourceValues(values)
            let file = directory.appendingPathComponent("ProfileDesk-Account-Setup.json")
            try data.write(to: file, options: [.atomic, .completeFileProtection])
            staging = directory
            return try await withCheckedThrowingContinuation { continuation in
                completion = .exporting(continuation)
                operation = UUID()
                let controller = UIDocumentPickerViewController(forExporting: [file], asCopy: true)
                controller.delegate = self
                picker = controller
                if !host.present(controller) { finish(error: SessionFailure.archiveUnavailable) }
            }
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        guard controller === picker else { return }
        finish()
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard controller === picker, let token = operation, host?.archiveUsable == true else {
            if controller === picker { finish() }
            return
        }
        switch completion {
        case .exporting:
            // The selected destination never crosses the native boundary.
            finish(exported: !urls.isEmpty)
        case .importing:
            guard reader == nil, urls.count == 1, let url = urls.first else { finish(error: SessionFailure.invalidArchive); return }
            let task = Task.detached(priority: .userInitiated) { try AccountSetupArchive.read(url) }
            reader = task
            Task { @MainActor [weak self] in
                let result = await task.result
                guard let self, self.operation == token else { return }
                guard !task.isCancelled, self.host?.archiveUsable == true else { self.finish(); return }
                switch result {
                case .success(let text): self.finish(imported: text)
                case .failure(let error): self.finish(error: error)
                }
            }
        case nil: break
        }
    }

    /// Lock, background or Flutter detach invalidates the token before dismissing.
    func cancel() {
        let controller = picker
        finish()
        controller?.dismiss(animated: false)
    }

    private func finish(imported: String? = nil, exported: Bool = false, error: Error? = nil) {
        let pending = completion
        completion = nil; operation = nil
        reader?.cancel(); reader = nil
        picker?.delegate = nil; picker = nil
        if let staging { try? FileManager.default.removeItem(at: staging) }
        staging = nil
        switch pending {
        case .importing(let callback):
            if let error { callback.resume(throwing: error) } else { callback.resume(returning: imported) }
        case .exporting(let callback):
            if let error { callback.resume(throwing: error) } else { callback.resume(returning: exported) }
        case nil: break
        }
    }
}
