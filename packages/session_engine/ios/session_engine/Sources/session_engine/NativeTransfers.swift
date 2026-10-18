import Foundation
import UIKit
import UniformTypeIdentifiers
import WebKit

@MainActor
protocol NativeTransferHost: AnyObject {
    func isUsable(_ handle: ViewHandle) -> Bool
    var transferRoot: URL { get }
    func present(_ controller: UIViewController) -> Bool
    func presentShare(items: [Any], completion: (() -> Void)?)
    func transferState()
    func transferFailed(_ owner: ViewHandle, code: String)
}

@MainActor
final class NativeTransfers: NSObject, UIDocumentPickerDelegate, WKDownloadDelegate {
    private weak var engine: (any NativeTransferHost)?
    private var picker: UIDocumentPickerViewController?
    private var pickerOwner: ViewHandle?
    private var pickerCompletion: (([URL]?) -> Void)?
    private var importWorker: (id: UUID, owner: ViewHandle, task: Task<[URL], Error>)?
    private var importFinishing: Task<Void, Never>?
    private var importProgress: Double?
    private struct DownloadRecord { let id: UUID; let download: WKDownload; let owner: ViewHandle; let directory: URL; var destination: URL? }
    private var downloads = [ObjectIdentifier: DownloadRecord]()
    private var downloadProgress = [ObjectIdentifier: NSKeyValueObservation]()
    private var cancelling = [ObjectIdentifier: Task<Void, Never>]()
    var active: Bool { pickerCompletion != nil || importWorker != nil || !downloads.isEmpty || !cancelling.isEmpty }
    var progress: Double? {
        if importWorker != nil { return importProgress }
        guard pickerCompletion == nil, cancelling.isEmpty, !downloads.isEmpty else { return nil }
        let values = downloads.values.map { $0.download.progress }
        guard values.allSatisfy({ $0.totalUnitCount > 0 }) else { return nil }
        let total = values.reduce(0.0) { $0 + Double($1.totalUnitCount) }
        let done = values.reduce(0.0) { $0 + Double($1.completedUnitCount) }
        return min(1, max(0, done / total))
    }

    init(engine: any NativeTransferHost) { self.engine = engine }
    func pick(owner: ViewHandle, multiple: Bool, completion: @escaping ([URL]?) -> Void) {
        guard !active, engine?.isUsable(owner) == true else { completion(nil); return }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.allowsMultipleSelection = multiple
        picker.delegate = self
        pickerOwner = owner; pickerCompletion = completion; self.picker = picker
        guard engine?.present(picker) == true else { finishPicker(nil); return }
        engine?.transferState()
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        guard controller === picker else { return }
        importWorker?.task.cancel(); finishPicker(nil)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard controller === picker else { return }
        guard importWorker == nil, let owner = pickerOwner, engine?.isUsable(owner) == true, let root = engine?.transferRoot else { finishPicker(nil); return }
        let transferId = UUID()
        let directory = root.appendingPathComponent(owner.profileId, isDirectory: true).appendingPathComponent(transferId.uuidString, isDirectory: true)
        importProgress = nil
        let reportProgress: @Sendable (Int64, Int64?) -> Void = { [weak self] copied, total in
            guard let self else { return }
            Task { @MainActor in
                guard self.importWorker?.id == transferId, self.importWorker?.owner == owner, self.engine?.isUsable(owner) == true else { return }
                self.importProgress = total.flatMap { $0 > 0 ? min(1, max(0, Double(copied) / Double($0))) : nil }
                self.engine?.transferState()
            }
        }
        let worker = Task.detached(priority: .userInitiated) {
            try TransferFiles.importFiles(urls, into: directory, progress: reportProgress)
        }
        importWorker = (transferId, owner, worker)
        importFinishing = Task { @MainActor [weak self] in
            let result = await worker.result
            guard let self else { try? FileManager.default.removeItem(at: directory); return }
            defer { self.importWorker = nil; self.importFinishing = nil; self.importProgress = nil; self.engine?.transferState() }
            guard !worker.isCancelled, self.pickerOwner == owner, self.engine?.isUsable(owner) == true else {
                try? FileManager.default.removeItem(at: directory)
                if self.pickerOwner == owner { self.finishPicker(nil) }
                return
            }
            switch result {
            case .success(let copies): self.finishPicker(copies)
            case .failure:
                self.engine?.transferFailed(owner, code: "fileImportFailed")
                self.finishPicker(nil)
            }
        }
    }
    private func finishPicker(_ urls: [URL]?) {
        let completion = pickerCompletion
        pickerCompletion = nil; pickerOwner = nil; picker?.delegate = nil; picker = nil
        completion?(urls)
        engine?.transferState()
    }

    func begin(_ download: WKDownload, owner: ViewHandle) {
        guard engine?.isUsable(owner) == true, let root = engine?.transferRoot else { download.cancel { _ in }; return }
        let transferId = UUID()
        let directory = root.appendingPathComponent(owner.profileId, isDirectory: true).appendingPathComponent(transferId.uuidString, isDirectory: true)
        let id = ObjectIdentifier(download)
        downloads[id] = DownloadRecord(id: transferId, download: download, owner: owner, directory: directory)
        downloadProgress[id] = download.progress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self, self.downloads[id]?.id == transferId, self.downloads[id]?.owner == owner, self.engine?.isUsable(owner) == true else { return }
                self.engine?.transferState()
            }
        }
        download.delegate = self
        engine?.transferState()
    }
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let key = ObjectIdentifier(download)
        guard var record = downloads[key], engine?.isUsable(record.owner) == true else { completionHandler(nil); return }
        do {
            try FileManager.default.createDirectory(at: record.directory, withIntermediateDirectories: true)
            let destination = record.directory.appendingPathComponent(TransferFiles.safeFilename(suggestedFilename))
            record.destination = destination; downloads[key] = record
            completionHandler(destination)
        } catch { completionHandler(nil); fail(download, code: "downloadDestinationFailed") }
    }
    func downloadDidFinish(_ download: WKDownload) {
        guard let record = downloads.removeValue(forKey: ObjectIdentifier(download)) else { return }
        downloadProgress.removeValue(forKey: ObjectIdentifier(download))?.invalidate()
        download.delegate = nil
        if engine?.isUsable(record.owner) == true, let destination = record.destination {
            engine?.presentShare(items: [destination]) { try? FileManager.default.removeItem(at: record.directory) }
        } else { try? FileManager.default.removeItem(at: record.directory) }
        engine?.transferState()
    }
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) { fail(download, code: "downloadFailed") }
    private func fail(_ download: WKDownload, code: String) {
        guard let record = downloads.removeValue(forKey: ObjectIdentifier(download)) else { return }
        downloadProgress.removeValue(forKey: ObjectIdentifier(download))?.invalidate()
        download.delegate = nil
        try? FileManager.default.removeItem(at: record.directory)
        engine?.transferFailed(record.owner, code: code)
        engine?.transferState()
    }
    func download(_ download: WKDownload, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, decisionHandler: @escaping (WKDownload.RedirectPolicy) -> Void) {
        guard let record = downloads[ObjectIdentifier(download)], engine?.isUsable(record.owner) == true, request.url?.scheme == "https" else { decisionHandler(.cancel); return }
        decisionHandler(.allow)
    }
    func download(_ download: WKDownload, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) { completionHandler(.performDefaultHandling,nil) }

    func cancel(owner: ViewHandle? = nil) {
        if let work = importWorker, owner == nil || work.owner == owner { work.task.cancel() }
        if let pickerOwner, owner == nil || owner == pickerOwner { picker?.dismiss(animated: false); finishPicker(nil) }
        for (id, record) in Array(downloads) where owner == nil || record.owner == owner {
            downloads.removeValue(forKey: id)
            downloadProgress.removeValue(forKey: id)?.invalidate()
            record.download.delegate = nil
            let task = Task { @MainActor [weak self] in
                await withCheckedContinuation { continuation in
                    record.download.cancel { _ in continuation.resume() }
                }
                try? FileManager.default.removeItem(at: record.directory)
                self?.cancelling.removeValue(forKey: id)
                self?.engine?.transferState()
            }
            cancelling[id] = task
        }
        engine?.transferState()
    }
    func waitForCancellation() async {
        if let task = importFinishing { await task.value }
        for task in Array(cancelling.values) { await task.value }
    }
    func removeFiles(profileId: String) throws {
        guard UUID(uuidString: profileId) != nil, let root = engine?.transferRoot else { throw SessionFailure.storage }
        let directory = root.appendingPathComponent(profileId, isDirectory: true)
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }
}
