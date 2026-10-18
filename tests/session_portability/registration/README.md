# Synthetic native registration-wrapper migration

This standalone simulator fixture tests the narrow AES-CTR envelope algorithm
reviewed in the retained public `WAWebSignalCommonUtils` and
`WAWebSignalStoreApi` modules. It does not run service code, access an account,
or implement production import/export.

```sh
python3 tests/session_portability/registration/run.py
```

Reserve the serialized native build/simulator slot first. The runner creates
one disposable iOS 26.5 simulator and one loopback HTTPS fixture server. Every
command is bounded to 60 seconds; first boot permits one additional bounded
boot-status wait on the same owned simulator. No physical device is selected.

Identical Swift source runs first in a bare `swiftc` baseline, then in an ordinary
minimal Xcode app target. Xcode generates the Simulator app identity, linked XML
and DER entitlement sections, processed app metadata, and ad-hoc signature. The
target supports only Simulator and has no dependencies or custom build scripts.
The runner verifies both linked sections against Xcode's generated files,
checks the ad-hoc signature, and compares the installed executable with its
built input before launching either control. No identity entitlements are
manually patched in the Xcode control. The baseline app is uninstalled after its
results are retained and its only diagnostic store is removed. The Xcode control
therefore starts from a clean installation; no source/destination data exists yet.
Public `SecItem`
operations target only a fresh disposable canary item; they never inspect,
replace, or extract WebKit's master key. AES-GCM and AES-CTR CryptoKey persistence
controls expose the original `DataCloneError` rather than making it optional.
Only standard simulator signing is used; no private Apple entitlements, private
WebKit APIs, certificate private keys, or provider directory access is involved.

The required migration proof:

1. Persist two synthetic identity payloads as `{encKey, value}` envelopes in a
   fresh named source store, using independently generated nonextractable
   AES-CTR-128 keys, a 128-bit zero counter, and encrypt/decrypt usages.
2. Decrypt the known synthetic payloads into a bounded in-memory native transfer.
   Original wrapper keys never leave the source web view and cannot be exported.
3. Close the source view, prove the distinct destination store has no source
   database or source-only sentinel, and rewrap with independently generated
   destination keys before persisting the envelopes.
4. Verify exact synthetic plaintext equality and four wrong-key decryption
   controls showing the destination keys differ from both source keys. Each
   wrapper key encrypts exactly one payload; the fixture never encrypts an
   additional challenge under the reused CTR counter.
5. Reopen the source and compare its original encrypted envelope bytes in memory.
6. Terminate the app and reboot only the owned simulator. A fresh process opens
   only the destination store and verifies persisted keys and plaintexts. Another
   fresh process verifies the source remains intact.
7. Remove only the recorded owned stores through public WebKit APIs, then delete
   the owned simulator, stop its server, and remove its temporary TLS certificate.

Evidence under `build/session-registration-*` contains checks, statuses,
counts, source hashes and build logs. No synthetic identity bytes, ciphertexts,
CryptoKeys, or transfer archive are written into reports. App-owned metadata
records only the two fresh store IDs so the cold phases can reopen them.

The reviewed WebKit implementation explains why missing app identity can break
CryptoKey persistence: serialization needs an app-scoped Keychain wrapping key.
This is diagnostic source evidence, not an API this fixture invokes:
[SerializedCryptoKeyWrapCocoa.mm](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/crypto/cocoa/SerializedCryptoKeyWrapCocoa.mm).

The Simulator link/sign distinction is also explicit in Bazel's primary build
implementation, [entitlements_support.bzl](https://github.com/bazelbuild/rules_apple/blob/master/apple/internal/entitlements_support.bzl).
Its [linking_support.bzl](https://github.com/bazelbuild/rules_apple/blob/master/apple/internal/linking_support.bzl)
requires the XML and DER sections together. An intermediate XML-only control
launched but still received missing-entitlement errors; that failure is retained.
The subsequent hand-linked XML+DER control also failed Keychain access. Neither
failure establishes a production WebKit limitation. The standard Xcode target
replaces the hand-packaged control to resolve that fixture configuration question.
An earlier control incorrectly placed the iOS entitlements in the host signature;
SpringBoard rejected launch, and its failure is retained separately. It made no
claim about whether correctly configured CryptoKey persistence succeeds.

Passing proves only this synthetic wrapper migration and its native persistence.
It does not prove complete WhatsApp state coverage, independent authenticated
restore, another key family, account-lock handling, or production readiness.
