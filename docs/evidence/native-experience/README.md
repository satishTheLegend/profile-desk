# Native experience verification checkpoint

19 October 2026. Product work remains in progress; no new development release was installed. Actual native messaging components are implemented, but their live WhatsApp port is not registered. The installed setup archive still requires relinking.

| Check | Current result | Scope |
|---|---|---|
| Mobile Flutter analysis | No issues | Whole mobile package |
| Mobile Flutter tests | 87 passed | Includes 30 native messaging interaction/fault cases |
| Official fallback browser fixture | 73 passed | Owned fictional HTML, locally intercepted requests, real browser clicks |
| Android native unit tests | 57 passed, no failures/skips | API 29 Robolectric; window/privacy/keyboard, ownership, archive and lifecycle |
| iOS viewport/privacy/lifetime fixture | 109 passed | Owned iOS 27 simulator, actual production native classes and fictional input |
| iOS engine/callback fixture | 59 passed | Includes actual in-flight readiness cancellation and weak session release; event-ownership limit retained |
| SwiftPM layout resource | Passed | Actual resource loader, source equality and stale-resource rejection |
| Generated bindings/localization | Identical regeneration | Pigeon and Flutter localization |
| Synthetic registration migration | 125 passed | Separate owned iOS 26.5 test, independent cold process/reboot |
| Empty-origin import capability | 138 passed | Independent empty named stores, fixed inert HTML, LocalStorage/typed IndexedDB/fresh nonextractable keys, cold process/reboot |

[Prior shared-check input hashes](current-source-snapshot.json), [Flutter analysis](flutter-analyze.log), [Flutter tests](flutter-tests.log), [browser result](layout-browser-result.json), [Android summary](android-test-summary.json), [latest iOS results, inputs and limits](../ios/layout-lifetime/README.md), [resource loader](ios-resource-result.json), [generation check](generated-check.log). [Synthetic migration evidence and limits](../session-portability/registration/fault-controls/README.md).

The native components implement search, list selection, native text rows, bounded earlier history, read-only/unsupported states, account/chat drafts, single-flight text actions, uncertain outcomes, native Back and host-driven refresh. They clear private state before official fallback. Typed lock failures invalidate all pending work and purge titles, messages, queries and drafts. [Readable fictional previews, reproduction and lifecycle contract](../../../apps/mobile/test/fixtures/native_messaging/README.md).

Typed presentation feedback and Android Back use bounded exact-view queries, no polling and no private content. They discard late results permanently after route hide or native eligibility loss, even after return/resume/unlock. The first keyboard Back hides the IME; detail returns to list; menus give explicit guidance and Original remains available.

Fallback fixes cover primary full-row buttons versus popup accessories, attribute-only structure changes without observer loops, reachable nested/edge dialogs, preservation of service-hidden overlays, draft-preserving list return, repeated Android mode commands and iOS recovery to full desktop fit when structure becomes unknown.

Native privacy protection covers the whole window. Both platforms end input without clearing drafts. Android additionally guards the native Window.Callback key/shortcut entry, restricts traversal/activation to its enabled Unlock control, and restores only its own callback slot. The iOS cover becomes first responder before a delayed Flutter handler can process private input. Actual hardware keyboard and accessibility behavior on physical devices remain separate checks.

Independent review found and verified fixes for retained state on typed lock errors, keyboard input beneath an opaque cover, and keyboard access to Android Unlock. The final keyboard fixture uses the real attached hierarchy and Window.Callback dispatch; Robolectric's separate Activity.currentFocus shadow cache is not artificially populated. Initial assertion/focus diagnosis logs and the intermediate iOS run are preserved. The earlier 67-check run used the prior resource and remains historical. The final 94-check run verifies all source hashes and packaged resource bytes. Initial status-query SDK signature errors and a fixture timing/cover mismatch are retained; the final fixture explicitly uncovers and waits for the resized viewport before asserting steady read-only status. Existing Robolectric Surface/CloseGuard diagnostics are retained in the complete Android log; this suite is not a native memory/performance certification.

Public static source supplies an internal text-chat path and 24 encrypted fields across 14 application schemas. Normal-browser final salt and FTS HMAC consumers are mapped. A later ordinary anonymous same-browser code request succeeded, allowing the known Worm consumer to be mapped to four encrypted pending-action queues; its normal initializer starts resend, key-share and deletion drains. Generic `VERSION_STR` can be non-unique. Conditional service-worker writers are mapped, but their push/periodic reachability in WKWebView remains unverified. The [current boundary review](../session-portability/state-boundary-review/README.md) distinguishes those facts from complete state/schema coverage, consistent capture and replay guarantees, which remain open. Public bundles stay hash-verified in ignored build output; no official client was executed and no real account, messages or key material was accessed.

A genuine-cold-first-view native-display candidate is now source-backed for synthetic testing. It requires exact fresh authenticated socket state and stream, account/lock/runtime binding and an irreversible native process-owned admission latch. Missing duration can legitimately mean disabled, while convenience getters can migrate/delete malformed or legacy settings. `MAIN`/cached sync, a defaulted getter or replacement-navigation completion cannot prove this whole gate. No live port is activated by the review.

The [empty-origin fixture](../session-portability/origin-bootstrap/README.md) passes 138 assertions before any remote client loads. It establishes synthetic destination storage and cold persistence only; it supplies neither a complete source snapshot nor authenticated restore.

The remaining live adapter, complete native encrypted archive, single-app operation wiring and independent authenticated restore gates are tracked in [the implementation checklist](../../PROFILE_DESK_NATIVE_EXPERIENCE_PLAN.md). No fixture pass closes the user's login-preserving deployment condition.

The whole source check also passes 25 contract, 25 registry, 87 mobile, 17 HTTPS-server and 32 runner-safety tests. Generated Pigeon/localization output is identical. [Full check log](full-source-check.log). Public log paths/hostnames are normalized; raw local evidence remains under ignored build output.

The prior optimized unsigned production artifacts pass inspection
([report](release-artifact-checks.json)): backup/cleartext restrictions, AOT,
packaged privacy declarations and known fixture/plugin exclusions. The newer
iOS lifetime fix has its own rebuilt unsigned artifact and inspection report
in the [latest evidence](../ios/layout-lifetime/README.md). Its actual Flutter/native
allocation/open/detach/management flow also passes with 255 copied source hashes
matching and owned fixture/Simulator cleanup. The earlier 254-input shell result
remains historical ([result](ios-shell-result.json), [log](ios-shell.log)).
Thirty-six prior macOS helper tests pass ([log](ios-helpers.log)). These are
automated component/shell checks; owned readiness-event delivery, actual service
sessions, media and restored login remain outside their proof.

The earlier iOS callback/detach checkpoint passed 39 assertions ([result](ios-engine-result.json)). The subsequent bounded-layout/readiness fix passes [59 engine and 109 viewport assertions](../ios/layout-lifetime/README.md), with current source/package hashes and another optimized unsigned production build/artifact check. Android engine/application lint reports zero errors and 26 warnings ([summary](android-lint-summary.json)); these warnings remain documented.

Earlier optimized development build 5 is signed with a matching provisioning profile and verifies deeply ([artifact check](iphone-development-build5.json)). It predates the subsequent iOS callback-lifetime fix; it is not a current-source release candidate. No installation or real-session verification is implied.

Public Linux CI [passes at code commit 0344679](https://github.com/satishTheLegend/profile-desk/actions/runs/39235384168), including clean-clone bootstrap, source analysis/tests, generated-code equality, an Android QA build and native tests ([current publication metadata](../ios/layout-lifetime/github-publication.json)). The earlier 5440a55 success and initial ignored-lockfile failure remain preserved in [prior metadata](github-ci-result.json). This does not add real-account or physical-device certification.
