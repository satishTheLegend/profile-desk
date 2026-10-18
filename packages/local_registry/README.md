# Account service

`AccountService` is a Dart use-case facade over `SessionEngine`. Each platform's native SQLite registry is the **only durable authority** for profiles, reservation capacity, allocation, cleanup and preferences. This package writes no files and maintains no second lifecycle journal.

The facade validates alias feedback, delegates authoritative writes, publishes defensive metadata snapshots and refreshes after native profile/cleanup events. Out-of-order refresh results cannot replace a newer cache. Rename and reorder preserve native identifiers. Navigation success never sets authentication observation; the operator must explicitly confirm the account.

The displayed ten-slot capacity includes allocation, missing/quarantined profiles and removals awaiting actual wipe. Android releases the slot only when native state is `cleanupPending` with stage `containerDeletionPending`, after its website-wipe callback and app-data cleanup. Pending containers remain subject to the native backlog limit. iOS releases capacity after named-store removal and app cleanup complete. A pending wipe never counts as successful removal.

`replaceUnavailable` accepts only missing/quarantined profiles. It waits for actual cleanup before reserving a new profile, never carries over backing IDs, and preserves the alias only when explicitly requested. A restore-quarantined installation may independently reject new allocation until the platform's documented reset policy is completed.

Run `flutter test` and `flutter analyze` in this directory. Tests verify facade behavior, failures and races against a test-only engine. They do not prove SQLite transaction behavior or native browser isolation; native tests provide that evidence separately.
