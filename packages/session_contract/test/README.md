# Coordinator regression tests

The coordinator suite covers native cover-before-label ordering, serialized disposal/open, four-field ownership, latest-selection supersession, early and stale callbacks, transfer cancellation, inactive cleanup while switching, delayed native mutation reconciliation, startup tombstones, renderer recovery through view rebuild, and lock/authentication races.

`support/fake_engine.dart` is a deterministic test dependency. It is outside `lib`, has no production export and is never used to claim native implementation or service compatibility. A completed navigation event means only that the view became ready; authentication remains unknown until explicit operator confirmation.

View replacement and disposal preserve persistent stores. Reload uses a new view/operation/generation against the same store so stale prior-navigation callbacks cannot reveal content. Cleanup callbacks carry their own operation identity and remain independent of selection generation; the native durable journal remains authoritative if Dart detaches.

A mutation timeout blocks new view mutations while its actual late result is reconciled. Late views are disposed; late reveals are covered again; late authentication successes are re-locked. A failed reconciliation remains covered and requires native recovery/restart. Native cleanup can continue independently while another eligible account opens.

Run `flutter test` and `flutter analyze` in `packages/session_contract`.
