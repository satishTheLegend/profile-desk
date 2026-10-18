# Build release and support guide

## Local setup

Tested host: Apple silicon macOS; Flutter3.47.5/Dart3.13.4; Xcode27.1; Android SDK installed; Flutter configured JDK17. Run `scripts/bootstrap.sh`, `scripts/check.sh`, and `python3 scripts/check_generated.py`. Native engines use OS SQLite. AndroidX WebKit1.17.1 is pinned in the plugin. Check platform evidence files for exact tests/providers.

`./scripts/build_android.sh development debug` produces a development debug APK. `./scripts/build_android.sh production release` prepares an unsigned release APK unless approved signing is configured. `./scripts/build_ios.sh development simulator` produces a simulator app. `./scripts/build_ios.sh production device-unsigned` produces an unsigned device app, not an installable signed archive. Development, QA and production have separate identifiers and storage.

Never commit signing files or credentials. Configure the final app identifier and release team/keystore through approved secret storage. Build a signed archive/bundle only after owner settings exist. Verify the actual release variant; a debug build or simulator result is insufficient. Retain symbols, mapping files, dependency inventory, build IDs and safe test evidence.

## Review package and release decision

1. Product owner supplies reviewable permitted-use/distribution basis and intended regions/account types. QR consent alone does not establish provider permission.
2. QA supplies all70 acceptance dispositions, declared OS/provider/physical-device matrix, actual ten-account pairing and7-/14-day retention evidence. Critical/high wrong-account, isolation, privacy and data-loss defects block release.
3. Native engineers resolve essential photo/document download and upload compatibility on both platforms. Unverified conditional camera/voice/calls stay disabled.
4. Release owner selects final original name/icon, legal entity, support contact and privacy URL. Profile Desk is a working name; no trademark clearance is claimed.
5. Prepare truthful store disclosures including embedded website data flows. Verify current SDK/target rules and developer account testing requirements at submission.
6. Supply reproducible reviewer access to the actual feature with authorized accounts/devices. Do not rely on an unusable expiring QR or portray a synthetic harness as live integration.
7. With explicit release authorization, create signed artifacts and submit through the selected channel. No upload/submission has been performed by local implementation.

## Draft store copy

Profile Desk organizes separately linked accounts in one foreground workspace. Choose a saved profile from the top selector. Each profile has its own browser storage. Account owners approve linking in the official primary application. The app does not create accounts and has no app-owned messaging backend. Switching closes the active page; inactive profiles are not monitored and do not promise notifications or current unread counts.

Only retain claims proven by the final device/service matrix. Do not advertise ten live accounts, calls, reliable background sync or universal persistence on the basis of synthetic tests.

## Privacy disclosure draft

The application stores local profile labels, settings and browser session data to provide account selection and access. The embedded website communicates with its service providers under their policies. The application does not send messages, contacts or browser session exports to an app-owned backend. Diagnostics are local technical information shared only through an explicit system action. Camera/microphone/calls are disabled pending validated support. Local removal removes access from this installation, while remote unlinking is controlled in the primary app. Exported files may remain in destinations the user selected.

Before publishing, the release owner must add the actual operator identity, support contact, jurisdictions, retention details, service recipients and store-specific data-safety disclosures. This draft is not legal approval or a no-data-collected assertion.

## Incident and maintenance runbook

- Wrong account display, cross-profile data, unauthorized capture or loss: stop release/distribution, preserve redacted technical evidence, reproduce only with synthetic data, assign native/coordinator owner, assess whether affected owners need remote unlink guidance. Fix and rerun affected suites before resuming.
- Correlated website failure: distinguish outage/provider change from local corruption. Offer connection checks, bounded reload and compatibility information. Never clear all accounts first.
- Lost phone/access termination: use primary app Linked devices controls for remote unlink. Local cleanup status cannot certify service-side revocation.
- Native change: rerun same-origin isolation, startup/deletion interruptions, switching, permissions and privacy. Website/OS/provider change: run authorized pairing/manual text/photo/document smoke suite.
- Migration/rollback: preserve immutable IDs and database forward migrations; rehearse upgrade with synthetic profiles. Mobile store rollbacks cannot instantly replace every installed client. Halt rollout when migration compatibility is uncertain.

## Missing external actions

Product/release owner: provider/distribution basis, final identity/contact/signing ownership and actual release authorization. QA/account owners: supported physical devices, specifically authorized test accounts and consenting recipients. QA: actual elapsed retention runs and complete acceptance matrix. Native engineering/product: supported solution or explicit scope decision for Android media download gap. Independent local implementation/testing continues while these remain pending.

## Local build limitations

Prepared GitHub workflows have not run remotely. Apple workflow requires an approved runner with the tested Xcode27.1/Flutter3.47.5 and iOS27 simulator; hosted runner availability was not assumed. Local development/QA debug, Android unsigned production release and iOS unsigned production device builds are separate artifacts. Android SDK XML tooling emitted a metadata-version warning during a successful debug build; native compilation/lint evidence is separate. License/advisory review remains explicit in DEPENDENCIES.md.

Android restored-installation recovery: installation-bound proof failure quarantines access. Ordinary replacement cannot establish trust in that installation. Explain the Android system app-storage reset requirement, including loss of every local profile, before the operator chooses it. Relink each new profile afterward; exported copies remain outside app control.

The artifact SDK tools require JDK17 on PATH/JAVA_HOME; on the tested host use `export JAVA_HOME=/opt/homebrew/opt/openjdk@17`.

Local artifact preservation: `python3 scripts/verify_release_artifacts.py` inspects the built unsigned variants; `python3 scripts/package_local_candidate.py` preserves APK/device app, native symbols/mapping and hashes under the ignored `artifacts/profile-desk-0.1.0-local/`. The manifest records the exact source snapshot even before a Git commit. `tests/device_flows/smoke_android_release.py SERIAL` uses a temporary local key only on a dedicated emulator, refuses an existing production installation, and removes its empty installation/key afterward. It does not configure release signing.
