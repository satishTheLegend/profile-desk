# Local store review preparation package

Prepared 18 October 2026 for Profile Desk 0.1.0+1. **Draft for internal review; not submitted, published, or ready for store approval.** This package closes the local documentation portion of Word-plan P241–247 and prompt REQ-16-033…035. Final service validation, required Android media, permission, operator identity, signing and actual reviewer access remain open.

Current source/evidence: [implementation report](REPORT.md), [design traceability](DESIGN_DOCUMENT_TRACEABILITY.md), [compatibility matrix](COMPATIBILITY.md), [release/support guide](RELEASE_AND_SUPPORT.md), [artifact review](RELEASE_REVIEW.md), [dependency inventory](DEPENDENCIES.md), and [screenshot preparation inventory](release-assets/README.md). Preview assets are fictional native-shell preparation material, not proof of linked accounts or a substitute for real product screenshots.

## Product identity and release fields

| Field | Concrete draft or current state | Owner / requirement before submission |
| --- | --- | --- |
| Working display name | Profile Desk | Product owner approves final original name and trademark/brand review; no clearance is claimed |
| Version | 0.1.0+1 | Release owner selects final candidate/version; retain signed build provenance |
| Category suggestion | Productivity | Release owner verifies actual core use and current store category choices |
| Audience | One authorized device operator managing their permitted linked accounts | Product owner defines account types, target age groups and regions; no children's-product assumption |
| Monetization | No app payments, advertising SDKs, subscriptions or tracking in current native shell | Reassess the whole delivered experience, including external web behavior, for final declarations |
| Developer / legal operator | PENDING OWNER | Exact registered legal identity, account enrollment and support responsibility |
| Contact and support URL | PENDING OWNER / HOSTING | Real monitored contact and active support URL; no fabricated address |
| Privacy policy URL | PENDING OWNER / HOSTING | Final policy based on the worksheet below, publicly accessible at the actual release URL |
| Service-use basis | PENDING REVIEWABLE EVIDENCE | Product owner provides permitted-use/distribution basis; QR consent alone is insufficient |
| Distribution channel | NOT SELECTED / NOT AUTHORIZED | Release owner selects testing/release channel after gates; no store action has been performed |
| Package and bundle identifiers | Separate development, QA and production configuration exists | Confirm final production identity, signing ownership and no collision before release |
| Permissions | Internet/network observation; OS-mediated lock; user-selected file access; no baseline camera/microphone/contacts/SMS/location/notifications | Reinspect actual merged signed manifests and all linked SDKs |

## Listing draft

This wording describes the current candidate. It deliberately reports the unresolved compatibility/media state. It is **not** proposed as a public beta/store listing while core functionality is unverified. Replace the final paragraph only after the corresponding evidence exists; do not silently remove limitations.

**Name:** Profile Desk

**Subtitle:** Organize separate profiles

**Short description:** Keep separate account profiles in one foreground workspace.

**Description:**

Profile Desk provides a native workspace for organizing separately linked browser profiles. Create a local label, choose a color, reorder the list, and select a profile from the top account selector. The local registry supports up to ten saved or incomplete setups. Only the selected profile has an active web view.

The intended companion flow opens the official WhatsApp Web page. The account owner approves linking in the official primary application. Profile Desk does not create WhatsApp registrations. A separate primary device is required for the supported setup instructions; phone-number linking is not currently a verified feature of this embedded client.

Native controls include profile management, optional device authentication, background privacy covers, compatibility information, local removal and user-controlled technical diagnostics. Removing a local profile removes access from this installation. Remote unlinking is performed through the primary account's linked-device controls. Files intentionally exported to other apps or storage have their own retention.

Inactive profiles are not monitored and do not promise notifications, current unread counts or continuous synchronization. Switching closes the active page and can lose unsent drafts or other temporary page state. There is no unified inbox, automatic messaging, account sharing or app-owned messaging backend. Camera capture, microphone recording and calls are disabled.

This is an unapproved local development candidate. Storage isolation has been exercised with synthetic fixtures, but actual account pairing, messaging and media have not been validated. Android authenticated/blob downloads are not implemented through a verified supported route. This candidate is not ready for public distribution, and no official endorsement or provider authorization is claimed.

**Initial release note draft:** Local profile management, typed native session engines, isolated synthetic storage tests, scoped cleanup, app lock and privacy covers are implemented. This package records an unsigned development candidate; public release remains gated by the compatibility, media, device, retention and authorization work in the implementation report.

## Screenshot inventory and capture conditions

Fifteen local PNG previews now render the actual Flutter shell across phone, narrow, tablet, large-text and landscape viewports (standard phone previews are860×1864) with a visible “FICTIONAL PROFILES” banner: [welcome](release-assets/welcome.png), [accounts](release-assets/accounts.png), [selector](release-assets/selector.png), [privacy](release-assets/privacy.png), and [lock](release-assets/lock.png). The [asset inventory](release-assets/README.md) records generation details, hashes and evidence limitations. The lock preview simulates the UI state; it does not validate OS authentication. None contains website, pairing or message imagery. These previews must never imply that an account is linked or authenticated. Do not include a QR, pairing code, phone number, private conversation, real contact list or session value in retained imagery.

| Shot | Intended image and caption | Current allowable source | Final submission dependency |
| --- | --- | --- | --- |
| 01 Welcome | “A separate place for each profile” | Prepared `welcome.png`, labeled fictional shell render | Final device size/appearance and accurate copy review |
| 02 Account manager | “Name, color and organize your profiles” | Prepared `accounts.png`, labeled fictional shell render | Capture exact release UI; no fabricated connected statuses |
| 03 Selector | “Choose the profile you want to open” | Prepared `selector.png`, labeled fictional shell render | Verify responsive phone/tablet layout on release device |
| 04 Privacy | “Optional device lock and local controls” | Prepared `privacy.png` and simulated `lock.png` | Verify enabled/disabled state and real OS authentication behavior |
| 05 Help/compatibility | “Understand linking and device support” | Additional capture pending; must use actual environment readout | Avoid asserting compatibility on untested devices |
| 06 Main workspace | Native selector plus actual official service in authorized test context | **NOT AVAILABLE** | Service-use gate; fictional messages; specifically consenting recipient; no QR/codes/private identities; actual release build |
| 07 Files and cleanup | Real supported photo/document selection/save/share and local removal | **NOT AVAILABLE** | Android required download gap resolved; actual platform media/device validation |

Do not submit preview fixtures as evidence of actual integration. Apple expects accurate app-in-use screenshots and fictional account information; the submitted feature set and imagery must match. [Apple App Review Guidelines, 2.3](https://developer.apple.com/app-store/review/guidelines/)

## Data-flow inventory from implemented source

This is a technical worksheet, not a completed legal policy or a set of final console answers. It separates app-controlled storage/transfers from service-controlled web traffic. The native shell's lack of a messaging backend does not imply that the embedded website collects no data.

| Data / flow | Implemented purpose and storage | Recipient / egress | Current retention or deletion boundary | Evidence and unresolved question |
| --- | --- | --- | --- | --- |
| User-entered alias, color, order, random profile ID and timestamps | Native SQLite profile management | No app-owned server path in inspected source | Profile cleanup removes app-owned records; ordinary upgrade preserves identity | `NativeRegistry.kt`, `ProfileRegistry.swift`; aliases may contain personal data despite being local |
| Lock, theme and local preferences | Native settings | No app-owned server path | Until reset/removal as defined by settings | Registry source; confirm actual backup/restore behavior on release devices |
| Browser session and website storage | Named WebKit/Android browser profiles | Browser communicates with the official service and its legitimate dependencies | Browser/service lifecycle; scoped local cleanup; remote revocation separate | No app session export; provider data recipients/retention and actual restore behavior require verification |
| Messages and service account details rendered in the official site | Foreground service use, controlled by the website | Service and message recipients | Service policies and user controls; deleting a local profile does not delete remote messages | Actual service flows untested; host renders an endpoint and is not claimed cryptographically incapable of seeing content |
| User-selected photos/documents | Original-view native selection; URI/stream or private staged file | Selected official webpage and its service when user submits | Cleanup on cancellation/failure/disposal/removal/startup; successful iOS imports remain until view disposal/removal/startup because WebKit consumption is unobserved. The service copy is separate | REQ-12-014 success-cleanup gap remains open; actual upload, cloud access, large/zero-byte/revoked-file/device behavior still requires tests |
| Downloaded content | iOS browser-native download staging and explicit system share | User-selected Files/Photos/app destination | Local staging cleanup; intentionally exported copies remain outside profile deletion | Android authenticated/blob route missing; iOS actual-service path unverified |
| Local diagnostics | OS/provider/capability/coarse count allowlist; no aliases or page/file content | Only destination chosen in OS share UI | Destination controls its copy; no automatic native upload | Actual export helper tests exist; final support recipient and retention are undefined |
| OS authentication | Device credential/biometric unlock decision | OS authentication service | Application receives result, not biometric template | Native lock source; physical enrollment/lockout/interruption evidence pending |
| Installation trust proof | Keychain/Keystore key and installation-bound nonce | Local OS secure storage | Used to quarantine untrusted restores; not a website credential or browser encryption key | Native installation/persistence code; physical restore/OEM transfer tests open |
| OS network observation | Coarse offline/path/reachable indication | Local native observation | Transient state | Does not establish service connectivity or authentication |
| External help and user-selected links | Open official help or external URL through OS browser | Selected external website/browser | External service policy | Native URL policy; website browsing data is not copied into shell diagnostics |
| Native dependencies | Flutter/Riverpod/SVG/intl plus native platform libraries | No native analytics, ad, crash-upload or replay provider configured in current code | SDK/platform-specific behavior | Review complete dependency/license/advisory inventory and actual signed build; OS/vendor collection is not an invented app-owned backend |
| Public support/privacy hosting | Not deployed | **UNKNOWN until host chosen** | **UNKNOWN** | Hosting access logs, cookies, analytics and contact workflows require a separate inventory once selected |
| Support email/contact submissions | No app-owned support inbox/automatic send configured | **UNKNOWN until operator supplies contact** | **UNKNOWN** | Never request QR/session exports; define recipient, purpose, retention and deletion route before publishing |

Relevant source: [native Android engine](../packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/AndroidSessionEngine.kt), [native Android registry](../packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt), [iOS registry](../packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift), [iOS transfers](../packages/session_engine/ios/session_engine/Sources/session_engine/NativeTransfers.swift), [iOS diagnostics](../packages/session_engine/ios/session_engine/Sources/session_engine/NativeDiagnostics.swift), and [threat model](THREAT_MODEL.md).

## Apple App Privacy worksheet

Apple distinguishes data processed only on-device from collection and requires assessment of embedded web traffic unless users are navigating the open web. This purpose-built official-origin workspace should not assume that exception. A public privacy-policy URL is required. These are current policy observations checked on18 October2026; final data categories depend on verified service/SDK behavior. [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

| Console topic | Candidate assessment from current evidence | What must be resolved before final answer |
| --- | --- | --- |
| Data collected? | **PENDING; do not select “Data Not Collected” based on the native shell alone** | Inventory service traffic/retention and applicable partners in the approved test context |
| Local alias/preferences/restore proof | Native-only paths observed; no app-controlled off-device transmission | Verify exact signed build and any future backup/support/analytics addition |
| Messages / photos / documents | Candidate categories for actual website communication; native registry does not store message copies | Map current service collection, purposes and retention; do not infer from end-to-end encryption alone |
| Account identifiers / phone/contact details | Native alias is not verified identity; website account data remains a possible disclosure surface | Determine categories actually collected by service traffic and whether linked to the user |
| Diagnostics / customer support | Optional OS share export exists, with destination selected by user | Determine whether the eventual operator receives/stores reports and whether any optional-disclosure criteria actually apply |
| Data linked to user | **PENDING per data type** | Account/service identifiers can link website data; native random IDs alone do not settle this |
| Tracking | No native tracking integration configured | Evaluate actual service/SDK use under Apple's definition; no unsupported global no-tracking assertion |
| Collection purpose | Native management/lock and intended communication are functionality | Record purposes separately for each actual receiving service/partner; not all website uses are known |
| Privacy manifest | Native module declares its own inspected behavior | Empty native collected-data arrays do not complete or replace the app-level website privacy label; validate all manifests/required-reason APIs in final build |
| Privacy choices / deletion | Local removal and primary-app remote unlink are different controls | Supply real policy/contact URLs and clearly distinguish local sessions, exported files and remote service data |

The category suggestions are engineering inferences from the feature design and code, not claims that the relevant service collection has been observed. The current Apple console form must be completed only after the open facts have been established.

## Google Play Data safety worksheet

Google includes SDK transfers and has a specific WebView code/behavior condition and an open-web exception. Record the applicability analysis for this fixed-origin wrapper; it is not a general browser. User-initiated transfer exceptions to “sharing” do not automatically settle collection or other website transfers. The developer remains responsible for accurate answers. [Google Play Data safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)

| Console topic | Candidate assessment from current evidence | What must be resolved before final answer |
| --- | --- | --- |
| Collection and sharing scope | **PENDING** for embedded website; native app-owned messaging server absent | Document whether the wrapper controls delivered WebView code/behavior, all relevant recipients and the reason for each inclusion/exclusion |
| Personal information / identifiers | Local labels/IDs stay in app-owned storage; website account metadata unverified | Actual service categories, account linkage and purpose |
| Messages / photos / files | Native original-view upload exists; service transmission requires actual validation | Determine collection/sharing, required versus optional behavior and retention by type |
| Device/other IDs / app activity | No native ad/analytics SDK configured | Evaluate website and final dependency behavior; absence of native analytics is not whole-app proof |
| Diagnostics | Explicit OS share of allowlisted technical text | Identify final recipient and test reasonable user expectation/exception applicability; do not apply a blanket exemption |
| Ephemeral processing | Native staging is temporary but service retention unknown | Do not classify all transmissions as ephemeral; prove each relevant recipient's processing/retention |
| Encryption in transit | Native production HTTPS policy rejects cleartext/TLS bypass | Validate actual complete traffic and service flow before any whole-app declaration |
| Deletion | Local cleanup controls exist; account creation is not implemented by this shell | Determine relevant current account/deletion form answers from the final account model; link service controls separately |
| Optional/required | Selection is user-controlled; intended messaging requires service data | Answer per type and for all supported users/regions; do not infer optional simply because access needs linking |
| Privacy policy | Draft content exists | Final operator, active URL, website recipients, retention, user controls and app link remain needed |
| Ads / target audience / content rating | No native ads or payments; audience/ratings not selected | Assess final delivered web content and choose truthful owner-approved declarations |
| Restricted app access | Real core feature needs linked-account approval | Supply reproducible review access/instructions, not an expiring QR or a synthetic substitute |

Google's app-content workflow covers privacy policy, ads, audience, ratings and restricted access instructions. The final app and listing need the actual completed values, rather than the pending worksheet. [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)

## Reproducible reviewer procedure

**Current status: prepared procedure, not yet executable.** Do not submit until the actual service/physical-device gates and Android required-media gap are resolved. The release owner must arrange permitted review access with approved test accounts and an available primary-device approval method. Account owners, pairing devices and recipients are absent from this local workspace; none are invented here.

Apple requires review access to the real feature, meaningful native utility and truthful metadata. Its rules also address dependence on another app; explain the official primary-app requirement explicitly. A proposed demo cannot silently replace the actual product, and an alternative demo route may need prior approval. These remain review risks, not guaranteed exceptions. [Apple App Review Guidelines, 2.1, 4.2 and 4.2.3](https://developer.apple.com/app-store/review/guidelines/)

Google's WebView policy calls for permission from the website owner or administrator. A tester's QR approval does not supply that distribution evidence. [Google Play Webviews policy](https://support.google.com/googleplay/android-developer/answer/9899034?hl=en)

1. Release owner supplies the exact signed candidate, supported device/provider matrix, active support/privacy URLs and permitted-use evidence. Record the build identifier and hash privately with the review package; public docs must contain no test-account credentials or session exports.
2. Provide reviewers with a supported way to use the dedicated authorized test accounts and primary devices throughout review. Complete a fresh-device rehearsal with someone who did not build the app. If reliable access cannot be arranged, keep submission blocked and obtain an accepted review arrangement before proceeding.
3. Launch a fresh installation. Confirm welcome/foreground limitations, then Add account. Verify capability checks before profile allocation. On unsupported Android providers, the app must explain incompatibility while management/help remain available.
4. Enter fictional alias “Studio”. In the official primary app choose Linked devices → Link a device and approve the QR shown inside this app. Do not upload, retain, email or forward QR/codes to establish access. Verify the account identity in the official page, then use the host's explicit confirmation control. The alias is a label, not app-verified identity.
5. Repeat with fictional alias “Personal” and a second specifically authorized account. Switch using the native selector, verify the displayed service identity, rename/reorder profiles, and verify storage remains bound to the original profile. A ten-account claim additionally requires the full approved ten-account evidence, not this two-account walkthrough alone.
6. With specifically consenting test recipients, manually send a fictional text, photo and document through the actual website. Verify the real supported download/save/share path and cancellation on each platform. This step is blocked for the current Android candidate; no workaround using exported cookies or page scraping is allowed.
7. Open the native privacy screen, enable OS-backed lock on a device with authentication configured, background and reopen, then test cancellation. The account content remains covered until authentication succeeds. Confirm the actual device's app-switcher behavior.
8. Remove “Studio” locally through its named confirmation, verify blocked access and completion/retry status, and confirm “Personal” still opens. Explain that local removal does not remotely revoke the linked device; use official primary-app controls to revoke it separately. Check empty state after removing the remaining test profile.
9. Open Help/compatibility, inspect capabilities, and generate the technical diagnostic summary through system share only to the authorized review destination. Verify it contains no alias, phone number, QR, message, URL or private file path.
10. Reviewer/QA records actual results, device/provider/build and relevant acceptance IDs. Release owner preserves redacted technical evidence and performs approved test-account revocation/cleanup. No recipient is messaged merely because it appears in the account's contacts.

**Draft reviewer note:** Profile Desk is a one-operator foreground companion workspace using isolated persistent browser profiles. It has no app account registration or messaging backend. The native utility is profile organization, stable isolated storage, one-view switching, device lock/covers, local cleanup and compatibility/support controls. Linking requires the official primary application and account-owner approval. Please use the approved review access arrangement supplied privately. Inactive profiles are not monitored. The exact supported media/device matrix and known limitations are attached. The synthetic isolation harness and fictional screenshot fixtures are development-only and are absent from production.

This reviewer note cannot truthfully be sent as a completed submission until the required access arrangement, service permission, media support and evidence exist. Keep the current draft limitation paragraph in the internal package until then.

## Release package closure checklist

- [x] Concrete truthful listing draft and internal release note prepared.
- [x] Native/server/website/system-share data-flow worksheet prepared from source.
- [x] Current Apple/Google disclosure and review guidance checked from primary sources on18 October2026.
- [x] Fifteen labeled fictional shell previews and two finite motion previews, screenshot subjects, caption draft, provenance boundary and real-feature dependencies prepared.
- [x] Real reviewer procedure, independent rehearsal requirement and safe test-data handling specified.
- [ ] Final original name, legal operator, real support contact, regions/audience and approved privacy policy/URLs supplied.
- [ ] Website recipients, code/behavior analysis, actual collection/purposes/retention and linked/tracking classifications verified.
- [ ] Final console disclosures, required-reason API/SDK review and content/ads/audience ratings completed against signed build.
- [ ] Actual supported service/physical-device/retention/media acceptance evidence complete; Android required download gap resolved.
- [ ] Accurate release-build screenshot set captured and reviewed; previews are not passed off as service evidence.
- [ ] Provider/distribution basis and workable real reviewer access established.
- [ ] Signed artifacts, owner-approved submission channel, staged rollout and explicit release authorization ready.

No external publication, privacy-policy hosting, account acquisition, outgoing message or app-store action was performed while preparing this package.
