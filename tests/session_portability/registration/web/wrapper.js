'use strict';

// Reimplements the reviewed algorithm with synthetic bytes. No service code,
// credentials or real Signal identity material is loaded or executed.
globalThis.registrationProbe = (() => {
  const dbName = 'synthetic-registration-wrappers';
  const storeName = 'synthetic-meta';
  const fields = ['public', 'private'];
  const algorithm = () => ({name: 'AES-CTR', length: 128, counter: new Uint8Array(16)});
  const plain = () => [Uint8Array.from({length: 32}, (_, i) => i + 1),
    Uint8Array.from({length: 32}, (_, i) => 255 - i)];
  const equal = (a, b) => a.length === b.length && a.every((value, index) => value === b[index]);
  const bytes = value => Array.from(new Uint8Array(value));
  // This is a test-only acceptance boundary, not a claim that the service
  // validates its own stored envelopes. Validate before any native transfer.
  function validateEnvelopes(envelopes) {
    if (!Array.isArray(envelopes) || envelopes.length !== 2) throw new TypeError('Invalid synthetic wrapper count');
    for (const envelope of envelopes) {
      if (!envelope || Object.getPrototypeOf(envelope) !== Object.prototype
          || Object.keys(envelope).sort().join(',') !== 'encKey,value'
          || !(envelope.encKey instanceof CryptoKey) || !(envelope.value instanceof ArrayBuffer)
          || envelope.value.byteLength !== 32 || envelope.encKey.type !== 'secret'
          || envelope.encKey.extractable !== false || envelope.encKey.algorithm.name !== 'AES-CTR'
          || envelope.encKey.algorithm.length !== 128
          || [...envelope.encKey.usages].sort().join(',') !== 'decrypt,encrypt') {
        throw new TypeError('Invalid synthetic wrapper');
      }
    }
    if (envelopes[0].encKey === envelopes[1].encKey) throw new TypeError('Shared synthetic wrapper key');
  }
  function validateTransfer(transfer) {
    if (!transfer || Object.getPrototypeOf(transfer) !== Object.prototype
        || Object.keys(transfer).sort().join(',') !== 'privateBytes,publicBytes') throw new TypeError('Invalid synthetic transfer');
    const payloads = [transfer.publicBytes, transfer.privateBytes];
    for (const payload of payloads) {
      // Array.every skips sparse slots; require each own indexed byte explicitly.
      if (!Array.isArray(payload) || payload.length !== 32
          || Array.from({length: 32}, (_, i) => i).some(i => !Object.hasOwn(payload, i)
            || !Number.isInteger(payload[i]) || payload[i] < 0 || payload[i] > 255)) {
        throw new TypeError('Invalid synthetic payload');
      }
    }
    return payloads;
  }
  async function unwrap(envelopes) {
    validateEnvelopes(envelopes);
    // Distinct JS wrappers can still reference one underlying cloned key.
    // Detect that in this known-plaintext fixture without exporting any key.
    const cross = bytes(await crypto.subtle.decrypt(algorithm(), envelopes[1].encKey, envelopes[0].value));
    if (equal(cross, bytes(plain()[0]))) throw new TypeError('Cloned shared synthetic key');
    const payloads = [];
    for (let index = 0; index < 2; index++) {
      const payload = bytes(await crypto.subtle.decrypt(algorithm(), envelopes[index].encKey, envelopes[index].value));
      // Known fictional bytes make corruption detectable in this fixture.
      // AES-CTR itself is unauthenticated; production needs an authenticated archive.
      if (!equal(payload, bytes(plain()[index]))) throw new TypeError('Corrupt synthetic payload');
      payloads.push(payload);
    }
    return {publicBytes: payloads[0], privateBytes: payloads[1]};
  }
  async function database() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(dbName, 1);
      request.onupgradeneeded = () => request.result.createObjectStore(storeName);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
      request.onblocked = () => reject(new Error('Blocked synthetic database'));
    });
  }
  async function read() {
    const db = await database();
    try {
      return await new Promise((resolve, reject) => {
        const transaction = db.transaction(storeName, 'readonly');
        const requests = fields.map(field => transaction.objectStore(storeName).get(field));
        transaction.oncomplete = () => resolve(requests.map(request => request.result));
        transaction.onerror = () => reject(transaction.error);
        transaction.onabort = () => reject(transaction.error);
      });
    } finally { db.close(); }
  }
  async function write(envelopes) {
    const db = await database();
    try {
      await new Promise((resolve, reject) => {
        const transaction = db.transaction(storeName, 'readwrite');
        transaction.oncomplete = resolve;
        transaction.onerror = () => reject(transaction.error);
        transaction.onabort = () => reject(transaction.error);
        try { envelopes.forEach((envelope, index) => transaction.objectStore(storeName).put(envelope, fields[index])); }
        catch (error) { transaction.abort(); reject(error); }
      });
    } finally { db.close(); }
  }
  async function wrap(payload) {
    const encKey = await crypto.subtle.generateKey({name: 'AES-CTR', length: 128}, false, ['encrypt', 'decrypt']);
    return {encKey, value: await crypto.subtle.encrypt(algorithm(), encKey, payload)};
  }
  async function inspect(envelopes) {
    const expected = plain();
    const states = [];
    for (let index = 0; index < envelopes.length; index++) {
      const envelope = envelopes[index];
      if (!envelope || !(envelope.encKey instanceof CryptoKey) || !(envelope.value instanceof ArrayBuffer)) {
        states.push({shape: false}); continue;
      }
      let exportRejected = false;
      try { await crypto.subtle.exportKey('raw', envelope.encKey); }
      catch (error) { exportRejected = error.name === 'InvalidAccessError'; }
      const decrypted = bytes(await crypto.subtle.decrypt(algorithm(), envelope.encKey, envelope.value));
      states.push({shape: Object.keys(envelope).sort().join(',') === 'encKey,value',
        nonextractable: envelope.encKey.extractable === false, exportRejected,
        algorithmMatches: envelope.encKey.algorithm.name === 'AES-CTR' && envelope.encKey.algorithm.length === 128,
        usagesMatch: [...envelope.encKey.usages].sort().join(',') === 'decrypt,encrypt',
        plaintextMatches: equal(decrypted, bytes(expected[index]))});
    }
    // A wrong-key decryption check avoids encrypting a second plaintext with
    // the same CTR key/counter. Each wrapper key encrypts exactly one payload.
    const differentKeys = envelopes.length === 2 && envelopes.every(envelope => envelope?.encKey instanceof CryptoKey)
      && !equal(bytes(await crypto.subtle.decrypt(algorithm(), envelopes[1].encKey, envelopes[0].value)), bytes(expected[0]));
    return {states, differentKeys, envelopes: envelopes.map(envelope => envelope ? bytes(envelope.value) : [])};
  }
  async function cloneControl(name, length) {
    const key = await crypto.subtle.generateKey({name, length}, false, ['encrypt', 'decrypt']);
    const db = await database();
    try {
      await new Promise((resolve, reject) => {
        const transaction = db.transaction(storeName, 'readwrite');
        transaction.oncomplete = resolve;
        transaction.onerror = () => reject(transaction.error);
        transaction.onabort = () => reject(transaction.error);
        try { transaction.objectStore(storeName).put(key, 'control'); }
        catch (error) { transaction.abort(); reject(error); }
      });
      return {persisted: true, errorName: 'none'};
    } catch (error) {
      return {persisted: false, errorName: ['DataCloneError', 'SecurityError', 'AbortError'].includes(error.name) ? error.name : 'OtherError'};
    } finally { db.close(); }
  }
  return Object.freeze({
    async diagnose() {
      return {secureContext: isSecureContext, aesGCM: await cloneControl('AES-GCM', 256), aesCTR: await cloneControl('AES-CTR', 128)};
    },
    async empty() {
      return {databaseAbsent: !(await indexedDB.databases()).some(db => db.name === dbName),
        sourceSentinelAbsent: localStorage.getItem('source-only-sentinel') === null};
    },
    async seed() {
      const envelopes = await Promise.all(plain().map(wrap));
      if (envelopes[0].encKey === envelopes[1].encKey) throw new Error('Wrapper keys must differ');
      await write(envelopes);
      localStorage.setItem('source-only-sentinel', 'owned-source-only');
      return await inspect(await read());
    },
    async transfer() {
      const envelopes = await read();
      // Original wrapper keys never cross the WKWebView boundary. Only these
      // known synthetic plaintext bytes enter the in-memory transfer object.
      return await unwrap(envelopes);
    },
    async restore(transfer) {
      const payloads = validateTransfer(transfer);
      const envelopes = await Promise.all(payloads.map(payload => wrap(Uint8Array.from(payload))));
      if (envelopes[0].encKey === envelopes[1].encKey) throw new Error('Fresh wrapper keys must differ');
      await write(envelopes);
      const state = await inspect(await read());
      return {...state, sourceSentinelAbsent: localStorage.getItem('source-only-sentinel') === null};
    },
    async faults() {
      const valid = await read();
      const before = valid.map(envelope => bytes(envelope.value));
      const cases = [];
      async function rejects(name, action) {
        let rejected = false;
        try { await action(); } catch (error) { rejected = error instanceof TypeError; }
        cases.push({name, rejected});
      }
      const changed = (key, value) => [{encKey: key, value}, valid[1]];
      const key = valid[0].encKey;
      await rejects('missing-wrapper', () => unwrap([valid[0]]));
      await rejects('extra-wrapper', () => unwrap([...valid, valid[0]]));
      await rejects('null-wrapper', () => unwrap([null, valid[1]]));
      await rejects('missing-key', () => unwrap([{value: valid[0].value}, valid[1]]));
      await rejects('extra-counter-field', () => unwrap([{...valid[0], counter: new Uint8Array(16)}, valid[1]]));
      await rejects('counter-override', () => unwrap([{...valid[0], counter: new Uint8Array(8)}, valid[1]]));
      await rejects('fake-key', () => unwrap(changed({}, valid[0].value)));
      await rejects('typed-array-envelope', () => unwrap(changed(key, new Uint8Array(valid[0].value))));
      for (const length of [0, 31, 33]) {
        await rejects('ciphertext-length-' + length, () => unwrap(changed(key, new ArrayBuffer(length))));
      }
      for (const [name, spec, extractable, usages] of [
        ['wrong-algorithm', {name: 'AES-GCM', length: 128}, false, ['encrypt', 'decrypt']],
        ['wrong-key-length', {name: 'AES-CTR', length: 256}, false, ['encrypt', 'decrypt']],
        ['extractable-key', {name: 'AES-CTR', length: 128}, true, ['encrypt', 'decrypt']],
        ['missing-decrypt-usage', {name: 'AES-CTR', length: 128}, false, ['encrypt']],
        ['missing-encrypt-usage', {name: 'AES-CTR', length: 128}, false, ['decrypt']],
      ]) {
        const invalid = await crypto.subtle.generateKey(spec, extractable, usages);
        await rejects(name, () => unwrap(changed(invalid, valid[0].value)));
      }
      // Reuse is rejected before crypto. No test encrypts a second plaintext
      // under the same CTR key/counter, including this deliberately shared key.
      await rejects('shared-key-counter', () => unwrap([valid[0], {...valid[1], encKey: key}]));
      await rejects('cloned-shared-key-counter', () => unwrap([valid[0], {...valid[1], encKey: structuredClone(key)}]));
      const corrupt = new Uint8Array(valid[0].value.slice(0)); corrupt[0] ^= 1;
      await rejects('ciphertext-corruption', () => unwrap(changed(key, corrupt.buffer)));
      const payload = () => ({publicBytes: bytes(plain()[0]), privateBytes: bytes(plain()[1])});
      await rejects('null-transfer', () => this.restore(null));
      await rejects('missing-private-payload', () => this.restore({publicBytes: payload().publicBytes}));
      await rejects('extra-payload-field', () => this.restore({...payload(), key: 'not-allowed'}));
      for (const [name, value] of [['negative', -1], ['overflow', 256], ['fractional', 1.5], ['nan', NaN], ['string', '1']]) {
        const transfer = payload(); transfer.privateBytes[0] = value;
        await rejects('payload-byte-' + name, () => this.restore(transfer));
      }
      const sparse = payload(); delete sparse.publicBytes[1];
      await rejects('sparse-payload', () => this.restore(sparse));
      const short = payload(); short.publicBytes.pop();
      await rejects('short-payload', () => this.restore(short));
      const typed = payload(); typed.privateBytes = Uint8Array.from(typed.privateBytes);
      await rejects('typed-array-payload', () => this.restore(typed));
      const after = await read();
      const preserved = after.every((envelope, index) => equal(bytes(envelope.value), before[index]));
      const verified = await unwrap(after);
      return {cases, preserved, validStillReadable: validateTransfer(verified).length === 2,
        unsafeCounterReusePerformed: false};
    },
    async verify() {
      const state = await inspect(await read());
      return {...state, sourceSentinelAbsent: localStorage.getItem('source-only-sentinel') === null};
    },
    async against(sourceCiphertexts) {
      const envelopes = await read();
      const expected = plain();
      let comparisons = 0, allKeysDifferent = true;
      for (let sourceIndex = 0; sourceIndex < 2; sourceIndex++) {
        for (const envelope of envelopes) {
          const result = bytes(await crypto.subtle.decrypt(algorithm(), envelope.encKey, Uint8Array.from(sourceCiphertexts[sourceIndex])));
          allKeysDifferent = allKeysDifferent && !equal(result, bytes(expected[sourceIndex]));
          comparisons++;
        }
      }
      return {comparisons, allKeysDifferent};
    }
  });
})();
