# Whole implementation verification checklist

18 October 2026, Asia/Kolkata. **Audit complete; implementation partially complete; release blocked.** The repository implements the shared shell and both real native engines, and the bounded local checks below pass. It does not yet meet the original design's complete definition of done. Checked boxes describe the exact work stated beside them, never an implied full device or service pass.

Subsequent iPhone follow-up: development release0.1.0 (2) is installed with native desktop-viewport fitting and a user-approved Safari identification trial limited to the development bundle. Physical preauthentication comparison confirms full-width rendering and the standard identifier reaches Continue in browser. See [compatibility observations](COMPATIBILITY.md), [deployment evidence](evidence/ios/viewport/physical-development-install-build2.json) and [current resume notes](RESUME.md). Actual pairing/messaging and the broader acceptance gates remain open. The audit's unsigned candidate manifest below predates these viewport changes and is historical, not the current device-build snapshot.

This audit compares the original [Word plan](../WhatsApp_Web_Android_iOS_Application_Plan.docx) and the retained [implementation prompt](IMPLEMENTATION_INSTRUCTIONS.md) against source, tests, artifacts and recorded failures. Baseline Git HEAD is `44df481c7ae8b0e74f9b0d816e45f5bcc1502e7d`; the audit adds uncommitted source fixes and documents. The current candidate manifest records the working-tree file hashes. Its HEAD field alone does not identify those changes.

## Complete source coverage

- [x] Preserve the original DOCX unchanged: SHA-256 `61ba18db9beb2fac9be2e13928c82d4bb933441f3bb2e73ab66834e81494968d`.
- [x] Map all 337 nonempty Word paragraphs, across 358 paragraph positions, in 52 topic groups. Map all 21 tables, including all 214 data rows and 21 headers; retain 52 phase checklist bullets, 13 risks and 36 source IDs / 37 hyperlinks. See the [complete Word crosswalk](DESIGN_DOCUMENT_TRACEABILITY.md).
- [x] Preserve and disposition all 374 original prompt clauses, with exact source text, implementation status, validation scope, code, evidence, acceptance references, owner and next action. See the [complete prompt checklist](PROMPT_VERIFICATION_CHECKLIST.md) and [requirements CSV](requirements.csv).
- [x] Preserve and disposition all 70 original acceptance scenarios and expected outcomes. The [checklist's acceptance appendix](PROMPT_VERIFICATION_CHECKLIST.md#15-complete-acceptance-catalog) and [acceptance CSV](acceptance.csv) include the full cases and remaining procedures.
- [x] Add [automated traceability verification](../scripts/check_traceability.py) to [the standard check command](../scripts/check.sh). It independently checks prompt extraction, immutable source tuples, exact acceptance text, Word hash/anchors, table rows, source links, case references and generated Markdown freshness.
- [x] Review Android and iOS independently, reproduce defects before fixing them, retain failed evidence, cross-review changes, rebuild production artifacts and verify the resulting package.
- [x] Prepare a concrete [store review draft](STORE_REVIEW_PACKAGE.md) and [fifteen labeled fictional shell previews](release-assets/README.md). These are draft shell assets; they do not demonstrate paired accounts, service features or physical devices.

Coverage is not fulfillment. The 374 rows include rationale and procedure as well as executable requirements; percentages based on their count would misrepresent product completion. The checker does not certify semantic implementation, every referenced assertion, or runtime behavior.

| Requirement implementation disposition | Rows |
| --- | ---: |
| Implemented source | 199 |
| Completed local workflow | 32 |
| Documented decision/procedure/artifact | 72 |
| Partial | 45 |
| External dependency | 20 |
| Required exclusion / disabled conditional feature | 6 |
| **Total** | **374** |

Validation dispositions: 310 scoped PASS, 22 NOT_RUN, 18 BLOCKED_HARDWARE, 16 BLOCKED_SERVICE_ACCESS, 2 PENDING_ELAPSED_TIME and 6 NOT_APPLICABLE_WITH_REASON. A scoped PASS does not change a PARTIAL implementation into a completed requirement.

| Acceptance disposition | Cases |
| --- | ---: |
| PASS_LOCAL | 4 |
| PASS_SYNTHETIC | 8 |
| PASS_UNIT | 5 |
| PARTIAL | 40 |
| BLOCKED_SERVICE_ACCESS | 8 |
| PENDING_ELAPSED_TIME | 1 |
| CONDITIONAL_DISABLED | 2 |
| OPEN_RELEASE_GAP | 1 |
| BLOCKED_RELEASE_AUTHORIZATION | 1 |
| **Total** | **70** |

AT-M03 is PARTIAL: the new native picker regression passes, while the complete OS-picker/device/service matrix remains open. REQ-12-014 is PARTIAL / NOT_RUN for its full cleanup-on-success clause. REQ-12-016 now correctly records existing progress UI and unverified download flows.

## Source and bounded local behavior

| Check | Result and precise boundary |
| --- | --- |
| [x] Flutter architecture and native integration | Flutter/Riverpod shell, typed Pigeon bindings, real Kotlin/Swift plugins, native SQLite authority and one live production WebView. Actual integrated shell runs exist on both platforms; the final iOS run was repeated after this audit's changes. |
| [x] Ten-slot identity and lifecycle source | Transactional reservation, immutable profile IDs, retained incomplete setup, alias/reorder, missing-store quarantine, relink, tombstones, cleanup retry and startup reconciliation. See [architecture](ARCHITECTURE.md), native audits and registry tests. |
| [x] Selection, attachment and callback ownership | Profile/view/operation/generation checks, covered transitions, owner-bound callbacks and stale event rejection. This audit adds Flutter attachment boundaries and actual native picker/detach regressions. Physical compositor and all interruption sequences remain unproved. |
| [x] Android profile architecture | API 29 minimum plus runtime MULTI_PROFILE and DELETE_BROWSING_DATA gates; immutable profile assignment before navigation; profile-scoped wipe and deferred clean-process container deletion. Existing provider-positive and provider-negative fixtures have distinct results. |
| [x] iOS profile architecture | iOS 17 minimum; persistent named WKWebsiteDataStore; public inventory/removal, disposal, retained deletion failures and retry. Existing hosted isolation evidence remains narrower than the complete lifecycle matrix. |
| [x] Shell and account UX | Welcome, selector, management, add/rename/reorder/remove, explicit retained setup, recovery, relink, help, compatibility, privacy and lock. English ARB, semantics, large-text/tablet widget checks, light/dark theme and original branding exist. |
| [x] Security boundaries in source | Exact official main origin, OS-routed external links, denied unvalidated capture permissions, no generic privileged JS bridge, cookie/session export or arbitrary production URL. Native locks/covers, installation-bound trust, quarantine and backup exclusions are implemented. |
| [x] Foreground media mechanisms | Android content-URI chooser; iOS private staged uploads, WKDownload/progress/cancel and explicit share source. Full successful service media acceptance remains open; essential Android downloads are absent. |
| [x] Privacy and release infrastructure | Technical diagnostic allowlists, production/test dependency separation, packaged privacy/backup configuration, build scripts, pinned dependencies and prepared CI. Store privacy declarations and final signed runtime behavior remain separate checks. |
| [x] Synthetic evidence catalog | Existing two/ten-store isolation, middle removal, fresh replacement, normal lifecycle process/reboot, channel/transport checks and 200-selection stress recorded in [Android evidence](ANDROID_EVIDENCE.md) and [iOS evidence](IOS_EVIDENCE.md). Those broad fixtures were reviewed, not all rerun in this audit. |

The full platform checklists distinguish each source assertion from unfinished native/device validation: [Android](ANDROID_DESIGN_AUDIT.md) and [iOS](IOS_DESIGN_AUDIT.md).

## Defects repaired and validation executed for this audit

| Finding | Repair and verification |
| --- | --- |
| Android replacement Flutter engine inherited obsolete selection ordering | Reset ordering at the attachment boundary after invalidating and disposing the prior owner; preserve ordering for Activity-only changes. Failing and passing native regressions retained. |
| Queued Android calls and late detach/lifecycle events could affect a replacement attachment | Guard all host API entry points and plugin/view/activity ownership with an attachment epoch. Already-persisted durable cleanup remains allowed to finish. Three attachment regressions pass. |
| Android picker launch-error recovery could throw through its completion callback | Use protected exactly-once completion and transfer cleanup even when callback delivery throws. Native launch-error regression passes. |
| Delayed iOS picker A callback could cancel or deliver through picker B | Require exact controller identity before mutation or file delivery. Actual UIKit picker objects/callbacks and synthetic file bytes/destinations are exercised. Original failures are retained. |
| iOS plugin registration survived Flutter detachment and could reject a replacement | Publish detach ownership, cancel owned transient work, drain durable cleanup, unregister old channels/observers and permit replacement registration. Guard old host calls, queued lifecycle work and post-await ownership. Final native harness passes 24 assertions. |

| Executed check | Result | Evidence |
| --- | --- | --- |
| Standard check command after changes | PASS: 25 coordinator, 18 facade, 7 widget, 17 HTTPS fixture and 32 QA-runner safety tests; four-package format/analyze, production source exclusions and new traceability checks | [final shared log](evidence/design-audit/final-shared-checks.log) |
| Generated Pigeon / ARB drift | PASS, regenerated content identical | [generator log](evidence/design-audit/generated-sources.log) |
| Android native regressions and lint | 18 tests, 0 failures/errors/skips; lint 0 errors / 14 existing warnings | [native log](evidence/android/api36/audit-final-native-checks.txt), [scope and pre-fix failures](ANDROID_DESIGN_AUDIT.md) |
| iOS production-plugin native fixture | 24 assertions PASS on owned iOS 27 simulator; source hashes checked before/after compilation and completion | [result](evidence/ios/engine-picker-detach-final-24-pass.json), [source snapshot](evidence/ios/engine-picker-detach-final-source-snapshot.json) |
| Final real Flutter/native iOS integration | 1 test PASS_LOCAL: cold shell, allocate, fixed official URL open, detach, keep setup and scoped removal; 198 source hashes match; both fixture identities removed and owned simulator deleted | [result](evidence/design-audit/ios-shell-final.json), [log](evidence/design-audit/ios-shell-final.log) |
| Android optimized production APK | Build PASS, unsigned | [build log](evidence/design-audit/android-production-build.log) |
| iOS optimized production device app | Build PASS, unsigned | [build log](evidence/design-audit/ios-production-build.log) |
| Actual production artifact inspection | PASS: packaged configuration, AOT, bounded known fixture/plugin markers, mapped DEX inventory and expected unsigned state | [inspection JSON](evidence/design-audit/release-artifact-checks.json) |
| Candidate packaging | Matching Runner/App/Flutter dSYM UUIDs, archive integrity, source snapshot and artifact hash verification | [manifest](evidence/design-audit/local-candidate-manifest.json), [verification](evidence/design-audit/final-package-verification.json) |
| Draft shell previews | Fifteen current widget renders, visibly labeled fictional profiles, plus finite motion previews; visually inspected | [current UI verification](UI_MOTION_ENHANCEMENT.md), [asset manifest](release-assets/manifest.json) |

The iOS focused fixture uses registrar/messenger/presentation doubles and does not prove an actual Flutter-engine destruction/recreation cycle or an upload to WhatsApp. Its expanded registry initialization attempt failed in the fixture and is preserved, along with intermediate runner/launch failures. The passing standard Flutter integration independently covers actual shell/native registry/open/removal. No service account was paired or messaged. Previously recorded Android runtime smoke, storage/stress runs and iOS 27/29-test suites are historical evidence, not claimed as new reruns.

## All delivery phase exits

| Phase | Locally completed work | Original exit still open |
| --- | --- | --- |
| 0 — Feasibility | [x] Public native profile engines, capability rejection, two/ten-store fixtures, selected architecture and retained findings | [ ] G1/G2 evidence, real small-phone pairing/chat/files, full baseline resource/usability comparison and seven-day retention |
| 1 — Foundations | [x] Modules, registry, typed bridge, test-only fake, flavors, dependencies, local checks and CI configuration | [ ] Remote CI execution and final release signing ownership/configuration |
| 2 — Lifecycle | [x] Allocation, switching, relink, teardown, scoped cleanup, reconciliation and native attachment fixes | [ ] Ten real linked accounts and complete device/provider/upgrade/restore/interruption matrix |
| 3 — Media, privacy and usability | [x] Owned picker paths, iOS download source/progress, app lock, navigation rules, responsive shell and disclosure draft | [ ] Essential Android downloads, iOS successful-upload cleanup policy, actual media delivery/share, accessibility and physical privacy/usability matrix |
| 4 — Hardening and beta | [x] Race/identity/privacy fixes, local test/build/artifact checks and documented failures | [ ] Remaining native fault matrix, physical p95/whole-app resource evidence, signed migration and actual fourteen-day beta |
| 5 — Release preparation | [x] Unsigned package/symbols, concrete listing/disclosure/reviewer draft, fictional shell previews, support/incident/rollback procedures | [ ] Final identity/URLs, permission/distribution evidence, truthful release screenshots, reviewer accounts, final disclosures, signing, submission and staged rollout authorization |

No complete product-phase exit is inferred from the fact that independent local work in later phases was authorized and executed.

## All design gates

| Gate | Current result | Closure evidence |
| --- | --- | --- |
| G1 — Service authorization | [ ] Open | Product/release owner supplies a reviewable permitted test/distribution basis and required website permissions. |
| G2 — Embedded compatibility | [ ] Open | Authorized QR linking and basic text/photo/document use on declared minimum/current devices; retain failed platforms honestly. |
| G3 — Ten-profile isolation | [x] Synthetic scenarios; [ ] complete gate | Existing same-origin ten-store evidence plus ten actual account identities, correct visible account and full supported device matrix. |
| G4 — Session lifecycle | [x] Source/local scenarios; [ ] complete gate | Full native interruption/provider/restore/upgrade/reconnect/deletion matrix, including unresolved abrupt-termination evidence. |
| G5 — Phone usability | [ ] Open; required download gap | Small phone QR/chat/composer/keyboard/files, zoom/accessibility, supported Android download path and actual iOS media behavior. |
| G6 — Distribution readiness | [x] Local draft package; [ ] complete gate | Final identity, support/privacy URLs, accurate declarations/screenshots, reviewer access, permission evidence and signed distribution checks. |

## Remaining work, owners and acceptance criteria

These are unfinished work items, not all external blockers. Native fault injection and device-independent investigation can continue locally; hardware, service credentials, elapsed days and release identities cannot be replaced with synthetic evidence.

| Open item | Owner | Required next action and proof |
| --- | --- | --- |
| [ ] Android authenticated HTTP/blob/decrypted download, save and share | Native engineering + product owner | Implement a supported public context-preserving path without credential export, arbitrary JS bridge or default-profile fallback. Validate AT-M08–M10 against actual authenticated/decoded media and cancellation. An explicit unsupported result does not fulfill the required feature; a scope change would need a revised design. |
| [ ] iOS cleanup after successful upload, REQ-12-014 | Native engineering + product owner | Establish a public browser-safe post-consumption cleanup policy, or record an explicit retention/scope decision. Current files survive until bound-view disposal, profile removal or startup; returning picker URLs is not upload completion. Test deferred reads, cleanup and cross-profile isolation without deleting data prematurely. |
| [ ] Native media end to end | Native engineering + device QA | Execute real OS/Photos/cloud/document picker and WKDownload HTTP/blob/share callbacks, byte integrity, cancel/switch/remove, revoked grants, zero-byte/large/low-space handling and iPad presentation. Fetch-based fixture hashes do not satisfy these paths. AT-M01–M05/M08–M10. |
| [ ] Native lifecycle and fault matrix | Native engineering + QA | Inject each reservation/allocation/cleanup-journal interruption and disk/wipe error; exercise prolonged churn, service-worker updates, provider capability loss/return and queued engine replacement. Induce actual iOS WebContent termination. Retain original abrupt-termination mismatch until diagnosed. AT-I03/I09–I14; AT-D05/D06/D09/D11–D14. |
| [ ] Authorized ten-account service coverage | Product owner + account owners + device QA | Supply authorized primary devices/accounts and consenting recipients, then pair all ten, exchange text/photos/documents, revoke/relink, verify displayed identity and actual linked-device limits. Record minimal redacted evidence and environment. AT-A08; AT-I06/I13; media cases. |
| [ ] Minimum/current/OEM physical matrix | Device QA | Run [compatibility matrix](COMPATIBILITY.md) on actual iOS 17+ iPhone/iPad and Android API29+/supported providers/OEM devices; exercise authentication, snapshots, keyboard, rotation, low memory/storage, network handovers and restore/transfer/reinstall. |
| [ ] Accessibility and measured performance | Device QA | VoiceOver/TalkBack, focus/large text, phone/tablet layout, repeated production selector <150ms / startup <2s / covered context <300ms / website usability <5s p95 measurements. Measure host plus WebContent memory, thermal/battery and one-profile baseline; fixture navigation timing and one startup sample are insufficient. |
| [ ] Actual 7-/14-day retention | Retention QA + account owners | Start authorized runs, preserve real start/end timestamps and daily observations; no run has started and simulated clock changes are not accepted. AT-I15. |
| [ ] Signed security and migration validation | Release engineering + device QA | Configure the eventual release identity; validate same-signature upgrades, entitlements, provisioning, backup/restore, active-view inspection disabled, technical-only logs/share diagnostics and signed runtime smoke. AT-S01–S08/S12. |
| [ ] CI and dependency closure | Engineering/release owner | Provision repository/runner and execute prepared CI; review full native/buildscript/composite dependencies, advisories and licenses. Module locks and a local build do not establish complete provenance or legal review. |
| [ ] Final store package and operating identity | Product/release owner | Finalize name/trademark/operator/contact, public privacy/support URLs, website-inclusive disclosures, validated feature screenshots, reviewer procedure/access and distribution basis. Use [store worksheet](STORE_REVIEW_PACKAGE.md); fictional shell previews remain drafts. |
| [ ] Signed release, submission and rollout | Release owner | Close required gates, inspect exact signed outputs, obtain the final distribution decision, submit and monitor the agreed rollout. No upload, publication or submission was performed. |

Camera, microphone, calls and voice remain conditional-disabled. Inactive notifications, automated/background messaging, session import/export, scraping, privileged page bridges and an unofficial messaging protocol remain excluded as specified; they are not remaining baseline features to add.

## Reproduction and evidence integrity

Run from the repository root:

```sh
./scripts/check.sh
python3 scripts/check_generated.py
python3 scripts/check_traceability.py
JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./scripts/build_android.sh production release
./scripts/build_ios.sh production device-unsigned
JAVA_HOME=/opt/homebrew/opt/openjdk@17 python3 scripts/verify_release_artifacts.py
python3 scripts/package_local_candidate.py
```

Native runner commands and limitations are in the platform audit documents. The integrated shell runner uses a disposable QA source copy with separate identities; do not restore its integration-test dependency to the production manifest. The native regression and integration simulators used in this audit were removed and fixture cleanup verified.

The current unsigned package is `artifacts/profile-desk-0.1.0-local/`; the previous package was preserved at `artifacts/profile-desk-0.1.0-before-design-audit/`. Current exact hashes and UUIDs are in the linked audit manifest and package-verification JSON. Files under `evidence/build/` remain historical evidence for their recorded source/artifact hashes. Source snapshots record files at packaging or test time; they do not attest compiler inputs, reproducible builds or future signed releases.

Current official Android [ProfileStore documentation](https://developer.android.com/reference/androidx/webkit/ProfileStore) and WebKit's [named profile API guidance](https://webkit.org/blog/14423/building-profiles-with-new-webkit-api/) were rechecked for the public inventory/deletion boundaries used by this design. Preserving all original source links does not mean every time-sensitive policy or source page was revalidated; submission rules must be checked again for the actual release.

Keep the CSVs authoritative for per-row dispositions, regenerate the prompt checklist with `python3 scripts/check_traceability.py --write`, and retain evidence scope when recording future passes. See [REPORT.md](REPORT.md) and [RESUME.md](RESUME.md) for the current handover.
