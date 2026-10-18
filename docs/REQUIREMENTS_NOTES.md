# Reading the requirement ledger

18 October viewport follow-up: the user explicitly approved testing Safari-compatible browser identification after the physical iPhone showed a Safari15+ warning. This exception is limited to the development bundle; QA/production retain the original identity and the source prompt remains unchanged. The standard suffix reached a preauthentication download landing with Continue in browser, while branded suffixes failed. The native viewport fit is implemented separately for iOS. See `COMPATIBILITY.md` and `evidence/ios/viewport/physical-browser-comparison.json`; neither observation closes account pairing/media or production compatibility requirements.

The [whole-design checklist](DESIGN_VERIFICATION_CHECKLIST.md) consolidates the current audit. The [Word crosswalk](DESIGN_DOCUMENT_TRACEABILITY.md) covers all 337 nonempty paragraphs and 214 data rows; the [generated prompt checklist](PROMPT_VERIFICATION_CHECKLIST.md) presents every requirement and all 70 acceptance cases. Run `python3 scripts/check_traceability.py` to verify preserved source content, complete anchors/references and generated-view freshness; use `--write` after ledger edits. This verifies traceability, not semantic fulfillment.

Reconciled on 18 October 2026 IST. `requirements.csv` preserves all374 IDs, source sections and requirement texts from the initial extraction. The added `dependencies` and `validation_scope` columns make prerequisites and evidence limits explicit. The original ID/source/text sequence has SHA-256 `080d02ca81dc81d368b177facbe7680be0d86035dd1a4e5338f5f59e6db08533` when serialized as UTF-8 JSON tuples with `ensure_ascii=False` and Python's default separators.

Implementation and validation are different:

- `IMPLEMENTED` identifies concrete source implementing that clause. It does not certify every hardware, service or release scenario.
- `PARTIAL` identifies a missing source behavior, incomplete broad procedure or a clause that combines implemented behavior with required unverified flows.
- `DOCUMENTED` identifies a substantive decision, procedure, boundary or prepared artifact.
- `COMPLETED_LOCAL` identifies an executed local workflow step.
- `EXTERNAL_DEPENDENCY` identifies unavailable accounts, hardware, elapsed time, signing or release inputs, with a named owner and action.
- `EXCLUDED` identifies a prohibited feature or a conditional feature deliberately withheld. It is never a waiver of essential photo/document support.

`validation_status=PASS` applies only to the adjacent `validation_scope` and `evidence`. A source inspection, widget test, coordinator test or simulator fixture must not be read as a full physical-device or actual-service pass. The70 complete acceptance cases remain separately tracked in `acceptance.csv`. Parent headings are classified as rationale; their children carry the executable details. Source references use `SRC-S01` through `SRC-S36`, independently of security acceptance cases `AT-S01` through `AT-S12`; see `SOURCE_CATALOG.md` for the preserved Word hyperlinks.

Final local reconciliation uses the executed checks and exact scope in REPORT.md, ANDROID_EVIDENCE.md, IOS_EVIDENCE.md and RELEASE_REVIEW.md. Native stress/process/transport results are recorded independently of shared unit tests. The hosted fixtures use synthetic same-origin markers and prove no real WhatsApp account compatibility.

The essential Android authenticated/blob download path remains `OPEN_RELEASE_GAP`. It is marked partial rather than excluded. Camera, microphone, voice and calls remain conditional and disabled. Actual authorized pairing/text/photo/document flows, physical minimum/current/OEM device coverage,7-/14-day elapsed retention, service/distribution basis and final signing/reviewer access remain independent dependencies.

The whole-design audit also marks REQ-12-014 PARTIAL / NOT_RUN for its complete cleanup-on-success requirement: successful iOS picker imports remain until view disposal, profile removal or startup, because returning file URLs does not prove WebKit consumption or upload completion. Narrow staging/cancel/removal checks pass separately. AT-M03 is PARTIAL despite the new passing native stale-picker regression. REQ-12-016 records the existing progress implementation while retaining unverified download behavior. Final implementation dispositions total 199 IMPLEMENTED, 32 COMPLETED_LOCAL, 72 DOCUMENTED, 45 PARTIAL, 20 EXTERNAL_DEPENDENCY and 6 EXCLUDED; these are not a product-completion percentage.

The integration reconciliation updates local report/checkpoint/compatibility dispositions, typed network observations, per-transfer progress ownership, actual diagnostic payload tests and bounded artifact checks. Native runtime additions retain their exact executed context; broader signed/physical/service cases remain open. Preserve failures and narrower evidence when recording a later passing rerun; never turn a pending broad clause into PASS solely because related source compiles.
