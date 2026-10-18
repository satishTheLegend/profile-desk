# Fictional native messaging fixture

30 focused tests passed on 19 October 2026. Focused Flutter analysis reported no issues. The fixture port exists only in `test/native_messaging_test.dart`; it is not registered in Profile Desk.

The PNGs contain invented conversations only. They were rendered at 390 × 844 logical pixels with reduced motion, existing local Manrope/Roboto fonts, and no account, network, media URL or device operation. Both were visually inspected for readable typography, list/bubble alignment, native input and reachable fallback controls. These are component previews; the surrounding product account bar is deliberately outside this component.

From `apps/mobile`:

```sh
flutter analyze lib/features/messaging test/native_messaging_test.dart
flutter test test/native_messaging_test.dart --reporter expanded
```

Optional readable preview capture uses the installed Flutter SDK's existing Material font cache (substitute its actual local directory):

```sh
flutter test test/native_messaging_test.dart --reporter expanded \
  --dart-define=NATIVE_MESSAGING_CAPTURE=true \
  --dart-define=NATIVE_MESSAGING_FONT_ROOT=/path/to/flutter/bin/cache/artifacts/material_fonts
```

Coverage includes exact scope/action ownership, stale list/history/send callbacks, disposal, lock clearing, account/chat drafts, single-flight sends, rejection/timeout/unknown outcomes, accepted-versus-delivered distinction, bounded history, actual search/tap/type/send/system-Back/fallback actions, loading/empty/link/offline/unsupported/read-only states, semantic labels/touch targets, 320/440 widths with 2× text and keyboard insets, and landscape/tablet reachability. Unsupported content has no body payload. Drafts are memory-only and discarded on suspension/disposal.

An added uncertainty-at-large-text test reproduced a real bottom overflow before the feedback/composer area was constrained and made scrollable. Initial harness issues (tap before rebuild, semantics teardown timing and real-async PNG capture) were corrected; the final complete run has no hit-test warnings or skipped cases.

This verifies Flutter components with fictional data. It does not establish real-service visibility filtering, screen-lock readiness, chat synchronization, native-window privacy covering, live sends or session restore. A production adapter must enforce those boundaries before registration. Ephemeral/view-once/private content must remain excluded or unsupported until its own reviewed visibility/expiry contract exists. `partialHistory` is explicit; bounded display history is not a backup/export.

## Integration lifecycle

`NativeMessagingWorkspace` requires a real `NativeMessagingPort`, immutable `MessagingScope(profileId, viewInstanceId, selectionGeneration)`, `active`, `refreshRevision` and an explicit `onOpenOfficial` callback. Scope changes invalidate outstanding results; refresh revisions update the list/current conversation while preserving drafts and current rows during the request. The widget schedules no polling.

Set `active=false` on lock, background, detach or official-view handoff; content and drafts are cleared. The widget also suspends itself **before** invoking `onOpenOfficial`, so deferred navigation cannot retain its private rows. Return from the official interface requires an explicit `active=false` then `active=true` host transition after verifying current scope/readiness; a mere parent rebuild is insufficient. Disposal clears all retained content. The host must still supply a synchronous native full-window cover before OS snapshots—Dart state clearing does not replace that requirement.

The port provides only `loadChats(scope)`, `loadMessages(scope, chatId, beforeCursor)` and `sendText(scope, chatId, text, actionId)`. Responses must repeat the exact scope; messages also repeat the chat ID, and send results repeat chat/action IDs. `accepted` means submitted to the official client, never delivered/read. `rejected` is only a confirmed non-send; ambiguous outcomes/exceptions/timeouts are `uncertain` and cannot be retried automatically. Native ownership/deduplication must remain authoritative even after widget disposal or handoff.

## Independent-review lock correction

A typed `NativeMessagingException.locked` is handled centrally for list reads, message refreshes, history pagination and text sends. It clears all display content, selected title, query and every retained account draft; invalidates outstanding reads/actions by advancing the ownership epoch; and exposes the locked state without replaying an ambiguous send. Returned locked snapshots use the same purge. A lock failure belonging to an old scope cannot lock a newly selected account. Seven added fault/widget cases cover these paths and delayed results.

## Verified source hashes

SHA-256 after the final focused analysis and 30-case fixture run (the last source change only added a required lint brace):

- `apps/mobile/lib/features/messaging/native_messaging_controller.dart`: `e22696201cdfaa82a6b95445f18c32aff8f05190ec77160d91d84709597c5fae`
- `apps/mobile/lib/features/messaging/native_messaging_models.dart`: `3cb014b57f9d49093730c242d01871568f84535879c1d2f1da2dbc1d0042b01a`
- `apps/mobile/lib/features/messaging/native_messaging_port.dart`: `e7296940c491bb99298ce6a6ed58d2fd75c82fc4d7bb2c9907e99439269fcabd`
- `apps/mobile/lib/features/messaging/native_messaging_workspace.dart`: `2fa4d8111666fcd56ccc52408bfe59cd1899aa3feb9fb32d1b9aef4b1c8de205`
- `apps/mobile/test/native_messaging_test.dart`: `d27e935370337a248cda6bc4c6ef05633d83b99f0bf92cd94f5e19da38515ccc`
