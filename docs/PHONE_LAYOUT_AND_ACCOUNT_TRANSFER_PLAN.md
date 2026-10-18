# Phone navigation and account setup transfer implementation plan

**18 October clarification:** the user requires a restored QR-linked session to remain logged in and has made this a prerequisite for further deployment. Current setup transfer does not meet that requirement. Deployment is on hold; see [verification and required gates](SESSION_RESTORE_VERIFICATION.md).

**Goal:** Deliver readable official web panes on phones and honest import/export of all account setup metadata.

**Architecture:** Static structural layout adapter plus typed owned-view controls. System document pickers exchange a bounded versioned setup archive; native SQLite performs validated batch allocation of fresh stores.

**Tech stack:** Flutter/Dart, Pigeon, Swift/WebKit (iOS 17+), Kotlin/AndroidX WebKit 1.17.1 (Android 29+).

**Spec:** [PHONE_LAYOUT_AND_ACCOUNT_TRANSFER.md](PHONE_LAYOUT_AND_ACCOUNT_TRANSFER.md).

**Execution:** Root owns shared contract, Flutter UI and docs; independent workers own the layout adapter, iOS integration and Android integration. Preserve all prior changes. No commits, push or publication. User's standing autonomous implementation instruction governs routine design choices.

**Status, 18 October 2026:** Product implementation and automated source/fixture checks are complete. Development release build/resource verification is running separately and remains pending below. Real authenticated layout and system document-provider acceptance are not established by these checks. Signed-in session migration remains unsupported. See the [evidence checklist](evidence/phone-layout-transfer/README.md).

## Global constraints

- Exactly ten reserved profiles; one live account WebView; no private APIs or raw store copies.
- Archive <=64 KiB, version 1, format `profile-desk-account-setup`, `requiresRelinking=true`; maximum ten aliases/colors and theme only.
- Do not export credentials or claim signed-in restoration.
- No arbitrary JS/URL/selector in shared contract, no website content in diagnostics.
- Native privacy cover is immediate and outside web transforms; stale ownership must fail closed.
- Serial native build/test workloads on the 16GB host.

## Review focus

1. Unknown service structure must not strand the user; Original layout remains reachable.
2. A same-chat click or a menu click must not be mistaken for another conversation.
3. Capacity/name conflicts between preview and commit must leave existing accounts unchanged.
4. Interrupted provider allocation must remain recoverable, never falsely marked logged in.
5. Picker completion after lock/detach must not import or expose preview data.

## Tasks

### 1. Shared contract and archive preview

- [x] Add WorkspaceLayout enum and two fixed commands in `packages/session_contract/pigeons/session_api.dart`; regenerate with `bash scripts/generate_bridge.sh`.
- [x] Add three archive methods to shared/native adapter and fake engine.
- [x] Create strict bounded `AccountSetupArchive` codec in local_registry; test allowlist, types, limits, duplicate JSON keys, depth, roundtrip and excluded secret/state fields.
- [x] Add AccountService import method preserving timeout reconciliation and refreshing actual state on failure/late result, including imported appearance independently of the initiating route.

### 2. Bundled layout adapter

- [x] Create `packages/session_engine/layout/workspace_layout.js`, with no text/storage/network reads or native message bridge. Viewport metadata is retained only to restore layout configuration.
- [x] Build owned DOM fixture and 59 browser checks covering list/detail/back, retained-side settings/menu, dialog, same selection, responsive image width, resize, unknown structure, cleanup, origin restrictions and reduced motion.
- [x] Configure both platforms to bundle the same local script and include it in native source snapshots/harness resources, with no remote script dependency.
- [x] Verify the exact bundled resource and exclusions in both development release artifacts. SPM uses a checked generated regular copy; its actual Bundle.module loader and packaged hash passed.

### 3. iOS integration and transfer

- [x] Add isolated-world injection and typed commands to WorkspaceWebView/SessionEnginePlugin; preserve desktop-fit Original mode, preauthentication fallback and ownership/cover semantics.
- [x] Add app-owned UIDocumentPicker archive coordinator, bounded reads, explicit export completion/cancel, staging cleanup and lock/detach invalidation.
- [x] Add strict native archive parser and registry batch allocation with fresh identities, preflight and interruption reconciliation.
- [x] Run focused native suites serially: 38 registry/codec tests, 39 engine/lifecycle assertions and 66 viewport/identity/layout assertions passed. The final native suite follows a bounded fixture teardown fix for owned named stores; isolation assertions remain strict.

### 4. Android integration and transfer

- [x] Add trusted-page fixed script integration/commands and attachment wrapper methods. Android uses page-world presentation code without a native message bridge; it does not claim iOS isolated-world equivalence.
- [x] Add app-owned system document open/create flow with bounded stream reads, owned request codes and lifecycle invalidation.
- [x] Add strict native parser and batch allocation; preserve provider isolation and interrupted allocation handling.
- [x] Pass 42 focused Gradle registry/codec/lifecycle tests and release Kotlin compilation; release lint reports zero errors and 18 warnings.
- [x] Complete Android development release build4 packaging/resource verification: 98 unchanged source inputs, matching layout and 25 declared assets, AOT, backup protections, unsigned state and fixture/DEX exclusions.

### 5. Flutter surfaces

- [x] Add compact workspace Chats & menu and explicit layout recovery controls only when an owned ready view is available; preserve cover layout and large text.
- [x] Add Account setup backup screen with export disclosure, import file selection, editable name preview, conflicts/capacity, optional appearance, confirmation and relinking instructions.
- [x] Localize copy; reuse existing tiles/icons/motion and reduced-motion behavior; no new animation dependency.
- [x] Pass widget tests for disclosure, cancel, conflicts, import, errors, appearance reconciliation and 2× text overflow.

### 6. Review, evidence and release preparation

- [x] Run `bash scripts/check.sh`: 83 Dart tests and 49 Python tests pass; inspect the actual fictional fixture screenshots and retain bounded evidence.
- [x] Verify generated Pigeon bindings and localization regenerate identically.
- [x] Review final native lifecycle/ownership and shared UI changes independently; address transient layout-control state and route-independent imported-theme reconciliation.
- [x] Build iOS/Android development releases 0.1.0(4). Signed iOS verification covers 111 unchanged source inputs, signature/profile, AOT, layout, local assets and bounded fixture exclusions; Android verification covers 98 inputs.
- [x] Update compatibility, threat model, design and this implementation/evidence checklist with actual source/fixture results and open physical acceptance.
- [x] Complete release/resume handoff and independently confirm iPhone build4 installation. Launch was attempted and blocked by the locked device; no runtime pass is claimed.
- [x] Record signed-in migration as unsupported, separately from completed account setup transfer.

## Acceptance still open

- [ ] Real authenticated WhatsApp chat/menu selection, same-chat reselection, dialogs and secondary panes on the connected iPhone and supported Android devices.
- [ ] Physical keyboard, actual pinch, rotation and VoiceOver/TalkBack behavior against the live service.
- [ ] Real local/cloud document-provider export/import, cancellation and interruption acceptance on both platforms.
- [x] Final development artifacts verified; iPhone installation and installed version independently confirmed.
- [ ] Foreground launch of build4: iOS denied the attempt because the physical device is locked (CoreDeviceError10002 / Locked).
- [ ] Full signed-in session migration: unsupported by the currently verified complete-store API surface; no credential archive is implemented or claimed.

## Review report

Brainstorming and gstack routing consulted. Native fixture, contract and lifecycle review chosen; browser/site crawls and public SEO work do not apply to this authenticated workspace. Design self-review resolved metadata/session naming, original-layout recovery, fresh store identity, duplicate/capacity revalidation and lock ownership. No external model or unavailable gstack workflow is claimed as run.
