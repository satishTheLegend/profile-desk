# Desktop workspace viewport regression

Run from the repository root:

```sh
packages/session_engine/ios/NativeTests/run-viewport-tests.sh
```

The runner compiles the production iOS sources with warnings treated as errors,
records source hashes, creates an owned disposable iOS 17+ simulator, installs the
fixture, copies its JSON result, and shuts down/deletes only that simulator. Set
`IOS_TEST_RUNTIME` to an installed simulator runtime identifier to choose one.

The fixture loads only controlled HTML in nonpersistent stores. Its baseline has
an `overflow:hidden`, `100vw` root and a fixed-width child: native `contentSize`
matches the phone width although the right side is clipped. It then tests the
actual `SessionHostView` and `WorkspaceWebView` at phone, landscape-sized, tablet,
and narrow multitasking widths. Assertions cover the desktop layout viewport,
full rendered width, native coordinate conversion and hit testing, safe-area
ownership, repeated layout stability, responsive content, privacy-cover bounds
and input interception, and disposal/deallocation.

The desktop workspace uses an explicit 980-point layout floor, scaled through a
public UIKit view transform to the real host width. It does not set `pageZoom`,
read a page's DOM, change cookies, or inject viewport markup. The fixture alone
reads its own local HTML geometry to verify the right edge is visible. The
980-pixel desktop-style viewport is documented in Apple's archived
[Safari Web Content Guide](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/UsingtheViewport/UsingtheViewport.html);
it is a chosen application layout policy, not a claim that current WebKit always
chooses that default.

Native pinch remains enabled. Programmatic `UIScrollView.setZoomScale` proves
that a zoom range is available and that the fitter does not synchronously write
the scale during height changes. WebKit resets that programmatic scale after
processing the resized viewport on the tested simulator. Actual touch pinch
combined with the keyboard, VoiceOver navigation, physical rotation, service
login and message use remain separate device checks; these tests do not claim
those passed.

Results and rejected pageZoom experiments are retained under
`docs/evidence/ios/viewport/`. The runner's timestamped `build/ios-viewport-*`
directory contains the source snapshot, compiler log, runtime metadata and result.

The user-approved Safari-compatible identification trial is restricted to the
exact development bundle ID, `dev.profiledesk.profileDesk.development`. Four
additional checks cover unchanged identification for a missing bundle ID,
production and QA, plus the user-agent observed from an actual development-policy
WKWebView loading fixture HTML. These identity checks are separate from viewport
fitting; local fixture identity does not prove service acceptance, authentication
or account persistence. Earlier 27-assertion viewport evidence is preserved
separately from development-policy attempts and results.
