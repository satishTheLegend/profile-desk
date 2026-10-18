# Native experience verification checkpoint

19 October 2026. Product work remains in progress; no new development release was installed. Actual native messaging components are implemented, but their live WhatsApp port is not registered. The installed setup archive still requires relinking.

| Check | Current result | Scope |
|---|---|---|
| Mobile Flutter analysis | No issues | Whole mobile package |
| Mobile Flutter tests | 87 passed | Includes 30 native messaging interaction/fault cases |
| Official fallback browser fixture | 73 passed | Owned fictional HTML, locally intercepted requests, real browser clicks |
| Android native unit tests | 57 passed, no failures/skips | API 29 Robolectric; window/privacy/keyboard, ownership, archive and lifecycle |
| iOS viewport/privacy fixture | 94 passed | Owned iOS 27 simulator, actual production native classes and fictional input |
| SwiftPM layout resource | Passed | Actual resource loader, source equality and stale-resource rejection |
| Generated bindings/localization | Identical regeneration | Pigeon and Flutter localization |
| Synthetic registration migration | 125 passed | Separate owned iOS 26.5 test, independent cold process/reboot |

[Current input hashes](current-source-snapshot.json), [Flutter analysis](flutter-analyze.log), [Flutter tests](flutter-tests.log), [browser result](layout-browser-result.json), [Android summary](android-test-summary.json), [iOS result](ios-viewport-result.json), [iOS final input verification](ios-viewport-final-source-verification.json), [resource loader](ios-resource-result.json), [generation check](generated-check.log). [Synthetic migration evidence and limits](../session-portability/registration/fault-controls/README.md).

The native components implement search, list selection, native text rows, bounded earlier history, read-only/unsupported states, account/chat drafts, single-flight text actions, uncertain outcomes, native Back and host-driven refresh. They clear private state before official fallback. Typed lock failures invalidate all pending work and purge titles, messages, queries and drafts. [Readable fictional previews, reproduction and lifecycle contract](../../../apps/mobile/test/fixtures/native_messaging/README.md).

Typed presentation feedback and Android Back use bounded exact-view queries, no polling and no private content. They discard late results permanently after route hide or native eligibility loss, even after return/resume/unlock. The first keyboard Back hides the IME; detail returns to list; menus give explicit guidance and Original remains available.

Fallback fixes cover primary full-row buttons versus popup accessories, attribute-only structure changes without observer loops, reachable nested/edge dialogs, preservation of service-hidden overlays, draft-preserving list return, repeated Android mode commands and iOS recovery to full desktop fit when structure becomes unknown.

Native privacy protection covers the whole window. Both platforms end input without clearing drafts. Android additionally guards the native Window.Callback key/shortcut entry, restricts traversal/activation to its enabled Unlock control, and restores only its own callback slot. The iOS cover becomes first responder before a delayed Flutter handler can process private input. Actual hardware keyboard and accessibility behavior on physical devices remain separate checks.

Independent review found and verified fixes for retained state on typed lock errors, keyboard input beneath an opaque cover, and keyboard access to Android Unlock. The final keyboard fixture uses the real attached hierarchy and Window.Callback dispatch; Robolectric's separate Activity.currentFocus shadow cache is not artificially populated. Initial assertion/focus diagnosis logs and the intermediate iOS run are preserved. The earlier 67-check run used the prior resource and remains historical. The final 94-check run verifies all source hashes and packaged resource bytes. Initial status-query SDK signature errors and a fixture timing/cover mismatch are retained; the final fixture explicitly uncovers and waits for the resized viewport before asserting steady read-only status. Existing Robolectric Surface/CloseGuard diagnostics are retained in the complete Android log; this suite is not a native memory/performance certification.

Public static source supplies an internal text-chat path and24 encrypted fields across 14 application schemas. It does not establish a safe positive live screen-unlock gate: private mounted UI state and asynchronous relock precede reliable connection/cache changes, and a defaulted false lock setting is insufficient. Normal-browser final salt is mapped to successful-login `companion_enc_static`; FTS HMAC consumers and their required fresh-manifest/cache rebuild are mapped. Worm key consumers, complete state coverage and consistent capture/restore ordering remain unresolved. The anonymous public worker-source loader returned HTTP400/non-JSON; that request failure does not prove authentication is required or migration impossible. A narrower disabled-screen-lock candidate remains unapproved: reviewed preference getters can migrate/delete values, and fresh DOM ownership does not prove old worker operations stopped. All selected public bundles are hash-verified and cached privately under ignored build output for subsequent analysis; no client was executed and no real account, messages or key material were accessed.

The remaining live adapter, complete native encrypted archive, single-app operation wiring and independent authenticated restore gates are tracked in [the implementation checklist](../../PROFILE_DESK_NATIVE_EXPERIENCE_PLAN.md). No fixture pass closes the user's login-preserving deployment condition.

The whole source check also passes 25 contract, 25 registry, 87 mobile, 17 HTTPS-server and 32 runner-safety tests. Generated Pigeon/localization output is identical. [Full check log](full-source-check.log). Public log paths/hostnames are normalized; raw local evidence remains under ignored build output.

Both current optimized unsigned production builds pass artifact inspection
([report](release-artifact-checks.json)): backup/cleartext restrictions, AOT,
packaged privacy declarations and known fixture/plugin exclusions. The isolated
iOS Flutter/native shell passes its real allocation/open/detach/management flow
with all 254 copied source hashes matching and owned simulator/fixture cleanup
verified ([result](ios-shell-result.json), [log](ios-shell.log)). Thirty-six macOS
native helper tests also pass ([log](ios-helpers.log)). These are automated
component/shell checks; actual service sessions, media and restored login remain
outside their proof.

The current iOS engine callback/detach fixture passes 39 assertions ([result](ios-engine-result.json)); its input hashes still match. Android engine/application lint reports zero errors and 26 warnings ([summary](android-lint-summary.json)); these warnings remain documented.

Optimized development build 5 is signed with a matching provisioning profile and verifies deeply ([artifact check](iphone-development-build5.json)). It is prepared locally; no installation or real-session verification is implied.
