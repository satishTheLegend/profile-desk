# Profile Desk implementation and verification report

18 October 2026, Asia/Kolkata · local candidate 0.1.0+1

The repository contains a working Flutter shell and real Kotlin/Swift native engines for ten separately stored browser profiles. Both optimized production builds compile. Synthetic native storage tests establish the exercised isolation and deletion behavior on the recorded emulator/simulator configurations. This is a local implementation candidate, not a verified ten-account WhatsApp product or an approved release.

The original Word plan and pasted instructions are retained. The independent design audit now maps all 374 prompt clauses and 70 acceptance cases, plus all 337 nonempty Word paragraphs and 214 data rows in 21 tables. The 37 source hyperlinks remain represented. Start with [the consolidated checklist](DESIGN_VERIFICATION_CHECKLIST.md), [the complete prompt checklist](PROMPT_VERIFICATION_CHECKLIST.md) and [the Word crosswalk](DESIGN_DOCUMENT_TRACEABILITY.md). Source completeness is verified by `scripts/check_traceability.py`; it does not establish requirement fulfillment. Implementation, synthetic validation, actual-service validation and release authorization remain separate facts.

## Source delivered

- Flutter/Riverpod shell with welcome, permanent account selector, responsive management, add/rename/reorder/remove, explicit partial setup retention, relink/replacement, cleanup retry, help, compatibility and privacy settings. English ARB localization, dark/light themes, large-text layouts, semantics and original icons are included.
- Typed Pigeon schema and generated Dart/Kotlin/Swift transport. Native SQLite is the durable authority for identity, preferences, transactional ten-slot reservation, allocation compensation, tombstones and cleanup stages.
- Android API29+ engine requiring runtime MULTI_PROFILE and DELETE_BROWSING_DATA. Permanent profile assignment precedes configuration/navigation. Wipe callbacks advance durable cleanup independently of selection; loaded containers are removed at a later clean process start.
- iOS17+ persistent named WKWebsiteDataStore engine. Inventory/startup cleanup precedes named-profile use. Public deletion failures retain retryable state. A blank ephemeral WebKit bootstrap fixes the observed cold-inventory crash without loading a persistent account store.
- One production WebView, exact profile/view/operation/generation ownership, bounded recovery and late-result reconciliation. Covers prevent stale reveals; missing/restored stores are quarantined instead of silently reassigned.
- Installation-bound restore trust; native OS-authentication lock epochs, foreground/background covers, contextual file selection and exact-origin navigation. Camera/microphone/calls remain disabled. No generic JavaScript privilege bridge, credential export, session import, DOM scraping or arbitrary production URL is exposed.
- iOS bounded private file staging, browser-context WKDownload, progress/cancellation and OS share. Network observation is distinct from authentication/service readiness. Diagnostic export uses a technical allowlist.
- Same-origin HTTPS synthetic fixture, native tests, shared race tests, integrated shell smoke, build/check/generation/artifact scripts, CI configuration, threat model, dependency inventory and operating documentation.

## Delivery phases

| Phase | Local result | Remaining gate |
| --- | --- | --- |
| 0 Feasibility | Native two/ten-store fixtures, capability rejection and real shell integration executed; architecture failures repaired | Authorized real accounts, physical baseline, elapsed retention and essential Android download decision |
| 1 Foundations | Shell, typed contract, native authority, flavors, dependency wiring and check/CI entry points implemented | Remote CI needs repository/runner provisioning |
| 2 Account lifecycle | Reservation, identity, switching, recovery, cleanup and relink management implemented; unit/native coverage recorded | Full physical/provider interruption/upgrade/restore matrix and actual linked-account behavior |
| 3 Media/privacy/usability | Native selection, iOS download, permission/transfer ownership, lock/covers and responsive shell implemented | Android authenticated/blob download remains essential; iOS successful-upload staging cleanup does not satisfy the exact success clause; actual-service media and device usability validation remain open |
| 4 Hardening/beta | Race/privacy/startup defects fixed; local checks, native fixtures and production artifact review executed | Physical resource/lifecycle matrix, signed migration, seven-/fourteen-day soak and unresolved essential media gate |
| 5 Release preparation | Unsigned builds, symbols/mapping, build scripts, store/privacy worksheet, five clearly fictional shell previews and incident/support procedures prepared | Final identity, permission/distribution basis, signing, reviewer access, truthful final screenshots and explicit release decision |

## Builds and tests actually executed

Tested host: Apple silicon macOS; Flutter3.47.5/Dart3.13.4; JDK17; Android SDK36; AndroidX WebKit1.17.1; Xcode27.1. The platform evidence files contain precise command output, versions, failures and narrower context for each run. The design-audit reruns below are distinct from retained earlier native storage and Android runtime evidence.

| Check | Result and evidence |
| --- | --- |
| Formatting/static analysis | Design-audit rerun passes across four Dart packages; `evidence/design-audit/final-shared-checks.log` |
| Shared coordinator |25 tests PASS, including200 seeded switches, stale events, late operations, lock races and network/progress observations |
| Account facade |18 tests PASS, including allocation/event refresh ordering, allocation serialization, retained cleanup and failure recovery |
| Flutter shell |7 widget tests PASS, including small-screen large text and tablet selector semantics |
| HTTPS fixture server |17 tests PASS, including scoped HTTP cache, WSS identity/echo and bounded synthetic file endpoints |
| Generated files | Design-audit Pigeon/localization regeneration identical; `evidence/design-audit/generated-sources.log` |
| Source traceability |374 immutable prompt clauses, all 70 cases, Word 337 paragraphs/214 data rows/37 hyperlinks verified; coverage only |
| Android native helpers | Design-audit 18 tests PASS; lint 0 errors/14 existing warnings. Includes real plugin/Pigeon attachment and chooser exception regressions; `evidence/android/api36/audit-final-native-checks.txt` (Robolectric API29, not API36 runtime) |
| iOS native helpers | Earlier 27 focused macOS and 29 hosted native tests PASS. Design audit adds 24 actual production callback/detach assertions using registrar/presentation doubles; `IOS_DESIGN_AUDIT.md` describes limitations |
| Android native storage | API36/WebView133 ten-store six-mechanism isolation, middle wipe, fresh empty replacement and separate-process deferred deletion PASS; exact stress/renderer evidence in `ANDROID_EVIDENCE.md` |
| iOS hosted storage | iOS27 ten-store fixture with 81 assertions PASS, including BroadcastChannel/SharedWorker controls and public deletion retry; earlier failures retained in `IOS_EVIDENCE.md` |
| Native transport | Android and iOS same-URL HTTP cache, WSS handshake identity and synthetic file byte/hash probes PASS; these fetch probes do not validate native picker/download callbacks |
| Native persistence | Both platforms retained six storage mechanisms in two seeded profiles across normal lifecycle process termination and emulator/simulator reboot; abrupt foreground termination and physical retention remain unproven |
| Native switch stress |200 selections across ten profiles PASS on both platforms; iOS 631 assertions/max one attached view; Android navigation-plus-verification p95 3.187s and iOS 0.661s are fixture timings, not UI/service performance claims |
| Isolated QA runner |32 safety tests PASS; separate pinned test dependencies and disposable app identities protect production builds and existing applications |
| Real integrated iOS QA app | Design-audit iOS27 rerun PASS_LOCAL, 1 test/4s after 40.7s build; 198 copied source hashes match, owned fixture/simulator cleanup verified. `evidence/design-audit/ios-shell-final.json` |
| Real integrated Android QA app | Earlier API36 isolated Flutter/native test PASS in 4s; not rerun after this audit's Android changes. No pairing or page extraction |
| Optimized Android runtime smoke | Earlier candidate only: temporary local test-signed empty-welcome smoke PASS, cold launch 820ms and no page targets. Not rerun on design-audit APK; no active WebView inspection claim |
| Android builds | Design-audit optimized production unsigned APK PASS; `evidence/design-audit/android-production-build.log` |
| iOS builds | Design-audit optimized production unsigned device app PASS; `evidence/design-audit/ios-production-build.log` |
| Release inspection | Design-audit artifacts pass packaged manifest/backup/privacy/AOT/known-test-exclusion and unsigned-state checks; `evidence/design-audit/release-artifact-checks.json` |
| Store draft assets | Five fictional native-shell PNG previews rendered with manifest and store worksheet; `release-assets/README.md`. These are draft previews, not actual WhatsApp screenshots |

Remote CI has not executed. No physical device or service account was used. Native storage, transport, process/reboot and 200-switch results in this table are retained earlier evidence; they were not rerun during the design audit. An official URL open proves native integration only; it is not pairing, authentication, sending or website feature validation. Fixture timings include navigation/storage assertions and cannot be substituted for the plan's selector/startup/website p95 targets. Host-only memory samples cannot prove total WebContent resource behavior.

## Failures and review findings

Failures were preserved instead of overwritten by later passes. Android API35/WebView124 lacks required scoped deletion; the isolation prerequisite fails and the production gate correctly refuses allocation. An initial API36 fixture replacement error had no diagnostic root cause; subsequent isolated/combined passes do not erase it. An initial200-switch attempt timed out during final cleanup and masked the primary error; test reporting was fixed and stress workloads serialized after observed host memory pressure.

iOS unhosted macOS named-store tests failed; the CI path now runs macOS helpers separately and retains a hosted iOS native runner. An integrated iOS26.5 cold-inventory crash was fixed through ephemeral WebKit bootstrap and verified by actual relaunch. Busy WebKit stores can reject public deletion; failures remain retryable. A later SharedWorker-extended fixture passed messaging controls but failed a deletion retry, and its full result remains recorded as FAIL.

The final 81-assertion iOS fixture passed with bounded public deletion attempts: the first attempt was pending and the second completed, preserving the other nine stores. An earlier immediate-termination persistence run mismatched one profile without enough per-store detail to diagnose it. A detailed immediate replay and the normal-background lifecycle run both passed; they do not erase the unexplained failure or prove reliable abrupt-termination retention.

Android process testing exposed cookie persistence loss; the engine now flushes only the bound profile's cookie manager at disposal/background. A later headless fixture could not preserve profile inventory; the corrected fixture uses a real attached Activity and normal lifecycle. Final process/reboot, renderer recovery and clean-process cleanup regressions passed. These results do not establish power-loss or active hard-kill durability.

Production artifact inspection also found Flutter’s iOS integration-test plugin in a release binary. The fixture was moved to an isolated QA source copy, the dependency removed from the production manifest, and the artifact verifier strengthened to reject its actual symbols/channel. Clean production rebuilds pass the stronger checks. Earlier narrower artifact passes remain historical evidence only.

The first Android optimized smoke incorrectly rejected an empty devtools socket; exact-PID endpoint inspection showed no page targets. A later attempt encountered a system-wide emulator ANR. Its screenshot/failure is retained; restarting only the dedicated emulator without wiping data restored responsiveness and the corrected smoke passed. FLAG_SECURE produces a black capture, so welcome verification uses candidate-only accessibility nodes. Flutter also attempted to uninstall a base QA identity instead of the flavored fixture; disposable identities protected production, and the fixture runner now owns cleanup of its proven-new installations.

An earlier isolated iOS run also found a real facade race: profile creation returned while a later pending event read suppressed publication of its completed snapshot. AccountService now orders successful publications rather than requested reads. Two deterministic regressions cover the overlap and a failed newer read, while older-read rollback protection remains tested. The original integration assertion was retained.

Independent reviews fixed authentication epochs/late callbacks, lock fail-closed behavior, picker cleanup, cleanup journal regression, malformed native identity/row handling and per-transfer progress ownership. The release review also corrected Apple CI routing and added the official Gradle distribution checksum. Repository-owned Gradle module locks now accompany the resolved inventory; buildscript/composite verification and advisory review remain distinct. No claim of zero defects follows from the bounded reviews.

The new independent design audit found additional native lifetime defects. Android retained a previous Flutter coordinator's selection generation; captured old Pigeon calls and late plugin detach could mutate or invalidate a replacement, and picker launch failure bypassed safe callback completion. Attachment epochs now guard every host entry and late lifecycle event; ordering resets only at a new Flutter attachment. Original failing native tests are preserved. iOS ignored picker-controller identity and did not publish/detach its process-owned plugin correctly. The corrected engine rejects stale calls, drains transfer/cleanup work before replacement startup and rechecks attachment after async boundaries. Actual native callback regressions and cross-review cover these changes; see `ANDROID_DESIGN_AUDIT.md` and `IOS_DESIGN_AUDIT.md` for exact scope. Both production builds and the iOS isolated shell were rerun after these changes.

## Essential limitations and release decision

**Release is blocked.** Android authenticated HTTP/blob download/save/share has no implemented, verified public context-preserving route. The engine emits an explicit unsupported result; cookie export, arbitrary scripting and hidden default-profile fallbacks were not used. This is an essential product gap, not a waived optional feature. iOS download source is implemented but still needs actual-service validation.

REQ-12-014 also remains partial: successful iOS upload imports retain their private staged files until view disposal, profile removal or startup cleanup. Returning URLs does not establish that WebKit has consumed/uploaded them, and no supported upload-completion callback has been established. Immediate deletion could break deferred reads. The exact cleanup-on-success clause is therefore unfulfilled; the checklist records the actual view-lifetime policy.

No authorized ten-account pairing, text/photo/document exchange, primary-device revocation or device-linked limit test was performed. No seven-/fourteen-day elapsed retention run has started. Minimum/current physical iPhone/iPad/Android/OEM, low-memory devices, accessibility, disk pressure, biometric interruptions, network handovers, backup/restore and signed upgrade testing remain in the acceptance ledger. `COMPATIBILITY.md` distinguishes actual observations from configured minimums.

Profile Desk is a working original name; trademark clearance, legal entity, contact, privacy URL and distribution basis are not supplied. Store submission, external publication, account acquisition and outgoing messages were not performed. Prepared privacy text includes embedded website traffic and is not a no-data-collected claim.

## Artifacts and reproduction

The final production source is built by:

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@17 # Tested host; use your JDK17 installation.
./scripts/bootstrap.sh
./scripts/check.sh
python3 scripts/check_generated.py
./scripts/build_android.sh production release
./scripts/build_ios.sh production device-unsigned
python3 scripts/verify_release_artifacts.py
python3 scripts/package_local_candidate.py
```

Design-audit builds use the working-tree source based on `44df481`, including the native fixes above. They are not binaries of clean commit `3cf85e7`; that earlier candidate and `evidence/build/local-candidate-manifest.json` are historical. New artifact inspection is recorded in `evidence/design-audit/release-artifact-checks.json`. The new package manifest is `evidence/design-audit/local-candidate-manifest.json`, with source snapshot SHA-256 `d562f44961689e728e0fb9b32310770d159b748a064af03363ecc994f2ddb244`.

The local package target is `artifacts/profile-desk-0.1.0-local/`: unsigned Android APK, zipped unsigned iOS device app, native symbols/R8 mapping, and a manifest of exact hashes plus a source snapshot. Build outputs remain under `apps/mobile/build/`. Packaging verifies Runner/App/Flutter dSYM UUIDs and ZIP integrity. The earlier package is retained separately as `artifacts/profile-desk-0.1.0-before-design-audit/`. The current manifest identifies the three packaged outputs and their exact hashes. `evidence/design-audit/final-package-verification.json` passes verification of all 213 source files, artifact/archive bytes, symbol inputs and evidence snapshots. This is package consistency, not compiler-input attestation. These are not store-ready signed releases; do not distribute the ephemeral locally test-signed historical smoke copy as a release.

Native commands and fixture certificate procedures are in `ANDROID_EVIDENCE.md`, `IOS_EVIDENCE.md` and `tests/profile_harness/README.md`. The integrated smoke command is `python3 tests/device_flows/run_shell_integration.py -d DEVICE_ID` from the repository root. It builds an isolated QA source copy; the integration-test SDK plugin is absent from the production application manifest. Apple CI requires the explicit provisioned runner in `.github/workflows/apple.yml`. The original Word source is unchanged.

## Consolidated next dependencies

| Owner | Dependency/action | Procedure/evidence |
| --- | --- | --- |
| Native engineering + product owner | Resolve essential Android download route or make an explicit product scope decision; retain no credential export/JS bridge constraint | AT-M08, ANDROID_EVIDENCE.md |
| iOS engineering + product owner | Resolve or explicitly accept the successful-upload staging lifetime limitation without deleting files before WebKit consumes them | REQ-12-014, IOS_DESIGN_AUDIT.md |
| Product owner + account owners | Supply permitted test/distribution basis, specifically authorized accounts/primary devices and consenting recipients | RELEASE_AND_SUPPORT.md; AT-A08/I06/M01 |
| Device QA | Execute declared physical minimum/current/OEM matrix, lifecycle/files/privacy/accessibility/network/disk-pressure cases and signed upgrade | COMPATIBILITY.md; all70 acceptance dispositions; tests/device_flows/README.md |
| Retention QA | Start and observe actual7-/14-day runs after accounts/devices are available | AT-I15; preserve real start/end timestamps |
| Release owner | Final identity/contact/privacy URL, signing ownership, resolved license/advisory review, reviewer access and release authorization | RELEASE_AND_SUPPORT.md; recheck final signed artifacts and current store requirements |

Every remaining acceptance row records its next action and owner. Preserve local profiles when diagnosing upstream outages; never clear every account as the first recovery step. See `RESUME.md` for the final checkpoint and exact evidence paths.
