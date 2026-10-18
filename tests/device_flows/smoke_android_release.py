#!/usr/bin/env python3
"""Smoke a local test-signed COPY of the optimized APK on a dedicated emulator.

Never uses a release key. Refuses an existing production installation. Removes
only its new empty test installation and temporary private key in finally.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import signal
import subprocess
import tempfile
import time
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = "dev.profiledesk.profile_desk"


def run(command, **kwargs):
    kwargs.setdefault("timeout", 120)
    return subprocess.run([str(x) for x in command], check=True, capture_output=True,
                          **kwargs).stdout


def assert_welcome(adb, output, remote_path):
    """Observe the candidate's accessible welcome without changing application state."""
    expected = "Set up your workspace"
    last_error = "Welcome heading was absent"
    # UIAutomator may start before Flutter has published semantics. Bound both the
    # attempt count and each command; no permission/login/account interaction occurs.
    for _ in range(3):
        try:
            run(adb + ["shell", "uiautomator", "dump", remote_path], timeout=15)
            document = ET.fromstring(run(adb + ["shell", "cat", remote_path], timeout=5))
            candidate = [node for node in document.iter("node")
                         if node.get("package") == PACKAGE]
            # Retain candidate-only semantics even when the expected control is
            # below the viewport or the bounded assertion ultimately fails.
            evidence = ET.Element("candidate-accessibility", package=PACKAGE)
            for node in candidate:
                ET.SubElement(evidence, "node", node.attrib)
            ET.ElementTree(evidence).write(output / "welcome-accessibility.xml",
                                           encoding="utf-8", xml_declaration=True)
            if any(expected in node.get(attribute, "")
                   for node in candidate for attribute in ("text", "content-desc")):
                return {"expected_heading": expected, "observed": True,
                        "scope": "Candidate-package accessibility nodes only; empty welcome"}
            for node in candidate:
                if node.get("scrollable") != "true":
                    continue
                bounds = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.get("bounds", ""))
                if bounds:
                    left, top, right, bottom = map(int, bounds.groups())
                    x = (left + right) // 2
                    run(adb + ["shell", "input", "swipe", x,
                               top + (bottom - top) * 3 // 4, x,
                               top + (bottom - top) // 4, 300], timeout=8)
                    break
        except (subprocess.SubprocessError, ET.ParseError) as error:
            last_error = str(error)
    raise RuntimeError(f"Candidate welcome accessibility check failed: {last_error}")


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("serial", help="Explicit dedicated emulator serial")
args = parser.parse_args()
sdk = Path(os.environ.get("ANDROID_HOME", Path.home() / "Library/Android/sdk"))
adb = [sdk / "platform-tools/adb", "-s", args.serial]
if run(adb + ["shell", "getprop", "ro.kernel.qemu"]).strip() != b"1":
    raise SystemExit("This local fixture runs only on an explicit emulator.")
packages = run(adb + ["shell", "pm", "list", "packages", PACKAGE]).decode().splitlines()
if f"package:{PACKAGE}" in packages:
    raise SystemExit("Refusing to replace or remove an existing production installation.")
apk = ROOT / "apps/mobile/build/app/outputs/flutter-apk/app-production-release.apk"
output = ROOT / "build/android-production-smoke"
output.mkdir(parents=True, exist_ok=True)
(output / "result.json").unlink(missing_ok=True)
java = Path(os.environ.get("JAVA_HOME", "/opt/homebrew/opt/openjdk@17"))
versions = sorted((sdk / "build-tools").glob("*/apksigner"),
                  key=lambda p: tuple(int(n) for n in p.parent.name.split(".") if n.isdigit()))
if not versions:
    raise SystemExit("Android SDK apksigner unavailable")
install_attempted = False
forward_port = None
remote_ui = f"/sdcard/profiledesk-smoke-{secrets.token_hex(8)}.xml"
def interrupted(_signal, _frame):
    raise InterruptedError("Local smoke interrupted; attempting owned-installation cleanup")

signal.signal(signal.SIGTERM, interrupted)
try:
    with tempfile.TemporaryDirectory(prefix="profiledesk-local-sign-") as directory:
        private = Path(directory)
        password = private / "password"
        password.write_text(secrets.token_urlsafe(32))
        password.chmod(0o600)
        key = private / "local.p12"
        run([java / "bin/keytool", "-genkeypair", "-keystore", key,
             "-storepass:file", password, "-keypass:file", password,
             "-alias", "isolated-local-smoke", "-keyalg", "RSA", "-keysize", "2048",
             "-validity", "2", "-dname", "CN=Profile Desk Local Test Only", "-noprompt"])
        signed = output / "production-local-test-signed.apk"
        run([versions[-1], "sign", "--ks", key, "--ks-pass", f"file:{password}",
             "--out", signed, apk], env={**os.environ, "JAVA_HOME": str(java)})
        run([versions[-1], "verify", signed], env={**os.environ, "JAVA_HOME": str(java)})
        install_attempted = True
        run(adb + ["install", signed])
        run(adb + ["shell", "am", "force-stop", PACKAGE])
        launch = run(adb + ["shell", "am", "start", "-W", "-n", f"{PACKAGE}/.MainActivity"]).decode()
        time.sleep(3)
        pid = run(adb + ["shell", "pidof", PACKAGE]).decode().strip()
        if not pid.isdecimal():
            raise RuntimeError("Production candidate did not survive launch")
        # Empty welcome only: no profile, URL, QR, account or message is created.
        (output / "welcome.png").write_bytes(run(adb + ["exec-out", "screencap", "-p"]))
        welcome = assert_welcome(adb, output, remote_ui)
        sockets = run(adb + ["shell", "cat", "/proc/net/unix"], timeout=15).decode()
        paths = {line.split()[-1] for line in sockets.splitlines() if len(line.split()) >= 8}
        socket = f"webview_devtools_remote_{pid}"
        socket_present = f"@{socket}" in paths
        inspection = {"exact_candidate_pid": pid, "socket_present": socket_present,
                      "target_count": 0, "targets": []}
        if socket_present:
            forward_port = run(adb + ["forward", "tcp:0", f"localabstract:{socket}"], timeout=15).decode().strip()
            if not forward_port.isdecimal():
                raise RuntimeError("ADB did not return an ephemeral inspection port")
            def endpoint(name):
                with urllib.request.urlopen(f"http://127.0.0.1:{forward_port}/json/{name}", timeout=5) as response:
                    return json.load(response)
            version = endpoint("version")
            if version.get("Android-Package") != PACKAGE:
                raise RuntimeError("Inspection endpoint did not identify the candidate package")
            targets = endpoint("list")
            if not isinstance(targets, list):
                raise RuntimeError("Inspection target response was not a list")
            inspection.update({"reported_package": version["Android-Package"],
                               "provider": version.get("Browser"), "target_count": len(targets),
                               "targets": [{"id": target.get("id"), "type": target.get("type")} for target in targets]})
            if targets:
                raise RuntimeError(f"Unexpected candidate inspection targets at empty welcome: {len(targets)}")
        if run(adb + ["shell", "pidof", PACKAGE], timeout=15).decode().strip() != pid:
            raise RuntimeError("Candidate process changed during the welcome probe")
        result = {"result": "PASS", "serial": args.serial,
                  "observed_at": datetime.now(ZoneInfo("Asia/Kolkata")).isoformat(),
                  "android_api": run(adb + ["shell", "getprop", "ro.build.version.sdk"]).decode().strip(),
                  "context": "Optimized production APK, temporary local test signing, empty welcome only",
                  "unsigned_apk_sha256": hashlib.sha256(apk.read_bytes()).hexdigest(),
                  "test_signed_apk_sha256": hashlib.sha256(signed.read_bytes()).hexdigest(),
                  "launch": launch, "alive_after_seconds": 3,
                  "welcome_accessibility": welcome,
                  "screenshot_scope": "FLAG_SECURE may produce a black capture; screenshot is not visual proof of welcome rendering",
                  "inspection": inspection,
                  "inspection_scope": "No inspectable candidate page targets at empty welcome; no WebView was opened and active-page policy was not exercised",
                  "release_signing": False, "service_validation": False}
finally:
    try:
        if forward_port is not None:
            run(adb + ["forward", "--remove", f"tcp:{forward_port}"], timeout=15)
    finally:
        try:
            run(adb + ["shell", "rm", "-f", remote_ui], timeout=15)
        finally:
            if install_attempted:
                remaining = run(adb + ["shell", "pm", "list", "packages", PACKAGE]).decode().splitlines()
                if f"package:{PACKAGE}" in remaining:
                    run(adb + ["uninstall", PACKAGE])
result["temporary_key_removed"] = True
result["empty_test_installation_removed"] = True
result["inspection_forward_removed"] = True
result["remote_accessibility_dump_removed"] = True
(output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))
