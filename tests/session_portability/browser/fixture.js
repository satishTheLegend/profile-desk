// TEST-ONLY feasibility spike. Not imported by the application or its builds.
// This knows one owned database and selected storage fields. It is not a
// complete browser-state serializer and must never be used on service accounts.
(() => {
  'use strict';
  const DATABASE = 'owned-session-portability-probe';
  const STORE = 'fixture';
  const MAX_BYTES = 128 * 1024;
  const MAX_NODES = 2000;
  const MAX_DEPTH = 24;
  const utf8 = new TextEncoder();
  const challenge = utf8.encode('owned-fixture-restore-challenge-v1');
  const request = (operation) => new Promise((resolve, reject) => {
    operation.onsuccess = () => resolve(operation.result);
    operation.onerror = () => reject(operation.error);
  });
  const transactionDone = (transaction) => new Promise((resolve, reject) => {
    transaction.oncomplete = resolve;
    transaction.onerror = () => reject(transaction.error);
    transaction.onabort = () => reject(transaction.error || new Error('aborted'));
  });
  async function open() {
    const operation = indexedDB.open(DATABASE, 1);
    operation.onupgradeneeded = () => operation.result.createObjectStore(STORE);
    return request(operation);
  }
  async function entries() {
    const database = await open();
    try {
      const transaction = database.transaction(STORE);
      const done = transactionDone(transaction);
      const store = transaction.objectStore(STORE);
      const [keys, values] = await Promise.all([request(store.getAllKeys()), request(store.getAll())]);
      await done;
      return keys.map((key, index) => [key, values[index]]);
    } finally { database.close(); }
  }
  async function writeAll(values) {
    const database = await open();
    try {
      const transaction = database.transaction(STORE, 'readwrite');
      const done = transactionDone(transaction);
      for (const [key, value] of values) transaction.objectStore(STORE).put(value, key);
      await done;
    } finally { database.close(); }
  }
  const bytes = (buffer) => Array.from(new Uint8Array(buffer));
  function budget() {
    let nodes = 0;
    return (depth) => {
      if (depth > MAX_DEPTH || ++nodes > MAX_NODES) throw new Error('fixture-limit');
    };
  }
  async function encode(value, visit, parents = new Set(), depth = 0) {
    visit(depth);
    if (value === null || typeof value === 'string' || typeof value === 'boolean') return ['primitive', value];
    if (typeof value === 'number' && Number.isFinite(value)) return ['primitive', value];
    if (value === undefined) return ['undefined'];
    if (typeof value !== 'object' || parents.has(value)) throw new Error('unsupported-fixture-value');
    const next = new Set(parents).add(value);
    const child = (item) => encode(item, visit, next, depth + 1);
    if (value instanceof CryptoKey) {
      // Never silently replace a nonextractable key with {} or a missing value.
      if (!value.extractable) throw new Error('nonextractable-key');
      if (value.algorithm.name !== 'HMAC') throw new Error('unsupported-key-algorithm');
      return ['hmac-key', await crypto.subtle.exportKey('jwk', value), value.extractable, [...value.usages]];
    }
    if (value instanceof ArrayBuffer) return ['array-buffer', bytes(value)];
    if (value instanceof Uint8Array) return ['uint8-array', Array.from(value)];
    if (value instanceof Date && Number.isFinite(value.getTime())) return ['date', value.toISOString()];
    if (value instanceof Blob) return ['blob', value.type, bytes(await value.arrayBuffer())];
    if (value instanceof Map) return ['map', await Promise.all([...value].map(async ([key, item]) => [await child(key), await child(item)]))];
    if (Array.isArray(value)) return ['array', await Promise.all(value.map(child))];
    if (Object.getPrototypeOf(value) !== Object.prototype && Object.getPrototypeOf(value) !== null) throw new Error('unsupported-fixture-value');
    return ['object', await Promise.all(Object.entries(value).map(async ([key, item]) => [key, await child(item)]))];
  }
  function byteArray(value) {
    if (!Array.isArray(value) || value.length > MAX_BYTES || value.some((n) => !Number.isInteger(n) || n < 0 || n > 255)) throw new Error('invalid-bytes');
    return new Uint8Array(value);
  }
  async function decode(value, visit, depth = 0) {
    visit(depth);
    if (!Array.isArray(value) || typeof value[0] !== 'string') throw new Error('invalid-tag');
    const child = (item) => decode(item, visit, depth + 1);
    switch (value[0]) {
      case 'primitive':
        if (value.length !== 2 || !(value[1] === null || ['string', 'boolean'].includes(typeof value[1]) || typeof value[1] === 'number' && Number.isFinite(value[1]))) throw new Error('invalid-primitive');
        return value[1];
      case 'undefined':
        if (value.length !== 1) throw new Error('invalid-undefined');
        return undefined;
      case 'array-buffer': return byteArray(value[1]).buffer;
      case 'uint8-array': return byteArray(value[1]);
      case 'date': {
        const date = new Date(value[1]);
        if (!Number.isFinite(date.getTime()) || date.toISOString() !== value[1]) throw new Error('invalid-date');
        return date;
      }
      case 'blob': return new Blob([byteArray(value[2])], { type: value[1] });
      case 'array': return Promise.all(value[1].map(child));
      case 'map': return new Map(await Promise.all(value[1].map(async ([key, item]) => [await child(key), await child(item)])));
      case 'object': {
        const result = Object.create(null);
        for (const [key, item] of value[1]) {
          if (typeof key !== 'string' || Object.hasOwn(result, key)) throw new Error('invalid-object-key');
          Object.defineProperty(result, key, { value: await child(item), enumerable: true, writable: true, configurable: true });
        }
        return result;
      }
      case 'hmac-key': {
        if (value[2] !== true || !Array.isArray(value[3]) || value[3].some((usage) => !['sign', 'verify'].includes(usage))) throw new Error('invalid-key');
        return crypto.subtle.importKey('jwk', value[1], { name: 'HMAC', hash: 'SHA-256' }, true, value[3]);
      }
      default: throw new Error('unsupported-fixture-tag');
    }
  }
  const storageEntries = (storage) => Array.from({ length: storage.length }, (_, i) => {
    const key = storage.key(i);
    return [key, storage.getItem(key)];
  });
  function validateStorage(values) {
    if (!Array.isArray(values) || values.length > 20 || values.some((entry) => !Array.isArray(entry) || entry.length !== 2 || entry.some((item) => typeof item !== 'string'))) throw new Error('invalid-storage');
  }
  async function exportFixture() {
    const visit = budget();
    const records = [];
    for (const [key, value] of await entries()) records.push([await encode(key, visit), await encode(value, visit)]);
    const archive = JSON.stringify({ format: 'owned-fixture-spike', version: 1, records, local: storageEntries(localStorage), session: storageEntries(sessionStorage) });
    if (utf8.encode(archive).length > MAX_BYTES) throw new Error('fixture-limit');
    return archive;
  }
  async function importFixture(archive) {
    if (typeof archive !== 'string' || utf8.encode(archive).length > MAX_BYTES) throw new Error('fixture-limit');
    const value = JSON.parse(archive);
    if (value.format !== 'owned-fixture-spike' || value.version !== 1 || !Array.isArray(value.records) || value.records.length > 20) throw new Error('invalid-fixture-envelope');
    validateStorage(value.local);
    validateStorage(value.session);
    const visit = budget();
    const records = [];
    // Complete all async type/key validation before opening the write transaction.
    for (const [key, item] of value.records) records.push([await decode(key, visit), await decode(item, visit)]);
    if ((await entries()).length || localStorage.length || sessionStorage.length) throw new Error('target-not-empty');
    await writeAll(records);
    for (const [key, item] of value.local) localStorage.setItem(key, item);
    for (const [key, item] of value.session) sessionStorage.setItem(key, item);
    return true;
  }
  async function seed() {
    const exportable = await crypto.subtle.generateKey({ name: 'HMAC', hash: 'SHA-256', length: 256 }, true, ['sign', 'verify']);
    const locked = await crypto.subtle.generateKey({ name: 'HMAC', hash: 'SHA-256', length: 256 }, false, ['sign', 'verify']);
    const buffer = new Uint8Array([2, 3, 5, 7]).buffer;
    await writeAll([
      ['structured', { text: 'owned-fixture', binary: buffer, view: new Uint8Array(buffer, 1, 2), date: new Date('2026-01-02T03:04:05.000Z'), map: new Map([['a', 2], [9, new Uint8Array([4, 6])]]), blob: new Blob(['owned blob'], { type: 'text/plain' }), list: [null, true, undefined, 4] }],
      ['portable-key', exportable], ['locked-key', locked],
    ]);
    localStorage.setItem('owned-local', 'local-value');
    sessionStorage.setItem('owned-session', 'session-value');
    return true;
  }
  async function exportabilityEvidence() {
    const values = new Map(await entries());
    const locked = values.get('locked-key');
    let errorName = null;
    try { await crypto.subtle.exportKey('jwk', locked); } catch (error) { errorName = error.name; }
    const signature = await crypto.subtle.sign('HMAC', locked, challenge);
    let emittedArchive = null;
    let rejectedReason = null;
    try { emittedArchive = await exportFixture(); } catch (error) { rejectedReason = error.message; }
    const afterExport = new Map(await entries());
    return {
      persistedCryptoKey: locked instanceof CryptoKey,
      nonextractable: locked.extractable === false,
      canStillSign: await crypto.subtle.verify('HMAC', locked, signature, challenge),
      exportError: errorName,
      naiveJSONLosesKey: JSON.stringify(locked) === '{}',
      archiveNotEmitted: emittedArchive === null,
      exportRejectedReason: rejectedReason,
      sourceRecordCount: afterExport.size,
      sourceKeysPreserved: JSON.stringify([...afterExport.keys()]) === JSON.stringify([...values.keys()]),
    };
  }
  async function removeLockedKey() {
    const database = await open();
    try {
      const transaction = database.transaction(STORE, 'readwrite');
      const done = transactionDone(transaction);
      transaction.objectStore(STORE).delete('locked-key');
      await done;
    } finally { database.close(); }
  }
  async function signature() {
    const key = new Map(await entries()).get('portable-key');
    return bytes(await crypto.subtle.sign('HMAC', key, challenge));
  }
  async function inspect() {
    const values = new Map(await entries());
    const item = values.get('structured');
    const key = values.get('portable-key');
    return {
      count: values.size,
      arrayBuffer: item?.binary instanceof ArrayBuffer && bytes(item.binary).join() === '2,3,5,7',
      uint8Array: item?.view instanceof Uint8Array && item.view.join() === '3,5',
      date: item?.date instanceof Date && item.date.toISOString() === '2026-01-02T03:04:05.000Z',
      map: item?.map instanceof Map && item.map.get('a') === 2 && item.map.get(9) instanceof Uint8Array && item.map.get(9).join() === '4,6',
      blob: item?.blob instanceof Blob && item.blob.type === 'text/plain' && await item.blob.text() === 'owned blob',
      primitiveArray: Array.isArray(item?.list) && item.list[0] === null && item.list[1] === true && item.list[2] === undefined && item.list[3] === 4,
      keyType: key instanceof CryptoKey && key.type === 'secret' && key.extractable && key.algorithm.name === 'HMAC' && key.usages.join() === 'sign,verify',
      local: localStorage.getItem('owned-local') === 'local-value',
      session: sessionStorage.getItem('owned-session') === 'session-value',
    };
  }
  async function empty() { return !(await entries()).length && !localStorage.length && !sessionStorage.length; }
  async function rejectMalformed(archive) {
    let failed = false;
    try { await importFixture(archive); } catch { failed = true; }
    return failed && await empty();
  }
  globalThis.ownedPortabilityProbe = { seed, exportabilityEvidence, removeLockedKey, exportFixture, importFixture, signature, inspect, empty, rejectMalformed };
})();
