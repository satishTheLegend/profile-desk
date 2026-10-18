# Public WebKit session portability feasibility probe

This is a disposable, test-only probe, not a session backup implementation.
It runs only on a newly created iOS 26.5 simulator. The runner never selects an
existing simulator or a physical device, and compiles no production app code.

Run from the repository root, with the native simulator/build slot otherwise idle:

```sh
python3 tests/session_portability/ios/run.py
```

The app seeds **owned synthetic data** on `https://localhost:8447` into a fresh
named `WKWebsiteDataStore`: LocalStorage, SessionStorage, a plain IndexedDB record,
cookie, and CacheStorage. It generates an in-memory nonextractable AES CryptoKey
and separately attempts optional key persistence and service-worker registration.
It checks:

- LocalStorage's public archive restores into another fresh named store.
- Requests to archive IndexedDB, service workers, cookies, mixed types, and all
  website types fail with the specific WebKit unsupported-type rejection, rather
  than silently representing a complete backup. Unrelated errors fail the probe.
- The LocalStorage archive omits the other seeded storage types.
- The public cookie API can copy the owned cookie separately.
- LocalStorage and separately copied cookies persist when the destination view
  closes and the same destination store reopens; IndexedDB and its key stay absent.
- The synthetic in-memory nonextractable CryptoKey is usable while raw `exportKey`
  is rejected. Stored-key usability is checked only if the optional IndexedDB
  clone succeeds. `DataCloneError` is explicitly reported as `UNAVAILABLE`, not
  as a successful persisted-key roundtrip. Service-worker activation is similarly
  independent of the required LocalStorage/IndexedDB/cookie controls.

The report returns `PASS_WITH_LIMITATIONS` when all required core assertions pass
but an optional source control is unavailable. An omission assertion runs only
when its corresponding source control existed. Failed source controls never
establish archive capability. All earlier failed runs remain in `build/`.

The probe does not assume WhatsApp uses that exact key type or data arrangement.
It tests why LocalStorage plus cookies cannot constitute a generic complete
browser-profile backup. No WhatsApp origin, account, QR, message, credential,
private WebKit API, or provider storage directory is accessed.

All archive blobs and synthetic key handles remain in memory. Evidence contains
only booleans, assertion names, OS/runtime metadata, error domain/code, source
hashes and build logs under `build/session-portability-ios-*`. No archive blobs,
cookie values or key bytes are exported into the evidence. The app removes only
the two store IDs it allocates through the public removal API. The runner then
shuts down and deletes its owned simulator, stops its loopback server, and removes
the temporary certificate/key directory. It records cleanup separately.

This probe cannot prove that a real WhatsApp linked login restores, that a server
will continue trusting copied material, that device-bound secrets are portable,
or that cross-platform migration works. Those are separate acceptance gates.

The unsupported-type classifier checks `WKErrorDomain`, `WKError.Code.unknown`,
and the exact fixed description prefix plus one requested type, matching the
[public API implementation at this pinned WebKit revision](https://github.com/WebKit/WebKit/blob/a11228658545f5a823a897cc3bdc2cd386e11492/Source/WebKit/UIProcess/API/Cocoa/WKWebsiteDataStore.mm).
Classifier positive/negative controls reject missing-archive and unrelated
WebKit failures. The probe repeats the repository's public ephemeral WebKit
bootstrap before constructing named stores, and allows bounded removal retries
for WebKit's asynchronous release of disposed views.
The runner permits at most two 60-second boot-status waits on the same newly
created simulator, since first-boot OS data migration can exceed one minute.
