# Session-preserving restore verification

Updated 19 October 2026. **Result: requirement not met; further product deployment is on hold.** The owner approved the separate Session Lab diagnostic app; that exception does not satisfy or remove the product gate. On 19 October 2026 the owner explicitly retained the restored-session requirement when offered an exception for tested UI build 5. Deployment and the requested subsequent Mac shutdown remain held.

The user's clarified requirement is: link WhatsApp Web by scanning its QR code, export a backup, restore that backup into the application, and remain logged in without scanning again. Account setup transfer does not satisfy this requirement. This is now an explicit deployment gate, not an optional future enhancement.

## What the current code does

| Data or behavior | Current result |
|---|---|
| Account names, colors, order, appearance | Exported and imported |
| Cookies, login credentials, browser databases and application keys | Not exported |
| Conversations, attachments or media | Not exported |
| Original browser profile identity | Not exported or reused by import |
| Imported browser profile | Fresh identity and empty store, authentication observation `unknown` |
| Restore without QR linking | Not implemented or verified |

The schema requires `requiresRelinking: true` and rejects additional fields. See [shared codec](../packages/local_registry/lib/src/account_setup_archive.dart), [iOS registry](../packages/session_engine/ios/session_engine/Sources/session_engine/ProfileRegistry.swift), and [Android registry](../packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/NativeRegistry.kt). The iOS and Android native import methods allocate new browser stores. Existing destination profiles are preserved, but opening an old retained profile is not proof that a backup restored its login.

An independent read-only source review confirmed these paths. The seven focused Dart archive/facade tests were rerun and passed, including rejection of credential fields and creation of profiles with unknown authentication. [Rerun log](evidence/phone-layout-transfer/session-restore-dart.log). Existing native tests explicitly assert fresh identities and unknown authentication. These passes establish setup-transfer behavior; they do not establish signed-in restore.

## Platform feasibility recheck

- iOS 26+ exposes public serialized data APIs. Current [WebKit implementation](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebsiteDataStore.mm) accepts only LocalStorage in `WKWebsiteDataStore.fetchDataOfTypes`, returning an error for other types. The installed Xcode SDK's `WKWebViewDataType` exposes SessionStorage only. These APIs do not supply a complete browser-profile backup. [Apple API reference](https://developer.apple.com/documentation/webkit/wkwebsitedatastore/fetchdata(of:completionhandler:)).
- The project's AndroidX WebKit 1.17.1 AAR was inspected using `javap -public`: `Profile`, `ProfileStore` and `WebStorageCompat` provide profile access/creation/deletion and scoped managers, without a complete serialized profile export/restore operation. [Archived public API inventory](evidence/phone-layout-transfer/session-restore-android-public-api.txt), [Profile reference](https://developer.android.com/reference/androidx/webkit/Profile), [ProfileStore reference](https://developer.android.com/reference/androidx/webkit/ProfileStore).

Updated inference: the verified public APIs do not establish a complete browser-profile archive. This does not rule out a sufficient application-specific authentication subset; that possibility is now being tested in the [session-backup implementation work](SESSION_BACKUP_IMPLEMENTATION_PLAN.md). Cookies or LocalStorage alone cannot be treated as a complete archive. No claim is made that session migration is universally impossible, that every WhatsApp key is hardware-bound, or that a future platform API cannot change the result. The original API recheck accessed no real WhatsApp storage or credentials.

The later owner-operated [Session Lab build3 report](evidence/session-portability/lab-v3/physical-storage-observation.json) supplies counts only from its separate test profile. It observed two nonextractable AES-CTR secret-key occurrences, permitting encrypt/decrypt, within 61 fully visited and 3 sampled stores; 82 discovered stores were skipped. The classifier inspects value types transiently and returns no record contents or key material. Standard key export rejects these observed key objects, but their authentication necessity remains unknown. Neither this partial scan nor its zero change/error counters establish a sufficient archive or consistent snapshot. No actual credential archive or independent restored login has been demonstrated.

The subsequent static public-client review establishes a narrow semantic migration candidate: Signal registration identity bytes are independently encrypted under local nonextractable AES-CTR keys, and the official read path decrypts them. A destination can generate fresh local wrappers instead of exporting the original keys. The [synthetic native proof](evidence/session-portability/registration/README.md) passes 125 assertions, including thirty invalid-input controls, after independent cold process/reboot with source preservation. Additional HKDF, Noise, preference and encrypted application state prevents treating this narrow format as a complete session. No real-profile values were read by this research. See [the current unified checklist](PROFILE_DESK_NATIVE_EXPERIENCE_PLAN.md).

A further [empty-origin capability probe](evidence/session-portability/origin-bootstrap/README.md) passes 138 assertions. Public `loadHTMLString` can initialize the declared HTTPS origin's synthetic LocalStorage and IndexedDB before any remote client loads; the destination survives independent process restart and an owned Simulator reboot. The original nonextractable key is never exported. This establishes a destination primitive, not complete session restoration. The [latest source review](evidence/session-portability/state-boundary-review/README.md) maps Worm encryption to pending-action queues and identifies replay, runtime identity and all-writer consistency gaps. No actual credential archive or restored login has been demonstrated.

## Required completion gates

1. Establish a supported way to serialize and restore every item of state required for authenticated cold-start restore. A complete browser-profile archive is not essential if a reviewed smaller subset is proved sufficient. Required nonexportable or origin-bound keys remain a conditional blocker; WhatsApp's actual required key representation is not yet verified.
2. Design an encrypted, versioned archive with bounded parsing, key recovery, compatibility checks, staging and rollback. The current readable setup JSON must never carry credentials.
3. Restore into an independent empty destination profile while preserving the source. Reusing the original store or retaining it alongside a new import is not a valid restore test.
4. With the account owner's authorized test session, verify authenticated access after restore and a cold restart without QR/code linking, account isolation, and expected behavior after service-side logout/revocation. Record only status evidence, never conversation or credential contents.
5. Verify the accepted device/OS combinations and document remaining limits. Do not imply Android/iOS cross-platform portability from a same-device pass.
6. Deploy only after the user's session-retention requirement is demonstrated, or after they explicitly change that condition.

## Deployment state

Build4 was installed during the earlier authorized deployment; that historical fact remains unchanged. The subsequent deployment request was interrupted before any new install or launch. This verification performed no install, launch, uninstall, reset, linking or message action. Further deployment is held by the user's clarified acceptance condition, not a skill approval requirement.

Under the later explicit diagnostic exception, Session Lab build3 was installed and foreground-launched. The complete installed-app record for Profile Desk matched before/after and remains build4. Capturing the owner-operated report did not modify either app, clear storage or export credentials. The product deployment condition remains unmet.
