# Diagnostic lab review

18 October 2026. Independent source review, followed by focused verification of corrections. No device, real account or service inspection was part of this review.

The initial review found three defects, now corrected:

1. A queued scan could begin after background/navigation invalidation. Native generation, active-scene, current-view, origin and loading checks now run immediately before JavaScript invocation.
2. A new scan could reset the previous scan's shared cancellation Boolean. Each scan now captures a unique token; cancellation and cleanup target only the matching token. Synthetic overlapping-scan checks verify that older work cannot resume or cancel newer work.
3. A build could copy resources from mutable sources after checking their hashes. Compilation now uses staged captured bytes, and packaging uses captured JS/plist bytes with final equality checks.

Additional hardening includes a generation-checked twelve-second native watchdog that discards late results and releases the controls. The script's scan limits remain cooperative: record deserialization can precede a traversal check, and a stalled WebKit process cannot be given a strict memory/execution bound by this watchdog. The wording no longer promises a hard stop. A native desktop viewport fit prevents the earlier narrow-screen clipping pattern without changing page zoom or reading page contents.

Reviewed boundaries: exact HTTPS origin, main frame, isolated world, no generic message bridge, readonly IndexedDB access, fixed counts/reason schema, no credential/content logging or exporting, and removal limited to the lab's own recorded UUID. Complete type scans explicitly do not prove session portability.

Final classifier evidence passes 31 checks and matches the current classifier and test-runner SHA-256 values. Native lifecycle/watchdog behavior was reviewed in source and compiled; it has not been exercised on a physical device. These results do not establish a working session archive or successful WhatsApp login restoration.
