# Profile Desk UI and motion enhancement

Date: 18 October 2026. Scope: the existing Flutter application shell on iOS and Android.

## Design decision

Retain Profile Desk’s forest-green and warm-cream identity, with muted sage and lilac supporting profile identity. Use Manrope for display headings and the platform’s body font for familiar controls and readable settings. Make saved profiles immediately recognizable and selectable, while preserving the distinction between saved storage and an account the user has explicitly confirmed.

Brainstorming and gstack routing were consulted. This is a bounded enhancement of existing workflows. The user’s standing instruction to choose recommendations and implement without check-ins governed execution. Native viewport, browser identification, persistence, security boundaries and service integration remain the existing implementation.

## Implemented surfaces

- Welcome: original profile-tile illustration, stronger heading hierarchy and readable disclosures before setup.
- Workspace: actual saved-profile tiles with direct selection through the same guarded account-selection path; responsive heading/artwork arrangement in landscape.
- Selector: recognizable identity marks, selected state, native sheet on phones and anchored dialog on wide screens; unavailable profiles and ten-slot limit remain enforced.
- Account management: adaptive one/two-column tiles, distinct details/edit/open/reorder actions, live identity preview in forms and a clearer detail header.
- Privacy and appearance: grouped authentication/theme controls, original shield illustration and retained local-access limitations.
- Help: four localized numbered linking steps, contextual official-help actions and retained technical capability disclosures.
- Lock: immediate opaque surface and immediate exclusion of underlying account semantics and touch access. Only the illustration inside the cover animates.

## Motion specification

| Element | Motion | Accessibility/lifecycle behavior |
| --- | --- | --- |
| Account, opening and privacy artwork | Three original local Lottie JSON scenes, 30 fps, each under 1.7 seconds, one play | Completed static artwork for reduced motion or accessible navigation; pause when hidden/inactive; icon fallback on asset failure |
| Selected Tabler icons | 240 ms restrained rotation/scale emphasis | No repeated loop; static when motion is reduced |
| Editorial/tile entrance | 280 ms, at most 120 ms stagger, 8 logical-pixel travel | Immediate final position and opacity with reduced motion; never wraps a native view or privacy cover |
| Press feedback | 2.5% scale, 110 ms press / 160 ms release | Preserves the child’s gesture handler and semantics; resets on cancellation; disabled for reduced motion |

Animations express the shell’s organization and interaction. They do not assert a successful service connection, completed linking or guaranteed screen-capture prevention. No service-page DOM, QR code, message or account identity is inspected for animation.

The three JSON files total 22,154 bytes. Artwork is authored in `apps/mobile/assets/animations/author_scenes.py`; only explicit JSON entries ship in the app. Lottie is pinned to 3.6.1. Manrope is bundled locally with its SIL Open Font License and an in-app license entry. There are no runtime font or animation downloads.

## Verification checklist

- [x] Original animations render nonblank final artwork, finish, and dispose cleanly.
- [x] Reduced motion and accessible navigation show static artwork.
- [x] Background and hidden-scene playback pauses; pointer cancellation restores controls.
- [x] 320px layouts, 2× text and keyboard-visible forms remain scrollable and usable.
- [x] Adaptive account grid, unavailable-profile access, reorder identity and duplicate-name validation pass focused tests.
- [x] Lock protects underlying route semantics/touches on its first frame.
- [x] Dark mode and appearance preferences remain functional.
- [x] Fifteen fictional shell scenarios captured for visual review, including tablet and landscape.
- [x] Actual Flutter motion captured into a finite two-second GIF and MP4.
- [x] Final repository checks after all review fixes: 69 Dart tests (25 contract, 18 registry, 26 shell/motion), 49 Python tests, all four analyzers, source exclusions and design traceability.
- [x] iOS development release0.1.0(3) built and signed; signature, profile/device coverage, AOT and bundled assets verified.
- [x] Android development release0.1.0(3) built; unsigned status, non-debuggable manifest, AOT and bundled assets verified.
- [x] Install and foreground-launch build3 on the iPhone as an in-place update frombuild2; installed version and running process independently confirmed. The earlier unavailable-device attempt remains retained.

Evidence: [verification summary](evidence/ui-enhancement/verification.json), [repository checks](evidence/ui-enhancement/repository-check.log), [15-scenario capture log](evidence/ui-enhancement/shell-capture-final.log), [iOS artifact checks](evidence/ui-enhancement/ios-build-verification.json), [Android artifact checks](evidence/ui-enhancement/android-build-verification.json), [motion verification](evidence/ui-enhancement/motion-verification.json), and [visual inventory](release-assets/README.md). All72 recorded production source inputs were unchanged across both builds.

The signed iOS app/IPA and unsigned Android APK are in `artifacts/ui-motion-20261018/`. Physical installation is complete: [build3 deployment evidence](evidence/ui-enhancement/physical-development-install-build3.json) confirms the in-place update, foreground launch and running process. No app was uninstalled and no profile data was reset.

These checks concern the application shell. The previous compatibility report’s authenticated WhatsApp linking, chat, attachment, native accessibility and distribution validation gaps remain open.
