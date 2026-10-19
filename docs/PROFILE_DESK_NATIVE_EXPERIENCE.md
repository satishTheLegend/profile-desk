# Native messaging and session backup inside Profile Desk

19 October 2026. Architectural design following the user's explicit request for actual native chat lists, messages and composer, plus session-preserving import/export inside Profile Desk. Their subsequent “1,2” is interpreted as native everyday messaging with the official interface retained for QR linking and compatibility fallback. Earlier permission to choose recommendations and implement without routine check-ins remains in effect.

## Intended outcome

Profile Desk is the only product application. After the account owner links through the official QR flow, supported chat lists, conversation messages and composition render as Flutter widgets at device resolution. Native navigation provides account switching, chat search, conversation back, privacy and Backup & Restore. The official WebView continues to own the network protocol and browser session; it is a linking/fallback surface, not the everyday message renderer.

Backup & Restore belongs in that same app. The requested completion condition is an encrypted export containing every selected profile's metadata and all required session/data state, restored into independent fresh profiles, surviving an application restart without QR/code relinking. A surviving source profile or a setup-only file does not meet it. Complete-information coverage must be stated explicitly; service resynchronization is not proof that omitted local conversations or media were backed up.

The separate Session Lab remains a test-only artifact containing owner-linked test data. Do not delete its data or make product users install it. It is not the implementation of the requested feature.

## Scope and constraint changes

The user has now explicitly requested native display of their chat lists/messages and a native composer. This authorizes a narrowly scoped, reviewed data/action adapter for those functions and supersedes the original presentation-only restriction for this feature. It does not authorize arbitrary JavaScript/URLs/selectors through the shared contract, automated messages, QR/OTP extraction, a replacement WhatsApp protocol, private platform APIs or raw browser-directory copying.

Display data may enter ephemeral Flutter memory for the native widgets. Credentials and archive plaintext remain native-owned and never enter Flutter snapshots, logs, telemetry, screenshots or diagnostic evidence. Actual service tests remain owner-operated; automated tests use fictional fixture data and synthetic keys.

Ten isolated profiles and one live WebView remain. Every read, action, polling result and archive operation is bound to the current profile/view/selection generation, foreground state and app lock. Native privacy protection must cover Flutter-rendered messages synchronously before OS snapshots, not only cover the hidden WebView host.

## Options and selected direction

| Approach | Assessment |
|---|---|
| Phone-adapted official page alone | Useful linking/fallback repair; does not satisfy the user's explicit native-widget requirement |
| Native widgets with a fixed adapter to the existing official client | Selected engineering path; preserves the official messaging protocol but depends on reviewed internal client interfaces and must fail closed on incompatibility |
| A new personal-account messaging protocol client | Outside retained scope; no protocol replacement or assumption of an official consumer API |

For backups, public whole-profile serialization is insufficient. The source-backed candidate is a version-specific semantic migration adapter: decrypt only explicitly identified local wrapping formats, protect recovered state in a native encrypted archive, then recreate destination-local wrappers. This must cover all required dependencies, not merely the two observed AES-CTR values.

## Native messaging components

| Unit | Responsibility | Boundary |
|---|---|---|
| Native messaging models/port | Bounded chat summaries, message pages, readiness, explicit send outcomes | No cookies, keys, paths, DOM or arbitrary script |
| Native chat list | Search/filter, unread/status indications, selected conversation | Flutter widgets; no remote avatar URL fetching or fake content in product |
| Native conversation | Header/back, message types, loading/history, read-only states | Plain text rendering; unsupported content explicitly routes to official UI |
| Native composer | Multiline draft, send progress/failure, account-scoped ownership | No automatic resend after ambiguous timeout or account change |
| Fixed client adapter | Allowlisted collection reads and user-triggered client actions | Exact HTTPS origin/main frame, bounded output, known schema, no generic bridge |
| Native host coordinator | Ownership, visibility, cancellation and synchronous privacy cover | Current view only; polling stops on lock/background/detach |
| Backup & Restore | Selection, coverage, encrypted file operations, staging/rollback | Existing setup format stays distinct; no false success or silent skipped state |

Reviewed public code supplies candidate internal interfaces: `WAWebChatCollection.ChatCollection`, chat/message models, `WAWebChatLoadMessages.loadEarlierMsgs` and `WAWebSendTextMsgChatAction.sendTextMsgToChat`. These are source-visible internals, not a documented supported third-party API. Final adapter signatures, readiness/locked-chat filtering and completion semantics must follow the retained source review and fixtures before wiring real profiles.

A hidden official runtime is allowed only while its exact native host remains owned and the app is foreground/unlocked. The official UI must be reachable without clearing a session. Unknown modules, unsupported schema, account mismatch and lock invalidate results immediately. Chat rows, message bodies and draft text never appear in exception strings or diagnostics. No animation delays privacy covering.

## Interaction and visual contracts

Use existing Profile Desk colors, typography, Tabler assets and motion primitives. The stack detector missed the monorepo's existing Lottie dependency; the actual app already has local animations and Manrope. No new visual dependency is needed.

- Chat list is the first native screen after verified readiness. Compact native account selector and overflow controls leave most height for content.
- Conversation navigation uses an ordinary native Back control and platform back behavior. Drafts are scoped to profile/chat; switching cannot send a draft to another account.
- Rows, header controls and composer actions have at least 48 logical-pixel touch targets. Message text uses normal device-scale typography, never desktop-page scaling.
- Native list scrolling, keyboard inset handling, selectable text and semantic labels are required. Loading, empty, read-only, failed-send, offline, locked and unsupported-adapter states are designed explicitly.
- Sending is a user action. Pending and uncertain outcomes are distinct from delivered/read indicators returned by the client. Retrying after an uncertain outcome requires checking state; never automatically repeat a send.
- Narrow 320–440 widths, 2× text, landscape and tablet layouts must remain reachable. Reduced motion removes decorative transitions; pause animation in the background.
- Attachments, reactions, replies, editing, deletion, group/admin actions, calls, view-once and disappearing content need explicit capability/status handling. Unsupported operations must not be presented as functioning native controls or recorded as implemented.
- The official fallback receives targeted fixes for verified structural failures: primary activation, attribute-only pane changes, overlay reachability, native keyboard dismissal and accurate navigation/status labels. Synthetic fixtures do not prove current service selectors.

## Session and information migration

The static source review proves one narrow format: Signal registration identity public/private bytes are independently wrapped with fresh nonextractable AES-CTR-128 keys using a 128-bit zero counter. The stored wrappers are local protection; the recovered identity bytes are consumed by the Signal client. A fresh key must be generated per destination wrapper because the counter is fixed. This is a semantic migration opportunity, not proof of complete session portability.

Additional dependencies include HKDF base keys, Noise credentials, mutable Signal tables, application encryption, preferences/cache state, screen-lock layers and potentially media. All must be mapped before enabling full export. An enabled website screen lock must be honored; the adapter cannot bypass it.

The native probe reproduces wrapper persistence and independent destination cold reopening with synthetic data: 125 assertions include thirty invalid-input controls and source preservation. Ordinary Xcode Simulator packaging resolved the earlier hand-packaged fixture's Keychain/`DataCloneError` issue. This narrow proof does not establish a complete service session or physical-device restore.

Archive orchestration must validate the complete selected batch before offering a file, encrypt native-owned payloads with a reviewed recovery-secret format, and reject unsupported/inconsistent/oversized state. Import authenticates the archive before allocating fresh profiles, restores before the official client boots, and commits only after all required stages succeed. An owned recovery journal may reclaim only newly staged stores; existing profiles are never overwrite/cleanup targets. Exact cryptographic container choices are a separate gated implementation task after payload feasibility, not an invented completed format.

## Acceptance and release gates

| Requirement | Required evidence |
|---|---|
| Actual native chat list, message rows and composer | Widget/interaction tests plus native integration observation; cosmetic DOM styling does not pass |
| Correct clicks/back/keyboard | Fixture tasks and owned native integration tests; actual service navigation remains owner-operated |
| No cross-account/stale action | Profile switch, timeout, lock, detach and delayed-result fault tests |
| Private native content | Immediate native window cover and accessibility hiding before snapshot; no content in diagnostics |
| User-initiated text send | Synthetic action contract tests; real send only in an explicitly owner-operated test |
| Retained login from archive | Independent fresh store, source inaccessible to destination, cold app restart, no relinking |
| Complete information | Explicit included-state inventory and equality checks; omitted/unknown data blocks a full-backup claim |
| One app | Product routes and operations inside Profile Desk; no Session Lab dependency |
| Deployment | Existing user hold remains until session-retaining restore passes or the user explicitly changes it |

The accompanying implementation plan tracks implemented, verified, blocked and owner-operated gates separately. No checklist may convert a source review, fictional preview or synthetic pass into verified real-service behavior.
