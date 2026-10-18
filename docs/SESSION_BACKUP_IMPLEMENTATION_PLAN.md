# Current-session backup and restore

Updated 19 October 2026. Status: feasibility prototypes implemented and the separate diagnostic lab installed after explicit approval. Its first report observed two nonextractable CryptoKey occurrences. Build2 hit the record cap before reaching later stores. Build3's fair sampling preserves all limits; 52 synthetic checks and native builds pass, and installation/foreground launch are verified. Its physical report classified 2,000 records across 61 full and 3 sampled stores, with 82 stores skipped; it observed two nonextractable AES-CTR secret-key occurrences permitted to encrypt/decrypt. Their authentication role remains unknown. Further counting alone cannot establish a portable login-state subset. The product deployment hold remains; the exception covers Session Lab testing only.

Later source review and the user's native-UI/complete-information request are tracked in [the unified design](PROFILE_DESK_NATIVE_EXPERIENCE.md) and [implementation checklist](PROFILE_DESK_NATIVE_EXPERIENCE_PLAN.md). The public client source now establishes one exact registration-wrapper format and additional dependent key families. This supersedes the earlier statement below that no schema had been mapped; it does not establish a complete archive or tie the lab's two observations to particular records.

## Intended result

Link an account through the official WhatsApp Web flow, export its current authenticated state, and restore into a genuinely independent empty profile. After reopening that destination, the account must remain authenticated without another QR/code link. Support all selected accounts, up to the existing ten-account limit, without merging their stores. Preserve the source profiles throughout the operation.

The initial compatibility target is the same platform and supported OS/provider family. The later request explicitly includes complete information: conversation/media coverage must be established and stated, and cannot silently be replaced by later service synchronization. Cross-platform transfer remains a separate verification requirement. Login restoration cannot override expiry or logout performed by WhatsApp or the account owner.

The user's latest request authorizes investigating and implementing this feature. Their explicit deployment prerequisite still applies. Brainstorming selects a feasibility spike before committing to a production architecture; gstack routing and engineering security guidance inform the tests and gates. Routine confirmation is not required to work on these synthetic prototypes.

This is an explicit scope change from the original prompt's exclusions of session export/import and session backup (sections 2, 7 and 13). The later native-widget request also authorizes a bounded reviewed chat-display/action adapter. It does not authorize a generic scripting bridge, private browser-file access, unrelated data collection, automated messages, or account linking on the owner's behalf. Credential handling, if proven viable, belongs only to the explicit encrypted session-backup operation.

## Corrected feasibility question

The earlier investigation established that public native APIs do not export an entire browser profile. That alone does **not** establish that a sufficient application-specific authentication subset cannot be exported. The correct question is whether **all state required for authenticated cold-start restore** can be captured and restored through supported APIs.

| Approach | Decision |
|---|---|
| Native whole-store archive | Insufficient on reviewed WebKit/Android APIs; test its actual boundaries |
| Fixed-origin, reviewed credential-state serializer plus native cookie transport | Investigate; potentially viable only when every required value is portable and sufficiency is proven |
| Reuse a surviving original profile identifier | Does not satisfy backup/restore; not accepted as evidence |
| Raw private provider files, private APIs or replacement WhatsApp protocol | Outside retained project constraints; not the implementation path |

## Architecture if the feasibility gates pass

The existing readable account-setup JSON remains separate. It must never carry login state. A new session archive would be native-owned and encrypted, with a versioned bounded envelope and a user-controlled recovery secret that works after reinstall. Authentication keys, cookies and archive bytes must not enter Flutter state, telemetry, diagnostic logs or saved test evidence.

Use fixed commands bound to a current unlocked attachment and selected profile. No arbitrary URL, selector, JavaScript, filesystem path or generic storage query enters the shared contract. An explicitly reviewed credential-store/schema allowlist limits the fixed-origin serializer. Unknown schema, unsupported value/key types, inconsistent reads, missing cookie coverage or unsupported providers stop export before a file is offered. Do not silently skip data or label an incomplete archive successful.

Export needs a consistent snapshot. IndexedDB transactions are per database; merely hiding or pausing a WebView does not establish that all service workers and other writers stopped. Cross-store consistency must be addressed and tested before production activation. Selected accounts are processed sequentially to preserve the one-live-view rule; cancellation restores ordinary ownership without changing source stores.

Import authenticates and validates the archive before allocation. It stages fresh profile identities, restores into a controlled empty origin bootstrap before the remote application runs, then commits metadata only after all selected profiles succeed. Failed or interrupted allocations remain in a narrowly owned recovery journal. Existing profiles and browser data are never replacement/deletion targets. The archive cannot disable device lock or import installation trust.

Cryptography should use vetted native authenticated encryption and a reviewed password-based key derivation scheme. Exact algorithms, parameters, chunk limits and container format must be fixed and adversarially tested before implementation; a custom cipher or plaintext credential file is not a shortcut around the remaining portability question.

## Work and gates

### 1. Empirical portability probes

- [x] Build an isolated browser fixture that exports supported typed IndexedDB values, LocalStorage, SessionStorage and an exportable signing key.
- [x] Destroy the source browser context before import into an independently empty context; compare a cryptographic challenge, not an `isLoggedIn` flag.
- [x] Verify that a persisted nonextractable key still works but cannot be exported; reject the complete export rather than silently serialize it to `{}`.
- [x] Run the native WebKit core probe: 37 assertions pass with a recorded limitation. LocalStorage archive/restore, separate cookie transfer, unsupported native archive types and fresh-store reopen are verified. In-memory nonextractable-key use/export rejection passes; persisted-key cloning is unavailable (`DataCloneError`) in this disposable simulator app.
- [x] Independently review the browser prototype's isolation, claims and cleanup; retain evidence with explicit limits.
- [x] Finish independent review and compilation of the separate counts-only Session Lab diagnostic app: 31 synthetic checks, clean simulator/device compilation, matching tested/packaged classifier and verified local development signature.
- [x] Obtain the requested exception and install only the diagnostic lab. The installed bundle/version is independently verified; Profile Desk's installed record is unchanged. Automatic launch was blocked by device lock.
- [x] Obtain an owner-operated native report from the real workspace. The user authorized a screenshot; only the fixed diagnostic values were retained, and the temporary screenshot was removed. Linking method and fresh-profile restoration were not observed.
- [x] Obtain one manual extended diagnostic report: build2 correctly distinguishes started/completed work and stops at its 2,000-record ceiling. Its sampled portion contains no observed keys; algorithm/type/usage categories remain unobserved, not established as absent.
- [x] Implement, test, review, build and install bounded coverage with one metadata inventory followed by one fair prefix per store. This keeps existing ceilings, starts small stores first, reserves record budget for later stores and explicitly reports partial sampling. No key contents, record identifiers, resume offsets or cryptographic operations are permitted.
- [x] Obtain the owner-operated build3 report and assess the remaining state-boundary investigation. It encounters two nonextractable AES-CTR secret-key occurrences but leaves their role unknown. A completed sample is not a complete storage scan or authenticated restore proof.

The extended diagnostic in lab build2 passed 42 synthetic checks and produced the owner-operated partial report above. [Build3](evidence/session-portability/lab-v3/README.md) passes 52 synthetic checks, independent source review, both native compilations, tested/packaged script comparison and signature verification. It is installed and foreground-launched as an in-place update without uninstall/reset. The lab identity persistence code is unchanged and its owner-operated report is captured; linking method and retention without relinking were not independently observed.

Commands:

```sh
node tests/session_portability/browser/run.mjs build/session-portability-browser-current
python3 tests/session_portability/ios/run.py
```

These are test-only probes. They do not modify the production backup screen or access real accounts. Browser fixtures demonstrate mechanisms on Chrome; they do not establish Android WebView equivalence. Native simulator probes do not establish physical-device/service compatibility.

Native evidence is [archived with cleanup and prior failures](evidence/session-portability/README.md). The iOS result is `PASS_WITH_LIMITATIONS`, not an authenticated backup pass. Its LocalStorage archive demonstrably omits seeded IndexedDB records, cookies, caches and workers; public cookie transport handles only the separately copied synthetic cookie. The stored-key limitation is a property of this test environment and does not establish WhatsApp's key representation.

### 2. Establish the service-specific state boundary

- [ ] Establish a reviewed current WhatsApp credential-store/schema allowlist without reading or logging conversation contents.
- [x] Trace the exact public registration-wrapper schema, encryption/decryption paths and identity consumers; distinguish source facts from the lab's counts-only observations.
- [x] Identify additional HKDF, Noise, preferences/cache and application-encryption dependencies which prevent treating the narrow registration records as a full session.
- [ ] Establish supported migration semantics for every required value family, including nonextractable keys; absence of such keys is not a prerequisite if their semantic state can be legitimately migrated.
- [ ] Establish fixed cookie origin/path/partition coverage. Android's feature-gated `CookieManagerCompat.getCookieInfo` preserves more attributes than `getCookie`; its availability and coverage require checks.
- [ ] Determine which cache/service-worker state is safely rebuilt after restore and prove that omitted state is not required for authentication.
- [ ] Demonstrate a stable snapshot strategy and a controlled fresh-origin restore bootstrap.

The retained public client code maps `signal-storage/signal-meta-store` records `signal_reg_id`, `signal_static_pubkey` and `signal_static_privkey`. Public/private identity bytes are independently wrapped as `{encKey,value}` using fresh nonextractable AES-CTR-128 keys with a 128-bit zero counter. The official read path decrypts those wrappers back to identity bytes. This supports testing semantic transfer under new destination-local wrapper keys; exporting the original CryptoKey is unnecessary for this narrow format. Distinct fresh keys are essential because the counter is fixed.

The same review identifies nonextractable HKDF keys in `wawc_db_enc` (`keys`, `fts_hmac_keys`, `worm_ear_keys`), Noise credentials and user/cache preferences, and encrypted application records with `_data/iv/_keyId/_scheme`. A subsequent source pass maps 24 encrypted columns across 14 schemas and supports logical decrypt/re-encrypt in principle for those known fields. A subsequent bounded pass maps ordinary-browser final-key salt to the successful-login response's `companion_enc_static` field. The FTS worker consumes an HMAC key for token-prefix indexes (six HMAC bytes and an optional three-byte chat hash); changing that key requires rebuilding a fresh manifest and worker caches, since an existing completed manifest can make indexing skip work. Worm key consumers remain unresolved. The success handler also starts sync/identity work, so knowing the salt source does not establish a safe restore/bootstrap barrier. Complete migration, snapshot consistency, cookie coverage, screen-lock layers and local conversation/media coverage remain open.

The [synthetic native probe](evidence/session-portability/registration/README.md) now passes 92 assertions with independent cold process/reboot and source preservation. Standard Xcode build/installation resolved its earlier simulator Keychain failure without relaxing the same Swift/JS assertions. This proves the narrow wrapper mechanism; no production session export is enabled from it.

A test using real authentication still requires owner-operated linking where necessary and the retained deployment condition. Synthetic results do not supply a genuine restored-login proof.

The [19 October state-boundary review](evidence/session-portability/state-boundary-review.md) found no credential-schema mapping or migration interface in the reviewed official whitepaper, multi-device architecture and help documentation. Those sources do not establish the observed keys' purpose. The generic whole-value exporter cannot preserve these nonextractable key objects through standard export/wrap operations; a sufficient smaller subset remains unverified. Production implementation is blocked at this gate, with no further owner scan requested. This is a limitation of the verified path and evidence, not proof that session migration is universally impossible.

The standalone [Session Lab](../tests/session_portability/ios_lab/README.md) is a diagnostic aid for this phase. It creates only its own browser profile in a different application sandbox. A manual scan returns fixed type counts and key-extractability flags, never database names, record contents, cookies or key material. It does not establish a credential-store allowlist, a consistent snapshot, state sufficiency or successful restoration. Scan bounds are cooperative; oversized records and unavailable APIs must remain limitations rather than being silently omitted. A lab build or a complete counts scan does not close any real-session restoration gate.

The [first physical observation](evidence/session-portability/physical-storage-observation-20261019.json) reports two nonextractable-key occurrences. Repeated storage of the same underlying key can count more than once. The interrupted record/store may be partially traversed. This supplies positive evidence of encountered nonextractable CryptoKey values, while leaving their purpose and authentication necessity unknown. The next diagnostic uses a 30-second cooperative deadline and 35-second native watchdog, retains existing data/node ceilings, and adds only fixed progress and key-metadata histograms. It does not use resume offsets or retain record identifiers, and it must not present a changing-store scan as an atomic snapshot.

The [second physical observation](evidence/session-portability/lab-v2/physical-storage-observation.json) demonstrates starvation under a sequential global record cap: 2,000 records completed before all discovered databases were visited. The next refinement changes allocation, not the ceilings: inventory counts, sort small stores first, allocate `min(currentStoreCount, floor(remainingRecordBudget / remainingStores))`, and traverse one prefix per store. Current count and prefix share a readonly transaction; count changes are flagged and schema/version changes make the result inconclusive. Finishing a prefix is not full-store completion. Deadline and node limits can still prevent complete coverage.

The [third physical observation](evidence/session-portability/lab-v3/physical-storage-observation.json) confirms the refinement reaches the key categories: two nonextractable AES-CTR secret-key observations, both permitting encrypt/decrypt. Coverage is still partial (61 full, 3 sampled, 82 skipped stores). A generic `exportKey`/`wrapKey` archive cannot preserve those key objects; whether authenticated restoration requires them is not known. Do not claim the feature universally impossible or silently omit the keys. The next work is bounded public documentation/client-source research for a reviewed credential-state boundary and supported regeneration/migration path, without inspecting real record contents. No further cap increases or repeated diagnostic builds are planned without a new decisive question.

### 3. Implement the protected archive and native orchestration

- [ ] Finalize encrypted format, KDF/recovery UX, bounds and format compatibility after phase 2 passes.
- [ ] Implement native export/import coordinators, document-provider handling, operation ownership, cancellation and lock/background behavior.
- [ ] Implement fresh-profile staging, whole-batch commit/rollback and restart recovery without overwriting existing sessions.
- [ ] Add explicit session-backup UI alongside setup backup; show exact platform/provider compatibility and honest failure reasons.
- [ ] Verify corrupted archives, wrong passwords, unsupported schema/types, resource exhaustion, source preservation, isolation and interrupted transfer recovery.

### 4. Prove the user's requirement before deployment

- [ ] Use an authorized test account linked through the official UI. Preserve its source profile.
- [ ] Export and restore into an independent destination; prevent destination access to the surviving source store.
- [ ] Cold restart the application and confirm authenticated access without scanning or code linking.
- [ ] Verify account switching/isolation, supported OS/provider combinations and expected revocation/expiry behavior.
- [ ] Only then enable the feature in a development release and deploy under the user's existing instruction.

## Evidence and source basis

- [Browser prototype](../tests/session_portability/browser/README.md) and [native probe](../tests/session_portability/ios/README.md).
- [Current setup-only verification](SESSION_RESTORE_VERIFICATION.md) remains valid for the installed application.
- [WebCrypto key cloning/export](https://www.w3.org/TR/webcrypto/#SubtleCrypto-method-exportKey): structured cloning is not a portable byte export; nonextractable keys cannot be exported or wrapped for archival. This is a conditional obstacle, not evidence about WhatsApp's actual current key representation.
- [IndexedDB transactions](https://www.w3.org/TR/IndexedDB/#transaction-concept) do not form one transaction across all browser stores.
- [Fetch opaque responses](https://fetch.spec.whatwg.org/#concept-filtered-response-opaque) conceal response bodies; a required opaque cache cannot be faithfully serialized through ordinary page APIs.
- [AndroidX cookie information API](https://android.googlesource.com/platform/frameworks/support/+/705f3e7c73983ddf4d99ed44f98fc2283e86c9e2/webkit/webkit/src/main/java/androidx/webkit/CookieManagerCompat.java) provides attribute-bearing cookies subject to a provider feature check.
