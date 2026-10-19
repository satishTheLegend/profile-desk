# Empty-origin import capability

19 October 2026. [138 assertions pass](result.json) in an owned iOS 26.5 Simulator, using a normal Xcode Simulator target and public WebKit APIs. [Fixture and reproduction](../../../../tests/session_portability/origin_bootstrap/README.md).

The app loads fixed inert HTML with `loadHTMLString` and a declared app-bound `https://bootstrap.profiledesk.invalid/` base URL. The actual Window security origin, location, base URI and secure context match. A blocking content rule and restrictive CSP prohibit network resources; observations show no resource loads, script elements, child frames or service-worker registrations. Only fixed app-owned test JavaScript executes.

Two independent empty named stores receive fictional data. The source's nonextractable AES-CTR key remains in its store; bounded fictional plaintext crosses native memory and is wrapped with a fresh nonextractable destination key. LocalStorage, typed IndexedDB values and key usability survive fresh WebViews, separate app processes and a reboot of only the owned Simulator. Destination ciphertext differs from source; source ciphertext remains unchanged. Each generated CTR key encrypts one fixture payload only. This is not an authenticated archive format.

Named data-store instances remain retained across the fresh-view checks. Each process also creates an inert nonpersistent WebView to initialize WebKit's UI run loop; cold isolation refers to the designated **named** store. The installed executable matches the built fixture, all source hashes remain unchanged, and owned store/rule/Simulator cleanup passes. Reports contain booleans, counts, digests and synthetic process identifiers, with no payload/key/ciphertext bytes.

[Prior attempts](attempt-history.json) preserve the compiler and lifetime failures. The passing fixture combines retained native store sessions and explicit WebKit initialization; it does not establish which change alone explains the earlier LocalStorage loss.

This closes the synthetic empty-origin capability question. It does **not** establish a consistent source capture, full service-state coverage, safe worker retirement, encrypted production backup, restored WhatsApp authentication, cross-platform portability or permission to deploy.
