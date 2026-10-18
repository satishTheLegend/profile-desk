#!/usr/bin/env python3
"""Build the standalone lab only. Never install, launch, or access a device."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
BUNDLE = "dev.profiledesk.sessionPortabilityLab"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", choices=("iphoneos", "iphonesimulator"), default="iphonesimulator")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    output = (args.output or PROJECT / "build" / ("session-portability-lab-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"))).resolve()
    output.mkdir(parents=True, exist_ok=False)
    app = output / "SessionPortabilityLab.app"
    app.mkdir()
    files = [HERE / name for name in ("main.swift", "StorageClassifier.js", "Info.plist", "build.py")]
    captured = {path.name: path.read_bytes() for path in files}
    source = {str(path.relative_to(PROJECT)): hashlib.sha256(captured[path.name]).hexdigest() for path in files}
    (output / "source-snapshot.json").write_text(json.dumps(source, indent=2) + "\n")
    staged = output / "captured-inputs"
    staged.mkdir()
    for name, data in captured.items():
        (staged / name).write_bytes(data)
    sdk = subprocess.run(["xcrun", "--sdk", args.sdk, "--show-sdk-path"], check=True, capture_output=True, text=True, timeout=30).stdout.strip()
    target = "arm64-apple-ios17.0" + ("-simulator" if args.sdk == "iphonesimulator" else "")
    with (output / "build.log").open("w") as log:
        subprocess.run(["xcrun", "--sdk", args.sdk, "swiftc", "-warnings-as-errors", "-sdk", sdk,
                        "-target", target, str(staged / "main.swift"), "-o", str(app / "SessionPortabilityLab")],
                       check=True, stdout=log, stderr=subprocess.STDOUT, timeout=60)
    for name in ("StorageClassifier.js", "Info.plist"):
        (app / name).write_bytes(captured[name])
    for path, digest in source.items():
        if hashlib.sha256((PROJECT / path).read_bytes()).hexdigest() != digest:
            raise RuntimeError("Lab source changed during compilation")
    for name in ("StorageClassifier.js", "Info.plist"):
        if (app / name).read_bytes() != captured[name]:
            raise RuntimeError("Packaged lab resource differs from captured input")
    with (app / "Info.plist").open("rb") as source_plist:
        info = plistlib.load(source_plist)
    if info["CFBundleIdentifier"] != BUNDLE:
        raise RuntimeError("Unexpected lab bundle identifier")
    if args.sdk == "iphonesimulator":
        subprocess.run(["codesign", "--force", "--sign", "-", str(app)], check=True, capture_output=True, timeout=30)
    result = {"result": "PASS", "sdk": args.sdk, "bundle": BUNDLE,
              "app": str(app), "deviceSigned": False, "deployed": False, "launched": False,
              "classifierSHA256": hashlib.sha256((app / "StorageClassifier.js").read_bytes()).hexdigest(),
              "scope": "Compilation only. Simulator builds are ad hoc signed; device builds remain unsigned. No device, simulator boot, installation or service access."}
    (output / "build-result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
