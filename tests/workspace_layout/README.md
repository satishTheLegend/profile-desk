# Owned mobile layout fixture

Run from the repository root:

```sh
node tests/workspace_layout/run.mjs
```

Node 22+ and a local Chrome executable are required. Set `CHROME_PATH` if Chrome
is elsewhere. The optional first argument chooses the evidence directory.

The dependency-free runner launches its own headless browser with a disposable
profile, blocks DNS resolution, and intercepts every page request before sending
an owned HTML response. `https://web.whatsapp.com/` is a **synthetic document
origin** in these tests; no WhatsApp response, account, session, message, or QR is
loaded. It uses a dedicated isolated JavaScript world to exercise the exact
production origin gate and real trusted browser clicks. The page cannot access
the adapter's control object. Ordinary HTML, text, input, storage, and network
accessors are blocked in that world to catch accidental content access.

Checks cover initial list and rail, trusted row selection, same-chat reselection,
native Back, composer input, search and menu exclusions, a known-side settings
replacement with a real user-operated Back control, responsive side images, a portal dialog,
full-row primary buttons versus popup accessories, nested/edge-positioned dialogs,
attribute-only structural changes and observer-loop prevention,
untrusted clicks, reduced motion, width/height changes, absent/duplicate structural
hooks, asynchronous detail creation, restoration, repeated installation and
disposal, origin/port/subframe gates. Screenshots and the JSON result use only
fictional fixture content. The fixture intentionally contains readable 16px text;
these checks establish that the adapter preserves that size rather than scaling
a desktop page down.

## Static adapter contract

Source: `packages/session_engine/layout/workspace_layout.js`.

Install the unchanged resource in a dedicated isolated world, main frame only,
after a document exists. It starts inactive. Native integration must separately
provide actual phone-sized native bounds. After recognizing the structure, the
adapter saves the existing viewport meta content (or absent-tag state) and uses
`width=device-width, initial-scale=1`. This nonprivate layout configuration is the
only service attribute value retained, solely for restoration. Original mode,
disposal, and unknown layouts restore it without overwriting a newer service
change. No user agent, `pageZoom`, or native view geometry is changed by this script.
Execute only the following fixed expressions in the same isolated world:

```js
__profileDeskLayout.setMode('phone')
__profileDeskLayout.setMode('original')
__profileDeskLayout.supportsStructure()
__profileDeskLayout.showList()
__profileDeskLayout.dispose()
```

The structural probe returns only a boolean and works independently of current
viewport width. Other commands return only `{mode, state, available, reason}`.
States are `original`, `list`, `menu`, `detail`, or `unavailable`. Reasons are bounded structural
failure codes, never service text or identifiers. No general-purpose web/native
message bridge exists. The native caller must validate its exact current view
handle and lifecycle before each command, and use only fixed commands. Native
privacy covers retain authority; this script neither changes nor signals them.

`phone` is active for 320–600 CSS-pixel layout viewports. It starts on the list,
keeps the navigation rail where one can be unambiguously identified, and changes
to detail after a **trusted** click within a `role=row` or `role=listitem` under
`#pane-side`. Interactive controls, menu items and dialogs are excluded, except
an unambiguous full-row primary button without a popup declaration. A valid
`#main` must exist, including when created shortly after the original service
click. The original event is not canceled, replaced, replayed, or synthesized.
When the service replaces only the list inside an already validated, connected
`#side`, the same shell/side/rail ancestry can remain in readable `menu` mode.
This is permitted only for the exact previously validated nodes; unknown side
replacements, ambiguous IDs, or changed ancestry fall back. Native `showList()`
does not close such a service panel. Its own user-operated Back control restores
the chat list. Calling `setMode('phone')` again preserves an active recognized
pane rather than resetting it.
`showList()` changes presentation only; it does not operate service navigation,
close a service dialog, remove a draft, or infer that a message was sent.

Only known structural IDs, roles, ancestry, dimensions, connection state and the
viewport meta layout configuration are inspected. The script never reads text,
HTML, titles, input values, chat/contact
identifiers, storage, credentials, QR data, or network data. Its own generated
style string contains fixed CSS and a bounded rail-width measurement. All own
classes and style nodes are removed in original mode and on disposal; existing
service classes and inline styles are preserved. Presentation changes are
immediate with no adapter animation.

## Limits and remaining checks

These structural selectors are **unverified against authenticated WhatsApp**.
There is no supported service DOM contract. Unrecognized or ambiguous hooks remove
all adapter styling and restore viewport metadata. A matching structure
can recover after replacement; native UI must retain an explicit Original view
escape regardless. Unknown positioned ancestor wrappers also fall back instead
of guessing their dimensions. Generic overlay checks cover the fixture's portal
dialog, nested dialog, edge position, list menu and retained-side settings panel.
Only overlays visible in the service's original presentation receive overrides;
hidden/aria-hidden ones remain excluded. These cases do not cover every service
overlay architecture.

The runner is Chrome evidence, not WKWebView or Android WebView evidence. Actual
platform viewport behavior, supported JavaScript-world isolation, keyboard,
VoiceOver/TalkBack, all authenticated panes/dialogs and real service selections
remain separate checks. Android integrations without isolated JavaScript worlds
must explicitly document their narrower isolation boundary.
