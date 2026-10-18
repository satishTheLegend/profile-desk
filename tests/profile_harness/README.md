# Same-origin profile storage harness

This fixture writes **synthetic markers only** to cookies (including a server-set HttpOnly cookie), localStorage, IndexedDB, CacheStorage and storage written by an active service worker. Every profile must use the **identical HTTPS origin**, including port. Different hostnames or paths do not prove native profile isolation.

Run the server with an existing test certificate trusted by the device and a matching private key:

```sh
python3 tests/profile_harness/server.py --cert /private/test-cert.pem --key /private/test-key.pem
```

The default listener is `127.0.0.1:8443`. For a physical device, specify the development machine's reachable LAN address with `--host`; the certificate's SAN must cover the hostname or IP used by that device. Keep keys outside the repository. Provision a dedicated test CA/certificate using your normal device-lab workflow. Trust it in the QA test environment; do not bypass TLS validation or change production transport security. The server has no plaintext fallback, and requires TLS 1.2 or newer.

For the Android emulator fixture, `python3 tests/profile_harness/create_test_certificate.py` creates a private temporary directory containing an ephemeral two-day CA and server certificate. It prints their paths, never key material. Trust **only the public `ca.pem`** through the dedicated instrumentation application's `network_security_config`; Android emulator host routing uses `https://10.0.2.2:8443`. The certificate also covers localhost and 127.0.0.1. Regenerate it on each test run and remove the temporary directory afterwards. Do not put private keys or this CA trust configuration in a production application.

Use only the QA application identity and controlled native harness build. Never inject this origin into the production workspace path. A desktop browser can check the fixture itself, but it does **not** verify AndroidX or WebKit named-store behavior.

## Procedure

1. Start with a clean QA installation and reconcile its registry before opening profiles.
2. Create profile 1. Set the expected marker to `synthetic-01` and select **Verify existing storage** before writing. Record `EMPTY` for all six stores.
3. Write the marker, then verify `MATCH`. Repeat through profile 10 with `synthetic-02` … `synthetic-10`.
4. Switch between all ten profiles, including rapid switches. Verify the native alias and expected marker agree. A `MISMATCH` is a failed isolation/binding test; preserve the report before changing storage.
5. Terminate/relaunch the QA app, restart the device, and repeat verification. Record each action and timestamp separately.
6. Remove profile 5 using the native account manager. Let cleanup finish or report its actual pending stage. Verify that profiles 1–4 and 6–10 retain their markers. Add a replacement with a new identity, verify `EMPTY`, and then seed it.
7. Test inactive cleanup: start removing B, switch A → C, and confirm B's journal completes without changing C. Repeat when required provider capabilities disappear and later return.
8. Repeat with a service worker active, process termination at each cleanup stage, disk pressure and provider updates. **Run 4-second worker write burst** keeps an extendable message event writing synthetic CacheStorage data for a bounded four seconds; trigger native removal immediately during that interval. Native instrumentation may invoke `workerMessage("burst", "synthetic-05")` without awaiting its completion before removing the fixture profile. Verify after the write window has elapsed. Native instrumentation must verify quiescence and final store inventory; this webpage alone cannot observe destroyed stores or prove forensic erasure.
9. Save the displayed synthetic JSON and safe device/build/provider information into the test evidence record. A real 7-/14-day retention check needs dated observations separated by those elapsed periods.

**Clear fixture storage** resets only fixture data in the current origin. It is a convenience for fixture development, not evidence that native account removal works. Reading empty storage may initialize an empty database and register the fixture worker, so do not reopen a production tombstoned store for deletion verification.

## Automated fixture checks

```sh
python3 -m unittest discover -s tests/profile_harness/tests -v
node --check tests/profile_harness/web/app.js
node --check tests/profile_harness/web/worker.js
node --check tests/profile_harness/web/transport.js
```

Server unit tests exercise handler policy over an in-process loopback HTTP server. The executable server always requires HTTPS. These checks do not count as native profile-isolation acceptance evidence.

## HTTP cache, WebSocket and synthetic file fixtures

Open `/transport/page` on the **same scheme, host and port in every native profile**. This additional route serves the storage fixture with `/transport.js` preloaded and a CSP that explicitly permits WSS to that exact host. The original `/`, `app.js`, `worker.js` and six-store behavior are unchanged. Restart the test server or start an independently owned test listener after updating its source; an already running Python process retains its earlier handlers.

The helper is `window.ProfileDeskTransport`. The server retains no cross-request account or marker table. Only validated synthetic markers from the request's `harness_http_only` cookie are returned. Requests are not logged.

| Endpoint | Semantics |
| --- | --- |
| `GET /transport/cache` | Fixed URL; requires bounded `X-Probe-Nonce`. Returns the cookie-derived marker and that nonce, with `Cache-Control: private, max-age=600`. Deliberately no `Vary: Cookie` or `Vary: X-Probe-Nonce`: header partitioning must not conceal shared profile caches. Queries are rejected. |
| `GET /transport/socket` | Same-origin WSS, version 13, subprotocol `profiledesk.synthetic.v1`. Initial identity and echo responses carry the handshake's HttpOnly-derived marker. Only synthetic text tokens and bounded control frames are accepted. The test implementation accepts unfragmented masked frames, at most 1 KiB payload, 16 frames and 15 seconds per connection; it is not a general WebSocket service. |
| `GET /transport/download` | Cookie-derived synthetic document, fixed safe filename, digest and marker headers; no-store. Requires a seeded fixture cookie. |
| `POST /transport/upload` | At most 64 KiB, `application/octet-stream`, same Origin, exact synthetic file format and a marker matching the request cookie. Returns byte count and digest. Does not retain the body or write files. Real/unrecognized files are rejected. |

Prime profile A's cookie using the existing `cookieMarker("synthetic-a", true)` fixture, then run:

```javascript
await ProfileDeskTransport.cacheProbe("synthetic-a", { cache: "reload" });
// Expect MATCH and cacheHit=false: the network response echoes this request's nonce.
await ProfileDeskTransport.cacheProbe("synthetic-a");
// Expect MATCH and cacheHit=true: the cached response retains the earlier nonce.
await ProfileDeskTransport.websocketProbe("synthetic-a");
// Expect MATCH for handshake identity, echoed identity and the exact random token.
await ProfileDeskTransport.fileProbe("synthetic-a");
// Expect MATCH for cookie owner, byte count and SHA-256 after download/upload.
```

In profile B, set `synthetic-b`, then call `cacheProbe("synthetic-b")` **without reload** first. Expect MATCH and a miss, followed by a MATCH/hit on repetition. Reopen A and verify its marker/hit. A cache result that reports B's marker is a failure. A repeated miss is inconclusive for cache isolation because it lacks the same-profile positive control; do not mark it passed. `cacheProbe(null)` can verify an empty cookie/cache state before seeding a fresh replacement, subject to the native test's store-lifecycle rules. HTTP cache observations are distinct from CacheStorage in the six-store suite.

`websocketProbe(expectedMarker)` checks one bounded connection. Run it in both named profiles with their distinct cookie markers. Its returned token is generated per call; the server's echoed marker comes only from that connection's cookie, not a body-supplied identity. These browser probes require successful native execution before becoming native isolation evidence; server unit tests alone establish protocol policy.

`fileProbe()` uses fetch and Blob upload. It does **not** exercise a native document picker, WebKit download delegate, OS destination chooser, cancellation, progress UI or a real service attachment. To expose explicit synthetic controls, call `ProfileDeskTransport.installFileControls()`, then operate `#transport-download` or `#transport-upload` through the native UI. The latter records its bounded result in `ProfileDeskTransport.lastFileResult`; native callback ownership and cancellation still need their own assertions. Upload only a document generated by this fixture for the selected profile. A previous profile's file is rejected on marker mismatch.

The transport suite currently adds ten server tests, for 17 fixture policy tests total. It checks fixed cache URL/headers, absence of retained server marker state, bounded file ownership/content, the separate CSP page, WebSocket handshake/identity/echo/ping/close, and rejection of foreign origins, malformed handshakes, unmasked/oversized/non-synthetic frames. Native device results belong in the platform evidence ledgers, not this unit-test count.
