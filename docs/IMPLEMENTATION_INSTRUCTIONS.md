# Complete Android and iOS implementation instructions for a ten account WhatsApp Web session manager

You are the lead mobile architect and implementation engineer for this project. Execute the complete scoped implementation: inspect the repository, verify the platform constraints, plan the work, write the application, integrate both native engines, test what the environment genuinely supports, fix defects, prepare release materials, and produce a precise handover.

The intended product is a Flutter Android and iOS application with a persistent native account selector at the top. One authorized operator can save up to ten separately linked WhatsApp account profiles and open the selected account’s official WhatsApp Web session. Each profile has an isolated persistent browser store. Begin with one live account WebView at a time.

This is an instruction to perform the work. Do not finish after providing a plan, architecture diagram, scaffold, mocked demonstration, one platform, or one phase. Continue through all dependency-ready tasks that are authorized and executable. Keep implementation progress, test evidence, and release permission as separate facts.

## 1 Working authority scope and continuity

1. Read the current repository instructions and inspect the working tree before editing. Preserve unrelated changes, existing secrets, signing settings, and useful implementations. Do not reset the repository, overwrite user work, delete branches, force-push, or rewrite project instructions to remove restrictions.

2. If `WhatsApp_Web_Android_iOS_Application_Plan.docx` is supplied, read its entire body, tables, acceptance catalog, phase checklists, risk register, and source references. A filename or preview is insufficient. Use available DOCX extraction tools; preserve table rows and hyperlinks. This prompt is self-contained enough to start when the document is unavailable. Record that limitation and continue instead of asking for the attachment again.

3. Treat explicit user instructions as controlling. Use the source plan as the product baseline and current verified platform documentation as the implementation authority for API behavior. Record conflicts and resolve routine engineering choices. Do not invent permission, compatibility, SDK capabilities, credentials, or successful tests.

4. This request authorizes all independent, reversible local implementation, configuration, documentation, debugging, and testing needed for the defined product. It does not imply permission to purchase services, acquire accounts, message arbitrary recipients, disclose secrets, distribute builds publicly, or submit to app stores. Reuse explicit authorization already present in the session; do not ask for it again.

5. When an external action needs authorization that has not been provided, finish its concrete build, configuration, evidence, and review package first. Ask only for the remaining action. Never use missing release permission as a reason to abandon independent code or tests.

6. If a toolchain, device, account, service permission, or elapsed test period is missing, record the exact blocker once and continue independent work. Do not wait indefinitely, fabricate a result, or keep repeating the same question.

7. Do not expand the product after every feature. Add work only to satisfy an existing requirement, correct a defect, or address an evidenced compatibility or privacy risk. Record unrelated ideas separately without implementing them.

8. If the session is interrupted or context becomes limited, checkpoint actual repository state, completed work, pending tasks, commands, results, and blockers in `docs/RESUME.md`. On continuation, read that checkpoint, inspect the current diff, and resume without restarting or duplicating completed work. Never put secrets or session data in the checkpoint.

9. Give concise progress updates explaining completed outcomes, findings, and the next dependency being resolved. End only when executable scoped work is complete or every remaining task has a concrete unresolved dependency.

## 2 Fixed product requirements and exclusions

Implement these baseline decisions:

- One operator and up to ten linked account profiles per installation, including incomplete linking setups. This is not a ten-employee identity or role system.
- A native selector that remains reachable above the web content during loading, failures, and recovery.
- A stable random identifier for every profile, independent of alias, list position, phone number, and selected row.
- Official HTTPS WhatsApp Web content in a profile-specific persistent browser store.
- Official QR linking approved in the primary WhatsApp app. Official phone-number linking is conditional on availability and verification.
- One live WebView across the application initially. Do not preload ten websites or keep hidden inactive WebViews.
- Flutter shared UI, a typed platform contract, Swift iOS engine, Kotlin Android engine, and a transactional local registry.
- iOS 17 or later as the planned deployment baseline. Android 10/API 29 or later as the proposed product minimum, with mandatory runtime WebView capability checks.
- Phone-first UI with tablet, landscape, keyboard, resizing, accessibility, and larger-text validation.
- Optional OS-backed app lock, background preview protection, safe navigation, scoped permissions, and local cleanup.
- No separate application registration, custom password login, OTP system, or app-owned messaging server.
- English shell with localization-ready strings. Preserve an existing localization convention; additional languages must not alter the external website.
- A free development/beta baseline. Do not add payments, advertisements, subscriptions, tracking, or remote configuration without a separate requirement.

Required user features are add, name, rename, reorder, select, link, relink, reload safely, remove one profile, remove all local profiles, view compatibility details, configure privacy, and access useful recovery/help screens. Implement validated foreground text, photo, and document flows through the official website.

Treat voice notes, direct camera capture, calls, video calls, and foreground message indicators as separate capability gates. Provide them only when the actual embedded flow is supported and tested. If an essential photo/document flow fails, report it as a release gap rather than quietly changing the requirement.

Do not implement a unified inbox, server-hosted sessions, QR relays, session export/import, cloud session sync, contact/chat scraping, DOM extraction of conversations, automated sends, scheduled messages, bulk messaging, automatic replies, AI summaries, translation, or private WhatsApp protocol clients.

Do not promise continuous synchronization, current unread counts, or notifications for inactive profiles. Do not request notification permission without a real supported event source and an approved feature.

The Business Platform is a different product alternative. If the wrapper is not viable, prepare a specific alternative proposal; do not silently replace this application with a business inbox, backend, or multi-tenant system.

## 3 Initial inspection and official source verification

Start by inventorying:

- Repository structure, git status, applicable instructions, current application architecture, and reusable code.
- Host OS; available Flutter/Dart, Swift/Xcode, Kotlin/Java/Gradle, Android SDK, and package tooling.
- Existing native plugins and their construction/lifecycle behavior.
- Available emulators, simulators, connected physical devices, OS releases, and Android WebView providers.
- Existing CI, signing access, application identifiers, flavors, and deployment processes without exposing secret values.
- Availability of specifically authorized test accounts, pairing devices, consenting test recipients, and permission evidence.

Use `rg` and targeted reads for repository discovery. Run independent inspections in parallel when supported. Do not dump secrets, complete environment variables, browser databases, or private account data.

Reverify current primary documentation before choosing or calling platform APIs. Record URLs, access date, relevant finding, and resulting decision in the research/architecture record. At minimum verify:

- WhatsApp linking flows, supported clients, linked-device constraints, and applicable service guidance.
- Apple persistent website data stores, deletion, navigation, downloads, app lifecycle, and minimum-functionality/service-access review rules.
- AndroidX profile creation/assignment, profile loading/deletion restrictions, browsing-data deletion, feature flags, thread rules, and provider behavior.
- Flutter platform views, platform channels/Pigeon, and compatible build-tool versions.
- Current app-store SDK/target API, privacy, and review requirements.

Use the document’s dated versions as research starting points, not permanent pins. Select compatible stable versions and record the actual versions tested. Keep deployment minimums distinct from compile SDK, target SDK, and store upload SDK. Availability-check newer optional APIs.

If current documentation is inaccessible, use the supplied baseline cautiously, mark the specific claim unverified, and continue work that does not depend on it. Do not assert that a package version or method exists merely because it sounds plausible.

Keep these independent gates visible:

- **G1:** Service-use and distribution basis.
- **G2:** Actual embedded WhatsApp compatibility.
- **G3:** Ten-profile storage isolation and account binding.
- **G4:** Lifecycle, restoration, recovery, and deletion.
- **G5:** Phone usability and supported media.
- **G6:** Release readiness and distribution authorization.

An account owner approving a QR link is different from provider permission to distribute the integration. Mainstream browser support is different from embedded-client support. Extra native screens, original branding, internal distribution, or an unofficial disclosure do not establish permission or guarantee acceptance.

Run synthetic/local implementation work while external evidence is pending. If a core isolation gate actually fails, repair that architecture before adding dependent features. Do not defeat an intentional restriction or conceal an unsupported client.

## 4 Execution plan traceability and collaboration

Create `docs/MASTER_IMPLEMENTATION_PLAN.md` as the authoritative dependency-ordered implementation checklist. Extract requirements from every plan section, not just its feature table.

For each requirement record:

- Stable requirement ID.
- Source section or prompt clause.
- Required, conditional, excluded, rationale, or external-dependency classification.
- Platform and owning module.
- Dependencies.
- Implementation status and code reference.
- Acceptance-test IDs.
- Validation status and evidence reference.
- Defect/blocker and the exact next action.

Use distinct namespaces: `REQ-*` for requirements, `AT-A01` through `AT-S12` for acceptance tests, and `SRC-S01` through `SRC-S36` for the source plan’s references. Preserve original acceptance identifiers through this prefix mapping.

Keep implementation status separate from validation status. Validation values must distinguish:

- `NOT_RUN`
- `PASS`
- `FAIL`
- `BLOCKED_ENVIRONMENT`
- `BLOCKED_HARDWARE`
- `BLOCKED_SERVICE_ACCESS`
- `PENDING_ELAPSED_TIME`
- `NOT_APPLICABLE_WITH_REASON`

Skipped tests never count as passed.

Prepare substantive documents with actual decisions and findings: product requirements, system design and ADRs, security/privacy model, testing/evidence ledger, compatibility matrix, build/release guide, support/incident runbook, and `RESUME`. Consolidate related material when appropriate; do not create dozens of empty documentation files.

If agent tools are available, delegate real independent work within actual concurrency limits. Suitable assignments are iOS engine, Android engine, Flutter UI/registry, and QA/security review. Establish contract and file ownership before parallel edits; use isolated worktrees where helpful and authorized. The lead owns integration and verification. Do not invent agent capabilities, models, or results.

For each implementation unit:

1. Inspect the affected code and requirements.
2. Make the smallest complete change.
3. Run meaningful checks.
4. Fix failures at their source.
5. Update evidence and checklist.
6. Integrate.
7. Continue.

Preserve existing BLoC/Riverpod or equivalent conventions. If no convention exists, choose Riverpod and document the decision. Do not introduce two competing state systems.

## 5 Repository and architecture

Use one modular mobile repository. Adapt an existing layout instead of duplicating it. A suitable new layout is:

- `apps/mobile/lib/app`
- `apps/mobile/lib/features/accounts`
- `apps/mobile/lib/features/workspace`
- `apps/mobile/lib/features/privacy`
- `apps/mobile/lib/features/help`
- `packages/session_contract`
- `packages/session_engine/ios`
- `packages/session_engine/android`
- `packages/local_registry`
- `tests/profile_harness`
- `tests/device_flows`
- `docs`
- `scripts`

Make the session engine a correctly registered Flutter plugin/platform-view integration, including real platform manifests, build configuration, generated bindings, and lifecycle hooks. Directories and pseudocode do not satisfy implementation.

Keep UI, domain coordination, persistence, and platform mechanisms separate:

- `AccountService` owns add/rename/reorder/relink/remove use cases and capacity.
- `SessionCoordinator` serializes selection and visibility.
- `ProfileRegistry` persists metadata and lifecycle records.
- Native engines own immutable profile-to-WebView binding.
- `PermissionBroker` owns origin/profile-scoped decisions.
- `TransferManager` owns native picker and transfer lifetimes.
- Cleanup coordination owns durable deletion progress and reconciliation.

Use SQLite with migrations or an equivalently transactional existing local store. Do not introduce microservices, a messaging backend, or unnecessary authentication infrastructure.

Create development, QA/test, and production application identities so test stores cannot become production sessions. Public configuration may contain environment name, log policy, and development harness origin. Never embed secrets in Dart defines or checked-in environment files. Production must not accept arbitrary user-configured workspace URLs or remote executable scripts.

Provide a fake engine for deterministic UI/coordinator tests. Production must use the real native engine and fail explicitly when unavailable. A fake, placeholder, catch-and-return-success implementation, or TODO cannot satisfy a native requirement.

## 6 Local records allocation and startup reconciliation

Implement these records or equivalent typed entities:

- **AccountProfile:** immutable `id` and `platformProfileId`; alias; normalizedAlias; color; orderIndex; createdAt; lastOpenedAt; allocation/lifecycle state.
- **ProfileObservation:** profileId; observation; observedAt; evidenceType.
- **AppPreferences:** lockMode; returnLockPolicy; locale; theme; diagnosticsChoice.
- **PermissionDecision:** profileId; canonical origin; capability; decision; updatedAt.
- **TransferTask:** taskId; profileId; viewInstanceId; operation ownership; state; short-lived private staging reference.
- **CleanupJournal:** profileId; cleanupOperationId; stage; attempts; lastErrorClass; updatedAt.
- **SchemaVersion:** version and migration history.

Do not persist messages, contacts, page HTML, cookies, QR payloads, pairing codes, OTPs, IndexedDB copies, or WhatsApp cryptographic material in these records.

Account allocation must reserve capacity transactionally before native allocation. Normalize aliases by trimming and case-insensitive comparison, enforce uniqueness, and provide useful validation for empty or long labels.

The metadata database and native browser store do not share one atomic transaction. Implement a journaled allocation workflow with compensation/reconciliation for crashes between reservation, native store creation, finalization, and first load. Repeated Add taps must never allocate an eleventh account or duplicate a reservation.

Preserve backing identifiers during rename, reorder, app upgrade, and metadata migration. A replacement profile receives a new identifier. Never reuse a deleted identifier or assign an orphaned store to a different account.

At startup, reconcile registry records, pending allocation, cleanup journal, and the public native store inventory before opening any session. Missing stores, surviving orphan stores, and inconsistent restored records need explicit states. Do not silently create an empty replacement and label it authenticated.

Choose one durable authority for lifecycle/journal stages. Document ownership and bootstrap ordering across Flutter and native code. Native startup must be able to honor tombstones before any plugin, profile getter, preload, or view creation loads a target pending deletion. If callbacks can complete without the Dart UI, the durable completion path must still be reliable; avoid unsynchronized duplicate journals.

Define exactly when capacity is released during deferred deletion/relink replacement. Keep at most ten user-accessible/reserved account slots, never reuse pending storage, bound any temporary cleanup containers, and prevent repeated create/remove cycles from consuming capacity forever. Treat this as a tested architectural decision.

Normal app upgrades should retain valid profiles. Reinstall, backup restoration, and a new phone follow the verified reset/quarantine/relink policy. A matching UUID or a simple installation flag alone is not proof of restore trust.

## 7 Typed platform contract and state model

Generate a typed Dart/Swift/Kotlin contract using Pigeon or an equivalent established mechanism.

Include operations equivalent to:

- `queryCapabilities`
- `allocateProfile`
- `openProfile`
- `disposeView`
- `reloadProfileView`
- `requestLocalRemoval`
- `retryPendingCleanup`
- `setPrivacyCover`
- `cancelTransfer`
- Typed engine events.

Define explicit error classes, idempotency, cancellation, timeouts, and required execution threads. Keep platform exceptions from becoming uncaught UI crashes. A timeout means an operation needs reconciliation; it is not proof that a native mutation never happened.

Separate state dimensions:

- **Store:** reserving/allocating, available, removing, cleanup pending, missing/quarantined.
- **View:** detached, loading, visible, disposing, failed.
- **Authentication observation:** unknown, user confirmed, relink requested, revocation observed when supported.
- **Network:** unknown, offline, reachable.

A reachable network, completed navigation, title, or HTTP success does not establish WhatsApp authentication, account identity, or synchronization. Use honest Saved/Last opened/User confirmed labels when that is all the app knows.

Define event ownership separately:

- **View events:** profileId, viewInstanceId, operationId, selectionGeneration.
- **Transfer events:** original profile/view/operation and their explicit lifetime policy.
- **Cleanup events:** profileId, cleanupOperationId, and journal stage independently of the active selection.

The production contract must not expose arbitrary JavaScript execution, page extraction, cookie export, session import/export, or native filesystem access. Flutter-to-native controls are not a webpage JavaScript bridge. Any test instrumentation must be restricted to the controlled harness and excluded from production.

## 8 Race-safe account selection and recovery

Enforce these invariants in real code and tests:

1. A WebView is bound to one immutable profile before navigation.
2. Only the latest valid selection transaction can reveal content.
3. The visible native alias and attached profile must match before removing the cover.
4. Every async callback validates its appropriate ownership after asynchronous boundaries.
5. Removing/tombstoned profiles cannot reopen through callbacks, retries, or restore.
6. View disposal never wipes persistent session data.
7. File results cannot reach another account.
8. Recovery never synthesizes message sends or replays account operations.

Implement selection in this order:

1. Serialize the request and assign a monotonically increasing generation.
2. Put an opaque native cover over the outgoing content before changing the visible alias.
3. Resolve known native file pickers, permission prompts, recordings, and transfer guards.
4. Dispose and release the outgoing WebView while retaining its persistent store.
5. Resolve the target’s immutable identifier and lifecycle eligibility.
6. Construct/bind the target view.
7. Validate profile, view, operation, and current generation before displaying it.
8. On failure, retain an account-specific recovery screen and usable selector.

A newer selection supersedes an unfinished older one. Cancellation must not leave leaked views or release another operation’s resources.

Give a clear first-use explanation that switching can lose unsent drafts, scroll state, or transient page activity. When a known native operation is active, offer a deterministic finish/cancel choice. Do not inspect conversation text to detect drafts.

Complete picker callbacks exactly once, including cancellation, view disposal, activity interruption, and profile removal. Discard stale URI grants and temporary files safely.

A valid inactive-profile cleanup completion must advance its journal after the user switches elsewhere. Do not reject it merely because its profile is not selected. It must not reveal content or alter the current workspace.

Implement bounded, visible renderer/reconnect recovery. Preserve the affected profile, distinguish service outage from corruption, and avoid infinite reload loops. After uncertain send status, let the operator inspect the official interface. Do not claim control over the website’s own internal delivery/retry behavior.

Keep the single-live-view rule application-wide. Disable unsupported multi-window/multi-scene behavior explicitly rather than accidentally creating one active account view per window.

## 9 iOS engine implementation

Use public Swift/WebKit APIs with iOS 17 as the baseline unless a documented requirement change is approved.

For each profile, use its stable UUID with `WKWebsiteDataStore(forIdentifier:)`, set `WKWebViewConfiguration.websiteDataStore` before constructing `WKWebView`, and reopen the same named store on subsequent ordinary launches.

Do not use the default persistent store for account slots, cookie swapping, separate process pools, or separate WebView objects as a substitute for isolated stores. Do not invent private API workarounds.

Run UIKit/WebKit lifecycle work on the required main actor/thread. Use appropriately available `WKNavigationDelegate`, `WKUIDelegate`, `WKDownload`, and content-process termination callbacks.

iOS has no `WKWebView.destroy()` equivalent. Implement disposal concretely: cancel owned operations, stop relevant loading, remove the view, disconnect observers/delegates/handlers where appropriate, release engine references, and verify no unintended retain cycle remains. Keep the persistent store.

Compare ordinary rendering and the public desktop-content preference using the real prototype. Do not make browser impersonation or an access-control bypass a prerequisite.

Evaluate App-Bound Domains against observed legitimate navigation. Its domain limit is not the account limit. Validate service-worker registration, update, restoration, and cleanup in all ten named stores, especially profiles four through ten. Historical engine discussions are test inputs, not proof of current behavior.

For local deletion: persist removing state, block access, stop owned activity, release every view referencing the store, invoke the public named-store removal API, and handle the actual completion/error. Clean app-owned records and files using a durable journal. An unavailable or failed API leaves cleanup pending.

Do not reopen a production tombstoned session to inspect deletion. Controlled destructive verification belongs in the test harness. Quarantine orphan stores through public APIs; do not edit WebKit’s live database files.

Handle content-process termination by recreating only the affected view against the same eligible store. Disable production inspectability. Availability-check optional APIs newer than iOS 17. Record realistic background suspension, eviction, and relinking behavior without claiming indefinite persistence.

## 10 Android engine implementation

Use Kotlin and a verified compatible stable AndroidX WebKit release.

Before allocation check an available provider, `WebViewFeature.MULTI_PROFILE`, and `WebViewFeature.DELETE_BROWSING_DATA` for the planned immediate wipe route. Reevaluate after provider changes. The Android version, installed library, compile SDK, and target SDK do not establish provider support.

The native factory must create `WebView`, immediately bind the permanent profile through `WebViewCompat.setProfile`, and only then configure or navigate it. Audit Flutter plugins for any hidden configuration or loading before assignment. Never rebind an existing view.

Use profile-scoped `CookieManager`, `WebStorage`, and `ServiceWorkerController`. Native grants, pickers, files, and transfers also require explicit scoping. Avoid default-profile helpers in cleanup/download code.

Implement Android disposal on the correct thread: detach, destroy, and release the view without clearing session data. Handle `onRenderProcessGone` with bounded recovery against the same profile. Do not treat `onPause` as proof all JavaScript stopped, and do not use global `pauseTimers` as a per-account control.

Implement removal as a persistent state machine with distinct stages for:

- Requested.
- Access blocked.
- Clients disposed.
- Website wipe pending.
- Website wiped.
- App data cleanup pending.
- Container deletion pending.
- Complete.

Preserve these behaviors regardless of chosen names:

1. Persist the tombstone and deny new opens, restore, and late page writes.
2. Obtain the target’s existing scoped `WebStorage` handle without recreating an absent profile.
3. Cancel owned native operations, detach/destroy every associated view, and release references.
4. Prevent concurrent target loads/restores while wiping.
5. Invoke the verified profile-specific browsing-data deletion API and await its actual callback.
6. Handle errors, process death, provider loss, and disk failures explicitly.
7. Clean target-owned staging files and permission records.
8. Track final native profile-container deletion separately.
9. Complete `ProfileStore` deletion during a clean startup before `getProfile`, `getOrCreateProfile`, `setProfile`, or other code loads that target.
10. Reconcile before opening saved accounts; handle an already absent target idempotently.

Reverify the exact loaded-profile deletion restriction and enumeration behavior in current documentation and instrumentation. Destroying a visible WebView alone must not be assumed to make immediate `deleteProfile` legal.

Handle `deleteProfile` return semantics correctly: `true` means the profile existed and deletion was accepted; some disk cleanup can remain asynchronous. `false` means the profile was absent. Do not equate either result with a separately verified completed website-data wipe.

Enumeration includes the default profile: never delete it, and reconcile only clearly app-owned account stores. Keep ambiguous inventory entries quarantined rather than assigning or deleting them blindly. Verify these behaviors against `SRC-S20`.

Browsing-data deletion is not atomic relative to concurrent writes. Test and document service-worker quiescence and the evidence supporting successful cleanup. Do not claim forensic erasure or guarantees unsupported by the API.

If required provider capabilities disappear, retain blocked access and a pending wipe until support returns. Management, cleanup requests, compatibility guidance, and official remote-unlink help must remain available. Never show false success.

Do not force-kill the app as a cleanup UX, delete all profiles to remove one, manipulate live Chromium databases, or use ten processes/data directories as an unplanned fallback. A supported-capability failure must never fall back to shared storage.

## 11 Screens pairing and account-management behavior

Implement the welcome, empty, add-account, linking, workspace, account-manager, profile-settings, privacy-settings, recovery, and help/diagnostics screens.

Use a native top selector with alias, color/monogram, selected indicator, and dropdown. On phones use an accessible sheet; on tablets use an anchored popover. Show capacity, Add account, and honest status. Long aliases need an accessible full label. Use text/icons in addition to color.

Keep destructive actions in management with a confirmation naming the target profile. Separate remove-local-profile from remote unlink. Removing local access while offline must not imply the service’s linked-device record was revoked.

First pairing:

1. Explain local session storage and foreground/inactive-account limitations.
2. Check capabilities.
3. Collect alias and reserve capacity.
4. Allocate and bind the isolated native profile.
5. Load the official [WhatsApp Web website](https://web.whatsapp.com/).
6. Explain official primary-device “Linked devices” → “Link a device” approval.
7. Let the primary device scan the displayed QR.
8. Ask the operator to verify the account shown by the official site and confirm the alias.

Keep host instructions outside the webpage. Do not collect QR values, OTPs, credentials, or pairing codes. Displaying a QR does not require this app’s camera permission.

Explain same-phone pairing before it becomes a dead end. Provide official phone-number linking only after its actual flow works in this client; otherwise explain the separate-device requirement. Opening another browser’s QR links that browser’s profile, not this application’s selected profile.

Handle QR expiration/reload, already-full linked-device allowance, cancellation, wrong-account pairing, and relinking without inventing verification. Partial setup offers Keep for later or Remove local setup with correct capacity and crash recovery.

Relinking a valid existing context is deliberate. Corrupt-store replacement receives a new ID and journaled cleanup of the old store; preserve alias only through an explicit choice. Do not wipe all profiles to fix one account.

Implement safe areas, keyboard/IME overlap, focus, scrolling, large text, light/dark shell themes, orientation, tablet resizing, accessible error states, and selector reachability. Use original placeholder branding pending a final approved name; do not invent ownership or trademark clearance.

## 12 Navigation permissions files and media

Parse URLs canonically and check scheme and exact host. Do not authorize by substring or suffix matches that accept malicious lookalike hosts. Distinguish main-frame navigation from legitimate third-party subresources and document the tested origin policy.

Keep expected workspace navigation in the bound view. Route ordinary external links through an appropriate system browser after user action. Handle redirects, telephone links, app deep links, unsupported schemes, and new-window requests explicitly.

Popups must not silently create a default-profile or hidden second WebView. Choose a tested same-context route or explicit unsupported behavior consistent with the one-view rule. Do not broadly block legitimate service assets without testing.

Never bypass invalid TLS, disable Safe Browsing where supported, introduce broad mixed-content/transport exceptions, or expose arbitrary local files.

Use no general webpage-to-native bridge. A narrow future bridge requires a reviewed origin/frame-aware contract, bounded payloads, operation ownership, and tests. The top visible URL alone does not authenticate an iframe.

Check OS permission and web-origin permission separately. Grants must match the requesting profile, active trusted origin, requested capability, and user intent. Do not blanket-grant a request’s full resource array. Stop or safely interrupt capture on lock, switch, or loss of foreground.

Request camera or microphone only for supported user-initiated actions. Prefer system limited photo/file pickers. Do not request contacts, SMS, location, or baseline notifications. An existing global OS permission never authorizes every web origin.

For uploads:

- Bind selection to the original profile/view/operation.
- Complete success/cancellation once.
- Support exposed multiple selection where validated.
- Handle cloud-backed, large, zero-byte, unusual-name, revoked-access, interrupted, and low-space cases.
- Prefer scoped URIs/streams; avoid whole attachments in Dart memory or large base64 bridge messages.
- Keep staging private and profile-specific; clean on success, cancellation, removal, and crash recovery.
- Let the official website enforce its current messaging/file limits rather than inventing substitutes.

For downloads:

- Validate ordinary HTTP and blob/decrypted media separately.
- Use browser-native context where supported. A blob URL is not a normal network URL.
- Do not export a global cookie jar or session credentials to make downloads work.
- Provide progress, cancellation, sanitized filenames, safe destinations, disk-full handling, and cleanup.
- Export via explicit system save/share action.
- Explain that profile deletion cannot remove copies already exported to Photos, Files, or another app.
- Anchor iPad share/popover UI and test focus/resizing.

For voice notes/camera/calls, validate actual site behavior, capture origin, routing, Bluetooth, interruption, rotation, backgrounding, lock, and switching before enabling the promise. Do not add fake audio or improper foreground/background services to keep sessions alive.

## 13 Privacy backup diagnostics and app lock

Write and implement a threat model covering wrong-account display, cross-profile storage, stale file callbacks, malicious frames, local access, logs, interrupted cleanup, restored sessions, and dependency changes.

Before enabling app lock, check authentication availability and supported device-credential fallback. If setup is absent, explain the required device setup. If enabled authentication is canceled, unavailable, locked out, or affected by enrollment changes, keep content covered and provide supported recovery. Never silently disable an enabled lock.

Apply the native opaque cover before background snapshots and before revealing content on return. Distinguish OS picker interruptions from genuine app return so lock dialogs cannot trap users or misroute callbacks. Do not claim universal screenshot prevention.

Use Keychain/Keystore only for actual app-owned secrets. Do not claim they automatically encrypt the entire browser database with an app-owned key or create ten independent user identities. Do not claim the host app is cryptographically unable to observe rendered content.

Do not implement session backup/sync. Configure supported exclusions for sensitive app-owned records and temporary files. On Android cover legacy backup rules and current cloud/device-transfer rules; do not rely on `allowBackup=false` alone. Verify real provider storage/restore behavior without editing live database files.

Test registry-present/store-absent, store-present/registry-absent, restore, reinstall, transfer, and ordinary-upgrade cases. Quarantine unknown restored access; require relinking where trust cannot be established. Do not clear legitimate sessions on every upgrade.

Default to on-device diagnostics with user-controlled export. Allowlist app/build, OS/provider version, capability flags, error class, operation timing, and coarse capacity. Exclude aliases, phone numbers, contacts, message text, page titles, full URLs/query strings, QR/codes, file names/paths, DOM snapshots, and memory dumps.

Disable session replay, automatic screenshots, verbose native inspection, and sensitive crash attachments. Audit actual SDK payloads before adding remote reporting. Search logs and generated artifacts for synthetic sensitive markers.

Prepare truthful privacy disclosures from implemented data flows, including embedded website traffic. A local shell without a backend is not automatically a no-data-collected application. Record recipients, purposes, retention, permission behavior, and store-specific WebView disclosure decisions.

## 14 Test harness evidence and performance

Build a controlled developer-owned HTTPS same-origin harness available only to development/instrumentation builds. Use distinct synthetic profile markers against the same scheme, host, and port so separate domains cannot conceal accidental sharing.

Exercise cookies with server-verified HttpOnly behavior, localStorage, IndexedDB, Cache Storage, service-worker registration/update/deletion, HTTP cache, WebSockets, supported messaging channels/workers, and file callbacks. Keep test-server state correctly scoped so the harness itself does not leak markers.

Use valid test TLS or narrowly documented development-only setup; never weaken production transport security. Harness scripting or simultaneous-view isolation probes must remain test-only and must not change the production contract or live-view budget.

Prove two profiles, then ten. Test middle-profile removal and fresh replacement, normal relaunch, process termination, reboot, migration, renderer failure, storage eviction, and cleanup interruption at every stage.

Use:

- Unit tests for capacity, normalization, journal transitions, migrations, selection races, event ownership, and redaction.
- Widget tests with the fake engine for native shell states and actions.
- Real native instrumentation for profile binding/storage/deletion.
- Device integration tests for lifecycle, composition, files, permissions, and privacy.
- Manual procedures for official QR approval and dynamic service behavior when automation is inappropriate.

A fake engine does not prove native isolation. Ten empty stores do not prove ten linked WhatsApp sessions. A simulator is not a physical device. A configured CI workflow is not a build execution. Source review is not runtime validation.

After the applicable service-test gate, validate real pairing using authorized test accounts and specifically consenting recipients with fictional messages/media. Do not send messages merely because arbitrary contacts are visible. Keep QR values, credentials, real conversations, and account identifiers out of stored evidence.

For every run record test ID, requirement, commit/build, device, OS/provider, synthetic-versus-service context, procedure, expected result, actual result, date/time, evidence path, runner, and defect/blocker. Preserve redacted evidence and exact commands.

Run the full acceptance catalog below. Expand it only for discovered requirement-related risks. Do not delete, skip, or reclassify a failing required test to manufacture completion.

Run a seven-day feasibility retention check and a fourteen-day beta soak using actual elapsed time. Keep primary accounts active where needed and test intentional remote revocation separately. Record start/end timestamps. Until elapsed evidence exists, mark pending and continue other work. Do not simulate days, use long blocking sleeps, or schedule recurring automation without authorization.

Measure on declared baseline devices:

- Native selector response: provisional p95 below 150 ms.
- Usable local shell startup: provisional p95 below 2 seconds, excluding biometric response/network.
- Covered correct target context after selection: provisional p95 below 300 ms.
- Website usable: provisional p95 below 5 seconds on a defined normal network, recorded separately and rebaselined after feasibility.
- One live production WebView.
- 200 randomized switches across ten profiles without unrecoverable failure.
- Settled host plus web-content resource trends after all profiles have been visited.
- Zero observed account-mismatch frames in controlled captured test scenarios.
- Zero synthetic sensitive markers in allowed diagnostic paths.

These are proposed targets, not measured achievements. Record sample sizes, device/network conditions, cold/warm paths, memory pressure, thermal behavior, and comparison with a single-profile baseline. Do not invent universal memory or battery limits. Propose justified target changes explicitly; never weaken a privacy/isolation invariant.

## 15 Complete acceptance catalog

Retain all 70 source-plan cases. Prefix original identifiers with `AT-` in the evidence ledger. Each row below names the scenario and required outcome; expand it into setup, steps, assertions, cleanup, ownership, and evidence.

### Account management and linking

- **AT-A01:** First launch with no profiles. Required outcome: clear empty state and Link account action.
- **AT-A02:** Create first profile. Required outcome: unique registry and native store; correct alias shown.
- **AT-A03:** Add profiles two through ten. Required outcome: ten independently addressable stores.
- **AT-A04:** Attempt profile eleven. Required outcome: no extra store allocated; useful capacity message.
- **AT-A05:** Rapid repeated Add taps. Required outcome: atomic limit and no duplicate reservations.
- **AT-A06:** Rename and reorder. Required outcome: identity and underlying session remain unchanged.
- **AT-A07:** Duplicate aliases and long text. Required outcome: duplicate normalized aliases rejected; long accessible labels work.
- **AT-A08:** Successful QR pairing. Required outcome: official page authenticates; owner verifies alias.
- **AT-A09:** Expired QR and reload. Required outcome: official fresh QR flow; no stored QR or blank trap.
- **AT-A10:** Cancel partial setup. Required outcome: reservation kept or cleaned according to explicit choice.
- **AT-A11:** Same-phone setup. Required outcome: working official code flow or clear additional-device explanation.
- **AT-A12:** Account already at linked-device limit. Required outcome: official failure preserved with relevant help.
- **AT-A13:** Wrong account intentionally paired. Required outcome: user can correct alias or remove/relink; no false verified identity claim.
- **AT-A14:** Remove all accounts. Required outcome: every store enters cleanup; empty state after successful completion.

### Isolation switching and persistence

- **AT-I01:** Cookie and HttpOnly harness markers. Required outcome: no cross-profile markers at the same origin.
- **AT-I02:** localStorage and IndexedDB. Required outcome: independent values and restoration.
- **AT-I03:** Cache Storage and service workers. Required outcome: independent registration, update, and cleanup.
- **AT-I04:** Shared channel or worker capability. Required outcome: no supported cross-profile message or data leakage.
- **AT-I05:** Profiles four through ten on iOS. Required outcome: no unhandled service-worker or profile-capacity failure.
- **AT-I06:** All ten accounts paired. Required outcome: each displays the expected authorized test account.
- **AT-I07:** 200 randomized profile switches. Required outcome: correct alias-to-store binding; stable resource trend.
- **AT-I08:** Switch again before prior load completes. Required outcome: only newest selection can reveal content.
- **AT-I09:** Late callback from disposed view. Required outcome: ignored or canceled without changing active account.
- **AT-I10:** Relaunch after OS process termination. Required outcome: existing valid stores reopen without unnecessary reset.
- **AT-I11:** Device reboot and OS update. Required outcome: correct restore or honest relink state.
- **AT-I12:** App upgrade and registry migration. Required outcome: existing profile identifiers and sessions retained.
- **AT-I13:** Provider update or unsupported downgrade. Required outcome: capabilities rechecked; no shared-profile fallback.
- **AT-I14:** Lost or evicted website storage. Required outcome: clear relink path; no false authentication state.
- **AT-I15:** Seven-day and fourteen-day retention. Required outcome: dated evidence, independent of intentional revocation tests.
- **AT-I16:** Remove profile five and add another. Required outcome: profiles one to four and six to ten unaffected; new identity allocated.

### Deletion and recovery

- **AT-D01:** Delete selected profile. Required outcome: content immediately covered and access blocked.
- **AT-D02:** Delete inactive profile. Required outcome: other sessions remain usable.
- **AT-D03:** Delete while offline. Required outcome: local effect accurate; no remote revocation claim.
- **AT-D04:** Android loaded-profile delete restriction. Required outcome: immediate scoped wipe and journaled deferred deletion.
- **AT-D05:** Wipe fails or disk error occurs. Required outcome: retry state preserved; no success claim.
- **AT-D06:** Process stops at each cleanup stage. Required outcome: startup resumes idempotently; no resurrected account.
- **AT-D07:** Service worker writes during removal. Required outcome: profile quiesced; remaining access or data detected and addressed.
- **AT-D08:** Remote unlink from primary phone. Required outcome: affected account requests relinking without changing others.
- **AT-D09:** Renderer crashes. Required outcome: correct profile rebuild and visible recovery.
- **AT-D10:** Reload while a send status is uncertain. Required outcome: no automatic resend; user checks official message status.
- **AT-D11:** Repeated create/remove cycles. Required outcome: no uncontrolled orphaned stores or lost capacity.
- **AT-D12:** Backup restore and reinstall. Required outcome: defined session/registry behavior; unknown restored access quarantined.
- **AT-D13:** Remove inactive B, then switch from A to C before completion. Required outcome: B cleanup journal completes; active views unaffected.
- **AT-D14:** Required provider API disappears, then returns. Required outcome: requested wipe remains pending and resumes only for the intended profile.

### Files permissions and usability

- **AT-M01:** Photo and document attachment. Required outcome: selected content reaches correct originating account.
- **AT-M02:** Picker cancel or app interruption. Required outcome: original callback receives cancellation safely.
- **AT-M03:** Account switch while picker is open. Required outcome: switch guarded; no file reaches another profile.
- **AT-M04:** Cloud-backed, zero-byte, or large file. Required outcome: correct progress or actionable failure; bounded memory.
- **AT-M05:** Permission denied, then revoked. Required outcome: no crash or silent capture; clear retry route.
- **AT-M06:** Origin requests camera or microphone. Required outcome: exact origin and user intent checked before grant.
- **AT-M07:** Microphone interruption and Bluetooth. Required outcome: correct recording or disclosed unsupported state.
- **AT-M08:** HTTP and blob download. Required outcome: supported paths save; unsupported paths fail clearly.
- **AT-M09:** Unsafe filename or disk full. Required outcome: sanitized destination and cleanup.
- **AT-M10:** Save/share, then remove account. Required outcome: local temporary data removed; exported-copy effect explained.
- **AT-M11:** Small-screen portrait and landscape. Required outcome: QR and composer usable; native selector remains reachable.
- **AT-M12:** Keyboard, emoji, and long messages. Required outcome: composer visible; focus and scrolling behave correctly.
- **AT-M13:** Tablet resizing and external keyboard. Required outcome: layout, focus, and share UI remain valid.
- **AT-M14:** VoiceOver and TalkBack. Required outcome: account selection, state, and essential web actions understandable.

### Privacy security and release

- **AT-S01:** Lock, background, and app switcher. Required outcome: opaque cover hides account content.
- **AT-S02:** Authentication unavailable, locked out, canceled, or enrollment changed. Required outcome: content stays covered; supported fallback or setup/recovery route.
- **AT-S03:** Switch races under lock. Required outcome: no content flash from any account.
- **AT-S04:** External links and malicious host suffix. Required outcome: correct browser route or block after proper URL parsing.
- **AT-S05:** Untrusted frame or bridge request. Required outcome: no native privilege or account control exposed.
- **AT-S06:** Invalid TLS and mixed content. Required outcome: no bypass or insecure load.
- **AT-S07:** Synthetic sensitive markers in logs. Required outcome: no token, message, alias, phone, or file-path leakage.
- **AT-S08:** Production inspection and debug harness. Required outcome: inspection disabled; debug entry points absent.
- **AT-S09:** Capability unavailable. Required outcome: informative failure before pairing; cleanup remains accessible.
- **AT-S10:** Network drop and resume. Required outcome: account context preserved and bounded retry.
- **AT-S11:** Submission and reviewer access. Required outcome: actual core behavior reproducible with truthful review instructions.
- **AT-S12:** Release upgrade and rollback preparation. Required outcome: signed artifacts, migration evidence, and recovery plan ready.

Run relevant cases on both platforms where applicable. In particular, retain AT-D13 and AT-D14; cleanup completion after account switching and capability loss/recovery are required behaviors.

The matrix must include older/smaller supported iPhone hardware, minimum and current supported iOS, iPad resizing, Android API 29 and newer supported versions, relevant OEMs/WebView providers, unsupported-capability cases, lower-memory hardware, Wi-Fi/mobile/offline/captive-portal behavior, storage pressure, and accessibility.

## 16 Execute all six delivery phases

Use phases 0 through 5. Work may overlap where dependencies permit; do not use phase boundaries as automatic stopping points.

### Phase 0 Feasibility

- Inventory the environment and verify primary sources.
- Establish service/test/distribution evidence status.
- Build minimal real native containers and the synthetic harness.
- Prove two then ten isolated stores, binding, removal, restart recovery, and phone layout where executable.
- Measure initial resources and begin actual retention where authorized/available.
- Produce a dated feasibility decision distinguishing pass, failure, and missing evidence.
- Repair proven architecture failures before dependent feature expansion.

### Phase 1 Foundations

- Finalize UX, domain invariants, typed commands/events, native lifecycle boundaries, and registry/journal ownership.
- Implement real plugin registration, dependency wiring, migrations, flavors, fake engine, and diagnostic policy.
- Build all screen states and account management foundations.
- Establish formatting, static checks, unit/native test entry points, and CI.
- Confirm no production path depends on a mock or test origin.

### Phase 2 Account lifecycle

- Finish allocation/capacity, unique aliases, ordering, real profile binding, and official pairing guidance.
- Implement safe switching, cover timing, authentication observations, restoration, and bounded recovery.
- Finish relink, remove-one/remove-all, tombstones, compensation, deferred Android cleanup, and startup reconciliation.
- Verify profile isolation, lifecycle, and deletion cases.
- Claim ten-account service support only after actual corresponding evidence exists.

### Phase 3 Media privacy and usability

- Implement validated photo/document upload/download/save/share paths.
- Finish scoped permission/callback handling, app lock, background covers, navigation, and popup behavior.
- Complete keyboard, tablet, larger-text, screen-reader, and error-state usability.
- Add help, compatibility information, and safe diagnostic export.
- Enable conditional media features only after their capability tests.
- Draft privacy disclosures from actual implementation.

### Phase 4 Hardening and beta

- Execute applicable acceptance cases across available devices/providers.
- Fix race, cleanup, crash, storage, security, resource, and media defects.
- Run repeated switches, restore/reinstall/migration, log redaction, and production-build checks.
- Collect elapsed beta evidence rather than forecasting it.
- Resolve every critical/high privacy, wrong-account, isolation, and data-loss defect.
- Freeze a candidate with known limitations and actual coverage.

### Phase 5 Release preparation and handover

- Recheck current SDK/target API, developer-account, branding, privacy, and review requirements.
- Produce reproducible builds, release configuration, symbols/mappings, versioned artifacts, and dependency inventory.
- Prepare support/privacy copy, listings, screenshots using fictional or authorized data, and review instructions.
- Explain the real companion/primary-app requirement and provide a workable review path.
- Do not disguise synthetic demo mode as actual integration or depend on an unusable expiring QR.
- Prepare staged rollout, recovery/migration, incident, upstream compatibility, and maintenance procedures.
- Submit or distribute only when the required evidence and existing authorization support that action.

An unavailable device or external permission keeps the corresponding gate pending while independent source, harness, build configuration, tests, and preparation continue. A documented definitive incompatibility must remain a product decision, not an excuse to bypass restrictions or quietly substitute another product.

## 17 Build CI and release configuration

Pin tested toolchains and dependencies; include lockfiles and an update procedure. Use the repository’s CI provider where one exists. Keep signing credentials in approved secret storage. Do not print or commit certificates, private keys, provisioning secrets, API keys, or account exports.

Provide scripts for bootstrap, formatting checks, analysis, unit/widget tests, bridge generation checks, relevant native tests, harness startup, and supported Android/iOS builds.

Execute commands appropriate to the actual repository, including `flutter pub get`, formatting verification, `flutter analyze`, `flutter test`, native Gradle/Xcode checks, and Flutter platform builds where available. Capture the real output and exit status. Generate exact alternative-machine commands when a platform toolchain is unavailable.

A Linux host can still implement and review Swift source and prepare macOS CI, but cannot claim an Xcode build ran. An unsigned iOS build, signed archive, simulator build, Android debug APK, and store-ready artifact must be labeled accurately.

CI should validate changed code and the meaningful affected suites. Use native runners for native evidence. Required tests must not be disabled to pass CI. Fix compilation warnings/errors that indicate lifecycle, availability, or type-contract defects; do not suppress them without a justified decision.

Production builds must exclude:

- Test harness origins and debug menus.
- Fake session engine injection.
- Generic test JavaScript/data-export surfaces.
- Web inspection/debugging.
- Transport-security bypasses.
- Sensitive logging, session replay, and automatic screenshots.
- Hardcoded test-account material.

Retain symbols/mappings, build/commit provenance, dependency/license inventory, and safe logs. Run release-candidate smoke tests against the actual built variant.

## 18 Quality loop completion report and maintenance

For each completed feature, verify both its own behavior and adjacent account/lifecycle/permission boundaries. Use regression tests when they protect a real invariant. Avoid tests that merely duplicate implementation or assert that a mock returns its configured answer.

Conduct an independent review of native storage binding, startup order, race handling, allocation compensation, deletion, backup, and release configuration. Fix actionable findings, run the necessary affected checks, and update traceability.

Use bounded retries and root-cause investigation. Do not repeatedly run the same failing command without new evidence. Do not add unrelated features or endless testing after the required risks are resolved.

Prepare complete handover material:

- Reproducible local setup and build/run commands.
- Requirements and implementation/test traceability.
- Architecture and profile/allocation/deletion decisions.
- Threat model and permission/backup/privacy analysis.
- Real device/provider compatibility and supported-feature matrix.
- All 70 acceptance dispositions with evidence.
- Relinking, local removal, remote unlink, and safe recovery guidance.
- Release/signing ownership and review package.
- Maintenance smoke suite for upstream website/OS/provider changes.
- Incident procedure for wrong-account display, leakage, or data loss.
- Store-controlled rollout/rollback limitations and migration compatibility.
- Current checkpoint and exact remaining dependencies.

Never clear every account as the first response to a website outage. Preserve sessions where possible and distinguish external service changes from local corruption.

End with one self-contained report that separates:

1. Source implementation completed.
2. Builds actually executed and their result.
3. Automated tests actually executed.
4. Physical-device and actual-service validation.
5. Elapsed retention evidence.
6. Defects and supported limitations.
7. Service/distribution and release readiness.
8. Prepared artifacts and exact commands.
9. The smallest consolidated set of missing user actions, if any.

Do not claim 100 percent completion, zero bugs, universal device support, verified ten-account use, or store readiness without the corresponding evidence. Pending evidence is not implementation failure, and implementation completion is not proof of release readiness.

Stop only when all currently executable required work is finished and every remaining item has an explicit dependency, owner/action, procedure, and honest status. Do not finish with “Would you like me to continue?” when authorized work remains.

## 19 Primary research starting points

These references came from the source plan’s October 2026 research. Verify the current relevant content before relying on API or policy details. Prefix source IDs with SRC- so they cannot be confused with acceptance-test IDs.

- [SRC-S01 — WhatsApp Help Center: About linked devices](https://faq.whatsapp.com/378279804439436/?cms_platform=android&locale=da_DK)
- [SRC-S02 — WhatsApp Help Center: How to fix connection issues](https://faq.whatsapp.com/852892549070029/?cms_platform=web&helpref=hc_fnav)
- [SRC-S03 — Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [SRC-S04 — Google Play Spam policy and Webviews](https://support.google.com/googleplay/android-developer/answer/9899034?hl=en)
- [SRC-S05 — WhatsApp Business Help Center: QR linking](https://faq.whatsapp.com/878854700132604/?cms_platform=android)
- [SRC-S06 — Meta announcement of account switching on iOS, March 26, 2026](https://about.fb.com/news/2026/03/whatsapp-new-features-simplify-storage-switch-accounts/)
- [SRC-S07 — WhatsApp Help Center: Linking with phone number](https://faq.whatsapp.com/1324084875126592/?cms_platform=web&locale=vi_VN)
- [SRC-S08 — Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels)
- SRC-S09 — Flutter native platform views: [iOS](https://docs.flutter.dev/platform-integration/ios/platform-views) and [Android](https://docs.flutter.dev/platform-integration/android/platform-views)
- [SRC-S10 — WebKit: Building Profiles with new WebKit API](https://webkit.org/blog/14423/building-profiles-with-new-webkit-api/)
- [SRC-S11 — Apple WKWebsiteDataStore](https://developer.apple.com/documentation/webkit/wkwebsitedatastore)
- [SRC-S12 — Apple WKProcessPool](https://developer.apple.com/documentation/webkit/wkprocesspool)
- [SRC-S13 — WebKit Updates to Storage Policy](https://webkit.org/blog/14403/updates-to-storage-policy/)
- [SRC-S14 — WebKit App Bound Domains](https://webkit.org/blog/10882/app-bound-domains/)
- [SRC-S15 — Apple Explore WKWebView additions](https://developer.apple.com/videos/play/wwdc2021/10032/)
- [SRC-S16 — Android WebViewCompat profile assignment](https://developer.android.com/reference/androidx/webkit/WebViewCompat)
- [SRC-S17 — Android WebStorageCompat browsing-data deletion](https://developer.android.com/reference/androidx/webkit/WebStorageCompat)
- [SRC-S18 — AndroidX WebKit release notes](https://developer.android.com/jetpack/androidx/releases/webkit)
- [SRC-S19 — Android Profile API](https://developer.android.com/reference/androidx/webkit/Profile)
- [SRC-S20 — Android ProfileStore API](https://developer.android.com/reference/androidx/webkit/ProfileStore)
- [SRC-S21 — Android security guidance for WebView native bridges](https://developer.android.com/privacy-and-security/risks/insecure-webview-native-bridges)
- [SRC-S22 — Android Access native APIs with JavaScript bridge](https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge)
- [SRC-S23 — Apple Optimizing Your App’s Data for iCloud Backup](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)
- [SRC-S24 — Apple Preparing your UI to run in the background](https://developer.apple.com/documentation/uikit/preparing-your-ui-to-run-in-the-background)
- [SRC-S25 — WebKit Web Push for Web Apps on iOS and iPadOS](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/)
- [SRC-S26 — Android Google Play target API requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [SRC-S27 — Apple SDK minimum submission requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)
- [SRC-S28 — Apple Developer Program membership](https://developer.apple.com/programs/whats-included/)
- [SRC-S29 — Google Play Console registration](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en-IN)
- [SRC-S30 — Meta official WhatsApp Cloud API documentation on Postman](https://www.postman.com/meta/whatsapp-business-platform/documentation/wlk6lh4/whatsapp-cloud-api?entity=request-13382743-eb9a6721-1056-4db2-b00a-2290e04b5b5d)
- [SRC-S31 — WhatsApp Business: Organize your inbox and scale your business](https://whatsappbusiness.com/resources/resource-library/organize-whatsapp-inbox-meta-business-suite/)
- [SRC-S32 — Meta WhatsApp brand guidelines](https://www.meta.com/brand/resources/whatsapp/whatsapp-brand/)
- [SRC-S33 — Android Auto Backup and device transfer rules](https://developer.android.com/identity/data/autobackup)
- [SRC-S34 — Chromium Android WebView startup implementation](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/android_webview/lib/aw_main_delegate.cc)
- [SRC-S35 — Apple App privacy details for web traffic](https://developer.apple.com/app-store/app-privacy-details/)
- [SRC-S36 — Google Play Data Safety form and WebView rules](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)

## 20 Start execution now

Inspect the current workspace and source plan first. Create the requirement ledger and dependency-ordered checklist, identify actual tools and blockers, and immediately begin the minimal real native profile engines and same-origin harness.

Delegate independent work when available. Continue through every executable phase, update evidence as you go, and deliver working source plus a truthful verification and release-readiness report.