#!/usr/bin/env python3
"""Create an ephemeral CA and HTTPS fixture certificate outside the repository.

Trust only ca.pem inside a dedicated test build. Never install the private CA key
or server key in an app, and never change production TLS validation.
"""
import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--days", type=int, default=2)
    args = parser.parse_args()
    if args.days < 1 or args.days > 7:
        parser.error("Test certificates must expire within 1–7 days")
    directory = Path(tempfile.mkdtemp(prefix="profile-harness-tls-"))
    directory.chmod(0o700)
    os.umask(0o077)

    def openssl(*command):
        subprocess.run(["openssl", *command], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    openssl("req", "-x509", "-newkey", "rsa:2048", "-nodes", "-keyout", str(directory / "ca.key"),
            "-out", str(directory / "ca.pem"), "-days", str(args.days), "-subj", "/CN=Profile Desk Synthetic Harness Test CA",
            "-addext", "basicConstraints=critical,CA:TRUE", "-addext", "keyUsage=critical,keyCertSign,cRLSign")
    openssl("req", "-newkey", "rsa:2048", "-nodes", "-keyout", str(directory / "server.key"),
            "-out", str(directory / "server.csr"), "-subj", "/CN=localhost")
    (directory / "server.ext").write_text(
        "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:10.0.2.2\n"
        "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\n")
    openssl("x509", "-req", "-in", str(directory / "server.csr"), "-CA", str(directory / "ca.pem"),
            "-CAkey", str(directory / "ca.key"), "-CAcreateserial", "-out", str(directory / "server.pem"),
            "-days", str(args.days), "-extfile", str(directory / "server.ext"))
    print(json.dumps({"directory": str(directory), "ca": str(directory / "ca.pem"),
                      "certificate": str(directory / "server.pem"), "key": str(directory / "server.key"),
                      "hostOrigin": "https://127.0.0.1:8443", "androidEmulatorOrigin": "https://10.0.2.2:8443"}))


if __name__ == "__main__":
    main()
