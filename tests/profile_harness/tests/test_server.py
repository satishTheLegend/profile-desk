"""Server policy tests use loopback HTTP internally; CLI serving always requires TLS."""
import http.client
import importlib.util
import json
import threading
import unittest
from pathlib import Path
from http.server import ThreadingHTTPServer

spec = importlib.util.spec_from_file_location("harness_server", Path(__file__).parents[1] / "server.py")
server_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server_module)


class HarnessTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), server_module.Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def request(self, path, method="GET", body=None, headers=None):
        host = f"127.0.0.1:{self.server.server_port}"
        connection = http.client.HTTPConnection(host, timeout=3)
        defaults = {"Origin": f"https://{host}", "Content-Type": "application/json"}
        defaults.update(headers or {})
        connection.request(method, path, body=body, headers=defaults)
        response = connection.getresponse()
        result = response.status, dict(response.getheaders()), response.read()
        connection.close()
        return result

    def test_assets_never_allow_path_traversal(self):
        for path in ["/../server.py", "/%2e%2e/server.py", "/unknown", "/web/index.html"]:
            self.assertEqual(self.request(path)[0], 404)

    def test_assets_have_private_test_headers(self):
        status, headers, body = self.request("/")
        self.assertEqual(status, 200)
        self.assertEqual(headers["X-Robots-Tag"], "noindex, nofollow")
        self.assertIn("frame-ancestors 'none'", headers["Content-Security-Policy"])
        self.assertNotIn(b"https://web.whatsapp.com", body)

    def test_http_only_cookie_is_synthetic_persistent_and_scoped(self):
        status, headers, _ = self.request("/api/cookie", "POST", json.dumps({"marker": "synthetic-01"}))
        self.assertEqual(status, 200)
        cookie = headers["Set-Cookie"]
        for expected in ["harness_http_only=synthetic-01", "HttpOnly", "Secure", "SameSite=Strict", "Max-Age=31536000"]:
            self.assertIn(expected, cookie)
        status, _, body = self.request("/api/cookie", headers={"Cookie": "harness_http_only=synthetic-01"})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body), {"marker": "synthetic-01"})

    def test_clear_cookie_expires_only_fixture_cookie(self):
        status, headers, _ = self.request("/api/cookie", "POST", '{"marker":null}')
        self.assertEqual(status, 200)
        self.assertIn("harness_http_only=;", headers["Set-Cookie"])
        self.assertIn("Max-Age=0", headers["Set-Cookie"])

    def test_foreign_origin_cannot_seed_fixture(self):
        status, _, _ = self.request("/api/cookie", "POST", '{"marker":"synthetic-01"}', {"Origin": "https://malicious.invalid"})
        self.assertEqual(status, 403)

    def test_non_synthetic_or_unbounded_input_is_rejected(self):
        for value in ["real-account", "synthetic-\r\nSet-Cookie:x", "synthetic-" + "x" * 49, 9, []]:
            self.assertEqual(self.request("/api/cookie", "POST", json.dumps({"marker": value}))[0], 400)
        self.assertEqual(self.request("/api/cookie", "POST", "x" * 257)[0], 413)
        self.assertEqual(self.request("/api/cookie", "POST", "[]")[0], 400)
        self.assertEqual(self.request("/api/cookie", "POST", "{broken")[0], 400)

    def test_only_valid_fixture_cookie_is_reflected(self):
        _, _, body = self.request("/api/cookie", headers={"Cookie": "harness_http_only=private; unrelated=secret"})
        self.assertEqual(json.loads(body), {"marker": None})


if __name__ == "__main__":
    unittest.main()
