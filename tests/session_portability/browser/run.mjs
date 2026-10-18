#!/usr/bin/env node
// Disposable browser contexts, local fixture only. Never visits WhatsApp.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { access, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const fixture = await readFile(resolve(here, 'fixture.js'), 'utf8');
const output = resolve(process.argv[2] || resolve(here, '../../../build/session-portability-browser-latest'));
const chromePath = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const profile = await mkdtemp(resolve(tmpdir(), 'profile-desk-portability-'));
const delay = (ms) => new Promise((done) => setTimeout(done, ms));
const checks = [];
const connections = [];
const contexts = [];
let browser;
let chrome;
let servedRequests = 0;
let blockedRequests = 0;
let failure;
let archive;
let version;
let evidence = {};
const cleanup = { processExited: false, serverClosed: false, profileRemoved: false };
const check = (name, value) => { assert.ok(value, name); checks.push({ name, pass: true }); };
const server = createServer((request, response) => {
  servedRequests += 1;
  response.writeHead(200, { 'Content-Type': 'text/html', 'Cache-Control': 'no-store', 'Content-Security-Policy': "default-src 'none'" });
  response.end('<!doctype html><meta charset="utf-8"><title>Owned portability fixture</title>');
});
function connect(url) {
  return new Promise((resolveConnection, reject) => {
    const socket = new WebSocket(url);
    const replies = new Map();
    const handlers = new Map();
    let sequence = 0;
    const send = (method, params = {}) => new Promise((done, failed) => {
      const id = ++sequence;
      const timer = setTimeout(() => { replies.delete(id); failed(new Error(`CDP timeout: ${method}`)); }, 15000);
      replies.set(id, { done, failed, timer });
      socket.send(JSON.stringify({ id, method, params }));
    });
    socket.onopen = () => resolveConnection({ send, handlers, close: () => socket.close() });
    socket.onerror = () => reject(new Error('owned browser connection failed'));
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
    socket.onclose = () => {
      for (const reply of replies.values()) { clearTimeout(reply.timer); reply.failed(new Error('owned browser closed')); }
      replies.clear();
    };
  });
}
function waitForProcessExit(process, timeout) {
  if (process.exitCode !== null || process.signalCode !== null) return Promise.resolve(true);
  return new Promise((done) => {
    const finished = () => { clearTimeout(timer); process.off('exit', finished); done(true); };
    const timer = setTimeout(() => { process.off('exit', finished); done(false); }, timeout);
    process.once('exit', finished);
  });
}

try {
  await mkdir(output, { recursive: true });
  await new Promise((done) => server.listen(0, '127.0.0.1', done));
  const origin = `http://127.0.0.1:${server.address().port}`;
  chrome = spawn(chromePath, [
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--disable-background-networking', '--disable-component-update', '--disable-sync',
    '--disable-default-apps', '--disable-extensions', '--metrics-recording-only',
    '--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1', '--no-proxy-server',
    '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank',
  ], { stdio: 'ignore' });
  let port;
  let browserPath;
  for (let i = 0; i < 240; i += 1) {
    try { [port, browserPath] = (await readFile(resolve(profile, 'DevToolsActivePort'), 'utf8')).split('\n'); break; } catch { await delay(25); }
  }
  assert.ok(port && browserPath, 'owned headless browser started');
  browser = await connect(`ws://127.0.0.1:${port}${browserPath}`);
  version = await browser.send('Browser.getVersion');
  async function page() {
    const { browserContextId } = await browser.send('Target.createBrowserContext', { disposeOnDetach: true });
    contexts.push(browserContextId);
    const { targetId } = await browser.send('Target.createTarget', { url: 'about:blank', browserContextId });
    const connection = await connect(`ws://127.0.0.1:${port}/devtools/page/${targetId}`);
    connections.push(connection);
    connection.handlers.set('Fetch.requestPaused', [({ requestId, request }) => {
      const allowed = new URL(request.url).origin === origin;
      if (!allowed) blockedRequests += 1;
      connection.send(allowed ? 'Fetch.continueRequest' : 'Fetch.failRequest', allowed ? { requestId } : { requestId, errorReason: 'BlockedByClient' }).catch(() => {});
    }]);
    await connection.send('Fetch.enable', { patterns: [{ urlPattern: '*', requestStage: 'Request' }] });
    await connection.send('Page.enable');
    await connection.send('Runtime.enable');
    const evaluate = async (expression) => {
      const result = await connection.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      // Deliberately omit exception content: it could contain serialized test data.
      if (result.exceptionDetails) throw new Error('owned fixture evaluation failed');
      return result.result.value;
    };
    await connection.send('Page.navigate', { url: `${origin}/fixture` });
    let ready = false;
    for (let i = 0; i < 100; i += 1) {
      if (await evaluate(`location.origin === ${JSON.stringify(origin)} && document.readyState === 'complete'`)) { ready = true; break; }
      await delay(25);
    }
    assert.ok(ready, 'local fixture loaded');
    await evaluate(fixture);
    return { browserContextId, evaluate, connection };
  }
  const source = await page();
  check('owned loopback fixture is a secure WebCrypto context', await source.evaluate('isSecureContext && !!crypto.subtle'));
  check('source context starts empty', await source.evaluate('ownedPortabilityProbe.empty()'));
  await source.evaluate('ownedPortabilityProbe.seed()');
  // Reload proves IndexedDB persists the nonextractable key, without exporting it.
  await source.evaluate('globalThis.ownedReloadSentinel = true');
  const loaded = new Promise((done, failed) => {
    const timer = setTimeout(() => { source.connection.handlers.delete('Page.loadEventFired'); failed(new Error('owned fixture reload timed out')); }, 10000);
    source.connection.handlers.set('Page.loadEventFired', [() => {
      clearTimeout(timer);
      source.connection.handlers.delete('Page.loadEventFired');
      done();
    }]);
  });
  await source.connection.send('Page.reload');
  await loaded;
  check('reload replaced the old document and reached complete readiness before reinjection', await source.evaluate(`document.readyState === 'complete' && typeof ownedReloadSentinel === 'undefined' && typeof ownedPortabilityProbe === 'undefined'`));
  await source.evaluate(fixture);
  const locked = await source.evaluate('ownedPortabilityProbe.exportabilityEvidence()');
  check('IndexedDB retains a nonextractable CryptoKey across reload', locked.persistedCryptoKey && locked.nonextractable);
  check('stored nonextractable key still signs and verifies in its source context', locked.canStillSign);
  check('WebCrypto rejects nonextractable key export with InvalidAccessError', locked.exportError === 'InvalidAccessError');
  check('naive JSON serializes nonextractable CryptoKey as an empty object', locked.naiveJSONLosesKey);
  check('unsupported key aborts export before emitting any archive', locked.archiveNotEmitted && locked.exportRejectedReason === 'nonextractable-key');
  check('rereading after failed export confirms source record count and keys remain unchanged', locked.sourceRecordCount === 3 && locked.sourceKeysPreserved);
  const target = await page();
  check('target uses a distinct browser storage context', source.browserContextId !== target.browserContextId);
  check('target has no source IndexedDB or web storage before restore', await target.evaluate('ownedPortabilityProbe.empty()'));
  check('oversized import is rejected without creating target records', await target.evaluate(`ownedPortabilityProbe.rejectMalformed('x'.repeat(128 * 1024 + 1))`));
  check('unsupported value tag rejects import before target writes', await target.evaluate(`ownedPortabilityProbe.rejectMalformed(JSON.stringify({ format: 'owned-fixture-spike', version: 1, records: [[['primitive', 'fixture-key'], ['unknown-tag']]], local: [], session: [] }))`));
  await source.evaluate('ownedPortabilityProbe.removeLockedKey()');
  archive = await source.evaluate('ownedPortabilityProbe.exportFixture()');
  const sourceSignature = await source.evaluate('ownedPortabilityProbe.signature()');
  check('supported tagged fixture archive remains within 128 KiB bound', Buffer.byteLength(archive) < 128 * 1024);
  const archiveBytes = Buffer.byteLength(archive);
  await browser.send('Target.disposeBrowserContext', { browserContextId: source.browserContextId });
  contexts.splice(contexts.indexOf(source.browserContextId), 1);
  check('source context is destroyed before target restore', !(await browser.send('Target.getBrowserContexts')).browserContextIds.includes(source.browserContextId));
  await target.evaluate(`ownedPortabilityProbe.importFixture(${JSON.stringify(archive)})`);
  archive = undefined;
  const restored = await target.evaluate('ownedPortabilityProbe.inspect()');
  check('target contains exactly the two supported fixture records', restored.count === 2);
  for (const type of ['arrayBuffer', 'uint8Array', 'date', 'map', 'blob', 'primitiveArray', 'keyType', 'local', 'session']) check(`target restores ${type} with its type and value preserved`, restored[type]);
  const targetSignature = await target.evaluate('ownedPortabilityProbe.signature()');
  check('restored exportable key reproduces source cryptographic challenge result', JSON.stringify(targetSignature) === JSON.stringify(sourceSignature));
  check('loopback fixture was served without any external page request', servedRequests >= 2 && blockedRequests === 0);
  evidence = {
    browser: version, archiveBytes,
    scope: 'Test-only owned fixture in two isolated disposable Chrome storage contexts. Local loopback requests only; no WhatsApp, user browser profile, real session, chat, QR, or cookie was accessed.',
    limits: 'Only a known IndexedDB database and selected web storage were covered. No native iOS or Android portability claim, full browser profile export, service-worker/cache/HTTP-only-cookie coverage, platform keystore access, or real WhatsApp authenticated restore is demonstrated. The transient archive contained an exportable synthetic key, stayed in process memory and was not written to disk. Nonextractable keys remain unsupported and cause export rejection.',
  };
} catch (error) {
  failure = error;
} finally {
  archive = undefined;
  for (const context of contexts) try { await browser?.send('Target.disposeBrowserContext', { browserContextId: context }); } catch { /* Browser may have exited. */ }
  for (const connection of connections) connection.close();
  browser?.close();
  try {
    if (chrome) {
      chrome.kill('SIGTERM');
      cleanup.processExited = await waitForProcessExit(chrome, 2000);
      if (!cleanup.processExited) {
        chrome.kill('SIGKILL');
        cleanup.processExited = await waitForProcessExit(chrome, 5000);
      }
      assert.ok(cleanup.processExited, 'owned browser exited before profile removal');
    } else cleanup.processExited = true;
    await new Promise((done, failed) => server.close((error) => error ? failed(error) : done()));
    cleanup.serverClosed = true;
    await rm(profile, { recursive: true, force: true, maxRetries: 4, retryDelay: 100 });
    try { await access(profile); } catch (error) { if (error.code === 'ENOENT') cleanup.profileRemoved = true; else throw error; }
    check('cleanup confirms owned browser exit, closed server and removed temporary profile', cleanup.processExited && cleanup.serverClosed && cleanup.profileRemoved);
  } catch (error) { failure ||= error; }
}
await mkdir(output, { recursive: true });
await writeFile(resolve(output, 'result.json'), JSON.stringify({
  result: failure ? 'FAIL' : 'PASS', count: checks.length, checks, ...evidence,
  ...(failure ? { error: failure.message } : {}), servedRequests, blockedRequests, cleanup,
}, null, 2) + '\n');
if (failure) throw failure;
console.log(`PASS: ${checks.length} owned portability checks. Evidence: ${output}`);
