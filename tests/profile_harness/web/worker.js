"use strict";
const cacheName = "synthetic-profile-worker-v1";
self.addEventListener("install", (event) => event.waitUntil(self.skipWaiting()));
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));
self.addEventListener("message", (event) => {
  const port = event.ports[0];
  if (!port || !["read", "write", "burst"].includes(event.data?.action)) return;
  event.waitUntil((async () => {
    try {
      const cache = await caches.open(cacheName);
      if (["write", "burst"].includes(event.data.action)) {
        if (!/^synthetic-[a-zA-Z0-9_-]{1,48}$/.test(event.data.marker)) throw new Error("Invalid synthetic marker");
        await cache.put("/synthetic-worker-marker", new Response(event.data.marker));
      }
      if (event.data.action === "burst") {
        for (let index = 0; index < 20; index += 1) {
          await new Promise((resolve) => setTimeout(resolve, 200));
          await cache.put("/synthetic-worker-marker", new Response(event.data.marker));
        }
      }
      const response = await cache.match("/synthetic-worker-marker");
      port.postMessage({ marker: response ? await response.text() : null });
    } catch (error) {
      port.postMessage({ error: String(error) });
    } finally {
      port.close();
    }
  })());
});
