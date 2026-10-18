# Native session engine

Kotlin/AndroidX WebKit and Swift/WebKit implementation of the generated Pigeon contract. `NativeSessionEngine` preserves raw native futures so `SessionCoordinator` can reconcile late operations after its deadline. `NativeSessionView` owns a persistent empty host; each selection binds a new view to one immutable persistent store before navigation.

Android requires API29 and both MULTI_PROFILE and DELETE_BROWSING_DATA; iOS requires17 named stores. Native SQLite owns registry, preferences and durable cleanup. Restore trust is installation-bound. No shared-store fallback, JavaScript privilege bridge, production test URL or session export exists.

See platform `NativeTests`/`src/test`/`src/androidTest`, `docs/ANDROID_EVIDENCE.md`, `docs/IOS_EVIDENCE.md` and root release guide. Generated message files are produced only from `packages/session_contract/pigeons/session_api.dart`.
