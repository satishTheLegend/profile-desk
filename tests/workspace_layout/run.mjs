#!/usr/bin/env node
// Dependency-free browser checks. Every request is fulfilled locally by CDP;
// the HTTPS hostname is synthetic so the production origin guard is exercised.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const source = await readFile(resolve(here, '../../packages/session_engine/layout/workspace_layout.js'), 'utf8');
const fixture = await readFile(resolve(here, 'fixture.html'), 'utf8');
const output = resolve(process.argv[2] || resolve(here, 'results'));
const chromePath = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const profile = await mkdtemp(resolve(tmpdir(), 'profile-desk-layout-'));
const delay = (ms) => new Promise((done) => setTimeout(done, ms));
const checks = [];
const requests = [];
let chrome;
let socket;

function check(name, value) { assert.ok(value, name); checks.push({ name, pass: true }); }

try {
  await mkdir(output, { recursive: true });
  chrome = spawn(chromePath, [
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--disable-background-networking', '--disable-component-update', '--disable-sync',
    '--disable-default-apps', '--disable-extensions', '--metrics-recording-only',
    '--host-resolver-rules=MAP * ~NOTFOUND', '--remote-debugging-port=0',
    `--user-data-dir=${profile}`, 'about:blank',
  ], { stdio: 'ignore' });
  let port;
  for (let attempt = 0; attempt < 200; attempt += 1) {
    try { port = (await readFile(resolve(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]; break; } catch { await delay(25); }
  }
  assert.ok(port, 'owned headless browser started');
  const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  const target = targets.find((item) => item.type === 'page');
  socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((done, reject) => { socket.onopen = done; socket.onerror = reject; });
  let sequence = 0;
  const replies = new Map();
  const handlers = new Map();
  const send = (method, params = {}) => new Promise((done, reject) => {
    const id = ++sequence;
    replies.set(id, { done, reject });
    socket.send(JSON.stringify({ id, method, params }));
  });
  socket.onmessage = ({ data }) => {
    const message = JSON.parse(data);
    if (message.id) {
      const reply = replies.get(message.id);
      replies.delete(message.id);
      if (message.error) reply?.reject(new Error(JSON.stringify(message.error)));
      else reply?.done(message.result);
    } else {
      for (const handler of handlers.get(message.method) || []) handler(message.params);
    }
  };
  handlers.set('Fetch.requestPaused', [({ requestId, request, resourceType }) => {
    requests.push({ url: request.url, local: true, resourceType });
    const body = resourceType === 'Document' ? fixture : '';
    send('Fetch.fulfillRequest', {
      requestId, responseCode: body ? 200 : 204,
      responseHeaders: [{ name: 'Content-Type', value: 'text/html; charset=utf-8' }],
      body: Buffer.from(body).toString('base64'),
    }).catch(() => {});
  }]);
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Fetch.enable', { patterns: [{ urlPattern: '*', requestStage: 'Request' }] });
  await send('Emulation.setDeviceMetricsOverride', { width: 375, height: 760, deviceScaleFactor: 1, mobile: true });
  let world;
  const evaluate = async (expression, isolated = false) => {
    const value = await send('Runtime.evaluate', {
      expression, returnByValue: true, awaitPromise: true,
      ...(isolated ? { contextId: world } : {}),
    });
    if (value.exceptionDetails) throw new Error(JSON.stringify(value.exceptionDetails));
    return value.result.value;
  };
  async function navigate(url = 'https://web.whatsapp.com/') {
    const navigation = await send('Page.navigate', { url });
    for (let count = 0; count < 100; count += 1) {
      if (await evaluate('document.readyState === "complete" && !!document.querySelector("#workspace")')) break;
      await delay(20);
    }
    world = (await send('Page.createIsolatedWorld', { frameId: navigation.frameId, worldName: 'ProfileDeskLayoutFixture' })).executionContextId;
    await evaluate(`(() => {
      globalThis.__fixtureForbiddenReads = 0;
      globalThis.__fixtureAnimationFrames = 0;
      const originalFrame = requestAnimationFrame.bind(globalThis);
      globalThis.requestAnimationFrame = (callback) => originalFrame((time) => { __fixtureAnimationFrames += 1; callback(time); });
      const blocked = () => { __fixtureForbiddenReads += 1; throw new Error('Forbidden service-content access'); };
      for (const [prototype, properties] of [
        [Element.prototype, ['innerHTML', 'outerHTML']],
        [Node.prototype, ['textContent']],
        [HTMLElement.prototype, ['innerText', 'title']],
        [HTMLInputElement.prototype, ['value']],
        [HTMLTextAreaElement.prototype, ['value']],
      ]) for (const property of properties) Object.defineProperty(prototype, property, { configurable: true, get: blocked, set: blocked });
      for (const property of ['localStorage', 'sessionStorage', 'indexedDB']) Object.defineProperty(globalThis, property, { configurable: true, get: blocked });
      for (const property of ['fetch', 'XMLHttpRequest', 'WebSocket']) Object.defineProperty(globalThis, property, { configurable: true, value: blocked });
    })()`, true);
    await evaluate(source, true);
  }
  const command = (expression) => evaluate(`__profileDeskLayout.${expression}`, true);
  const settled = () => delay(80);
  async function click(selector) {
    const point = await evaluate(`(() => { const r=document.querySelector(${JSON.stringify(selector)}).getBoundingClientRect(); return {x:r.left+Math.min(25,r.width/2),y:r.top+r.height/2}; })()`);
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', button: 'left', clickCount: 1, ...point });
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', button: 'left', clickCount: 1, ...point });
    await settled();
  }
  const detail = () => evaluate('document.documentElement.classList.contains("profile-desk-phone-detail")');
  const phone = () => evaluate('document.documentElement.classList.contains("profile-desk-phone-layout")');
  const capture = async (name) => {
    const result = await send('Page.captureScreenshot', { format: 'png' });
    await writeFile(resolve(output, `${name}.png`), Buffer.from(result.data, 'base64'));
  };

  await navigate();
  check('isolated-world controls are unavailable to website scripts', await evaluate('typeof globalThis.__profileDeskLayout === "undefined"'));
  check('adapter starts without modifying page presentation', !(await phone()));
  check('read-only presentation query starts in original mode', (await command('presentation()')).state === 'original');
  const initial = await command("setMode('phone')");
  if (!initial.available) console.log('Initial structural status', initial, await evaluate('({innerWidth,clientWidth:document.documentElement.clientWidth,height:innerHeight})'));
  check('phone mode starts with list and a valid structural layout', initial.state === 'list' && initial.available);
  check('read-only presentation contains only the bounded structural status', await evaluate(`(() => { const s=__profileDeskLayout.presentation(); return Object.isFrozen(s) && Object.keys(s).sort().join(',')==='available,mode,reason,state' && s.state==='list'; })()`, true));
  check('375px list preserves 16px text, menu rail, and viewport width', await evaluate(`(() => { const s=document.querySelector('#side').getBoundingClientRect(); const r=document.querySelector('nav').getBoundingClientRect(); return s.left===56 && s.right===375 && r.width===56 && getComputedStyle(document.querySelector('[role=row]')).fontSize==='16px'; })()`));
  check('conversation is not visible or interactive in initial list', await evaluate(`getComputedStyle(document.querySelector('#main')).visibility==='hidden' && getComputedStyle(document.querySelector('#main')).pointerEvents==='none'`));
  check('width-independent structural probe reports a recognized layout', await command('supportsStructure()'));
  await capture('phone-list-375');

  await click('#row-a span');
  check('trusted row selection opens full-width detail after service handler', await detail() && await evaluate('window.fixtureSelected===1'));
  check('presentation query observes current conversation without changing it', (await command('presentation()')).state === 'detail' && await detail());
  check('detail fills phone and keeps native font size', await evaluate(`(() => { const r=document.querySelector('#main').getBoundingClientRect(); return r.left===0 && r.right===375 && getComputedStyle(document.querySelector('#composer')).fontSize==='16px'; })()`));
  await click('#composer');
  await send('Input.insertText', { text: 'Owned test draft' });
  check('composer remains focusable and editable', await evaluate('document.activeElement.id === "composer" && document.querySelector("#composer").textContent === "Owned test draft"'));
  await capture('phone-conversation-375');
  check('native Back command restores list', (await command('showList()')).state === 'list' && !(await detail()));
  check('returning to the list preserves the page-owned unsent draft', await evaluate('document.querySelector("#composer").textContent === "Owned test draft"'));
  await click('#row-a span');
  check('reselecting the same existing conversation opens detail again', await detail() && await evaluate('window.fixtureSelected===2'));
  await command('showList()');
  await click('#search');
  check('search input keeps list mode', !(await detail()));
  await click('#row-action');
  check('row action keeps a usable menu in list mode', !(await detail()) && await evaluate(`getComputedStyle(document.querySelector('[role=menu]')).visibility==='visible'`));
  await click('#menu-item');
  check('menu item is not misclassified as chat selection', !(await detail()));
  check('known side replacement retains readable settings and menu rail', await phone() && (await command('showList()')).state === 'menu' && await evaluate(`(() => { const s=document.querySelector('#side').getBoundingClientRect(); const p=document.querySelector('#fixture-settings').getBoundingClientRect(); return s.left===56 && p.right<=375 && getComputedStyle(document.querySelector('#fixture-settings')).fontSize==='16px' && getComputedStyle(document.querySelector('nav')).visibility==='visible'; })()`));
  check('settings image is constrained to actual available side width', await evaluate(`(() => { const image=document.querySelector('#settings-image').getBoundingClientRect(); return image.right<=375 && image.width<=319 && image.height>0; })()`));
  check('repeated phone command preserves known menu state', (await command("setMode('phone')")).state === 'menu');
  check('presentation query distinguishes the retained official menu', (await command('presentation()')).state === 'menu');
  await capture('phone-settings-375');
  await click('#settings-back');
  check('real service Back click restores a recognized chat list', await phone() && (await command('showList()')).state === 'list' && await evaluate('document.querySelector("#pane-side") !== null'));
  await click('#dialog-button');
  check('generic portal dialog remains above the mobile panes', await evaluate(`document.elementFromPoint(60,130).closest('[role=dialog]')!==null`));
  await capture('phone-overlay-375');
  await click('#close-dialog');
  await evaluate('document.querySelector("#row-a span").click()');
  await settled();
  check('untrusted synthetic clicks never change the presentation pane', !(await detail()));

  await evaluate(`(() => {
    const row=document.createElement('div'); row.id='row-primary'; row.setAttribute('role','listitem');
    row.style.padding='0';
    const button=document.createElement('button'); button.id='primary-chat';
    button.style.cssText='width:100%;min-height:72px;font:inherit';
    const label=document.createElement('span'); label.textContent='Owned primary-button chat';
    button.appendChild(label); row.appendChild(button);
    button.onclick=()=>{ window.fixtureSelected+=1; };
    document.querySelector('#pane-side').appendChild(row);
  })()`);
  await settled();
  await click('#primary-chat span');
  check('a full-row primary button can open the selected conversation', await detail());
  await command('showList()');
  await evaluate("document.querySelector('#primary-chat').setAttribute('aria-haspopup','menu')");
  await click('#primary-chat span');
  check('a row-sized popup button remains a menu action', !(await detail()));
  await evaluate("document.querySelector('#row-primary').remove()");

  await evaluate(`(() => {
    const overlay=document.createElement('div'); overlay.id='nested-overlay';
    overlay.setAttribute('role','dialog'); overlay.setAttribute('aria-modal','true');
    overlay.style.cssText='position:fixed;left:700px;top:900px;width:340px;height:140px';
    const button=document.createElement('button'); button.id='nested-close'; button.textContent='Close fixture';
    button.onclick=()=>overlay.remove(); overlay.appendChild(button);
    document.querySelector('#main').appendChild(overlay);
  })()`);
  await settled();
  check('visible dialog nested in the inactive pane is reachable within the screen', await evaluate(`(() => {
    const e=document.querySelector('#nested-overlay'), r=e.getBoundingClientRect();
    return r.left>=0 && r.top>=0 && r.right<=375 && r.bottom<=760 &&
      document.elementFromPoint(r.left+30,r.top+30)?.closest('#nested-overlay')===e;
  })()`));
  await evaluate("document.querySelector('#nested-overlay').setAttribute('aria-hidden','true')");
  await settled();
  check('service-hidden nested dialog loses all visibility overrides', await evaluate("!document.querySelector('#nested-overlay').classList.contains('profile-desk-layout-overlay') && getComputedStyle(document.querySelector('#nested-overlay')).visibility==='hidden'"));
  await evaluate("document.querySelector('#nested-overlay').removeAttribute('aria-hidden')");
  await settled();
  await click('#nested-close');
  check('nested overlay close remains a real working click', await evaluate("!document.querySelector('#nested-overlay')"));
  await evaluate(`(() => { const duplicate=document.createElement('div'); duplicate.id='fixture-id-change'; document.body.appendChild(duplicate); })()`);
  await settled();
  await evaluate("document.querySelector('#fixture-id-change').id='main'");
  await settled();
  check('attribute-only structural ambiguity removes phone presentation', !(await phone()));
  await evaluate("document.body.lastElementChild.remove()");
  await settled();
  check('attribute-only structure recovery restores the list', await phone() && !(await detail()));
  const stableFrames = await evaluate('__fixtureAnimationFrames', true);
  await delay(300);
  check('observing attributes does not react to the adapters own presentation mutations', (await evaluate('__fixtureAnimationFrames', true))-stableFrames<4);

  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
  await click('#row-b span');
  check('reduced motion switches immediately without layout animations', await detail() && await evaluate(`getComputedStyle(document.querySelector('#main')).animationName==='none' && getComputedStyle(document.querySelector('#main')).transitionDuration==='0s'`));
  await send('Emulation.setDeviceMetricsOverride', { width: 600, height: 420, deviceScaleFactor: 1, mobile: true });
  await settled();
  check('resize preserves detail and fills keyboard-sized available height', await detail() && await evaluate(`document.querySelector('#main').getBoundingClientRect().height===420`));
  await send('Emulation.setDeviceMetricsOverride', { width: 760, height: 600, deviceScaleFactor: 1, mobile: true });
  await settled();
  check('tablet width falls back to untouched original layout', !(await phone()) && await evaluate('document.querySelectorAll("style[data-profile-desk-layout]").length===0'));
  check('structural probe remains true at tablet width without forcing phone mode', await command('supportsStructure()'));
  await send('Emulation.setDeviceMetricsOverride', { width: 430, height: 820, deviceScaleFactor: 1, mobile: true });
  await settled();
  check('returning to phone width safely starts from list', await phone() && !(await detail()));

  await evaluate('const duplicate=document.createElement("div"); duplicate.id="pane-side"; document.body.appendChild(duplicate)');
  const ambiguous = await command("setMode('phone')");
  check('duplicate structural hook removes adapter styling and reports fallback', ambiguous.state === 'unavailable' && !(await phone()));
  check('presentation query reports unavailable structure without revealing page data', (await command('presentation()')).state === 'unavailable');
  await evaluate('document.body.lastElementChild.remove()');
  await settled();
  check('valid structural layout can recover after ambiguity is removed', await phone());
  await command("setMode('original')");
  await evaluate('document.querySelector("#pane-side").id="unknown-list"');
  const unknown = await command("setMode('phone')");
  check('unknown layout is left untouched', unknown.reason === 'list-hook' && !(await phone()));
  await evaluate('document.querySelector("#unknown-list").id="pane-side"');
  await command("setMode('phone')");

  await evaluate('window.savedMain=document.querySelector("#main"); savedMain.remove()');
  await settled();
  check('list remains usable before any conversation container exists', (await command("setMode('phone')")).state === 'list');
  await click('#row-a span');
  check('row click cannot reveal a nonexistent conversation', !(await detail()));
  await evaluate('document.querySelector("#workspace").appendChild(window.savedMain)');
  await settled();
  check('asynchronously created conversation completes trusted selection', await detail());
  await command('showList()');
  await click('#row-a span');
  await evaluate('document.querySelector("#main").remove()');
  await settled();
  check('removing the active detail returns to list', await phone() && !(await detail()));
  await evaluate('document.querySelector("#workspace").appendChild(window.savedMain)');

  await command("setMode('original')");
  await evaluate('document.querySelector("meta[name=viewport]").setAttribute("content", "width=980, initial-scale=0.4")');
  await settled();
  check('structural probe recognizes a desktop980 viewport without changing it', await command('supportsStructure()') && await evaluate('document.querySelector("meta[name=viewport]").content === "width=980, initial-scale=0.4"'));
  await command("setMode('phone')");
  await settled();
  check('phone mode replaces desktop viewport metadata and uses device width', await phone() && await evaluate('document.documentElement.clientWidth === 430'));
  await command("setMode('original')");
  check('original mode exactly restores desktop viewport metadata', await evaluate('document.querySelector("meta[name=viewport]").content === "width=980, initial-scale=0.4"'));
  await evaluate('document.querySelector("meta[name=viewport]").remove()');
  await command("setMode('phone')");
  await settled();
  check('missing viewport metadata can be supplied for recognized phone layout', await phone() && await evaluate('document.querySelectorAll("meta[name=viewport]").length === 1'));
  await command("setMode('original')");
  check('original mode restores absence of viewport metadata', await evaluate('document.querySelectorAll("meta[name=viewport]").length === 0'));
  await send('Emulation.setDeviceMetricsOverride', { width: 760, height: 600, deviceScaleFactor: 1, mobile: true });
  await command("setMode('phone')");
  const beforeFrames = await evaluate('__fixtureAnimationFrames', true);
  await delay(300);
  check('wide viewport without metadata does not create an observer animation loop', (await evaluate('__fixtureAnimationFrames', true)) - beforeFrames < 4 && await evaluate('document.querySelectorAll("meta[name=viewport]").length === 0'));
  await send('Emulation.setDeviceMetricsOverride', { width: 430, height: 820, deviceScaleFactor: 1, mobile: true });
  await settled();
  await command("setMode('original')");
  await evaluate('const m=document.createElement("meta"); m.name="VIEWPORT"; document.head.appendChild(m)');
  await command("setMode('phone')");
  await command("setMode('original')");
  check('viewport metadata with absent content and existing name casing is restored', await evaluate('document.querySelector("meta[name=VIEWPORT]").getAttribute("content") === null'));
  await evaluate('document.querySelector("meta[name=VIEWPORT]").setAttribute("content", "width=device-width,initial-scale=1")');
  await command("setMode('phone')");
  await evaluate('window.savedSide=document.querySelector("#side"); const panel=document.createElement("section"); panel.id="unknown-menu-panel"; panel.setAttribute("role", "region"); savedSide.replaceWith(panel)');
  await settled();
  check('unknown menu replacement is left untouched with adapter styling removed', !(await phone()) && !(await command('supportsStructure()')) && await evaluate('document.querySelector("#unknown-menu-panel") !== null'));
  await evaluate('document.querySelector("#unknown-menu-panel").replaceWith(window.savedSide)');
  await settled();
  check('recognized list can recover after a menu replacement returns', await phone());

  for (let count = 0; count < 5; count += 1) {
    await evaluate(source, true);
    await command("setMode('phone')");
    check(`re-injection ${count + 1} owns exactly one style`, await evaluate('document.querySelectorAll("style[data-profile-desk-layout]").length===1'));
    await command("setMode('original')");
    check(`original mode ${count + 1} removes all adapter classes and style`, await evaluate(`!document.querySelector('[class*="profile-desk-"]') && document.querySelectorAll('style[data-profile-desk-layout]').length===0`));
  }
  await command("setMode('phone')");
  await command('dispose()');
  await click('#row-a span');
  await settled();
  check('dispose removes API, styles, classes and selection listeners', await evaluate('typeof __profileDeskLayout === "undefined"', true) && !(await phone()));
  check('all layout flows work with content, input, storage and network access blocked', await evaluate('__fixtureForbiddenReads === 0', true));

  await navigate('https://example.invalid/');
  check('foreign origin cannot install adapter controls', await evaluate('typeof __profileDeskLayout === "undefined"', true));
  await navigate('http://web.whatsapp.com/');
  check('HTTP origin cannot install adapter controls', await evaluate('typeof __profileDeskLayout === "undefined"', true));
  await navigate('https://web.whatsapp.com:444/');
  check('nondefault port cannot install adapter controls', await evaluate('typeof __profileDeskLayout === "undefined"', true));
  await navigate('https://web.whatsapp.com:443/');
  check('explicit default HTTPS port is accepted', (await command("setMode('phone')")).available);
  await evaluate('const frame=document.createElement("iframe"); frame.srcdoc="<!doctype html><html><body></body></html>"; document.body.appendChild(frame)');
  await settled();
  const tree = await send('Page.getFrameTree');
  const childId = tree.frameTree.childFrames[0].frame.id;
  const subworld = await send('Page.createIsolatedWorld', { frameId: childId, worldName: 'ProfileDeskChildFixture' });
  const childResult = await send('Runtime.evaluate', { contextId: subworld.executionContextId, expression: `${source}\ntypeof __profileDeskLayout`, returnByValue: true });
  check('subframes cannot install adapter controls', childResult.result.value === 'undefined');
  check('every browser request was intercepted locally', requests.length > 0 && requests.every((request) => request.local));

  await writeFile(resolve(output, 'result.json'), JSON.stringify({
    result: 'PASS', count: checks.length, checks,
    scope: 'Owned synthetic HTML in isolated Chrome world. All URL requests are locally fulfilled with DNS blocked. No real service, account, QR, message or network response was used.',
    limits: 'WhatsApp structural selectors and actual authenticated mobile behavior remain unverified. Android JavaScript-world isolation and iOS WKWebView behavior require platform checks.',
    browser: await send('Browser.getVersion'), requests,
  }, null, 2) + '\n');
  console.log(`PASS: ${checks.length} owned layout checks. Evidence: ${output}`);
} catch (error) {
  await mkdir(output, { recursive: true });
  await writeFile(resolve(output, 'result.json'), JSON.stringify({ result: 'FAIL', checks, error: String(error), requests }, null, 2) + '\n');
  throw error;
} finally {
  socket?.close();
  chrome?.kill('SIGTERM');
  await delay(250);
  await rm(profile, { recursive: true, force: true, maxRetries: 4, retryDelay: 100 });
}
