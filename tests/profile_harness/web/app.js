"use strict";

const databaseName = "synthetic-profile-harness-v1";
const cacheName = "synthetic-profile-harness-v1";
const workerCacheName = "synthetic-profile-worker-v1";
const markerKey = "profile-marker";
const markerInput = document.querySelector("#marker");
const statusNode = document.querySelector("#status");
const reportNode = document.querySelector("#report");

function requestResult(request) {
  return new Promise((resolve, reject) => {
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
    request.onblocked = () => reject(new Error("Database blocked by another live client."));
  });
}

async function database() {
  const request = indexedDB.open(databaseName, 1);
  request.onupgradeneeded = () => request.result.createObjectStore("markers");
  return requestResult(request);
}

async function idbMarker(value, write = false) {
  const db = await database();
  try {
    return await new Promise((resolve, reject) => {
      const transaction = db.transaction("markers", write ? "readwrite" : "readonly");
      const store = transaction.objectStore("markers");
      const request = write ? store.put(value, markerKey) : store.get(markerKey);
      transaction.oncomplete = () => resolve(request.result ?? null);
      transaction.onerror = () => reject(transaction.error);
      transaction.onabort = () => reject(transaction.error || new Error("Transaction aborted"));
    });
  } finally {
    db.close();
  }
}

async function cookieMarker(value, write = false) {
  const response = await fetch("/api/cookie", write ? {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ marker: value }),
  } : {});
  if (!response.ok) throw new Error(`Cookie endpoint failed (${response.status}).`);
  return (await response.json()).marker;
}

async function workerMessage(action, marker) {
  await bounded(navigator.serviceWorker.register("/worker.js", { scope: "/" }));
  const registration = await bounded(navigator.serviceWorker.ready);
  const worker = registration.active;
  if (!worker) throw new Error("No active service worker.");
  return new Promise((resolve, reject) => {
    const channel = new MessageChannel();
    const timer = setTimeout(() => {
      channel.port1.close();
      reject(new Error("Service worker response timed out."));
    }, 5000);
    channel.port1.onmessage = ({ data }) => {
      clearTimeout(timer);
      channel.port1.close();
      data.error ? reject(new Error(data.error)) : resolve(data.marker);
    };
    worker.postMessage({ action, marker }, [channel.port2]);
  });
}

async function bounded(promise) {
  let timer;
  try {
    return await Promise.race([promise, new Promise((_, reject) => {
      timer = setTimeout(() => reject(new Error("Service worker activation timed out.")), 5000);
    })]);
  } finally {
    clearTimeout(timer);
  }
}

async function readStores() {
  const cache = await caches.open(cacheName);
  const response = await cache.match("/synthetic-marker");
  const readableCookie = document.cookie.split("; ").find((part) => part.startsWith("harness_readable="));
  return {
    readableCookie: readableCookie ? readableCookie.split("=")[1] : null,
    httpOnlyCookie: await cookieMarker(),
    localStorage: localStorage.getItem(markerKey),
    indexedDB: await idbMarker(),
    cacheStorage: response ? await response.text() : null,
    serviceWorker: await workerMessage("read"),
  };
}

function expectedMarker() {
  const value = markerInput.value;
  if (!/^synthetic-[a-zA-Z0-9_-]{1,48}$/.test(value)) throw new Error("Use a synthetic- marker followed by 1–48 letters, digits, underscores or hyphens.");
  return value;
}

async function verify() {
  const expected = expectedMarker();
  const stores = await readStores();
  const allEmpty = Object.values(stores).every((value) => value === null);
  const allMatch = Object.values(stores).every((value) => value === expected);
  const report = { recordedAt: new Date().toISOString(), origin: location.origin, expected, result: allMatch ? "MATCH" : allEmpty ? "EMPTY" : "MISMATCH", stores };
  reportNode.textContent = JSON.stringify(report, null, 2);
  statusNode.textContent = allMatch ? "All stores match the expected synthetic profile." : allEmpty ? "Every tested store is empty. This is expected before first seed or after native removal." : "Storage mismatch. Record this failure; do not overwrite the evidence.";
  return report;
}

async function seed() {
  const marker = expectedMarker();
  document.cookie = `harness_readable=${marker}; Path=/; Max-Age=31536000; Secure; SameSite=Strict`;
  await cookieMarker(marker, true);
  localStorage.setItem(markerKey, marker);
  await idbMarker(marker, true);
  await (await caches.open(cacheName)).put("/synthetic-marker", new Response(marker));
  await workerMessage("write", marker);
  await verify();
}

async function clear() {
  document.cookie = "harness_readable=; Path=/; Max-Age=0; Secure; SameSite=Strict";
  await cookieMarker(null, true);
  localStorage.removeItem(markerKey);
  await requestResult(indexedDB.deleteDatabase(databaseName));
  await caches.delete(cacheName);
  await caches.delete(workerCacheName);
  for (const registration of await navigator.serviceWorker.getRegistrations()) await registration.unregister();
  await verify();
}

async function run(action) {
  for (const button of document.querySelectorAll("button")) button.disabled = true;
  try {
    if (!isSecureContext) throw new Error("A trusted HTTPS origin is required.");
    statusNode.textContent = "Checking synthetic storage…";
    await action();
  } catch (error) {
    statusNode.textContent = "Fixture failed. Record the error and capability information.";
    reportNode.textContent = JSON.stringify({ result: "ERROR", error: String(error) }, null, 2);
  } finally {
    for (const button of document.querySelectorAll("button")) button.disabled = false;
  }
}

document.querySelector("#seed").addEventListener("click", () => run(seed));
document.querySelector("#verify").addEventListener("click", () => run(verify));
document.querySelector("#clear").addEventListener("click", () => run(clear));
document.querySelector("#burst").addEventListener("click", () => run(async () => {
  statusNode.textContent = "Worker writes are active for four seconds. The native deletion test may now remove this fixture profile.";
  await workerMessage("burst", expectedMarker());
  await verify();
}));
document.querySelector("#reload").addEventListener("click", () => location.reload());
