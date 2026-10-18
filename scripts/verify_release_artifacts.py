#!/usr/bin/env python3
"""Inspect unsigned production artifacts. This is not a runtime or security proof.

Requires the Android SDK apkanalyzer/apksigner and macOS codesign. Only known
fixture markers are searched; their absence cannot establish arbitrary-code
absence. The JSON report records exact artifact hashes and bounded checks.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"
DOMAINS = {
    "root", "file", "database", "sharedpref", "external", "device_root",
    "device_file", "device_database", "device_sharedpref",
}
MARKERS = (
    "FakeSessionEngine", "profiledesk_harness_ca", "profiledesk_test_network_security",
    "harness.profiledesk.invalid", "harness_http_only", "harness_readable",
    "synthetic-journal-test", "ProfileIsolationInstrumentedTest",
    "IntegrationTestPlugin", "FLTIntegrationTestRunner", "IntegrationTestIosTest",
    "plugins.flutter.io/integration_test",
    "https://10.0.2.2:8443", "https://127.0.0.1:8443",
    "https://localhost:8443", "https://localhost:8445",
    "https://localhost:8447", "ownedPortabilityProbe",
    "dev.profiledesk.sessionPortabilityLab",
)
FORBIDDEN_PATHS = re.compile(
    r"(?:^|/)(?:kernel_blob\.bin|vm_snapshot_data|isolate_snapshot_data|"
    r"profile_harness|androidTest|NativeTests|integration_test)(?:/|$)|\.xctest(?:/|$)"
)
FIXTURE_ORIGIN = re.compile(rb"https?://(?:localhost|127\.0\.0\.1|10\.0\.2\.2):844[345]")


def run(command, *, accept_failure=False):
    result = subprocess.run(command, capture_output=True, text=True, timeout=120)
    if result.returncode and not accept_failure:
        raise RuntimeError(f"{Path(command[0]).name} failed ({result.returncode}): "
                           f"{result.stderr[:500]}")
    return result


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def scan_entry(name, data):
    issues = []
    if FORBIDDEN_PATHS.search(name):
        issues.append(f"prohibited fixture/debug path: {name}")
    if FIXTURE_ORIGIN.search(data):
        issues.append(f"known local fixture origin in {name}")
    for marker in MARKERS:
        if marker.encode() in data or marker.encode("utf-16-le") in data:
            issues.append(f"known fixture marker {marker!r} in {name}")
    return issues


def require(condition, message):
    if not condition:
        raise ValueError(message)


def android_checks(apk, sdk):
    analyzer = sdk / "cmdline-tools/latest/bin/apkanalyzer"
    versions = sorted((sdk / "build-tools").glob("*/apksigner"),
                      key=lambda p: tuple(int(n) for n in re.findall(r"\d+", p.parent.name)))
    require(analyzer.exists() and versions, "Required Android SDK tools are missing")
    with zipfile.ZipFile(apk) as archive:
        entries = archive.namelist()
        issues = [issue for name in entries for issue in scan_entry(name, archive.read(name))]
        require(not issues, "; ".join(issues))
        require("lib/arm64-v8a/libapp.so" in entries, "Android AOT application library missing")
        require(not any(n.startswith("META-INF/") and n.endswith((".RSA", ".DSA", ".EC"))
                        for n in entries), "Expected unsigned APK has JAR signing material")
        # Flutter's resource shrinker may rename packaged XML paths. Resolve names
        # from the resource table rather than trusting source filenames.
        resource_output = run([str(sdk / "build-tools" / versions[-1].parent.name / "aapt2"),
                               "dump", "resources", str(apk)]).stdout
        resource_paths = {}
        resource_name = None
        for line in resource_output.splitlines():
            match = re.search(r"resource 0x[0-9a-f]+ xml/(backup_rules|data_extraction_rules)", line)
            if match:
                resource_name = match.group(1)
            elif "resource 0x" in line:
                resource_name = None
            if resource_name:
                match = re.search(r"\(file\) (\S+) type=XML", line)
                if match:
                    resource_paths[resource_name] = match.group(1)
        require(set(resource_paths) == {"backup_rules", "data_extraction_rules"},
                "Backup rule resources could not be resolved in the APK")
    manifest = ET.fromstring(run([str(analyzer), "manifest", "print", str(apk)]).stdout)
    app = manifest.find("application")
    require(app is not None, "Android application manifest entry missing")
    require(manifest.get("package") == "dev.profiledesk.profile_desk", "Wrong Android production identifier")
    require(app.get(ANDROID + "debuggable", "false") == "false", "APK is debuggable")
    require(app.get(ANDROID + "allowBackup") == "false", "APK enables backup")
    require(app.get(ANDROID + "usesCleartextTraffic") == "false", "APK enables cleartext traffic")
    require(app.get(ANDROID + "testOnly", "false") == "false", "APK is test-only")
    require(app.get(ANDROID + "networkSecurityConfig") is None, "Unexpected network security override")
    require(manifest.find("instrumentation") is None, "Instrumentation entry in production APK")
    permission_names = {item.get(ANDROID + "name") for item in manifest.findall("uses-permission")}
    require(not permission_names.intersection({"android.permission.CAMERA", "android.permission.RECORD_AUDIO",
            "android.permission.MANAGE_EXTERNAL_STORAGE", "android.permission.READ_EXTERNAL_STORAGE"}),
            "Unvalidated capture or broad-storage permission in APK")
    parsed_rules = {}
    for name, path in resource_paths.items():
        tree = ET.fromstring(run([str(analyzer), "resources", "xml", "--file", path, str(apk)]).stdout)
        sections = [tree] if name == "backup_rules" else [tree.find("cloud-backup"), tree.find("device-transfer")]
        for section in sections:
            require(section is not None, f"Missing backup policy in {name}")
            excluded = {item.get("domain") for item in section.findall("exclude") if item.get("path") == "."}
            require(DOMAINS <= excluded, f"Incomplete backup exclusions in {name}/{section.tag}")
        parsed_rules[name] = path
    dex_command = [str(analyzer), "dex", "packages", "--defined-only"]
    mapping = ROOT / "apps/mobile/build/app/outputs/mapping/productionRelease/mapping.txt"
    if mapping.is_file():
        dex_command.extend(["--proguard-mappings", str(mapping)])
    dex = run(dex_command + [str(apk)]).stdout
    require(not re.search(r"org\.junit|androidx\.test\.|org\.robolectric|ProfileIsolationInstrumentedTest|HarnessActivity", dex),
            "Test classes in APK DEX definitions")
    signature = run([str(versions[-1]), "verify", str(apk)], accept_failure=True)
    require(signature.returncode != 0 and "Missing META-INF/MANIFEST.MF" in signature.stderr,
            "APK is not the expected unsigned artifact; inspect signature separately")
    return {
        "artifact": str(apk.relative_to(ROOT)), "sha256": sha256(apk), "bytes": apk.stat().st_size,
        "package": manifest.get("package"), "debuggable": False, "allow_backup": False,
        "cleartext": False, "backup_resources": parsed_rules, "signature": "unsigned (expected)",
        "known_fixture_marker_scan": "PASS", "zip_entries_scanned": len(entries),
        "dex_test_class_scan": "PASS", "dex_mapping_used": mapping.is_file(),
        "mapping_sha256": sha256(mapping) if mapping.is_file() else None,
        "aot_library_present": True,
    }


def ios_checks(bundle):
    info = plistlib.loads((bundle / "Info.plist").read_bytes())
    require(info.get("CFBundleIdentifier") == "dev.profiledesk.profileDesk", "Wrong iOS production identifier")
    require(info.get("CFBundleSupportedPlatforms") == ["iPhoneOS"], "Expected iOS device artifact")
    require(info.get("MinimumOSVersion") == "17.0", "Unexpected iOS minimum version")
    require(info.get("WKAppBoundDomains") == ["web.whatsapp.com"], "Unexpected app-bound domains")
    require(not info.get("NSBonjourServices"), "Debug Bonjour service in production bundle")
    require(not info.get("NSAppTransportSecurity"), "Unexpected ATS exception in production bundle")
    require(not info.get("NSCameraUsageDescription") and not info.get("NSMicrophoneUsageDescription"),
            "Unvalidated camera/microphone declaration in production bundle")
    require(not info.get("UIApplicationSceneManifest", {}).get("UIApplicationSupportsMultipleScenes", False),
            "Multiple iOS scenes enabled")
    files = sorted(path for path in bundle.rglob("*") if path.is_file())
    issues = [issue for path in files for issue in scan_entry(str(path.relative_to(bundle)), path.read_bytes())]
    require(not issues, "; ".join(issues))
    require((bundle / "Frameworks/App.framework/App").is_file(), "iOS AOT application library missing")
    signature = run(["/usr/bin/codesign", "-d", "--entitlements", ":-", str(bundle)], accept_failure=True)
    require(signature.returncode != 0 and "not signed at all" in signature.stderr,
            "Expected unsigned iOS device bundle; inspect signing separately")
    require(not (bundle / "embedded.mobileprovision").exists(), "Unexpected embedded provision profile")
    privacy = {}
    for path in files:
        if path.name == "PrivacyInfo.xcprivacy":
            manifest = plistlib.loads(path.read_bytes())
            require(manifest.get("NSPrivacyTracking") is False, "Privacy manifest declares tracking")
            privacy[str(path.relative_to(bundle))] = manifest
    require("session_engine_session_engine.bundle/PrivacyInfo.xcprivacy" in privacy,
            "Native plugin privacy manifest is not packaged")
    require("Frameworks/Flutter.framework/PrivacyInfo.xcprivacy" in privacy,
            "Flutter privacy manifest is not packaged")
    # Deterministic directory digest: relative path, NUL, file digest, LF.
    inventory = [(str(path.relative_to(bundle)), sha256(path)) for path in files]
    tree_hash = hashlib.sha256("".join(f"{name}\0{digest}\n" for name, digest in inventory).encode()).hexdigest()
    return {
        "artifact": str(bundle.relative_to(ROOT)), "tree_sha256": tree_hash,
        "executable_sha256": sha256(bundle / info["CFBundleExecutable"]),
        "aot_sha256": sha256(bundle / "Frameworks/App.framework/App"),
        "bundle_id": info["CFBundleIdentifier"], "minimum_os": info["MinimumOSVersion"],
        "signature": "unsigned (expected); final distribution entitlements not evaluated",
        "files_scanned": len(files), "known_fixture_marker_scan": "PASS", "privacy_manifests": privacy,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path, default=ROOT / "apps/mobile/build/app/outputs/flutter-apk/app-production-release.apk")
    parser.add_argument("--ios-app", type=Path, default=ROOT / "apps/mobile/build/ios/iphoneos/Runner.app")
    parser.add_argument("--android-sdk", type=Path, default=Path(os.environ.get("ANDROID_HOME", Path.home() / "Library/Android/sdk")))
    parser.add_argument("--output", type=Path, default=ROOT / "build/release-artifact-checks.json")
    args = parser.parse_args()
    report = {
        "scope": "Unsigned production artifact metadata, known fixture markers, packaged configuration and DEX class inventory; no runtime proof or release approval.",
        "verifier_sha256": sha256(Path(__file__)),
        "known_fixture_markers": list(MARKERS),
        "artifact_inputs": {
            "android_apk_sha256": sha256(args.apk) if args.apk.is_file() else None,
            "ios_executable_sha256": sha256(args.ios_app / "Runner") if (args.ios_app / "Runner").is_file() else None,
        },
    }
    try:
        report["android"] = android_checks(args.apk.resolve(), args.android_sdk)
        report["ios"] = ios_checks(args.ios_app.resolve())
        report["result"] = "PASS"
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired, zipfile.BadZipFile, ET.ParseError) as error:
        report["result"] = "FAIL"
        report["error"] = str(error)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Artifact checks: {report['result']}. Report: {args.output}")
    if report["result"] != "PASS":
        print(report["error"], file=sys.stderr)
        return 1
    print("Signatures intentionally absent; candidate runtime and final signed checks remain separate.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
