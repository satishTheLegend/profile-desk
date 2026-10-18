#!/usr/bin/env python3
"""Preserve local unsigned artifacts and symbols; never sign or upload them."""
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "artifacts/profile-desk-0.1.0-local"
APK = ROOT / "apps/mobile/build/app/outputs/flutter-apk/app-production-release.apk"
APP = ROOT / "apps/mobile/build/ios/iphoneos/Runner.app"
MAPPING = ROOT / "apps/mobile/build/app/outputs/mapping/productionRelease"
IOS_RELEASE = ROOT / "apps/mobile/build/ios/Release-production-iphoneos"
ARTIFACT_NAMES = (
    "android-production-unsigned.apk",
    "ios-production-device-unsigned.zip",
    "native-symbols-and-mapping.zip",
)
SYMBOL_PAIRS = (
    ("Runner", APP / "Runner", IOS_RELEASE / "Runner.app.dSYM"),
    ("App", APP / "Frameworks/App.framework/App", IOS_RELEASE / "App.framework.dSYM"),
    ("Flutter", APP / "Frameworks/Flutter.framework/Flutter", IOS_RELEASE / "Flutter.framework.dSYM"),
)


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def archive(path, inputs):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as output:
        for source, prefix in inputs:
            files = sorted(p for p in source.rglob("*") if p.is_file() or p.is_symlink())
            for item in files:
                name = (Path(prefix) / item.relative_to(source)).as_posix()
                info = zipfile.ZipInfo(name, (2026, 10, 18, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = (item.lstat().st_mode & 0xFFFF) << 16
                data = os.readlink(item).encode() if item.is_symlink() else item.read_bytes()
                output.writestr(info, data)


def uuids(path):
    output = subprocess.run(["xcrun", "dwarfdump", "--uuid", str(path)],
                            check=True, capture_output=True, text=True, timeout=30).stdout
    matches = re.findall(r"UUID: ([0-9A-Fa-f-]{36}) \(([^)]+)\)", output)
    if not matches or len({architecture for _, architecture in matches}) != len(matches):
        raise SystemExit(f"Cannot establish unambiguous symbol UUIDs for {path}")
    return {architecture: value.upper() for value, architecture in matches}


def main():
    required = [APK, MAPPING / "mapping.txt"]
    for label, binary, symbols in SYMBOL_PAIRS:
        required.extend([binary, symbols / "Contents/Resources/DWARF" / label])
    for path in required:
        if not path.is_file():
            raise SystemExit(f"Build the production artifacts and symbols first: missing {path}")
    symbol_uuids = {}
    for label, binary, symbols in SYMBOL_PAIRS:
        binary_uuids, debug_uuids = uuids(binary), uuids(symbols)
        if binary_uuids != debug_uuids:
            raise SystemExit(f"Refusing mismatched {label} dSYM: binary={binary_uuids}, symbols={debug_uuids}")
        symbol_uuids[label] = binary_uuids

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    # TemporaryDirectory creates a private directory on the same filesystem,
    # permitting atomic replacement of each generated file when all are ready.
    with tempfile.TemporaryDirectory(prefix=".profile-desk-candidate-", dir=OUTPUT.parent) as directory:
        stage = Path(directory)
        shutil.copy2(APK, stage / ARTIFACT_NAMES[0])
        archive(stage / ARTIFACT_NAMES[1], [(APP, "Runner.app")])
        symbols = [(MAPPING, "android/productionRelease")]
        symbols.extend((path, f"ios/{path.name}") for _, _, path in SYMBOL_PAIRS)
        archive(stage / ARTIFACT_NAMES[2], symbols)
        for name in ARTIFACT_NAMES[1:]:
            with zipfile.ZipFile(stage / name) as packaged:
                if packaged.testzip() is not None:
                    raise SystemExit(f"Archive integrity failure: {name}")

        names = subprocess.check_output(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT,
        ).decode().split("\0")
        source_hashes = {name: digest(ROOT / name) for name in sorted(set(names))
                         if name.startswith(("apps/", "packages/", "scripts/", ".github/"))
                         and (ROOT / name).is_file()}
        source_json = json.dumps(source_hashes, sort_keys=True, separators=(",", ":")).encode()
        commit = subprocess.run(["git", "rev-parse", "--verify", "HEAD"], cwd=ROOT,
                                capture_output=True, text=True)
        manifest = {
            "version": "0.1.0+1",
            "created_at": datetime.now(ZoneInfo("Asia/Kolkata")).isoformat(),
            "status": "LOCAL_UNSIGNED_CANDIDATE_NOT_DISTRIBUTABLE",
            "git_head": commit.stdout.strip() if commit.returncode == 0 else None,
            "source_snapshot_sha256": hashlib.sha256(source_json).hexdigest(),
            "source_files": source_hashes,
            "toolchains": {"flutter": "3.47.5", "dart": "3.13.4", "xcode": "27.1",
                           "jdk": "17", "gradle": "9.3.1", "android_webkit": "1.17.1"},
            "ios_symbol_uuids": symbol_uuids,
            "artifacts": [{"file": name, "bytes": (stage / name).stat().st_size,
                           "sha256": digest(stage / name)} for name in ARTIFACT_NAMES],
            "limits": ["No release signing or store upload performed.",
                       "The source snapshot identifies files at packaging time, not an attestation of compiler inputs.",
                       "Artifact checks and runtime/device/service evidence are separate."],
        }
        (stage / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

        OUTPUT.mkdir(parents=True, exist_ok=True)
        # A failed/interrupted replacement must never leave an earlier manifest
        # presenting a mixed set of files as a complete valid candidate. Preserve
        # unrelated directory contents and publish the new manifest only last.
        (OUTPUT / "manifest.json").unlink(missing_ok=True)
        for name in ARTIFACT_NAMES:
            os.replace(stage / name, OUTPUT / name)
        os.replace(stage / "manifest.json", OUTPUT / "manifest.json")
    print(json.dumps({"output": str(OUTPUT), "artifacts": manifest["artifacts"],
                      "ios_symbol_uuids": symbol_uuids}, indent=2))


if __name__ == "__main__":
    main()
