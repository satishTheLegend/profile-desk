# Public repository preparation

Published at [satishTheLegend/profile-desk](https://github.com/satishTheLegend/profile-desk) with the project owner as sole commit author and committer, without co-author trailers. Code commit `5440a55` passes public Linux CI. No device deployment or shutdown is recorded.

Public text evidence replaces personal home-directory prefixes with
`/Users/LOCAL_USER`, standalone local usernames with `LOCAL_USER`, and host names
with `LOCAL_HOST`. Raw local counterparts are preserved under the ignored
`build/private-publication-evidence/` directory before normalization. Its local
manifest records the affected paths and original/public file hashes. Product
assertion values, recorded counts, algorithm/source/artifact digests and
provenance URLs are preserved. Normalized log bytes differ from their original
raw files; historical digests still describe the original recorded inputs and
outputs. Requirements, traceability and the supplied Word plan are preserved.

The repository contains implementation work in progress. Native Flutter chat
list, message and composer components are tested with fictional data; the live
WhatsApp adapter is not enabled. Current account setup files contain account
metadata and appearance and require linking again. Complete session/data export
and independently verified authenticated restore remain unfinished. Passing
synthetic storage or migration tests does not establish a real account restore.
The product deployment hold remains in force until the required restore and cold
restart proof is complete.

The publication review found no actual conversations, QR linking data, account
credentials or session archives in the intended public files. Included chat and
shell previews use fictional fixtures; historical launcher/error screenshots
contain simulator UI. Local build/signing artifacts and private raw evidence
remain excluded by ignore rules.

No public application-source license grant has been selected. Making the
repository public does not select an open-source license. Third-party licenses
remain in force: bundled Tabler icons retain their MIT notice, Manrope retains
its SIL Open Font License, and resolved dependency notices/inventory are
preserved. Original project artwork follows the application's eventual licensing
decision.

The initial public snapshot was a clean root commit authored
and committed by the project owner. Earlier local development history contains
machine-specific paths and is preserved on a local-only history branch;
it is not part of the public branch. No existing remote history is replaced.
Do not push that local history branch or use `git push --all` for publication.
