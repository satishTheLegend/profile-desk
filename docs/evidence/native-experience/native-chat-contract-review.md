# Native chat adapter: static interface review

Status: a source-visible internal text-chat path exists; runtime compatibility and service acceptance are unverified. This is a proposed fixture contract, not an implemented or supported WhatsApp API.

This review reused the nine official public script bodies already fetched by the browser reviewer. It performed no client execution, account/profile/device access, message send, attachment send or additional download. All 32 inspected module files matched their recorded source hashes. Exact source URLs, script/module SHA-256 values and byte offsets are in the manifests referenced by `findings.json`.

## Fixed native contract proposed for fixtures

Every request carries the current `ViewHandle`, an operation UUID and the adapter-generation token. Native ownership checks occur before execution and before returning results. IDs returned to Flutter are opaque adapter-issued references, not caller-provided WhatsApp IDs. Main-world maps resolve references back to previously projected current models. Do not accept arbitrary module names, script, selectors, URLs, functions or JIDs.

- `probeNativeChat(view)` returns a bounded status enum: unavailable, linking, synchronizing, ready, disconnected, serviceLocked or unsupportedRevision, plus explicit feature booleans. A source hash is review provenance, not a runtime availability check.
- `listNativeChats(view, pageToken?)` returns bounded projected rows: chatRef, displayTitle, optional text preview, timestamp, unreadCount, archived, pinned, kind, canSendText. Use the official `getShouldAppearInList` predicate and recheck locked-chat exclusion. Unknown predicates/types fail closed. Page tokens are generation-scoped; reordered collections invalidate stale pages.
- `openNativeConversation(view, chatRef)` returns the bounded current message window and capability/history state. A local view selection does not justify directly setting `chat.active`: that setter triggers presence, persistence and ephemeral lifecycle changes in the reviewed source.
- `loadEarlierNativeMessages(view, chatRef, pageToken)` invokes the official `loadEarlierMsgs` once for an explicit user pagination request, supplies an AbortSignal, then projects a bounded window. Its internal PAGE_SIZE and history-state semantics remain authoritative. Empty results are not proof of complete phone history.
- `sendNativeText(view, chatRef, operationId, text)` revalidates current chat identity, visibility, service/app lock, foreground and send capability before the official `sendTextMsgToChat(chat,text,{})` action. One user gesture owns one invocation. A pending-operation map prevents duplicate invocation within the adapter generation. Return the allowlisted send-result enum; do not call OK delivered/read. The high-level action does not guarantee a returned message ID. No automatic retry on timeout/process interruption; outcome must be shown as unknown if it cannot be reconciled.
- `closeNativeConversation(view)` releases references/subscriptions/native text state; any official active/read/presence effects require a separately reviewed user-action path.

Prototype bounds can be 50 chat rows, 50 message rows and 256 KiB encoded response, with explicit `truncated` and continuation state. These are proposed limits, not measured product limits. Text/body bounds must distinguish truncated display from a full draft being sent; never silently truncate outbound text.

Projected text messages may contain only an opaque messageRef, text, timestamp, direction, delivery enum and explicit edit/expiry markers. `viewMode`, pending deletion, expiry, view-once and message type require checks before text projection. Unknown and unsupported rich message types remain typed unavailable rows with an official-page recovery action; never reinterpret arbitrary bodies as text. Never project key material, mediaKey, remote URLs, storage or authentication structures. Private snapshots remain in memory and are cleared on lock, navigation, account change or disposal; no diagnostics or screenshot artifacts contain real message data.

## Proven source interfaces

`WAWebChatCollection.ChatCollection`, `WAWebFrontendChatGetters.getShouldAppearInList`, `getFormattedTitle`, `getOptimisticUnreadCount`, `getPreviewMessage`, `chat.msgs`, `WAWebChatLoadMessages.loadEarlierMsgs`, `WAWebSendTextMsgChatAction.sendTextMsgToChat`, `WAWebViewModeUtils.isViewModeVisibleInSurface`, `WAWebKeepInChatMsgUtils.isExpiredAndNotKept`, `WAWebMsgGetters.getIsSentByMe`, `WAWebSocketModel.Socket`.

`msg.viewMode` is a declared model property. There is no exported `WAWebMsgGetters.getViewMode` in this corpus; do not invent that call.

The loader source assigns the page-global `require` and `__d`. The existing iOS isolated layout world cannot directly read those page globals. A native integration would require an explicitly reviewed fixed page-world adapter; no general page-to-native message channel is required for bounded native-initiated requests.

## Attachment boundary

The official `WAWebMediaPrep` instance exposes `waitForPrep()` and `sendToChat({chat,earlyUpload,options})`, backed by `WAWebMediaPrepSendToChat`. This confirms an internal upload/send pipeline, not a complete native attachment implementation. The reviewed class constructor takes a preparation promise and media model state, not a plain File. Native-file-to-client-media preparation, bounded byte transfer, cleanup, cancellation, provider access, actual send and protected/view-once rendering remain unverified. Keep attachment capability false until that whole path exists and is tested.

## Essential fixture cases

1. Missing loader/export/revision, initialization delay, service screen lock, sync/disconnect, navigation-origin mismatch.
2. Official predicate rejects locked/hidden chats; archived/empty/new/group/broadcast/special chat shapes; unknown field or getter failures reveal no partial private payload.
3. Visible text versus hidden/deleted/expired/view-once/ciphertext/media/system messages; unknown enum/type; giant strings and malformed surrogate handling; no raw object serialization.
4. Chat reorder/removal, message edit/delete/expiry and stale opaque references; pagination cancellation, partial history and empty page without false completeness.
5. Explicit text send reaches only the official high-level action once; blank text, blocked/read-only chat, pending duplicate tap, stale generation, lock, detach, exception, error enum, timeout and unknown outcome. No automatic retry.
6. Safe native text rendering of hostile strings, URLs and markup; no script or clickable-action interpretation without a separate user gesture.
7. Locked/background/disposed views clear returned snapshots and reject late results. Account A results cannot populate Account B.

These fixtures can establish the app-owned adapter boundary and native widget behavior. They cannot establish the currently deployed service revision, real linking, message delivery, full rich-message parity, notifications, backup portability or provider approval.
