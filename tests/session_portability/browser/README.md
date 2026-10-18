# Browser storage portability feasibility probe

This is a **test-only spike**, not an application archive format or a session-backup implementation. It answers whether selected structured IndexedDB values and an exportable synthetic key can survive a tagged JSON round trip into an independent storage context, and whether an unsupported key fails honestly.

Run from the repository root with installed Node and Google Chrome:

```sh
node tests/session_portability/browser/run.mjs build/session-portability-browser-latest
```

`CHROME_PATH` can identify another existing Chrome binary. No dependencies are installed. The runner launches a disposable headless profile, two separate browser contexts, and an ephemeral loopback HTTP server. All page requests are restricted to that owned local origin. Existing user profiles and service accounts are never opened. The source context is destroyed before the target import.

The fixture includes ArrayBuffer, a Uint8Array slice, Date, Map, Blob, primitive arrays, LocalStorage, SessionStorage, and extractable/nonextractable HMAC CryptoKeys. Assertions compare types and values inside the fixture; evidence contains only booleans, counts, environment versions and size. Synthetic key material and the transient archive are never written to evidence files. The runner closes its contexts/browser/server and removes its temporary profile.

Export has a 128 KiB output limit plus node/depth budgets. Import bounds input, validates/decode types before starting its IndexedDB write transaction, and requires an empty target. This is a deliberately narrow probe, **not a hardened general archive parser or production transaction**. It does not establish coverage of every IndexedDB type, cyclic/shared references, schema/index metadata, cookies, service workers, caches, browser-private files, or OS keystores.

Passing results do **not** demonstrate restored WhatsApp login on iOS or Android. A nonextractable key can remain usable inside its original browser context while `exportKey` fails; naive JSON conversion silently destroys the key. The probe therefore rejects the entire export while such a key is present. Only the explicitly supported subset is tested after removing that synthetic record.
