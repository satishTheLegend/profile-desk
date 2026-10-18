# Verified sources and pending evidence

Access date: 18 October 2026 IST. API behavior must also pass native tests on declared versions.

| Source | Finding and decision |
| --- | --- |
| [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels) | Pigeon supports Swift/Kotlin; native UI work stays on required main thread. Use generated bindings. |
| [Pigeon](https://pub.dev/packages/pigeon) | Pub API resolved 29.0.10, pinned; Dart 3.13.4 installed. |
| [Riverpod](https://pub.dev/packages/flutter_riverpod) | Pub API resolved 3.4.3; use one shared state system. |
| [WhatsApp linked devices](https://faq.whatsapp.com/378279804439436/) | Help page returned no extractable body. Service policy claims remain unverified; no permission inference from QR consent. |
| [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/) | Useful native behavior and accurate reviewer access/disclosures are dependencies. No acceptance is claimed. |
| [Google Play spam/WebViews](https://support.google.com/googleplay/android-developer/answer/9899034?hl=en) | Provider permission remains a release dependency for a purpose-built website wrapper. |
| [Google target SDK](https://developer.android.com/google/play/requirements/target-sdk) | Recheck at release; target and minimum supported Android are different. |
| [Apple submission requirements](https://developer.apple.com/news/upcoming-requirements/) | Xcode 27.1 installed; archive/upload require release configuration and authorization. |

Native API decisions and evidence are in IOS_EVIDENCE.md and ANDROID_EVIDENCE.md. No approved service test accounts or consenting recipients are configured. No service messages will be sent during synthetic tests. Seven- and fourteen-day tests require actual elapsed time.

Shell localization follows Flutter's source-generated ARB workflow: [Internationalizing Flutter apps](https://docs.flutter.dev/ui/internationalization) and [source generation change](https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source), accessed18Oct2026. [GitHub runner image inventory](https://github.com/actions/runner-images/blob/main/images/macos/toolsets/toolset-26.json) did not establish the exact tested Xcode27.1 hosted toolchain; prepared Apple CI uses an explicitly provisioned self-hosted label instead of assuming availability.
