# Profile Desk implementation plan

Goal: implement the supplied ten-profile Android/iOS session manager with honest verification.

Architecture: Flutter shell, typed Pigeon contract, Swift/Kotlin native profile engines, native SQLite lifecycle authority. See ARCHITECTURE.md and the supplied Word plan for the baseline. Parallel native engineers own each plugin platform; shared worker owns coordinator/account facade/harness; lead owns UI, integration, evidence and release preparation.

18 October follow-up: [phone navigation and account transfer design](PHONE_LAYOUT_AND_ACCOUNT_TRANSFER.md) and [implementation checklist](PHONE_LAYOUT_AND_ACCOUNT_TRANSFER_PLAN.md) track the latest additive user requests. Actual signed-in session migration is an unmet capability; account setup transfer is explicitly named and requires relinking. Original prompt/Word evidence remains preserved.

## Global constraints

- Maximum ten reserved/access-enabled profiles; one live production WebView application-wide.
- Immutable IDs, no shared storage fallback, no arbitrary web/native bridge.
- iOS 17+, Android API29+ and runtime MULTI_PROFILE/DELETE_BROWSING_DATA.
- Official HTTPS workspace only; scoped transfers and permissions; privacy covers.
- Physical service tests, retention and release authorization reported separately.

## Review focus

- A stale view completion must not reveal under another alias.
- Cleanup of inactive B must finish while A switches to C (AT-D13).
- Provider capability loss preserves pending cleanup until support returns (AT-D14).
- Process death between reservation and allocation never loses capacity or adopts another store.
- Picker callbacks and authentication interruptions must never deliver to the wrong account.

## Dependency ordered tasks

- [x] Read both source documents and inspect workspace/toolchains; no existing code or git history.
- [x] Define typed host/events, storage ownership, view host and design direction.
- [x] Generate and verify Pigeon contract; implement native registration and app configuration.
- [x] Implement each native transactional registry, allocation compensation, startup reconciliation and scoped cleanup.
- [x] Implement coordinator/account services and invariant/race tests.
- [x] Implement all shell screens, account management, linking/relink, compatibility/help/privacy.
- [x] Implement native picker ownership, iOS download plumbing, permission denial boundaries and app lock.
- [ ] Complete essential Android authenticated/blob downloads and validate foreground photo/document flows on both platforms. Explicit unsupported errors do not complete this requirement.
- [x] Implement same-origin HTTPS harness and native instrumentation; prove two then ten stores.
- [x] Execute formatting, static analysis, shared tests, native tests and supported build variants; repair failures.
- [x] Exercise simulator/emulator lifecycle and UI; record actual coverage and physical-device gaps.
- [x] Run independent security/lifecycle review; fix findings and affected tests.
- [x] Complete 70-case evidence dispositions, build/release scripts, CI, support/privacy/incident docs and checkpoint.
- [ ] Actual authorized device/service pairing and 7/14-day retention: external dependencies, never inferred from mocks.
- [ ] Signed release and distribution: prepare package; external account/permission/approval dependencies remain explicit.

Completion marks above describe source/local execution, not full live-service acceptance. Essential Android authenticated/blob download is an OPEN_RELEASE_GAP; physical/service/retention and signed-release gates remain open. See REPORT.md and COMPATIBILITY.md.

Detailed requirement and acceptance traceability is maintained in docs/requirements.csv and docs/acceptance.csv. Implementation status and validation status are separate columns; NOT_RUN and blocked never mean PASS.

## Whole-design verification

- [x] Independently compare every prompt clause and acceptance case with the retained source.
- [x] Trace every nonempty Word paragraph and table row, including phase exits, risks and source links, in [DESIGN_DOCUMENT_TRACEABILITY.md](DESIGN_DOCUMENT_TRACEABILITY.md).
- [x] Provide all 374 prompt dispositions and all 70 acceptance cases in [PROMPT_VERIFICATION_CHECKLIST.md](PROMPT_VERIFICATION_CHECKLIST.md); `scripts/check_traceability.py` prevents omissions and stale generated copies.
- [ ] Close every release gate in [DESIGN_VERIFICATION_CHECKLIST.md](DESIGN_VERIFICATION_CHECKLIST.md). An audited disposition does not mean the requirement has passed its complete acceptance matrix.
