#!/usr/bin/env python3
"""HTTPS-only synthetic storage fixture. Never pass real account data here."""

import argparse
import base64
import hashlib
import json
import re
import ssl
import struct
import time
from http import cookies
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

WEB_ROOT = Path(__file__).resolve().parent / "web"
MARKER = re.compile(r"synthetic-[a-zA-Z0-9_-]{1,48}\Z")
PROBE_NONCE = re.compile(r"[a-zA-Z0-9_-]{1,64}\Z")
SYNTHETIC_FILE = re.compile(rb"PROFILE_DESK_SYNTHETIC_FILE_V1\n(synthetic-[a-zA-Z0-9_-]{1,48})\n(?:SYNTHETIC\n)*\Z")
MAX_FILE_BYTES = 65536
WS_PROTOCOL = "profiledesk.synthetic.v1"
ASSETS = {
    "/": ("index.html", "text/html; charset=utf-8"),
    "/app.js": ("app.js", "text/javascript; charset=utf-8"),
    "/style.css": ("style.css", "text/css; charset=utf-8"),
    "/worker.js": ("worker.js", "text/javascript; charset=utf-8"),
    "/shared-worker.js": ("shared-worker.js", "text/javascript; charset=utf-8"),
    "/transport.js": ("transport.js", "text/javascript; charset=utf-8"),
}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        # Requests, query strings and cookie values are deliberately not logged.
        pass

    def respond(self, status, body, content_type="application/json", headers=(), *, cache_control="no-store", csp=None):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", cache_control)
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Robots-Tag", "noindex, nofollow")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Content-Security-Policy", csp or "default-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
        for key, value in headers:
            self.send_header(key, value)
        self.end_headers()
        self.wfile.write(body)

    def json(self, status, value, headers=()):
        self.respond(status, json.dumps(value).encode(), headers=headers)

    def fixture_marker(self):
        jar = cookies.SimpleCookie()
        try:
            jar.load(self.headers.get("Cookie", ""))
        except cookies.CookieError:
            return None
        item = jar.get("harness_http_only")
        return item.value if item and MARKER.fullmatch(item.value) else None

    def same_origin_transport(self, *, required=False):
        origin = self.headers.get("Origin")
        if origin is None and not required:
            return self.headers.get("Sec-Fetch-Site", "same-origin") in {"same-origin", "none"}
        return origin == "https://" + self.headers.get("Host", "")

    def transport_get(self, path):
        if urlsplit(self.path).query:
            return self.json(400, {"error": "fixed_url_required"})
        if not self.same_origin_transport():
            return self.json(403, {"error": "same_origin_required"})
        if path == "/transport/page":
            host = self.headers.get("Host", "")
            if not re.fullmatch(r"[a-zA-Z0-9.-]+(?::[0-9]{1,5})?", host):
                return self.json(400, {"error": "invalid_host"})
            body = (WEB_ROOT / "index.html").read_bytes().replace(
                b"</head>", b'<script src="/transport.js" defer></script></head>')
            return self.respond(200, body, "text/html; charset=utf-8", csp=(
                "default-src 'self'; connect-src 'self' wss://" + host
                + "; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"))
        if path == "/transport/cache":
            nonce = self.headers.get("X-Probe-Nonce", "")
            if not PROBE_NONCE.fullmatch(nonce):
                return self.json(400, {"error": "probe_nonce_required"})
            body = json.dumps({"marker": self.fixture_marker(), "requestNonce": nonce}).encode()
            # Deliberately no Vary: Cookie or nonce: identical URLs must exercise
            # the browser profile's private HTTP cache, not header partitioning.
            return self.respond(200, body, cache_control="private, max-age=600")
        if path == "/transport/download":
            marker = self.fixture_marker()
            if marker is None:
                return self.json(409, {"error": "seed_fixture_cookie_first"})
            data = b"PROFILE_DESK_SYNTHETIC_FILE_V1\n" + marker.encode() + b"\n" + b"SYNTHETIC\n" * 1024
            return self.respond(200, data, "application/octet-stream", (
                ("Content-Disposition", 'attachment; filename="synthetic-profile-document.txt"'),
                ("X-Profile-Marker", marker), ("X-Content-SHA256", hashlib.sha256(data).hexdigest()),
            ))
        if path == "/transport/socket":
            return self.transport_socket()
        return self.json(404, {"error": "not_found"})

    def transport_upload(self):
        if urlsplit(self.path).query:
            return self.json(400, {"error": "fixed_url_required"})
        if not self.same_origin_transport(required=True):
            return self.json(403, {"error": "same_origin_required"})
        if self.headers.get("Content-Type", "").split(";")[0] != "application/octet-stream":
            return self.json(415, {"error": "binary_required"})
        if self.headers.get("Transfer-Encoding"):
            return self.json(400, {"error": "content_length_required"})
        try:
            size = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self.json(400, {"error": "invalid_length"})
        if not 0 < size <= MAX_FILE_BYTES:
            return self.json(413, {"error": "invalid_size"})
        self.connection.settimeout(5)
        try:
            body = self.rfile.read(size)
        except (OSError, TimeoutError):
            self.close_connection = True
            return
        match = SYNTHETIC_FILE.fullmatch(body)
        if len(body) != size or not match:
            return self.json(400, {"error": "synthetic_file_required"})
        marker = match.group(1).decode()
        if marker != self.fixture_marker():
            return self.json(409, {"error": "profile_marker_mismatch"})
        # No filesystem writes, filenames, global marker table or retained body.
        return self.json(200, {"marker": marker, "bytes": len(body), "sha256": hashlib.sha256(body).hexdigest()})

    def transport_socket(self):
        if not self.same_origin_transport(required=True):
            return self.json(403, {"error": "same_origin_required"})
        try:
            key = self.headers.get("Sec-WebSocket-Key", "")
            valid_key = len(base64.b64decode(key, validate=True)) == 16
        except ValueError:
            valid_key = False
        connection_tokens = {part.strip().lower() for part in self.headers.get("Connection", "").split(",")}
        protocols = {part.strip() for part in self.headers.get("Sec-WebSocket-Protocol", "").split(",")}
        if (self.headers.get("Upgrade", "").lower() != "websocket" or "upgrade" not in connection_tokens
                or self.headers.get("Sec-WebSocket-Version") != "13" or not valid_key or WS_PROTOCOL not in protocols):
            return self.json(400, {"error": "websocket_handshake_required"})
        self.protocol_version = "HTTP/1.1"
        self.send_response(101)
        self.send_header("Upgrade", "websocket")
        self.send_header("Connection", "Upgrade")
        self.send_header("Sec-WebSocket-Protocol", WS_PROTOCOL)
        self.send_header("Sec-WebSocket-Accept", base64.b64encode(hashlib.sha1(
            (key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest()).decode())
        self.end_headers()
        self.close_connection = True
        self.connection.settimeout(5)
        marker = self.fixture_marker()

        def send(opcode, payload):
            prefix = bytes([0x80 | opcode])
            prefix += bytes([len(payload)]) if len(payload) < 126 else b"\x7e" + struct.pack("!H", len(payload))
            self.wfile.write(prefix + payload)
            self.wfile.flush()

        def exact(length):
            value = self.rfile.read(length)
            if len(value) != length:
                raise EOFError()
            return value

        try:
            send(1, json.dumps({"type": "identity", "marker": marker}).encode())
            deadline = time.monotonic() + 15
            for _ in range(16):
                self.connection.settimeout(max(0.1, min(5, deadline - time.monotonic())))
                if time.monotonic() >= deadline:
                    break
                first, second = exact(2)
                opcode, length = first & 15, second & 127
                # This bounded fixture supports unfragmented text/control frames.
                if first & 0x70 or not first & 0x80 or not second & 0x80 or opcode not in {1, 8, 9, 10}:
                    send(8, struct.pack("!H", 1002))
                    return
                if length == 126:
                    length = struct.unpack("!H", exact(2))[0]
                elif length == 127:
                    send(8, struct.pack("!H", 1009))
                    return
                if length > 1024 or (opcode >= 8 and length > 125):
                    send(8, struct.pack("!H", 1009))
                    return
                mask = exact(4)
                payload = bytes(byte ^ mask[index % 4] for index, byte in enumerate(exact(length)))
                if opcode == 8:
                    send(8, struct.pack("!H", 1000))
                    return
                if opcode == 9:
                    send(10, payload)
                    continue
                if opcode == 10:
                    continue
                try:
                    token = payload.decode("utf-8")
                except UnicodeDecodeError:
                    send(8, struct.pack("!H", 1007))
                    return
                if not MARKER.fullmatch(token):
                    send(8, struct.pack("!H", 1008))
                    return
                send(1, json.dumps({"type": "echo", "marker": marker, "token": token}).encode())
            send(8, struct.pack("!H", 1000))
        except (OSError, EOFError, TimeoutError):
            pass

    def do_GET(self):
        path = urlsplit(self.path).path
        if path.startswith("/transport/"):
            return self.transport_get(path)
        if path == "/api/cookie":
            jar = cookies.SimpleCookie()
            try:
                jar.load(self.headers.get("Cookie", ""))
            except cookies.CookieError:
                return self.json(400, {"error": "invalid_cookie"})
            marker = jar.get("harness_http_only")
            value = marker.value if marker and MARKER.fullmatch(marker.value) else None
            return self.json(200, {"marker": value})
        if path == "/robots.txt":
            return self.respond(200, b"User-agent: *\nDisallow: /\n", "text/plain")
        asset = ASSETS.get(path)
        if asset is None:
            return self.json(404, {"error": "not_found"})
        filename, content_type = asset
        headers = (("Service-Worker-Allowed", "/"),) if path == "/worker.js" else ()
        self.respond(200, (WEB_ROOT / filename).read_bytes(), content_type, headers)

    def do_POST(self):
        if urlsplit(self.path).path == "/transport/upload":
            return self.transport_upload()
        if urlsplit(self.path).path != "/api/cookie":
            return self.json(404, {"error": "not_found"})
        # Prevent a different website seeding a cookie into a test profile.
        expected_origin = "https://" + self.headers.get("Host", "")
        if self.headers.get("Origin") != expected_origin:
            return self.json(403, {"error": "same_origin_required"})
        if self.headers.get("Content-Type", "").split(";")[0] != "application/json":
            return self.json(415, {"error": "json_required"})
        try:
            size = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self.json(400, {"error": "invalid_length"})
        if size < 1 or size > 256:
            return self.json(413, {"error": "invalid_size"})
        try:
            payload = json.loads(self.rfile.read(size))
        except (ValueError, UnicodeDecodeError):
            return self.json(400, {"error": "invalid_json"})
        if not isinstance(payload, dict) or set(payload) != {"marker"}:
            return self.json(400, {"error": "marker_required"})
        marker = payload["marker"]
        if marker is not None and (not isinstance(marker, str) or not MARKER.fullmatch(marker)):
            return self.json(400, {"error": "synthetic_marker_required"})
        value = marker or ""
        max_age = "31536000" if marker else "0"
        cookie = f"harness_http_only={value}; Path=/; Max-Age={max_age}; HttpOnly; Secure; SameSite=Strict"
        self.json(200, {"marker": marker}, (("Set-Cookie", cookie),))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cert", type=Path, required=True)
    parser.add_argument("--key", type=Path, required=True)
    parser.add_argument("--host", default="127.0.0.1", help="Use an explicit LAN address only for authorized device testing.")
    parser.add_argument("--port", type=int, default=8443)
    args = parser.parse_args()
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.load_cert_chain(args.cert, args.key)
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    print(f"Synthetic storage harness: https://{args.host}:{server.server_port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
