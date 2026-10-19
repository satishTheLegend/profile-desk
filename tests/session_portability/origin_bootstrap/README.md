# Empty-origin bootstrap capability probe

This standalone Simulator fixture tests whether public `WKWebView.loadHTMLString`
can initialize a declared app-bound HTTPS origin before any remote client is
loaded. It uses the literal `https://bootstrap.profiledesk.invalid/`, inert HTML
with a restrictive CSP, a blocking content rule, no external references, and only
fixed app-owned test JavaScript. There is no fixture server or network load.

```sh
python3 tests/session_portability/origin_bootstrap/run.py
```

Reserve the native build/Simulator slot before running. The runner builds one
ordinary minimal Xcode Simulator app, creates one disposable Simulator, and
never selects a physical device. Commands have 60-second deadlines. Each WebKit
operation also has a native deadline. Origin, location, base URI and secure
context must actually match; an opaque origin or `about:blank` is reported as an
unsupported result, without substituting another navigation technique.

Two independent named data stores start empty. Each native data-store object is
retained across fresh-view checks, so replacing a view does not also change the
native store-session lifetime. The source stores fictional
typed data and a nonextractable AES-CTR key. Only fictional plaintext values
cross an in-memory native transfer; the destination generates its own key and
encrypts once with that key/counter. Fresh WebViews verify LocalStorage and typed values,
nonextractability and source preservation. App termination and an owned
Simulator reboot precede separate cold destination/source processes. Cleanup
removes only the recorded owned stores and content-rule identifier. Every phase
first creates an inert nonpersistent WebView to initialize WebKit's UI run loop;
the cold-process isolation claim applies to named persistent stores.

Reports contain statuses, counts, digests, process IDs and source/build hashes;
no payload, key, ciphertext or transfer bytes are persisted in reports. Store
UUIDs are private fixture ownership metadata in the disposable app container.
No official WhatsApp source, origin, account, session or worker is loaded.

A pass establishes only this empty-origin synthetic restore capability. It
does not establish a consistent capture boundary, safe shutdown of existing
WebKit workers, service state coverage, authenticated restore, or a production
archive format. A failure must retain the exact failed capability and must not
be treated as a service-session limitation.
