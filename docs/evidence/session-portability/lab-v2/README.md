# Session Lab build2

19 October 2026. Diagnostic-only update following the [first physical report](../physical-storage-observation-20261019.json). That report hit its deadline after 1,075 records were started and observed two nonextractable CryptoKey occurrences. Their uniqueness and authentication role remain unknown.

## Change

A single manually initiated pass now targets 30 seconds, with a 35-second native watchdog. Existing database/store/record/node/depth ceilings remain unchanged; there is no automatic retry, pagination or identifier retention. Progress separates discovered, started and completed work. Record counts and traversal share a readonly transaction; completed-record counts increment after classification.

The only added key information is fixed numeric histograms of allowlisted algorithm, type and usage categories, with an `other` bucket. No raw algorithm dictionary, key bytes, identifier, record contents or cryptographic operation is returned or performed. Manual Cancel, token ownership, background/navigation invalidation and stale-result checks remain in force. The report states that observations are neither unique-key identities nor proof of authentication necessity.

## Validation

- [Classifier evidence](classifier-result.json): 42 synthetic checks pass, including the actual longer deadline, late callbacks, cancellation, all retained caps, partial completion, duplicate-key occurrences and metadata filtering. Cleanup confirms browser exit and removal of its temporary profile. Requests were fulfilled locally; these are Chrome fixture checks, not a new real-account scan.
- Independent source review passed for progress semantics, readonly access, bounded metadata, cancellation/watchdog ownership and unchanged lab identity. Native UI/lifecycle runtime behavior was not established by source review.
- [Simulator](simulator-build-result.json) and [device](device-build-result.json) compilation passed with warnings treated as errors. Both compiled captured inputs and packaged the exact tested classifier.
- [Signed candidate](signed-candidate.json): strict signature and profile/bundle coverage verified. All four build inputs matched, and the identity persistence block matched build1 byte-for-byte.
- The initial classifier attempt is retained in `initial-classifier-attempt/`. It passed its first 20 checks before a test-runner CDP completion-value serialization error; the corrected harness passed all 42. This was not interpreted as a platform capability failure.

## Installation and remaining gate

[Physical installation](physical-install.json) confirms version 0.1.0 (2) as an in-place update from build1 under the existing diagnostic testing authorization. No uninstall/reset occurred. Profile Desk's installed-app record matched before and after, remaining build4. Automatic launch was blocked by device lock; the owner has been asked to unlock/open the lab and leave the updated report visible.

The owner subsequently left the updated report visible and authorized its capture. [Physical observation](physical-storage-observation.json): `inconclusive / scanLimit`; databases 4 complete / 5 started / 11 discovered; stores 19 complete / 20 started / 24 discovered; records 2,000 complete / 2,000 started / 2,462 discovered. No keys or unknown types were encountered in that portion; LocalStorage had 83 entries and SessionStorage had two. Only fixed diagnostic values were retained and the temporary screenshot was removed.

The record ceiling prevented later stores from being visited. Zero key observations in this pass do not negate the earlier two nonextractable occurrences, establish key removal, or identify authentication state. The linking method and retention without relinking were not independently observed. The bounded inventory-and-fair-prefix refinement is now installed as [build3](../lab-v3/README.md), without increasing limits; its owner-operated report is pending. The product deployment hold remains in force; this diagnostic app still does not create or restore session archives.
