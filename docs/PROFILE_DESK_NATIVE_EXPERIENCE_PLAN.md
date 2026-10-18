# Profile Desk native experience implementation plan

> For agentic workers: execute the assigned units with explicit file ownership and independent review. Preserve other workers' edits. The user's existing direction selects autonomous implementation without routine stage-approval prompts. No commits, publication or product deployment are implied.

**Goal:** deliver actual native messaging and session-preserving backup/restore inside Profile Desk, with an official linking/fallback surface.

**Architecture:** Flutter renders filtered native chat/message models. A fixed native-owned adapter delegates explicit actions to the existing official client, bound to the current isolated view. Backup uses a separately reviewed semantic-state adapter and native encryption/staging; setup-only files retain their existing meaning.

**Tech stack:** existing Flutter/Riverpod/Pigeon, Kotlin/Swift, public WebView/WKWebView, local Tabler/Lottie assets; no new visual library.

**Spec:** [PROFILE_DESK_NATIVE_EXPERIENCE.md](PROFILE_DESK_NATIVE_EXPERIENCE.md).

## Global constraints

- Actual native chat lists, messages and composer are required; CSS-only changes do not close that requirement.
- Ten isolated profiles, one live official WebView; every action/result belongs to an exact view and selection generation.
- No arbitrary script, URL, selector or filesystem path in the shared contract.
- No automated real messages or QR linking. Automated tests use fictional data and synthetic keys.
- Credentials/archive plaintext remain native-owned; native display content is ephemeral and excluded from logging/diagnostics.
- A native window-level cover must protect Flutter messages synchronously on privacy transitions.
- Existing setup archives remain setup-only; complete session/data export cannot silently omit unknown state.
- Product deployment remains held pending independent session restore and cold restart without relinking.

## Review focus

1. Locked/view-once/disappearing/hidden chats and messages must not leak through collection snapshots; source-backed visibility filtering is mandatory.
2. Delayed snapshot/send callbacks after profile switch, lock, route disposal or timeout cannot update another conversation or resend.
3. Native message content must be covered before OS snapshots even while Dart is delayed.
4. Ambiguous send outcomes must never be promoted to delivered or retried automatically.
5. A syntactically valid but incomplete credential archive must fail before being offered as a complete backup.

## Task 1: Public interface and migration evidence

Files: `build/session-state-public-review/`, reviewed non-sensitive evidence under `docs/evidence/session-portability/`; native interface review under `build/native-chat-public-review/`.

- [x] Trace public Signal registration wrapper writes, reads and identity consumers; preserve source hashes and exact module references.
- [x] Identify additional HKDF, Noise, preference/cache and application-encryption dependencies; keep full restore unproved.
- [x] Map native chat visibility, message pagination and text-send result semantics from the same bounded unauthenticated public corpus.
- [x] Independently review the proposed fixed interfaces and reject collection dumping or undocumented side-effectful selection setters. Review identifies an unresolved positive live service-unlock gate; this is not approval to activate an adapter.

No real account/runtime/key operations in this task. A reviewed internal interface is not a stable public API guarantee.

## Task 2: Native messaging widgets and state controller

Create under `apps/mobile/lib/features/messaging/`: `native_messaging_models.dart`, `native_messaging_port.dart`, `native_messaging_controller.dart`, `native_messaging_workspace.dart`. Tests: `apps/mobile/test/native_messaging_test.dart`. Localized strings belong in `app_en.arb` and generated localization files, coordinated with other edits.

Interfaces:

- Immutable `MessagingScope` captures profile ID, view-instance ID and selection generation; no mutable global selected-account lookup in a pending action.
- `NativeMessagingPort` exposes scoped chat-list loading, scoped message-page loading and explicit text sending only. The production adapter is a later task; no fake port is registered in the product.
- Models cover a filtered chat summary, a message page, delivery state and explicit send outcome. Unsupported/private content has no body payload.
- `NativeMessagingWorkspace` consumes the port/scope and an explicit official-interface callback. It contains real native list/message/composer widgets; fictional content exists only in tests.

- [x] Implement native chat list/search, selection and conversation Back with appropriate empty/loading/error/read-only states.
- [x] Implement native text rows, unsupported-content handling, pagination and keyboard-aware composer.
- [x] Implement account/chat-scoped drafts and single-flight send; preserve failed/uncertain draft and never auto-retry.
- [x] Test actual tap/type/back/send interactions, no duplicate send, delayed result after scope change/disposal, failure/uncertain outcomes, read-only chat, pagination and supported/unsupported content.
- [x] Test 320×568 and 440-point widths, 2× text, keyboard insets, accessibility and reduced-motion behavior. Render fictional previews for visual inspection.
- [x] Run focused Flutter tests and analysis after coordinating the heavyweight native slot. Thirty focused messaging cases and all 87 mobile tests pass; whole mobile analysis is clean. [Fixtures/lifecycle contract](../apps/mobile/test/fixtures/native_messaging/README.md).

This task can be implemented with a deterministic port fixture while source visibility rules are reviewed. It is not a live-service integration pass and must not expose simulated conversations in the application.

## Task 3: Fixed adapter and native privacy integration

Planned seams: `packages/session_contract/pigeons/session_api.dart`, generated bindings, `packages/session_engine/lib/session_engine.dart`, native `SessionEnginePlugin.swift` / `AndroidSessionEngine.kt` / `AttachedSessionHostApi.kt`, and a new bundled fixed native-messaging script.

- [ ] Finalize the exact DTO/action contract from Task1; retain bounded payload sizes, known message types, view identity and explicit compatibility failures.
- [ ] Implement fixed-origin/main-frame adapter reads and explicit user-triggered actions using reviewed official-client modules. No arbitrary bridge or collection dump.
- [ ] Implement native ownership, foreground/lock guards, cancellation, callback validation and visible/hidden official surface switching.
- [x] Add full-window native privacy covering for native Flutter chat content and test immediate protection before delayed Dart work. Both native covers protect the entire app window and end input; live messaging-port integration remains open below.
- [ ] Test missing/changed modules, locked/private/unsupported content, oversized/malformed snapshots, cross-account/stale results, duplicate-action prevention and unknown send outcome.
- [ ] Integrate native workspace readiness and fallback into `WorkspaceScreen`; stop polling on lock/background/detach. Keep QR linking owner-operated.
- [ ] Verify native compilation and deterministic owned WebView fixtures before any actual-profile observation.

This task depends on the source-backed visibility/action contract. An adapter failure reveals an explicit official fallback rather than raw private data or invented chat state.

## Task 4: Official fallback interaction fixes

Files: canonical `packages/session_engine/layout/workspace_layout.js`, `tests/workspace_layout/`, generated SwiftPM resource, native workspace layout methods and focused native fixtures.

- [x] Reproduce primary row-button/accessory distinction and attribute-only pane transitions before modifying the adapter.
- [x] Correct structural observation without reacting endlessly to owned mutations.
- [x] Reproduce nested and edge-positioned dialogs/menus; make supported overlays reachable without moving service nodes or synthetic clicks.
- [x] Dismiss native keyboard on list return without reading/changing draft content; test stale view and draft preservation.
- [x] Add bounded typed layout-state feedback, explicit Original recovery and owned Android Back. Keyboard hides first, detail returns to list, menu provides guidance, and root/nested routing remains ordinary. Route hide, lifecycle/lock/cover/navigation round trips permanently invalidate pending replies.
- [x] Run browser, native viewport/resource and ownership checks: 73 browser cases, 94 iOS viewport/privacy/status assertions, resource-loader checks and 57 Android unit tests pass. Actual service selectors remain separately unverified until owner-operated testing.

## Task 5: Synthetic native semantic-state migration

Ownership: new `tests/session_portability/registration/` and `build/session-registration-*`.

- [x] Reproduce exact AES-CTR registration wrapper structure using synthetic identity bytes and distinct per-envelope keys.
- [x] Resolve the earlier WebKit CryptoKey persistence fixture failure using ordinary Xcode build/installation, public APIs and matched signing/configuration controls. Same Swift/JS assertions pass without relaxed limits.
- [x] Preserve source data, migrate semantic bytes, create fresh destination wrappers and verify equality/wrong-key controls after separate destination process restart and owned simulator reboot. [92-assertion proof](evidence/session-portability/registration/README.md).
- [x] Reject malformed wrappers, wrong algorithm/usages, shared counter/key misuse and incomplete payloads. Thirty invalid-input controls pass without source mutation or unsafe CTR reuse; the expanded cold migration passes [125 assertions](evidence/session-portability/registration/fault-controls/README.md). Plaintext remains in test memory only.
- [x] Clean only owned stores/simulator/resources and preserve initial failures. No physical app installation is part of this task.

## Task 6: Complete payload boundary and encrypted archive

This remains a blocking implementation gate rather than a claim of a finished format.

- [ ] Establish exact version-pinned coverage for required mutable Signal state, Noise, screen-lock layers, preferences/caches and encrypted application data; classify local conversation/media coverage separately.
- [ ] Prove a consistent capture strategy and empty-origin restore before the official client starts. Unknown required state rejects the entire selected export.
- [ ] Select and review a concrete bounded authenticated-encryption/KDF container and recovery UX using current native primitives, then implement native-only archive code and tamper/wrong-secret/resource-limit tests.
- [ ] Implement sequential multi-profile export, file-provider operations, cancellation, source preservation and native-owned sensitive staging cleanup.
- [ ] Implement fresh-profile import journal, whole-batch commit/rollback and process-interruption recovery; never reuse original profile identity as restore proof.

Task6 cannot be marked implemented from Task5's narrow wrapper pass. Native-window/privacy and operation ownership from Task3 also apply to all archive UX.

## Task 7: Single-app backup UX and final verification

Files: `apps/mobile/lib/features/backup/`, workspace navigation, existing setup screen/native archive routes and localization/tests.

- [ ] Present Backup & Restore inside Profile Desk with explicit full-session/data coverage and setup-only alternative. Do not rename setup JSON into a session archive.
- [ ] Wire real session operations only when Task6 supplies a functioning payload path; no misleading enabled export action or fake success.
- [ ] Test selected accounts, capacity/conflicts, secret entry/recovery, complete/unsupported coverage, cancellation, lock, malformed files and fresh-profile import outcomes.
- [ ] Perform independent review of all changed units; run relevant shared/native suites and artifact exclusion checks.
- [ ] Produce current signed development artifacts only after source/tests match; preserve existing Profile Desk and Session Lab data.
- [ ] Owner-operated service checks: native list/navigation/keyboard, explicitly initiated send, source/destination isolation, full selected-data coverage and cold restart without relinking.
- [ ] Deploy the product only when the user's retained session-restore condition is demonstrated or explicitly changed.

## Current status

Native messaging components and their thirty interaction/fault cases are implemented; the full mobile suite passes 87 tests. The production port is not registered, so this does not yet provide live native WhatsApp conversations. A source-backed text path exists, but positive service-unlock state and relock transitions remain unproved; socket state/defaulted lock settings are insufficient. Typed lock-error purging and native keyboard privacy issues found by independent review are fixed.

Fallback/browser checks pass 73 cases; final iOS viewport/privacy/status checks pass 94 with unchanged input/package hashes. SwiftPM resource delivery passes. Native full-window protection exists on both platforms, with actual service/widget integration still required. A narrow synthetic registration-wrapper migration passes 125 assertions, including thirty invalid-input controls, across cold process/reboot with source preservation. Twenty-four encrypted columns across fourteen application schemas are mapped in public source, while Worm key consumers, the final-salt restore/bootstrap barrier, complete payload consistency and authenticated restore remain open. Normal-browser final salt and FTS blind-index consumers are mapped; safe complete migration is not yet proved.

No new product deployment or verified authenticated restore. Every unchecked item is required/open, not implicitly skipped. [Current evidence and limits](evidence/native-experience/README.md). A blocked platform/service capability must be recorded with evidence and user-visible consequences rather than silently replaced by a narrower feature.
