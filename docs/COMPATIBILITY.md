# Verified compatibility and remaining coverage

Evidence date: 18 October 2026, Asia/Kolkata. This matrix reports the configurations actually exercised. Deployment minimums are source configuration, not a promise that every device at that minimum has passed.

| Environment | Observation | Scope |
| --- | --- | --- |
| Android API35 emulator, arm64, Google WebView124.0.6367.219 | Required scoped browsing-data deletion absent; production allocation rejected before creating a profile | Correct unsupported-provider handling; isolation scenario blocked |
| Android API36 emulator, arm64, Google WebView133.0.6943.137 | Ten-profile six-store fixture, 200 selections, renderer recovery, middle removal, empty replacement, normal-lifecycle process/reboot retention and deferred deletion passed | Synthetic native evidence; SharedWorker unavailable on this provider; see ANDROID_EVIDENCE.md |
| iOS26.5 iPhone17e simulator | Real Flutter QA shell cold launch, allocation, official URL open, disposal, keep-setup and scoped removal passed | Integrated native bridge/lifecycle; no pairing or page extraction |
| iOS27 iPhone18Pro simulator | 81-assertion ten-store fixture, 200 selections, six mechanisms, scoped deletion/replacement, BroadcastChannel and SharedWorker isolation; normal-lifecycle process/reboot retention and isolated Flutter/native QA passed | Hosted synthetic WebKit evidence; earlier unexplained immediate-termination mismatch retained; see IOS_EVIDENCE.md |
| iPhone17ProMax, iOS26.6.2, physical device | Reproduced clipped page and Safari15+ warning. A real980-point native WebView viewport scaled to440 available points fits the whole compatibility card. Standard Safari-compatible identification reaches the download landing with Continue in browser | Preauthentication comparison only; user approved identification trial is enabled only for the exact development bundle. Branded suffixes still failed. See `evidence/ios/viewport/physical-browser-comparison.json` |
| Android API29 minimum, OEM/low-memory phones, physical Android tablets | No physical devices available | Pending device matrix; API29 Robolectric tests do not replace it |
| iOS17 minimum, older/smaller physical iPhone, physical iPad | No physical devices available | Pending minimum/current device, keyboard, resizing, accessibility and lifecycle matrix |

## Implemented feature boundary

| Feature | Android | iOS |
| --- | --- | --- |
| Profile registry, ten-slot reservation, stable identity and scoped local deletion | Implemented; provider feature gate; loaded containers deferred until next process | Implemented with persistent named stores and retryable public deletion |
| Foreground workspace and selector | One production WebView, dispose/recreate on switching | One production WebView, dispose/recreate on switching |
| Photo/document selection | System document picker, callback bound to original view | Native picker, private staged bounded copy, original-view and transfer-token ownership |
| Downloads/save/share | Explicit unsupported event; essential authenticated/blob download remains OPEN_RELEASE_GAP | WKDownload with private staging, progress, cancellation and OS share; actual-service validation pending |
| Camera, microphone, voice and calls | Disabled | Disabled |
| App lock and privacy cover | OS authentication, lock epochs, native cover, FLAG_SECURE | OS authentication, lock epochs, native view and full-window covers |
| Network indication | OS default path with validated internet capability | OS path availability; does not establish internet/service reachability |
| Background notifications and inactive unread counts | Not promised; inactive pages disposed | Not promised; inactive pages disposed |
| Live account pairing/text/media compatibility | Not tested | Not tested |
| Phone chat-list/detail presentation | Bundled structural adapter; synthetic browser checks pass; authenticated provider behavior pending | Same adapter in isolated WebKit content world; native viewport validation tracked in new feature evidence |
| Account setup export/import | Native document flow, bounded metadata schema and fresh profiles | Native document flow, bounded metadata schema and fresh profiles |
| Preserve signed-in sessions in an archive | Unsupported by verified public profile API | Unsupported: current iOS26 store archive supports LocalStorage only |

The latest phone-layout change retains the earlier desktop fit as **Original layout** and as iOS's preauthentication fallback. Recognized narrow layouts use actual host width and a bundled presentation-only script. iOS runs it in a separate WebKit content world and checks only a fixed structural-availability boolean; Android uses fixed trusted-page commands without a native message bridge. The adapter reads structural presence/geometry and viewport configuration, never conversation text, HTML, identities, input values or storage. Synthetic browser evidence covers list/detail/menu/overlay behavior and exact style restoration; authenticated service selectors remain unverified. See [design and limitations](PHONE_LAYOUT_AND_ACCOUNT_TRANSFER.md) and [fixture procedure](../tests/workspace_layout/README.md).

Actual pinch together with the software keyboard, physical rotation, VoiceOver and the authenticated composer remain unverified. The earlier viewport fixture showed WebKit resetting a programmatic scroll zoom after asynchronous height resizing; the implementation still leaves native pinch to WebKit and does not use `pageZoom` to infer content width. Earlier physical desktop-fit evidence remains historical and does not prove the new phone adapter works with every WhatsApp pane.

The development-only Safari identification uses WebKit's own desktop identity plus a standard version suffix through `applicationNameForUserAgent`; application code never assigns `customUserAgent`. On the tested simulator that getter returned an empty string, while the owned fixture's `navigator.userAgent` reported the correct full desktop identity; a nil getter is therefore not used as a correctness condition. All31 viewport/identity assertions pass; earlier timeout and incorrect-getter-assumption failures remain in the evidence directory. The suffix is a compatibility policy, not a claim of complete Safari feature parity. QA and production keep the original browser identity and therefore still have an unresolved actual-service compatibility gate. No linking or messaging success is inferred from the download landing.

No authorized service accounts or recipients were available. No messages were sent and no QR/pairing/session values were retained. Retention runs have not started; seven- and fourteen-day evidence requires actual elapsed observations. Network transitions, disk pressure, restore/reinstall, signed migration, system picker interruptions, biometric enrollment/lockout, and assistive-technology task flows remain in the device procedure and acceptance ledger.

## Performance interpretation

Native fixture switch timings include navigation and storage verification. They do not measure the selector's response, cover transition, or real website readiness. Emulator/simulator host-only memory samples exclude web-content processes and do not establish leak freedom, battery use or a physical-device baseline. The plan's provisional p95 targets (selector150ms, shell2s, covered target300ms, website5s) remain unverified until their specific intervals, device/network conditions and sample sets are measured. One-live-view ownership is separately tested; no universal memory limit is invented.

Use `tests/device_flows/README.md` and all70 rows in `acceptance.csv` to complete the matrix. Keep failing/unsupported outcomes and their exact provider versions when later configurations pass.
