"use strict";

// Test-only transient connectivity probe. The same-profile positive control
// establishes that distinct stores, rather than worker absence, isolate ports.
let connections = 0;
self.onconnect = (event) => {
  const port = event.ports[0];
  const portId = ++connections;
  port.onmessage = (message) => {
    const data = message.data;
    if (data?.type !== "probe" || typeof data.token !== "string" ||
        data.token.length > 128) return;
    port.postMessage({ token: data.token, portId, connections });
  };
  port.start();
};
