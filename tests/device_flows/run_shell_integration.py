#!/usr/bin/env python3
"""Run the real shell integration test in an isolated QA-only source copy.

The production app manifest never includes the native integration_test plugin.
This command adds that SDK dev dependency only inside build/qa-shell-workspace,
using the separately pinned fixture lock. It does not patch generated registrants
or the Flutter SDK. Use an explicit dedicated simulator/emulator device ID.
"""

import argparse
from dataclasses import dataclass
import fcntl
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
from xml.parsers.expat import ExpatError


ROOT = Path(__file__).resolve().parents[2]
WORKSPACE = ROOT / "build/qa-shell-workspace"
FIXTURES = ROOT / "tests/device_flows/flutter"
MARKER_NAME = ".profiledesk-qa-workspace.json"
OWNER = "profiledesk-isolated-shell-qa-v1"
ANDROID_FIXTURE_ID = "dev.profiledesk.shell_fixture"
IOS_FIXTURE_ID = "dev.profiledesk.shellFixture"
MAX_IOS_INVENTORY_BYTES = 4 * 1024 * 1024


@dataclass(frozen=True)
class FixtureOwnership:
    platform: str
    device_id: str
    executable: str
    identifiers_absent_before: frozenset[str]


def file_hash(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def replace_required(path, before, after, *, count=1):
    contents = path.read_text()
    if contents.count(before) != count:
        raise SystemExit(f"Unexpected source shape for QA transform: {path}")
    path.write_text(contents.replace(before, after))


def isolated_symlink_target(source, destination, source_root, stage):
    target = os.readlink(source)
    # An absolute in-repository link would still point to shared production
    # files after copying. Relative links must stay inside both source and QA.
    if Path(target).is_absolute():
        raise SystemExit(f"Absolute source link cannot be isolated: {source}")
    if not source.resolve().is_relative_to(source_root):
        raise SystemExit(f"Source link leaves the project: {source}")
    if not (destination.parent / target).resolve().is_relative_to(stage):
        raise SystemExit(f"Copied source link would leave the QA workspace: {source}")
    return target


def prepare(*, refresh_native_lock=False):
    production_pubspec = ROOT / "apps/mobile/pubspec.yaml"
    manifest = production_pubspec.read_text()
    if re.search(r"(?m)^\s+integration_test\s*:", manifest):
        raise SystemExit("Production pubspec must not contain integration_test.")
    if manifest.count("\ndev_dependencies:\n") != 1:
        raise SystemExit("Expected one production dev_dependencies section.")
    fixture_lock = FIXTURES / "pubspec.lock"
    native_lock = FIXTURES / "android-app.gradle.lockfile"
    test_source = FIXTURES / "shell_native_test.dart"
    for required in (fixture_lock, test_source):
        if not required.is_file():
            raise SystemExit(f"Missing isolated fixture input: {required}")
    if not refresh_native_lock and not native_lock.is_file():
        raise SystemExit("Missing QA native lock; run --prepare-only --refresh-native-lock first.")

    names = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT,
    ).decode().split("\0")
    names = sorted({name for name in names if name.startswith(("apps/mobile/", "packages/"))})
    WORKSPACE.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".qa-shell-source-", dir=WORKSPACE.parent) as directory:
        stage = Path(directory) / "workspace"
        stage.mkdir(mode=0o700)
        source_hashes = {}
        for name in names:
            source = ROOT / name
            if not source.is_file() and not source.is_symlink():
                continue
            destination = stage / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            if source.is_symlink():
                target = isolated_symlink_target(source, destination, ROOT, stage)
                destination.symlink_to(target)
                source_hashes[name] = hashlib.sha256(target.encode()).hexdigest()
            else:
                shutil.copy2(source, destination)
                source_hashes[name] = file_hash(destination)

        # Resolve complete chains once every selected source link is copied.
        for name in names:
            copied = stage / name
            if copied.is_symlink() and not copied.resolve().is_relative_to(stage):
                raise SystemExit(f"Copied source link chain leaves the QA workspace: {name}")

        app = stage / "apps/mobile"
        # Only this copied manifest receives the native test plugin.
        qa_manifest = manifest.replace("\ndev_dependencies:\n", "\ndev_dependencies:\n  integration_test:\n    sdk: flutter\n", 1)
        (app / "pubspec.yaml").write_text(qa_manifest)
        shutil.copy2(fixture_lock, app / "pubspec.lock")
        (app / "integration_test").mkdir(exist_ok=True)
        shutil.copy2(test_source, app / "integration_test/shell_native_test.dart")
        if native_lock.is_file():
            shutil.copy2(native_lock, app / "android/app/gradle.lockfile")
        android_gradle = app / "android/app/build.gradle.kts"
        # Flutter's failed-build cleanup falls back to namespace, not the flavored
        # applicationId. Both must therefore name only the disposable fixture.
        for key in ("namespace", "applicationId"):
            replace_required(android_gradle, f'{key} = "dev.profiledesk.profile_desk"',
                             f'{key} = "{ANDROID_FIXTURE_ID}"')
        replace_required(app / "android/app/src/main/AndroidManifest.xml",
                         'android:name=".MainActivity"',
                         'android:name="dev.profiledesk.profile_desk.MainActivity"')
        ios_project = app / "ios/Runner.xcodeproj/project.pbxproj"
        ios_contents = ios_project.read_text()
        identifiers = re.findall(r"PRODUCT_BUNDLE_IDENTIFIER = (dev\.profiledesk\.profileDesk(?:\.[A-Za-z]+)?);", ios_contents)
        if not identifiers or "dev.profiledesk.profileDesk.qa" not in identifiers:
            raise SystemExit("Expected default and QA iOS bundle identifiers.")
        ios_contents = re.sub(r"(PRODUCT_BUNDLE_IDENTIFIER = )dev\.profiledesk\.profileDesk(?=[.;])",
                              rf"\g<1>{IOS_FIXTURE_ID}", ios_contents)
        if "PRODUCT_BUNDLE_IDENTIFIER = dev.profiledesk.profileDesk" in ios_contents:
            raise SystemExit("A production iOS bundle identifier survived the QA transform.")
        ios_project.write_text(ios_contents)
        transformed = ("pubspec.yaml", "pubspec.lock", "android/app/gradle.lockfile",
                       "android/app/build.gradle.kts", "android/app/src/main/AndroidManifest.xml",
                       "ios/Runner.xcodeproj/project.pbxproj", "integration_test/shell_native_test.dart")
        marker = {
            "owner": OWNER,
            "purpose": "QA fixture only; never distribute or copy its app artifacts into production outputs.",
            "source_files": source_hashes,
            "fixture_lock_sha256": file_hash(fixture_lock),
            "fixture_test_sha256": file_hash(test_source),
            "effective_qa_pubspec_sha256": file_hash(app / "pubspec.yaml"),
            "android_fixture_ids": [ANDROID_FIXTURE_ID, ANDROID_FIXTURE_ID + ".qa"],
            "ios_fixture_ids": [IOS_FIXTURE_ID, IOS_FIXTURE_ID + ".qa"],
            "qa_only_transforms": {
                "dependency": "integration_test SDK dev dependency and separately pinned Dart/native fixture locks",
                "android": "disposable namespace/applicationId; fully qualified original MainActivity class",
                "ios": "all app/test bundle identifiers moved into the disposable shellFixture family",
                "effective_file_sha256": {name: file_hash(app / name) for name in transformed if (app / name).is_file()},
            },
        }
        (stage / MARKER_NAME).write_text(json.dumps(marker, indent=2) + "\n")
        if WORKSPACE.exists():
            try:
                owned = json.loads((WORKSPACE / MARKER_NAME).read_text()).get("owner") == OWNER
            except (OSError, ValueError):
                owned = False
            if not owned or WORKSPACE.is_symlink():
                raise SystemExit(f"Refusing to replace an unrecognized QA workspace: {WORKSPACE}")
            shutil.rmtree(WORKSPACE)
        os.replace(stage, WORKSPACE)
    return WORKSPACE / "apps/mobile"


def refresh_android_lock(app):
    # Flutter generates the ignored wrapper on its first Android build. Reuse
    # that SDK-generated launcher, but select only the isolated project with -p.
    wrapper = ROOT / "apps/mobile/android/gradlew"
    wrapper_properties = Path("android/gradle/wrapper/gradle-wrapper.properties")
    if not wrapper.is_file() or file_hash(ROOT / "apps/mobile" / wrapper_properties) != file_hash(app / wrapper_properties):
        raise SystemExit("Native lock refresh needs the matching Flutter-generated Android wrapper from a default app build.")
    result = subprocess.run([str(wrapper), "-p", str(app / "android"), ":app:dependencies", "--write-locks", "--console=plain"],
                            cwd=app / "android", stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, timeout=600)
    print(result.stdout, end="")
    result.check_returncode()
    # Gradle's report task can exit zero even if individual configurations fail.
    if re.search(r"\bFAILED\b", result.stdout):
        raise SystemExit("A QA dependency configuration failed to resolve; refusing to publish its lock.")
    generated = app / "android/app/gradle.lockfile"
    contents = generated.read_text()
    if re.search(r"(?m)^io\.flutter:", contents):
        raise SystemExit("QA native lock must exclude SDK-pinned, target-dependent io.flutter coordinates.")
    if not re.search(r"(?m)^androidx\.test\.espresso:espresso-core:[^=]+=.*qaDebugRuntimeClasspath", contents):
        raise SystemExit("QA native lock did not resolve the integration SDK's native dependencies.")
    shutil.copy2(generated, FIXTURES / "android-app.gradle.lockfile")
    marker_path = WORKSPACE / MARKER_NAME
    marker = json.loads(marker_path.read_text())
    marker["qa_only_transforms"]["effective_file_sha256"]["android/app/gradle.lockfile"] = file_hash(generated)
    marker_path.write_text(json.dumps(marker, indent=2) + "\n")


def fixture_identifiers(platform):
    if platform == "android":
        base = ANDROID_FIXTURE_ID
    elif platform == "ios":
        base = IOS_FIXTURE_ID
    else:
        raise SystemExit("The isolated shell fixture supports only Android and iOS.")
    return frozenset((base, base + ".qa"))


def parse_ios_inventory(output):
    if not isinstance(output, bytes) or not output or len(output) > MAX_IOS_INVENTORY_BYTES:
        raise SystemExit("Could not verify the bounded iOS simulator app inventory.")
    try:
        installed = plistlib.loads(output)
    except (plistlib.InvalidFileException, ValueError, TypeError, ExpatError):
        # simctl also emits OpenStep property lists, which plistlib cannot read.
        # Use the system parser through stdin/stdout without temporary files.
        try:
            converted = subprocess.run(["/usr/bin/plutil", "-convert", "xml1", "-o", "-", "--", "-"],
                                       input=output, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       check=True, timeout=5).stdout
            if len(converted) > MAX_IOS_INVENTORY_BYTES:
                raise ValueError("Converted inventory exceeds the size limit")
            installed = plistlib.loads(converted)
        except (OSError, subprocess.SubprocessError, plistlib.InvalidFileException, ValueError, TypeError, ExpatError) as error:
            raise SystemExit("Could not verify the iOS simulator app inventory after plist conversion.") from error
    if not isinstance(installed, dict) or any(not isinstance(key, str) or not key or not isinstance(value, dict)
                                               for key, value in installed.items()):
        raise SystemExit("Could not verify the iOS simulator app inventory.")
    return set(installed)


def device_inventory(platform, device_id, executable):
    if platform == "android":
        output = subprocess.check_output([executable, "-s", device_id, "shell", "pm", "list", "packages"], text=True, timeout=30)
        lines = [line.strip() for line in output.splitlines() if line.strip()]
        if not lines or any(not line.startswith("package:") for line in lines):
            raise SystemExit("Could not verify the Android package inventory.")
        return {line.removeprefix("package:") for line in lines}
    return parse_ios_inventory(subprocess.check_output([executable, "simctl", "listapps", device_id], timeout=30))


def guard_disposable_device(app, device_id):
    devices = json.loads(subprocess.check_output(["flutter", "devices", "--machine"], text=True, timeout=60))
    selected = [device for device in devices if device.get("id") == device_id]
    if len(selected) != 1 or not selected[0].get("isSupported") or not selected[0].get("emulator"):
        raise SystemExit("Use an exact supported, running dedicated emulator/simulator ID; physical devices are not used by this runner.")
    platform = selected[0].get("targetPlatform", "")
    if platform.startswith("android-"):
        platform = "android"
        sdk_dirs = [os.environ.get("ANDROID_HOME"), os.environ.get("ANDROID_SDK_ROOT")]
        properties = app / "android/local.properties"
        if properties.is_file():
            sdk_dirs += re.findall(r"(?m)^sdk\.dir=(.+)$", properties.read_text())
        executable = shutil.which("adb") or next((str(Path(directory) / "platform-tools/adb")
                                                  for directory in sdk_dirs if directory and (Path(directory) / "platform-tools/adb").is_file()), None)
        if not executable:
            raise SystemExit("Cannot find adb to verify that the disposable fixture identities are absent.")
    elif platform == "ios":
        executable = "xcrun"
    else:
        raise SystemExit("The isolated shell fixture supports only Android and iOS.")
    fixture_ids = fixture_identifiers(platform)
    if device_inventory(platform, device_id, executable) & fixture_ids:
        raise SystemExit("A disposable shell fixture app is already installed. Refusing to overwrite its data; use a fresh dedicated device or explicitly remove that fixture first.")
    print("Verified disposable shell fixture identities are absent; the test may install/remove only those fixture identities.")
    return FixtureOwnership(platform, device_id, executable, fixture_ids)


def cleanup_owned_fixture(ownership):
    allowed = fixture_identifiers(ownership.platform)
    if ownership.identifiers_absent_before != allowed or not ownership.device_id:
        raise SystemExit("Refusing cleanup without exact disposable fixture ownership from preflight.")
    installed = device_inventory(ownership.platform, ownership.device_id, ownership.executable)
    failures = []
    for identifier in sorted(installed & ownership.identifiers_absent_before):
        if ownership.platform == "android":
            command = [ownership.executable, "-s", ownership.device_id, "uninstall", identifier]
        else:
            command = [ownership.executable, "simctl", "uninstall", ownership.device_id, identifier]
        try:
            subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=30)
        except (OSError, subprocess.SubprocessError) as error:
            failures.append(f"{identifier}: {type(error).__name__}")
    remaining = device_inventory(ownership.platform, ownership.device_id, ownership.executable) & allowed
    if failures or remaining:
        raise RuntimeError("Disposable fixture cleanup failed: " + "; ".join(failures + sorted(remaining)))
    print("Verified both disposable fixture identities absent after cleanup.")


def run_owned_test(app, ownership):
    test_error = None
    try:
        subprocess.run(["flutter", "test", "--no-pub", "integration_test/shell_native_test.dart", "--flavor", "qa", "-d", ownership.device_id],
                       cwd=app, check=True, timeout=1200)
    except BaseException as error:
        test_error = error
        raise
    finally:
        try:
            cleanup_owned_fixture(ownership)
        except BaseException as cleanup_error:
            if test_error is None:
                raise
            message = f"Additionally, disposable fixture cleanup failed: {type(cleanup_error).__name__}: {cleanup_error}"
            test_error.add_note(message)
            print(message, file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-d", "--device", help="Exact dedicated simulator/emulator device ID")
    parser.add_argument("--prepare-only", action="store_true", help="Copy and resolve the pinned QA fixture without launching a device")
    parser.add_argument("--refresh-native-lock", action="store_true", help="With --prepare-only, regenerate the separately pinned QA Android dependency lock")
    args = parser.parse_args()
    if args.refresh_native_lock and not args.prepare_only:
        parser.error("--refresh-native-lock requires --prepare-only; lock generation never launches a device.")
    if not args.prepare_only and (not args.device or args.device.strip().lower() == "all"):
        parser.error("Provide an explicit dedicated device with -d (or use --prepare-only).")
    WORKSPACE.parent.mkdir(parents=True, exist_ok=True)
    lock_path = WORKSPACE.parent / ".qa-shell-workspace.lock"
    with os.fdopen(os.open(lock_path, os.O_CREAT | os.O_RDWR, 0o600), "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit("Another isolated shell QA run owns the workspace.")
        app = prepare(refresh_native_lock=args.refresh_native_lock)
        subprocess.run(["flutter", "pub", "get", "--enforce-lockfile"], cwd=app, check=True, timeout=300)
        subprocess.run(["flutter", "analyze", "--no-pub", "integration_test/shell_native_test.dart"], cwd=app, check=True, timeout=300)
        if args.refresh_native_lock:
            refresh_android_lock(app)
        if args.prepare_only:
            print(f"Prepared pinned QA fixture only; no device was launched: {app}")
            return
        ownership = guard_disposable_device(app, args.device)
        run_owned_test(app, ownership)


if __name__ == "__main__":
    main()
