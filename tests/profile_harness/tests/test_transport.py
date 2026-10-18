"""Transport protocol policy tests, not native browser isolation evidence."""

import base64
import hashlib
import http.client
import importlib.util
import json
from pathlib import Path
import socket
import struct
import threading
import unittest
from http.server import ThreadingHTTPServer

spec = importlib.util.spec_from_file_location("transport_server", Path(__file__).parents[1] / "server.py")
server_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server_module)


class TransportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), server_module.Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.host = f"127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def request(self, path, method="GET", body=None, headers=None):
        connection = http.client.HTTPConnection(self.host, timeout=3)
        defaults = {"Origin": f"https://{self.host}", "Content-Type": "application/octet-stream"}
        defaults.update(headers or {})
        connection.request(method, path, body=body, headers=defaults)
        response = connection.getresponse()
        result = response.status, dict(response.getheaders()), response.read()
        connection.close()
        return result

    def test_cache_uses_same_fixed_private_url_without_header_partitioning(self):
        for marker, nonce in [("synthetic-a", "probe-first"), ("synthetic-b", "probe-second")]:
            status, headers, body = self.request("/transport/cache", headers={
                "Cookie": f"harness_http_only={marker}", "X-Probe-Nonce": nonce,
            })
            self.assertEqual(status, 200)
            self.assertEqual(json.loads(body), {"marker": marker, "requestNonce": nonce})
            self.assertEqual(headers["Cache-Control"], "private, max-age=600")
            self.assertNotIn("Vary", headers)
            self.assertNotIn("Set-Cookie", headers)

    def test_cache_has_no_server_retained_marker(self):
        self.request("/transport/cache", headers={"Cookie": "harness_http_only=synthetic-a", "X-Probe-Nonce": "probe-a"})
        status, _, body = self.request("/transport/cache", headers={"X-Probe-Nonce": "probe-empty"})
        self.assertEqual(status, 200)
        self.assertIsNone(json.loads(body)["marker"])

    def test_cache_rejects_query_foreign_origin_and_unbounded_nonce(self):
        self.assertEqual(self.request("/transport/cache?profile=a", headers={"X-Probe-Nonce": "p"})[0], 400)
        self.assertEqual(self.request("/transport/cache", headers={"Origin": "https://foreign.invalid", "X-Probe-Nonce": "p"})[0], 403)
        for nonce in ["", "p" * 65, "not synthetic"]:
            self.assertEqual(self.request("/transport/cache", headers={"X-Probe-Nonce": nonce})[0], 400)

    def test_download_upload_roundtrip_is_bounded_and_profile_owned(self):
        owner = {"Cookie": "harness_http_only=synthetic-file-owner"}
        status, headers, body = self.request("/transport/download", headers=owner)
        self.assertEqual(status, 200)
        self.assertEqual(headers["Cache-Control"], "no-store")
        self.assertLessEqual(len(body), server_module.MAX_FILE_BYTES)
        self.assertEqual(headers["Content-Disposition"], 'attachment; filename="synthetic-profile-document.txt"')
        self.assertEqual(headers["X-Content-SHA256"], hashlib.sha256(body).hexdigest())
        status, _, uploaded = self.request("/transport/upload", "POST", body, owner)
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(uploaded), {"marker": "synthetic-file-owner", "bytes": len(body), "sha256": hashlib.sha256(body).hexdigest()})
        self.assertEqual(self.request("/transport/upload", "POST", body, {"Cookie": "harness_http_only=synthetic-other"})[0], 409)

    def test_file_routes_reject_real_unbounded_and_foreign_inputs(self):
        self.assertEqual(self.request("/transport/download")[0], 409)
        self.assertEqual(self.request("/transport/upload", "POST", b"actual unrelated content")[0], 400)
        self.assertEqual(self.request("/transport/upload", "POST", b"x" * 65537)[0], 413)
        self.assertEqual(self.request("/transport/upload", "POST", b"x", {"Origin": "https://foreign.invalid"})[0], 403)
        self.assertEqual(self.request("/transport/upload", "POST", b"x", {"Content-Type": "multipart/form-data"})[0], 415)
        self.assertEqual(self.request("/transport/upload", "POST", b"x", {"Transfer-Encoding": "chunked"})[0], 400)
        self.assertEqual(self.request("/transport/download?filename=secret")[0], 400)

    def test_helper_is_served_no_store_with_indexing_protection(self):
        status, headers, body = self.request("/transport.js")
        self.assertEqual(status, 200)
        self.assertEqual(headers["Cache-Control"], "no-store")
        self.assertEqual(headers["X-Robots-Tag"], "noindex, nofollow")
        self.assertIn(b"window.ProfileDeskTransport", body)

    def test_separate_transport_page_explicitly_allows_only_same_host_wss(self):
        status, headers, body = self.request("/transport/page")
        self.assertEqual(status, 200)
        self.assertIn(b'<script src="/transport.js" defer>', body)
        self.assertIn("connect-src 'self' wss://" + self.host + ";", headers["Content-Security-Policy"])
        self.assertNotIn("wss://", self.request("/")[1]["Content-Security-Policy"])
        self.assertEqual(self.request("/transport/page", headers={"Host": "bad-host; unsafe"})[0], 403)

    def websocket(self, cookie="harness_http_only=synthetic-a", changes=None):
        client = socket.create_connection(("127.0.0.1", self.server.server_port), timeout=3)
        headers = {"Host": self.host, "Origin": f"https://{self.host}", "Upgrade": "websocket",
                   "Connection": "Upgrade", "Sec-WebSocket-Version": "13",
                   "Sec-WebSocket-Key": base64.b64encode(b"0123456789abcdef").decode(),
                   "Sec-WebSocket-Protocol": server_module.WS_PROTOCOL, "Cookie": cookie}
        headers.update(changes or {})
        request = "GET /transport/socket HTTP/1.1\r\n" + "".join(f"{key}: {value}\r\n" for key, value in headers.items()) + "\r\n"
        client.sendall(request.encode())
        response = b""
        while not response.endswith(b"\r\n\r\n"):
            byte = client.recv(1)
            if not byte or len(response) > 8192:
                raise AssertionError("Unbounded/closed handshake")
            response += byte
        return client, response

    def read_frame(self, client):
        def exact(size):
            body = b""
            while len(body) < size:
                chunk = client.recv(size - len(body))
                if not chunk:
                    raise AssertionError("Unexpected WebSocket close")
                body += chunk
            return body
        first, second = exact(2)
        self.assertFalse(second & 128, "Server frames cannot be masked")
        length = second & 127
        if length == 126:
            length = struct.unpack("!H", exact(2))[0]
        self.assertLessEqual(length, 1024)
        return first & 15, exact(length)

    def send_frame(self, client, payload, opcode=1):
        mask = b"abcd"
        prefix = bytes([0x80 | opcode])
        prefix += bytes([0x80 | len(payload)]) if len(payload) < 126 else b"\xfe" + struct.pack("!H", len(payload))
        client.sendall(prefix + mask + bytes(byte ^ mask[index % 4] for index, byte in enumerate(payload)))

    def test_websocket_identity_and_echo_are_connection_scoped(self):
        first, headers = self.websocket()
        second, _ = self.websocket("harness_http_only=synthetic-b")
        try:
            self.assertIn(b"HTTP/1.1 101", headers)
            accept = base64.b64encode(hashlib.sha1(b"MDEyMzQ1Njc4OWFiY2RlZg==258EAFA5-E914-47DA-95CA-C5AB0DC85B11").digest())
            self.assertIn(b"Sec-WebSocket-Accept: " + accept, headers)
            for client, marker in [(first, "synthetic-a"), (second, "synthetic-b")]:
                opcode, body = self.read_frame(client)
                self.assertEqual(opcode, 1)
                self.assertEqual(json.loads(body), {"type": "identity", "marker": marker})
                self.send_frame(client, b"synthetic-echo")
                self.assertEqual(json.loads(self.read_frame(client)[1]), {"type": "echo", "marker": marker, "token": "synthetic-echo"})
                self.send_frame(client, b"ping", 9)
                self.assertEqual(self.read_frame(client), (10, b"ping"))
                self.send_frame(client, b"", 8)
                self.assertEqual(self.read_frame(client)[0], 8)
        finally:
            first.close()
            second.close()

    def test_websocket_rejects_foreign_origin_and_invalid_handshake(self):
        for changes, status in [({"Origin": "https://foreign.invalid"}, b"403"),
                                ({"Sec-WebSocket-Key": "bad"}, b"400"),
                                ({"Sec-WebSocket-Protocol": "arbitrary"}, b"400")]:
            client, headers = self.websocket(changes=changes)
            try:
                self.assertIn(status, headers.split(b"\r\n")[0])
            finally:
                client.close()

    def test_websocket_rejects_unmasked_oversized_and_non_synthetic_payloads(self):
        for data, expected_code in [(b"\x81\x01x", 1002), (b"\x81\xfe\x04\x01", 1009), (b"private text", 1008)]:
            client, _ = self.websocket()
            try:
                self.read_frame(client)
                if expected_code == 1008:
                    self.send_frame(client, data)
                else:
                    client.sendall(data)
                opcode, body = self.read_frame(client)
                self.assertEqual(opcode, 8)
                self.assertEqual(struct.unpack("!H", body)[0], expected_code)
            finally:
                client.close()


if __name__ == "__main__":
    unittest.main()
