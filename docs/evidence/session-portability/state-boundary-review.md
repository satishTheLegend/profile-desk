# Authentication-state boundary review — 19 October 2026

**Result: the production session-export requirement remains blocked by an unverified service-specific state boundary.** The completed diagnostic establishes encountered value categories; it does not establish which values must survive an independent restore. No new product code or device deployment is justified by this report alone.

## Observed evidence

[The build3 report](lab-v3/physical-storage-observation.json) encountered two nonextractable AES-CTR secret-key occurrences with encrypt/decrypt permission. They may repeat one underlying key. It fully scanned 61 stores, sampled 3 and skipped 82 discovered stores. The 5,691 counted records describe inventoried/visited stores, not every discovered store. Equal inventory/visit counts and zero observed changes or read failures do not make this an atomic snapshot.

The [Web Crypto Recommendation](https://www.w3.org/TR/2017/REC-WebCryptoAPI-20170126/#SubtleCrypto-method-exportKey) rejects `exportKey` for a nonextractable key. Its [wrapping algorithm](https://www.w3.org/TR/2017/REC-WebCryptoAPI-20170126/#SubtleCrypto-method-wrapKey) enforces the same restriction. This rules out generic preservation of these observed key objects through those operations. It does not establish hardware binding, their role, or whether a sufficient login-state subset could omit them.

## Bounded primary-source review

An independent research pass reviewed the following public documentation without accessing an account, executing client code or reading real records:

- [WhatsApp Encryption Overview](https://www.whatsapp.com/security/WhatsApp-Security-Whitepaper.pdf), version 9 dated 25 February 2026, pages 8–10: describes AES-CTR in companion/primary linking to protect ephemeral public keys. An algorithm match does not connect that documented role to the observed stored keys. The reviewed paper does not supply an IndexedDB credential schema or browser-session migration contract. The PDF was extracted in memory; reviewed bytes SHA-256 `4cc7bf38d91abf7fefd1957fc9259f63fcc8aaa2d79c97d2bed3d11948e3a386`, length 1,879,555 bytes. A browsing-tool redirect failure preceded the successful direct public fetch; no local copy was retained.
- [Meta multi-device architecture](https://engineering.fb.com/2021/07/14/security/whatsapp-multi-device/): describes device identity, history-transfer and application-state encryption. It does not identify the observed CryptoKey occurrences or document their browser storage migration.
- [WhatsApp restore-chat-history help](https://faq.whatsapp.com/618575946635920/?cms_platform=web&locale=fi_FI): says linked Web/Mac/Windows devices cannot back up or restore chat history. This is a chat-history limitation, not independent proof that credential-session migration is impossible.

The review found no supported mapping or migration interface **in these materials**. Public client source was not executed or comprehensively analyzed. Do not turn this limited negative finding into a universal impossibility claim.

## Implementation decision and next gate

Do not increase scan limits, omit opaque keys silently, reuse the source profile as a restored destination, or label the metadata archive a session backup. A new broad count scan cannot establish requiredness. No further owner scan is currently requested.

Further session implementation requires a reviewed, version-specific credential-store/schema boundary, a supported way to preserve or regenerate every required value, cookie coverage, snapshot consistency and a controlled empty-origin restore. Required nonextractable keys without supported serialization would block that path; optional keys must be demonstrated optional through an independent restore and cold restart without QR/code relinking. The existing source profile must survive either outcome.

Encrypted archive format, native orchestration, production UI activation and product deployment remain uncompleted. Profile Desk still supports setup metadata transfer only. These are explicit open gates rather than completed features. The user's deployment hold remains in force; Session Lab's diagnostic exception does not remove it.
