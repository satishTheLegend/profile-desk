#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../../../.." && pwd)"
harness_root="$project_root/packages/session_engine/ios/NativeTests"
mode="${1:-full}"
case "$mode" in full) timeout_seconds=360;; messaging|transport|persistence|persistence-lifecycle) timeout_seconds=180;; stress) timeout_seconds=1800;; *) printf 'Usage: %s [full|messaging|transport|persistence|persistence-lifecycle|stress]\n' "$0" >&2; exit 2;; esac
output_root="$project_root/build/ios-storage-harness"
if [ "$mode" = stress ]; then output_root="$project_root/build/ios-storage-harness-stress"; fi
if [ "$mode" = messaging ]; then output_root="$project_root/build/ios-storage-harness-messaging"; fi
if [ "$mode" = transport ]; then output_root="$project_root/build/ios-storage-harness-transport"; fi
if [ "$mode" = persistence ]; then output_root="$project_root/build/ios-storage-harness-persistence"; fi
if [ "$mode" = persistence-lifecycle ]; then output_root="$project_root/build/ios-storage-harness-persistence-lifecycle"; fi
app_bundle="$output_root/ProfileDeskHarness.app"
private_dir="$(mktemp -d /tmp/profiledesk-tls.XXXXXX)"
chmod 700 "$private_dir"
simulator_id=""
server_pid=""
container=""
cleanup() {
  if [ -n "$container" ] && [ -f "$container/Documents/progress.json" ]; then
    cp "$container/Documents/progress.json" "$output_root/progress.json"
  fi
  if [ -n "$server_pid" ]; then kill "$server_pid" 2>/dev/null || true; fi
  if [ -n "$simulator_id" ]; then xcrun simctl shutdown "$simulator_id" 2>/dev/null || true; xcrun simctl delete "$simulator_id"; fi
  rm -rf "$private_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$app_bundle"
rm -f "$output_root/result.json" "$output_root/progress.json"
if [[ "$mode" = persistence* ]]; then
  rm -f "$output_root/seed-result.json" "$output_root/process-result.json" "$output_root/reboot-result.json"
  rm -f "$output_root/seed-background.json" "$output_root/process-background.json"
fi
openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 1 -subj /CN=ProfileDeskLocalTestCA -addext 'basicConstraints=critical,CA:TRUE' -addext 'subjectAltName=DNS:localhost,IP:127.0.0.1' -keyout "$private_dir/key.pem" -out "$private_dir/cert.pem" >/dev/null 2>&1
simulator_id="$(xcrun simctl create 'ProfileDesk Synthetic Isolation' com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro com.apple.CoreSimulator.SimRuntime.iOS-27-0)"
xcrun simctl boot "$simulator_id"
python3 - "$simulator_id" <<'PY'
import subprocess, sys
subprocess.run(['xcrun', 'simctl', 'bootstatus', sys.argv[1], '-b'], check=True,
               timeout=120, stdout=subprocess.DEVNULL)
PY
xcrun simctl keychain "$simulator_id" add-root-cert "$private_dir/cert.pem"
python3 "$project_root/tests/profile_harness/server.py" --cert "$private_dir/cert.pem" --key "$private_dir/key.pem" --port 8445 >"$output_root/server.log" 2>&1 &
server_pid=$!
for ((attempt=0; attempt<20; attempt++)); do
  if curl --silent --fail --cacert "$private_dir/cert.pem" https://localhost:8445/app.js >/dev/null; then break; fi
  if ! kill -0 "$server_pid" 2>/dev/null; then cat "$output_root/server.log" >&2; exit 1; fi
  sleep 1
done
curl --silent --fail --cacert "$private_dir/cert.pem" https://localhost:8445/app.js >/dev/null
xcrun --sdk iphonesimulator swiftc -warnings-as-errors -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" -target arm64-apple-ios17.0-simulator "$harness_root/../session_engine/Sources/session_engine/WebKitBootstrap.swift" "$harness_root/HarnessApp/main.swift" -o "$app_bundle/ProfileDeskHarness"
cp "$harness_root/HarnessApp/Info.plist" "$app_bundle/Info.plist"
codesign --force --sign - "$app_bundle" >/dev/null
xcrun simctl install "$simulator_id" "$app_bundle"
launch_mode="$mode"
extra_arguments=()
if [[ "$mode" = persistence* ]]; then launch_mode=persistence-seed; fi
if [ "$mode" = persistence-lifecycle ]; then extra_arguments=(--normal-lifecycle); fi
xcrun simctl launch "$simulator_id" dev.profiledesk.synthetic-ios-harness "--$launch_mode" ${extra_arguments[@]+"${extra_arguments[@]}"}
container="$(xcrun simctl get_app_container "$simulator_id" dev.profiledesk.synthetic-ios-harness data)"
wait_result() {
  local output_name="$1"
  for ((attempt=0; attempt<timeout_seconds; attempt++)); do
    if [ -f "$container/Documents/progress.json" ]; then
      cp "$container/Documents/progress.json" "$output_root/progress.json"
    fi
    if [ -f "$container/Documents/result.json" ]; then
      cp "$container/Documents/result.json" "$output_root/$output_name"
      cat "$output_root/$output_name"
      python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))["result"] == "PASS" else 1)' "$output_root/$output_name"
      return $?
    fi
    sleep 1
  done
  printf 'Synthetic harness timed out; inspect simulator logs.\n' >&2
  return 1
}
background_fixture() {
  local stage="$1"
  if [ "$mode" != persistence-lifecycle ]; then return 0; fi
  rm -f "$container/Documents/background.json"
  xcrun simctl launch "$simulator_id" com.apple.Preferences >/dev/null
  for ((attempt=0; attempt<20; attempt++)); do
    if [ -f "$container/Documents/background.json" ]; then
      cp "$container/Documents/background.json" "$output_root/$stage-background.json"
      python3 -c 'import json,sys; v=json.load(open(sys.argv[1])); assert v["event"] == "sceneDidEnterBackground" and v["viewAttached"] is True' "$output_root/$stage-background.json"
      return $?
    fi
    sleep 1
  done
  printf 'UIKit background event was not observed.\n' >&2
  return 1
}
if [[ "$mode" != persistence* ]]; then wait_result result.json; exit $?; fi
wait_result seed-result.json
background_fixture seed
xcrun simctl terminate "$simulator_id" dev.profiledesk.synthetic-ios-harness
rm -f "$container/Documents/result.json"
xcrun simctl launch "$simulator_id" dev.profiledesk.synthetic-ios-harness --persistence-process ${extra_arguments[@]+"${extra_arguments[@]}"}
wait_result process-result.json
background_fixture process
xcrun simctl terminate "$simulator_id" dev.profiledesk.synthetic-ios-harness
rm -f "$container/Documents/result.json"
xcrun simctl shutdown "$simulator_id"
xcrun simctl boot "$simulator_id"
python3 - "$simulator_id" <<'PY'
import subprocess, sys
subprocess.run(['xcrun', 'simctl', 'bootstatus', sys.argv[1], '-b'], check=True,
               timeout=120, stdout=subprocess.DEVNULL)
PY
xcrun simctl launch "$simulator_id" dev.profiledesk.synthetic-ios-harness --persistence-reboot ${extra_arguments[@]+"${extra_arguments[@]}"}
wait_result reboot-result.json
python3 - "$output_root" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
phases = [json.loads((root / name).read_text()) for name in ['seed-result.json', 'process-result.json', 'reboot-result.json']]
value = {'result': 'PASS' if all(p['result'] == 'PASS' for p in phases) else 'FAIL',
         'mode': 'persistence', 'profiles': 2, 'phases': phases,
         'scope': 'Synthetic simulator process termination/relaunch and same-simulator shutdown/boot; not real service or elapsed-day retention.'}
value['backgroundEvents'] = [json.loads(p.read_text()) for p in sorted(root.glob('*-background.json'))]
(root / 'result.json').write_text(json.dumps(value, indent=2) + '\n')
print(json.dumps({'result': value['result'], 'phases': len(phases)}))
PY
