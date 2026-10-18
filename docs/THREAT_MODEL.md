# Security and privacy model

The native app, its Flutter control layer, and each embedded website are separate trust boundaries. The operator who unlocks the app can access all profiles. A profile is not a separate human identity. Website TLS, OS isolation and endpoint security remain dependencies.

| Asset or failure | Control | Verification |
| --- | --- | --- |
| Wrong account shown beneath another label | Opaque native cover before changing selection; immutable profile/view/operation/generation; latest-only reveal | Coordinator race tests; native binding tests; device captured-frame validation pending |
| Cross-profile website state | iOS named persistent stores; Android profile assigned before any view use; capability failure blocks allocation | Ten-profile same-origin native harness; provider versions recorded |
| Delayed picker sends to a different account | Native ownership bound to original view; transfer guard; callback once; disposal cancellation | Native transfer review; real media matrix pending |
| Malicious website accesses native privileges | No general JavaScript bridge; exact parsed top-level scheme/host; no TLS bypass; external links require user action | Native URL policy tests and production exclusion checks |
| Incomplete local deletion resurrects account | Native SQLite tombstone; block access; scoped wipe callback; startup reconciliation before profile loads; cleanup independent of selection | Registry/native cleanup tests and AT-D13; full process-interruption matrix pending |
| Restored registry or orphaned stores adopted silently | Native installation trust evidence and public inventory; missing/unknown stores quarantined | Registry tests; actual backup/restore/device-transfer matrix pending |
| Background snapshot or enabled lock exposes content | Native background cover; native lock state; OS authentication; global Flutter route overlay | Native lifecycle source review and widget lock test; physical snapshot/auth interruptions pending |
| Sensitive diagnostics escape | Technical allowlist; generic error classes; explicit system share; no telemetry/replay/screenshots | Actual diagnostic payload helper tests and bounded unsigned artifact marker scans passed; signed physical runtime/privacy matrix remains pending |
| Download path exports session credentials | iOS native WKDownload context; Android unsupported paths fail explicitly; no global cookie helper or export | Source review; actual service media validation pending |
| Supply-chain or build drift | Pinned package versions and lockfiles; generated bridge drift check; separate build identities | Local static/tests/builds and prepared CI; CI execution separately recorded |
| Setup archive smuggles credentials or destination trust | Exact versioned metadata allowlist, 64KiB/ten-entry limits, fresh IDs and unknown auth; native revalidation; lock/permissions never imported | Shared/native parser and transaction tests; physical document-provider matrix pending |
| Stale setup picker exports or imports after detach/lock | App-owned operation tokens and attachment epochs, cancellation, scoped reads, generic errors and staging cleanup | Native lifecycle tests; real provider interruptions pending |
| Presentation adapter observes private messages | Fixed bundled script, exact main-frame origin, structural hooks only; no native message handler; only a bounded availability Boolean on iOS | Owned isolated-world browser test blocks content, input, storage and network reads; authenticated layout QA pending |

## Data inventory

- Native SQLite: random identifiers, user-entered aliases, colors, order, observed timestamps, lifecycle/journal, preferences and scoped permission decisions. Retained until profile cleanup; aliases can be personal data.
- Browser-managed website stores: service-owned session and website storage, isolated per profile. The app does not copy these into its registry, diagnostics or backend.
- Staging: private per-profile files and native picker grants. iOS download staging is removed after share/cancel; successful upload copies remain available for WebKit consumption until the bound view is disposed, the profile removed, or startup cleanup. Immediate cleanup after website upload completion is not implemented because there is no trusted completion signal. This remains a documented REQ-12-014 gap requiring a validated retention design.
- Exported files: user-selected destinations have their own retention; local profile deletion cannot remove them.
- User-requested account setup files: ordered aliases/colors and appearance only, readable unencrypted JSON with explicit disclosure before export. No signed-in browser session, messages or credentials are included. Import creates fresh profiles and requires official linking again. The new request changes the original feature exclusion without enabling automatic cloud or OS browser backups.
- OS trust material: app-owned restore-integrity keys/nonces as implemented natively, not website credentials. No claim that Keychain/Keystore encrypts the entire browser database.

## Backup and deletion limits

Android explicitly excludes app roots, files, databases, preferences and device-encrypted counterparts from legacy cloud backup and modern cloud/device transfer. iOS app-owned data uses supported exclusions. Browser provider behavior, OEM transfer and real restore require runtime evidence. No forensic erasure promise. Local removal is not remote linked-device revocation.

## Release blockers

No reviewed service-distribution basis, no approved test accounts, no physical-device matrix or elapsed retention is currently supplied. Essential Android blob/authenticated media download remains an explicit public-API compatibility gap. Do not market unverified media, calling, notification, privacy or retention claims.
