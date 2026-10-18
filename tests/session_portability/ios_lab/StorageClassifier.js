// Isolated-world, main-frame, fixed-origin diagnostic. Counts only; no export.
// This file is a WKWebView.callAsyncJavaScript function body, not a page script.
const limits = { databases: 12, stores: 64, records: 2000, nodes: 20000, depth: 20, milliseconds: 30000 };
const counts = {
  localStorage: 0, sessionStorage: 0,
  nodes: 0, primitive: 0, array: 0, object: 0, arrayBuffer: 0, typedArray: 0,
  date: 0, map: 0, set: 0, blob: 0, extractableKeys: 0, nonextractableKeys: 0,
  unsupported: 0, repeatedReferences: 0,
};
const progress = {
  databasesDiscovered: 0, databasesInventoried: 0, databasesStarted: 0, databasesCompleted: 0,
  storesDiscovered: 0, storesInventoried: 0, storesStarted: 0, storesCompleted: 0, storesSampled: 0, storesSkipped: 0,
  recordsInventoried: 0, recordsDiscovered: 0, recordsStarted: 0, recordsCompleted: 0,
  inventoryTruncated: 0, inventoryChanges: 0, countChanges: 0, inventoryFailures: 0,
};
// Fixed numeric categories only. Never return raw algorithm dictionaries,
// parameter values, identifiers, usage strings, or any cryptographic material.
const algorithmCategories = ['other', 'AES-GCM', 'AES-CBC', 'AES-CTR', 'AES-KW', 'HMAC', 'HKDF', 'PBKDF2', 'RSA-OAEP', 'RSA-PSS', 'RSASSA-PKCS1-v1_5', 'ECDSA', 'ECDH', 'Ed25519', 'X25519'];
const typeCategories = ['other', 'secret', 'public', 'private'];
const usageCategories = ['other', 'encrypt', 'decrypt', 'sign', 'verify', 'deriveKey', 'deriveBits', 'wrapKey', 'unwrapKey'];
const keyMetadata = {
  algorithms: algorithmCategories.map(() => 0),
  types: typeCategories.map(() => 0),
  usages: usageCategories.map(() => 0),
};
const category = (categories, value) => Math.max(0, categories.indexOf(value));
// Descriptors contain only transient database/store metadata, never record keys.
const descriptors = [];
const databaseStates = [];
const finish = (status, reason) => {
  progress.storesSkipped = progress.storesDiscovered - progress.storesStarted;
  progress.databasesCompleted = databaseStates.filter(state => state.inventoryComplete && !state.changed && !state.failed && state.fullStores === state.names.length).length;
  return { schemaVersion: 3, status, reason, counts: { ...counts }, progress: { ...progress },
    keyMetadata: Object.fromEntries(Object.entries(keyMetadata).map(([name, values]) => [name, [...values]])) };
};
if (self !== top || location.protocol !== 'https:' || location.hostname !== 'web.whatsapp.com' || location.port && location.port !== '443') return finish('refused', 'origin');
if (!isSecureContext || typeof indexedDB?.databases !== 'function') return finish('inconclusive', 'apiUnavailable');
// scanToken is an app-generated UUID passed as a callAsyncJavaScript argument.
// Replacing it cancels older invocations permanently; a new scan cannot reset
// a shared Boolean and accidentally revive an older pending read.
globalThis.__profileDeskPortabilityToken = scanToken;
const cancelled = () => globalThis.__profileDeskPortabilityToken !== scanToken;
const deadline = performance.now() + limits.milliseconds;
const ownedConnections = new Set();
const ownedTransactions = new Set();
let stopped = false;
let limitReason = null;
function guard(depth = 0) {
  if (stopped || cancelled()) throw new Error('cancelled');
  if (performance.now() >= deadline) { limitReason = 'deadline'; throw new Error('deadline'); }
  if (depth > limits.depth || counts.nodes >= limits.nodes) { limitReason = 'scanLimit'; throw new Error('scanLimit'); }
}
function classify(value, seen, depth = 0) {
  guard(depth);
  counts.nodes += 1;
  if (value === null || typeof value !== 'object') { counts.primitive += 1; return; }
  if (seen.has(value)) { counts.repeatedReferences += 1; return; }
  seen.add(value);
  if (value instanceof CryptoKey) {
    if (value.extractable) counts.extractableKeys += 1;
    else counts.nonextractableKeys += 1;
    keyMetadata.algorithms[category(algorithmCategories, value.algorithm.name)] += 1;
    keyMetadata.types[category(typeCategories, value.type)] += 1;
    for (const usage of value.usages) keyMetadata.usages[category(usageCategories, usage)] += 1;
    return;
  }
  if (value instanceof ArrayBuffer) { counts.arrayBuffer += 1; return; }
  if (ArrayBuffer.isView(value)) { counts.typedArray += 1; return; }
  if (value instanceof Blob) { counts.blob += 1; return; }
  if (value instanceof Date) { counts.date += 1; return; }
  if (value instanceof Map) {
    counts.map += 1;
    for (const [key, item] of value) { classify(key, seen, depth + 1); classify(item, seen, depth + 1); }
    return;
  }
  if (value instanceof Set) {
    counts.set += 1;
    for (const item of value) classify(item, seen, depth + 1);
    return;
  }
  if (Array.isArray(value)) {
    counts.array += 1;
    for (let i = 0; i < value.length; i += 1) classify(value[i], seen, depth + 1);
    return;
  }
  if (Object.getPrototypeOf(value) === Object.prototype || Object.getPrototypeOf(value) === null) {
    counts.object += 1;
    // Property names are used transiently to traverse values; never returned.
    // No getters, string conversion, byte reads, or cryptographic operations.
    for (const name of Object.keys(value)) {
      guard(depth);
      const property = Object.getOwnPropertyDescriptor(value, name);
      if (!property || !Object.hasOwn(property, 'value')) { counts.unsupported += 1; continue; }
      classify(property.value, seen, depth + 1);
    }
    return;
  }
  counts.unsupported += 1;
}
function fault(reason) { const error = new Error(reason); error.reason = reason; return error; }
function markChanged(state) {
  if (!state.changed) { state.changed = true; progress.inventoryChanges += 1; }
}
function close(database) { database.close(); ownedConnections.delete(database); }
function openExisting(state) {
  return new Promise((resolve, reject) => {
    guard();
    if (typeof state.name !== 'string' || !Number.isSafeInteger(state.version) || state.version < 1) { reject(fault('readFailure')); return; }
    let settled = false;
    const fail = reason => { if (!settled) { settled = true; reject(fault(reason)); } };
    const request = indexedDB.open(state.name, state.version);
    request.onupgradeneeded = () => {
      // Deleted databases must not be recreated, including after cancellation.
      request.transaction?.abort();
      request.result.close();
      fail('inventoryChanged');
    };
    request.onblocked = () => fail('readFailure');
    request.onerror = () => fail(request.error?.name === 'VersionError' ? 'inventoryChanged' : 'readFailure');
    request.onsuccess = () => {
      const database = request.result;
      try { guard(); } catch { database.close(); fail('cancelled'); return; }
      if (settled) { database.close(); return; }
      settled = true;
      ownedConnections.add(database);
      database.onversionchange = () => {
        if (!stopped && !cancelled()) markChanged(state);
        for (const transaction of ownedTransactions) if (transaction.db === database) try { transaction.abort(); } catch { /* Already ended. */ }
        close(database);
      };
      resolve(database);
    };
  });
}
function countStore(database, name) {
  return new Promise((resolve, reject) => {
    guard();
    const transaction = database.transaction(name, 'readonly');
    ownedTransactions.add(transaction);
    let count;
    const fail = () => { ownedTransactions.delete(transaction); reject(fault('readFailure')); };
    transaction.onerror = fail;
    transaction.onabort = fail;
    transaction.oncomplete = () => {
      ownedTransactions.delete(transaction);
      try { guard(); if (!Number.isSafeInteger(count) || count < 0) throw fault('readFailure'); resolve(count); }
      catch (error) { reject(error); }
    };
    const request = transaction.objectStore(name).count();
    request.onerror = fail;
    request.onsuccess = () => { try { guard(); count = request.result; } catch (error) { try { transaction.abort(); } catch {} reject(error); } };
  });
}
function addCount(field, count) {
  if (!Number.isSafeInteger(count) || count < 0 || !Number.isSafeInteger(progress[field] + count)) throw fault('readFailure');
  progress[field] += count;
}
function sameSchema(database, state) {
  return database.version === state.version && database.objectStoreNames.length === state.names.length &&
    state.names.every((name, index) => database.objectStoreNames[index] === name);
}
function scanPrefix(database, descriptor, remainingStores) {
  return new Promise((resolve, reject) => {
    guard();
    const transaction = database.transaction(descriptor.name, 'readonly');
    ownedTransactions.add(transaction);
    let scanned = 0;
    let quota;
    let currentCount;
    const fail = () => { ownedTransactions.delete(transaction); reject(fault('readFailure')); };
    const abort = error => { try { transaction.abort(); } catch { /* Already ended. */ } reject(error); };
    transaction.onerror = fail;
    transaction.onabort = fail;
    transaction.oncomplete = () => {
      ownedTransactions.delete(transaction);
      try {
        // Node budget can be exactly exhausted by the last completed record;
        // completion itself performs no additional value read/classification.
        if (stopped || cancelled()) throw fault('cancelled');
        if (performance.now() >= deadline) { limitReason = 'deadline'; throw fault('deadline'); }
        if (scanned !== quota || currentCount === undefined) throw fault('readFailure');
        resolve(currentCount > quota);
      } catch (error) { reject(error); }
    };
    const store = transaction.objectStore(descriptor.name);
    const total = store.count();
    total.onerror = fail;
    total.onsuccess = () => {
      try {
        guard();
        currentCount = total.result;
        addCount('recordsDiscovered', currentCount);
        if (currentCount !== descriptor.count) progress.countChanges += 1;
        quota = Math.min(currentCount, Math.floor((limits.records - progress.recordsStarted) / remainingStores));
        if (quota === 0) return;
        const request = store.openCursor();
        request.onerror = fail;
        request.onsuccess = () => {
          try {
            guard();
            const cursor = request.result;
            if (!cursor || scanned >= quota || progress.recordsStarted >= limits.records) throw fault('readFailure');
            progress.recordsStarted += 1;
            classify(cursor.value, new WeakSet());
            progress.recordsCompleted += 1;
            scanned += 1;
            // One prefix only. Do not fetch a further cursor/value at quota.
            // count() and this prefix share the same readonly transaction.
            if (scanned < quota) cursor.continue();
          } catch (error) { abort(error); }
        };
      } catch (error) { abort(error); }
    };
  });
}
function handleFailure(error, state) {
  guard(); // Cancellation/deadline/node limits must terminate, not continue.
  if (limitReason) throw error;
  if (state.changed || error.reason === 'inventoryChanged') markChanged(state);
  else { state.failed = true; progress.inventoryFailures += 1; }
}
let timer;
try {
  const work = (async () => {
    guard();
    counts.localStorage = localStorage.length;
    counts.sessionStorage = sessionStorage.length;
    const databases = await indexedDB.databases();
    guard();
    progress.databasesDiscovered = databases.length;
    if (databases.length > limits.databases) { limitReason = 'scanLimit'; throw new Error('scanLimit'); }
    // Metadata inventory first: no record values are read in this phase.
    for (const item of databases) {
      guard();
      const state = { name: item.name, version: item.version, names: [], inventoryComplete: false,
        changed: false, failed: false, started: false, fullStores: 0 };
      databaseStates.push(state);
      let database;
      try {
        database = await openExisting(state);
        guard();
        state.names = Array.from(database.objectStoreNames);
        progress.storesDiscovered += state.names.length;
        let inventoried = 0;
        for (const name of state.names) {
          guard();
          if (descriptors.length >= limits.stores) { progress.inventoryTruncated = 1; break; }
          const count = await countStore(database, name);
          guard();
          if (state.changed) throw fault('inventoryChanged');
          addCount('recordsInventoried', count);
          descriptors.push({ state, name, count, ordinal: descriptors.length });
          progress.storesInventoried += 1;
          inventoried += 1;
        }
        state.inventoryComplete = inventoried === state.names.length && !state.changed;
        if (state.inventoryComplete) progress.databasesInventoried += 1;
        if (state.names.length === 0) { state.started = true; progress.databasesStarted += 1; }
      } catch (error) { handleFailure(error, state); }
      finally { if (database) close(database); }
    }
    // Small stores finish first; a large prefix cannot spend the budget that
    // is reserved for later descriptors. Counts may change between phases.
    descriptors.sort((a, b) => a.count - b.count || a.ordinal - b.ordinal);
    for (let index = 0; index < descriptors.length; index += 1) {
      guard();
      const descriptor = descriptors[index];
      const state = descriptor.state;
      if (state.changed || state.failed) continue;
      if (!state.started) { state.started = true; progress.databasesStarted += 1; }
      let database;
      try {
        database = await openExisting(state);
        guard();
        if (!sameSchema(database, state)) throw fault('inventoryChanged');
        progress.storesStarted += 1;
        const sampled = await scanPrefix(database, descriptor, descriptors.length - index);
        if (stopped || cancelled()) throw fault('cancelled');
        if (state.changed) throw fault('inventoryChanged');
        if (sampled) progress.storesSampled += 1;
        else { progress.storesCompleted += 1; state.fullStores += 1; }
      } catch (error) { handleFailure(error, state); }
      finally { if (database) close(database); }
    }
    if (progress.inventoryChanges) return finish('inconclusive', 'inventoryChanged');
    if (progress.inventoryFailures) return finish('inconclusive', 'readFailure');
    if (progress.inventoryTruncated) return finish('inconclusive', 'scanLimit');
    if (progress.countChanges) return finish('inconclusive', 'countChanged');
    if (progress.storesSampled) return finish('inconclusive', 'coverageLimited');
    return counts.unsupported ? finish('inconclusive', 'unsupportedType') : finish('complete', 'observedTypesOnly');
  })();
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => { limitReason = 'deadline'; stopped = true; reject(new Error('deadline')); }, limits.milliseconds);
  });
  return await Promise.race([work, timeout]);
} catch {
  return finish('inconclusive', limitReason || (cancelled() ? 'cancelled' : 'readFailure'));
} finally {
  stopped = true;
  clearTimeout(timer);
  for (const transaction of ownedTransactions) try { transaction.abort(); } catch { /* Read already ended. */ }
  for (const database of ownedConnections) database.close();
  ownedTransactions.clear();
  ownedConnections.clear();
  descriptors.length = 0;
  for (const state of databaseStates) { state.name = null; state.names.length = 0; }
  databaseStates.length = 0;
  if (!cancelled()) globalThis.__profileDeskPortabilityToken = null;
}
