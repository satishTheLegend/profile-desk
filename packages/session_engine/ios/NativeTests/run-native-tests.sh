#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../../../.." && pwd)"
harness_root="$project_root/packages/session_engine/ios/NativeTests"
output_root="$project_root/build/ios-native-$(date -u +%Y%m%dT%H%M%SZ)"
simulator_id=""
cleanup() {
  if [ -d "$output_root/results.xcresult" ]; then
    xcrun xcresulttool get test-results summary --path "$output_root/results.xcresult" > "$output_root/summary.json" 2>/dev/null || true
  fi
  if [ -n "$simulator_id" ]; then
    xcrun simctl shutdown "$simulator_id" 2>/dev/null || true
    xcrun simctl delete "$simulator_id"
  fi
  printf 'Native iOS evidence: %s\n' "$output_root"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$output_root"
xcrun simctl list runtimes --json > "$output_root/runtimes.json"
runtime_and_device="$(python3 - "$output_root/runtimes.json" <<'PY'
import json, os, sys
runtimes = [r for r in json.load(open(sys.argv[1]))['runtimes']
            if r.get('isAvailable') and r.get('name', '').startswith('iOS ') and int(r['version'].split('.')[0]) >= 17]
override = os.environ.get('IOS_TEST_RUNTIME')
if override:
    runtimes = [r for r in runtimes if r['identifier'] == override]
if not runtimes:
    raise SystemExit('An available iOS 17+ simulator runtime is required.')
runtime = max(runtimes, key=lambda r: tuple(map(int, r['version'].split('.'))))
devices = [d for d in runtime['supportedDeviceTypes'] if d.get('productFamily') == 'iPhone']
device = os.environ.get('IOS_TEST_DEVICE_TYPE') or devices[0]['identifier']
if device not in [d['identifier'] for d in devices]:
    raise SystemExit('Requested simulator device is incompatible with the selected runtime.')
print(runtime['identifier'], device)
PY
)"
read -r runtime_id device_type <<< "$runtime_and_device"
simulator_id="$(xcrun simctl create 'ProfileDesk Native Regression' "$device_type" "$runtime_id")"
xcrun simctl boot "$simulator_id"
python3 - "$harness_root" "$simulator_id" "$output_root" <<'PY'
import pathlib, subprocess, sys
root, simulator, output = sys.argv[1:]
subprocess.run(['xcrun', 'simctl', 'bootstatus', simulator, '-b'], check=True,
               timeout=120, stdout=subprocess.DEVNULL)
with open(pathlib.Path(output) / 'console.log', 'w') as log:
    subprocess.run(['xcodebuild', 'test', '-scheme', 'ProfileDeskNative',
                    '-destination', f'platform=iOS Simulator,id={simulator}',
                    '-derivedDataPath', str(pathlib.Path(output) / 'DerivedData'),
                    '-resultBundlePath', str(pathlib.Path(output) / 'results.xcresult'),
                    '-parallel-testing-enabled', 'NO', '-test-timeouts-enabled', 'YES',
                    '-default-test-execution-time-allowance', '60',
                    '-maximum-test-execution-time-allowance', '120', 'CODE_SIGNING_ALLOWED=NO'],
                   cwd=root, stdout=log, stderr=subprocess.STDOUT, timeout=600, check=True)
PY
