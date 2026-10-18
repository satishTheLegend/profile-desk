# Phone layout and account setup transfer evidence

Updated 18 October 2026. This checklist records implemented code and bounded local
verification. Development releases 0.1.0(4) are built and verified. The iPhone
installation and version are confirmed; launch was blocked by its locked state.
It does not establish authenticated service compatibility or session migration.

| Check | Result | Evidence and scope |
|---|---|---|
| Shared Dart and Flutter | 83 passed | [Shared checks](shared-checks.log): contract, metadata facade/archive and widget checks. |
| Python fixtures and guards | 49 passed | [Shared checks](shared-checks.log): 17 fixture and 32 QA-guard tests. |
| Generated files | Passed | [Regeneration check](generated-checks.log): Pigeon and localization regenerate identically. |
| Browser layout fixture | 59 passed | [Result](browser-layout.json), [procedure](../../../tests/workspace_layout/README.md): owned HTML, local request interception, blocked DNS, isolated test world. No actual service content. |
| Android native | 42 passed; no errors, failures or skips | [Summary](android-native.json), [log](android-native.log): Robolectric/JVM provider and lifecycle fixtures. Release Kotlin compilation passed; lint has zero errors and 18 warnings. |
| iOS registry/codec sources, host SwiftPM suite | 38 passed | [Archived final log](ios-native.log) (macOS host). An earlier owned named-store teardown failure was fixed with a bounded inventory-checked retry; the final suite retains strict isolation assertions. |
| iOS engine/lifecycle | 39 passed | [Archived result](ios-engine.json), [source snapshot](ios-engine-source-snapshot.json): production registration, detach and picker callbacks with registrar/presentation doubles. |
| iOS viewport/identity/layout | 66 passed | [Archived result](ios-viewport.json), [source snapshot](ios-viewport-source-snapshot.json): actual native host/WebView and owned HTML; no live account or actual touch pinch. |
| SPM resource packaging | Passed | [Production loader probe](ios-spm-resource.json), [manifest/symlink checks](ios-spm-manifest-guard.json), [unconditional copy check](ios-spm-resource-check.log). The native harnesses above used the CocoaPods-style bundle; this follow-up closes the SPM packaging path separately. |
| Final development releases | Passed | [Signed iOS](ios-build-verification.json), [unsigned Android](android-build-verification.json). Both include the canonical script and production assets; 111 iOS and 98 Android/shared inputs remained unchanged. |
| Physical iPhone installation | Passed; launch blocked | [Redacted record](physical-development-install-build4.json): in-place build4 installation and independent version query succeeded. iOS denied launch because the device is locked; no current runtime/service pass. |

The core reports and snapshots are archived here. Raw build/deployment logs and
artifacts remain under `artifacts/phone-layout-20261018/`. The first iOS build
attempt exposed a generated dependency minimum of iOS15; the successful build
explicitly set `IPHONEOS_DEPLOYMENT_TARGET=17.0`, matching the app and plugin.
Earlier failed simulator/resource probes remain in their original local run directories.

Fictional Flutter previews: [backup screen](backup.png) and [import preview](backup-preview.png).

## Implemented and locally checked

- [x] Phone-width list and rail, trusted chat-row selection, same-chat reselection,
  conversation view, native list action and Original layout recovery.
- [x] Retain a known connected side container when its list becomes a settings/menu
  panel; preserve its user-operated Back action. Unknown or ambiguous structures
  fall back without reading service text or synthesizing service clicks.
- [x] Reversible viewport metadata/styles, constrained side images, overlays,
  narrow/tablet transitions, reduced motion and disposal.
- [x] Fixed typed commands scoped to the exact owned view, immediate native privacy
  cover, stale-operation rejection and foreground/attachment lifecycle checks.
- [x] Bounded 64 KiB versioned metadata archives with exact allowlists, depth and
  duplicate-key rejection, native validation, capacity/name preflight and fresh
  isolated destination stores.
- [x] Editable import preview, unencrypted-file disclosure, optional appearance,
  route-independent theme reconciliation and no automatic mutation replay.
- [x] Cancel/lock/detach and interrupted-allocation handling through owned fixtures.

## Open acceptance and unsupported scope

- [ ] Verify actual authenticated WhatsApp selectors and behavior: chats, menus,
  secondary panes, overlays, same-chat selection and composer interaction. Synthetic
  structural matches do not guarantee the provider's current DOM layout.
- [ ] Verify physical keyboard, rotation, actual pinch and VoiceOver/TalkBack.
- [ ] Exercise real OS/local/cloud document providers, saved-file reopening,
  cancellation, lock/detach interruptions and low-space/provider errors.
- [x] Finish release builds, resource/source/fixture-exclusion verification and
  physical installation/version confirmation.
- [ ] Launch build4 after the iPhone is unlocked; the attempted launch was denied
  by iOS and has not been counted as a pass.
- [ ] Full signed-in session migration remains **unsupported**. The implemented
  export contains ordered account names/colors and appearance only. It excludes
  chats, credentials, browser storage and signed-in sessions; every imported
  account requires official linking again. Setup transfer is not a substitute
  pass for the user's broader session-preserving migration request.

Android uses fixed code in the trusted page world without a native message
bridge. iOS uses a named isolated WebKit world. The stronger iOS world boundary
must not be attributed to Android. Existing production service-compatibility
and wider acceptance gates remain open; see the [design](../../PHONE_LAYOUT_AND_ACCOUNT_TRANSFER.md)
and [implementation plan](../../PHONE_LAYOUT_AND_ACCOUNT_TRANSFER_PLAN.md).
