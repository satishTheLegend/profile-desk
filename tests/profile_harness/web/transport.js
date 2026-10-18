"use strict";

// Developer-owned fixture only. No dependency on, injection into, or inspection
// of the service workspace. Callers must use the identical origin in all stores.
(() => {
  const markerPattern = /^synthetic-[a-zA-Z0-9_-]{1,48}$/;
  function checkMarker(marker, allowEmpty = false) {
    if (!(allowEmpty && marker === null) && !markerPattern.test(marker)) {
      throw new Error("A synthetic marker is required.");
    }
  }
  async function boundedFetch(path, options = {}) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 5000);
    try {
      const response = await fetch(path, { ...options, credentials: "same-origin", signal: controller.signal });
      // Read the body before releasing the deadline, not merely response headers.
      const bytes = await response.arrayBuffer();
      if (!response.ok) throw new Error(`Transport fixture failed (${response.status}).`);
      return { response, bytes, text: new TextDecoder().decode(bytes) };
    } finally {
      clearTimeout(timer);
    }
  }
  async function hash(bytes) {
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
  }
  async function cacheProbe(expectedMarker, { cache = "default" } = {}) {
    checkMarker(expectedMarker, true);
    if (!["default", "reload", "force-cache"].includes(cache)) throw new Error("Unsupported cache probe mode.");
    const requestNonce = "probe-" + crypto.randomUUID();
    const reply = await boundedFetch("/transport/cache", { cache, headers: { "X-Probe-Nonce": requestNonce } });
    const body = JSON.parse(reply.text);
    return {
      result: body.marker === expectedMarker ? "MATCH" : "MISMATCH", marker: body.marker,
      requestNonce, responseNonce: body.requestNonce, cacheHit: body.requestNonce !== requestNonce,
    };
  }
  async function websocketProbe(expectedMarker) {
    checkMarker(expectedMarker, true);
    const token = "synthetic-" + crypto.randomUUID();
    const url = new URL("/transport/socket", location.href);
    url.protocol = "wss:";
    return new Promise((resolve, reject) => {
      const socket = new WebSocket(url, "profiledesk.synthetic.v1");
      let identity;
      let finished = false;
      const timer = setTimeout(() => finish(new Error("WebSocket fixture timed out.")), 5000);
      function finish(error, value) {
        if (finished) return;
        finished = true;
        clearTimeout(timer);
        socket.close();
        if (error) reject(error); else resolve(value);
      }
      socket.onopen = () => socket.send(token);
      socket.onerror = () => finish(new Error("WebSocket fixture failed."));
      socket.onclose = () => { if (!finished) finish(new Error("WebSocket closed before proof.")); };
      socket.onmessage = ({ data }) => {
        try {
          const message = JSON.parse(data);
          if (message.type === "identity") identity = message.marker;
          if (message.type === "echo") finish(null, {
            result: identity === expectedMarker && message.marker === expectedMarker && message.token === token ? "MATCH" : "MISMATCH",
            identity, echoedMarker: message.marker, echoedToken: message.token, token,
          });
        } catch (_error) {
          finish(new Error("Malformed WebSocket fixture reply."));
        }
      };
    });
  }
  async function uploadFile(file) {
    if (!(file instanceof Blob) || file.size < 1 || file.size > 65536) throw new Error("Use a bounded synthetic fixture file.");
    const reply = await boundedFetch("/transport/upload", {
      method: "POST", headers: { "Content-Type": "application/octet-stream" }, body: file,
    });
    return JSON.parse(reply.text);
  }
  async function fileProbe(expectedMarker) {
    checkMarker(expectedMarker);
    const downloaded = await boundedFetch("/transport/download", { cache: "no-store" });
    const digest = await hash(downloaded.bytes);
    const upload = await uploadFile(new Blob([downloaded.bytes], { type: "application/octet-stream" }));
    return {
      result: downloaded.response.headers.get("X-Profile-Marker") === expectedMarker
        && downloaded.response.headers.get("X-Content-SHA256") === digest
        && upload.marker === expectedMarker && upload.sha256 === digest && upload.bytes === downloaded.bytes.byteLength ? "MATCH" : "MISMATCH",
      marker: upload.marker, bytes: upload.bytes, sha256: digest,
    };
  }
  function installFileControls() {
    if (document.querySelector("#transport-files")) return;
    const section = document.createElement("section");
    section.id = "transport-files";
    const label = document.createElement("label");
    label.textContent = "Upload a downloaded synthetic fixture file ";
    const input = document.createElement("input");
    input.id = "transport-upload";
    input.type = "file";
    input.accept = ".txt,application/octet-stream,text/plain";
    input.onchange = async () => {
      api.lastFileResult = null;
      try { api.lastFileResult = input.files[0] ? await uploadFile(input.files[0]) : { cancelled: true }; }
      catch (_error) { api.lastFileResult = { error: "synthetic_upload_failed" }; }
    };
    label.append(input);
    const link = document.createElement("a");
    link.id = "transport-download";
    link.href = "/transport/download";
    link.textContent = "Download synthetic fixture document";
    section.append(label, document.createElement("br"), link);
    document.querySelector("main").append(section);
  }
  const api = { cacheProbe, websocketProbe, fileProbe, uploadFile, installFileControls, lastFileResult: null };
  window.ProfileDeskTransport = api;
})();
