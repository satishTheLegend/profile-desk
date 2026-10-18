# Shell and motion previews

Fifteen previews render the actual enhanced Flutter shell with fictional local profile labels. The visible banner identifies synthetic shell previews. They are local design-review material; they do not establish verified WhatsApp integration, native authentication or physical-device behavior.

| Asset | Surface / condition |
| --- | --- |
| [Welcome](welcome.png) | Original account artwork, primary-device and foreground disclosures |
| [Workspace](workspace.png) | Three fictional saved profiles and direct selection tiles |
| [Accounts](accounts.png) | Account management, identity and distinct actions |
| [Selector](selector.png) | Phone sheet with saved-account status |
| [Privacy](privacy.png) | Authentication, appearance and local-data disclosures |
| [Help](help.png) | Four linking steps and official-help links |
| [Details](details.png) | Local profile actions and scoped-removal explanation |
| [Lock](lock.png) | Covered shell and explicit unlock action |
| [Dark accounts](accounts-dark.png) | Dark palette and identity tiles |
| [Tablet accounts](accounts-tablet.png) | Two-column layout at 1024 × 768 |
| [Narrow welcome](welcome-narrow.png) | 320 × 568 scrollable layout |
| [Large-text privacy](privacy-large-text.png) | 320 × 568 at 2× text |
| [Reduced-motion lock](lock-reduced.png) | Static completed illustration |
| [Landscape workspace](workspace-landscape.png) | 932 × 430 with compact introduction |
| [Large-text selector](selector-large-text.png) | One scrollable sheet at 320 × 568 / 2× text |

[Animated GIF](profile-desk-motion.gif) · [MP4](profile-desk-motion.mp4): the three actual local Lottie compositions, rendered in Flutter at 15 fps for two seconds. They play once and rest. No account data appears in the artwork.

Phone previews use a 430 × 932 logical viewport except where stated. All PNGs use pixel ratio 2. Each screenshot shows the first viewport; content remains scrollable. The fixture uses a Linux target override, bundled Manrope headings, macOS Arial loaded as the renderer’s Roboto body family and Flutter MaterialIcons. Arial supplies arrow glyphs missing from the SDK’s subset test font. This is a test-renderer choice; the app retains platform-native body text. The fixed-size disclosure banner is outside the application and ignores text scaling so it remains readable.

Visual review inspected the full set, then confirmed fixes for landscape spacing, selector reachability, touch targets and the test-font arrow glyph. Dedicated interaction tests reach the last of ten profiles and the Add action under large text, exercise unavailable access and form validation, and verify immediate lock semantics/touch protection. Rendering a locked fixture does not establish native biometric success or snapshot timing.

Reproduce shell captures from `apps/mobile`:

```sh
flutter test ../../tests/release_assets/capture_shell.dart \
  --dart-define=PREVIEW_FONT_DIR=/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts \
  --dart-define=PREVIEW_BODY_FONT_DIR=/System/Library/Fonts/Supplemental \
  --dart-define=PREVIEW_OUTPUT_DIR=/absolute/output/directory
```

`PREVIEW_BODY_FONT_DIR` is optional; without it, the SDK’s Roboto test fonts are used. Motion capture uses `tests/release_assets/capture_motion.dart` with `PREVIEW_FONT_DIR` and `MOTION_OUTPUT_DIR`, producing 30 numbered PNG frames suitable for encoding at 15 fps.

Both builders live under tests. They open no native browser, contact no service, display no QR and send no message. The shell fixture verifies that no profile-open call occurred. [manifest.json](manifest.json) records dimensions, hashes and capture-source hashes. See [UI motion design and verification](../UI_MOTION_ENHANCEMENT.md) for implementation details and remaining device/service validation limits.

Before store submission, replace these drafts with required device-size captures from the final signed candidate and accurately demonstrated features using fictional or explicitly authorized data. Final metadata, reviewer access and service captures remain open in [the review package](../STORE_REVIEW_PACKAGE.md).
