# Registration-wrapper fault controls and cold migration

19 October 2026. [125 assertions pass](verification.json) across six distinct app processes in the owned iOS 26.5 simulator. Source, installed executable and reviewed public-module hashes match; all owned resources were cleaned. The preceding [92-assertion proof](../README.md) and its failed packaging controls remain preserved.

The new controls reject thirty malformed inputs before transfer/write: missing/extra envelopes, invalid fields, counterfeit/extractable/wrong-algorithm/wrong-length/wrong-usage keys, invalid ciphertext types/lengths, shared or structured-cloned shared keys, damaged ciphertext, incomplete/extra transfer fields, invalid/sparse/short/typed-array payloads. The original encrypted bytes and their readability remain unchanged after all failures. Each CTR wrapper key encrypts exactly one synthetic payload; shared-key controls reject before encryption and wrong-key controls only decrypt.

This fixture validates two fixed fictional 32-byte payloads. Its known-byte comparison detects corruption for this test; AES-CTR does not authenticate arbitrary real data. The eventual archive requires authenticated encryption. This is neither a general credential validator nor evidence of complete WhatsApp session/data coverage.

The destination uses distinct fresh nonextractable keys in a different named WKWebsiteDataStore. After app termination and full reboot of only the owned simulator, a fresh process opens only the destination and verifies it; another opens only the unchanged source. Reports contain statuses/counts/hashes and no payload/key/ciphertext bytes. No real service/account or physical device was accessed.

Reproduce with `python3 tests/session_portability/registration/run.py` from the repository root, reserving the native simulator slot. [Fixture and exact limits](../../../../../tests/session_portability/registration/README.md).
