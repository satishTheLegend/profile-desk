# Android implementation and evidence

Access/test date: 18 October 2026 (Asia/Kolkata). This is source/build evidence, not WhatsApp service validation or release approval.

## Implemented boundaries

`packages/session_engine/android` is a real Kotlin Flutter plugin using generated Pigeon bindings and a platform-view host. Its process-scoped runtime owns one WebView, one SQLite registry, one active file chooser and the native privacy cover. The WebView is constructed directly; `WebViewCompat.setProfile` is its first operation. No third-party WebView plugin can configure a shared default view first.

Every persisted row/store pair must have a canonical UUID and the exact `profiledesk_` plus row UUID name. Startup, opening and both deletion paths quarantine mismatches before target store access, including corrupt tombstones; they cannot target the default profile or another row’s named store. Registry migrations start at schema 1. Transactions reserve at most ten accessible/reserved slots before native allocation. Aliases are trimmed, compared with locale-independent lowercase, limited to 40 Unicode code points and reject controls. Rename/reorder preserve identifiers. Interrupted allocation reconciles against public inventory. Missing stores remain missing; unknown native stores are counted/quarantined and never reassigned. A nonexportable Android Keystore HMAC key plus an excluded random nonce authenticates installation continuity; unknown restored registries remain quarantined. This is not encryption of browser storage.

Clean startup opens the native journal before any target profile getter. Failed installation provenance suspends inherited startup cleanup. Both native deletion paths require a matching journal operation, exact row/store identity and a row already in `removing` or `cleanupPending`; a corrupt journal pointing at an otherwise available row is quarantined without deleting its store. It enumerates names and asks public `deleteProfile` to remove tombstoned, not-yet-loaded containers. It never targets the default profile. An accepted container deletion does not assert a separately observed website-wipe callback or synchronous physical disk erasure.

In-process removal durably tombstones, disposes owned clients, blocks new service-worker network loads, obtains only the existing named profile, and invokes its scoped `WebStorageCompat.deleteBrowsingData`. Its completion updates SQLite even if Dart has detached or another profile is selected. App-owned permissions/transfers/staging are cleaned separately. The loaded container remains `containerDeletionPending` until a clean process start.

Capacity stays occupied until the actual wipe callback and app cleanup complete. `containerDeletionPending` releases an accessible slot. At most ten deferred containers may accumulate; further adds require an ordinary app restart. Identifiers are never reused.

Native callbacks validate the immutable profile/view/operation/generation. The shared coordinator implements reload by a new view against the same store. Native cover reveal requires an exact eligible owner, committed/visually synchronized content, foreground state and an unlocked app. Lifecycle callbacks apply the cover before Activity pause; `FLAG_SECURE` adds Android preview protection. This is not a universal screenshot-prevention claim. Device-credential/biometric authentication retains the cover on cancellation/failure. Known system picker interruptions are tracked independently.

Enabling app lock now requires successful native device authentication before preferences change. Cancellation leaves the prior setting intact. Native cover/authentication/share labels use Android string resources. Network state is a separate OS observation: a default path with both INTERNET and VALIDATED capabilities is `reachable`, no default path is `offline`, and an unvalidated/captive/unknown path is `unknown`. This neither infers login nor proves service reachability. The process-scoped callback uses supplied capabilities and ignores late loss/capability events for a superseded default network.

Navigation uses parsed exact HTTPS `web.whatsapp.com` (default/443 port), rejects user-info/lookalike hosts, and sends user-initiated external HTTP(S) links to the system. Invalid TLS is canceled; mixed content is prohibited; Safe Browsing remains enabled. Popups cannot allocate another WebView. No JavaScript bridge, arbitrary production scripting, cookie export, or DOM extraction exists. Capture/location requests are denied; microphone/camera/calls are unvalidated conditional features.

Uploads use `ACTION_OPEN_DOCUMENT` and original profile/view ownership; every accepted chooser receives success/cancel once. Selection disposal/removal cancels outstanding callbacks. No attachment bytes enter Dart memory and no persistent URI grants are acquired. Actual WhatsApp attachment behavior remains untested.

## Executed automated evidence

- `:session_engine:compileDebugKotlin`: PASS against AndroidX WebKit 1.17.1, compile SDK 36, JDK 17, AGP 9.1.0, Kotlin 2.4.0.
- `:session_engine:testDebugUnitTest`: PASS, 9 tests, 0 skipped/failures/errors. SQLite tests run with Robolectric API 29; these are not real WebView isolation tests.
- `:session_engine:assembleDebugAndroidTest`: PASS before the expanded HTTPS fixture test; final rerun recorded below.

Command (from `apps/mobile/android`):

```sh
JAVA_HOME=/opt/homebrew/opt/openjdk@17 ANDROID_HOME=/Users/LOCAL_USER/Library/Android/sdk \
  ./gradlew :session_engine:compileDebugKotlin :session_engine:testDebugUnitTest --console=plain
```

Reports: `apps/mobile/build/session_engine/test-results/testDebugUnitTest/` and `reports/tests/testDebugUnitTest/`. Tests cover ten-slot reservation, normalized duplicates, rename identity/color, reorder validation, tombstone durability across reopen, capacity release after wipe, replacement identity, bounded deferred containers, inactive-profile cleanup, and exact-origin rejection.

Dedicated AVD `profile_desk_qa_api35`, serial `emulator-5580`, was created from installed `system-images;android-35;google_apis;arm64-v8a` without modifying the user's existing AVD. Initial provider: `com.google.android.webview 124.0.6367.219`. This is an emulator, not physical hardware. Instrumentation results follow when the run completes.

## Test-only HTTPS fixture

The native instrumentation test accepts an explicit `harnessOrigin` argument; no production contract accepts URLs/scripts. The test APK trusts a generated, short-lived public CA for exactly `10.0.2.2`. Production has no custom trust anchors, arbitrary fixture URL, or evaluation bridge. The CA private key stays in the temporary fixture directory. Refresh the public certificate resource before every run:

```sh
packages/session_engine/android/prepare_harness_certificate.sh /absolute/path/to/ca.pem
cd apps/mobile/android
JAVA_HOME=/opt/homebrew/opt/openjdk@17 ANDROID_HOME=/Users/LOCAL_USER/Library/Android/sdk \
ANDROID_SERIAL=emulator-5580 ./gradlew :session_engine:connectedDebugAndroidTest \
  -Pandroid.testInstrumentationRunnerArguments.harnessOrigin=https://10.0.2.2:8443/ --console=plain
```

The instrumentation test verifies an initially empty six-store HTTPS origin, then unique synthetic markers in ten named profiles: readable and server-verified HttpOnly cookies, localStorage, IndexedDB, Cache Storage and service-worker cache. It destroys/recreates each view, wipes a middle profile, checks adjacent profiles, allocates a fresh replacement and asserts the provider's loaded-profile deletion restriction. It never uses WhatsApp content or accounts. Test-only destructive reopening is not a production tombstone path.

## Known release gaps

`downloadsSupported` and `captureSupported` are explicitly false. Android's public `DownloadListener` exposes a URL and metadata, not browser-owned decrypted/blob bytes. No verified browser-native blob export route was found in the public APIs reviewed. The implementation emits `downloadUnsupported`; it does not use cookie export, arbitrary page scripting/base64 extraction or a second default-profile view. Essential photo/document download/save/share therefore remains a release gap, not a passed or waived requirement. Authenticated ordinary HTTP downloads also remain disabled until a supported scoped mechanism is verified.

Physical device lifecycle/composition, file-picker interruption, biometric fallback, OS/provider updates, actual restore/transfer, disk pressure, broader service-worker write races during deletion, device performance and app-store requirements require further evidence. No real accounts were linked or messages sent. Seven-day/fourteen-day elapsed checks have not started. The service/distribution basis remains external. The resumed 200-switch synthetic run is reported separately below; it cannot substitute for real-service or physical-device performance.

## Primary references and resulting decisions

All accessed 18 October 2026:

- [AndroidX WebKit releases](https://developer.android.com/jetpack/androidx/releases/webkit): stable dependency 1.17.1; runtime feature support remains independent of library/API level. Google Maven resolved the exact artifact.
- [ProfileStore](https://developer.android.com/reference/androidx/webkit/ProfileStore): enumeration includes default; getters load profiles; loaded profiles cannot be deleted in-process; `true` accepts deletion and some cleanup is asynchronous, `false` means absent. Use the startup journal before getters and preserve separate wipe/container states.
- [WebViewCompat](https://developer.android.com/reference/androidx/webkit/WebViewCompat): bind the named profile before other WebView operations; assignment can create an absent store, so registry/inventory eligibility must be checked first.
- [WebStorageCompat](https://developer.android.com/reference/androidx/webkit/WebStorageCompat): profile-specific deletion includes cookies/cache/JavaScript-readable data, completes by callback and is not atomic against concurrent writes. Dispose clients first, block new worker network activity, retain limitations pending instrumentation.
- [FileChooserParams](https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams): use scoped system selection and an exactly-once callback; direct capture remains gated.
- [BiometricPrompt.Builder](https://developer.android.com/reference/android/hardware/biometrics/BiometricPrompt.Builder): public device credential fallback on API 29; API 30+ authenticator constants availability checked.
- [DownloadListener](https://developer.android.com/reference/android/webkit/DownloadListener): callback only signals a download; it does not provide a general authenticated blob byte-stream exporter. Missing safe route remains a stated product gap.
- [Read network state](https://developer.android.com/develop/connectivity/network-ops/reading-network-state): wait for callback capabilities rather than querying synchronously inside availability callbacks; a captive path lacks VALIDATED. The implementation separates OS path observation from service/authentication state.

## API 35 emulator results

- Full six-store isolation scenario: **BLOCKED_ENVIRONMENT** after actual prerequisite assertion failure, because WebView 124.0.6367.219 lacks `DELETE_BROWSING_DATA`. `MULTI_PROFILE` was present. No test profile was allocated before the failure. Raw executed-test failure is preserved in `docs/evidence/android/api35-unsupported/instrumentation.xml`; the requested storage guarantees are not passed on this provider.
- Production capability gate: **PASS**. A separate instrumented test instantiated `AndroidSessionEngine`, verified capability flags, attempted allocation and received `unsupportedProvider` without increasing registry count, then exercised cleanup management. Evidence: `docs/evidence/android/api35-unsupported/capability-gate-pass.xml`.
- To seek positive storage coverage without changing the user's existing API 35 AVD/image, installed a separate official API 36 system image for a dedicated QA AVD. Result recorded below when complete.

## Review fixes

An independent source review checked native startup ordering, profile binding, cleanup ownership and privacy. It found two defects that were fixed before the final native test rerun: manual lock could throw before covering when device authentication became unavailable, and a throwing file callback could abort transfer cleanup/disposal. Lock now always establishes native locked/covered state; authentication reports setup/recovery separately. Picker delivery uses cleanup in `finally`, and disposal clears references before delivering cancellation and always detaches/destroys. A native lock epoch rejects authentication success after a newer lock/background/detach.

A repeated removal request no longer regresses a completed wipe's `containerDeletionPending` journal stage or replaces its cleanup operation ID. The native instrumentation lifecycle test asserts this idempotency. The coordinator reload path creates a fresh view/operation/generation against the existing persistent store.

Android restore-quarantine recovery currently requires Android Settings to clear this application's storage after the user chooses to remove restored local access. Ordinary in-app replacement deliberately does not override a failed installation integrity binding. Valid upgrades keep the binding and profile identifiers.

## API 36 emulator results

Dedicated `profile_desk_qa_api36`, serial `emulator-5582`, Android 16/API 36, arm64 Google APIs system image revision 7, WebView `com.google.android.webview 133.0.6943.137`.

- **PASS** isolated full ten-profile synthetic storage test. Same HTTPS origin, six stores, ten unique markers, view destruction/recreation, middle-profile wipe after starting a four-second service-worker write burst, observation after that write lifetime, adjacent-profile retention, fresh-identifier replacement and loaded-profile deletion restriction. Evidence: `docs/evidence/android/api36/isolated-storage-pass.xml`.
- **PASS** combined suite: native cleanup prepare/idempotency/tombstone blocking, ten-profile storage scenario and native capability/locked-reveal gating. 3 tests, 0 failures, 0 skipped, 83.253 seconds. Evidence: `docs/evidence/android/api36/full-suite-pass.txt`.
- **PASS** separate clean-process native journal verification. On next instrumentation process, `initialize` removed the tombstoned named container before loading it; the surviving neighbor remained available. One test, 0 failures, 0 skipped. Evidence: `docs/evidence/android/api36/clean-start-verify-pass.txt`.
- An initial combined run returned a fixture `ERROR` at fresh replacement after the earlier ten-store/recreation/wipe/neighbor assertions had passed. Its initial error detail was not captured, and the cause is unknown. The failure is retained in `initial-fixture-failure.xml`. Subsequent isolated and combined runs passed with the same storage assertions; diagnostic detail was improved, no timeout or assertion was weakened. This remains a compatibility observation to watch during physical-device coverage.

These results establish the exercised synthetic behavior on this emulator/provider only. They do not establish ten linked WhatsApp sessions, physical-device behavior, elapsed retention, or universal service-worker quiescence.

For repeatable full fixture plus clean-process verification, start the repository's HTTPS harness with a fresh temporary CA, then run:

```sh
JAVA_HOME=/opt/homebrew/opt/openjdk@17 \
ANDROID_HOME=/Users/LOCAL_USER/Library/Android/sdk \
packages/session_engine/android/run_instrumentation.sh \
  /absolute/path/to/ca.pem https://10.0.2.2:8443/ emulator-5582
```

The script compiles the test APK and runs native unit tests, installs only `dev.profiledesk.session_engine.test`, clears only that known synthetic test package, runs the eight-test native suite, then starts separate instrumentation processes to verify the deferred journal and all six persisted storage markers in two profiles. Set `PROFILE_DESK_SWITCHES=200` to include the deterministic 200-selection stress sequence. It checks JUnit output because `am instrument` can return shell success for failed tests. An unavailable optional SharedWorker API is reported as an assumption skip, not as a successful isolation test. The app's development/QA/production packages are distinct and are not cleared. The fixture's public CA is extracted with OpenSSL; private keys are never packaged. Do not use Gradle connected-test teardown as a persistence proof because it uninstalls the test APK.

## Resumed final validation

The connectivity instrumentation deliberately creates two test-only simultaneous WebViews in one named profile and a third in another named profile at the identical HTTPS origin. BroadcastChannel must deliver to the same-profile control and remain absent from the other profile during a one-second observation window in each direction. SharedWorker, when exposed, must show two connected ports in the same profile and one in the separate profile. These extra views exist only in `src/androidTest`; production retains its one-view invariant.

The synthetic switch measurement includes fixture navigation and verification of all six stores, not just visual switching. PSS samples cover the instrumentation host process only, not complete renderer/GPU memory, and two endpoints cannot prove absence of leaks. The emulator reported software rendering and host memory pressure at launch. Results must not be used as a physical-device performance budget.

- Before the final persistence/cleanup review, native compilation and **13 unit tests PASS**. The two added network tests cover idempotent registration, initial offline state, captive-path uncertainty, validated reachability, and late old-network loss/capability events after a new default network. A third added test rejects malformed, default, noncanonical and cross-profile persisted identities before native store access. These are Robolectric API 29 callback tests and a pure identity-validation test, not a physical network handover. Evidence: `docs/evidence/android/api36/final-native-checks.txt`.
- Final lint completes with **0 errors, 14 warnings**: ten feature-check warnings remain despite explicit runtime checks in allocation/open/wipe paths (the separate unsupported-provider instrumentation exercises rejection); three dependency-update notices and one optional URI KTX suggestion. JavaScript use, application-context lifetime and the implemented renderer-loss override have narrowly documented source suppressions. No global lint disable or baseline was added. Evidence: `final-lint.txt`.
- Initial resumed stress attempt **FAILED**: the final fixture cleanup callback exceeded 30 seconds. That `finally` exception masked any earlier failure, so the initial cause and completed-switch count cannot be established. Its raw output is retained in `initial-200-switch-failure.txt`. Test reporting now preserves the primary exception and logs progress every twenty selections. The timeout has not been increased. Root and platform agents are serializing stress workloads after observing host memory pressure.
- In that same attempted suite, BroadcastChannel control/isolation and native cleanup/capability tests passed. SharedWorker was **SKIPPED_UNAVAILABLE** because this WebView provider does not expose its constructor; no SharedWorker isolation claim is made.

- Actual diagnostics share-payload unit test **PASS**: an Android Activity receives ACTION_CHOOSER containing ACTION_SEND text, with expected technical fields and none of the seeded private alias, token, profile/store IDs, transfer metadata or staged file path/name/content markers. This checks the emitted payload, not just its source template. Evidence: `docs/evidence/android/api36/diagnostics-privacy-unit-pass.txt`.

The renderer regression uses the public API-29 `WebView.webViewRenderProcess.terminate()` after runtime `WEB_VIEW_RENDERER_TERMINATE` support is established. It exercises the real native engine owner and callback; test code directs that already bound view to the controlled fixture without adding a production URL or scripting hook. The test observes exact-owner `rendererGone`, removal of the native view, a new view handle on reopen, and retention of all six synthetic stores. It is a renderer-loss recovery test, not actual-service validation. See [WebViewRenderProcess](https://developer.android.com/reference/androidx/webkit/WebViewRenderProcess) (accessed 18 October 2026).


## Completed serial stress and transport checks

- **PASS**, serial 200-switch run: six tests reported by JUnit, five passed and SharedWorker skipped as unavailable, zero failures, 679.220 seconds. This includes ten profiles/all six storage types, middle-profile wipe during the synthetic service-worker write burst, same-profile BroadcastChannel delivery and cross-profile non-delivery, public renderer termination/reopen, and native lifecycle/capability checks. Evidence: `serial-200-suite-pass.txt`. Separate clean-process journal verification passed in 1.092 seconds (`final-clean-start-verify-pass.txt`). The first failing concurrent-load run remains in `initial-200-switch-failure.txt`.
- Measured 200-selection p95 was **3,187 ms**, including navigation and six-store verification; host-process PSS was **99,778 → 102,950 KB**. These are synthetic emulator observations, not a production UI latency budget or total-process memory/leak result (`stress-metrics.txt`). This measurement predates the explicit cookie-flush change and is not a benchmark of its blocking I/O cost.
- **PASS**, separate two-profile HTTP-cache/WSS/synthetic-file probe, 19.489 seconds (`transport-probe-pass.txt`). Each profile first sees an empty cache, then an actual same-profile force-cache hit as the positive control. WSS identity/echo is checked against the profile cookie, and fetched/uploaded synthetic file hashes survive reopening. This tests the controlled browser transport boundary; it does not validate native file-picker behavior or implement Android download/export.
- PID-limited log capture covered only `dev.profiledesk.session_engine.test` host PID 4914 during the serial run. Scanning known synthetic private markers found none (`synthetic-runtime-pid.log`, `runtime-privacy-scan.json`). Renderer processes and all other app logs were outside this capture; absence is limited to the named markers and this run.

## Process and reboot persistence correction

The first two-profile direct-WebView seed passed, then the new instrumentation process failed. Re-reading the same stores before any reseed established that readable and HttpOnly cookies were absent while localStorage, IndexedDB, Cache Storage and the service-worker cache retained their markers. Both fixture cookies had persistent Max-Age values. The first failure and precise cookie-only diagnostic remain in `initial-process-persistence-failure.txt` and `process-persistence-cookie-loss-diagnostic.txt`.

The engine now flushes the already loaded, owned named profile's cookie manager after covering/disposal and on background pause. It verifies that the row is available, its canonical identity matches, and the profile is already in the engine's loaded-profile set before resolving that existing profile. Missing, default, other-profile and tombstoned stores are excluded. It never reads/exports cookie values and never uses the global cookie manager. A persistence exception keeps the cover and reports an owner-specific failure.

The public [CookieManager.flush documentation](https://developer.android.com/reference/android/webkit/CookieManager#flush()) states that currently accessible cookies are written to persistent storage and that the caller blocks until completion; I/O may occur. [Profile.getCookieManager](https://developer.android.com/reference/androidx/webkit/Profile#getCookieManager()) returns that profile's manager and requires MULTI_PROFILE support. These references were verified on 18 October 2026. The synchronous flush is a cookie persistence boundary and has a possible UI-thread I/O cost; it is not an atomic all-store transaction or a guarantee for power loss or termination before lifecycle callbacks run.

A stronger test then exercised the production engine in an unattached FrameLayout and exited immediately after allocating/seeding two new profiles. On next startup, public profile inventory lacked both names and the engine correctly marked them missing without recreating them. This separate failure remains in `initial-production-profile-inventory-failure.txt` and its diagnostic JSON. The test had never attached a real window. Public Chromium source for [the installed 133.0.6943.137 version](https://chromium.googlesource.com/chromium/src/+/refs/tags/133.0.6943.137/android_webview/browser/aw_browser_process.cc) commits pending local-state writes on loss of foreground; this explains a relevant lifecycle difference, not a public durability promise.

The corrected test adds a test-APK-only Activity/window. It uses the production engine to allocate, bind and dispose both profiles, with the controlled URL redirected solely by instrumentation, then executes native pause and normal window finish. It adds no arbitrary delay, custom production URL, private API or internal-file modification. Separate processes verify the original six markers before any reseed:

- **PASS** initial seed/disposal: 9.670 seconds, `production-persistence-seed-pass.txt`.
- **PASS** explicit force-stop then fresh process: 6.960 seconds, `production-persistence-process-pass.txt`.
- **PASS** dedicated emulator reboot, verified changed boot ID and completed boot, then reopen: 28.874 seconds, `production-persistence-reboot-pass.txt`. Scoped test-profile cleanup followed verification.

This establishes the exercised normal window/disposal/background → process restart → emulator reboot sequence on API 36/WebView 133. It does not pass the distinct headless immediate-exit scenario, prove instant active-page crash durability, establish power-loss durability, or replace physical-device/elapsed retention tests.

Reproduce reboot verification only after the seed/process stages and before clearing the test package:

```sh
ANDROID_HOME=/Users/LOCAL_USER/Library/Android/sdk \
packages/session_engine/android/run_reboot_check.sh \
  https://10.0.2.2:8443/ emulator-5582
```

The reboot helper refuses physical devices and AVD names outside the dedicated `profile_desk_qa_` namespace. It never reboots the user's existing emulator. The new Activity exists only in `src/androidTest`.

Final compilation/test-APK build succeeds. **14 Robolectric unit tests pass**, including a journal retargeted to an available valid-UUID profile, stale operation rejection and permitted tombstone cleanup. Inherited startup cleanup is suspended if the installation binding fails. Evidence: `persistence-cleanup-final-checks.txt`, `persistence-final-compile.txt`, `window-harness-build.txt`. Final lint remains **0 errors, 14 warnings** (`final-lint.txt`).

After these production changes, the focused real-device-runtime tests also pass on the emulator: public renderer termination/reopen, capability/locked-reveal checks and cleanup preparation, **3/3 in 11.932 seconds** (`post-fix-native-lifecycle-pass.txt`), followed by separate-process journal completion, **1/1 in 1.787 seconds** (`post-fix-clean-start-pass.txt`). The dedicated API 36 emulator was left booted for the root agent's integrated Flutter and optimized-APK smoke checks.


## Optimized empty-welcome inspection diagnostic

The initial root-owned optimized APK smoke failed because it treated a WebView devtools socket name as evidence of an inspectable page. A bounded diagnostic reinstalled only the same locally test-signed candidate after confirming no production installation existed. Exact PID matching confirmed the socket belonged to the candidate; `/json/version` reported the expected Android package, and `/json/list` was an empty array. The app cold-launched successfully and remained alive. The temporary forwarding rule and the owned empty installation were removed. No profile, QR, account or message was created. Evidence: `release-empty-devtools-diagnostic.json`.

This observation supports checking actual candidate-owned inspectable page targets rather than asserting no socket exists. It does not prove active-page inspection policy from the welcome screen; production still explicitly disables WebView content debugging before configuring/loading each owned view. No production change was made for this diagnostic. The corrected smoke audit and its final result are recorded below.

The dedicated emulator was responsive during the diagnostic: boot status returned in 0.273 seconds and `/data` usage in 1.172 seconds, with 15% used and approximately 8.6 GB available. These bounded probes did not reproduce the earlier eight-second shell timeouts (`release-smoke-health-check.json`).


## Final optimized APK and isolated shell QA

The corrected `tests/device_flows/smoke_android_release.py` checks the exact candidate PID's socket path. When a socket exists, it creates an ephemeral ADB forward, verifies the endpoint's Android package, and requires an empty `/json/list`. The forward is removed in `finally`. The initial socket-existence assertion failure remains in `optimized-smoke-initial-socket-failure.log`; the correction does not claim that the socket was absent.

The first corrected run failed the welcome accessibility assertion because Android displayed **“Process system isn't responding”** over the candidate. The captured system dialog and failure remain in `optimized-smoke-system-anr.png` and `optimized-smoke-system-anr-failure.log`. Subsequent bounded input/getprop probes also exceeded eight seconds. Only the dedicated `profile_desk_qa_api36` emulator was cold-restarted, without wiping its data; it completed boot in 20.360 seconds (`optimized-smoke-emulator-restart.json`). This was an emulator-wide failure, not a passed product test.

The retry **PASS** used the optimized production APK with SHA-256 `370e6c515cb4d3f61a0516736f793171f5cd1a3983dcec6f0d4f1349f7839b9f`, signed only as a local test copy with a temporary key. Cold launch completed in 1,468 ms. Candidate-package accessibility exposed **“Set up your workspace”**, with bounded scrolling permitted only within an observed candidate scrollable node; the action was never tapped. Exact candidate PID 3291 exposed a provider socket but zero page targets. The `FLAG_SECURE` capture is not visual rendering proof. No WebView/profile/account/message was opened or created in this smoke. The key, owned installation, ephemeral forward and remote accessibility dump were removed. Evidence: `optimized-release-smoke-pass.json` and `optimized-welcome-accessibility.xml`. No production source change was made for this correction.

The isolated QA runner then **PASS**ed one real Flutter/native integration test in four seconds after a 10.2-second QA build. It exercised the cold shell, native profile allocation, official-URL opening, view detach, confirmation/cancel behavior and scoped removal; no pairing, QR reading, page scripting, account content, attachment or messaging occurred. Test-only native integration dependencies and fixture identifiers remained in the isolated `build/qa-shell-workspace` copy. Command:

```sh
python3 tests/device_flows/run_shell_integration.py -d emulator-5582
```

Evidence: `shell-integration-pass.log`; the earlier Gradle failure remains in `shell-integration-initial-gradle-failure.log`. Flutter's successful test teardown attempted the unflavored fixture ID and logged `DELETE_FAILED_INTERNAL_ERROR`, leaving the actual `.qa` fixture installed. The exact flavored fixture created by this run was manually uninstalled, and both fixture IDs plus the empty production candidate were verified absent (`shell-integration-owned-cleanup.json`). The runner was subsequently hardened to clean only its preflight-owned fixture IDs and verify absence; the final rerun passes with this cleanup.

## Final shared-race rebuild and cleanup

The final shared AccountService publication-order fix passed the unchanged Android integration test (4 seconds, QA build 11.8 seconds). Flutter still emitted its absent-base-ID teardown warning; runner-owned cleanup verified both fixture IDs absent. See `evidence/build/android-integrated-smoke-final-pass.txt`.

The rebuilt optimized APK SHA-256 is `78ea0bf4aace35a6cef467715777fa84b8e41b56416dbbf6689022706b74aaed`. Its local test-signed empty-welcome smoke passed with cold launch 820ms, welcome accessibility confirmed and zero inspectable page targets for the exact candidate PID. This does not exercise active WebView inspection. See `evidence/android/api36/optimized-release-registry-fixed-pass.json` and its adjacent log/XML. The pre-fix smoke remains historical evidence. All owned candidate/shell/native fixture installations and the candidate forward were verified absent. The dedicated AVD name was verified before only emulator5582 was shut down without wiping data; `final-owned-runtime-cleanup.json` records it.
