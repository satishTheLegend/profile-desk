# Standalone session portability diagnostic lab

This is a **diagnostic app, not session backup or restore**. The app has a separate bundle identifier, `dev.profiledesk.sessionPortabilityLab`. It cannot read Profile Desk's app container or existing account identifiers. Nothing in this folder is imported by the product build.

Product deployment remains on hold. On 19 October 2026 the user explicitly approved the diagnostic-only exception, and Session Lab was installed on the authorized iPhone. Automatic launch was initially blocked by device lock; the owner subsequently supplied the first counts-only report. See [deployment evidence](../../../docs/evidence/session-portability/physical-lab-install-20261019.json). The build script does **not** install or launch anything. No authenticated-session restore is implied by compilation, synthetic checks, installation or an owner-operated storage scan.

The initial owner-operated scan reached its eight-second deadline after visiting four databases, 23 stores and 1,075 records. It observed zero extractable and two nonextractable key instances, zero unsupported values in the portion scanned, 23 LocalStorage entries and two SessionStorage entries. These are partial observations, not full coverage or proof that the observed keys are required for authentication.

Build 2 added a manually initiated thirty-second scan, coverage counters and numeric key-metadata categories. The owner-operated report reached the 2,000-record cap: 4/5/11 databases completed/started/discovered, 19/20/24 stores completed/started/discovered, and 2,000/2,000/2,462 records completed/started/discovered. It observed no keys or unknown types in that partial traversal, with 83 LocalStorage entries and two SessionStorage entries. This does not contradict build 1's two nonextractable key observations: neither traversal covered every record.

Build 3 changes only the diagnostic scheduling and coverage report. It first inventories bounded readonly store counts, then visits smaller stores first and allocates one prefix to each remaining store under the same record budget. It does not raise any limit. The bundle identifier and lab identity/file logic remain unchanged so an authorized in-place update can retain the separately linked lab profile. This change does not add session export or restore, pagination, retries or automatic escalation.

## Manual diagnostic flow after an approved lab installation

1. Tap **Open WhatsApp test workspace**. The app opens only `https://web.whatsapp.com/` in its own named persistent WKWebsiteDataStore, reusing its recorded lab identity when present. A standard Safari-compatible identification suffix is used for this compatibility experiment, following the previously approved development test. This does not make WKWebView the Safari app.
2. On first use, manually link a separate test account. For an in-place update, use the existing linked lab profile; report an unexpected relink request before clearing anything. The app does not scan a QR, extract an OTP, or automate linking, navigation, or messages.
3. Tap **Run extended scan**. A fixed script runs in the main frame's isolated content world and checks the exact HTTPS service origin. The scan targets thirty seconds and can be discarded with **Cancel scan**. No JavaScript message handler or general scripting bridge is registered.
4. Read the native counts-only report. **A complete scan does not establish session portability.** If nonextractable keys exist, generic key export cannot preserve those keys. If none are observed, other required state may still be missing or inaccessible. Limits, unsupported values, errors and timeouts produce **inconclusive** results.
5. When finished, **Clear lab account** requires confirmation and removes only the UUID recorded by this lab, using the public WKWebsiteDataStore removal API. The owner should also unlink the lab's linked device through WhatsApp if desired. Closing or backgrounding the app does not delete the lab profile.

## Data handling and boundaries

The classifier reads IndexedDB records transiently to identify their types. It returns only counts, a completion state and a fixed reason code. It never returns or saves record contents, record keys, property names, database names, store names, key material, cookies, page text/HTML, QR data or account identifiers. LocalStorage and SessionStorage contribute their entry counts only; their values are never read. CryptoKeys are classified by `extractable`, and only their standard algorithm name, type and permitted usages contribute to fixed numeric histograms. Unknown metadata maps to an **Other** category; raw algorithm dictionaries, parameters and strings are never returned. No key is exported, signed with, encrypted with or otherwise operated on. Blob and buffer contents are not read.

Key counts are **observations, not unique key identities**. The same key stored in multiple records can contribute multiple observations. Shared references within one record are not recounted. Algorithm or usage categories do not identify a key's role in WhatsApp or establish that it is required for authentication.

Coverage distinguishes metadata inventory from value visits. The classifier enumerates up to 12 databases and counts up to 64 stores in readonly transactions before visiting values. It keeps names, versions and store-count descriptors only in the isolated invocation, orders them by ascending inventory count (discovery order breaks ties), and clears them afterward. No record key, offset, checkpoint or resume token is retained.

Each visit validates the database version and store-name set, then recounts the store and reads its prefix in **one readonly transaction**. Its quota is `min(current count, floor(remaining record budget / remaining queued stores))`. Small stores finish early and unused quota is redistributed to later stores. There is one prefix per store, no second pass and no cursor continuation after the quota; the live transaction's count establishes whether all records were covered. Deadlines, node/depth limits or errors can still interrupt the pass before every store is visited.

The report separates inventoried, visited, fully scanned, sampled and skipped stores. A store with unread records is sampled, never completed; an interrupted visit is neither full nor a completed sample. A record is completed only after classification succeeds. Database completion requires every discovered store to be fully scanned and its inventory to be complete. Store discovery is **discovery so far**, not a claim about unopened databases. Records counted during inventory and during value visits are reported separately because they can differ.

Missing databases and version/schema changes make the result explicitly inconclusive; missing databases are not recreated and stale descriptors are not retried. Count changes are flagged while the current transaction's count controls that visit's quota. These observations are not an atomic snapshot and equal counts do not prove that values stayed unchanged. Truncated inventories, skipped stores and sampled prefixes cannot produce a complete result.

The unchanged structural limits are 12 databases, 64 stores, 2,000 records, 20,000 visited values and 20 nesting levels, with a thirty-second cooperative deadline. These checks run between reads and classifications: WebKit can deserialize a large value or stall before JavaScript gets control again. A separate native thirty-five-second watchdog discards the result and releases the scan controls; it cannot forcibly interrupt a blocked WebKit process. Manual cancellation similarly discards the native report and invalidates only that scan's token; an already pending WebKit read can still finish. Transactions are readonly. A database removed during discovery is not recreated. Each scan has a unique token, so starting another scan cannot revive an older cancelled read. Native results are discarded after backgrounding, navigation or profile cleanup. A native cover conceals the workspace when the app resigns active. Popups, foreign navigation, media capture and inspection are disabled. The official web workspace can make its normal network requests after the owner opens it; the classifier makes none.

The workspace fits a 980-point desktop layout to the available native bounds so the linking page is not cut horizontally. WebKit's native pinch zoom remains enabled; the lab does not add a DOM adapter or read QR/page contents.

This is an observation of records encountered during the scan, not an atomic snapshot across stores. The running website can change storage during scanning. Keys may also exist in memory, appear later or depend on state outside the APIs inspected here. An absence of observed nonextractable keys is not evidence that authentication can be exported or restored.

The random lab UUID is recorded only in the lab's own protected Application Support directory, marked excluded from OS backup. No existing data-store inventory is enumerated. Browser storage itself is managed by public WebKit APIs; this lab does not inspect or alter private WebKit directories or claim a broader OS-backup guarantee. An invalid identity record prevents opening any profile.

There is no report saving/sharing/export button and no credential archive. Reports remain in memory and on screen. Native errors are converted to generic messages without logging raw exceptions. Persistent test-account credentials stay in the isolated lab WebKit store until the owner clears it; this is why installation and account linking are separate explicit steps.

## Build only

Wait for other native builds/simulators to finish on the 16 GB host, then run:

```sh
python3 tests/session_portability/ios_lab/build.py --sdk iphonesimulator
python3 tests/session_portability/ios_lab/build.py --sdk iphoneos
```

Each creates a fresh `build/session-portability-lab-<UTC timestamp>/SessionPortabilityLab.app`, source hashes and build evidence. Source bytes are captured once, compiled from staged inputs and packaged from the same captured bytes; packaged resources are compared with those inputs. Simulator output is ad hoc signed. Device output is **unsigned** and cannot be installed without a separate reviewed development-signing step. `--output` accepts an unused output directory. No dependency installation, simulator boot, signing-account changes or device operation occurs.

## Synthetic classifier check

```sh
node tests/session_portability/ios_lab/test_classifier.mjs
```

This uses the exact bundled `StorageClassifier.js` with synthetic values in a disposable headless Chrome profile and an isolated world. CDP fulfills fixture requests locally while DNS is blocked; it never contacts WhatsApp. It verifies the classifier's counts, later-store budget allocation, cursor stopping at quota, source preservation, schema/count-change handling and cancellation/deadline behavior. It does not establish iOS runtime behavior or an authenticated account's storage. Results contain booleans/counts only. The runner destroys its browser and temporary profile.
