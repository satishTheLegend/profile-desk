#!/usr/bin/env python3
"""Owned Simulator-only empty-origin restore capability experiment."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import struct
import subprocess
import time

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
OUTPUT = PROJECT / "build" / ("session-origin-bootstrap-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"))
BUNDLE = "dev.profiledesk.syntheticOriginBootstrap"
EXECUTABLE = "ProfileDeskOriginBootstrapProbe"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
simulator = None
installed = False


def run(arguments, *, capture=False, log="simulator.log", check=True):
    with (OUTPUT / log).open("a") if log else open(os.devnull, "w") as destination:
        return subprocess.run(arguments, check=check, timeout=60, text=True,
                              stdout=subprocess.PIPE if capture else destination,
                              stderr=subprocess.PIPE if capture else subprocess.STDOUT)


def simctl(*arguments, **kwargs):
    return run(["xcrun", "simctl", *arguments], **kwargs)


def boot():
    simctl("boot", simulator)
    for attempt in range(2):
        try:
            simctl("bootstatus", simulator, "-b")
            return
        except subprocess.TimeoutExpired:
            if attempt:
                raise
            print("Owned Simulator startup: one remaining bounded wait.", flush=True)


def phase(name):
    simctl("launch", simulator, BUNDLE, "--phase=" + name)
    container = Path(simctl("get_app_container", simulator, BUNDLE, "data", capture=True).stdout.strip())
    deadline = time.monotonic() + (120 if name == "bootstrap" else 60)
    last_stage = None
    while time.monotonic() < deadline:
        progress = container / "Documents/progress.json"
        if progress.exists():
            current = json.loads(progress.read_text())
            if current.get("phase") == name and current.get("stage") != last_stage:
                last_stage = current["stage"]
                print(json.dumps({"phase": name, "stage": last_stage}), flush=True)
        report = container / ("Documents/" + name + "-result.json")
        if report.exists():
            shutil.copy2(report, OUTPUT / report.name)
            result = json.loads(report.read_text())
            simctl("terminate", simulator, BUNDLE, check=False)
            print(json.dumps({"phase": name, "result": result["result"], "assertions": result["assertions"]}), flush=True)
            return result
        time.sleep(0.5)
    simctl("terminate", simulator, BUNDLE, check=False)
    raise RuntimeError("Owned synthetic phase deadline: " + name)


def linked_section(executable, target):
    """Verify only the owned normal arm64 Simulator app's identity sections."""
    data = executable.read_bytes()
    magic, _, _, _, commands, _, _, _ = struct.unpack_from("<8I", data)
    if magic != 0xFEEDFACF:
        raise RuntimeError("Expected the owned arm64 Simulator executable")
    offset = 32
    for _ in range(commands):
        command, size = struct.unpack_from("<II", data, offset)
        if command == 0x19:
            sections = struct.unpack_from("<I", data, offset + 64)[0]
            for index in range(sections):
                section = offset + 72 + index * 80
                name, segment, _, length, position = struct.unpack_from("<16s16sQQI", data, section)
                if name.rstrip(b"\0") == target and segment.rstrip(b"\0") == b"__TEXT":
                    return data[position:position + length]
        offset += size
    return b""


def main():
    global simulator, installed
    OUTPUT.mkdir(parents=True)
    snapshot = {str(path.relative_to(PROJECT)): hashlib.sha256(path.read_bytes()).hexdigest()
                for path in sorted(HERE.rglob("*")) if path.is_file() and "__pycache__" not in path.parts}
    (OUTPUT / "source-snapshot.json").write_text(json.dumps(snapshot, indent=2) + "\n")
    result = {"result": "FAIL", "syntheticOnly": True, "realServiceAccessed": False,
              "physicalDeviceTouched": False, "remoteClientLoaded": False,
              "scope": "Public loadHTMLString empty-origin synthetic import only; no source quiescence or authenticated restore proof."}
    cleanup = {"ownedStoresAndRuleRemoved": False, "ownedSimulatorDeleted": False}
    phases = []
    try:
        derived = OUTPUT / "XcodeBuild"
        run(["xcodebuild", "-project", str(HERE / "OriginBootstrapProbe.xcodeproj"),
             "-scheme", EXECUTABLE, "-configuration", "Debug", "-sdk", "iphonesimulator",
             "-destination", "generic/platform=iOS Simulator", "-derivedDataPath", str(derived),
             "-jobs", "1", "build"], log="xcodebuild.log")
        app = derived / ("Build/Products/Debug-iphonesimulator/" + EXECUTABLE + ".app")
        generated = list(derived.rglob("*.app-Simulated.xcent"))
        if len(generated) != 1:
            raise RuntimeError("Expected one normal Xcode-generated Simulator identity")
        generated_xml = generated[0].read_bytes()
        generated_der = Path(str(generated[0]) + ".der").read_bytes()
        identity = plistlib.loads(generated_xml)
        if not identity.get("application-identifier", "").endswith("." + BUNDLE):
            raise RuntimeError("Generated identity differs from owned fixture bundle")
        if (plistlib.loads(linked_section(app / EXECUTABLE, b"__entitlements")) != identity or
                linked_section(app / EXECUTABLE, b"__ents_der") != generated_der):
            raise RuntimeError("Linked Simulator identity differs from normal generated sections")
        signature = run(["codesign", "--display", "--verbose=4", "--entitlements", "-", str(app)], capture=True)
        if "Signature=adhoc" not in signature.stderr:
            raise RuntimeError("Expected ordinary ad-hoc Simulator signing")
        (OUTPUT / "signing-control.json").write_text(json.dumps({"standardXcodeTarget": True,
            "linkedXMLAndDERMatchGeneratedInput": True, "adHocSignatureVerified": True,
            "manualEntitlementPatch": False, "appleDevelopmentPrivateKeyUsed": False,
            "executableSHA256": hashlib.sha256((app / EXECUTABLE).read_bytes()).hexdigest()}, indent=2) + "\n")
        runtimes = json.loads(simctl("list", "runtimes", "--json", capture=True).stdout)
        runtime = next(item for item in runtimes["runtimes"] if item["identifier"] == RUNTIME and item.get("isAvailable"))
        device = next(item for item in runtime["supportedDeviceTypes"] if item.get("productFamily") == "iPhone")
        simulator = simctl("create", "ProfileDesk Synthetic Origin Bootstrap", device["identifier"], RUNTIME, capture=True).stdout.strip()
        boot()
        simctl("install", simulator, str(app)); installed = True
        installed_app = Path(simctl("get_app_container", simulator, BUNDLE, "app", capture=True).stdout.strip())
        matched = hashlib.sha256((app / EXECUTABLE).read_bytes()).digest() == hashlib.sha256((installed_app / EXECUTABLE).read_bytes()).digest()
        if not matched or plistlib.loads((installed_app / "Info.plist").read_bytes()).get("CFBundleIdentifier") != BUNDLE:
            raise RuntimeError("Installed fixture does not match built owned app")
        result["installedExecutableMatchesBuiltApp"] = matched
        first = phase("bootstrap"); phases.append(first)
        # Preserve a bootstrap failure while collecting independent cold-store
        # diagnostics. Later passes cannot turn the failed bootstrap into PASS.
        simctl("shutdown", simulator); boot()
        destination = phase("cold-destination"); phases.append(destination)
        source = phase("cold-source"); phases.append(source)
        distinct = len({item["processInstanceID"] for item in phases}) == 3
        correct_stores = destination["openedStoreLabels"] == ["destination"] and source["openedStoreLabels"] == ["source"]
        result.update({"result": "PASS" if all(item["result"] == "PASS" for item in phases) and distinct and correct_stores else "FAIL",
                       "coldProcessesDistinct": distinct, "coldProcessesOpenOnlyDesignatedNamedStore": correct_stores,
                       "ownedSimulatorRebootBeforeColdVerification": True})
    except Exception as error:
        (OUTPUT / "runner-failure.json").write_text(json.dumps({"type": type(error).__name__, "message": str(error)}, indent=2) + "\n")
    finally:
        if simulator is not None:
            if installed:
                try:
                    simctl("terminate", simulator, BUNDLE, check=False)
                    removed = phase("cleanup"); phases.append(removed)
                    cleanup["ownedStoresAndRuleRemoved"] = removed["result"] == "PASS"
                except Exception:
                    cleanup["ownedStoresAndRuleRemoved"] = False
            else:
                cleanup["ownedStoresAndRuleRemoved"] = True
            try:
                simctl("shutdown", simulator, check=False)
                cleanup["ownedSimulatorDeleted"] = simctl("delete", simulator, check=False).returncode == 0
            except Exception:
                cleanup["ownedSimulatorDeleted"] = False
        else:
            cleanup = {key: True for key in cleanup}
        result["phaseCount"] = len(phases)
        result["assertions"] = sum(item["assertions"] for item in phases)
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
