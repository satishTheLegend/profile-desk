# Synthetic registration-wrapper migration

19 October 2026: **92 assertions pass** across six process phases on an owned iOS 26.5 simulator. This is a narrow mechanism proof, not a WhatsApp login-restore result.

[Verification](verification.json) records a standard Xcode-built application successfully persisting nonextractable AES-CTR and AES-GCM keys. Two synthetic identity payloads are decrypted in memory, then independently rewrapped with fresh destination AES-CTR-128 keys. The destination starts empty, cannot see the source sentinel, and survives app termination and a full owned simulator reboot. A separate cold source process confirms preservation of its original envelopes. Four wrong-key decryption controls establish separation from the source keys without reusing the CTR key/counter for another encryption.

The unchanged Swift/JavaScript assertions failed in the earlier hand-packaged simulator controls. Ordinary Xcode build/installation resolved the fixture-level Keychain and serialization failure. The evidence does not isolate a single entitlement or metadata field as the cause. Earlier failures remain under `build/session-registration-20261018T194343Z`, `...194918Z` and `...195427Z`; no failure was converted to a skip.

Independent read-only review verified all source/module hashes, executable hashes, strict signatures, Xcode-generated identity sections, cold process/store ownership, the absence of a cold-path seed, and targeted cleanup. The owned simulator, loopback server and temporary certificate are removed. Reports contain status/count/hash information and no payload or key bytes.

Open requirements: malformed-envelope fault cases; additional HKDF/Noise/application-key families; a consistent complete payload; conversation/media coverage; authenticated independent WhatsApp restore; physical/provider compatibility; encrypted product archives and single-app integration. Original wrapper keys were not exported. No physical device or actual account was accessed, and no new application was installed on the owner's iPhone.

Reproduction and implementation: [registration fixture](../../../../tests/session_portability/registration/README.md). Full run/build logs remain in `build/session-registration-20261018T200101Z`.
