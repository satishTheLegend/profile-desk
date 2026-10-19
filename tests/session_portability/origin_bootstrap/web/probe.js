/* Fixed fictional fixture only. Never load service code or real session data. */
(() => {
  'use strict';
  const origin = 'https://bootstrap.profiledesk.invalid';
  const url = origin + '/';
  const database = 'profiledesk_synthetic_origin_bootstrap';
  const sentinel = 'profiledesk_synthetic_source_only';
  const preferenceKey = 'profiledesk_synthetic_preference';
  const preference = 'fictional-compact';
  const plaintext = [41, 17, 0, 93, 8, 201, 33, 16];
  const typed = [7, 11, 19, 23];
  const buffer = [29, 31, 37];
  const date = '2025-01-02T03:04:05.000Z';
  const equal = (left, right) => left.length === right.length && left.every((value, index) => value === right[index]);
  const digest = async bytes => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes)), value => value.toString(16).padStart(2, '0')).join('');
  const request = value => new Promise((resolve, reject) => {
    value.onsuccess = () => resolve(value.result);
    value.onerror = () => reject(value.error);
  });
  async function open(create) {
    const names = await indexedDB.databases();
    if (!create && !names.some(item => item.name === database)) throw new Error('MissingFixtureDatabase');
    const operation = indexedDB.open(database, 1);
    operation.onupgradeneeded = () => operation.result.createObjectStore('records');
    return await request(operation);
  }
  async function read() {
    const db = await open(false);
    try {
      return await new Promise((resolve, reject) => {
        const transaction = db.transaction('records', 'readonly');
        const operation = transaction.objectStore('records').get('fictional');
        const countOperation = transaction.objectStore('records').count();
        let record;
        let count;
        operation.onsuccess = () => { record = operation.result; };
        countOperation.onsuccess = () => { count = countOperation.result; };
        transaction.oncomplete = () => resolve({ record, count });
        transaction.onabort = () => reject(transaction.error || new Error('ReadAborted'));
        transaction.onerror = () => {};
      });
    } finally { db.close(); }
  }
  async function environment() {
    let registrations;
    try { registrations = navigator.serviceWorker ? await navigator.serviceWorker.getRegistrations() : undefined; }
    catch { registrations = undefined; }
    return {
      locationMatches: location.href === url,
      originMatches: location.origin === origin,
      effectiveOriginMatches: globalThis.origin === origin,
      baseURIMatches: document.baseURI === url,
      secureContext: isSecureContext,
      cryptoAvailable: !!globalThis.crypto?.subtle,
      serviceWorkerRegistrationReadSucceeded: Array.isArray(registrations),
      serviceWorkerRegistrationCount: registrations?.length ?? -1,
      resourceCount: performance.getEntriesByType('resource').length,
      scriptElementCount: document.scripts.length,
      childFrameCount: frames.length
    };
  }
  async function empty() {
    return { databaseCount: (await indexedDB.databases()).length,
      localStorageCount: localStorage.length, cookieCount: document.cookie ? document.cookie.split(';').length : 0 };
  }
  function validate(transfer) {
    if (!transfer || Object.getPrototypeOf(transfer) !== Object.prototype ||
        Object.keys(transfer).sort().join(',') !== 'buffer,date,map,plaintext,preference,typed' ||
        !Array.isArray(transfer.plaintext) || !equal(transfer.plaintext, plaintext) ||
        !Array.isArray(transfer.typed) || !equal(transfer.typed, typed) ||
        !Array.isArray(transfer.buffer) || !equal(transfer.buffer, buffer) ||
        transfer.date !== date || !Array.isArray(transfer.map) || transfer.map.length !== 1 ||
        !Array.isArray(transfer.map[0]) || transfer.map[0].length !== 2 ||
        transfer.map[0][0] !== 'label' || transfer.map[0][1] !== 'fictional' ||
        transfer.preference !== preference) throw new TypeError('InvalidFixtureTransfer');
  }
  async function write(transfer, source) {
    validate(transfer);
    // Each newly generated key encrypts exactly one payload at this counter.
    // The original key never leaves its own WebView or enters the transfer.
    const encKey = await crypto.subtle.generateKey({ name: 'AES-CTR', length: 128 }, false, ['encrypt', 'decrypt']);
    const value = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-CTR', counter: new Uint8Array(16), length: 128 }, encKey, new Uint8Array(transfer.plaintext)));
    const record = { encKey, value, typed: new Uint8Array(transfer.typed), buffer: new Uint8Array(transfer.buffer).buffer,
      date: new Date(transfer.date), map: new Map(transfer.map), nested: { fictional: true } };
    const db = await open(true);
    try {
      await new Promise((resolve, reject) => {
        const transaction = db.transaction('records', 'readwrite');
        transaction.objectStore('records').add(record, 'fictional');
        transaction.oncomplete = resolve;
        transaction.onabort = () => reject(transaction.error || new Error('WriteAborted'));
        transaction.onerror = () => {};
      });
      localStorage.setItem(preferenceKey, transfer.preference);
      if (source) localStorage.setItem(sentinel, 'fictional-only');
    } finally { db.close(); }
    return await verify();
  }
  async function verify() {
    const { record, count } = await read();
    const decoded = new Uint8Array(await crypto.subtle.decrypt({ name: 'AES-CTR', counter: new Uint8Array(16), length: 128 }, record.encKey, record.value));
    let exportRejected = false;
    try { await crypto.subtle.exportKey('raw', record.encKey); }
    catch (error) { exportRejected = error.name === 'InvalidAccessError'; }
    return {
      recordCount: count,
      plaintextMatches: equal(Array.from(decoded), plaintext),
      localStorageMatches: localStorage.getItem(preferenceKey) === preference,
      typedDataMatches: record.typed instanceof Uint8Array && equal(Array.from(record.typed), typed) &&
        record.buffer instanceof ArrayBuffer && equal(Array.from(new Uint8Array(record.buffer)), buffer) &&
        record.date instanceof Date && record.date.toISOString() === date && record.map instanceof Map &&
        record.map.size === 1 && record.map.get('label') === 'fictional' && record.nested?.fictional === true,
      keyMatches: record.encKey instanceof CryptoKey && record.encKey.type === 'secret' && !record.encKey.extractable &&
        record.encKey.algorithm.name === 'AES-CTR' && record.encKey.algorithm.length === 128 &&
        record.encKey.usages.length === 2 && record.encKey.usages.includes('encrypt') && record.encKey.usages.includes('decrypt'),
      originalKeyExportRejected: exportRejected,
      sourceSentinelPresent: localStorage.getItem(sentinel) === 'fictional-only',
      ciphertextDigest: await digest(record.value),
      typedDataDigest: await digest(record.typed)
    };
  }
  async function transfer() {
    const { record } = await read();
    const value = new Uint8Array(await crypto.subtle.decrypt({ name: 'AES-CTR', counter: new Uint8Array(16), length: 128 }, record.encKey, record.value));
    const result = { plaintext: Array.from(value), typed: Array.from(record.typed), buffer: Array.from(new Uint8Array(record.buffer)),
      date: record.date.toISOString(), map: Array.from(record.map), preference: localStorage.getItem(preferenceKey) };
    validate(result);
    return result;
  }
  Object.defineProperty(globalThis, 'originBootstrapProbe', { value: Object.freeze({ environment, empty, verify, transfer,
    seed: () => write({ plaintext, typed, buffer, date, map: [['label', 'fictional']], preference }, true),
    restore: transfer => write(transfer, false) }), configurable: false, writable: false });
})();
