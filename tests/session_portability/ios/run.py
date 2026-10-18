#!/usr/bin/env python3
"""Compile/run a disposable public-WebKit probe; never target a physical device."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
OUTPUT = PROJECT / "build" / ("session-portability-ios-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"))
APP = OUTPUT / "ProfileDeskSessionPortability.app"
BUNDLE = "dev.profiledesk.synthetic-session-portability"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"


def run(arguments, *, capture=False, log=None, check=True):
    with open(log, "a") if log else open(os.devnull, "w") as destination:
        return subprocess.run(arguments, check=check, timeout=60, text=True,
                              stdout=subprocess.PIPE if capture else destination,
                              stderr=subprocess.PIPE if capture else subprocess.STDOUT)


def simctl(*arguments, **kwargs):
    return run(["xcrun", "simctl", *arguments], **kwargs)


def main():
    OUTPUT.mkdir(parents=True)
    APP.mkdir()
    simulator = None
    server = None
    container = None
    exit_code = 1
    cleanup = {"serverStopped": False, "simulatorDeleted": False, "temporaryCertificateDeleted": False}
    snapshot = {str(path.relative_to(PROJECT)): hashlib.sha256(path.read_bytes()).hexdigest()
                for path in sorted(HERE.rglob("*")) if path.is_file() and "__pycache__" not in path.parts}
    (OUTPUT / "source-snapshot.json").write_text(json.dumps(snapshot, indent=2) + "\n")
    try:
        with tempfile.TemporaryDirectory(prefix="profiledesk-session-probe-") as private_name:
            private = Path(private_name)
            sdk = run(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], capture=True).stdout.strip()
            run(["xcrun", "--sdk", "iphonesimulator", "swiftc", "-warnings-as-errors", "-sdk", sdk,
                 "-target", "arm64-apple-ios26.0-simulator", str(HERE / "main.swift"),
                 "-o", str(APP / "ProfileDeskSessionPortability")], log=OUTPUT / "build.log")
            for name, digest in snapshot.items():
                if hashlib.sha256((PROJECT / name).read_bytes()).hexdigest() != digest:
                    raise RuntimeError("Probe source changed during compilation")
            shutil.copy2(HERE / "Info.plist", APP / "Info.plist")
            run(["codesign", "--force", "--sign", "-", str(APP)], log=OUTPUT / "codesign.log")
            runtimes = json.loads(simctl("list", "runtimes", "--json", capture=True).stdout)
            runtime = next(r for r in runtimes["runtimes"] if r["identifier"] == RUNTIME and r.get("isAvailable"))
            device = next(d for d in runtime["supportedDeviceTypes"] if d.get("productFamily") == "iPhone")
            (OUTPUT / "runtime.json").write_text(json.dumps({"identifier": RUNTIME, "version": runtime["version"], "deviceType": device["identifier"]}, indent=2) + "\n")
            run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-sha256", "-nodes", "-days", "1",
                 "-subj", "/CN=ProfileDeskSessionProbeCA", "-addext", "basicConstraints=critical,CA:TRUE",
                 "-addext", "subjectAltName=DNS:localhost,IP:127.0.0.1",
                 "-keyout", str(private / "key.pem"), "-out", str(private / "cert.pem")])
            simulator = simctl("create", "ProfileDesk Synthetic Session Portability", device["identifier"], RUNTIME, capture=True).stdout.strip()
            simctl("boot", simulator)
            # First-run OS migration may exceed one minute. Each invocation is
            # bounded to 60s and at most two target the SAME owned simulator.
            for boot_attempt in range(2):
                try:
                    simctl("bootstatus", simulator, "-b", log=OUTPUT / "simulator.log")
                    break
                except subprocess.TimeoutExpired:
                    if boot_attempt == 1:
                        raise
                    print("Owned simulator first-boot migration exceeded 60s; one bounded continuation.", flush=True)
            simctl("keychain", simulator, "add-root-cert", str(private / "cert.pem"), log=OUTPUT / "simulator.log")
            with open(OUTPUT / "server.log", "w") as server_log:
                server = subprocess.Popen([sys.executable, str(HERE / "server.py"), "--cert", str(private / "cert.pem"), "--key", str(private / "key.pem")], stdout=server_log, stderr=subprocess.STDOUT)
                for _ in range(20):
                    if server.poll() is not None:
                        raise RuntimeError("Owned fixture server stopped")
                    if run(["curl", "--max-time", "1", "--silent", "--fail", "--cacert", str(private / "cert.pem"), "https://localhost:8447/"], check=False).returncode == 0:
                        break
                    time.sleep(0.2)
                else:
                    raise RuntimeError("Owned fixture server did not become ready")
                simctl("install", simulator, str(APP), log=OUTPUT / "simulator.log")
                simctl("launch", simulator, BUNDLE, log=OUTPUT / "simulator.log")
                container = Path(simctl("get_app_container", simulator, BUNDLE, "data", capture=True).stdout.strip())
                deadline = time.monotonic() + 120
                while time.monotonic() < deadline:
                    progress_file = container / "Documents/progress.json"
                    if progress_file.exists():
                        shutil.copy2(progress_file, OUTPUT / "progress.json")
                    result_file = container / "Documents/result.json"
                    if result_file.exists():
                        shutil.copy2(result_file, OUTPUT / "result.json")
                        result = json.loads(result_file.read_text())
                        print(json.dumps({"result": result["result"], "assertions": result["assertions"], "osVersion": result["osVersion"]}), flush=True)
                        exit_code = 0 if result["result"] in {"PASS", "PASS_WITH_LIMITATIONS"} else 1
                        break
                    time.sleep(0.5)
                else:
                    raise RuntimeError("Owned probe timed out without a result")
    except Exception as error:
        (OUTPUT / "runner-failure.json").write_text(json.dumps({"type": type(error).__name__, "message": str(error)}, indent=2) + "\n")
        print("Probe runner failed; see runner-failure.json", flush=True)
    finally:
        if server is not None:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill(); server.wait(timeout=5)
            cleanup["serverStopped"] = server.poll() is not None
        else:
            cleanup["serverStopped"] = True
        if simulator is not None:
            try:
                simctl("shutdown", simulator, check=False, log=OUTPUT / "simulator.log")
                cleanup["simulatorDeleted"] = simctl("delete", simulator, check=False, log=OUTPUT / "simulator.log").returncode == 0
            except Exception:
                cleanup["simulatorDeleted"] = False
        else:
            cleanup["simulatorDeleted"] = True
        cleanup["temporaryCertificateDeleted"] = "private_name" not in locals() or not Path(private_name).exists()
        (OUTPUT / "cleanup.json").write_text(json.dumps(cleanup, indent=2) + "\n")
        print("Evidence: " + str(OUTPUT), flush=True)
    return exit_code if all(cleanup.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
