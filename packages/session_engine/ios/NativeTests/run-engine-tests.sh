#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../../../.." && pwd)"
harness_root="$project_root/packages/session_engine/ios/NativeTests"
output_root="$project_root/build/ios-engine-$(date -u +%Y%m%dT%H%M%SZ)"
app_bundle="$output_root/ProfileDeskEngineHarness.app"
flutter_root="${FLUTTER_ROOT:-$(python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().parents[1])' "$(command -v flutter)")}"
framework_root="$flutter_root/bin/cache/artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator"
simulator_id=""
bounded_simctl() {
  python3 - "$@" <<'PYRUN'
import subprocess, sys
try:
    result = subprocess.run(['xcrun', 'simctl', *sys.argv[1:]], timeout=60)
except subprocess.TimeoutExpired:
    raise SystemExit('Owned simulator command timed out: ' + sys.argv[1])
raise SystemExit(result.returncode)
PYRUN
}
cleanup() {
  if [ -n "$simulator_id" ]; then bounded_simctl shutdown "$simulator_id" 2>/dev/null || true; bounded_simctl delete "$simulator_id"; fi
  printf 'iOS engine regression evidence: %s\n' "$output_root"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$app_bundle/Frameworks"
test -f "$framework_root/Flutter.framework/Flutter"
python3 - "$harness_root" "$output_root/source-snapshot.json" <<'PY'
import hashlib, json, os, pathlib, sys
root = pathlib.Path(sys.argv[1])
files = sorted((root.parent / 'session_engine/Sources/session_engine').glob('*.swift'))
files += sorted((root / 'EngineHarness').glob('*'))
files.append(root.parent.parent / "layout/workspace_layout.js")
snapshot = {os.path.relpath(p, root.parent): hashlib.sha256(p.read_bytes()).hexdigest() for p in files if p.is_file()}
pathlib.Path(sys.argv[2]).write_text(json.dumps(snapshot, indent=2, sort_keys=True) + '\n')
PY
xcrun --sdk iphonesimulator swiftc -warnings-as-errors -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -target arm64-apple-ios17.0-simulator -F "$framework_root" -framework Flutter -lsqlite3 \
  -Xlinker -rpath -Xlinker @executable_path/Frameworks \
  "$harness_root"/../session_engine/Sources/session_engine/*.swift "$harness_root/EngineHarness/main.swift" \
  -o "$app_bundle/ProfileDeskEngineHarness" > "$output_root/build.log" 2>&1
python3 - "$harness_root" "$output_root/source-snapshot.json" <<'PY'
import hashlib, json, pathlib, sys
root = pathlib.Path(sys.argv[1]).parent
for name, expected in json.loads(pathlib.Path(sys.argv[2]).read_text()).items():
    if hashlib.sha256((root / name).read_bytes()).hexdigest() != expected:
        raise SystemExit('Fixture source changed during compilation: ' + name)
PY
mkdir -p "$app_bundle/session_engine_layout.bundle"
cp "$project_root/packages/session_engine/layout/workspace_layout.js" "$app_bundle/session_engine_layout.bundle/workspace_layout.js"
cp "$harness_root/EngineHarness/Info.plist" "$app_bundle/Info.plist"
ditto "$framework_root/Flutter.framework" "$app_bundle/Frameworks/Flutter.framework"
codesign --force --sign - "$app_bundle/Frameworks/Flutter.framework" > "$output_root/codesign.log" 2>&1
codesign --force --sign - "$app_bundle" >> "$output_root/codesign.log" 2>&1
xcrun simctl list runtimes --json > "$output_root/runtimes.json"
read -r runtime_id device_type < <(python3 - "$output_root/runtimes.json" <<'PY'
import json, os, sys
runtimes = [r for r in json.load(open(sys.argv[1]))['runtimes'] if r.get('isAvailable') and r.get('name', '').startswith('iOS ') and int(r['version'].split('.')[0]) >= 17]
override = os.environ.get('IOS_TEST_RUNTIME')
if override: runtimes = [r for r in runtimes if r['identifier'] == override]
if not runtimes: raise SystemExit('An available iOS 17+ simulator runtime is required.')
runtime = max(runtimes, key=lambda r: tuple(map(int, r['version'].split('.'))))
devices = [d for d in runtime['supportedDeviceTypes'] if d.get('productFamily') == 'iPhone']
print(runtime['identifier'], devices[0]['identifier'])
PY
)
simulator_id="$(bounded_simctl create 'ProfileDesk Engine Regression' "$device_type" "$runtime_id")"
bounded_simctl boot "$simulator_id"
python3 - "$simulator_id" <<'PY'
import subprocess, sys
subprocess.run(['xcrun', 'simctl', 'bootstatus', sys.argv[1], '-b'], timeout=120, check=True, stdout=subprocess.DEVNULL)
PY
bounded_simctl install "$simulator_id" "$app_bundle"
bounded_simctl launch "$simulator_id" dev.profiledesk.engine-regression
container="$(bounded_simctl get_app_container "$simulator_id" dev.profiledesk.engine-regression data)"
for ((attempt=0; attempt<60; attempt++)); do
  if [ -f "$container/Documents/result.json" ]; then
    cp "$container/Documents/result.json" "$output_root/result.json"
    cat "$output_root/result.json"
    python3 - "$output_root/result.json" <<'PY'
import json, sys
raise SystemExit(0 if json.load(open(sys.argv[1]))['result'] == 'PASS' else 1)
PY
    exit 0
  fi
  sleep 1
done
printf 'Engine regression timed out.\n' >&2
exit 1
