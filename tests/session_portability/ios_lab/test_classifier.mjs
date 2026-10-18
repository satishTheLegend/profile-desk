#!/usr/bin/env node
// Exact lab classifier, owned synthetic fixture. No actual service access.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { access, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const classifierBytes = await readFile(resolve(here, 'StorageClassifier.js'));
const classifier = classifierBytes.toString('utf8');
const classifierSHA256 = createHash('sha256').update(classifierBytes).digest('hex');
const runnerSHA256 = createHash('sha256').update(await readFile(fileURLToPath(import.meta.url))).digest('hex');
const output = resolve(process.argv[2] || resolve(here, '../../../build/session-portability-lab-classifier-' + new Date().toISOString().replaceAll(/[:.]/g, '-')));
const profile = await mkdtemp(resolve(tmpdir(), 'profiledesk-lab-classifier-'));
const delay = (ms) => new Promise((done) => setTimeout(done, ms));
const checks = [];
const cleanup = { processExited: false, profileRemoved: false };
let chrome;
let socket;
let sequence = 0;
let scanSequence = 0;
let world;
let failure;
let version;
let fulfilledRequests = 0;
const replies = new Map();
const handlers = new Map();
const check = (name, result) => { assert.ok(result, name); checks.push({ name, pass: true }); };
function send(method, params = {}) {
  return new Promise((done, failed) => {
    const id = ++sequence;
    const timer = setTimeout(() => { replies.delete(id); failed(new Error(`CDP timeout: ${method}`)); }, 45000);
    replies.set(id, { done, failed, timer });
    socket.send(JSON.stringify({ id, method, params }));
  });
}
async function evaluate(expression, isolated = false) {
  const result = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true, ...(isolated ? { contextId: world } : {}) });
  if (result.exceptionDetails) throw new Error('Owned classifier fixture evaluation failed');
  return result.result.value;
}
const scan = () => evaluate(`(async () => { const scanToken = 'owned-scan-${++scanSequence}'; ${classifier}\n})()`, true);
async function navigate(url = 'https://web.whatsapp.com/') {
  const navigation = await send('Page.navigate', { url });
  let ready = false;
  for (let i = 0; i < 100; i += 1) {
    try {
      if (await evaluate(`location.href === ${JSON.stringify(url)} && document.readyState === 'complete'`)) { ready = true; break; }
    } catch { /* Navigation may replace the execution context between polls. */ }
    await delay(25);
  }
  assert.ok(ready, 'owned synthetic fixture loaded');
  world = (await send('Page.createIsolatedWorld', { frameId: navigation.frameId, worldName: 'ProfileDeskSessionLabCounts' })).executionContextId;
}
async function seed(expression, key = 'owned-record-marker') {
  return evaluate(`(async () => {
    const opened = indexedDB.open('owned-database-marker', 1);
    opened.onupgradeneeded = () => opened.result.createObjectStore('owned-store-marker');
    const db = await new Promise((done, fail) => { opened.onsuccess = () => done(opened.result); opened.onerror = () => fail(); });
    const value = await (async () => { ${expression} })();
    await new Promise((done, fail) => {
      const tx = db.transaction('owned-store-marker', 'readwrite');
      tx.oncomplete = done; tx.onerror = fail; tx.onabort = fail;
      tx.objectStore('owned-store-marker').put(value, ${JSON.stringify(key)});
    });
    db.close();
    return true;
  })()`);
}
async function reset() {
  await evaluate(`(async () => {
    for (const item of await indexedDB.databases()) await new Promise((done, fail) => {
      const request = indexedDB.deleteDatabase(item.name); request.onsuccess = done; request.onerror = fail; request.onblocked = fail;
    });
    localStorage.clear(); sessionStorage.clear();
  })()`);
}
function waitForExit(child, timeout) {
  if (child.exitCode !== null || child.signalCode !== null) return Promise.resolve(true);
  return new Promise((done) => {
    const exited = () => { clearTimeout(timer); child.off('exit', exited); done(true); };
    const timer = setTimeout(() => { child.off('exit', exited); done(false); }, timeout);
    child.once('exit', exited);
  });
}

try {
  await mkdir(output, { recursive: true });
  chrome = spawn(process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--disable-background-networking', '--disable-component-update', '--disable-sync',
    '--disable-default-apps', '--disable-extensions', '--metrics-recording-only',
    '--host-resolver-rules=MAP * ~NOTFOUND', '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank',
  ], { stdio: 'ignore' });
  let port;
  for (let i = 0; i < 240; i += 1) {
    try { [port] = (await readFile(resolve(profile, 'DevToolsActivePort'), 'utf8')).split('\n'); break; } catch { await delay(25); }
  }
  assert.ok(port, 'owned browser started');
  const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  socket = new WebSocket(targets.find((target) => target.type === 'page').webSocketDebuggerUrl);
  await new Promise((done, fail) => { socket.onopen = done; socket.onerror = fail; });
  socket.onmessage = ({ data }) => {
    const message = JSON.parse(data);
    if (message.id) {
      const reply = replies.get(message.id);
      replies.delete(message.id);
      if (!reply) return;
      clearTimeout(reply.timer);
      if (message.error) reply.failed(new Error(`CDP command failed: ${message.error.code}`));
      else reply.done(message.result);
    } else for (const handler of handlers.get(message.method) || []) handler(message.params);
  };
  handlers.set('Fetch.requestPaused', [({ requestId }) => {
    fulfilledRequests += 1;
    send('Fetch.fulfillRequest', { requestId, responseCode: 200,
      responseHeaders: [{ name: 'Content-Type', value: 'text/html' }, { name: 'Content-Security-Policy', value: "default-src 'none'" }],
      body: Buffer.from('<!doctype html><title>Owned classifier fixture</title>').toString('base64'),
    }).catch(() => {});
  }]);
  await send('Fetch.enable', { patterns: [{ urlPattern: '*', requestStage: 'Request' }] });
  await send('Page.enable');
  await send('Runtime.enable');
  version = await send('Browser.getVersion');
  await navigate();
  const empty = await scan();
  check('empty owned fixture returns complete counts without claiming portability', empty.status === 'complete' && empty.reason === 'observedTypesOnly' && empty.progress.recordsStarted === 0);
  await seed(`
    const extractable = await crypto.subtle.generateKey({name:'HMAC',hash:'SHA-256'}, true, ['sign']);
    const nonextractable = await crypto.subtle.generateKey({name:'HMAC',hash:'SHA-256'}, false, ['sign']);
    const value = { secretText: 'owned-sensitive-value-marker', nested: [extractable, { key: nonextractable }],
      buffer: new ArrayBuffer(8), typed: new Uint8Array([1, 2]), date: new Date(),
      map: new Map([['a', 1]]), set: new Set([2]), blob: new Blob(['owned-blob-content-marker']) };
    value.circular = value;
    return value;
  `);
  await evaluate(`localStorage.setItem('owned-local-key-marker','owned-local-value-marker'); sessionStorage.setItem('owned-session-key-marker','owned-session-value-marker')`);
  await evaluate(`(() => {
    globalThis.forbiddenCalls = 0;
    globalThis.writeTransactions = 0;
    const blocked = () => { forbiddenCalls += 1; throw new Error('forbidden read'); };
    for (const method of ['exportKey', 'wrapKey', 'sign', 'encrypt', 'decrypt']) crypto.subtle[method] = blocked;
    Storage.prototype.getItem = blocked;
    Blob.prototype.arrayBuffer = blocked;
    Blob.prototype.text = blocked;
    Object.defineProperty(document, 'cookie', {get:blocked});
    const transaction = IDBDatabase.prototype.transaction;
    IDBDatabase.prototype.transaction = function(...args) { if (args[1] !== 'readonly') writeTransactions += 1; return transaction.apply(this, args); };
  })()`, true);
  const observed = await scan();
  check('known structured values complete without reading record contents into report', observed.status === 'complete' && observed.progress.recordsCompleted === 1);
  check('successful coverage separates inventory, visits and full scans', ['databasesDiscovered','databasesInventoried','databasesStarted','databasesCompleted','storesDiscovered','storesInventoried','storesStarted','storesCompleted','recordsInventoried','recordsDiscovered','recordsStarted','recordsCompleted'].every(field => observed.progress[field] === 1) && ['storesSampled','storesSkipped','inventoryTruncated','inventoryChanges','countChanges','inventoryFailures'].every(field => observed.progress[field] === 0));
  check('nested extractable and nonextractable keys are counted separately', observed.counts.extractableKeys === 1 && observed.counts.nonextractableKeys === 1);
  check('key metadata is fixed numeric HMAC, secret and sign histograms', observed.keyMetadata.algorithms.length === 15 && observed.keyMetadata.algorithms[5] === 2 && observed.keyMetadata.algorithms.reduce((a, b) => a + b, 0) === 2 && observed.keyMetadata.types.length === 4 && observed.keyMetadata.types[1] === 2 && observed.keyMetadata.usages.length === 9 && observed.keyMetadata.usages[3] === 2);
  for (const kind of ['arrayBuffer', 'typedArray', 'date', 'map', 'set', 'blob']) check(`${kind} contributes only a type count`, observed.counts[kind] === 1);
  check('cyclic references terminate without recursion failure', observed.counts.repeatedReferences === 1);
  check('local and session storage use entry counts only', observed.counts.localStorage === 1 && observed.counts.sessionStorage === 1);
  check('no key operation, cookie read, blob read or web-storage value read occurred', await evaluate('forbiddenCalls === 0', true));
  check('every scan transaction was explicitly readonly', await evaluate('writeTransactions === 0', true));
  const wire = JSON.stringify(observed);
  check('report excludes database/store names, record keys and synthetic private values', !wire.includes('owned-') && !wire.includes('secretText') && !wire.includes('nested') && !wire.includes('key_ops'));
  check('report contains only declared schema and numeric count fields', observed.schemaVersion === 3 && Object.keys(observed).sort().join() === 'counts,keyMetadata,progress,reason,schemaVersion,status' && Object.values(observed.counts).every((value) => Number.isInteger(value) && value >= 0) && Object.values(observed.progress).every((value) => Number.isInteger(value) && value >= 0) && Object.values(observed.keyMetadata).every(values => values.every(value => Number.isInteger(value) && value >= 0)));
  const repeated = await scan();
  check('repeated scan preserves progress, type counts and key observations', JSON.stringify(repeated.counts) === JSON.stringify(observed.counts) && JSON.stringify(repeated.progress) === JSON.stringify(observed.progress) && JSON.stringify(repeated.keyMetadata) === JSON.stringify(observed.keyMetadata));
  await seed('return /unsupported-fixture-type/;', 'unknown-type');
  const unknown = await scan();
  check('unsupported values produce inconclusive rather than a portability success', unknown.status === 'inconclusive' && unknown.reason === 'unsupportedType' && unknown.counts.unsupported === 1);
  await reset();
  await seed(`globalThis.ownedDuplicateKey = await crypto.subtle.generateKey({name:'AES-GCM',length:256}, false, ['encrypt','decrypt']); return ownedDuplicateKey;`, 'first-key-occurrence');
  await seed('return ownedDuplicateKey;', 'second-key-occurrence');
  const duplicates = await scan();
  check('same synthetic key in two records is reported as two observations, not deduplicated identities', duplicates.counts.nonextractableKeys === 2 && duplicates.keyMetadata.algorithms[1] === 2 && duplicates.keyMetadata.types[1] === 2 && duplicates.keyMetadata.usages[1] === 2 && duplicates.keyMetadata.usages[2] === 2 && duplicates.progress.recordsCompleted === 2);
  await evaluate(`globalThis.originalKeyDescriptors = {};
    for (const field of ['algorithm','type','usages']) originalKeyDescriptors[field] = Object.getOwnPropertyDescriptor(CryptoKey.prototype, field);
    Object.defineProperty(CryptoKey.prototype, 'algorithm', {configurable:true,get:() => ({name:'owned-private-algorithm-marker',privateParameter:'owned-key-parameter-marker'})});
    Object.defineProperty(CryptoKey.prototype, 'type', {configurable:true,get:() => 'owned-private-type-marker'});
    Object.defineProperty(CryptoKey.prototype, 'usages', {configurable:true,get:() => ['owned-private-usage-marker']}); void 0;`, true);
  const otherMetadata = await scan();
  check('unknown key metadata maps only to numeric Other categories', otherMetadata.keyMetadata.algorithms[0] === 2 && otherMetadata.keyMetadata.types[0] === 2 && otherMetadata.keyMetadata.usages[0] === 2 && !JSON.stringify(otherMetadata).includes('owned-'));
  await evaluate(`for (const field of ['algorithm','type','usages']) Object.defineProperty(CryptoKey.prototype, field, originalKeyDescriptors[field]); void 0;`, true);
  check('metadata classification never calls cryptographic key operations', await evaluate('forbiddenCalls === 0', true));
  await reset();
  await seed('return {small:true};', 'a-complete');
  await seed('let value = {}; for (let i = 0; i < 25; i += 1) value = {nested: value}; return value;', 'z-incomplete');
  await evaluate(`(async () => { const request = indexedDB.open('owned-database-marker', 2); request.onupgradeneeded = () => request.result.createObjectStore('aaa-empty'); const db = await new Promise((done,fail) => { request.onsuccess=() => done(request.result); request.onerror=fail; }); db.close(); })()`);
  const deep = await scan();
  check('excessive nesting is bounded and inconclusive', deep.status === 'inconclusive' && deep.reason === 'scanLimit');
  check('partial traversal never marks the failing record, store or database completed', deep.progress.recordsDiscovered === 2 && deep.progress.recordsStarted === 2 && deep.progress.recordsCompleted === 1 && deep.progress.storesDiscovered === 2 && deep.progress.storesStarted === 2 && deep.progress.storesCompleted === 1 && deep.progress.databasesDiscovered === 1 && deep.progress.databasesStarted === 1 && deep.progress.databasesCompleted === 0);
  await reset();
  await seed('return Array.from({length:20001}, () => 1);');
  const nodes = await scan();
  check('visited-node limit is bounded and inconclusive', nodes.status === 'inconclusive' && nodes.reason === 'scanLimit' && nodes.counts.nodes <= 20000);
  check('a partially classified node-limited record is started but not completed', nodes.progress.recordsDiscovered === 1 && nodes.progress.recordsStarted === 1 && nodes.progress.recordsCompleted === 0);
  await reset();
  await seed('return 1;', 0);
  await evaluate(`(async () => { const request=indexedDB.open('owned-database-marker',1); const db=await new Promise((done,fail)=>{request.onsuccess=()=>done(request.result);request.onerror=fail;}); await new Promise((done,fail)=>{const tx=db.transaction('owned-store-marker','readwrite');tx.oncomplete=done;tx.onerror=fail; for(let i=1;i<=2000;i+=1)tx.objectStore('owned-store-marker').put(1,i);});db.close(); })()`);
  const recordLimit = await scan();
  check('extended scan retains the 2000-record cap without automatic escalation', recordLimit.status === 'inconclusive' && recordLimit.reason === 'coverageLimited' && recordLimit.progress.recordsDiscovered === 2001 && recordLimit.progress.recordsStarted === 2000 && recordLimit.progress.recordsCompleted === 2000 && recordLimit.progress.storesCompleted === 0 && recordLimit.progress.storesSampled === 1);
  await reset();
  await evaluate(`(async () => {
    const key = await crypto.subtle.generateKey({name:'AES-GCM',length:256}, false, ['encrypt','decrypt']);
    const request=indexedDB.open('owned-fair-fixture',1);
    request.onupgradeneeded=()=>{for(const name of ['aaa-large','bbb-large','zzz-key'])request.result.createObjectStore(name);};
    const db=await new Promise((done,fail)=>{request.onsuccess=()=>done(request.result);request.onerror=fail;});
    await new Promise((done,fail)=>{const tx=db.transaction(['aaa-large','bbb-large','zzz-key'],'readwrite');tx.oncomplete=done;tx.onerror=fail;
      for(const name of ['aaa-large','bbb-large'])for(let i=0;i<2001;i+=1)tx.objectStore(name).put(1,i);
      tx.objectStore('zzz-key').put(key,'owned-key-record-marker');}); db.close();
  })()`);
  await evaluate(`(() => {
    globalThis.prefixEvents = {}; globalThis.prefixContinues = {}; globalThis.prefixValues = {}; globalThis.prefixOrder = [];
    globalThis.originalOpenCursor = IDBObjectStore.prototype.openCursor;
    globalThis.originalContinue = IDBCursor.prototype.continue;
    globalThis.originalValue = Object.getOwnPropertyDescriptor(IDBCursorWithValue.prototype,'value');
    globalThis.originalCursorKeys = {};
    for(const field of ['key','primaryKey']){
      originalCursorKeys[field]=Object.getOwnPropertyDescriptor(IDBCursor.prototype,field);
      Object.defineProperty(IDBCursor.prototype,field,{configurable:true,get:()=>{throw new Error('record identifiers forbidden');}});
    }
    IDBObjectStore.prototype.openCursor=function(...args){
      const name=this.name; prefixOrder.push(name); const request=originalOpenCursor.apply(this,args);
      request.addEventListener('success',()=>{prefixEvents[name]=(prefixEvents[name]||0)+1;}); return request;
    };
    IDBCursor.prototype.continue=function(...args){const name=this.source.name;prefixContinues[name]=(prefixContinues[name]||0)+1;return originalContinue.apply(this,args);};
    Object.defineProperty(IDBCursorWithValue.prototype,'value',{configurable:true,get:function(){const name=this.source.name;prefixValues[name]=(prefixValues[name]||0)+1;return originalValue.get.call(this);}});
  })()`, true);
  const fair = await scan();
  check('large earlier stores cannot starve the later small key-holding store', fair.status === 'inconclusive' && fair.reason === 'coverageLimited' && fair.counts.nonextractableKeys === 1 && fair.progress.storesStarted === 3 && fair.progress.recordsStarted === 2000);
  check('small-store-first traversal completes one store and honestly marks two sampled prefixes', fair.progress.storesCompleted === 1 && fair.progress.storesSampled === 2 && fair.progress.storesSkipped === 0 && fair.progress.databasesCompleted === 0 && fair.progress.recordsInventoried === 4003 && fair.progress.recordsDiscovered === 4003);
  check('remaining budget is allocated to every remaining store without a second prefix', await evaluate(`prefixOrder.join() === 'zzz-key,aaa-large,bbb-large' && prefixValues['zzz-key'] === 1 && prefixValues['aaa-large'] === 999 && prefixValues['bbb-large'] === 1000`, true));
  check('cursor requests stop at quota without fetching an extra record or end cursor', await evaluate(`prefixEvents['zzz-key'] === 1 && prefixEvents['aaa-large'] === 999 && prefixEvents['bbb-large'] === 1000 && !prefixContinues['zzz-key'] && prefixContinues['aaa-large'] === 998 && prefixContinues['bbb-large'] === 999`, true));
  check('fair-prefix report contains no record identifiers or store names', !JSON.stringify(fair).includes('owned-') && !JSON.stringify(fair).includes('aaa-large') && !JSON.stringify(fair).includes('zzz-key'));
  check('scan leaves all source counts, primitive values and the stored nonextractable key intact', await evaluate(`(async()=>{
    const request=indexedDB.open('owned-fair-fixture',1);const db=await new Promise((done,fail)=>{request.onsuccess=()=>done(request.result);request.onerror=fail;});
    const result=await new Promise((done,fail)=>{const tx=db.transaction(['aaa-large','bbb-large','zzz-key'],'readonly');const values=[];
      for(const name of ['aaa-large','bbb-large','zzz-key']){const r=tx.objectStore(name).count();r.onsuccess=()=>values.push(r.result);}
      const primitive=tx.objectStore('aaa-large').get(2000);let primitiveOK=false;primitive.onsuccess=()=>{primitiveOK=primitive.result===1;};
      const key=tx.objectStore('zzz-key').get('owned-key-record-marker');let keyOK=false;key.onsuccess=()=>{keyOK=key.result instanceof CryptoKey && !key.result.extractable;};
      tx.oncomplete=()=>done(values.join()==='2001,2001,1' && primitiveOK && keyOK);tx.onerror=fail;});db.close();return result;
  })()`));
  await evaluate(`IDBObjectStore.prototype.openCursor=originalOpenCursor; IDBCursor.prototype.continue=originalContinue;
    Object.defineProperty(IDBCursorWithValue.prototype,'value',originalValue);
    for(const field of ['key','primaryKey'])Object.defineProperty(IDBCursor.prototype,field,originalCursorKeys[field]); void 0;`, true);
  await reset();
  await seed('return 1;');
  await evaluate(`globalThis.originalOpen = indexedDB.open.bind(indexedDB); globalThis.openCalls=0;
    indexedDB.open=function(name,version){const request=originalOpen(name,version);openCalls+=1;
      if(openCalls===2)request.addEventListener('success',()=>{const tx=request.result.transaction('owned-store-marker','readwrite');tx.objectStore('owned-store-marker').put(2,'owned-added-after-inventory');});return request;};`, true);
  const countChanged = await scan();
  check('count changes between inventory and visits use the current same-transaction count', countChanged.status === 'inconclusive' && countChanged.reason === 'countChanged' && countChanged.progress.countChanges === 1 && countChanged.progress.recordsInventoried === 1 && countChanged.progress.recordsDiscovered === 2 && countChanged.progress.recordsCompleted === 2 && countChanged.progress.storesCompleted === 1);
  await evaluate('indexedDB.open=originalOpen;', true);
  await reset();
  await seed('return 1;');
  await evaluate(`globalThis.openCalls=0; indexedDB.open=function(name,version){openCalls+=1;
    if(openCalls===2){const upgrade=originalOpen(name,version+1);upgrade.onupgradeneeded=()=>upgrade.result.createObjectStore('owned-new-schema');upgrade.onsuccess=()=>upgrade.result.close();}
    return originalOpen(name,version);};`, true);
  const versionChanged = await scan();
  check('version changes after inventory are inconclusive without retrying a stale descriptor', versionChanged.status === 'inconclusive' && versionChanged.reason === 'inventoryChanged' && versionChanged.progress.inventoryChanges === 1 && versionChanged.progress.storesInventoried === 1 && versionChanged.progress.storesStarted === 0 && versionChanged.progress.storesSkipped === 1 && versionChanged.progress.databasesCompleted === 0 && await evaluate('openCalls === 2', true));
  await evaluate('indexedDB.open=originalOpen;', true);
  await reset();
  await seed('return 1;');
  await evaluate(`globalThis.openCalls=0; indexedDB.open=function(...args){openCalls+=1;return originalOpen(...args);};
    globalThis.originalNames=Object.getOwnPropertyDescriptor(IDBDatabase.prototype,'objectStoreNames');
    Object.defineProperty(IDBDatabase.prototype,'objectStoreNames',{configurable:true,get:function(){return openCalls>=2 ? ['owned-different-schema'] : originalNames.get.call(this);}});void 0;`, true);
  const schemaChanged = await scan();
  check('schema mismatch is explicit and never marked as full coverage', schemaChanged.status === 'inconclusive' && schemaChanged.reason === 'inventoryChanged' && schemaChanged.progress.inventoryChanges === 1 && schemaChanged.progress.recordsStarted === 0 && schemaChanged.progress.storesCompleted === 0 && schemaChanged.progress.storesSkipped === 1);
  await evaluate(`indexedDB.open=originalOpen;Object.defineProperty(IDBDatabase.prototype,'objectStoreNames',originalNames);void 0;`, true);
  await reset();
  await seed('return 1;');
  await evaluate(`globalThis.openCalls=0; indexedDB.open=function(name,version){openCalls+=1;if(openCalls===2)indexedDB.deleteDatabase(name);return originalOpen(name,version);};`, true);
  const removedAfterInventory = await scan();
  check('database deleted after inventory is neither recreated nor reported scanned', removedAfterInventory.status === 'inconclusive' && removedAfterInventory.reason === 'inventoryChanged' && removedAfterInventory.progress.recordsStarted === 0 && removedAfterInventory.progress.storesSkipped === 1 && await evaluate(`(async()=>!(await indexedDB.databases()).some(item=>item.name==='owned-database-marker'))()`));
  await evaluate('indexedDB.open=originalOpen;', true);
  await reset();
  await evaluate(`(async () => { const request=indexedDB.open('owned-many-stores',1); request.onupgradeneeded=()=>{for(let i=0;i<65;i+=1)request.result.createObjectStore('owned-store-'+i);}; const db=await new Promise((done,fail)=>{request.onsuccess=()=>done(request.result);request.onerror=fail;});db.close(); })()`);
  const storeLimit = await scan();
  check('extended scan retains the 64-store cap with discovered coverage reported honestly', storeLimit.status === 'inconclusive' && storeLimit.reason === 'scanLimit' && storeLimit.progress.storesDiscovered === 65 && storeLimit.progress.storesStarted === 64 && storeLimit.progress.storesCompleted === 64 && storeLimit.progress.databasesCompleted === 0 && storeLimit.progress.storesInventoried === 64 && storeLimit.progress.storesSkipped === 1 && storeLimit.progress.inventoryTruncated === 1);
  await reset();
  await evaluate(`globalThis.originalDatabases = indexedDB.databases.bind(indexedDB); indexedDB.databases = async () => Array.from({length:13}, () => ({name:'owned-placeholder',version:1}));`, true);
  const many = await scan();
  check('database-count limit retains 12 while reporting all discovered candidates', many.status === 'inconclusive' && many.reason === 'scanLimit' && many.progress.databasesDiscovered === 13 && many.progress.databasesStarted === 0);
  await evaluate(`indexedDB.databases = async () => [{name:'owned-removed-before-open',version:1}];`, true);
  const raced = await scan();
  check('database removed between discovery/open yields inconclusive', raced.status === 'inconclusive' && raced.reason === 'inventoryChanged' && raced.progress.inventoryChanges === 1);
  check('raced missing database was not recreated', await evaluate(`(async () => !(await indexedDB.databases()).some(item => item.name === 'owned-removed-before-open'))()`));
  await evaluate('globalThis.pendingDiscovery = []; indexedDB.databases = () => new Promise(done => pendingDiscovery.push(done));', true);
  await evaluate(`globalThis.oldScanPromise = (async () => { const scanToken = 'old-overlapping-scan'; ${classifier}\n})(); void 0;`, true);
  await evaluate(`globalThis.newScanPromise = (async () => { const scanToken = 'new-overlapping-scan'; ${classifier}\n})(); void 0;`, true);
  check('overlapping synthetic scans both reached deferred discovery', await evaluate('pendingDiscovery.length === 2', true));
  // Simulate a delayed native cancellation for the old invocation. It must not
  // cancel the replacement invocation or let the old read resume as current.
  await evaluate(`if (globalThis.__profileDeskPortabilityToken === 'old-overlapping-scan') globalThis.__profileDeskPortabilityToken = null; for (const done of pendingDiscovery) done([]);`, true);
  const cancelledOld = await evaluate('oldScanPromise', true);
  const completedNew = await evaluate('newScanPromise', true);
  check('starting a new scan cannot revive the superseded scan', cancelledOld.status === 'inconclusive' && cancelledOld.reason === 'cancelled' && cancelledOld.progress.databasesStarted === 0);
  check('late cancellation of the previous token preserves the new scan', completedNew.status === 'complete');
  await evaluate('globalThis.pendingDiscovery = [];', true);
  await evaluate(`globalThis.manualCancelPromise = (async () => { const scanToken = 'manual-cancel-scan'; ${classifier}\n})(); void 0;`, true);
  await evaluate(`if(globalThis.__profileDeskPortabilityToken === 'manual-cancel-scan') globalThis.__profileDeskPortabilityToken = null; pendingDiscovery[0]([]);`, true);
  const manuallyCancelled = await evaluate('manualCancelPromise', true);
  check('manual matching-token cancellation discards a late discovery callback', manuallyCancelled.status === 'inconclusive' && manuallyCancelled.reason === 'cancelled' && manuallyCancelled.progress.databasesStarted === 0);
  await evaluate('indexedDB.databases = () => new Promise(done => { globalThis.lateDiscovery = done; });', true);
  const deadlineStart = performance.now();
  await evaluate(`globalThis.deadlineReportPromise = (async () => { const scanToken = 'deadline-scan'; ${classifier}\n})(); void 0;`, true);
  const deadline = await evaluate('deadlineReportPromise', true);
  check('unresponsive storage discovery ends at the thirty-second cooperative deadline', deadline.status === 'inconclusive' && deadline.reason === 'deadline' && performance.now() - deadlineStart >= 29000);
  await evaluate(`lateDiscovery([{name:'owned-late-database',version:1}]);`, true);
  const afterLate = await evaluate('deadlineReportPromise', true);
  check('callbacks arriving after deadline cannot change the completed report', JSON.stringify(afterLate) === JSON.stringify(deadline));
  await navigate('https://example.invalid/');
  check('foreign origin is refused before storage scanning', (await scan()).status === 'refused');
  await navigate('http://web.whatsapp.com/');
  check('non-HTTPS service origin is refused', (await scan()).status === 'refused');
  await navigate('https://web.whatsapp.com:444/');
  check('nondefault service port is refused', (await scan()).status === 'refused');
  check('all page requests were fulfilled by the owned fixture with DNS disabled', fulfilledRequests >= 4);
} catch (error) { failure = error; }
finally {
  socket?.close();
  try {
    if (chrome) {
      chrome.kill('SIGTERM');
      cleanup.processExited = await waitForExit(chrome, 2000);
      if (!cleanup.processExited) { chrome.kill('SIGKILL'); cleanup.processExited = await waitForExit(chrome, 5000); }
      assert.ok(cleanup.processExited, 'owned browser exited');
    } else cleanup.processExited = true;
    await rm(profile, { recursive: true, force: true, maxRetries: 4, retryDelay: 100 });
    try { await access(profile); } catch (error) { if (error.code === 'ENOENT') cleanup.profileRemoved = true; else throw error; }
    check('owned browser exits and its temporary profile is removed', cleanup.processExited && cleanup.profileRemoved);
  } catch (error) { failure ||= error; }
}
await mkdir(output, { recursive: true });
await writeFile(resolve(output, 'result.json'), JSON.stringify({
  result: failure ? 'FAIL' : 'PASS', count: checks.length, checks, cleanup, browser: version,
  classifierSHA256, runnerSHA256,
  fulfilledRequests, ...(failure ? { error: failure.message } : {}),
  scope: 'Exact bundled classifier in an isolated Chrome world with owned synthetic IndexedDB records. All requests locally fulfilled; no real service, account, QR, credentials, browser profile, iOS deployment or device access.',
  limits: 'Classifier behavior only. This does not prove iOS behavior, real WhatsApp storage characteristics, session archive completeness or restored authentication.',
}, null, 2) + '\n');
if (failure) throw failure;
console.log(`PASS: ${checks.length} owned lab classifier checks. Evidence: ${output}`);
