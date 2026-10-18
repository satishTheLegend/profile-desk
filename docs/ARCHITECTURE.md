# Profile Desk architecture

Date: 18 October 2026. Baseline: supplied Word plan and complete implementation instructions. The user explicitly requested full local implementation after reading both; release authorization remains separate.

## Product boundary

One operator manages at most ten independently linked official website profiles. Flutter renders the persistent native shell above one native WebView. No backend, message automation, extraction, account credentials, inactive notifications, or session synchronization. iOS 17 minimum; Android API 29 minimum with mandatory provider feature checks. Official QR linking requires an appropriate primary device. Account aliases are user labels, never verified identity.

## ADR 001 Native lifecycle authority

Native SQLite is the sole durable registry and allocation/deletion journal authority. The shared AccountService validates user input and invokes generated typed commands; it does not persist a competing lifecycle. This permits clean-start Android container deletion before any profile getter loads a tombstoned store, and lets cleanup callbacks finish without a Dart screen. Both platforms expose the same registry operations and schema semantics. Native database transactions reserve capacity before allocation. An unfinished allocation is reconciled, never silently authenticated. Failures retain blocked states.

Profile metadata: immutable random ID, immutable native store ID, normalized unique alias, color, ordering, creation/open time, lifecycle, user observation. Cleanup: operation ID, durable stage, attempts, redacted error, update time. No messages, cookies, QR values, phone numbers or attachment paths in diagnostics. Released capacity must never permit deleted IDs to be reused.

## ADR 002 View and event ownership

One platform-view host is registered as `profile_desk/session`. openProfile creates and binds a native browser view within it. The binding is immutable. The coordinator covers outgoing content before changing the alias, disposes the prior view and checks the newest generation after each await. Native reveal verifies the exact ViewHandle and unlocked state. View events carry profile, view, operation and generation. Cleanup events use profile and cleanup-operation ownership independently of selection. Navigation completion means render readiness, never authentication.

## ADR 003 Interface and dependencies

Pigeon generates Dart, Swift and Kotlin bindings from packages/session_contract/pigeons/session_api.dart. Flutter 3.47.5 and Dart 3.13.4 are the installed baseline. Riverpod is the sole app state system. Native SQLite APIs avoid a second database plugin that could initialize profiles too early. Public native profile APIs are verified against current official documentation. Generated bindings are checked for drift.

## Design direction

Working name Profile Desk, original neutral branding. Warm light surface, deep teal actions, readable system typography, clear selected label, accessible 48-point targets and modest motion. Native sheet on phones and anchored selector on wide screens. Full-text state alongside color. No stock chat screenshots or invented accounts. Dark mode follows device preference or explicit setting. Website is unmodified. Tabler outline icons are selected locally as SVG assets.

## Evidence and authority

Synthetic storage tests do not establish actual WhatsApp compatibility. Code, executed builds, automated tests, devices, elapsed retention and distribution permission remain separate. No physical device, approved real test accounts or reviewed provider permission has been supplied. Those gates remain pending while local source/build/harness work proceeds. No live sends or store submission are authorized by implementation alone.
