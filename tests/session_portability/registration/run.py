#!/usr/bin/env python3
"""Synthetic native wrapper migration with signed controls and cold restart."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
OUTPUT = PROJECT / "build" / ("session-registration-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"))
BUNDLE = "dev.profiledesk.syntheticRegistration"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
simulator = None
container = None


def linked_section(executable, target):
    """Read only this owned arm64 Mach-O's normal Simulator entitlement section."""
    data = executable.read_bytes()
    magic, _, _, _, commands, _, _, _ = struct.unpack_from("<8I", data)
    if magic != 0xFEEDFACF:
        raise RuntimeError("Expected the owned arm64 Mach-O executable")
    offset = 32
    for _ in range(commands):
        command, size = struct.unpack_from("<II", data, offset)
        if command == 0x19:  # LC_SEGMENT_64
            sections = struct.unpack_from("<I", data, offset + 64)[0]
            for index in range(sections):
                section = offset + 72 + index * 80
                name, segment, _, length, position = struct.unpack_from("<16s16sQQI", data, section)
                if name.rstrip(b"\0") == target and segment.rstrip(b"\0") == b"__TEXT":
                    return data[position:position + length]
        offset += size
    return b""


def run(arguments, *, capture=False, log=None, check=True):
    with open(log, "a") if log else open(os.devnull, "w") as destination:
        return subprocess.run(arguments, check=check, timeout=60, text=True,
                              stdout=subprocess.PIPE if capture else destination,
                              stderr=subprocess.PIPE if capture else subprocess.STDOUT)


def simctl(*arguments, **kwargs):
    return run(["xcrun", "simctl", *arguments], **kwargs)


def boot():
    simctl("boot", simulator, log=OUTPUT / "simulator.log")
    for attempt in range(2):
        try:
            simctl("bootstatus", simulator, "-b", log=OUTPUT / "simulator.log")
            return
        except subprocess.TimeoutExpired:
            if attempt:
                raise
            print("Owned simulator OS startup: one remaining bounded 60-second wait.", flush=True)


def phase(name):
    global container
    simctl("launch", simulator, BUNDLE, "--phase=" + name, log=OUTPUT / "simulator.log")
    container = Path(simctl("get_app_container", simulator, BUNDLE, "data", capture=True).stdout.strip())
    deadline = time.monotonic() + (120 if name == "migrate" else 90)
    last_stage = None
    while time.monotonic() < deadline:
        progress = container / "Documents/progress.json"
        if progress.exists():
            current = json.loads(progress.read_text())
            if current.get("phase") == name and current.get("stage") != last_stage:
                last_stage = current["stage"]
                print(json.dumps({"phase": name, "stage": last_stage}), flush=True)
                (OUTPUT / (name + "-progress.json")).write_text(json.dumps(current, indent=2) + "\n")
        result_file = container / ("Documents/" + name + "-result.json")
        if result_file.exists():
            shutil.copy2(result_file, OUTPUT / result_file.name)
            result = json.loads(result_file.read_text())
            simctl("terminate", simulator, BUNDLE, log=OUTPUT / "simulator.log")
            print(json.dumps({"phase": name, "result": result["result"], "assertions": result["assertions"]}), flush=True)
            if result["result"] != "PASS":
                raise RuntimeError("Synthetic phase failed: " + name)
            return result
        time.sleep(0.5)
    raise RuntimeError("Synthetic phase timed out: " + name)


def install(app, variant):
    simctl("install", simulator, str(app), log=OUTPUT / "simulator.log")
    installed = Path(simctl("get_app_container", simulator, BUNDLE, "app", capture=True).stdout.strip())
    expected = hashlib.sha256((app / "ProfileDeskRegistrationProbe").read_bytes()).hexdigest()
    actual = hashlib.sha256((installed / "ProfileDeskRegistrationProbe").read_bytes()).hexdigest()
    identity = plistlib.loads((installed / "Info.plist").read_bytes())
    matched = expected == actual and identity.get("CFBundleIdentifier") == BUNDLE
    (OUTPUT / (variant + "-installed-identity.json")).write_text(json.dumps({"executableSHA256MatchesBuiltApp": matched,
        "bundleIdentifierMatches": identity.get("CFBundleIdentifier") == BUNDLE,
        "installedExecutableSHA256": actual}, indent=2) + "\n")
    if not matched:
        raise RuntimeError("Installed owned fixture differs from the built control")


def webkit_keychain_statuses():
    # Read only filtered diagnostics from the disposable simulator. Do not
    # retain general logs, any account data, or keychain item contents.
    output = simctl("spawn", simulator, "log", "show", "--last", "10m", "--style", "json",
                    "--predicate", 'eventMessage CONTAINS "WebCrypto master key"', capture=True, check=False)
    statuses = []
    if output.returncode == 0:
        for line in output.stdout.splitlines():
            match = re.search(r'(?:Could not find WebCrypto master key in Keychain|Cannot store WebCrypto master key), error (-?\d+)', line)
            if match:
                statuses.append(int(match.group(1)))
    (OUTPUT / "webkit-keychain-statuses.json").write_text(json.dumps({"commandSucceeded": output.returncode == 0, "statusCodes": statuses}, indent=2) + "\n")


def main():
    global simulator
    OUTPUT.mkdir(parents=True)
    server = None
    result = {"result": "FAIL", "syntheticOnly": True, "realServiceAccessed": False, "physicalDeviceTouched": False}
    cleanup = {"serverStopped": False, "simulatorDeleted": False, "temporaryCertificateDeleted": False}
    snapshot = {str(path.relative_to(PROJECT)): hashlib.sha256(path.read_bytes()).hexdigest()
                for path in sorted(HERE.rglob("*")) if path.is_file() and "__pycache__" not in path.parts}
    (OUTPUT / "source-snapshot.json").write_text(json.dumps(snapshot, indent=2) + "\n")
    try:
        reviewed = json.loads((PROJECT / "build/session-state-public-review/retained-modules.json").read_text())
        modules = [module for module in reviewed["modules"] if module["name"] in {"WAWebSignalCommonUtils", "WAWebSignalStoreApi"}]
        if len(modules) != 2:
            raise RuntimeError("Expected exactly two reviewed public wrapper modules")
        for module in modules:
            if hashlib.sha256((PROJECT / module["path"]).read_bytes()).hexdigest() != module["moduleSHA256"]:
                raise RuntimeError("Reviewed public module hash mismatch")
        findings = json.loads((PROJECT / "build/session-state-public-review/findings.json").read_text())
        (OUTPUT / "reviewed-source.json").write_text(json.dumps({"modules": modules, "algorithm": findings["localSignalWrapping"]["wrapperAlgorithm"], "executedServiceCode": False}, indent=2) + "\n")
        with tempfile.TemporaryDirectory(prefix="profiledesk-registration-probe-") as private_name:
            private = Path(private_name)
            sdk = run(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], capture=True).stdout.strip()
            compiled = OUTPUT / "compiled-probe.o"
            run(["xcrun", "--sdk", "iphonesimulator", "swiftc", "-warnings-as-errors", "-sdk", sdk,
                 "-target", "arm64-apple-ios26.0-simulator", "-emit-object", str(HERE / "main.swift"), "-o", str(compiled)], log=OUTPUT / "build.log")
            baseline_app = OUTPUT / "baseline.app"
            baseline_app.mkdir()
            run(["xcrun", "--sdk", "iphonesimulator", "swiftc", "-sdk", sdk,
                 "-target", "arm64-apple-ios26.0-simulator", str(compiled),
                 "-o", str(baseline_app / "ProfileDeskRegistrationProbe")], log=OUTPUT / "build.log")
            shutil.copy2(HERE / "Info.plist", baseline_app / "Info.plist")
            run(["codesign", "--force", "--sign", "-", str(baseline_app)], log=OUTPUT / "codesign.log")
            derived = OUTPUT / "XcodeBuild"
            run(["xcodebuild", "-project", str(HERE / "RegistrationProbe.xcodeproj"),
                 "-scheme", "ProfileDeskRegistrationProbe", "-configuration", "Debug", "-sdk", "iphonesimulator",
                 "-destination", "generic/platform=iOS Simulator", "-derivedDataPath", str(derived), "-jobs", "1", "build"],
                log=OUTPUT / "xcodebuild.log")
            identity_app = derived / "Build/Products/Debug-iphonesimulator/ProfileDeskRegistrationProbe.app"
            apps = {"baseline": baseline_app, "identity": identity_app}
            generated = list(derived.rglob("*.app-Simulated.xcent"))
            if len(generated) != 1:
                raise RuntimeError("Expected one normal Xcode-generated Simulator identity plist")
            generated_xml = generated[0].read_bytes()
            generated_der = Path(str(generated[0]) + ".der").read_bytes()
            if plistlib.loads(generated_xml).get("application-identifier") != "MD6DKTN62T." + BUNDLE:
                raise RuntimeError("Normal Xcode-generated app identity does not match the owned bundle")
            signing = {}
            for variant, app in apps.items():
                executable = app / "ProfileDeskRegistrationProbe"
                linked_xml = linked_section(executable, b"__entitlements")
                observed = plistlib.loads(linked_xml) if linked_xml else {}
                expected = plistlib.loads(generated_xml) if variant == "identity" else {}
                linked_der = linked_section(executable, b"__ents_der")
                if observed != expected or linked_der != (generated_der if variant == "identity" else b""):
                    raise RuntimeError("Embedded Simulator identity differs from generated control")
                signature = run(["codesign", "--display", "--verbose=4", "--entitlements", "-", str(app)], capture=True)
                host = plistlib.loads(signature.stdout.encode()) if signature.stdout.strip() else {}
                if host not in [{}, {"com.apple.security.get-task-allow": True}] or "Signature=adhoc" not in signature.stderr:
                    raise RuntimeError("Expected a normal ad-hoc Simulator signature")
                signing[variant] = {"observedLinkedSimulatorEntitlements": observed,
                                    "linkedDERMatchesGeneratedInput": True, "linkedDERPresent": bool(linked_der),
                                    "hostSignatureEntitlements": host, "adHocSignatureVerified": True,
                                    "executableSHA256": hashlib.sha256(executable.read_bytes()).hexdigest()}
            (OUTPUT / "signing-control.json").write_text(json.dumps({"sameSwiftSourceSHA256": snapshot[str((HERE / "main.swift").relative_to(PROJECT))],
                "identityBuiltAndPackagedByStandardXcodeTarget": True, "manualIdentityEntitlementPatch": False,
                "controls": signing,
                "adHocSimulatorOnly": True, "appleDevelopmentPrivateKeyUsed": False}, indent=2) + "\n")
            for name, digest in snapshot.items():
                if hashlib.sha256((PROJECT / name).read_bytes()).hexdigest() != digest:
                    raise RuntimeError("Probe source changed during compilation")
            runtimes = json.loads(simctl("list", "runtimes", "--json", capture=True).stdout)
            runtime = next(item for item in runtimes["runtimes"] if item["identifier"] == RUNTIME and item.get("isAvailable"))
            device = next(item for item in runtime["supportedDeviceTypes"] if item.get("productFamily") == "iPhone")
            run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-sha256", "-nodes", "-days", "1",
                 "-subj", "/CN=ProfileDeskRegistrationProbeCA", "-addext", "basicConstraints=critical,CA:TRUE",
                 "-addext", "subjectAltName=DNS:localhost,IP:127.0.0.1", "-keyout", str(private / "key.pem"), "-out", str(private / "cert.pem")])
            simulator = simctl("create", "ProfileDesk Synthetic Registration", device["identifier"], RUNTIME, capture=True).stdout.strip()
            boot()
            simctl("keychain", simulator, "add-root-cert", str(private / "cert.pem"), log=OUTPUT / "simulator.log")
            with open(OUTPUT / "server.log", "w") as server_log:
                server = subprocess.Popen([sys.executable, str(HERE / "server.py"), "--cert", str(private / "cert.pem"), "--key", str(private / "key.pem")], stdout=server_log, stderr=subprocess.STDOUT)
                for _ in range(20):
                    if server.poll() is not None:
                        raise RuntimeError("Owned fixture server stopped")
                    if run(["curl", "--max-time", "1", "--silent", "--fail", "--cacert", str(private / "cert.pem"), "https://localhost:8449/"], check=False).returncode == 0:
                        break
                    time.sleep(0.2)
                else:
                    raise RuntimeError("Owned fixture server did not become ready")
                install(apps["baseline"], "baseline")
                baseline = phase("baseline")
                webkit_keychain_statuses()
                # A clean ordinary installation avoids carrying any identity
                # registration/cache from the intentionally malformed baseline.
                # Its only diagnostic store was already publicly removed; no
                # source or destination identity records exist at this point.
                simctl("uninstall", simulator, BUNDLE, log=OUTPUT / "simulator.log")
                install(apps["identity"], "identity")
                identity = phase("identity")
                migrated = phase("migrate")
                # Kill the app before a full reboot of only this owned simulator,
                # ensuring no old UI/WebContent/Network process supplies a key.
                simctl("shutdown", simulator, log=OUTPUT / "simulator.log")
                boot()
                destination = phase("cold-destination")
                source = phase("cold-source")
                removed = phase("cleanup")
                phases = [baseline, identity, migrated, destination, source, removed]
                baseline_state = next(item for item in baseline["observations"] if "aesGCM" in item)
                baseline_keychain = next(item["keychain"] for item in baseline["observations"] if "keychain" in item)
                resolved = baseline_keychain["addStatus"] == -34018 and all(
                    baseline_state[algorithm]["persisted"] is False and baseline_state[algorithm]["errorName"] == "DataCloneError"
                    for algorithm in ["aesGCM", "aesCTR"])
                cold = migrated["processIdentifier"] != destination["processIdentifier"] and destination["openedStoreLabels"] == ["destination"]
                result.update({"result": "PASS" if resolved and cold else "FAIL", "phaseCount": len(phases),
                               "assertions": sum(item["assertions"] for item in phases),
                               "standardXcodeInstallationResolvesFixtureCloneFailure": resolved,
                               "destinationVerifiedAfterAppTerminationAndOwnedSimulatorReboot": cold,
                               "originalSourcePreserved": source["result"] == "PASS", "allStoreCleanupChecksPass": removed["result"] == "PASS",
                               "originalWrapperKeysExported": False, "syntheticPlaintextTransferPersisted": False,
                               "scope": "Two synthetic AES-CTR registration wrappers only; not a complete service session or production import."})
    except Exception as error:
        (OUTPUT / "runner-failure.json").write_text(json.dumps({"type": type(error).__name__, "message": str(error)}, indent=2) + "\n")
        print("Probe failed; retained diagnostics in output directory.", flush=True)
    finally:
        if server is not None:
            server.terminate()
            try:
                server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill(); server.wait(timeout=5)
        cleanup["serverStopped"] = server is None or server.poll() is not None
        if simulator is not None:
            try:
                simctl("shutdown", simulator, check=False, log=OUTPUT / "simulator.log")
                cleanup["simulatorDeleted"] = simctl("delete", simulator, check=False, log=OUTPUT / "simulator.log").returncode == 0
            except Exception:
                cleanup["simulatorDeleted"] = False
        else:
            cleanup["simulatorDeleted"] = True
        cleanup["temporaryCertificateDeleted"] = "private_name" not in locals() or not Path(private_name).exists()
        result["sourceHashesMatch"] = all(hashlib.sha256((PROJECT / name).read_bytes()).hexdigest() == digest for name, digest in snapshot.items())
        if not all(cleanup.values()) or not result["sourceHashesMatch"]:
            result["result"] = "FAIL"
        (OUTPUT / "cleanup.json").write_text(json.dumps(cleanup, indent=2) + "\n")
        (OUTPUT / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result), flush=True)
        print("Evidence: " + str(OUTPUT), flush=True)
    return 0 if result["result"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
