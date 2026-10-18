# Profile Desk

A Flutter Android/iOS foreground workspace for up to ten separately stored browser profiles. Native Kotlin/Swift engines own durable profile identity, allocation and deletion. Only one profile has a live WebView. This is an independent companion prototype; actual WhatsApp pairing and distribution readiness are separate gates.

Latest work: [native messaging components, readable phone navigation and session-migration research](docs/PROFILE_DESK_NATIVE_EXPERIENCE_PLAN.md). The Flutter chat list, messages and composer are implemented and tested with fictional fixtures; the live WhatsApp adapter is not enabled. Account setup files contain names, colors, order and appearance and require linking again. Complete session/data backup and authenticated restore remain unimplemented and unverified. [Current testing evidence and limits](docs/evidence/native-experience/README.md).

## Run locally

Tested: Flutter3.47.5/Dart3.13.4, JDK17, Android SDK36+, Xcode27.1. Android requires API29+ **and** runtime AndroidX WebKit multi-profile/scoped-deletion support; iOS requires17+.

```sh
./scripts/bootstrap.sh
./scripts/check.sh
cd apps/mobile
flutter run --flavor development
```

Use `scripts/build_android.sh` and `scripts/build_ios.sh` for explicit QA/production artifacts. Production signing is intentionally unconfigured. Generated bridge: `scripts/generate_bridge.sh`. English shell copy lives in `apps/mobile/lib/l10n/app_en.arb`; `flutter gen-l10n` regenerates typed strings. Add future locales through ARB; external website localization remains owned by its provider.

## Source and evidence

Start with the [whole-design verification checklist](docs/DESIGN_VERIFICATION_CHECKLIST.md): every Word paragraph/table and all 374 prompt clauses / 70 acceptance cases have a disposition. Native attachment/picker defects found during the audit are repaired and tested. Required Android downloads, iOS successful-upload cleanup, real-account/device validation, elapsed retention and release setup remain open.

- `apps/mobile`: accessible Flutter shell and Riverpod state composition.
- `packages/session_contract`: Pigeon schema and race-safe coordinator; fake engine exists only under tests.
- `packages/local_registry`: account facade; native SQLite remains the durable authority.
- `packages/session_engine`: real platform engines and platform view adapter.
- `tests/profile_harness`: same-origin HTTPS synthetic storage fixture, excluded from production.
- `docs/ARCHITECTURE.md`, `THREAT_MODEL.md`, `RELEASE_AND_SUPPORT.md`: design, privacy and operating decisions.
- `docs/requirements.csv`, `acceptance.csv`, platform evidence and `REPORT.md`: actual implementation and validation dispositions.

The supplied Word plan is preserved. No credentials, test accounts or live-service assertions are bundled. Do not treat synthetic isolation, a simulator run or an unsigned build as proof of supported live account behavior. [Source and Android CI](https://github.com/satishTheLegend/profile-desk/actions/workflows/check.yml) runs on GitHub. Apple CI uses an explicitly provisioned runner label for the tested toolchain.
