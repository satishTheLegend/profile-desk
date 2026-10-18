# Phone navigation and account setup transfer

**18 October clarification:** the user requires a restored QR-linked session to remain logged in and has made this a prerequisite for further deployment. Current setup transfer does not meet that requirement. Deployment is on hold; see [verification and required gates](SESSION_RESTORE_VERIFICATION.md).

Date: 18 October 2026. Status: phone layout and account setup transfer implemented, tested and included in development build4; installed on the authorized iPhone. Launch is pending unlock. Signed-in session migration and actual authenticated service acceptance remain open. See the [completed implementation checklist](PHONE_LAYOUT_AND_ACCOUNT_TRANSFER_PLAN.md) and [evidence](evidence/phone-layout-transfer/README.md).

## Intent and authority

The user wants readable phone navigation: show the official chat list and menu first, then show the selected conversation or menu pane at usable size. They also requested import/export of all sessions and full planning using brainstorming and gstack, continuing the navigation work. Their standing direction is to choose recommendations and implement without routine check-ins.

This document records a change request against the original design. It does not rewrite the original prompt or turn unmet requirements into passes. Session-preserving migration remains a separate unmet requirement; account setup transfer is a useful, explicitly labeled subset.

| Module | Responsibility | Dependency |
|---|---|---|
| phone-layout | Present official web panes at phone width, with original-layout recovery | Current owned native WebView |
| account-setup-transfer | Export/import ordered account metadata using new isolated stores | Native registry and system document pickers |
| session-migration-research | Establish whether full signed-in storage is publicly portable | Platform APIs and service verification |

Build order: define contracts and fixtures; implement phone-layout and account-setup-transfer independently; integrate, review, validate and prepare a development build. Session migration research gates any future credential archive.

## Evidence and alternatives

The current iOS workspace lays out at 980 points and scales to the host width. At 440 points this reduces a 16-point font to approximately 7.2 points. Zooming/cropping the desktop view would improve size but cannot reliably infer which chat or menu item was selected. Recreating chats in Flutter would require extracting private content and maintaining a second messenger UI. The selected approach retains the official web UI and adapts only its structural layout.

The source prompt bans conversation extraction, arbitrary script execution in the shared contract, and a general page-to-native bridge. It does not prohibit reviewed bundled presentation code. See `IMPLEMENTATION_INSTRUCTIONS.md` sections containing lines 51, 174, 240, 367 and 387; Word P124/P129 and T02R06 in `DESIGN_DOCUMENT_TRACEABILITY.md`. A fixed presentation command has no user-supplied script, selector, URL or extracted page content.

Full session portability is not supported by the verified public API surface:

| Platform | Public capability | Missing guarantee |
|---|---|---|
| iOS 17–25 | Named stores, cookie access, data inventory/deletion | No full serialized profile export/restore |
| iOS 26+ | `WKWebsiteDataStore.fetchData/restoreData` | Current implementation accepts LocalStorage only |
| iOS 26+ | `WKWebView.fetchData/restoreData` | SessionStorage only |
| AndroidX WebKit 1.17.1 | Named profiles and storage managers | No full profile archive/restore |

Sources checked 18 October 2026: [Apple fetch API](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/fetchdata(of:completionhandler:)), [WebKit implementation pinned to a1122865, lines 606–622](https://github.com/WebKit/WebKit/blob/a11228658545f5a823a897cc3bdc2cd386e11492/Source/WebKit/UIProcess/API/Cocoa/WKWebsiteDataStore.mm#L606), [Android Profile](https://developer.android.com/reference/androidx/webkit/Profile), [ProfileStore](https://developer.android.com/reference/androidx/webkit/ProfileStore). Local Xcode headers and the project's 1.17.1 Android AAR were also inspected. Cookies plus local/session storage do not constitute complete IndexedDB, service-worker or application key migration. No claim is made that all WhatsApp keys are hardware-bound.

## Phone layout design

On narrow devices, keep a compact native toolbar with **Chats & menu** and an **Original layout** recovery action. Account selection remains in the existing app header. The normal flow is list → user selects a chat → conversation → native Chats & menu. The official menu and secondary panes stay inside the official WebView; none of their text is copied into Flutter.

The adapter is a reviewed static app resource. Android and CocoaPods package the canonical file; Swift Package Manager packages a generated regular copy because its resource copier preserves symlinks. `sync-layout-resource.sh --check` runs in the shared checks, and final artifact verification compares packaged bytes with the canonical source. It runs only on the exact HTTPS `web.whatsapp.com` origin, default port, main frame. On iOS use a named isolated `WKContentWorld`; do not install a page-to-native message handler. On Android inject only the fixed bundled script into an owned allowlisted page. The shared contract exposes only `setWorkspaceLayout(view, phone|original)` and `showWorkspaceList(view)`.

Allowed observations: presence/ancestry of fixed structural hooks, geometry, structural roles and visibility booleans. Disallowed: text/HTML, titles, input values, message/contact/chat identifiers, credentials, QR/codes, browser storage, network payloads or automatic service actions. Selection reacts to a genuine user's click on a structurally recognized list row, then checks for a detail pane. Observers coalesce work and disconnect on disposal. No selected conversation identity leaves the page.

Recognized phone layouts use the actual host width, keeping ordinary 16px web text approximately 16 native points at default zoom. The rail/list fills the available width, and detail fills it after selection. Do not animate or transform privacy covers. Keep dialogs and menus above the adapted pane. Unknown layouts retain an accessible recovery path and must not be described as verified responsive support. Wide/tablet layouts retain side-by-side behavior. Keyboard and safe-area resizing must fit the available host, with no hardcoded device resolution.

Original mode removes adapter styles and restores the previous desktop-fit policy. Mode changes affect only the current exact `ViewHandle`; stale handles, lock, detach or nonforeground state cannot alter a newer account. Opening another account starts at the list. Selection does not infer authentication or change account observations.

## Account setup archive design

Product names: **Account setup backup**, **Export account setup**, **Import account setup**. Always disclose: **Account names, colors, order and appearance only. Each imported account must be linked again. Chats and signed-in sessions are not included.** Do not call it a session backup or claim restore keeps login.

Version 1 is UTF-8 JSON, at most 64 KiB, at most ten ordered entries:

```json
{"format":"profile-desk-account-setup","version":1,"requiresRelinking":true,"accounts":[{"alias":"Work","color":4280371038}],"appearance":{"theme":"system"}}
```

Only these keys are accepted. Colors are unsigned 32-bit integers. Aliases follow existing limits: trimmed, 1–40 Unicode scalars, no control characters, case-insensitive uniqueness. Import rejects unknown fields, invalid types, unsupported versions, oversized files, invalid theme, duplicate names and too many accounts. Files are unencrypted readable account metadata; the export UI says so before the user chooses where to save them. No remote upload or account is introduced.

Excluded: original profile/store IDs, timestamps, authentication observations, permissions, installation binding, lock settings, onboarding acknowledgements, cleanup journals, files, messages, contacts, cookies, HTML, IndexedDB, browser archives and keys. Existing OS backup exclusions and untrusted-restore quarantine remain intact.

Flow: choose file → bounded validation → preview/edit account names and see conflicts/capacity → explicit Import accounts action → native revalidation → fresh profiles → result with relink instruction. Import appends; it never overwrites, merges or deletes destination profiles. Appearance import is optional and off by default. Empty archives are valid exports but cannot create accounts. Cancel before confirmation makes no registry change. File pickers are app-level operations, independent from website uploads.

Native SQLite remains the only durable authority. Reserve the complete batch inside one transaction after rechecking names/capacity; every entry receives a fresh platform identity and unknown authentication observation. An installation-excluded, flushed allocation journal records only newly generated IDs before provider creation. On an interrupted transaction, startup may reclaim only those journal-owned identifiers that have no committed registry row. Existing profiles and committed imported profiles cannot be deletion targets; installation trust is checked first. A provider failure cannot create a falsely available signed-in profile. Never replay a timed-out mutation automatically. A repeated successful import is rejected by alias conflicts unless names were deliberately changed.

Typed native control methods: `pickAccountSetupArchive() -> String?`, `exportAccountSetupArchive() -> bool`, `importAccountSetupArchive(String archive, bool applyAppearance) -> List<AccountProfile>`. These carry only the bounded allowlisted metadata schema, not arbitrary file bytes or paths. Native validation repeats shared preview validation. Pickers are bound to the current Flutter attachment; stale callbacks cannot mutate state. On lock/detach, cancel or reject; do not expose previews beneath the app lock. Export and import cannot overlap native web transfers or another presentation.

Android preserves the existing owned-system-picker handoff policy: opening its document provider immediately covers the workspace but does not cancel that same request as ordinary backgrounding. Explicit lock and activity/Flutter detach cancel it; ordinary background without an owned picker locks normally when enabled. This exception is tested separately from genuine background transitions. Imported appearance is reconciled by the app-level service even when the initiating screen closes or an operation finishes after its deadline.

## Scope changes and preserved requirements

| Original rule | Change |
|---|---|
| No session import/export in production contract | Explicit account-metadata archive methods added at user's request; credential/session archive still absent |
| No session backup/sync | User-requested setup file exchange permitted; no automatic OS/cloud sync or browser-store copying |
| No arbitrary script/page extraction | Preserved; fixed layout-only adapter is reviewed and bundled |
| No private API workarounds | Preserved |
| Ten isolated stores; one live WebView | Preserved |
| Installation-bound trust and relink on untrusted restore | Preserved; imported setup creates fresh trusted empty stores |
| Immediate native privacy covers and device authentication | Preserved |

## Verification and release gates

Use synthetic owned pages/accounts only for automated tests. Do not send messages, inspect actual message text or export existing credentials. Actual WhatsApp chat/menu/keyboard behavior requires a separate manual device observation; fixture results are not proof of service compatibility. No physical acceptance box may be checked from a source review alone.

- Layout: list first, genuine selection, same-chat reselection, Back, menu/settings, dialog overlay, unknown structure, 320/375/440 widths, landscape/tablet, keyboard, pinch, stale commands, reduced motion and disposal.
- Archives: 0/1/10 entries; malformed, oversized and unsupported documents; excluded keys; invalid colors/theme/aliases; duplicates/conflicts; 10-slot boundary; fresh identities; destination unchanged; auth reset; lock/detach/cancel; failed allocation and recovery; late result without replay.
- UI: 48-point controls, 2× text without overflow, honest relink disclosure, editable preview, disabled import until valid, no raw exception/path/filename leakage.
- Regression: `bash scripts/check.sh`; focused native registry/engine/viewport suites; release build compile/resource/fixture-exclusion checks. Serialize Xcode workloads on this host.

## Future signed-in migration gate

Keep this requirement open. Proceed only if supported APIs can preserve every item of state required for authenticated cold-start restore, and fresh-profile tests establish that the service accepts it. A reviewed sufficient credential subset may qualify; copying every browser cache is not inherently required. The [current session-backup work](SESSION_BACKUP_IMPLEMENTATION_PLAN.md) tests this distinction. Then design authenticated encryption, passphrase/key recovery, bounded parsing, OS/version compatibility, staging/rollback, stale-session revocation handling and cross-account isolation tests. Raw filesystem copies and cookies-only archives do not satisfy this gate.
