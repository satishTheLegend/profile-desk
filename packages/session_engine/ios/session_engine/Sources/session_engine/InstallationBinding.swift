import Foundation
import CryptoKit
import Security

/// A restored database needs both an excluded installation anchor and a device-only Keychain secret.
/// This protects provenance; it does not claim to encrypt WebKit's databases.
final class InstallationBinding {
    private let secretLoader: () throws -> Data
    init(secretLoader: (() throws -> Data)? = nil) { self.secretLoader = secretLoader ?? Self.deviceSecret }

    func verifyOrQuarantine(registry: ProfileRegistry, directory: URL) throws {
        let secret = try secretLoader()
        let nonce = try registry.preference("installationNonce", fallback: "")
        let proof = try registry.preference("installationProof", fallback: "")
        let anchorURL = directory.appendingPathComponent("installation.anchor")
        let anchor = try? Data(contentsOf: anchorURL)
        if let nonceData = Data(base64Encoded:nonce), !nonceData.isEmpty,
           anchor == nonceData, let code = Data(base64Encoded:proof),
           HMAC<SHA256>.isValidAuthenticationCode(code, authenticating: nonceData, using: SymmetricKey(data:secret)) { return }

        if !(try registry.list(includeRemoved:true)).isEmpty { try registry.quarantineUntrustedRestore() }
        var freshNonce = Data(count:32)
        let status = freshNonce.withUnsafeMutableBytes { bytes in SecRandomCopyBytes(kSecRandomDefault,bytes.count,bytes.baseAddress!) }
        guard status == errSecSuccess else { throw SessionFailure.storage }
        let code = Data(HMAC<SHA256>.authenticationCode(for:freshNonce, using:SymmetricKey(data:secret)))
        try freshNonce.write(to:anchorURL,options:.atomic)
        var excluded = anchorURL
        var values = URLResourceValues(); values.isExcludedFromBackup = true; try excluded.setResourceValues(values)
        #if os(iOS)
        try FileManager.default.setAttributes([.protectionKey:FileProtectionType.completeUntilFirstUserAuthentication],ofItemAtPath:anchorURL.path)
        #endif
        try registry.setInstallationBinding(nonce:freshNonce.base64EncodedString(), proof:code.base64EncodedString())
    }

    private static func deviceSecret() throws -> Data {
        let service = (Bundle.main.bundleIdentifier ?? "dev.profiledesk") + ".installation-binding"
        let query: [String:Any] = [kSecClass as String:kSecClassGenericPassword, kSecAttrService as String:service, kSecAttrAccount as String:"binding-v1", kSecAttrSynchronizable as String:false]
        var lookup = query; lookup[kSecReturnData as String] = true; lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary,&result)
        if status == errSecSuccess, let secret = result as? Data, secret.count == 32 { return secret }
        guard status == errSecItemNotFound else { throw SessionFailure.storage }
        var secret = Data(count:32)
        guard secret.withUnsafeMutableBytes({ SecRandomCopyBytes(kSecRandomDefault,$0.count,$0.baseAddress!) }) == errSecSuccess else { throw SessionFailure.storage }
        var item = query
        item[kSecValueData as String] = secret
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(item as CFDictionary,nil) == errSecSuccess else { throw SessionFailure.storage }
        return secret
    }
}
