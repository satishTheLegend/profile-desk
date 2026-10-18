# Complete prompt verification checklist

Generated from the reviewed requirement and acceptance ledgers. This file retains every clause and all 70 cases. A PASS applies only to its stated validation scope. Source inspection, unit tests and synthetic fixtures do not close physical, service, elapsed-time or release gates.

Start with [the audit report](DESIGN_VERIFICATION_CHECKLIST.md) and [the original Word plan crosswalk](DESIGN_DOCUMENT_TRACEABILITY.md). The introduction and section 20 state the execution objective; sections 1–14 and 16–18 supply all 374 ledger clauses. Section 15 is the 70-case catalog below. Section 19 is preserved in [the source catalog](SOURCE_CATALOG.md).

Refresh after reviewing CSV changes: `python3 scripts/check_traceability.py --write`. A normal run checks both source completeness and this generated view, without modifying files.

## Requirement dispositions

| Implementation status | Clauses |
| --- | ---: |
| COMPLETED_LOCAL | 32 |
| DOCUMENTED | 72 |
| EXCLUDED | 6 |
| EXTERNAL_DEPENDENCY | 20 |
| IMPLEMENTED | 199 |
| PARTIAL | 45 |

These overlapping product clauses include process instructions and rationale. Their counts are not a product completion percentage.

## 1. Working authority scope and continuity

### REQ-01-001

1. Read the current repository instructions and inspect the working tree before editing. Preserve unrelated changes, existing secrets, signing settings, and useful implementations. Do not reset the repository, overwrite user work, delete branches, force-push, or rewrite project instructions to remove restrictions.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: local workflow and document audit

Source: docs/ARCHITECTURE.md; docs/RESUME.md

Evidence: docs/ARCHITECTURE.md records authorization, ownership and external gates. Original supplied DOCX and pasted instructions retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: workflow/docs.

Remaining action: Maintain these process constraints through final handover. Owner: integration lead. Dependencies: Supplied instructions and original Word plan.

### REQ-01-002

2. If `WhatsApp_Web_Android_iOS_Application_Plan.docx` is supplied, read its entire body, tables, acceptance catalog, phase checklists, risk register, and source references. A filename or preview is insufficient. Use available DOCX extraction tools; preserve table rows and hyperlinks. This prompt is self-contained enough to start when the document is unavailable. Record that limitation and continue instead of asking for the attachment again.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: local workflow and document audit

Source: docs/ARCHITECTURE.md; docs/RESUME.md

Evidence: docs/ARCHITECTURE.md records authorization, ownership and external gates. Original supplied DOCX and pasted instructions retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: workflow/docs.

Remaining action: Maintain these process constraints through final handover. Owner: integration lead. Dependencies: Supplied instructions and original Word plan.

### REQ-01-003

3. Treat explicit user instructions as controlling. Use the source plan as the product baseline and current verified platform documentation as the implementation authority for API behavior. Record conflicts and resolve routine engineering choices. Do not invent permission, compatibility, SDK capabilities, credentials, or successful tests.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: local workflow and document audit

Source: docs/ARCHITECTURE.md; docs/RESUME.md

Evidence: docs/ARCHITECTURE.md records authorization, ownership and external gates. Original supplied DOCX and pasted instructions retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: workflow/docs.

Remaining action: Maintain these process constraints through final handover. Owner: integration lead. Dependencies: Supplied instructions and original Word plan.

### REQ-01-004

4. This request authorizes all independent, reversible local implementation, configuration, documentation, debugging, and testing needed for the defined product. It does not imply permission to purchase services, acquire accounts, message arbitrary recipients, disclose secrets, distribute builds publicly, or submit to app stores. Reuse explicit authorization already present in the session; do not ask for it again.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: local workflow and document audit

Source: docs/ARCHITECTURE.md; docs/RESUME.md

Evidence: docs/ARCHITECTURE.md records authorization, ownership and external gates. Original supplied DOCX and pasted instructions retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: workflow/docs.

Remaining action: Maintain these process constraints through final handover. Owner: integration lead. Dependencies: Supplied instructions and original Word plan.

### REQ-01-005

5. When an external action needs authorization that has not been provided, finish its concrete build, configuration, evidence, and review package first. Ask only for the remaining action. Never use missing release permission as a reason to abandon independent code or tests.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: Local candidate, evidence reconciliation and explicit dependency handover; no release or full acceptance claim

Source: docs/REPORT.md; docs/RESUME.md; docs/acceptance.csv; docs/requirements.csv; artifacts/profile-desk-0.1.0-local/manifest.json

Evidence: Final unsigned Android/iOS builds, strengthened artifact checks, matching symbols and exact artifact/source hashes are preserved. All374 clauses and70 acceptance scenarios retain source text with current dispositions. Report records failures, open source gap and remaining owners/actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: workflow/docs.

Remaining action: Native engineering resolves Android download gap; account/device QA supplies approved service/physical/elapsed evidence; release owner resolves distribution/signing inputs. Follow the consolidated handover; do not infer full acceptance from local completion. Owner: integration lead; remaining actions assigned in docs/REPORT.md. Dependencies: Supplied instructions and original Word plan.

### REQ-01-006

6. If a toolchain, device, account, service permission, or elapsed test period is missing, record the exact blocker once and continue independent work. Do not wait indefinitely, fabricate a result, or keep repeating the same question.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: local workflow and document audit

Source: docs/ARCHITECTURE.md; docs/RESUME.md

Evidence: docs/ARCHITECTURE.md records authorization, ownership and external gates. Original supplied DOCX and pasted instructions retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: workflow/docs.

Remaining action: Maintain these process constraints through final handover. Owner: integration lead. Dependencies: Supplied instructions and original Word plan.

### REQ-01-007

7. Do not expand the product after every feature. Add work only to satisfy an existing requirement, correct a defect, or address an evidenced compatibility or privacy risk. Record unrelated ideas separately without implementing them.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: local workflow and document audit

Source: docs/ARCHITECTURE.md; docs/RESUME.md

Evidence: docs/ARCHITECTURE.md records authorization, ownership and external gates. Original supplied DOCX and pasted instructions retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: workflow/docs.

Remaining action: Maintain these process constraints through final handover. Owner: integration lead. Dependencies: Supplied instructions and original Word plan.

### REQ-01-008

8. If the session is interrupted or context becomes limited, checkpoint actual repository state, completed work, pending tasks, commands, results, and blockers in `docs/RESUME.md`. On continuation, read that checkpoint, inspect the current diff, and resume without restarting or duplicating completed work. Never put secrets or session data in the checkpoint.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: Local candidate, evidence reconciliation and explicit dependency handover; no release or full acceptance claim

Source: docs/REPORT.md; docs/RESUME.md; docs/acceptance.csv; docs/requirements.csv; artifacts/profile-desk-0.1.0-local/manifest.json

Evidence: Final unsigned Android/iOS builds, strengthened artifact checks, matching symbols and exact artifact/source hashes are preserved. All374 clauses and70 acceptance scenarios retain source text with current dispositions. Report records failures, open source gap and remaining owners/actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: workflow/docs.

Remaining action: Native engineering resolves Android download gap; account/device QA supplies approved service/physical/elapsed evidence; release owner resolves distribution/signing inputs. Follow the consolidated handover; do not infer full acceptance from local completion. Owner: integration lead; remaining actions assigned in docs/REPORT.md. Dependencies: Supplied instructions and original Word plan.

### REQ-01-009

9. Give concise progress updates explaining completed outcomes, findings, and the next dependency being resolved. End only when executable scoped work is complete or every remaining task has a concrete unresolved dependency.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: Local candidate, evidence reconciliation and explicit dependency handover; no release or full acceptance claim

Source: docs/REPORT.md; docs/RESUME.md; docs/acceptance.csv; docs/requirements.csv; artifacts/profile-desk-0.1.0-local/manifest.json

Evidence: Final unsigned Android/iOS builds, strengthened artifact checks, matching symbols and exact artifact/source hashes are preserved. All374 clauses and70 acceptance scenarios retain source text with current dispositions. Report records failures, open source gap and remaining owners/actions.

Acceptance: N/A — process/documentation clause. Classification: conditional. Module: workflow/docs.

Remaining action: Native engineering resolves Android download gap; account/device QA supplies approved service/physical/elapsed evidence; release owner resolves distribution/signing inputs. Follow the consolidated handover; do not infer full acceptance from local completion. Owner: integration lead; remaining actions assigned in docs/REPORT.md. Dependencies: Supplied instructions and original Word plan.

## 2. Fixed product requirements and exclusions

### REQ-02-001

Implement these baseline decisions:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: docs/ARCHITECTURE.md; apps/mobile/lib/features/

Evidence: packages/session_contract/test/ (23 tests); packages/local_registry/test/ (16 tests); apps/mobile/test/shell_test.dart (7 tests); native synthetic evidence in docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Acceptance: N/A — parent product baseline; see REQ-02-002 through REQ-02-019. Classification: rationale. Module: product/app/native engines.

Remaining action: Complete applicable device/service acceptance; do not infer live service support from source or fixtures. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-002

- One operator and up to ten linked account profiles per installation, including incomplete linking setups. This is not a ten-employee identity or role system.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md native capacity tests; packages/local_registry/test/ capacity tests; apps/mobile/test/shell_test.dart eleventh-slot UI test

Acceptance: AT-A03; AT-A04; AT-A05. Classification: required. Module: product/app/native engines.

Remaining action: Run the linked complete acceptance case on declared physical devices; preserve the narrower automated evidence. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence; physical-device verification remains separate.

### REQ-02-003

- A native selector that remains reachable above the web content during loading, failures, and recovery.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression

Source: apps/mobile/lib/features/workspace/workspace_screen.dart

Evidence: apps/mobile/test/shell_test.dart covers reachable shell; native selector remains outside web content

Acceptance: AT-A01; AT-M11; AT-S09. Classification: required. Module: product/app/native engines.

Remaining action: Verify reachability during real-page loading/error and keyboard states on physical devices. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence; physical-device verification remains separate.

### REQ-02-004

- A stable random identifier for every profile, independent of alias, list position, phone number, and selected row.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md rename/reorder/cleanup tests preserve IDs; replacement tests require fresh IDs.

Acceptance: AT-A06; AT-I16. Classification: required. Module: product/app/native engines.

Remaining action: Run the linked complete acceptance case on declared physical devices; preserve the narrower automated evidence. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence; physical-device verification remains separate.

### REQ-02-005

- Official HTTPS WhatsApp Web content in a profile-specific persistent browser store.

**Implementation:** PARTIAL · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; apps/mobile/lib/features/help/help_screen.dart

Evidence: Native target is official HTTPS workspace; guidance implemented. No actual authorized service pairing evidence.

Acceptance: AT-A08; AT-A09; AT-A11; AT-I06. Classification: required. Module: product/app/native engines.

Remaining action: Authorized account owners execute official QR pairing; keep optional phone-number linking unpromised. Owner: engineering + device QA. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-006

- Official QR linking approved in the primary WhatsApp app. Official phone-number linking is conditional on availability and verification.

**Implementation:** PARTIAL · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; apps/mobile/lib/features/help/help_screen.dart

Evidence: Native target is official HTTPS workspace; guidance implemented. No actual authorized service pairing evidence.

Acceptance: AT-A08; AT-A09; AT-A11; AT-I06. Classification: conditional. Module: product/app/native engines.

Remaining action: Authorized account owners execute official QR pairing; keep optional phone-number linking unpromised. Owner: engineering + device QA. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-007

- One live WebView across the application initially. Do not preload ten websites or keep hidden inactive WebViews.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ one-owner tests and200 seeded fake-engine switches; iOS hosted storage test uses one live view.

Acceptance: AT-I07; AT-I08; AT-I09. Classification: required. Module: product/app/native engines.

Remaining action: Run the linked complete acceptance case on declared physical devices; preserve the narrower automated evidence. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence; physical-device verification remains separate.

### REQ-02-008

- Flutter shared UI, a typed platform contract, Swift iOS engine, Kotlin Android engine, and a transactional local registry.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; apps/mobile/lib/app/providers.dart

Evidence: docs/ARCHITECTURE.md ADR001-003; generated/native development builds and focused tests.

Acceptance: AT-A02; AT-D13. Classification: required. Module: product/app/native engines.

Remaining action: Run the linked complete acceptance case on declared physical devices; preserve the narrower automated evidence. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence; physical-device verification remains separate.

### REQ-02-009

- iOS 17 or later as the planned deployment baseline. Android 10/API 29 or later as the proposed product minimum, with mandatory runtime WebView capability checks.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression

Source: apps/mobile/android/app/build.gradle.kts; apps/mobile/ios/Runner.xcodeproj/project.pbxproj; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md actual runtime checks: API35 unsupported, API36 supported; native Swift targets iOS17.

Acceptance: AT-S09; AT-I13. Classification: required. Module: product/app/native engines.

Remaining action: Test actual minimum-OS physical hardware; deployment target is not compatibility proof. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence; physical-device verification remains separate.

### REQ-02-010

- Phone-first UI with tablet, landscape, keyboard, resizing, accessibility, and larger-text validation.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: apps/mobile/lib/app/design.dart; apps/mobile/lib/features/workspace/workspace_screen.dart

Evidence: apps/mobile/test/shell_test.dart phone320px/large text/tablet dark layout tests pass; actual web composition and assistive technology incomplete.

Acceptance: AT-M11; AT-M12; AT-M13; AT-M14. Classification: required. Module: product/app/native engines.

Remaining action: Run VoiceOver/TalkBack, keyboard, rotation and tablet resizing on supported physical devices. Owner: engineering + device QA. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-011

- Optional OS-backed app lock, background preview protection, safe navigation, scoped permissions, and local cleanup.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression

Source: apps/mobile/lib/features/privacy/; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ auth/lock race tests; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md cover/native auth source and helper tests.

Acceptance: AT-S01; AT-S02; AT-S03. Classification: required. Module: product/app/native engines.

Remaining action: Run the linked complete acceptance case on declared physical devices; preserve the narrower automated evidence. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence; physical-device verification remains separate.

### REQ-02-012

- No separate application registration, custom password login, OTP system, or app-owned messaging server.

**Implementation:** EXCLUDED · **Validation:** NOT_APPLICABLE_WITH_REASON

Scope: intentional product exclusion; source boundary inspected

Source: docs/ARCHITECTURE.md; packages/session_contract/pigeons/session_api.dart

Evidence: No app registration, backend, monetization/tracking, protocol client, automation, scraping or inactive notifications are implemented. No notification permission is requested.

Acceptance: N/A — excluded authentication/backend feature. Classification: excluded. Module: product/app/native engines.

Remaining action: Keep excluded; a future scope change requires separate requirements and validation. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-013

- English shell with localization-ready strings. Preserve an existing localization convention; additional languages must not alter the external website.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression

Source: apps/mobile/lib/l10n/app_en.arb; apps/mobile/lib/l10n/app_localizations.dart; apps/mobile/l10n.yaml

Evidence: English ARB generation and Flutter localization delegates implemented; app analysis/tests pass.

Acceptance: AT-M14. Classification: required. Module: product/app/native engines.

Remaining action: Add locales through ARB generation if required; never modify the external website for shell translation. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-014

- A free development/beta baseline. Do not add payments, advertisements, subscriptions, tracking, or remote configuration without a separate requirement.

**Implementation:** EXCLUDED · **Validation:** NOT_APPLICABLE_WITH_REASON

Scope: intentional product exclusion; source boundary inspected

Source: docs/ARCHITECTURE.md; packages/session_contract/pigeons/session_api.dart

Evidence: No app registration, backend, monetization/tracking, protocol client, automation, scraping or inactive notifications are implemented. No notification permission is requested.

Acceptance: N/A — excluded monetization/tracking feature. Classification: excluded. Module: product/app/native engines.

Remaining action: Keep excluded; a future scope change requires separate requirements and validation. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-015

Required user features are add, name, rename, reorder, select, link, relink, reload safely, remove one profile, remove all local profiles, view compatibility details, configure privacy, and access useful recovery/help screens. Implement validated foreground text, photo, and document flows through the official website.

**Implementation:** PARTIAL · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: complete clause not yet verified; see evidence for executed subset

Source: apps/mobile/lib/features/; packages/local_registry/lib/src/account_service.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Account management/help/privacy source implemented and focused tests pass. Foreground actual-service text/photo/document flows are unverified; Android downloads unsupported.

Acceptance: AT-A01; AT-A06; AT-A08; AT-A14; AT-M01; AT-M08. Classification: required. Module: product/app/native engines.

Remaining action: Resolve OPEN_RELEASE_GAP Android native authenticated/blob downloads and execute authorized service flows. Owner: engineering + device QA. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-016

Treat voice notes, direct camera capture, calls, video calls, and foreground message indicators as separate capability gates. Provide them only when the actual embedded flow is supported and tested. If an essential photo/document flow fails, report it as a release gap rather than quietly changing the requirement.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: source review and narrower unit/widget evidence

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Camera/microphone/calls disabled and disclosed; Android essential download path remains OPEN_RELEASE_GAP.

Acceptance: AT-M01; AT-M06; AT-M07; AT-M08. Classification: conditional. Module: product/app/native engines.

Remaining action: Do not enable conditional capture until device/service tests pass; native engineer must resolve essential Android download path or obtain explicit product scope decision. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-017

Do not implement a unified inbox, server-hosted sessions, QR relays, session export/import, cloud session sync, contact/chat scraping, DOM extraction of conversations, automated sends, scheduled messages, bulk messaging, automatic replies, AI summaries, translation, or private WhatsApp protocol clients.

**Implementation:** EXCLUDED · **Validation:** NOT_APPLICABLE_WITH_REASON

Scope: intentional product exclusion; source boundary inspected

Source: docs/ARCHITECTURE.md; packages/session_contract/pigeons/session_api.dart

Evidence: No app registration, backend, monetization/tracking, protocol client, automation, scraping or inactive notifications are implemented. No notification permission is requested.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: excluded. Module: product/app/native engines.

Remaining action: Keep excluded; a future scope change requires separate requirements and validation. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-018

Do not promise continuous synchronization, current unread counts, or notifications for inactive profiles. Do not request notification permission without a real supported event source and an approved feature.

**Implementation:** EXCLUDED · **Validation:** NOT_APPLICABLE_WITH_REASON

Scope: intentional product exclusion; source boundary inspected

Source: docs/ARCHITECTURE.md; packages/session_contract/pigeons/session_api.dart

Evidence: No app registration, backend, monetization/tracking, protocol client, automation, scraping or inactive notifications are implemented. No notification permission is requested.

Acceptance: N/A — inactive notification/synchronization promise excluded. Classification: excluded. Module: product/app/native engines.

Remaining action: Keep excluded; a future scope change requires separate requirements and validation. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

### REQ-02-019

The Business Platform is a different product alternative. If the wrapper is not viable, prepare a specific alternative proposal; do not silently replace this application with a business inbox, backend, or multi-tenant system.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: product boundary review

Source: docs/ARCHITECTURE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Business Platform is not substituted. No definitive whole-product viability decision exists while service and media gates remain open.

Acceptance: N/A — alternative-product boundary. Classification: required. Module: product/app/native engines.

Remaining action: If feasibility becomes definitively negative, prepare a specific alternative proposal; do not silently change architecture. Owner: integration lead. Dependencies: Typed contract; native runtime capabilities; separately authorized service evidence.

## 3. Initial inspection and official source verification

### REQ-03-001

Start by inventorying:

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: docs/RESUME.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Empty-code repository inventoried; Flutter3.47.5/Dart3.13.4, Xcode27.1, JDK17/SDK and dedicated simulators/emulators recorded; no physical devices/test accounts/signing owner supplied.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: research/platform/release.

Remaining action: Update environment ledger for final candidate; never print secrets or inspect unrelated accounts. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-002

- Repository structure, git status, applicable instructions, current application architecture, and reusable code.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESUME.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Empty-code repository inventoried; Flutter3.47.5/Dart3.13.4, Xcode27.1, JDK17/SDK and dedicated simulators/emulators recorded; no physical devices/test accounts/signing owner supplied.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Update environment ledger for final candidate; never print secrets or inspect unrelated accounts. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-003

- Host OS; available Flutter/Dart, Swift/Xcode, Kotlin/Java/Gradle, Android SDK, and package tooling.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESUME.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Empty-code repository inventoried; Flutter3.47.5/Dart3.13.4, Xcode27.1, JDK17/SDK and dedicated simulators/emulators recorded; no physical devices/test accounts/signing owner supplied.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Update environment ledger for final candidate; never print secrets or inspect unrelated accounts. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-004

- Existing native plugins and their construction/lifecycle behavior.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESUME.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Empty-code repository inventoried; Flutter3.47.5/Dart3.13.4, Xcode27.1, JDK17/SDK and dedicated simulators/emulators recorded; no physical devices/test accounts/signing owner supplied.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Update environment ledger for final candidate; never print secrets or inspect unrelated accounts. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-005

- Available emulators, simulators, connected physical devices, OS releases, and Android WebView providers.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESUME.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Empty-code repository inventoried; Flutter3.47.5/Dart3.13.4, Xcode27.1, JDK17/SDK and dedicated simulators/emulators recorded; no physical devices/test accounts/signing owner supplied.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Update environment ledger for final candidate; never print secrets or inspect unrelated accounts. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-006

- Existing CI, signing access, application identifiers, flavors, and deployment processes without exposing secret values.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESUME.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Empty-code repository inventoried; Flutter3.47.5/Dart3.13.4, Xcode27.1, JDK17/SDK and dedicated simulators/emulators recorded; no physical devices/test accounts/signing owner supplied.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Update environment ledger for final candidate; never print secrets or inspect unrelated accounts. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-007

- Availability of specifically authorized test accounts, pairing devices, consenting test recipients, and permission evidence.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESUME.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Empty-code repository inventoried; Flutter3.47.5/Dart3.13.4, Xcode27.1, JDK17/SDK and dedicated simulators/emulators recorded; no physical devices/test accounts/signing owner supplied.

Acceptance: N/A — process/documentation clause. Classification: external-dependency. Module: research/platform/release.

Remaining action: Update environment ledger for final candidate; never print secrets or inspect unrelated accounts. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-008

Use `rg` and targeted reads for repository discovery. Run independent inspections in parallel when supported. Do not dump secrets, complete environment variables, browser databases, or private account data.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESUME.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Empty-code repository inventoried; Flutter3.47.5/Dart3.13.4, Xcode27.1, JDK17/SDK and dedicated simulators/emulators recorded; no physical devices/test accounts/signing owner supplied.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Update environment ledger for final candidate; never print secrets or inspect unrelated accounts. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-009

Reverify current primary documentation before choosing or calling platform APIs. Record URLs, access date, relevant finding, and resulting decision in the research/architecture record. At minimum verify:

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Primary URLs/access date and native API decisions recorded; installed declarations/compiler and provider instrumentation substantiate signatures/behavior; inaccessible pages explicitly limited.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Recheck time-sensitive platform/store guidance at candidate freeze; collect outstanding external evidence. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-010

- WhatsApp linking flows, supported clients, linked-device constraints, and applicable service guidance.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: WhatsApp help body was not extractable; approved service basis and actual embedded compatibility unavailable.

Acceptance: AT-A08; AT-I06. Classification: external-dependency. Module: research/platform/release.

Remaining action: Product owner supplies permitted test basis; QA verifies official linking/limits against current accessible sources. Owner: product owner + authorized account owners + device QA. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-011

- Apple persistent website data stores, deletion, navigation, downloads, app lifecycle, and minimum-functionality/service-access review rules.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Primary URLs/access date and native API decisions recorded; installed declarations/compiler and provider instrumentation substantiate signatures/behavior; inaccessible pages explicitly limited.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Recheck time-sensitive platform/store guidance at candidate freeze; collect outstanding external evidence. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-012

- AndroidX profile creation/assignment, profile loading/deletion restrictions, browsing-data deletion, feature flags, thread rules, and provider behavior.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Primary URLs/access date and native API decisions recorded; installed declarations/compiler and provider instrumentation substantiate signatures/behavior; inaccessible pages explicitly limited.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Recheck time-sensitive platform/store guidance at candidate freeze; collect outstanding external evidence. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-013

- Flutter platform views, platform channels/Pigeon, and compatible build-tool versions.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Primary URLs/access date and native API decisions recorded; installed declarations/compiler and provider instrumentation substantiate signatures/behavior; inaccessible pages explicitly limited.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Recheck time-sensitive platform/store guidance at candidate freeze; collect outstanding external evidence. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-014

- Current app-store SDK/target API, privacy, and review requirements.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: dated inventory/research documentation

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Apple review and Google target/privacy pages recorded; final submission date requirements have not been frozen.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Release owner re-verifies current SDK/target/privacy/developer-account rules immediately before signing/submission. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-015

Use the document’s dated versions as research starting points, not permanent pins. Select compatible stable versions and record the actual versions tested. Keep deployment minimums distinct from compile SDK, target SDK, and store upload SDK. Availability-check newer optional APIs.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Primary URLs/access date and native API decisions recorded; installed declarations/compiler and provider instrumentation substantiate signatures/behavior; inaccessible pages explicitly limited.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Recheck time-sensitive platform/store guidance at candidate freeze; collect outstanding external evidence. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-016

If current documentation is inaccessible, use the supplied baseline cautiously, mark the specific claim unverified, and continue work that does not depend on it. Do not assert that a package version or method exists merely because it sounds plausible.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Primary URLs/access date and native API decisions recorded; installed declarations/compiler and provider instrumentation substantiate signatures/behavior; inaccessible pages explicitly limited.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Recheck time-sensitive platform/store guidance at candidate freeze; collect outstanding external evidence. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-017

Keep these independent gates visible:

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: docs/RELEASE_AND_SUPPORT.md; docs/acceptance.csv

Evidence: G1–G6 dependencies separated in release guide/evidence ledger; no gate is inferred from another.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: research/platform/release.

Remaining action: Recheck time-sensitive platform/store guidance at candidate freeze; collect outstanding external evidence. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-018

- **G1:** Service-use and distribution basis.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Service-use/distribution basis is not supplied; QR consent is distinct.

Acceptance: AT-S11. Classification: external-dependency. Module: research/platform/release.

Remaining action: Product/release owner records provider/service and intended-distribution basis. Owner: product owner + authorized account owners + device QA. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-019

- **G2:** Actual embedded WhatsApp compatibility.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: No actual accounts linked or messages sent.

Acceptance: AT-A08; AT-I06; AT-M01; AT-M08. Classification: external-dependency. Module: research/platform/release.

Remaining action: Authorized owners provide ten accounts/primary devices and consenting recipients; execute approved compatibility matrix. Owner: product owner + authorized account owners + device QA. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-020

- **G3:** Ten-profile storage isolation and account binding.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: dated inventory/research documentation

Source: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Ten-store same-origin synthetic isolation passed on iOS27 and API36/WebView133; broad shared-channel/update/provider/hardware matrix remains incomplete.

Acceptance: AT-I01; AT-I02; AT-I03; AT-I04; AT-I05; AT-I16. Classification: required. Module: research/platform/release.

Remaining action: Record final expanded native fixture results and complete remaining physical isolation cases. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-021

- **G4:** Lifecycle, restoration, recovery, and deletion.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: dated inventory/research documentation

Source: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Native journals, startup recovery, scoped deletion implemented and focused tests pass; exhaustive crash-stage/restore/provider-change matrix incomplete.

Acceptance: AT-D01; AT-D06; AT-D12; AT-D13; AT-D14. Classification: required. Module: research/platform/release.

Remaining action: Execute full lifecycle/fault and physical restore matrix. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-022

- **G5:** Phone usability and supported media.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: dated inventory/research documentation

Source: apps/mobile/lib/features/; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Phone shell widget coverage; native upload ownership and iOS WKDownload source exist. Essential Android downloads remain OPEN_RELEASE_GAP.

Acceptance: AT-M01; AT-M08; AT-M11; AT-M14. Classification: required. Module: research/platform/release.

Remaining action: Resolve Android download route and execute real-device/service usability/media acceptance. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-023

- **G6:** Release readiness and distribution authorization.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: docs/RESEARCH.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Signing identities, final operator/contact, service basis and distribution authorization absent.

Acceptance: AT-S11; AT-S12. Classification: external-dependency. Module: research/platform/release.

Remaining action: Release owner provides final signing/review/distribution inputs after technical evidence is complete. Owner: product owner + authorized account owners + device QA. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-024

An account owner approving a QR link is different from provider permission to distribute the integration. Mainstream browser support is different from embedded-client support. Extra native screens, original branding, internal distribution, or an unofficial disclosure do not establish permission or guarantee acceptance.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/ARCHITECTURE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Synthetic work continues independently; API35 provider rejection remained blocked rather than falling back; dedicated API36 tested successfully.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Preserve separate compatibility/permission gates; repair actual invariant failures before dependent claims. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

### REQ-03-025

Run synthetic/local implementation work while external evidence is pending. If a core isolation gate actually fails, repair that architecture before adding dependent features. Do not defeat an intentional restriction or conceal an unsupported client.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: dated inventory/research documentation

Source: docs/ARCHITECTURE.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Synthetic work continues independently; API35 provider rejection remained blocked rather than falling back; dedicated API36 tested successfully.

Acceptance: N/A — process/documentation clause. Classification: required. Module: research/platform/release.

Remaining action: Preserve separate compatibility/permission gates; repair actual invariant failures before dependent claims. Owner: integration/release lead. Dependencies: Primary public documentation and installed toolchains.

## 4. Execution plan traceability and collaboration

### REQ-04-001

Create `docs/MASTER_IMPLEMENTATION_PLAN.md` as the authoritative dependency-ordered implementation checklist. Extract requirements from every plan section, not just its feature table.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Exact prompt source preservation plus full Word paragraph/table/hyperlink coverage; implementation dispositions remain scope-limited

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/DESIGN_DOCUMENT_TRACEABILITY.md; docs/PROMPT_VERIFICATION_CHECKLIST.md; scripts/check_traceability.py

Evidence: Whole-design audit traces337 nonempty Word paragraphs,214 table data rows,52 phase bullets,13 risks,36 source IDs/37 links,374 prompt clauses and70 acceptance cases. Automated checker verifies source identities, paragraph/table coverage and generated checklist freshness.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep each disposition tied to actual evidence; update the ledgers and regenerate the prompt checklist when remaining gates are tested. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-002

For each requirement record:

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: 374 original source clauses retained; distinct requirement and acceptance IDs, implementation and validation columns, evidence and next actions.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-003

- Stable requirement ID.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: 374 original source clauses retained; distinct requirement and acceptance IDs, implementation and validation columns, evidence and next actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-004

- Source section or prompt clause.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: 374 original source clauses retained; distinct requirement and acceptance IDs, implementation and validation columns, evidence and next actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-005

- Required, conditional, excluded, rationale, or external-dependency classification.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: Requirement classifications reviewed: required/conditional/excluded/rationale/external-dependency. Status is separate from classification.

Acceptance: N/A — process/documentation clause. Classification: conditional. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-006

- Platform and owning module.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: 374 original source clauses retained; distinct requirement and acceptance IDs, implementation and validation columns, evidence and next actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-007

- Dependencies.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: The dependencies column records prerequisites and external gate context for each row.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-008

- Implementation status and code reference.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: 374 original source clauses retained; distinct requirement and acceptance IDs, implementation and validation columns, evidence and next actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-009

- Acceptance-test IDs.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: 374 original source clauses retained; distinct requirement and acceptance IDs, implementation and validation columns, evidence and next actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-010

- Validation status and evidence reference.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: 374 original source clauses retained; distinct requirement and acceptance IDs, implementation and validation columns, evidence and next actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-011

- Defect/blocker and the exact next action.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: 374 original source clauses retained; distinct requirement and acceptance IDs, implementation and validation columns, evidence and next actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-012

Use distinct namespaces: `REQ-*` for requirements, `AT-A01` through `AT-S12` for acceptance tests, and `SRC-S01` through `SRC-S36` for the source plan’s references. Preserve original acceptance identifiers through this prefix mapping.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: source extraction/namespace audit; no blanket web verification

Source: docs/SOURCE_CATALOG.md; docs/requirements.csv; docs/acceptance.csv

Evidence: All374 REQ IDs,70 original AT cases and36 SRC IDs retained. DOCX XML yields37 exact external hyperlink targets; every source ID/target matches supplied instruction section19. SRC-S09 has2 platform links.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Preserve distinct SRC/AT namespaces; use current verified research rather than treating original source dates as permanent API authority. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-013

Keep implementation status separate from validation status. Validation values must distinguish:

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-014

- `NOT_RUN`

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-015

- `PASS`

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-016

- `FAIL`

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-017

- `BLOCKED_ENVIRONMENT`

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-018

- `BLOCKED_HARDWARE`

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-019

- `BLOCKED_SERVICE_ACCESS`

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-020

- `PENDING_ELAPSED_TIME`

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-021

- `NOT_APPLICABLE_WITH_REASON`

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-022

Skipped tests never count as passed.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: requirements.csv separates implementation_status from validation_status and adds validation_scope. Acceptance ledger preserves NOT_RUN/blocked/elapsed values; skipped results are not PASS.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Use PASS only for explicitly stated scope; broad acceptance remains independent. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-023

Prepare substantive documents with actual decisions and findings: product requirements, system design and ADRs, security/privacy model, testing/evidence ledger, compatibility matrix, build/release guide, support/incident runbook, and `RESUME`. Consolidate related material when appropriate; do not create dozens of empty documentation files.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Substantive architecture, threat, evidence, compatibility, release, support and continuity documents inspected; external product gates remain explicit

Source: docs/ARCHITECTURE.md; docs/THREAT_MODEL.md; docs/RELEASE_AND_SUPPORT.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/RESUME.md

Evidence: Existing substantive documents plus complete Word/prompt checklists and store review draft are present. See docs/DESIGN_VERIFICATION_CHECKLIST.md for the consolidated audit and remaining work.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Update actual device/service/retention/signing results when prerequisites exist; documentation does not substitute for those gates. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-024

If agent tools are available, delegate real independent work within actual concurrency limits. Suitable assignments are iOS engine, Android engine, Flutter UI/registry, and QA/security review. Establish contract and file ownership before parallel edits; use isolated worktrees where helpful and authorized. The lead owns integration and verification. Do not invent agent capabilities, models, or results.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: traceability structure/document review

Source: docs/requirements.csv; docs/acceptance.csv; docs/MASTER_IMPLEMENTATION_PLAN.md

Evidence: Independent Android/iOS/shared workers with explicit file ownership; integration lead owns UI/builds/docs; native security review findings fixed.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Preserve concurrent edits; integrate final worker evidence. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-025

For each implementation unit:

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: scripts/check.sh; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Affected native/coordinator/UI implementation was inspected, tested, fixed and integrated; examples include stale auth, inactive cleanup and iOS cold inventory defects.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: traceability/docs.

Remaining action: Repeat only affected checks after further changes; final source/build checks remain integration responsibility. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-026

1. Inspect the affected code and requirements.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: traceability structure/document review

Source: scripts/check.sh; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Affected native/coordinator/UI implementation was inspected, tested, fixed and integrated; examples include stale auth, inactive cleanup and iOS cold inventory defects.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Repeat only affected checks after further changes; final source/build checks remain integration responsibility. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-027

2. Make the smallest complete change.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: traceability structure/document review

Source: scripts/check.sh; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Affected native/coordinator/UI implementation was inspected, tested, fixed and integrated; examples include stale auth, inactive cleanup and iOS cold inventory defects.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Repeat only affected checks after further changes; final source/build checks remain integration responsibility. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-028

3. Run meaningful checks.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: traceability structure/document review

Source: scripts/check.sh; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Affected native/coordinator/UI implementation was inspected, tested, fixed and integrated; examples include stale auth, inactive cleanup and iOS cold inventory defects.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Repeat only affected checks after further changes; final source/build checks remain integration responsibility. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-029

4. Fix failures at their source.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: traceability structure/document review

Source: scripts/check.sh; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Affected native/coordinator/UI implementation was inspected, tested, fixed and integrated; examples include stale auth, inactive cleanup and iOS cold inventory defects.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Repeat only affected checks after further changes; final source/build checks remain integration responsibility. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-030

5. Update evidence and checklist.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: traceability structure/document review

Source: scripts/check.sh; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Affected native/coordinator/UI implementation was inspected, tested, fixed and integrated; examples include stale auth, inactive cleanup and iOS cold inventory defects.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Repeat only affected checks after further changes; final source/build checks remain integration responsibility. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-031

6. Integrate.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: traceability structure/document review

Source: scripts/check.sh; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Affected native/coordinator/UI implementation was inspected, tested, fixed and integrated; examples include stale auth, inactive cleanup and iOS cold inventory defects.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Repeat only affected checks after further changes; final source/build checks remain integration responsibility. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-032

7. Continue.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: traceability structure/document review

Source: scripts/check.sh; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Affected native/coordinator/UI implementation was inspected, tested, fixed and integrated; examples include stale auth, inactive cleanup and iOS cold inventory defects.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Repeat only affected checks after further changes; final source/build checks remain integration responsibility. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

### REQ-04-033

Preserve existing BLoC/Riverpod or equivalent conventions. If no convention exists, choose Riverpod and document the decision. Do not introduce two competing state systems.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: traceability structure/document review

Source: apps/mobile/lib/app/providers.dart; docs/ARCHITECTURE.md

Evidence: Riverpod selected for new repository; native SQLite remains sole durable lifecycle authority. No competing Dart registry persistence.

Acceptance: N/A — process/documentation clause. Classification: required. Module: traceability/docs.

Remaining action: Keep ledgers synchronized with final native/app results; record source catalog independently. Owner: integration lead. Dependencies: Preserved source instructions; original 70-case acceptance catalog.

## 5. Repository and architecture

### REQ-05-001

Use one modular mobile repository. Adapt an existing layout instead of duplicating it. A suitable new layout is:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: docs/ARCHITECTURE.md; apps/mobile/; packages/; tests/; scripts/

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; registered native engines compile into Flutter development builds.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: repository/module boundaries.

Remaining action: Rerun affected suites when integration boundaries change. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-002

- `apps/mobile/lib/app`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: apps/mobile/lib/app/

Evidence: apps/mobile/lib/app/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-003

- `apps/mobile/lib/features/accounts`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: apps/mobile/lib/features/accounts/

Evidence: apps/mobile/lib/features/accounts/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-004

- `apps/mobile/lib/features/workspace`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: apps/mobile/lib/features/workspace/

Evidence: apps/mobile/lib/features/workspace/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-005

- `apps/mobile/lib/features/privacy`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: apps/mobile/lib/features/privacy/

Evidence: apps/mobile/lib/features/privacy/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-006

- `apps/mobile/lib/features/help`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: apps/mobile/lib/features/help/

Evidence: apps/mobile/lib/features/help/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-007

- `packages/session_contract`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_contract/

Evidence: packages/session_contract/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-008

- `packages/session_engine/ios`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_engine/ios/

Evidence: packages/session_engine/ios/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-009

- `packages/session_engine/android`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_engine/android/

Evidence: packages/session_engine/android/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-010

- `packages/local_registry`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/local_registry/

Evidence: packages/local_registry/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-011

- `tests/profile_harness`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: tests/profile_harness/

Evidence: tests/profile_harness/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-012

- `tests/device_flows`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: tests/device_flows/

Evidence: tests/device_flows/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-013

- `docs`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: docs/

Evidence: docs/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-014

- `scripts`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: scripts/

Evidence: scripts/ contains executable source or substantive procedures appropriate to its module; not empty scaffolding.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Maintain module ownership and relevant checks. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-015

Make the session engine a correctly registered Flutter plugin/platform-view integration, including real platform manifests, build configuration, generated bindings, and lifecycle hooks. Directories and pseudocode do not satisfy implementation.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and focused automated regression; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: packages/session_engine/pubspec.yaml; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/SessionEnginePlugin.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; packages/session_engine/ios/session_engine/Package.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md native plugin compile; actual integrated Flutter development builds. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-A02; AT-S09. Classification: required. Module: repository/module boundaries.

Remaining action: Smoke-test rebuilt final application variants; plugin compilation alone is not launch validation. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-016

Keep UI, domain coordination, persistence, and platform mechanisms separate:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: docs/ARCHITECTURE.md; apps/mobile/; packages/; tests/; scripts/

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; registered native engines compile into Flutter development builds.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: repository/module boundaries.

Remaining action: Rerun affected suites when integration boundaries change. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-017

- `AccountService` owns add/rename/reorder/relink/remove use cases and capacity.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/local_registry/lib/src/account_service.dart

Evidence: Concrete module responsibility implemented; permission/transfer/cleanup helpers may reside inside native engine rather than separate nominal classes.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Validate ownership boundaries through linked native/coordinator scenarios. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-018

- `SessionCoordinator` serializes selection and visibility.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_contract/lib/src/coordinator.dart

Evidence: Concrete module responsibility implemented; permission/transfer/cleanup helpers may reside inside native engine rather than separate nominal classes.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Validate ownership boundaries through linked native/coordinator scenarios. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-019

- `ProfileRegistry` persists metadata and lifecycle records.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift

Evidence: Concrete module responsibility implemented; permission/transfer/cleanup helpers may reside inside native engine rather than separate nominal classes.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Validate ownership boundaries through linked native/coordinator scenarios. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-020

- Native engines own immutable profile-to-WebView binding.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Concrete module responsibility implemented; permission/transfer/cleanup helpers may reside inside native engine rather than separate nominal classes.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Validate ownership boundaries through linked native/coordinator scenarios. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-021

- `PermissionBroker` owns origin/profile-scoped decisions.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Native capture grants denied until capability gate; denial records are profile/origin scoped; reset removes local decisions.

Acceptance: AT-M05; AT-M06. Classification: required. Module: repository/module boundaries.

Remaining action: Validate ownership boundaries through linked native/coordinator scenarios. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-022

- `TransferManager` owns native picker and transfer lifetimes.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: source structure and executed development builds

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Original-view pickers and iOS native transfers implemented; Android download path is unsupported.

Acceptance: AT-M02; AT-M03; AT-M08. Classification: required. Module: repository/module boundaries.

Remaining action: Resolve essential Android download gap and validate file interruption behavior. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-023

- Cleanup coordination owns durable deletion progress and reconciliation.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Concrete module responsibility implemented; permission/transfer/cleanup helpers may reside inside native engine rather than separate nominal classes.

Acceptance: N/A — process/documentation clause. Classification: required. Module: repository/module boundaries.

Remaining action: Validate ownership boundaries through linked native/coordinator scenarios. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-024

Use SQLite with migrations or an equivalently transactional existing local store. Do not introduce microservices, a messaging backend, or unnecessary authentication infrastructure.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift

Evidence: Both platforms use native SQLite schema1 with migration ledger; native transactions are sole allocation/deletion authority.

Acceptance: AT-A05; AT-I12. Classification: required. Module: repository/module boundaries.

Remaining action: Rerun affected suites when integration boundaries change. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-025

Create development, QA/test, and production application identities so test stores cannot become production sessions. Public configuration may contain environment name, log policy, and development harness origin. Never embed secrets in Dart defines or checked-in environment files. Production must not accept arbitrary user-configured workspace URLs or remote executable scripts.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: apps/mobile/android/app/build.gradle.kts; apps/mobile/ios/Runner.xcodeproj/; packages/session_contract/pigeons/session_api.dart

Evidence: Development/QA/production identifiers separate stores. No production command accepts an arbitrary URL or script. No secrets in Dart defines.

Acceptance: AT-S08. Classification: required. Module: repository/module boundaries.

Remaining action: Inspect actual unsigned production artifacts and configure approved signing externally. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

### REQ-05-026

Provide a fake engine for deterministic UI/coordinator tests. Production must use the real native engine and fail explicitly when unavailable. A fake, placeholder, catch-and-return-success implementation, or TODO cannot satisfy a native requirement.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source structure and executed development builds

Source: packages/session_contract/test/support/fake_engine.dart; packages/session_engine/lib/session_engine.dart; scripts/verify_production.py

Evidence: Fake lives only under test; production adapter invokes Pigeon; unavailable native provider fails explicitly; source exclusion scanner passes.

Acceptance: AT-S08; AT-S09. Classification: required. Module: repository/module boundaries.

Remaining action: Keep fake/test origins out of compiled production artifact; run candidate smoke. Owner: integration lead. Dependencies: Flutter SDK; Pigeon; native toolchains.

## 6. Local records allocation and startup reconciliation

### REQ-06-001

Implement these records or equivalent typed entities:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: docs/ANDROID_EVIDENCE.md (9 Android unit tests); docs/IOS_EVIDENCE.md (21 native helper tests); packages/local_registry/test/ (16 facade tests).

Acceptance: N/A — parent entity definition; see REQ-06-002 through REQ-06-008. Classification: rationale. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-002

- **AccountProfile:** immutable `id` and `platformProfileId`; alias; normalizedAlias; color; orderIndex; createdAt; lastOpenedAt; allocation/lifecycle state.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Native records keep stable ID/platform ID, normalized alias, color/order/timestamps/state; on iOS UUID is both logical and native identifier.

Acceptance: AT-A06; AT-I12. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-003

- **ProfileObservation:** profileId; observation; observedAt; evidenceType.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Android observations table stores evidence=operator/time; iOS typed observation+observed_at records operator assertion with semantics implied by enum. Website readiness never records confirmation.

Acceptance: AT-A13. Classification: required. Module: native registry + shared AccountService.

Remaining action: Retain provenance semantics; add explicit evidence field if additional nonoperator observation types are introduced. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance.

### REQ-06-004

- **AppPreferences:** lockMode; returnLockPolicy; locale; theme; diagnosticsChoice.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_contract/pigeons/session_api.dart; apps/mobile/lib/features/privacy/privacy_screen.dart

Evidence: Lock/theme/welcome preferences persisted. English locale, lock-on-return when enabled and on-device diagnostics are fixed product policies; no separate mutable choices are exposed.

Acceptance: AT-S01; AT-S02; AT-S07. Classification: required. Module: native registry + shared AccountService.

Remaining action: Document fixed-policy equivalence in architecture; add persisted choices only when product behavior requires them. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance.

### REQ-06-005

- **PermissionDecision:** profileId; canonical origin; capability; decision; updatedAt.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Native permissions tables include profile/origin/capability/decision/update; unsupported capture is denied, never globally granted.

Acceptance: AT-M05; AT-M06. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-006

- **TransferTask:** taskId; profileId; viewInstanceId; operation ownership; state; short-lived private staging reference.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native source review; iOS staging helper tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Native transient tasks own original ViewHandle and private staging; crash recovery deletes stale app-owned staging. No attachment bytes cross Dart.

Acceptance: AT-M02; AT-M03; AT-M10. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-007

- **CleanupJournal:** profileId; cleanupOperationId; stage; attempts; lastErrorClass; updatedAt.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Cleanup journals persist operation/stage/attempts/error/update; Android clean-process verification passes; iOS tombstone reopen/idempotency helpers pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-008

- **SchemaVersion:** version and migration history.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Schema1 plus migrations table implemented in both registries; version1 reopen tested; no older shipping schema exists.

Acceptance: AT-I12. Classification: required. Module: native registry + shared AccountService.

Remaining action: Before schema2 ships, add actual upgrade migration fixtures; validate app upgrade on signed installation. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance.

### REQ-06-009

Do not persist messages, contacts, page HTML, cookies, QR payloads, pairing codes, OTPs, IndexedDB copies, or WhatsApp cryptographic material in these records.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: schema/source inspection

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; docs/THREAT_MODEL.md

Evidence: Tables contain app metadata and redacted journal state only; website secrets remain in platform stores, not duplicated into registry.

Acceptance: AT-S07. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-010

Account allocation must reserve capacity transactionally before native allocation. Normalize aliases by trimming and case-insensitive comparison, enforce uniqueness, and provide useful validation for empty or long labels.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Native transaction reserves capacity; trim/case-insensitive uniqueness/40 code-point/control validation. Native/shared/widget regression subsets pass.

Acceptance: AT-A04; AT-A05; AT-A07. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-011

The metadata database and native browser store do not share one atomic transaction. Implement a journaled allocation workflow with compensation/reconciliation for crashes between reservation, native store creation, finalization, and first load. Repeated Add taps must never allocate an eleventh account or duplicate a reservation.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and reservation/late-mutation regressions; not every crash stage

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Allocation reserves before native creation; incomplete states reconcile instead of synthetic success. Native reservation and late-mutation unit tests pass; exhaustive process-cut matrix incomplete.

Acceptance: AT-A05; AT-D06. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-012

Preserve backing identifiers during rename, reorder, app upgrade, and metadata migration. A replacement profile receives a new identifier. Never reuse a deleted identifier or assign an orphaned store to a different account.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Rename/reorder tests preserve IDs; fresh replacement and tombstone tests reject reuse; native middle-delete/replacement fixture passes.

Acceptance: AT-A06; AT-I12; AT-I16. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-013

At startup, reconcile registry records, pending allocation, cleanup journal, and the public native store inventory before opening any session. Missing stores, surviving orphan stores, and inconsistent restored records need explicit states. Do not silently create an empty replacement and label it authenticated.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Startup inventory reconciles missing/quarantine/pending stages before opening. Native helper tests and Android separate-process deferred deletion run pass; broad restore matrix incomplete.

Acceptance: AT-I14; AT-D06; AT-D12. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-014

Choose one durable authority for lifecycle/journal stages. Document ownership and bootstrap ordering across Flutter and native code. Native startup must be able to honor tombstones before any plugin, profile getter, preload, or view creation loads a target pending deletion. If callbacks can complete without the Dart UI, the durable completion path must still be reliable; avoid unsynchronized duplicate journals.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: docs/ARCHITECTURE.md; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: ADR001 declares native SQLite authority; native cleanup advances without active Dart view. Android clean-start test verifies deletion before getter.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-015

Define exactly when capacity is released during deferred deletion/relink replacement. Keep at most ten user-accessible/reserved account slots, never reuse pending storage, bound any temporary cleanup containers, and prevent repeated create/remove cycles from consuming capacity forever. Treat this as a tested architectural decision.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native helper and account-service tests

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/local_registry/lib/src/account_service.dart

Evidence: Capacity released only after wipe/app cleanup; Android containerDeletionPending does not reserve slot; backlog10 is bounded; tests assert fresh IDs and deferred limit.

Acceptance: AT-A04; AT-D11; AT-I16. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run remaining physical restore/migration and stage-specific process-interruption scenarios. Owner: native registry engineers. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance; physical-device verification remains separate.

### REQ-06-016

Normal app upgrades should retain valid profiles. Reinstall, backup restoration, and a new phone follow the verified reset/quarantine/relink policy. A matching UUID or a simple installation flag alone is not proof of restore trust.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/ios/session_engine/Sources/session_engine/InstallationBinding.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md installation-bound HMAC/provenance helpers pass; actual reinstall/backup/device-transfer and browser persistence not tested.

Acceptance: AT-I12; AT-D12. Classification: required. Module: native registry + shared AccountService.

Remaining action: Run physical restore/transfer/upgrade procedures; Android failed binding recovery requires deliberate system app-storage reset. Owner: engineering + device QA. Dependencies: Native SQLite authority; public store inventory; installation-bound provenance.

## 7. Typed platform contract and state model

### REQ-07-001

Generate a typed Dart/Swift/Kotlin contract using Pigeon or an equivalent established mechanism.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; scripts/generate_bridge.sh

Evidence: Pigeon29.0.10 generated Dart/Kotlin/Swift compiled with real engines; CI checks generation drift.

Acceptance: N/A — generated interface compile/drift checks. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-002

Include operations equivalent to:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ (23 tests), packages/local_registry/test/ (16 tests); native compile and integrated development builds.

Acceptance: N/A — parent operation list; see REQ-07-003 through REQ-07-012. Classification: rationale. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-003

- `queryCapabilities`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-S09. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-004

- `allocateProfile`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-A02; AT-A05. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-005

- `openProfile`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-I08. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-006

- `disposeView`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-I09. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-007

- `reloadProfileView`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-D09; AT-D10. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-008

- `requestLocalRemoval`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-D01; AT-D02. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-009

- `retryPendingCleanup`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-D05; AT-D14. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-010

- `setPrivacyCover`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-S01; AT-S03. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-011

- `cancelTransfer`

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-M02; AT-M03. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-012

- Typed engine events.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Typed async host operation and native implementation exist; coordinator/facade regression suite exercises applicable ownership and error paths.

Acceptance: AT-I09; AT-D13. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-013

Define explicit error classes, idempotency, cancellation, timeouts, and required execution threads. Keep platform exceptions from becoming uncaught UI crashes. A timeout means an operation needs reconciliation; it is not proof that a native mutation never happened.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: packages/session_contract/lib/src/coordinator.dart; packages/local_registry/lib/src/account_service.dart; apps/mobile/lib/app/actions.dart; packages/session_engine/lib/session_engine.dart

Evidence: Bounded coordinator/account waits preserve original native futures; late mutation results reconciled without replay.23 coordinator and16 facade tests include timeout/lock races. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-I08; AT-D05; AT-S03. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-014

Separate state dimensions:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ (23 tests), packages/local_registry/test/ (16 tests); native compile and integrated development builds.

Acceptance: N/A — parent state model; see REQ-07-015 through REQ-07-018. Classification: rationale. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-015

- **Store:** reserving/allocating, available, removing, cleanup pending, missing/quarantined.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift

Evidence: StoreState allocation/available/removing/cleanupPending/missing/quarantined independent of view and observation.

Acceptance: AT-D06; AT-I14. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-016

- **View:** detached, loading, visible, disposing, failed.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/lib/src/coordinator.dart

Evidence: WorkspacePhase detached/switching/loading/visible/failed plus explicit disposal operation; transition ownership is separate from store/auth state.

Acceptance: AT-I08; AT-D09. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-017

- **Authentication observation:** unknown, user confirmed, relink requested, revocation observed when supported.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift

Evidence: Unknown/userConfirmed/relinkRequested are explicit operator observations; remote revocation detection unsupported and not invented.

Acceptance: AT-A13; AT-D08. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-018

- **Network:** unknown, offline, reachable.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: Typed contract regeneration and unit observations/callback ownership; not physical network handover or service reachability

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NetworkMonitor.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: NetworkObservation unknown/offline/reachable implemented. Android14 native helpers and coordinator25 tests pass; iOS plugin typecheck passes. Android validated INTERNET path and iOS NWPath availability remain distinct from authentication.

Acceptance: AT-S10. Classification: required. Module: typed contract + coordinator.

Remaining action: Device QA exercises Wi-Fi/mobile/offline/captive portal and recovery; never infer login or service availability from an OS path. Owner: engineering + device QA. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-019

A reachable network, completed navigation, title, or HTTP success does not establish WhatsApp authentication, account identity, or synchronization. Use honest Saved/Last opened/User confirmed labels when that is all the app knows.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: apps/mobile/lib/features/workspace/workspace_screen.dart; packages/session_contract/pigeons/session_api.dart

Evidence: Saved/user-confirmed/relink labels use operator observations; viewReady is render readiness only.

Acceptance: AT-A13; AT-S10. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-020

Define event ownership separately:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/lib/session_engine.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ (23 tests), packages/local_registry/test/ (16 tests); native compile and integrated development builds.

Acceptance: AT-I09; AT-M03; AT-D13. Classification: rationale. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-021

- **View events:** profileId, viewInstanceId, operationId, selectionGeneration.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_contract/lib/src/coordinator.dart

Evidence: All4 ViewHandle fields validated; explicit regression requires each field before reveal.

Acceptance: AT-I08; AT-I09. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-022

- **Transfer events:** original profile/view/operation and their explicit lifetime policy.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Transfers retain original immutable owner; stale callback cancellation and lifetime rules implemented; device picker matrix still required.

Acceptance: AT-M02; AT-M03. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-023

- **Cleanup events:** profileId, cleanupOperationId, and journal stage independently of the active selection.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: generated bridge compilation and coordinator tests

Source: packages/session_contract/pigeons/session_api.dart; packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift

Evidence: Cleanup operation independent of selection; regression permits A→C while inactive B cleanup remains outstanding.

Acceptance: AT-D13. Classification: required. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

### REQ-07-024

The production contract must not expose arbitrary JavaScript execution, page extraction, cookie export, session import/export, or native filesystem access. Flutter-to-native controls are not a webpage JavaScript bridge. Any test instrumentation must be restricted to the controlled harness and excluded from production.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: contract/source exclusion check

Source: packages/session_contract/pigeons/session_api.dart; scripts/verify_production.py; tests/profile_harness/

Evidence: No arbitrary script/URL/filesystem/session-export methods; native fixture scripting is outside production plugin contract.

Acceptance: AT-S05; AT-S08. Classification: excluded. Module: typed contract + coordinator.

Remaining action: Preserve typed ownership and late-result reconciliation when extending the bridge. Owner: contract/coordinator engineer. Dependencies: Generated Pigeon bindings; main-thread native engines.

## 8. Race-safe account selection and recovery

### REQ-08-001

Enforce these invariants in real code and tests:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ verifies cover-before-label, stale completion, lock epochs, one live owner, inactive cleanup and late timeout handling. Native evidence in docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Acceptance: AT-I07; AT-I08; AT-I09; AT-M03; AT-D06; AT-S03. Classification: rationale. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-002

1. A WebView is bound to one immutable profile before navigation.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/BoundWebSession.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md real WebView is constructed/bound once before navigation; native storage fixture reopens distinct stores.

Acceptance: AT-I01; AT-I08. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-003

2. Only the latest valid selection transaction can reveal content.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ tests late view ready/dispose/lock and exact4-field ownership. No frame-level physical capture evidence claimed.

Acceptance: AT-I08. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-004

3. The visible native alias and attached profile must match before removing the cover.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ tests late view ready/dispose/lock and exact4-field ownership. No frame-level physical capture evidence claimed.

Acceptance: AT-I07; AT-S03. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-005

4. Every async callback validates its appropriate ownership after asynchronous boundaries.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ tests late view ready/dispose/lock and exact4-field ownership. No frame-level physical capture evidence claimed. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-I09; AT-M03. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-006

5. Removing/tombstoned profiles cannot reopen through callbacks, retries, or restore.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md tombstone access blocking/idempotency helper tests; Android clean-start verify preserves neighbor.

Acceptance: AT-D01; AT-D06. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-007

6. View disposal never wipes persistent session data.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md disposal retains store; hosted fixtures destroy/recreate views then read preserved markers.

Acceptance: AT-I10. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-008

7. File results cannot reach another account.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and staging helpers only; no actual-service attachment validation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md native owner guard/once-callback source; iOS staging cancellation helpers pass. Real OS picker interruption matrix incomplete.

Acceptance: AT-M03. Classification: required. Module: coordinator + native engines.

Remaining action: Execute interrupted/revoked/cloud picker scenarios on minimum/current physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-009

8. Recovery never synthesizes message sends or replays account operations.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_contract/lib/src/coordinator.dart; apps/mobile/lib/app/actions.dart

Evidence: packages/session_contract/test/ reload rebuilds same store with new owner and no operation replay; explicit uncertain-send warning.

Acceptance: AT-D10. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-010

Implement selection in this order:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ verifies cover-before-label, stale completion, lock epochs, one live owner, inactive cleanup and late timeout handling. Native evidence in docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Acceptance: AT-I08; AT-I09; AT-M03; AT-S03. Classification: rationale. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-011

1. Serialize the request and assign a monotonically increasing generation.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ tests late view ready/dispose/lock and exact4-field ownership. No frame-level physical capture evidence claimed. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-I08. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-012

2. Put an opaque native cover over the outgoing content before changing the visible alias.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ tests late view ready/dispose/lock and exact4-field ownership. No frame-level physical capture evidence claimed.

Acceptance: AT-S03. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-013

3. Resolve known native file pickers, permission prompts, recordings, and transfer guards.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and staging helpers only; no actual-service attachment validation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md native owner guard/once-callback source; iOS staging cancellation helpers pass. Real OS picker interruption matrix incomplete.

Acceptance: AT-M02; AT-M03. Classification: required. Module: coordinator + native engines.

Remaining action: Execute interrupted/revoked/cloud picker scenarios on minimum/current physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-014

4. Dispose and release the outgoing WebView while retaining its persistent store.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md disposal retains store; hosted fixtures destroy/recreate views then read preserved markers.

Acceptance: AT-I10. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-015

5. Resolve the target’s immutable identifier and lifecycle eligibility.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ tests late view ready/dispose/lock and exact4-field ownership. No frame-level physical capture evidence claimed.

Acceptance: AT-I14; AT-D01. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-016

6. Construct/bind the target view.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ verifies cover-before-label, stale completion, lock epochs, one live owner, inactive cleanup and late timeout handling. Native evidence in docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Acceptance: AT-I08. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-017

7. Validate profile, view, operation, and current generation before displaying it.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ tests late view ready/dispose/lock and exact4-field ownership. No frame-level physical capture evidence claimed.

Acceptance: AT-I08; AT-I09. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-018

8. On failure, retain an account-specific recovery screen and usable selector.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: apps/mobile/lib/features/workspace/workspace_screen.dart

Evidence: Account-specific error panel and top selector remain outside web content; shell tests exercise small/tablet layout.

Acceptance: AT-D09; AT-S09. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-019

A newer selection supersedes an unfinished older one. Cancellation must not leave leaked views or release another operation’s resources.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: packages/session_contract/test/ tests late view ready/dispose/lock and exact4-field ownership. No frame-level physical capture evidence claimed. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-I08; AT-I09. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-020

Give a clear first-use explanation that switching can lose unsent drafts, scroll state, or transient page activity. When a known native operation is active, offer a deterministic finish/cancel choice. Do not inspect conversation text to detect drafts.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: apps/mobile/lib/app/actions.dart; apps/mobile/lib/l10n/app_en.arb

Evidence: First switching warning persists preference; active known transfer offers explicit cancel; no draft DOM inspection.

Acceptance: AT-D10; AT-M03. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-021

Complete picker callbacks exactly once, including cancellation, view disposal, activity interruption, and profile removal. Discard stale URI grants and temporary files safely.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and staging helpers only; no actual-service attachment validation; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md native owner guard/once-callback source; iOS staging cancellation helpers pass. Real OS picker interruption matrix incomplete. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-M02; AT-M03. Classification: required. Module: coordinator + native engines.

Remaining action: Execute interrupted/revoked/cloud picker scenarios on minimum/current physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-022

A valid inactive-profile cleanup completion must advance its journal after the user switches elsewhere. Do not reject it merely because its profile is not selected. It must not reveal content or alter the current workspace.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift

Evidence: packages/session_contract/test/ inactive B cleanup regression passes while A selectsC; native journals not gated by selected profile.

Acceptance: AT-D13. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-023

Implement bounded, visible renderer/reconnect recovery. Preserve the affected profile, distinguish service outage from corruption, and avoid infinite reload loops. After uncertain send status, let the operator inspect the official interface. Do not claim control over the website’s own internal delivery/retry behavior.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/coordinator regression only

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Renderer callbacks expose failed state; reload is explicit and creates same-store view. No auto-resend or infinite reload loop; physical renderer/network fault validation incomplete.

Acceptance: AT-D09; AT-D10; AT-S10. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

### REQ-08-024

Keep the single-live-view rule application-wide. Disable unsupported multi-window/multi-scene behavior explicitly rather than accidentally creating one active account view per window.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: coordinator regression and native source review; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: apps/mobile/ios/Runner/Info.plist; apps/mobile/android/app/src/main/AndroidManifest.xml; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: iOS multi-scene disabled; Android singleTask activity; process-scoped native runtime one active view.200 fake switches verify coordinator limit. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-I07. Classification: required. Module: coordinator + native engines.

Remaining action: Complete frame-capture, native picker and interruption cases on physical devices. Owner: coordinator + native engineers. Dependencies: Immutable native binding; 4-part event ownership; durable cleanup journal; physical-device verification remains separate.

## 9. iOS engine implementation

### REQ-09-001

Use public Swift/WebKit APIs with iOS 17 as the baseline unless a documented requirement change is approved.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native compilation, helper tests and hosted WebKit fixture

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: docs/IOS_EVIDENCE.md public iOS17 named-store APIs typecheck;23 simulator native tests pass; hosted fixture exercises disposal/reopen.

Acceptance: AT-I01; AT-I02; AT-I10; AT-S08. Classification: required. Module: iOS native engine.

Remaining action: Complete iOS17 minimum/current physical-device and authorized service matrix. Owner: iOS engineer + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access; physical-device verification remains separate.

### REQ-09-002

For each profile, use its stable UUID with `WKWebsiteDataStore(forIdentifier:)`, set `WKWebViewConfiguration.websiteDataStore` before constructing `WKWebView`, and reopen the same named store on subsequent ordinary launches.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native compilation, helper tests and hosted WebKit fixture

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: docs/IOS_EVIDENCE.md public iOS17 named-store APIs typecheck;23 simulator native tests pass; hosted fixture exercises disposal/reopen.

Acceptance: AT-I01; AT-I02; AT-I10; AT-S08. Classification: required. Module: iOS native engine.

Remaining action: Complete iOS17 minimum/current physical-device and authorized service matrix. Owner: iOS engineer + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access; physical-device verification remains separate.

### REQ-09-003

Do not use the default persistent store for account slots, cookie swapping, separate process pools, or separate WebView objects as a substitute for isolated stores. Do not invent private API workarounds.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native compilation, helper tests and hosted WebKit fixture

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: docs/IOS_EVIDENCE.md public iOS17 named-store APIs typecheck;23 simulator native tests pass; hosted fixture exercises disposal/reopen.

Acceptance: AT-I01; AT-I02; AT-I10; AT-S08. Classification: required. Module: iOS native engine.

Remaining action: Complete iOS17 minimum/current physical-device and authorized service matrix. Owner: iOS engineer + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access; physical-device verification remains separate.

### REQ-09-004

Run UIKit/WebKit lifecycle work on the required main actor/thread. Use appropriately available `WKNavigationDelegate`, `WKUIDelegate`, `WKDownload`, and content-process termination callbacks.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native compilation, helper tests and hosted WebKit fixture

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: docs/IOS_EVIDENCE.md public iOS17 named-store APIs typecheck;23 simulator native tests pass; hosted fixture exercises disposal/reopen.

Acceptance: AT-I01; AT-I02; AT-I10; AT-S08. Classification: required. Module: iOS native engine.

Remaining action: Complete iOS17 minimum/current physical-device and authorized service matrix. Owner: iOS engineer + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access; physical-device verification remains separate.

### REQ-09-005

iOS has no `WKWebView.destroy()` equivalent. Implement disposal concretely: cancel owned operations, stop relevant loading, remove the view, disconnect observers/delegates/handlers where appropriate, release engine references, and verify no unintended retain cycle remains. Keep the persistent store.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native compilation, helper tests and hosted WebKit fixture

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: docs/IOS_EVIDENCE.md public iOS17 named-store APIs typecheck;23 simulator native tests pass; hosted fixture exercises disposal/reopen.

Acceptance: AT-I01; AT-I02; AT-I10; AT-S08. Classification: required. Module: iOS native engine.

Remaining action: Complete iOS17 minimum/current physical-device and authorized service matrix. Owner: iOS engineer + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access; physical-device verification remains separate.

### REQ-09-006

Compare ordinary rendering and the public desktop-content preference using the real prototype. Do not make browser impersonation or an access-control bypass a prerequisite.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: Public desktop content preference chosen; ordinary-versus-desktop comparison has no real authorized WhatsApp evidence.

Acceptance: AT-A08; AT-M11. Classification: external-dependency. Module: iOS native engine.

Remaining action: QA compares real embedded rendering modes with approved test account; no user-agent impersonation/bypass. Owner: product owner + authorized account owners + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access.

### REQ-09-007

Evaluate App-Bound Domains against observed legitimate navigation. Its domain limit is not the account limit. Validate service-worker registration, update, restoration, and cleanup in all ten named stores, especially profiles four through ten. Historical engine discussions are test inputs, not proof of current behavior.

**Implementation:** PARTIAL · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/ios/session_engine/Sources/session_engine/BoundWebSession.swift; apps/mobile/ios/Runner/Info.plist; packages/session_engine/ios/NativeTests/HarnessApp/

Evidence: docs/IOS_EVIDENCE.md App-Bound origin configured; hosted ten-profile worker cache/reopen/removal passes. Legitimate WhatsApp navigation and complete worker-update matrix unverified.

Acceptance: AT-I03; AT-I05; AT-S04. Classification: required. Module: iOS native engine.

Remaining action: Complete expanded fixture update/channel checks and authorized service navigation. Owner: engineering + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access.

### REQ-09-008

For local deletion: persist removing state, block access, stop owned activity, release every view referencing the store, invoke the public named-store removal API, and handle the actual completion/error. Clean app-owned records and files using a durable journal. An unavailable or failed API leaves cleanup pending.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native compilation, helper tests and hosted WebKit fixture

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: docs/IOS_EVIDENCE.md public named removal and durable stages; helper idempotency/tombstones and hosted middle removal pass. Fault injection remains partial.

Acceptance: AT-D01; AT-D02; AT-D05; AT-D06; AT-D13. Classification: required. Module: iOS native engine.

Remaining action: Complete iOS17 minimum/current physical-device and authorized service matrix. Owner: iOS engineer + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access; physical-device verification remains separate.

### REQ-09-009

Do not reopen a production tombstoned session to inspect deletion. Controlled destructive verification belongs in the test harness. Quarantine orphan stores through public APIs; do not edit WebKit’s live database files.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native compilation, helper tests and hosted WebKit fixture

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: Production enumerates before removal and never opens tombstones for verification; test-only fixture destructive reopen isolated; orphan stores quarantined.

Acceptance: AT-D06; AT-D12. Classification: required. Module: iOS native engine.

Remaining action: Complete iOS17 minimum/current physical-device and authorized service matrix. Owner: iOS engineer + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access; physical-device verification remains separate.

### REQ-09-010

Handle content-process termination by recreating only the affected view against the same eligible store. Disable production inspectability. Availability-check optional APIs newer than iOS 17. Record realistic background suspension, eviction, and relinking behavior without claiming indefinite persistence.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and compiled API availability; renderer/retention not fully executed

Source: packages/session_engine/ios/session_engine/Sources/session_engine/

Evidence: Termination callback preserves same-store identity and visible recovery; inspectability false; optional18.4 picker gated. No indefinite retention claim.

Acceptance: AT-D09; AT-S08; AT-I15. Classification: required. Module: iOS native engine.

Remaining action: Execute physical renderer/background/eviction cases and actual elapsed retention. Owner: iOS engineer + device QA. Dependencies: iOS17+; public named-store APIs; main actor; actual service access; physical-device verification remains separate.

## 10. Android engine implementation

### REQ-10-001

Use Kotlin and a verified compatible stable AndroidX WebKit release.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/build.gradle.kts

Evidence: AndroidX WebKit1.17.1 resolved/compiled and exercised on API36/WebView133; Kotlin2.4.0/AGP9.1.0/JDK17 documented.

Acceptance: AT-S09; AT-I13. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-002

Before allocation check an available provider, `WebViewFeature.MULTI_PROFILE`, and `WebViewFeature.DELETE_BROWSING_DATA` for the planned immediate wipe route. Reevaluate after provider changes. The Android version, installed library, compile SDK, and target SDK do not establish provider support.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md API35/WebView124 lacks scoped deletion and production allocation was rejected; API36/WebView133 both features present. Provider return-cycle incomplete.

Acceptance: AT-S09; AT-I13; AT-D14. Classification: required. Module: Android native engine.

Remaining action: Run actual provider disappearance/return and physical OEM updates; keep access blocked when features absent. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-003

The native factory must create `WebView`, immediately bind the permanent profile through `WebViewCompat.setProfile`, and only then configure or navigate it. Audit Flutter plugins for any hidden configuration or loading before assignment. Never rebind an existing view.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: Direct native WebView factory calls setProfile as first method; no third-party WebView constructor. API36 ten-profile six-store fixture passes.

Acceptance: AT-I01; AT-I08. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-004

Use profile-scoped `CookieManager`, `WebStorage`, and `ServiceWorkerController`. Native grants, pickers, files, and transfers also require explicit scoping. Avoid default-profile helpers in cleanup/download code.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: Existing target profile supplies storage/worker handles; scoped deletion/callback ownership implemented. No global cookie export; downloads disabled.

Acceptance: AT-I01; AT-I02; AT-I03; AT-M03. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-005

Implement Android disposal on the correct thread: detach, destroy, and release the view without clearing session data. Handle `onRenderProcessGone` with bounded recovery against the same profile. Do not treat `onPause` as proof all JavaScript stopped, and do not use global `pauseTimers` as a per-account control.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source review and view-disposal fixture; renderer crash unexecuted

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: Main-thread detach/destroy releases view retaining native store; onRenderProcessGone reports failure for same owner; no global pauseTimers.

Acceptance: AT-I10; AT-D09. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-006

Implement removal as a persistent state machine with distinct stages for:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: rationale. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-007

- Requested.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-008

- Access blocked.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-009

- Clients disposed.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-010

- Website wipe pending.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-011

- Website wiped.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-012

- App data cleanup pending.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-013

- Container deletion pending.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-014

- Complete.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt

Evidence: Durable requested/accessBlocked/clientsDisposed/websiteWipePending/websiteWiped/appDataCleanupPending/containerDeletionPending/complete stages. API36 prepare and separate clean-process verify pass.

Acceptance: AT-D04; AT-D06; AT-D13. Classification: required. Module: Android native engine.

Remaining action: Inject termination/disk failure at every stage on controlled native test device; current process test covers deferred-stage restart only. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-015

Preserve these behaviors regardless of chosen names:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md scoped wipe waits actual callback after tombstone/dispose; real fixture verifies middle wipe after bounded active-worker burst.

Acceptance: AT-D01; AT-D04; AT-D07. Classification: rationale. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-016

1. Persist the tombstone and deny new opens, restore, and late page writes.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md scoped wipe waits actual callback after tombstone/dispose; real fixture verifies middle wipe after bounded active-worker burst.

Acceptance: AT-D01; AT-D04; AT-D07. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-017

2. Obtain the target’s existing scoped `WebStorage` handle without recreating an absent profile.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md scoped wipe waits actual callback after tombstone/dispose; real fixture verifies middle wipe after bounded active-worker burst.

Acceptance: AT-D01; AT-D04; AT-D07. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-018

3. Cancel owned native operations, detach/destroy every associated view, and release references.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md scoped wipe waits actual callback after tombstone/dispose; real fixture verifies middle wipe after bounded active-worker burst.

Acceptance: AT-D01; AT-D04; AT-D07. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-019

4. Prevent concurrent target loads/restores while wiping.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md scoped wipe waits actual callback after tombstone/dispose; real fixture verifies middle wipe after bounded active-worker burst.

Acceptance: AT-D01; AT-D04; AT-D07. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-020

5. Invoke the verified profile-specific browsing-data deletion API and await its actual callback.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md scoped wipe waits actual callback after tombstone/dispose; real fixture verifies middle wipe after bounded active-worker burst.

Acceptance: AT-D01; AT-D04; AT-D07. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-021

6. Handle errors, process death, provider loss, and disk failures explicitly.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/helper coverage; full disk/provider transition fault matrix incomplete

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: Failures retain blocked pending journal; no timeout-as-success; native unit journal durability and separate-process deferred stage pass.

Acceptance: AT-D05; AT-D06; AT-D14. Classification: required. Module: Android native engine.

Remaining action: Inject disk failures and each cleanup process boundary; execute actual provider support disappearance/return. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal.

### REQ-10-022

7. Clean target-owned staging files and permission records.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: Target-only permissions/transfers removed; private staging cleanup separate from browser wipe; no persisted grants acquired.

Acceptance: AT-M10; AT-D04. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-023

8. Track final native profile-container deletion separately.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: API36 separate fresh instrumentation process initialized journal before any target getter; tombstoned container absent and neighbor retained. Repeated cleanup operation remains idempotent.

Acceptance: AT-D04; AT-D06. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-024

9. Complete `ProfileStore` deletion during a clean startup before `getProfile`, `getOrCreateProfile`, `setProfile`, or other code loads that target.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: API36 separate fresh instrumentation process initialized journal before any target getter; tombstoned container absent and neighbor retained. Repeated cleanup operation remains idempotent.

Acceptance: AT-D04; AT-D06. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-025

10. Reconcile before opening saved accounts; handle an already absent target idempotently.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: API36 separate fresh instrumentation process initialized journal before any target getter; tombstoned container absent and neighbor retained. Repeated cleanup operation remains idempotent.

Acceptance: AT-D04; AT-D06. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-026

Reverify the exact loaded-profile deletion restriction and enumeration behavior in current documentation and instrumentation. Destroying a visible WebView alone must not be assumed to make immediate `deleteProfile` legal.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md current ProfileStore docs plus actual loaded-profile restriction assertion. Default excluded; delete true/false handled without forensic/synchronous wipe claim.

Acceptance: AT-D04; AT-I16. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-027

Handle `deleteProfile` return semantics correctly: `true` means the profile existed and deletion was accepted; some disk cleanup can remain asynchronous. `false` means the profile was absent. Do not equate either result with a separately verified completed website-data wipe.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md current ProfileStore docs plus actual loaded-profile restriction assertion. Default excluded; delete true/false handled without forensic/synchronous wipe claim.

Acceptance: AT-D04; AT-I16. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-028

Enumeration includes the default profile: never delete it, and reconcile only clearly app-owned account stores. Keep ambiguous inventory entries quarantined rather than assigning or deleting them blindly. Verify these behaviors against `SRC-S20`.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native unit and API36 emulator instrumentation

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: docs/ANDROID_EVIDENCE.md current ProfileStore docs plus actual loaded-profile restriction assertion. Default excluded; delete true/false handled without forensic/synchronous wipe claim.

Acceptance: AT-D04; AT-I16. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-029

Browsing-data deletion is not atomic relative to concurrent writes. Test and document service-worker quiescence and the evidence supporting successful cleanup. Do not claim forensic erasure or guarantees unsupported by the API.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: one bounded concurrent-worker synthetic scenario on WebView133

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: API36 same-origin fixture starts4-second worker write burst, removes target, checks after burst lifetime; passes. This does not establish universal quiescence or forensic erasure.

Acceptance: AT-D07. Classification: required. Module: Android native engine.

Remaining action: Repeat with physical providers/update behaviors; preserve documented non-atomic API limitation. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-030

If required provider capabilities disappear, retain blocked access and a pending wipe until support returns. Management, cleanup requests, compatibility guidance, and official remote-unlink help must remain available. Never show false success.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: API35 unsupported-provider runtime plus source inspection of retry

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: Unsupported provider gate rejects allocation and permits management/cleanup request; pending wipe retained. Actual disappearance-and-return cycle not yet tested.

Acceptance: AT-S09; AT-D14. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

### REQ-10-031

Do not force-kill the app as a cleanup UX, delete all profiles to remove one, manipulate live Chromium databases, or use ten processes/data directories as an unplanned fallback. A supported-capability failure must never fall back to shared storage.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source boundary review and unsupported-provider test

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/

Evidence: No shared-storage fallback, force kill cleanup UX, browser database manipulation, all-profile wipe or ten-process design.

Acceptance: AT-S09; AT-D04. Classification: required. Module: Android native engine.

Remaining action: Verify current/minimum/OEM physical providers and stage-specific fault cases. Owner: Android engineer + device QA. Dependencies: MULTI_PROFILE and DELETE_BROWSING_DATA runtime features; main thread; startup journal; physical-device verification remains separate.

## 11. Screens pairing and account-management behavior

### REQ-11-001

Implement the welcome, empty, add-account, linking, workspace, account-manager, profile-settings, privacy-settings, recovery, and help/diagnostics screens.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: shell widget and source behavior coverage

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: All requested screen/state paths implemented, including recovery, compatibility and native diagnostic share;7 shell widget tests pass.

Acceptance: AT-A01; AT-A10; AT-S09. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-002

Use a native top selector with alias, color/monogram, selected indicator, and dropdown. On phones use an accessible sheet; on tablets use an anchored popover. Show capacity, Add account, and honest status. Long aliases need an accessible full label. Use text/icons in addition to color.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: shell widget and source behavior coverage

Source: apps/mobile/lib/features/workspace/workspace_screen.dart; apps/mobile/lib/app/design.dart

Evidence: Top selector, monogram/full semantic alias, selected state/capacity, phone sheet and wide-screen presentation implemented;7 widget tests cover layout, not physical screen reader.

Acceptance: AT-A07; AT-M11; AT-M13; AT-M14. Classification: required. Module: Flutter shell/account UI.

Remaining action: Verify wide-screen anchor behavior, keyboard focus and VoiceOver/TalkBack actual announcements. Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-003

Keep destructive actions in management with a confirmation naming the target profile. Separate remove-local-profile from remote unlink. Removing local access while offline must not imply the service’s linked-device record was revoked.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: shell widget and source behavior coverage

Source: apps/mobile/lib/features/accounts/account_screens.dart

Evidence: Management confirmations name target; remove all explicit; copy distinguishes local deletion/remote unlink/exported files.

Acceptance: AT-D01; AT-D02; AT-D03. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-004

First pairing:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: Welcome explains primary device/storage/inactive behavior; capability check precedes allocate; native binds isolated store and loads official HTTPS only.

Acceptance: AT-A01; AT-A02; AT-A08; AT-A11. Classification: rationale. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-005

1. Explain local session storage and foreground/inactive-account limitations.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and first-launch/widget/capacity coverage; no actual QR pairing

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: Welcome explains primary device/storage/inactive behavior; capability check precedes allocate; native binds isolated store and loads official HTTPS only.

Acceptance: AT-A01; AT-A02; AT-A08; AT-A11. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-006

2. Check capabilities.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and first-launch/widget/capacity coverage; no actual QR pairing

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: Welcome explains primary device/storage/inactive behavior; capability check precedes allocate; native binds isolated store and loads official HTTPS only.

Acceptance: AT-A01; AT-A02; AT-A08; AT-A11. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-007

3. Collect alias and reserve capacity.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and first-launch/widget/capacity coverage; no actual QR pairing

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: Welcome explains primary device/storage/inactive behavior; capability check precedes allocate; native binds isolated store and loads official HTTPS only.

Acceptance: AT-A01; AT-A02; AT-A08; AT-A11. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-008

4. Allocate and bind the isolated native profile.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and first-launch/widget/capacity coverage; no actual QR pairing

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: Welcome explains primary device/storage/inactive behavior; capability check precedes allocate; native binds isolated store and loads official HTTPS only.

Acceptance: AT-A01; AT-A02; AT-A08; AT-A11. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-009

5. Load the official [WhatsApp Web website](https://web.whatsapp.com/).

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and first-launch/widget/capacity coverage; no actual QR pairing

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: Welcome explains primary device/storage/inactive behavior; capability check precedes allocate; native binds isolated store and loads official HTTPS only.

Acceptance: AT-A01; AT-A02; AT-A08; AT-A11. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-010

6. Explain official primary-device “Linked devices” → “Link a device” approval.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source and first-launch/widget/capacity coverage; no actual QR pairing

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: Welcome explains primary device/storage/inactive behavior; capability check precedes allocate; native binds isolated store and loads official HTTPS only.

Acceptance: AT-A01; AT-A02; AT-A08; AT-A11. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-011

7. Let the primary device scan the displayed QR.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: apps/mobile/lib/features/; apps/mobile/lib/l10n/app_en.arb

Evidence: No authorized primary test phone/account supplied; no QR captured or parsed.

Acceptance: AT-A08. Classification: external-dependency. Module: Flutter shell/account UI.

Remaining action: Authorized owner scans official page QR displayed in selected native profile; record only redacted outcome. Owner: product owner + authorized account owners + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-012

8. Ask the operator to verify the account shown by the official site and confirm the alias.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/account-service tests, not paired-account identity verification

Source: apps/mobile/lib/features/accounts/account_screens.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift

Evidence: Explicit operator confirmation prompt names alias and says app does not inspect identity; observation persisted independently.

Acceptance: AT-A08; AT-A13. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-013

Keep host instructions outside the webpage. Do not collect QR values, OTPs, credentials, or pairing codes. Displaying a QR does not require this app’s camera permission.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract boundary review

Source: apps/mobile/lib/features/help/help_screen.dart; packages/session_contract/pigeons/session_api.dart

Evidence: Instructions rendered outside webpage; contract has no credential/QR/code collection; no camera permission needed for display.

Acceptance: AT-S05; AT-S07. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-014

Explain same-phone pairing before it becomes a dead end. Provide official phone-number linking only after its actual flow works in this client; otherwise explain the separate-device requirement. Opening another browser’s QR links that browser’s profile, not this application’s selected profile.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: shell widget and source behavior coverage

Source: apps/mobile/lib/features/help/help_screen.dart; apps/mobile/lib/l10n/app_en.arb

Evidence: Explicit same-phone limitation/separate primary-device explanation appears before setup; phone-code linking unpromised; alternate browser QR explained. First-launch widget test passes.

Acceptance: AT-A11. Classification: conditional. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-015

Handle QR expiration/reload, already-full linked-device allowance, cancellation, wrong-account pairing, and relinking without inventing verification. Partial setup offers Keep for later or Remove local setup with correct capacity and crash recovery.

**Implementation:** PARTIAL · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: complete clause not yet verified; see evidence for executed subset

Source: apps/mobile/lib/features/accounts/account_screens.dart; apps/mobile/lib/features/help/help_screen.dart

Evidence: Keep later/remove local setup flows and2 widget branch tests pass; QR expiry/full-device/wrong-account actual-service cases untested.

Acceptance: AT-A09; AT-A10; AT-A12; AT-A13. Classification: required. Module: Flutter shell/account UI.

Remaining action: Run authorized expiry/limit/wrong-account tests while preserving official page failure; verify persisted reservation/removal across native relaunch. Owner: engineering + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-016

Relinking a valid existing context is deliberate. Corrupt-store replacement receives a new ID and journaled cleanup of the old store; preserve alias only through an explicit choice. Do not wipe all profiles to fix one account.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: shell widget and source behavior coverage

Source: packages/local_registry/lib/src/account_service.dart; apps/mobile/lib/features/accounts/account_screens.dart

Evidence: packages/local_registry/test/replacement_test.dart validates fresh identity/explicit alias choice/wipe-before-allocate; relink keeps eligible same store. Android restore-binding failure requires system reset.

Acceptance: AT-I14; AT-I16; AT-D08. Classification: required. Module: Flutter shell/account UI.

Remaining action: Execute native integrated UI and approved-service procedures in tests/device_flows/README.md Owner: Flutter UI engineer + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

### REQ-11-017

Implement safe areas, keyboard/IME overlap, focus, scrolling, large text, light/dark shell themes, orientation, tablet resizing, accessible error states, and selector reachability. Use original placeholder branding pending a final approved name; do not invent ownership or trademark clearance.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: apps/mobile/lib/app/design.dart; apps/mobile/lib/features/

Evidence: apps/mobile/test/shell_test.dart small large-text and tablet dark layouts pass; app branding original provisional. Actual website keyboard/screen-reader/device resize not validated.

Acceptance: AT-M11; AT-M12; AT-M13; AT-M14. Classification: required. Module: Flutter shell/account UI.

Remaining action: Run physical accessibility/orientation/IME matrix; release owner approves final name independently. Owner: engineering + device QA. Dependencies: Native capabilities; shared account/coordinator state; separate primary linking device.

## 12. Navigation permissions files and media

### REQ-12-001

Parse URLs canonically and check scheme and exact host. Do not authorize by substring or suffix matches that accept malicious lookalike hosts. Distinguish main-frame navigation from legitimate third-party subresources and document the tested origin policy.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: policy helper tests and native source review

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NavigationPolicy.kt; packages/session_engine/ios/session_engine/Sources/session_engine/WorkspaceURLPolicy.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md exact parsed HTTPS host/default443/user-info policy tests pass; third-party subresources not mistaken for top-level workspace navigation.

Acceptance: AT-S04; AT-S05. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Complete scoped file/permission/TLS/deep-link device cases without weakening production policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-002

Keep expected workspace navigation in the bound view. Route ordinary external links through an appropriate system browser after user action. Handle redirects, telephone links, app deep links, unsupported schemes, and new-window requests explicitly.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native exact-origin/scheme helpers and source routing review

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NavigationPolicy.kt; packages/session_engine/ios/session_engine/Sources/session_engine/WorkspaceURLPolicy.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Native user-initiated supported links route through OS; untrusted redirects and unsupported schemes rejected. Service-specific deep-link compatibility remains unverified.

Acceptance: AT-S04. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Complete scoped file/permission/TLS/deep-link device cases without weakening production policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-003

Popups must not silently create a default-profile or hidden second WebView. Choose a tested same-context route or explicit unsupported behavior consistent with the one-view rule. Do not broadly block legitimate service assets without testing.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: policy helper tests and native source review

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NavigationPolicy.kt; packages/session_engine/ios/session_engine/Sources/session_engine/WorkspaceURLPolicy.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: No popup factory creates another/default WebView; same-context route or explicit refusal. Legitimate real-service popup path still needs validation.

Acceptance: AT-S04; AT-S05. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Complete scoped file/permission/TLS/deep-link device cases without weakening production policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-004

Never bypass invalid TLS, disable Safe Browsing where supported, introduce broad mixed-content/transport exceptions, or expose arbitrary local files.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/manifest inspection; physical invalid-TLS runtime scenario pending

Source: apps/mobile/android/app/src/main/AndroidManifest.xml; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; packages/session_engine/ios/session_engine/Sources/session_engine/BoundWebSession.swift

Evidence: Production has no TLS trust bypass; Android cleartext/mixed content prohibited and Safe Browsing enabled; iOS default TLS handling. Test CA limited to synthetic identities.

Acceptance: AT-S06. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Execute invalid-cert/mixed-content controlled fixture through actual built production-equivalent policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-005

Use no general webpage-to-native bridge. A narrow future bridge requires a reviewed origin/frame-aware contract, bounded payloads, operation ownership, and tests. The top visible URL alone does not authenticate an iframe.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract static inspection

Source: packages/session_contract/pigeons/session_api.dart; scripts/verify_production.py

Evidence: No webpage-to-native bridge or arbitrary JS/export API; production scanner passes.

Acceptance: AT-S05; AT-S08. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Complete scoped file/permission/TLS/deep-link device cases without weakening production policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-006

Check OS permission and web-origin permission separately. Grants must match the requesting profile, active trusted origin, requested capability, and user intent. Do not blanket-grant a request’s full resource array. Stop or safely interrupt capture on lock, switch, or loss of foreground.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/manifest review; capture deliberately unavailable

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NavigationPolicy.kt; packages/session_engine/ios/session_engine/Sources/session_engine/WorkspaceURLPolicy.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Camera/microphone/geolocation denied until supported; no contacts/SMS/location/notification permissions; system file picker scoped to original owner. No blanket grant.

Acceptance: AT-M05; AT-M06; AT-M07. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Complete scoped file/permission/TLS/deep-link device cases without weakening production policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-007

Request camera or microphone only for supported user-initiated actions. Prefer system limited photo/file pickers. Do not request contacts, SMS, location, or baseline notifications. An existing global OS permission never authorizes every web origin.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/manifest review; capture deliberately unavailable

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NavigationPolicy.kt; packages/session_engine/ios/session_engine/Sources/session_engine/WorkspaceURLPolicy.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Camera/microphone/geolocation denied until supported; no contacts/SMS/location/notification permissions; system file picker scoped to original owner. No blanket grant.

Acceptance: AT-M05; AT-M06; AT-M07. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Complete scoped file/permission/TLS/deep-link device cases without weakening production policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-008

For uploads:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md original-view system pickers; iOS chunked private staging/cancellation helpers pass; Android scoped URI/no persistent grant; no attachment bytes in Dart.

Acceptance: AT-M01; AT-M02; AT-M03; AT-M04. Classification: rationale. Module: native navigation/permissions/transfers.

Remaining action: Run real-system picker/file cases including cloud, revoked access, zero-byte/large input and interruption; then authorized website delivery. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-009

- Bind selection to the original profile/view/operation.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native source/staging helpers; service-file flow not established; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md original-view system pickers; iOS chunked private staging/cancellation helpers pass; Android scoped URI/no persistent grant; no attachment bytes in Dart. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-M01; AT-M02; AT-M03; AT-M04. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Run real-system picker/file cases including cloud, revoked access, zero-byte/large input and interruption; then authorized website delivery. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-010

- Complete success/cancellation once.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native source/staging helpers; service-file flow not established; attachment/picker regressions exercise limited native paths, not full physical or service acceptance

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md original-view system pickers; iOS chunked private staging/cancellation helpers pass; Android scoped URI/no persistent grant; no attachment bytes in Dart. Whole-design audit additionally fixed Flutter attachment ownership and native picker callback gaps; Android18 native unit tests and iOS24 actual callback/registration assertions pass. See docs/ANDROID_DESIGN_AUDIT.md and docs/IOS_DESIGN_AUDIT.md for preserved failing baselines and exact limits.

Acceptance: AT-M01; AT-M02; AT-M03; AT-M04. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Run real-system picker/file cases including cloud, revoked access, zero-byte/large input and interruption; then authorized website delivery. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-011

- Support exposed multiple selection where validated.

**Implementation:** PARTIAL · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Native exposed multiple selection is implemented but actual supported website selection not validated.

Acceptance: AT-M01. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Validate multiple-photo/document delivery on minimum/current devices with authorized service account. Owner: engineering + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-012

- Handle cloud-backed, large, zero-byte, unusual-name, revoked-access, interrupted, and low-space cases.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/IOS_EVIDENCE.md tests multibyte names/chunk copying/cancellation/partial failure; cloud-backed/revoked/low-space/large real device matrix incomplete.

Acceptance: AT-M04; AT-M09. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Run controlled Files/Android document-provider and disk-pressure scenarios; verify actionable error and bounded memory. Owner: engineering + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-013

- Prefer scoped URIs/streams; avoid whole attachments in Dart memory or large base64 bridge messages.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native source/staging helpers; service-file flow not established

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md original-view system pickers; iOS chunked private staging/cancellation helpers pass; Android scoped URI/no persistent grant; no attachment bytes in Dart.

Acceptance: AT-M01; AT-M02; AT-M03; AT-M04. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Run real-system picker/file cases including cloud, revoked access, zero-byte/large input and interruption; then authorized website delivery. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-014

- Keep staging private and profile-specific; clean on success, cancellation, removal, and crash recovery.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: Full cleanup-on-success clause is not implemented or verified; private staging, cancellation/removal helpers and picker ownership checks pass separately.

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: iOS successful picker imports retain copies for WebKit consumption until the bound view is disposed, the profile removed, or startup cleanup. Returning URLs does not prove website upload completion. Native callback regression verifies identity and destination, not actual service delivery. See docs/IOS_DESIGN_AUDIT.md and docs/THREAT_MODEL.md.

Acceptance: AT-M01; AT-M02; AT-M03; AT-M04. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Native engineering establishes a public browser-safe post-consumption cleanup policy or an explicit product retention decision; device QA validates delivery and cleanup without deleting files before WebKit reads them. Owner: native engineering + product owner + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-015

- Let the official website enforce its current messaging/file limits rather than inventing substitutes.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native source/staging helpers; service-file flow not established

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md original-view system pickers; iOS chunked private staging/cancellation helpers pass; Android scoped URI/no persistent grant; no attachment bytes in Dart.

Acceptance: AT-M01; AT-M02; AT-M03; AT-M04. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Run real-system picker/file cases including cloud, revoked access, zero-byte/large input and interruption; then authorized website delivery. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-016

For downloads:

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: parent clause; status reflects associated child requirements

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: iOS WKDownload uses browser context/private sanitized destinations/explicit anchored share. Native progress and shared determinate/indeterminate UI are implemented; actual WKDownload HTTP/blob/share flow remains unvalidated. Android emits downloadUnsupported: OPEN_RELEASE_GAP.

Acceptance: AT-M08; AT-M09; AT-M10. Classification: rationale. Module: native navigation/permissions/transfers.

Remaining action: Native engineering resolves supported Android authenticated/blob download/save/share without credential export; device QA validates actual HTTP/blob transfers, progress, cancellation and sharing on both platforms. Owner: native engineers + product owner + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-017

- Validate ordinary HTTP and blob/decrypted media separately.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: iOS WKDownload uses browser context/private sanitized destinations/explicit anchored share; actual HTTP/blob paths untested. Android emits downloadUnsupported: OPEN_RELEASE_GAP. Download byte-progress UI not present at review time.

Acceptance: AT-M08; AT-M09; AT-M10. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Native engineering resolves supported Android authenticated/blob download/save/share without credential export; implement progress if absent, then validate both platforms. Owner: native engineers + product owner + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-018

- Use browser-native context where supported. A blob URL is not a normal network URL.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: iOS WKDownload uses browser context/private sanitized destinations/explicit anchored share; actual HTTP/blob paths untested. Android emits downloadUnsupported: OPEN_RELEASE_GAP. Download byte-progress UI not present at review time.

Acceptance: AT-M08; AT-M09; AT-M10. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Native engineering resolves supported Android authenticated/blob download/save/share without credential export; implement progress if absent, then validate both platforms. Owner: native engineers + product owner + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-019

- Do not export a global cookie jar or session credentials to make downloads work.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract inspection

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift; packages/session_contract/pigeons/session_api.dart

Evidence: No global cookie/session credential export; Android download disabled instead of unsafe extraction. iOS uses WKDownload browser context.

Acceptance: AT-S05; AT-M08. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Complete scoped file/permission/TLS/deep-link device cases without weakening production policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-020

- Provide progress, cancellation, sanitized filenames, safe destinations, disk-full handling, and cleanup.

**Implementation:** PARTIAL · **Validation:** PASS

Scope: Implemented iOS file/progress ownership helpers and shared event tests; full download/media clause remains incomplete

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: WKDownload progress, private bounded staging, filename validation, cancellation and per-transfer token implemented; same-view stale progress rejection helpers pass. Flutter determinate/indeterminate progress added. Android authenticated/blob download remains OPEN_RELEASE_GAP.

Acceptance: AT-M08; AT-M09; AT-M10. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Resolve supported Android context-preserving download route without credential export or arbitrary scripting; execute actual-service and physical destination/disk-pressure cases. Owner: native engineers + product owner + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-021

- Export via explicit system save/share action.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: iOS WKDownload uses browser context/private sanitized destinations/explicit anchored share; actual HTTP/blob paths untested. Android emits downloadUnsupported: OPEN_RELEASE_GAP. Download byte-progress UI not present at review time.

Acceptance: AT-M08; AT-M09; AT-M10. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Native engineering resolves supported Android authenticated/blob download/save/share without credential export; implement progress if absent, then validate both platforms. Owner: native engineers + product owner + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-022

- Explain that profile deletion cannot remove copies already exported to Photos, Files, or another app.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: UI copy inspection

Source: apps/mobile/lib/features/accounts/account_screens.dart; apps/mobile/lib/features/help/help_screen.dart

Evidence: Local deletion copy explicitly excludes files already exported to Photos/Files/other apps.

Acceptance: AT-M10. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Complete scoped file/permission/TLS/deep-link device cases without weakening production policy. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-023

- Anchor iPad share/popover UI and test focus/resizing.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift

Evidence: System iPad share popover anchor is configured in source; physical focus/resizing/share destination behavior not executed.

Acceptance: AT-M10; AT-M13. Classification: required. Module: native navigation/permissions/transfers.

Remaining action: Run iPad anchored share/focus/rotation/resizing with approved synthetic files. Owner: engineering + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

### REQ-12-024

For voice notes/camera/calls, validate actual site behavior, capture origin, routing, Bluetooth, interruption, rotation, backgrounding, lock, and switching before enabling the promise. Do not add fake audio or improper foreground/background services to keep sessions alive.

**Implementation:** EXCLUDED · **Validation:** NOT_APPLICABLE_WITH_REASON

Scope: conditional unsupported feature withheld; not a passed capability test

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NavigationPolicy.kt; packages/session_engine/ios/session_engine/Sources/session_engine/WorkspaceURLPolicy.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Voice notes/camera/calls are gated off with explicit capability disclosure. No fake audio or background keepalive services.

Acceptance: AT-M06; AT-M07. Classification: conditional. Module: native navigation/permissions/transfers.

Remaining action: Only implement/enable after separate actual-service/device capture/routing/interruption evidence exists. Owner: native engineers + device QA. Dependencies: Trusted canonical main origin; original profile/view ownership; OS picker/provider support.

## 13. Privacy backup diagnostics and app lock

### REQ-13-001

Write and implement a threat model covering wrong-account display, cross-profile storage, stale file callbacks, malicious frames, local access, logs, interrupted cleanup, restored sessions, and dependency changes.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: security design/source review plus affected regression tests

Source: docs/THREAT_MODEL.md; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; packages/session_contract/lib/src/coordinator.dart

Evidence: Threat model has controls and residual risks; independent native review fixed lock/callback/staging/provenance defects.

Acceptance: AT-S01; AT-S03; AT-S05; AT-S07; AT-D12. Classification: required. Module: native security + privacy UI.

Remaining action: Run full physical privacy and restore matrix; keep release disclosures truthful. Owner: security/native engineers + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication; physical-device verification remains separate.

### REQ-13-002

Before enabling app lock, check authentication availability and supported device-credential fallback. If setup is absent, explain the required device setup. If enabled authentication is canceled, unavailable, locked out, or affected by enrollment changes, keep content covered and provide supported recovery. Never silently disable an enabled lock.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: helper/coordinator races; no physical biometric certification

Source: docs/THREAT_MODEL.md; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; packages/session_engine/ios/session_engine/Sources/session_engine/WindowPrivacyCover.swift; apps/mobile/lib/features/privacy/

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md auth epochs and fail-closed lock; coordinator late-auth tests/native lock state helpers pass. Physical enrollment/lockout/fallback not executed.

Acceptance: AT-S02; AT-S03. Classification: required. Module: native security + privacy UI.

Remaining action: Run full physical privacy and restore matrix; keep release disclosures truthful. Owner: security/native engineers + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication; physical-device verification remains separate.

### REQ-13-003

Apply the native opaque cover before background snapshots and before revealing content on return. Distinguish OS picker interruptions from genuine app return so lock dialogs cannot trap users or misroute callbacks. Do not claim universal screenshot prevention.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source plus shell concealment test

Source: docs/THREAT_MODEL.md; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; packages/session_engine/ios/session_engine/Sources/session_engine/WindowPrivacyCover.swift; apps/mobile/lib/features/privacy/

Evidence: Native view and full-window cover; Android FLAG_SECURE; OS-picker interruptions tracked; global Flutter lock hides labels/settings. Snapshot timing needs hardware.

Acceptance: AT-S01; AT-M02. Classification: required. Module: native security + privacy UI.

Remaining action: Capture controlled physical app-switcher/background evidence without account/QR content. Owner: security/native engineers + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication; physical-device verification remains separate.

### REQ-13-004

Use Keychain/Keystore only for actual app-owned secrets. Do not claim they automatically encrypt the entire browser database with an app-owned key or create ten independent user identities. Do not claim the host app is cryptographically unable to observe rendered content.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/security claim review and provenance helper tests

Source: packages/session_engine/ios/session_engine/Sources/session_engine/InstallationBinding.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; docs/THREAT_MODEL.md

Evidence: Keychain device-only secret/Android nonexportable HMAC bind installation; docs deny browser-database encryption or cryptographic host-isolation claims.

Acceptance: AT-D12. Classification: required. Module: native security + privacy UI.

Remaining action: Run full physical privacy and restore matrix; keep release disclosures truthful. Owner: security/native engineers + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication; physical-device verification remains separate.

### REQ-13-005

Do not implement session backup/sync. Configure supported exclusions for sensitive app-owned records and temporary files. On Android cover legacy backup rules and current cloud/device-transfer rules; do not rely on `allowBackup=false` alone. Verify real provider storage/restore behavior without editing live database files.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/ios/session_engine/Sources/session_engine/InstallationBinding.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; apps/mobile/android/app/src/main/res/xml/

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md backup exclusions/provenance/missing/orphan source and helper tests. Actual provider backup/device transfer/reinstall not validated.

Acceptance: AT-D12; AT-I12. Classification: excluded. Module: native security + privacy UI.

Remaining action: Physical QA performs supported backup/restore/reinstall/transfer plus ordinary upgrade matrix; never edit live browser data. Owner: engineering + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication.

### REQ-13-006

Test registry-present/store-absent, store-present/registry-absent, restore, reinstall, transfer, and ordinary-upgrade cases. Quarantine unknown restored access; require relinking where trust cannot be established. Do not clear legitimate sessions on every upgrade.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/ios/session_engine/Sources/session_engine/InstallationBinding.swift; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt; packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift; apps/mobile/android/app/src/main/res/xml/

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md backup exclusions/provenance/missing/orphan source and helper tests. Actual provider backup/device transfer/reinstall not validated.

Acceptance: AT-D12; AT-I12. Classification: required. Module: native security + privacy UI.

Remaining action: Physical QA performs supported backup/restore/reinstall/transfer plus ordinary upgrade matrix; never edit live browser data. Owner: engineering + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication.

### REQ-13-007

Default to on-device diagnostics with user-controlled export. Allowlist app/build, OS/provider version, capability flags, error class, operation timing, and coarse capacity. Exclude aliases, phone numbers, contacts, message text, page titles, full URLs/query strings, QR/codes, file names/paths, DOM snapshots, and memory dumps.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source payload allowlist review

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; apps/mobile/lib/features/privacy/privacy_screen.dart

Evidence: Explicit system diagnostic export allowlists technical fields; no alias/URL/page/file/session content; no automatic remote reporting.

Acceptance: AT-S07. Classification: required. Module: native security + privacy UI.

Remaining action: Inject synthetic sensitive markers then inspect actual diagnostic exports and candidate allowed logs. Owner: security/native engineers + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication.

### REQ-13-008

Disable session replay, automatic screenshots, verbose native inspection, and sensitive crash attachments. Audit actual SDK payloads before adding remote reporting. Search logs and generated artifacts for synthetic sensitive markers.

**Implementation:** PARTIAL · **Validation:** PASS

Scope: Actual diagnostics payload unit tests and bounded production artifact scan; complete signed-candidate runtime log matrix pending

Source: scripts/verify_production.py; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Android14 helper tests include captured ACTION_SEND allowlist excluding seeded markers; iOS27 macOS helpers and 29 hosted native tests include actual NativeDiagnostics payload marker tests. Final unsigned artifacts inspected by scripts/verify_release_artifacts.py. See docs/RELEASE_REVIEW.md and platform evidence.

Acceptance: AT-S07; AT-S08. Classification: required. Module: native security + privacy UI.

Remaining action: Repeat synthetic excluded-field injection and process-scoped logs on final signed physical candidates; no real account/session values in evidence. Owner: engineering + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication.

### REQ-13-009

Prepare truthful privacy disclosures from implemented data flows, including embedded website traffic. A local shell without a backend is not automatically a no-data-collected application. Record recipients, purposes, retention, permission behavior, and store-specific WebView disclosure decisions.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: draft disclosure review, not legal/store approval

Source: docs/RELEASE_AND_SUPPORT.md; docs/THREAT_MODEL.md

Evidence: Draft accounts for local metadata/browser stores/embedded website traffic/explicit sharing/export retention. No no-data-collected claim.

Acceptance: AT-S11. Classification: required. Module: native security + privacy UI.

Remaining action: Release/legal owner supplies operator/contact/regions/service recipients and completes store-specific privacy forms. Owner: security/native engineers + device QA. Dependencies: Native cover before lifecycle transitions; installation provenance; OS authentication.

## 14. Test harness evidence and performance

### REQ-14-001

Build a controlled developer-owned HTTPS same-origin harness available only to development/instrumentation builds. Use distinct synthetic profile markers against the same scheme, host, and port so separate domains cannot conceal accidental sharing.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: real synthetic native storage fixtures on declared emulator/simulator

Source: tests/profile_harness/; packages/session_engine/android/src/androidTest/; packages/session_engine/ios/NativeTests/HarnessApp/

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md hosted identical HTTPS origin across10 native stores; test app CA scoped outside production.

Acceptance: AT-I01; AT-I02; AT-I03. Classification: required. Module: QA/harness/device evidence.

Remaining action: Run the linked complete acceptance case on declared physical devices; preserve the narrower automated evidence. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time; physical-device verification remains separate.

### REQ-14-002

Exercise cookies with server-verified HttpOnly behavior, localStorage, IndexedDB, Cache Storage, service-worker registration/update/deletion, HTTP cache, WebSockets, supported messaging channels/workers, and file callbacks. Keep test-server state correctly scoped so the harness itself does not leak markers.

**Implementation:** PARTIAL · **Validation:** PASS

Scope: Executed native synthetic six-store isolation, HTTP cache, WSS identity and supported messaging controls; full native file-callback/worker-update matrix incomplete

Source: tests/profile_harness/

Evidence: Android36/WebView133 and iOS27 native fixtures pass six storage mechanisms plus same-URL HTTP cache and WSS handshake identity. iOS SharedWorker controls pass; unavailable Android SharedWorker recorded without isolation claim. Fetch file hash probes do not validate system picker/download callbacks.

Acceptance: AT-I01; AT-I02; AT-I03; AT-I04; AT-M03. Classification: required. Module: QA/harness/device evidence.

Remaining action: Device QA completes independent worker-update and native picker/download/permission callback interruption cases; resolve essential Android download source gap first. Owner: engineering + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-003

Use valid test TLS or narrowly documented development-only setup; never weaken production transport security. Harness scripting or simultaneous-view isolation probes must remain test-only and must not change the production contract or live-view budget.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: test transport/source boundary inspection and hosted fixture execution

Source: tests/profile_harness/create_test_certificate.py; packages/session_engine/android/src/androidTest/; packages/session_engine/ios/NativeTests/run-storage-harness.sh

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md dedicated public CA only in test app/disposable simulator, keys outside repo; production scanner passes.

Acceptance: AT-S06; AT-S08. Classification: required. Module: QA/harness/device evidence.

Remaining action: Run the linked complete acceptance case on declared physical devices; preserve the narrower automated evidence. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time; physical-device verification remains separate.

### REQ-14-004

Prove two profiles, then ten. Test middle-profile removal and fresh replacement, normal relaunch, process termination, reboot, migration, renderer failure, storage eviction, and cleanup interruption at every stage.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md ten-store reopen/middle wipe/fresh replacement and Android clean-process pending deletion pass; exhaustive reboot/migration/eviction/renderer/each cleanup stage not executed.

Acceptance: AT-I10; AT-I11; AT-I12; AT-I14; AT-I16; AT-D06; AT-D09. Classification: required. Module: QA/harness/device evidence.

Remaining action: Run bounded fault-injection/native lifecycle scenarios and physical reboot/upgrade matrix; retain each result separately. Owner: engineering + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-005

Use:

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: parent clause; status reflects associated child requirements

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; source/unit/widget/harness subsets executed. Synthetic results are not actual-service results.

Acceptance: N/A — parent test-method list; see REQ-14-006 through REQ-14-010. Classification: rationale. Module: QA/harness/device evidence.

Remaining action: Execute the remaining linked cases and retain redacted per-run metadata. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-006

- Unit tests for capacity, normalization, journal transitions, migrations, selection races, event ownership, and redaction.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: executed focused unit/native helper suites

Source: packages/session_contract/test/; packages/local_registry/test/; packages/session_engine/android/src/test/; packages/session_engine/ios/NativeTests/Tests/

Evidence: 23 coordinator,16 facade,9 Android and21 iOS helper tests cover invariants. Not every migration/fault/redaction case is present.

Acceptance: AT-A04; AT-A05; AT-A07; AT-I08; AT-D13. Classification: required. Module: QA/harness/device evidence.

Remaining action: Add regressions only for remaining required invariant gaps; do not equate unit coverage to full acceptance. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-007

- Widget tests with the fake engine for native shell states and actions.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: Flutter widget tests; no native WebView compatibility claim

Source: apps/mobile/test/shell_test.dart

Evidence: 7 shell widget tests pass with test-only fake engine.

Acceptance: AT-A01; AT-A04; AT-A10; AT-M11; AT-M13; AT-S01. Classification: required. Module: QA/harness/device evidence.

Remaining action: Run the linked complete acceptance case on declared physical devices; preserve the narrower automated evidence. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time; physical-device verification remains separate.

### REQ-14-008

- Real native instrumentation for profile binding/storage/deletion.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: emulator/simulator native fixture only

Source: packages/session_engine/android/src/androidTest/; packages/session_engine/ios/NativeTests/

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md actual native named-profile fixtures pass on declared API36/iOS27 environments.

Acceptance: AT-I01; AT-I02; AT-I03; AT-I16; AT-D04. Classification: required. Module: QA/harness/device evidence.

Remaining action: Repeat physical/minimum/current device/provider matrix; do not claim real linked accounts. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time; physical-device verification remains separate.

### REQ-14-009

- Device integration tests for lifecycle, composition, files, permissions, and privacy.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: tests/device_flows/README.md

Evidence: Device procedure and launch helper prepared; full integrated hardware media/privacy/composition suite unavailable.

Acceptance: AT-M01; AT-M02; AT-M03; AT-M11; AT-S01. Classification: required. Module: QA/harness/device evidence.

Remaining action: Device QA supplies dedicated hardware and records exact integrated procedure results. Owner: engineering + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-010

- Manual procedures for official QR approval and dynamic service behavior when automation is inappropriate.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: manual procedure preparation

Source: tests/device_flows/README.md

Evidence: Authorized QR/recipient/media, redaction, retention and device procedures prepared; no real-service execution claimed.

Acceptance: AT-A08; AT-A09; AT-A11; AT-A12; AT-A13; AT-I06; AT-D08. Classification: required. Module: QA/harness/device evidence.

Remaining action: Authorized account owners execute manual service paths with QA. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-011

A fake engine does not prove native isolation. Ten empty stores do not prove ten linked WhatsApp sessions. A simulator is not a physical device. A configured CI workflow is not a build execution. Source review is not runtime validation.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: evidence labeling audit

Source: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/acceptance.csv

Evidence: Evidence distinguishes synthetic/real service, unit/native, simulator/physical, configured CI/executed commands.

Acceptance: N/A — evidence classification rule for all70 acceptance cases. Classification: required. Module: QA/harness/device evidence.

Remaining action: Retain these distinctions in final report and all acceptance dispositions. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-012

After the applicable service-test gate, validate real pairing using authorized test accounts and specifically consenting recipients with fictional messages/media. Do not send messages merely because arbitrary contacts are visible. Keep QR values, credentials, real conversations, and account identifiers out of stored evidence.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: No authorized test accounts/primary phones/consenting recipients supplied; no service sends performed.

Acceptance: AT-A08; AT-I06; AT-M01; AT-M08. Classification: external-dependency. Module: QA/harness/device evidence.

Remaining action: Product/account owners supply test basis and consenting recipients; QA executes fictional text/photo/document service matrix. Owner: product owner + authorized account owners + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-013

For every run record test ID, requirement, commit/build, device, OS/provider, synthetic-versus-service context, procedure, expected result, actual result, date/time, evidence path, runner, and defect/blocker. Preserve redacted evidence and exact commands.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: complete clause not yet verified; see evidence for executed subset

Source: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/acceptance.csv

Evidence: Actual commands/device/OS/provider/results and raw evidence exist. Build hashes, per-run IDs and final metadata require root ledger reconciliation.

Acceptance: N/A — run metadata requirement for all70 acceptance cases. Classification: required. Module: QA/harness/device evidence.

Remaining action: Add final build hashes/run timestamps/test IDs and redacted evidence pointers; preserve failures alongside reruns. Owner: engineering + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-014

Run the full acceptance catalog below. Expand it only for discovered requirement-related risks. Do not delete, skip, or reclassify a failing required test to manufacture completion.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: complete clause not yet verified; see evidence for executed subset

Source: docs/acceptance.csv

Evidence: All70 cases preserved; broad catalog is not fully executed.

Acceptance: AT-A01..AT-A14; AT-I01..AT-I16; AT-D01..AT-D14; AT-M01..AT-M14; AT-S01..AT-S12. Classification: required. Module: QA/harness/device evidence.

Remaining action: Complete every case disposition with narrow evidence, missing prerequisite and owner; never mark skipped cases PASS. Owner: engineering + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-015

Run a seven-day feasibility retention check and a fourteen-day beta soak using actual elapsed time. Keep primary accounts active where needed and test intentional remote revocation separately. Record start/end timestamps. Until elapsed evidence exists, mark pending and continue other work. Do not simulate days, use long blocking sleeps, or schedule recurring automation without authorization.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** PENDING_ELAPSED_TIME

Scope: external prerequisite unavailable; no success inferred

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: No elapsed7-day/14-day account runs started.

Acceptance: AT-I15. Classification: external-dependency. Module: QA/harness/device evidence.

Remaining action: After authorized test accounts/devices available, record start and actual day7/day14 observations without simulated time. Owner: retention QA + authorized account owners. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-016

Measure on declared baseline devices:

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: parent clause; status reflects associated child requirements

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: Declared baseline physical devices/network and complete sample/performance/resource evidence unavailable; timings are provisional targets.

Acceptance: AT-I07; AT-M11. Classification: rationale. Module: QA/harness/device evidence.

Remaining action: QA measures cold/warm p95 startup/selector/cover/website and settled host+web resources against single-profile baseline; record samples/network/thermal state. Owner: performance/device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-017

- Native selector response: provisional p95 below 150 ms.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: external prerequisite unavailable; no success inferred

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: Declared baseline physical devices/network and complete sample/performance/resource evidence unavailable; timings are provisional targets.

Acceptance: AT-I07; AT-M11. Classification: external-dependency. Module: QA/harness/device evidence.

Remaining action: QA measures cold/warm p95 startup/selector/cover/website and settled host+web resources against single-profile baseline; record samples/network/thermal state. Owner: performance/device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-018

- Usable local shell startup: provisional p95 below 2 seconds, excluding biometric response/network.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: external prerequisite unavailable; no success inferred

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: Declared baseline physical devices/network and complete sample/performance/resource evidence unavailable; timings are provisional targets.

Acceptance: AT-I07; AT-M11. Classification: external-dependency. Module: QA/harness/device evidence.

Remaining action: QA measures cold/warm p95 startup/selector/cover/website and settled host+web resources against single-profile baseline; record samples/network/thermal state. Owner: performance/device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-019

- Covered correct target context after selection: provisional p95 below 300 ms.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: external prerequisite unavailable; no success inferred

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: Declared baseline physical devices/network and complete sample/performance/resource evidence unavailable; timings are provisional targets.

Acceptance: AT-I07; AT-M11. Classification: external-dependency. Module: QA/harness/device evidence.

Remaining action: QA measures cold/warm p95 startup/selector/cover/website and settled host+web resources against single-profile baseline; record samples/network/thermal state. Owner: performance/device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-020

- Website usable: provisional p95 below 5 seconds on a defined normal network, recorded separately and rebaselined after feasibility.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: external prerequisite unavailable; no success inferred

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: Declared baseline physical devices/network and complete sample/performance/resource evidence unavailable; timings are provisional targets.

Acceptance: AT-I07; AT-M11. Classification: external-dependency. Module: QA/harness/device evidence.

Remaining action: QA measures cold/warm p95 startup/selector/cover/website and settled host+web resources against single-profile baseline; record samples/network/thermal state. Owner: performance/device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-021

- One live production WebView.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source, coordinator invariants and single-view fixture

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: One active native engine view;23 coordinator tests including200 seeded switches; hosted iOS storage uses one view.

Acceptance: AT-I07. Classification: required. Module: QA/harness/device evidence.

Remaining action: Confirm live instance count in integrated/native randomized resource run. Owner: QA + native engineers. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-022

- 200 randomized switches across ten profiles without unrecoverable failure.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: Seeded native synthetic selection stress on the recorded emulator/simulator, separate from physical/service performance

Source: packages/session_contract/test/randomized_switches_test.dart; packages/session_engine/android/src/androidTest; packages/session_engine/ios/NativeTests/HarnessApp/main.swift

Evidence: Android36/WebView133 and iOS27 each completed 200 seeded selections across ten profiles with six-store verification. iOS631 assertions and max one attached owned WebView pass. Exact sequences, timings and app-only resource samples are in platform evidence.

Acceptance: AT-I07. Classification: required. Module: QA/harness/device evidence.

Remaining action: Physical QA repeats the scenario and measures total host plus web-content trends; synthetic navigation timings do not prove selector/startup/service budgets. Owner: engineering + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-023

- Settled host plus web-content resource trends after all profiles have been visited.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: external prerequisite unavailable; no success inferred

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: Android 200-switch app-process PSS samples and iOS app-process RSS samples have explicitly limited scope; they exclude WebContent processes and do not establish physical baseline or leak freedom.

Acceptance: AT-I07; AT-M11. Classification: external-dependency. Module: QA/harness/device evidence.

Remaining action: Performance QA measures settled host plus WebContent resources against one-profile baseline on declared physical devices, along with thermal/network state and specific p95 UI intervals. Owner: performance/device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-024

- Zero observed account-mismatch frames in controlled captured test scenarios.

**Implementation:** PARTIAL · **Validation:** BLOCKED_HARDWARE

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_contract/lib/src/coordinator.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Ownership/cover regressions pass; zero account-mismatch frame claim requires controlled native capture, which is not executed.

Acceptance: AT-I07; AT-S03. Classification: required. Module: QA/harness/device evidence.

Remaining action: Record synthetic controlled captured switching/lock scenarios on device and inspect alias/store frames. Owner: engineering + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-025

- Zero synthetic sensitive markers in allowed diagnostic paths.

**Implementation:** PARTIAL · **Validation:** PASS

Scope: Actual diagnostics payload unit tests and bounded production artifact scan; complete signed-candidate runtime log matrix pending

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; scripts/verify_production.py

Evidence: Android14 helper tests include captured ACTION_SEND allowlist excluding seeded markers; iOS27 macOS helpers and 29 hosted native tests include actual NativeDiagnostics payload marker tests. Final unsigned artifacts inspected by scripts/verify_release_artifacts.py. See docs/RELEASE_REVIEW.md and platform evidence.

Acceptance: AT-S07. Classification: required. Module: QA/harness/device evidence.

Remaining action: Repeat synthetic excluded-field injection and process-scoped logs on final signed physical candidates; no real account/session values in evidence. Owner: engineering + device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

### REQ-14-026

These are proposed targets, not measured achievements. Record sample sizes, device/network conditions, cold/warm paths, memory pressure, thermal behavior, and comparison with a single-profile baseline. Do not invent universal memory or battery limits. Propose justified target changes explicitly; never weaken a privacy/isolation invariant.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: external prerequisite unavailable; no success inferred

Source: tests/profile_harness/; packages/session_engine/ios/NativeTests/; packages/session_engine/android/src/androidTest/; tests/device_flows/README.md

Evidence: Declared baseline physical devices/network and complete sample/performance/resource evidence unavailable; timings are provisional targets.

Acceptance: AT-I07; AT-M11. Classification: external-dependency. Module: QA/harness/device evidence.

Remaining action: QA measures cold/warm p95 startup/selector/cover/website and settled host+web resources against single-profile baseline; record samples/network/thermal state. Owner: performance/device QA. Dependencies: Dedicated synthetic fixtures; approved physical hardware/accounts; actual elapsed time.

## 16. Execute all six delivery phases

### REQ-16-001

Use phases 0 through 5. Work may overlap where dependencies permit; do not use phase boundaries as automatic stopping points.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: implementation process audit

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Work across phases proceeds by dependencies; unsupported media/service gates not hidden by phase labels.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Continue independent local work; leave only concrete remaining dependencies. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-002

- Inventory the environment and verify primary sources.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-003

- Establish service/test/distribution evidence status.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-004

- Build minimal real native containers and the synthetic harness.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: native development builds and actual synthetic fixtures

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift; tests/profile_harness/

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md real containers+HTTPS fixture implemented and executed.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Finish executable local checks; leave every external gate with its owner and exact prerequisite. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-005

- Prove two then ten isolated stores, binding, removal, restart recovery, and phone layout where executable.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: phase activity spans implemented local work and outstanding validation

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md two/ten-store coverage, native middle removal/reopen and widget phone layout pass; complete process/phone service matrix remains incomplete.

Acceptance: AT-I01; AT-I02; AT-I03; AT-I16; AT-M11. Classification: required. Module: phase integration.

Remaining action: Finish executable local checks; leave every external gate with its owner and exact prerequisite. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-006

- Measure initial resources and begin actual retention where authorized/available.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: external prerequisite unavailable; no success inferred

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Physical resource baseline and authorized elapsed account retention unavailable.

Acceptance: AT-I07; AT-I15. Classification: external-dependency. Module: phase integration.

Remaining action: QA supplies baseline devices/accounts; measure resources and start actual dated retention. Owner: performance/retention QA. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-007

- Produce a dated feasibility decision distinguishing pass, failure, and missing evidence.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-008

- Repair proven architecture failures before dependent feature expansion.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: defect/fix/test history

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Real native defects (cold iOS inventory, lock epochs, callback cleanup, deferred journal regressions) investigated/fixed with affected tests; original failures retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Confirm final integrated smoke after latest fixes; never suppress unresolved invariant failure. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-009

- Finalize UX, domain invariants, typed commands/events, native lifecycle boundaries, and registry/journal ownership.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-010

- Implement real plugin registration, dependency wiring, migrations, flavors, fake engine, and diagnostic policy.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-011

- Build all screen states and account management foundations.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-012

- Establish formatting, static checks, unit/native test entry points, and CI.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-013

- Confirm no production path depends on a mock or test origin.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-014

- Finish allocation/capacity, unique aliases, ordering, real profile binding, and official pairing guidance.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-015

- Implement safe switching, cover timing, authentication observations, restoration, and bounded recovery.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-016

- Finish relink, remove-one/remove-all, tombstones, compensation, deferred Android cleanup, and startup reconciliation.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-017

- Verify profile isolation, lifecycle, and deletion cases.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: phase activity spans implemented local work and outstanding validation

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md broad synthetic pass; physical/update/fault-stage scenarios remain incomplete.

Acceptance: AT-I01; AT-I02; AT-I03; AT-D04; AT-D06; AT-D12. Classification: required. Module: phase integration.

Remaining action: Finish per-case evidence disposition and remaining native/hardware procedures. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-018

- Claim ten-account service support only after actual corresponding evidence exists.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: claim boundary audit

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: No verified ten linked account claim; ten synthetic stores explicitly distinguished.

Acceptance: N/A — process/documentation clause. Classification: conditional. Module: phase integration.

Remaining action: Only change service-support claim after authorized ten-account evidence. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-019

- Implement validated photo/document upload/download/save/share paths.

**Implementation:** PARTIAL · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: complete clause not yet verified; see evidence for executed subset

Source: packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift; packages/session_engine/ios/session_engine/Sources/session_engine/TransferFiles.swift

Evidence: Upload ownership and iOS native download implementation exist; actual service flows untested; Android essential download OPEN_RELEASE_GAP.

Acceptance: AT-M01; AT-M08; AT-M10. Classification: required. Module: phase integration.

Remaining action: Native engineer resolves Android safe download route; QA validates actual photo/document upload/download/save/share. Owner: engineering + device QA. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-020

- Finish scoped permission/callback handling, app lock, background covers, navigation, and popup behavior.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: phase activity spans implemented local work and outstanding validation

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Native lock/navigation/privacy and file callback ownership implemented with race/helper tests; real picker/background/security device matrix incomplete.

Acceptance: AT-M02; AT-M03; AT-S01; AT-S02; AT-S03; AT-S04. Classification: required. Module: phase integration.

Remaining action: Finish executable local checks; leave every external gate with its owner and exact prerequisite. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-021

- Complete keyboard, tablet, larger-text, screen-reader, and error-state usability.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_HARDWARE

Scope: external prerequisite unavailable; no success inferred

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Widget phone/tablet/large-text shell tests pass; real screen-reader/keyboard/composer/device resizing unavailable.

Acceptance: AT-M11; AT-M12; AT-M13; AT-M14. Classification: external-dependency. Module: phase integration.

Remaining action: Device QA runs declared hardware accessibility/composition matrix with authorized service flows. Owner: device/accessibility QA. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-022

- Add help, compatibility information, and safe diagnostic export.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-023

- Enable conditional media features only after their capability tests.

**Implementation:** EXCLUDED · **Validation:** NOT_APPLICABLE_WITH_REASON

Scope: unsupported conditional features withheld

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Capture/voice/calls gated off, with explicit unsupported capability text.

Acceptance: N/A — process/documentation clause. Classification: conditional. Module: phase integration.

Remaining action: Enable only after actual capability test evidence; do not emulate/background-keepalive. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-024

- Draft privacy disclosures from actual implementation.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-025

- Execute applicable acceptance cases across available devices/providers.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: phase activity spans implemented local work and outstanding validation

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md available simulator/emulator/native/widget subsets executed; all70 full device cases not complete.

Acceptance: AT-A01..AT-S12. Classification: required. Module: phase integration.

Remaining action: Finalize disposition table and remaining physical/service actions. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-026

- Fix race, cleanup, crash, storage, security, resource, and media defects.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: phase activity spans implemented local work and outstanding validation

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md independent review fixed concrete auth, picker, tombstone, staging and startup defects; essential Android media gap remains.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Fix new actionable regressions and required media gap; do not mark phase complete with open high-severity issues. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-027

- Run repeated switches, restore/reinstall/migration, log redaction, and production-build checks.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: phase activity spans implemented local work and outstanding validation

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: 200 coordinator switches and helper restore/reopen tests pass; actual release candidate runtime log/marker/migration/native resource checks remain incomplete.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Execute remaining candidate and native resource/log checks; label narrow tests separately. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-028

- Collect elapsed beta evidence rather than forecasting it.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** PENDING_ELAPSED_TIME

Scope: external prerequisite unavailable; no success inferred

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Elapsed beta retention has not occurred.

Acceptance: AT-I15. Classification: external-dependency. Module: phase integration.

Remaining action: After test gate is available, collect dated7-/14-day observations. Owner: retention QA. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-029

- Resolve every critical/high privacy, wrong-account, isolation, and data-loss defect.

**Implementation:** PARTIAL · **Validation:** NOT_RUN

Scope: phase activity spans implemented local work and outstanding validation

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Independent native review findings fixed and targeted tests passed; integrated final review/known essential download gap remains.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Complete final review; unresolved critical/high wrong-account/privacy/data-loss defects prohibit release. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-030

- Freeze a candidate with known limitations and actual coverage.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: Local candidate, evidence reconciliation and explicit dependency handover; no release or full acceptance claim

Source: docs/REPORT.md; docs/RESUME.md; docs/acceptance.csv; docs/requirements.csv; artifacts/profile-desk-0.1.0-local/manifest.json

Evidence: Final unsigned Android/iOS builds, strengthened artifact checks, matching symbols and exact artifact/source hashes are preserved. All374 clauses and70 acceptance scenarios retain source text with current dispositions. Report records failures, open source gap and remaining owners/actions.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Native engineering resolves Android download gap; account/device QA supplies approved service/physical/elapsed evidence; release owner resolves distribution/signing inputs. Follow the consolidated handover; do not infer full acceptance from local completion. Owner: integration lead; remaining actions assigned in docs/REPORT.md. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-031

- Recheck current SDK/target API, developer-account, branding, privacy, and review requirements.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Final signing/operator/branding/privacy/developer-account and submission date inputs absent.

Acceptance: AT-S11; AT-S12. Classification: external-dependency. Module: phase integration.

Remaining action: Release owner rechecks current store guidance and provides final identity/signing/distribution basis. Owner: product/release owner. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-032

- Produce reproducible builds, release configuration, symbols/mappings, versioned artifacts, and dependency inventory.

**Implementation:** PARTIAL · **Validation:** PASS

Scope: Executed local unsigned builds with pinned direct dependencies/Dart locks, inventory and symbol packages; no bit-for-bit/native-transitive reproducibility claim

Source: scripts/package_local_candidate.py; scripts/build_android.sh; scripts/build_ios.sh; docs/DEPENDENCIES.md

Evidence: Optimized production APK and unsigned iOS device build pass. Official Gradle9.3.1 checksum pinned; repository app/session_engine module dependency locks enforce resolved configurations excluding pinned-SDK ABI-selected io.flutter coordinates. Separate QA fixture lock build passes.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Complete signed release configuration, buildscript/composite dependency verification and advisory review; rerun required signed candidate checks. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-033

- Prepare support/privacy copy, listings, screenshots using fictional or authorized data, and review instructions.

**Implementation:** PARTIAL · **Validation:** PASS

Scope: Draft listing/support/privacy text, disclosure worksheet, reviewer procedure and five fictional shell previews; not final store assets or approved declarations

Source: docs/STORE_REVIEW_PACKAGE.md; docs/RELEASE_AND_SUPPORT.md; docs/release-assets/README.md; tests/release_assets/capture_shell.dart

Evidence: Five actual Flutter shell widget previews prepared with fictional profile labels and visible draft banners. Store package separates native data facts, embedded website unknowns, pending owner declarations and real reviewer requirements.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Release owner supplies final identity/contact/URLs and reviewed disclosures; QA captures real signed device/service behavior and provides an authorized reproducible review path before submission. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-034

- Explain the real companion/primary-app requirement and provide a workable review path.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-035

- Do not disguise synthetic demo mode as actual integration or depend on an unusable expiring QR.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-036

- Prepare staged rollout, recovery/migration, incident, upstream compatibility, and maintenance procedures.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: local implementation/documentation and focused tests only

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: See row-specific feature clauses and native/source evidence; this phase activity does not imply full service or release completion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Reconcile final artifacts/feature evidence; complete outstanding actual-device/service cases. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-037

- Submit or distribute only when the required evidence and existing authorization support that action.

**Implementation:** EXTERNAL_DEPENDENCY · **Validation:** BLOCKED_SERVICE_ACCESS

Scope: external prerequisite unavailable; no success inferred

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: No distribution or submission authorized/performed; candidate technical evidence remains incomplete.

Acceptance: AT-S11; AT-S12. Classification: external-dependency. Module: phase integration.

Remaining action: Only release owner may authorize selected distribution after evidence/signing/review requirements resolved. Owner: product/release owner. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

### REQ-16-038

An unavailable device or external permission keeps the corresponding gate pending while independent source, harness, build configuration, tests, and preparation continue. A documented definitive incompatibility must remain a product decision, not an excuse to bypass restrictions or quietly substitute another product.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: external blocker handling audit

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/acceptance.csv; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Native/source/test work proceeds with explicit hardware/service/retention gaps. Unsupported Android download not substituted by credential extraction.

Acceptance: N/A — process/documentation clause. Classification: required. Module: phase integration.

Remaining action: Keep exact blockers and owners visible; do not bypass restrictions or silently substitute a product. Owner: integration lead + QA/release owners. Dependencies: Earlier invariants; provider support; service/hardware/release evidence.

## 17. Build CI and release configuration

### REQ-17-001

Pin tested toolchains and dependencies; include lockfiles and an update procedure. Use the repository’s CI provider where one exists. Keep signing credentials in approved secret storage. Do not print or commit certificates, private keys, provisioning secrets, API keys, or account exports.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local build/script/configuration inspection; remote CI not executed

Source: apps/mobile/pubspec.lock; packages/*/pubspec.lock; docs/DEPENDENCIES.md; .github/workflows/

Evidence: Resolved locks/toolchains pinned; native versions recorded; CI actions pinned by SHA; no signing secrets checked in.

Acceptance: N/A — process/documentation clause. Classification: required. Module: build/CI/release.

Remaining action: Run dependency/license/advisory review before release; use approved external secret storage for signing. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-002

Provide scripts for bootstrap, formatting checks, analysis, unit/widget tests, bridge generation checks, relevant native tests, harness startup, and supported Android/iOS builds.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local build/script/configuration inspection; remote CI not executed

Source: scripts/; tests/profile_harness/README.md; packages/session_engine/android/run_instrumentation.sh; packages/session_engine/ios/NativeTests/run-storage-harness.sh

Evidence: Executable setup/check/build/bridge/native fixture scripts and exact commands exist; device flow procedures/helper included.

Acceptance: N/A — process/documentation clause. Classification: required. Module: build/CI/release.

Remaining action: Run candidate variants, retain provenance/symbols and repeat smoke checks; configure remote runner separately. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-003

Execute commands appropriate to the actual repository, including `flutter pub get`, formatting verification, `flutter analyze`, `flutter test`, native Gradle/Xcode checks, and Flutter platform builds where available. Capture the real output and exit status. Generate exact alternative-machine commands when a platform toolchain is unavailable.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: local command execution with reported results

Source: scripts/; .github/workflows/; docs/DEPENDENCIES.md; docs/RELEASE_AND_SUPPORT.md

Evidence: Local pub/format/analyze/widget/unit/native compile+instrumentation and integrated development builds actually executed; each platform evidence file states exact scope.

Acceptance: N/A — process/documentation clause. Classification: conditional. Module: build/CI/release.

Remaining action: Record final root consolidated check/build logs after current changes; do not infer remote CI execution. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-004

A Linux host can still implement and review Swift source and prepare macOS CI, but cannot claim an Xcode build ran. An unsigned iOS build, signed archive, simulator build, Android debug APK, and store-ready artifact must be labeled accurately.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: artifact naming audit

Source: scripts/; .github/workflows/; docs/DEPENDENCIES.md; docs/RELEASE_AND_SUPPORT.md

Evidence: macOS/Xcode available. Simulator/debug APK/unsigned device/release artifacts distinguished; no signed-store-ready assertion.

Acceptance: N/A — process/documentation clause. Classification: required. Module: build/CI/release.

Remaining action: Retain exact artifact variant/signing status in final report. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-005

CI should validate changed code and the meaningful affected suites. Use native runners for native evidence. Required tests must not be disabled to pass CI. Fix compilation warnings/errors that indicate lifecycle, availability, or type-contract defects; do not suppress them without a justified decision.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: workflow source review; local relevant suites executed, remote CI not run

Source: scripts/; .github/workflows/; docs/DEPENDENCIES.md; docs/RELEASE_AND_SUPPORT.md

Evidence: .github/workflows checks source/tests/bridge drift/Android and provisioned Apple runner; no remote execution claimed.

Acceptance: N/A — process/documentation clause. Classification: required. Module: build/CI/release.

Remaining action: Configure intended repository/runner before expecting remote CI status; do not disable required failures. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-006

Production builds must exclude:

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: parent clause; status reflects associated child requirements

Source: scripts/verify_production.py; packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Production excludes harness URLs/fake injection/general JS export/inspection/TLS bypass/replay/automatic screenshots/test accounts. Source exclusion script passes.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: rationale. Module: build/CI/release.

Remaining action: Inspect actual final production artifact and run candidate smoke; static scan is not runtime proof. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-007

- Test harness origins and debug menus.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract/manifest exclusion inspection only

Source: scripts/verify_production.py; packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Production excludes harness URLs/fake injection/general JS export/inspection/TLS bypass/replay/automatic screenshots/test accounts. Source exclusion script passes.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: required. Module: build/CI/release.

Remaining action: Inspect actual final production artifact and run candidate smoke; static scan is not runtime proof. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-008

- Fake session engine injection.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract/manifest exclusion inspection only

Source: scripts/verify_production.py; packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Production excludes harness URLs/fake injection/general JS export/inspection/TLS bypass/replay/automatic screenshots/test accounts. Source exclusion script passes.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: required. Module: build/CI/release.

Remaining action: Inspect actual final production artifact and run candidate smoke; static scan is not runtime proof. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-009

- Generic test JavaScript/data-export surfaces.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract/manifest exclusion inspection only

Source: scripts/verify_production.py; packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Production excludes harness URLs/fake injection/general JS export/inspection/TLS bypass/replay/automatic screenshots/test accounts. Source exclusion script passes.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: required. Module: build/CI/release.

Remaining action: Inspect actual final production artifact and run candidate smoke; static scan is not runtime proof. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-010

- Web inspection/debugging.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract/manifest exclusion inspection only

Source: scripts/verify_production.py; packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Production excludes harness URLs/fake injection/general JS export/inspection/TLS bypass/replay/automatic screenshots/test accounts. Source exclusion script passes.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: required. Module: build/CI/release.

Remaining action: Inspect actual final production artifact and run candidate smoke; static scan is not runtime proof. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-011

- Transport-security bypasses.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract/manifest exclusion inspection only

Source: scripts/verify_production.py; packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Production excludes harness URLs/fake injection/general JS export/inspection/TLS bypass/replay/automatic screenshots/test accounts. Source exclusion script passes.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: required. Module: build/CI/release.

Remaining action: Inspect actual final production artifact and run candidate smoke; static scan is not runtime proof. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-012

- Sensitive logging, session replay, and automatic screenshots.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract/manifest exclusion inspection only

Source: scripts/verify_production.py; packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Production excludes harness URLs/fake injection/general JS export/inspection/TLS bypass/replay/automatic screenshots/test accounts. Source exclusion script passes.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: required. Module: build/CI/release.

Remaining action: Inspect actual final production artifact and run candidate smoke; static scan is not runtime proof. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-013

- Hardcoded test-account material.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: source/contract/manifest exclusion inspection only

Source: scripts/verify_production.py; packages/session_contract/pigeons/session_api.dart; packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt; packages/session_engine/ios/session_engine/Sources/session_engine/SessionEnginePlugin.swift

Evidence: Production excludes harness URLs/fake injection/general JS export/inspection/TLS bypass/replay/automatic screenshots/test accounts. Source exclusion script passes.

Acceptance: AT-S05; AT-S07; AT-S08. Classification: required. Module: build/CI/release.

Remaining action: Inspect actual final production artifact and run candidate smoke; static scan is not runtime proof. Owner: build/release engineer. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

### REQ-17-014

Retain symbols/mappings, build/commit provenance, dependency/license inventory, and safe logs. Run release-candidate smoke tests against the actual built variant.

**Implementation:** PARTIAL · **Validation:** PASS

Scope: Unsigned production artifacts, hashes, native symbols/R8 mapping and local source snapshot; signed iOS candidate runtime remains external

Source: scripts/package_local_candidate.py; scripts/verify_release_artifacts.py; tests/device_flows/smoke_android_release.py

Evidence: Both optimized production builds passed; artifact package preserves APK/device bundle/symbols and exact hashes. Final device signing and full runtime/media/service matrix remain separate.

Acceptance: AT-S07; AT-S08; AT-S12. Classification: required. Module: build/CI/release.

Remaining action: Release owner supplies approved signing; repeat artifact inspection and device smoke on the exact signed distribution candidates. Owner: engineering + device QA. Dependencies: Installed exact toolchains; approved runner/signing inputs for distribution.

## 18. Quality loop completion report and maintenance

### REQ-18-001

For each completed feature, verify both its own behavior and adjacent account/lifecycle/permission boundaries. Use regression tests when they protect a real invariant. Avoid tests that merely duplicate implementation or assert that a mock returns its configured answer.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: executed focused regression suites

Source: packages/session_contract/test/; packages/local_registry/test/; apps/mobile/test/shell_test.dart; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Regression tests target capacity/identity/late callbacks/lock/cleanup/replacement/staging invariants, not merely fake returns.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Complete linked broad device acceptance separately; rerun affected suite after final edits. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-002

Conduct an independent review of native storage binding, startup order, race handling, allocation compensation, deletion, backup, and release configuration. Fix actionable findings, run the necessary affected checks, and update traceability.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: independent source review plus native/coordinator regressions

Source: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Independent native review fixed Android lock-before-auth/callback-finally/journal idempotency and iOS auth/provenance/metadata/staging issues; native affected checks passed.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Record any final findings and rebuild/smoke after latest fixes; review does not replace actual device validation. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-003

Use bounded retries and root-cause investigation. Do not repeatedly run the same failing command without new evidence. Do not add unrelated features or endless testing after the required risks are resolved.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: handover preparation and review evidence

Source: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: Failures investigated with distinct new evidence; iOS legacy scene/cold inventory and retained-cookie clients corrected; Android initial fixture failure preserved rather than deleted.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Do not rerun blindly or expand unrelated scope; investigate newly observed failure before weakening assertion. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-004

Prepare complete handover material:

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-005

- Reproducible local setup and build/run commands.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: handover preparation and review evidence

Source: docs/RELEASE_AND_SUPPORT.md; scripts/

Evidence: Substantive local handover material exists; status/evidence/next action stays scoped to implementation versus external validation.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile with final results and remaining dependencies before final handover. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-006

- Requirements and implementation/test traceability.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Exact prompt source preservation plus full Word paragraph/table/hyperlink coverage; implementation dispositions remain scope-limited

Source: docs/MASTER_IMPLEMENTATION_PLAN.md; docs/DESIGN_DOCUMENT_TRACEABILITY.md; docs/PROMPT_VERIFICATION_CHECKLIST.md; scripts/check_traceability.py

Evidence: Whole-design audit traces337 nonempty Word paragraphs,214 table data rows,52 phase bullets,13 risks,36 source IDs/37 links,374 prompt clauses and70 acceptance cases. Automated checker verifies source identities, paragraph/table coverage and generated checklist freshness.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Keep each disposition tied to actual evidence; update the ledgers and regenerate the prompt checklist when remaining gates are tested. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-007

- Architecture and profile/allocation/deletion decisions.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: handover preparation and review evidence

Source: docs/ARCHITECTURE.md

Evidence: Substantive local handover material exists; status/evidence/next action stays scoped to implementation versus external validation.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile with final results and remaining dependencies before final handover. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-008

- Threat model and permission/backup/privacy analysis.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: handover preparation and review evidence

Source: docs/THREAT_MODEL.md

Evidence: Substantive local handover material exists; status/evidence/next action stays scoped to implementation versus external validation.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile with final results and remaining dependencies before final handover. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-009

- Real device/provider compatibility and supported-feature matrix.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-010

- All 70 acceptance dispositions with evidence.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-011

- Relinking, local removal, remote unlink, and safe recovery guidance.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: handover preparation and review evidence

Source: apps/mobile/lib/features/help/help_screen.dart; docs/RELEASE_AND_SUPPORT.md

Evidence: Substantive local handover material exists; status/evidence/next action stays scoped to implementation versus external validation.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile with final results and remaining dependencies before final handover. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-012

- Release/signing ownership and review package.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: handover preparation and review evidence

Source: docs/RELEASE_AND_SUPPORT.md

Evidence: Substantive local handover material exists; status/evidence/next action stays scoped to implementation versus external validation.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile with final results and remaining dependencies before final handover. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-013

- Maintenance smoke suite for upstream website/OS/provider changes.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: handover preparation and review evidence

Source: docs/RELEASE_AND_SUPPORT.md; tests/device_flows/README.md

Evidence: Substantive local handover material exists; status/evidence/next action stays scoped to implementation versus external validation.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile with final results and remaining dependencies before final handover. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-014

- Incident procedure for wrong-account display, leakage, or data loss.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: handover preparation and review evidence

Source: docs/RELEASE_AND_SUPPORT.md

Evidence: Substantive local handover material exists; status/evidence/next action stays scoped to implementation versus external validation.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile with final results and remaining dependencies before final handover. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-015

- Store-controlled rollout/rollback limitations and migration compatibility.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: handover preparation and review evidence

Source: docs/RELEASE_AND_SUPPORT.md

Evidence: Substantive local handover material exists; status/evidence/next action stays scoped to implementation versus external validation.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile with final results and remaining dependencies before final handover. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-016

- Current checkpoint and exact remaining dependencies.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-017

Never clear every account as the first response to a website outage. Preserve sessions where possible and distinguish external service changes from local corruption.

**Implementation:** IMPLEMENTED · **Validation:** PASS

Scope: help/recovery source review

Source: apps/mobile/lib/features/help/help_screen.dart; apps/mobile/lib/app/actions.dart; docs/RELEASE_AND_SUPPORT.md

Evidence: Outage guidance preserves sessions, reload is explicit/guarded, no clear-all-first recovery. Removal remains separate confirmed action.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Reconcile final report and ledgers with actual final results; retain unresolved gates. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-018

End with one self-contained report that separates:

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: rationale. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-019

1. Source implementation completed.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-020

2. Builds actually executed and their result.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-021

3. Automated tests actually executed.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-022

4. Physical-device and actual-service validation.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-023

5. Elapsed retention evidence.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-024

6. Defects and supported limitations.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-025

7. Service/distribution and release readiness.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-026

8. Prepared artifacts and exact commands.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-027

9. The smallest consolidated set of missing user actions, if any.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: Prepared local handover and evidence dispositions; no full acceptance or release claim

Source: docs/REPORT.md; docs/COMPATIBILITY.md; docs/RESUME.md; docs/acceptance.csv

Evidence: Dated report separates source, local build/test results, physical/service/elapsed gaps, defects, release status, artifact commands and consolidated owner actions. All70 original acceptance scenarios retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Follow each stated external/device/release prerequisite and preserve prior failures when adding narrower passing observations. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-028

Do not claim 100 percent completion, zero bugs, universal device support, verified ten-account use, or store readiness without the corresponding evidence. Pending evidence is not implementation failure, and implementation completion is not proof of release readiness.

**Implementation:** DOCUMENTED · **Validation:** PASS

Scope: claim/evidence audit

Source: docs/RELEASE_AND_SUPPORT.md; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Evidence: No100%-complete/zero-bug/universal device/store-ready/verified ten-account service claim; release gaps and pending evidence explicitly retained.

Acceptance: N/A — process/documentation clause. Classification: required. Module: review/handover.

Remaining action: Keep final report claims within actual evidence scope. Owner: integration lead. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

### REQ-18-029

Stop only when all currently executable required work is finished and every remaining item has an explicit dependency, owner/action, procedure, and honest status. Do not finish with “Would you like me to continue?” when authorized work remains.

**Implementation:** COMPLETED_LOCAL · **Validation:** PASS

Scope: Local candidate, evidence reconciliation and explicit dependency handover; no release or full acceptance claim

Source: docs/REPORT.md; docs/RESUME.md; docs/acceptance.csv; docs/requirements.csv; artifacts/profile-desk-0.1.0-local/manifest.json

Evidence: Final unsigned Android/iOS builds, strengthened artifact checks, matching symbols and exact artifact/source hashes are preserved. All374 clauses and70 acceptance scenarios retain source text with current dispositions. Report records failures, open source gap and remaining owners/actions.

Acceptance: N/A — process/documentation clause. Classification: conditional. Module: review/handover.

Remaining action: Native engineering resolves Android download gap; account/device QA supplies approved service/physical/elapsed evidence; release owner resolves distribution/signing inputs. Follow the consolidated handover; do not infer full acceptance from local completion. Owner: integration lead; remaining actions assigned in docs/REPORT.md. Dependencies: Final source/build/test artifacts; native reviews; honest external gate status.

## 15. Complete acceptance catalog

Every original case is retained. PASS_UNIT, PASS_SYNTHETIC and PASS_LOCAL describe a limited observation, not a full device/service matrix.

### AT-A01

First launch with no profiles.

Required outcome: clear empty state and Link account action.

**Status:** PASS_LOCAL. English widget welcome/empty state and actual native cold launch on iOS26.5, final isolated iOS27 and Android36.

Evidence: apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt; docs/evidence/build/ios-isolated-shell-final-pass.json; docs/evidence/build/android-integrated-smoke-final-pass.txt; tests/device_flows/flutter/shell_native_test.dart; docs/evidence/ui/ios-qa-cold-launch.png

Remaining action: Repeat first-launch UI on declared physical device matrix. Owner: QA + native engineering.

### AT-A02

Create first profile.

Required outcome: unique registry and native store; correct alias shown.

**Status:** PARTIAL. Real iOS26.5 and final isolated iOS27/Android36 Flutter/native allocate/open/detach/remove pass; native transactional identity helpers pass both platforms.

Evidence: docs/evidence/build/ios-isolated-shell-final-pass.json; docs/evidence/build/android-integrated-smoke-final-pass.txt; tests/device_flows/flutter/shell_native_test.dart; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Complete authorized profile identity visual checks on physical platforms. Owner: QA + native engineering.

### AT-A03

Add profiles two through ten.

Required outcome: ten independently addressable stores.

**Status:** PASS_SYNTHETIC. Ten independently addressable same-origin stores exercised on Android36/WebView133 and iOS27; these are synthetic profiles.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Verify ten authorized linked accounts separately under AT-I06. Owner: QA + native engineering.

### AT-A04

Attempt profile eleven.

Required outcome: no extra store allocated; useful capacity message.

**Status:** PARTIAL. Native SQLite capacity helpers and ten-slot disabled shell control pass; complete platform allocation-boundary UI not yet recorded.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt

Remaining action: Exercise attempted eleventh allocation on each declared device/provider. Owner: QA + native engineering.

### AT-A05

Rapid repeated Add taps.

Required outcome: atomic limit and no duplicate reservations.

**Status:** PARTIAL. Native transactional capacity and facade serialization tests pass; rapid real-device taps/process interruption not complete.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Run repeated Add interaction and kill-between-reservation/allocation on device matrix. Owner: QA + native engineering.

### AT-A06

Rename and reorder.

Required outcome: identity and underlying session remain unchanged.

**Status:** PARTIAL. Registry rename/reorder keeps immutable IDs in native/unit tests; live linked-session retention untested.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Rename/reorder authorized linked profiles and verify displayed identity. Owner: QA + native engineering.

### AT-A07

Duplicate aliases and long text.

Required outcome: duplicate normalized aliases rejected; long accessible labels work.

**Status:** PARTIAL. Trim/case-normalized duplicate rules and Unicode length validation implemented; long-label tablet semantics test passes.

Evidence: apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Complete VoiceOver/TalkBack and native Unicode edge-case matrix. Owner: QA + native engineering.

### AT-A08

Successful QR pairing.

Required outcome: official page authenticates; owner verifies alias.

**Status:** BLOCKED_SERVICE_ACCESS. No authorized primary devices/test accounts supplied; no pairing performed.

Evidence: docs/RELEASE_AND_SUPPORT.md

Remaining action: Account owners provide authorized test accounts and primary pairing devices. Owner: product owner + authorized account QA.

### AT-A09

Expired QR and reload.

Required outcome: official fresh QR flow; no stored QR or blank trap.

**Status:** BLOCKED_SERVICE_ACCESS. Reload rebuilds same store; real QR expiry behavior is untested.

Evidence: packages/session_contract/test; docs/RELEASE_AND_SUPPORT.md

Remaining action: Exercise real QR expiry/reload without retaining QR values. Owner: product owner + authorized account QA.

### AT-A10

Cancel partial setup.

Required outcome: reservation kept or cleaned according to explicit choice.

**Status:** PASS_LOCAL. Widget tests verify keep/remove choices; real iOS and Android integration verifies reserved profile survives keeping and scoped removal.

Evidence: apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt; docs/evidence/build/ios-isolated-shell-final-pass.json; docs/evidence/build/android-integrated-smoke-final-pass.txt; tests/device_flows/flutter/shell_native_test.dart

Remaining action: Repeat native partial setup flow on physical platforms. Owner: QA + native engineering.

### AT-A11

Same-phone setup.

Required outcome: working official code flow or clear additional-device explanation.

**Status:** PASS_LOCAL. English welcome and help explicitly explain separate primary-device need; no phone-number linking promise.

Evidence: apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt

Remaining action: Check comprehension and accessibility on physical devices. Owner: QA + native engineering.

### AT-A12

Account already at linked-device limit.

Required outcome: official failure preserved with relevant help.

**Status:** BLOCKED_SERVICE_ACCESS. Official linked-device-limit page remains external; not induced with real account.

Evidence: apps/mobile/lib/features/help/help_screen.dart

Remaining action: Use approved account at its current allowance; observe official failure. Owner: product owner + authorized account QA.

### AT-A13

Wrong account intentionally paired.

Required outcome: user can correct alias or remove/relink; no false verified identity claim.

**Status:** BLOCKED_SERVICE_ACCESS. User-confirmation observation is separate from navigation; edit/remove/relink UI exists.

Evidence: apps/mobile/lib/features/accounts/account_screens.dart

Remaining action: Intentionally pair wrong authorized test account, then correct it. Owner: product owner + authorized account QA.

### AT-A14

Remove all accounts.

Required outcome: every store enters cleanup; empty state after successful completion.

**Status:** PARTIAL. Facade removal continues other profiles despite individual cleanup failure; native journal paths tested separately.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test

Remaining action: Run all-profile cleanup end-to-end on both native device matrices. Owner: QA + native engineering.

### AT-I01

Cookie and HttpOnly harness markers.

Required outcome: no cross-profile markers at the same origin.

**Status:** PASS_SYNTHETIC. Ten same-origin readable and server-verified HttpOnly cookie markers isolated in hosted native tests.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Repeat on minimum/physical/OEM provider matrix. Owner: QA + native engineering.

### AT-I02

localStorage and IndexedDB.

Required outcome: independent values and restoration.

**Status:** PASS_SYNTHETIC. Ten same-origin localStorage and IndexedDB markers retained on view recreation and isolated.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Repeat after real process death/reboot on physical matrix. Owner: QA + native engineering.

### AT-I03

Cache Storage and service workers.

Required outcome: independent registration, update, and cleanup.

**Status:** PARTIAL. CacheStorage/service-worker markers, recreation and deletion tested; full independent worker-update matrix incomplete.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Test separate registration updates and physical/provider variants. Owner: QA + native engineering.

### AT-I04

Shared channel or worker capability.

Required outcome: no supported cross-profile message or data leakage.

**Status:** PARTIAL. BroadcastChannel controls pass on both platforms; iOS27 SharedWorker positive/negative controls pass, Android WebView133 does not expose SharedWorker.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Repeat channel isolation on minimum/current physical devices; unavailable Android SharedWorker is not a pass. Owner: QA + native engineering.

### AT-I05

Profiles four through ten on iOS.

Required outcome: no unhandled service-worker or profile-capacity failure.

**Status:** PASS_SYNTHETIC. iOS27 hosted harness reached all ten stores with service-worker markers; no four-profile ceiling in this run.

Evidence: docs/IOS_EVIDENCE.md

Remaining action: Repeat iOS17 and physical/current iPhone/iPad contexts. Owner: QA + native engineering.

### AT-I06

All ten accounts paired.

Required outcome: each displays the expected authorized test account.

**Status:** BLOCKED_SERVICE_ACCESS. No actual ten-account pairing conducted.

Evidence: docs/RELEASE_AND_SUPPORT.md

Remaining action: Use ten owner-authorized accounts; manually verify identity per selector label. Owner: product owner + authorized account QA.

### AT-I07

200 randomized profile switches.

Required outcome: correct alias-to-store binding; stable resource trend.

**Status:** PASS_SYNTHETIC. 200 seeded selections across ten native profiles pass on Android36/WebView133 and iOS27, with six-store checks; app-only memory samples exclude WebContent and physical budgets.

Evidence: packages/session_contract/test/randomized_switches_test.dart; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Measure full host plus WebContent resource trends against one-profile baseline on the physical device matrix. Owner: QA + native engineering.

### AT-I08

Switch again before prior load completes.

Required outcome: only newest selection can reveal content.

**Status:** PASS_UNIT. Superseded opens are disposed; only newest selection reveals in coordinator race tests.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test

Remaining action: Repeat timing races under native/device load. Owner: QA + native engineering.

### AT-I09

Late callback from disposed view.

Required outcome: ignored or canceled without changing active account.

**Status:** PASS_UNIT. Stale navigation, transfer and mutated owner callbacks cannot affect new view in coordinator tests. Replaced Flutter attachment ordering and stale-entry rejection are now covered by Android18 unit tests and iOS24 callback/registration assertions; these are not full process/engine destruction proofs.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test; docs/ANDROID_DESIGN_AUDIT.md; docs/IOS_DESIGN_AUDIT.md

Remaining action: Repeat native late callback injection and renderer/device stress. Owner: QA + native engineering.

### AT-I10

Relaunch after OS process termination.

Required outcome: existing valid stores reopen without unnecessary reset.

**Status:** PARTIAL. Both platforms retain six synthetic storage mechanisms in two profiles across normal-lifecycle termination/relaunch; earlier iOS immediate-termination mismatch remains unexplained.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Validate abrupt termination and authorized session retention on the physical device matrix; preserve initial failure. Owner: QA + native engineering.

### AT-I11

Device reboot and OS update.

Required outcome: correct restore or honest relink state.

**Status:** PARTIAL. Android emulator and iOS simulator reboot retain six storage mechanisms in two synthetic profiles after normal lifecycle; physical reboot and OS upgrade remain untested.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Execute reboot and supported OS upgrade on assigned physical devices. Owner: QA + native engineering.

### AT-I12

App upgrade and registry migration.

Required outcome: existing profile identifiers and sessions retained.

**Status:** PARTIAL. Versioned native registry/schema and stable installation binding implemented; signed app-upgrade rehearsal not run.

Evidence: docs/ARCHITECTURE.md; docs/RELEASE_AND_SUPPORT.md

Remaining action: Install next signed build over seeded prior build and verify IDs/data. Owner: QA + native engineering.

### AT-I13

Provider update or unsupported downgrade.

Required outcome: capabilities rechecked; no shared-profile fallback.

**Status:** PARTIAL. Actual unsupported API35/WebView124 rejection and supported API36/WebView133 checks pass; in-place provider change untested.

Evidence: docs/ANDROID_EVIDENCE.md

Remaining action: Perform controlled provider update/downgrade while preserving installation data. Owner: QA + native engineering.

### AT-I14

Lost or evicted website storage.

Required outcome: clear relink path; no false authentication state.

**Status:** PARTIAL. Missing-store reconciliation, explicit unavailable state and fresh replacement facade tests pass.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test

Remaining action: Induce real storage eviction without editing live provider databases. Owner: QA + native engineering.

### AT-I15

Seven-day and fourteen-day retention.

Required outcome: dated evidence, independent of intentional revocation tests.

**Status:** PENDING_ELAPSED_TIME. No seven-day or fourteen-day actual-service retention run completed.

Evidence: tests/device_flows/README.md

Remaining action: Start approved dated retention runs and collect actual elapsed observations. Owner: QA + native engineering.

### AT-I16

Remove profile five and add another.

Required outcome: profiles one to four and six to ten unaffected; new identity allocated.

**Status:** PASS_SYNTHETIC. Middle named-store removal preserves other nine; fresh identity empty in both hosted native harnesses.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Repeat with authorized linked accounts and physical hardware. Owner: QA + native engineering.

### AT-D01

Delete selected profile.

Required outcome: content immediately covered and access blocked.

**Status:** PARTIAL. Coordinator covers before removal; native access denial/tombstones tested; real iOS integrated scoped removal passes.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/evidence/build/ios-isolated-shell-final-pass.json; docs/evidence/build/android-integrated-smoke-final-pass.txt; tests/device_flows/flutter/shell_native_test.dart

Remaining action: Verify native rendered-content cover during selected deletion on physical devices. Owner: QA + native engineering.

### AT-D02

Delete inactive profile.

Required outcome: other sessions remain usable.

**Status:** PARTIAL. Native middle-store deletion preserves adjacent data; coordinator independent cleanup tests pass.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Verify adjacent live authorized session usability during deletion. Owner: QA + native engineering.

### AT-D03

Delete while offline.

Required outcome: local effect accurate; no remote revocation claim.

**Status:** PARTIAL. Local-only cleanup and remote-unlink distinction implemented; full offline native deletion scenario not executed.

Evidence: docs/ARCHITECTURE.md; apps/mobile/lib/l10n/app_en.arb

Remaining action: Disable test-device networking and execute scoped local removal. Owner: QA + native engineering.

### AT-D04

Android loaded-profile delete restriction.

Required outcome: immediate scoped wipe and journaled deferred deletion.

**Status:** PASS_SYNTHETIC. Android36 loaded-profile restriction, scoped wipe, deferred journal and next-process container deletion passed.

Evidence: docs/ANDROID_EVIDENCE.md; docs/evidence/android/api36/clean-start-verify-pass.txt

Remaining action: Repeat provider/device matrix including API loss and disk pressure. Owner: QA + native engineering.

### AT-D05

Wipe fails or disk error occurs.

Required outcome: retry state preserved; no success claim.

**Status:** PARTIAL. Removal errors preserve retry state in tests; iOS busy worker rejection is retained/retry succeeds; disk-full injection incomplete.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test

Remaining action: Inject actual disk pressure and native wipe failure with recovery. Owner: QA + native engineering.

### AT-D06

Process stops at each cleanup stage.

Required outcome: startup resumes idempotently; no resurrected account.

**Status:** PARTIAL. Android clean-process deferred-container reconciliation passed; process termination at every allocation/cleanup stage not complete.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Run each durable interruption point on native device matrices. Owner: QA + native engineering.

### AT-D07

Service worker writes during removal.

Required outcome: profile quiesced; remaining access or data detected and addressed.

**Status:** PASS_SYNTHETIC. Active worker burst removal exercised: Android scoped wipe and iOS in-use rejection/retry retain neighbor data.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Repeat with provider variants; do not infer universal worker quiescence. Owner: QA + native engineering.

### AT-D08

Remote unlink from primary phone.

Required outcome: affected account requests relinking without changing others.

**Status:** BLOCKED_SERVICE_ACCESS. No primary-device remote unlink performed.

Evidence: apps/mobile/lib/features/help/help_screen.dart

Remaining action: Revoke one approved linked account and verify only it needs relinking. Owner: product owner + authorized account QA.

### AT-D09

Renderer crashes.

Required outcome: correct profile rebuild and visible recovery.

**Status:** PARTIAL. Android actual renderer termination, disposal and same-profile six-store reopen passed; iOS public recovery handler implemented, actual termination not induced.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Exercise iOS public process-termination callback and physical recovery on both platforms. Owner: QA + native engineering.

### AT-D10

Reload while a send status is uncertain.

Required outcome: no automatic resend; user checks official message status.

**Status:** PARTIAL. Reload explicitly warns about uncertain sends and never automatically resends; no real ambiguous send induced.

Evidence: apps/mobile/lib/l10n/app_en.arb; packages/session_contract/lib/src/coordinator.dart

Remaining action: Exercise approved uncertain-send scenario with consenting recipient. Owner: QA + native engineering.

### AT-D11

Repeated create/remove cycles.

Required outcome: no uncontrolled orphaned stores or lost capacity.

**Status:** PARTIAL. Post-wipe capacity release/backlog bound and fresh-ID tests pass; long repeated native churn incomplete.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test; docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Run repeated native create/remove and verify inventories/capacity remain bounded. Owner: QA + native engineering.

### AT-D12

Backup restore and reinstall.

Required outcome: defined session/registry behavior; unknown restored access quarantined.

**Status:** PARTIAL. Keystore/ThisDeviceOnly Keychain installation provenance and quarantine helpers tested; full restore/reinstall/transfer not performed.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Perform designated backup/restore/reinstall tests; Android untrusted install requires app-storage reset. Owner: QA + native engineering.

### AT-D13

Remove inactive B, then switch from A to C before completion.

Required outcome: B cleanup journal completes; active views unaffected.

**Status:** PASS_UNIT. Regression explicitly switches A to C while inactive B cleanup remains pending; B completion progresses independently.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test

Remaining action: Repeat delayed native wipe on declared platforms. Owner: QA + native engineering.

### AT-D14

Required provider API disappears, then returns.

Required outcome: requested wipe remains pending and resumes only for the intended profile.

**Status:** PARTIAL. Unsupported provider keeps cleanup accessible; facade retry ownership tested; real API disappear/return transition not induced.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test; docs/ANDROID_EVIDENCE.md

Remaining action: Change provider capability in a controlled installation and verify same tombstone resumes. Owner: QA + native engineering.

### AT-M01

Photo and document attachment.

Required outcome: selected content reaches correct originating account.

**Status:** BLOCKED_SERVICE_ACCESS. Origin/view-owned native photo/document selection implemented; actual account delivery unverified.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Send approved test photo/document only to consenting test recipient. Owner: product owner + authorized account QA.

### AT-M02

Picker cancel or app interruption.

Required outcome: original callback receives cancellation safely.

**Status:** PARTIAL. Picker ownership/cancel/finally cleanup implemented and source-reviewed; full system interruption matrix unrun. Audit adds actual iOS stale-picker identity/cancellation probes and Android throwing-callback/launch-failure regressions; all focused tests pass.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/ANDROID_DESIGN_AUDIT.md; docs/IOS_DESIGN_AUDIT.md

Remaining action: Cancel/background each native/cloud picker on physical platforms. Owner: QA + native engineering.

### AT-M03

Account switch while picker is open.

Required outcome: switch guarded; no file reaches another profile.

**Status:** PARTIAL. Shared switch guard passes. Audit reproduced and fixed an iOS late picker A callback using picker B ownership; actual native callback/registration fixture24 assertions pass. Full OS-picker and service-delivery matrix remains incomplete.

Evidence: docs/IOS_DESIGN_AUDIT.md; docs/evidence/ios/engine-picker-detach-baseline-failure.json; docs/evidence/ios/engine-picker-detach-final-24-pass.json; packages/session_contract/test

Remaining action: Run actual picker A interruption/switch/picker B delivery on both physical platforms and supported OS versions; confirm no file reaches the replacement account. Owner: QA + native engineering.

### AT-M04

Cloud-backed, zero-byte, or large file.

Required outcome: correct progress or actionable failure; bounded memory.

**Status:** PARTIAL. iOS staging uses bounded64KiB copy and progress; Android system content URIs avoid whole-file RAM copy; cloud/large/zero-byte matrix unrun.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Exercise physical cloud provider, empty/large files and failure feedback. Owner: QA + native engineering.

### AT-M05

Permission denied, then revoked.

Required outcome: no crash or silent capture; clear retry route.

**Status:** PARTIAL. File permissions are contextual; capture is denied. Native revoked-permission/device retry paths need execution.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Deny/revoke access and retry with actual system pickers. Owner: QA + native engineering.

### AT-M06

Origin requests camera or microphone.

Required outcome: exact origin and user intent checked before grant.

**Status:** CONDITIONAL_DISABLED. Camera/microphone stay denied; exact-origin and intent are prerequisites before any future enablement.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Keep disabled until real embedded capture flows are validated. Owner: QA + native engineering.

### AT-M07

Microphone interruption and Bluetooth.

Required outcome: correct recording or disclosed unsupported state.

**Status:** CONDITIONAL_DISABLED. Microphone/voice/calls unavailable and disclosed; Bluetooth recording not claimed.

Evidence: apps/mobile/lib/features/help/help_screen.dart

Remaining action: Validate actual foreground recording/interruptions before enabling capability. Owner: QA + native engineering.

### AT-M08

HTTP and blob download.

Required outcome: supported paths save; unsupported paths fail clearly.

**Status:** OPEN_RELEASE_GAP. iOS public WKDownload path implemented; Android authenticated/blob download lacks a safe validated public path.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Resolve essential Android download design without credential export/JS bridge, then actual service validation. Owner: product/release owner + native engineering.

### AT-M09

Unsafe filename or disk full.

Required outcome: sanitized destination and cleanup.

**Status:** PARTIAL. iOS filename normalization/byte cap, partial cleanup and cancellation tests pass; disk-full native export matrix missing.

Evidence: docs/IOS_EVIDENCE.md

Remaining action: Inject unsafe filename/large unicode name/disk-full on destination flow. Owner: QA + native engineering.

### AT-M10

Save/share, then remove account.

Required outcome: local temporary data removed; exported-copy effect explained.

**Status:** PARTIAL. Private staging and exported-copy distinction implemented; save/share then scoped-removal real UI not complete.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; apps/mobile/lib/l10n/app_en.arb

Remaining action: Save/share synthetic file through OS, remove originating profile, verify both effects. Owner: QA + native engineering.

### AT-M11

Small-screen portrait and landscape.

Required outcome: QR and composer usable; native selector remains reachable.

**Status:** PARTIAL. 320x568 at2x text widget shell passes; iOS26.5 welcome inspected. External QR/composer layout unverified.

Evidence: apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt; docs/evidence/ui/ios-qa-cold-launch.png

Remaining action: Validate real QR/composer in portrait/landscape on small physical devices. Owner: QA + native engineering.

### AT-M12

Keyboard, emoji, and long messages.

Required outcome: composer visible; focus and scrolling behave correctly.

**Status:** BLOCKED_SERVICE_ACCESS. Native shell keyboard inset/scrolling implemented; external message composer/emoji/long message not exercised.

Evidence: apps/mobile/lib/features/accounts/account_screens.dart

Remaining action: Use approved service account and device keyboard/emoji matrix. Owner: product owner + authorized account QA.

### AT-M13

Tablet resizing and external keyboard.

Required outcome: layout, focus, and share UI remain valid.

**Status:** PARTIAL. 1024x768 dark tablet widget selector with labeled44pt targets passes; real iPad resize/external keyboard/share UI not complete.

Evidence: apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt

Remaining action: Execute iPad and Android tablet resizing/external keyboard. Owner: QA + native engineering.

### AT-M14

VoiceOver and TalkBack.

Required outcome: account selection, state, and essential web actions understandable.

**Status:** PARTIAL. Shell semantics/tap target tests pass; actual VoiceOver/TalkBack and essential external web controls untested.

Evidence: apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt

Remaining action: Run assistive technology task-based testing with authorized account. Owner: QA + native engineering.

### AT-S01

Lock, background, and app switcher.

Required outcome: opaque cover hides account content.

**Status:** PARTIAL. Native full-window iOS cover, Android FLAG_SECURE, global Flutter route lock implemented; physical app-switcher timing not verified.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; apps/mobile/test/shell_test.dart; docs/evidence/build/checks.txt

Remaining action: Inspect background/foreground/snapshot transitions on physical devices. Owner: QA + native engineering.

### AT-S02

Authentication unavailable, locked out, canceled, or enrollment changed.

Required outcome: content stays covered; supported fallback or setup/recovery route.

**Status:** PARTIAL. Native auth epochs and canceled/late-result coordinator tests fail closed; enrollment/lockout hardware cases pending.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md; docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test

Remaining action: Execute OS cancellation/lockout/no-credential/enrollment-change matrix. Owner: QA + native engineering.

### AT-S03

Switch races under lock.

Required outcome: no content flash from any account.

**Status:** PASS_UNIT. New lock defeats queued/late reveals and native unlock requests are deduplicated in coordinator regressions.

Evidence: docs/evidence/build/checks.txt; packages/session_contract/test; packages/local_registry/test

Remaining action: Repeat visual race stress on physical device. Owner: QA + native engineering.

### AT-S04

External links and malicious host suffix.

Required outcome: correct browser route or block after proper URL parsing.

**Status:** PASS_UNIT. Parsed exact-host policies reject host suffix/userinfo/insecure workspace; native URL policy tests pass.

Evidence: docs/ANDROID_EVIDENCE.md; docs/IOS_EVIDENCE.md

Remaining action: Verify system browser route and legitimate service redirect coverage. Owner: QA + native engineering.

### AT-S05

Untrusted frame or bridge request.

Required outcome: no native privilege or account control exposed.

**Status:** PARTIAL. No JavaScript native privilege bridge; native owner/origin checks source-reviewed. Adversarial real frame matrix incomplete.

Evidence: scripts/verify_production.py; docs/THREAT_MODEL.md

Remaining action: Execute test-only malicious frame/link/file requests against native delegates. Owner: QA + native engineering.

### AT-S06

Invalid TLS and mixed content.

Required outcome: no bypass or insecure load.

**Status:** PARTIAL. Production TLS bypass absent; cleartext/mixed content restricted; test CA exists only in synthetic targets.

Evidence: scripts/verify_production.py; docs/THREAT_MODEL.md

Remaining action: Run invalid TLS/mixed-content negative fixture in each production configuration. Owner: QA + native engineering.

### AT-S07

Synthetic sensitive markers in logs.

Required outcome: no token, message, alias, phone, or file-path leakage.

**Status:** PARTIAL. Both native actual diagnostic payload allowlists pass seeded-marker tests; Android bounded PID log scan passes. Full signed physical runtime matrix pending.

Evidence: docs/THREAT_MODEL.md; packages/session_engine

Remaining action: Seed synthetic sensitive markers and scan actual release runtime logs/diagnostics. Owner: QA + native engineering.

### AT-S08

Production inspection and debug harness.

Required outcome: inspection disabled; debug entry points absent.

**Status:** PARTIAL. Final optimized unsigned artifacts pass strengthened exclusion/manifest/privacy checks. Android optimized candidate cold welcome and empty inspection-target list pass with temporary test signing; no WebView opened.

Evidence: scripts/verify_production.py; docs/evidence/build/checks.txt

Remaining action: Repeat checks and actual WebView inspection on final signed physical distribution variants. Owner: QA + native engineering.

### AT-S09

Capability unavailable.

Required outcome: informative failure before pairing; cleanup remains accessible.

**Status:** PASS_LOCAL. Android35/WebView124 rejected before allocation while cleanup remained callable; supported-provider gates tested separately.

Evidence: docs/evidence/android/api35-unsupported/capability-gate-pass.xml

Remaining action: Repeat unsupported OEM/provider and temporary API-loss states. Owner: QA + native engineering.

### AT-S10

Network drop and resume.

Required outcome: account context preserved and bounded retry.

**Status:** PARTIAL. Typed unknown/offline/path-reachable state added independently of auth; navigation recovery is bounded and manual.

Evidence: packages/session_contract/test/observations_test.dart; packages/session_engine

Remaining action: Exercise Wi-Fi/mobile/offline/captive portal and native network recovery. Owner: QA + native engineering.

### AT-S11

Submission and reviewer access.

Required outcome: actual core behavior reproducible with truthful review instructions.

**Status:** BLOCKED_RELEASE_AUTHORIZATION. Draft review procedure, disclosure worksheet, listing and five explicitly fictional shell previews prepared. Final identity/contact/hosting, provider/distribution basis, signing and real reviewer accounts are not supplied.

Evidence: docs/STORE_REVIEW_PACKAGE.md; docs/RELEASE_AND_SUPPORT.md; docs/release-assets/README.md

Remaining action: Release owner resolves permitted distribution, identity, privacy/support URL and reviewer access. Owner: product/release owner + native engineering.

### AT-S12

Release upgrade and rollback preparation.

Required outcome: signed artifacts, migration evidence, and recovery plan ready.

**Status:** PARTIAL. Both final unsigned production builds pass; module and Dart locks enforced, symbols/UUIDs preserved, CI/rollback runbook prepared. Signed release and upgrade remain pending.

Evidence: docs/RELEASE_AND_SUPPORT.md; .github/workflows; docs/DEPENDENCIES.md

Remaining action: Supply approved signing; rehearse same-installation upgrade and recovery before distribution. Owner: QA + native engineering.
