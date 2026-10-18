# Android design verification

Audit date: 18 October 2026. Reviewed candidate baseline: `44df481`; the fixes below are subsequent working-tree changes. **DONE_WITH_CONCERNS:** the Android source and local evidence have been reviewed, but the product is not release-complete.

This review checked the Android clauses in `IMPLEMENTATION_INSTRUCTIONS.md`, the original Word plan's Android engine, lifecycle, security, media, acceptance, risk and device-matrix content, the requirement/acceptance ledgers, native Kotlin sources, manifests, Gradle configuration, unit/instrumentation test sources and retained test results. It does not replace the separate full-document traceability review. Existing `PASS` entries are assessed according to their stated scope, not treated as proof of their entire acceptance scenario.

## Defects found and fixed during this audit

| Finding | Impact and fix | Requirement / acceptance | Evidence |
| --- | --- | --- | --- |
| Android process runtime retained the previous Flutter coordinator's selection counter. | A replacement Flutter engine starts its Dart counter at zero and could receive `superseded` until it caught up with the old counter. Flutter attachment now resets ordering only after invalidating the old attachment and disposing its owner. Activity-only detach retains ordering for the same Dart coordinator. | REQ-05-015; REQ-08-005; REQ-08-011; REQ-08-019; AT-I09 / AT-I10 | `FlutterAttachmentTest.replacementFlutterEngineStartsFreshOrderingWithoutRetainingOldOwner`; failing original and passing corrected XML/logs below. |
| A captured Pigeon handler from a detached Flutter engine could still mutate the shared registry. | Unregistering a handler does not cancel its queued coroutine. Every host API entry now checks an attachment epoch before touching the shared runtime. A removal already persisted before detachment can still complete its durable journal. | REQ-05-015; REQ-07-013; REQ-08-005; AT-I09 | `FlutterAttachmentTest.queuedOldAttachmentMutationCannotChangeTheReplacementRegistry` executes the old captured rename handler: the original implementation changed the alias; corrected implementation returns `staleAttachment` and preserves it. |
| Late detach from an old plugin could invalidate a replacement plugin. | Detach now checks attachment ownership before resetting the runtime or clearing the event sink. Stale Activity callbacks, activity results, platform-host creation and disposal also check attachment ownership. | REQ-05-015; REQ-08-005; REQ-08-024; AT-I09 | `FlutterAttachmentTest.lateOldPluginDetachAndLifecycleCallbacksCannotDetachReplacement` checks replacement API, event sink and view owner survive late old detach. |
| File-picker launch-error path bypassed the safe completion helper. | If the system picker failed to launch and its renderer callback threw, error recovery escaped as an exception. The path now uses `finishPicker`, which clears the owned transfer and emits completion even when delivery throws. Immediate chooser rejection also uses protected delivery. | REQ-08-021; REQ-12-009; REQ-12-010; AT-M02 | `PickerCompletionTest.missingPickerAndThrowingCallbackStillFinishTheOwnedTransfer` failed against the original catch path, then passed with exactly one cancellation and zero surviving transfer rows. |

Implementation references:

- `packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt:77`: `attachFlutterHost`; line 84 owner-bound detach; line 280 chooser error path; line 322 `finishPicker`.
- `packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AttachedSessionHostApi.kt:14`: guards all 20 host API methods.
- `packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/SessionEnginePlugin.kt:34`: binding ownership and platform-view dispatch; line 48 owner-bound engine detach; line 64 guarded Activity callbacks.

The regression tests exercise actual native plugin/Pigeon dispatch and SQLite through Robolectric API 29. They use reflection to establish prior private generation/owner state without creating a real renderer. They do not prove physical-device frame timing, real WhatsApp behavior or OS picker UI behavior.

## Native requirement checklist

`[x]` means the implementation and the specifically described local evidence were verified. `[ ]` identifies a required behavior or validation matrix that remains incomplete. A checked source boundary does not turn an unchecked device/service test into a pass.

| Check | Requirements | Verification and remaining scope |
| --- | --- | --- |
| [x] Real Kotlin plugin, typed Pigeon contract and native platform host | REQ-05-015; REQ-07-001–012 | Real registration and native calls exist; source, compilation and Flutter/native shell evidence are present. The attachment defects above were repaired. |
| [x] Correct stack and platform baselines | REQ-02-008–009; REQ-10-001 | Product minimum API 29; target API 36; AndroidX WebKit 1.17.1 pinned. Minimum API is distinct from provider support. |
| [x] Mandatory runtime profile/deletion gates | REQ-10-002 | `capabilities`, `requireSupported`, allocation/open and resume checks. API35/WebView124 actually rejected allocation because scoped deletion was absent; API36/WebView133 supplied positive coverage. |
| [x] Immediate immutable profile assignment | REQ-08-002; REQ-10-003 | `WebView` is created directly and `setProfile` is its first operation. Configuration/navigation follow assignment; no shared-store fallback or rebinding exists. |
| [x] Profile-scoped managers | REQ-10-004 | Cookies flush through the existing bound profile; cleanup obtains that profile's WebStorage/service-worker settings. No global cookie export. |
| [x] One live production WebView | REQ-08-024; REQ-14-021 | Process runtime has one owner/view, disposes before replacement, rejects another host, and now rejects stale attachment calls. Multi-view isolation probes are test-only. |
| [x] Disposal and renderer recovery | REQ-10-005; REQ-08-007; REQ-08-023 | Stop, detach, destroy and release preserve the named store. Actual Android renderer termination/reopen evidence exists. No global pauseTimers or automatic resend is used. |
| [x] Durable removal stages | REQ-10-006–015 | Native SQLite tracks requested, accessBlocked, clientsDisposed, websiteWipePending, websiteWiped, appDataCleanupPending and containerDeletionPending; completion deletes the row/journal. |
| [x] Tombstones prevent opening/removal races | REQ-10-016; REQ-10-019 | Lifecycle/identity/journal checks precede opening; callbacks require exact eligible owner. Scoped wipe follows owner disposal. |
| [x] Existing-store-only removal | REQ-10-017 | `getProfile` is used for wipe, never `getOrCreateProfile`; absent store completes idempotently. |
| [x] Cancel/destroy target-owned clients | REQ-10-018 | Active target removal disposes the view and its picker before wipe. A late chooser cannot deliver to another owner. |
| [x] Actual scoped wipe completion | REQ-10-020 | `WebStorageCompat.deleteBrowsingData` callback advances the journal; 30-second timeout retains pending state. Existing synthetic wipe evidence checks target stores and neighbors. |
| [ ] Full failure/interruption matrix | REQ-10-021; AT-D05; AT-D06 | Error paths and deferred-stage clean-process restart exist, but termination at every journal boundary and actual disk-full/native failure injection have not all run. This remains local QA work, not a successful full acceptance case. |
| [x] App-owned cleanup | REQ-10-022 | Target permissions, transfers, observations and staging are cleared separately. No persistent URI grants are acquired. Full system picker/export integration remains unverified. |
| [x] Separate final container deletion | REQ-10-023 | Loaded containers remain pending until a clean process; slot release follows successful scoped wipe plus app cleanup. |
| [x] Startup before target loads | REQ-10-024–025 | Public inventory and tombstones are reconciled before a target getter; exact canonical UUID/store identity and journal ownership are required. Separate-process native evidence confirms target absence with neighbor retention. |
| [x] Loaded-profile/default-store restrictions | REQ-10-026; REQ-10-028 | Actual API36 assertion covers loaded-profile restriction. Default profile is never a legal app row/store pair; unknown inventory is quarantined/count-only. |
| [x] Deletion result scope is honest | REQ-10-027 | Production treats nonthrowing delete or already-absent inventory as terminal container removal. It does not infer a separately observed website-wipe callback or forensic erasure. The Boolean is not separately recorded; `containerDeletionAccepted` also labels the already-absent path. This is a naming limitation, not evidence that an absent store still exists. |
| [x] Bounded service-worker deletion probe | REQ-10-029; AT-D07 | A bounded active-worker write burst was actually tested. Network blocking is not proof all worker JavaScript stopped; the API is non-atomic against writes. Broader providers remain open. |
| [ ] Actual capability disappearance and return | REQ-10-030; AT-D14 | Unsupported-provider startup and pending cleanup source paths are covered; replacing a provider in a live controlled installation and restoring support is not yet validated. |
| [x] No unsafe fallback | REQ-10-031 | No forced app kill as cleanup UX, browser-database editing, all-profile wipe, ten-process fallback, or shared default account storage. |
| [x] Transactional capacity and immutable identity | REQ-06-002; REQ-06-010–015 | SQLite reserves before native allocation; normalization/40-codepoint rules, ten-slot bound, replacement ID, rename/reorder identity, matching tombstone and ten deferred-container cap have unit evidence. |
| [ ] Long churn and allocation fault injection | REQ-06-011; REQ-06-015; AT-D11 | The backlog cap is tested; sustained create/remove inventory churn and every reservation/native-allocation interruption point still require execution. |
| [x] State dimensions remain separate | REQ-07-014–023 | Store/view/auth observation/network are independent. Network path and page readiness are not labeled login or account identity. Cleanup events have independent operation ownership. |
| [x] Latest owner and native cover checks | REQ-08-003–006; REQ-08-011–019 | Profile/view/operation/generation plus eligibility are checked before reveal; attachment epoch now scopes caller lifetime. Unit tests and synthetic switching evidence exist. |
| [ ] Physical wrong-frame visual proof | REQ-14-024; AT-S03 | Unit/synthetic evidence does not establish zero wrong-account frames across real device compositor, rotation and lock timing. |
| [x] Callback completion under native error | REQ-08-021; REQ-12-009–010 | Picker task retains original owner; cancel/dispose/removal and launch failure use safe callback cleanup. New actual launch-error regression passes. |
| [x] Navigation/security boundaries | REQ-12-001–007 | Exact HTTPS host/443 with no user-info; user-gesture HTTP(S) links use system browser, telephone links dial, unhandled schemes and popup creation are denied. TLS is canceled, mixed content blocked, Safe Browsing enabled, file access disabled; no native JS bridge. Capture/location are denied. |
| [ ] Real redirect, adversarial frame and transport matrix | AT-S04–06 | URL-policy unit checks are not real browser-route, malicious-frame or invalid-TLS/mixed-content native delegate tests. Test fixture network/file fetch is not a production chooser/download callback. |
| [x] Scoped file-selection mechanism | REQ-12-013–015 | ACTION_OPEN_DOCUMENT returns content URIs to the original owner; no full attachment bytes in Dart, base64 bridge, cookie export or persistent grant. Official website enforces its own limits. |
| [ ] Full uploads and edge cases | REQ-12-011–012; AT-M01–05 | No authorized real WhatsApp attachment delivered. Native/cloud picker cancel, revoked-access, large/zero-byte and low-space integration matrix remains open. |
| [ ] Required Android download/save/share | REQ-12-016–018; REQ-12-020–021; AT-M08–10 | `DownloadListener` deliberately reports `downloadUnsupported`. Both authenticated HTTP and blob/decrypted export are absent. This is an essential release gap, not a conditional feature waiver. |
| [x] Conditional capture remains disabled | REQ-12-024; AT-M06–07 | Camera, microphone, voice and calls are not offered as working features; no baseline camera/microphone/contacts/SMS/location/notification permission is requested. |
| [x] App-lock and preview mechanisms | REQ-13-002–003 | OS authentication with device credential fallback, enable-time authentication, epochs, opaque cover before pause and FLAG_SECURE exist. |
| [ ] Full authentication/snapshot matrix | AT-S01–02 | No-credential, real lockout, enrollment change, OEM snapshot and physical return timing are not fully validated. |
| [x] Restore trust and backup configuration | REQ-13-004–006 | Nonexportable Keystore HMAC plus excluded installation nonce; unknown restored registry is quarantined. Legacy and cloud/device-transfer exclusion XML exist, in addition to allowBackup=false. |
| [ ] Actual upgrade/restore/transfer behavior | REQ-06-016; REQ-13-005–006; AT-D12; AT-S12 | Provider-managed store behavior on actual restore/transfer/reinstall and same-install upgrade is not established by configuration or helper tests. |
| [x] Diagnostics and production exclusions | REQ-07-024; REQ-13-007–009 | Allowlisted share payload is directly tested with synthetic secret markers; source/artifact checks exclude known test APIs, integration plugin and debug entry points. |
| [ ] Signed active-page inspection/log proof | AT-S07–08 | Bounded candidate log scan and empty welcome `/json/list` are narrower than active WebView inspection and signed physical runtime coverage. |
| [x] Synthetic storage/performance evidence | REQ-14-001–003; REQ-14-008; REQ-14-022 | Ten profiles, six storage mechanisms, bounded worker removal, BroadcastChannel, HTTP cache, WSS identity, process/reboot, renderer failure and 200 selections have retained Android evidence. SharedWorker was unavailable and skipped, not passed. |
| [ ] Real account/device/performance matrix | REQ-14-009; REQ-14-012; REQ-14-016–020; REQ-14-023–026 | No ten real linked accounts, physical baseline/OEM matrix, combined host+renderer resource measurement or repeated production p95 device benchmark. |
| [ ] Elapsed retention and beta soak | REQ-14-015 | Seven-day and fourteen-day periods have not started. Synthetic storage retention is not elapsed WhatsApp retention. |
| [ ] Final release and service gates | G1; G2; G5; G6; AT-S11–12 | Distribution/service basis, actual embedded compatibility, essential Android media support, signing and final review package prerequisites remain separate. Local compilation does not establish them. |

## Evidence rerun for these fixes

Command from `apps/mobile/android`:

```sh
JAVA_HOME=/opt/homebrew/opt/openjdk@17 ANDROID_HOME=/Users/LOCAL_USER/Library/Android/sdk \
  ./gradlew :session_engine:testDebugUnitTest :session_engine:lintDebug --console=plain
```

Final run: **18 native unit tests, 0 failures, 0 errors, 0 skipped; lint 0 errors and 14 warnings.** The warnings remain dependency/style suggestions and runtime feature-gate analysis limitations. The Robolectric API29 tests run on JDK17; its SDK36/JDK21 warning does not mean these tests executed on API36. Evidence directory placement under `api36` groups the candidate's existing Android evidence and must not be read as the unit test's device target.

- `evidence/android/api36/attachment-audit-before-fix.txt` and `.xml`: both original lifecycle failures retained.
- `evidence/android/api36/attachment-audit-after-fix.xml`: all three attachment regressions after final fix.
- `evidence/android/api36/picker-audit-before-fix.txt` and `.xml`: original chooser exception retained.
- `evidence/android/api36/picker-audit-after-fix.xml`: corrected cancellation/cleanup regression.
- `evidence/android/api36/audit-final-native-checks.txt`: final suite and lint run.

The integrated production rebuild and artifact checks now pass; see [current package verification](evidence/design-audit/final-package-verification.json) and [whole-design checklist](DESIGN_VERIFICATION_CHECKLIST.md). Earlier candidate checks remain valid historical evidence for their original hashes; the new evidence identifies the changed sources and artifacts.

## Checklist interpretation and next actions

Keep `AT-I09`, `AT-M02` and related requirement entries scoped to the actual new regressions; do not promote their complete native/physical matrices to PASS solely because these tests pass. Add this audit to evidence for REQ-05-015, REQ-07-013, REQ-08-005, REQ-08-011, REQ-08-019, REQ-08-021, REQ-08-024 and REQ-12-009–010.

The current requirement ledger's scoped `PASS` values for REQ-10-021 and REQ-10-030 should be read with their explicit missing fault/provider transition procedures. The complete checklist must leave those procedures unchecked. The same applies to upload completion, physical privacy timing and restore behavior. No source review can convert those unexecuted cases into observed passes.

Durable finding: a process-persistent native engine and a Flutter-engine-persistent command channel have different lifetimes. Reset selection counters only at an explicit authenticated attachment boundary; reject old queued host calls and late detach/lifecycle callbacks while retaining already-started journal completion.
