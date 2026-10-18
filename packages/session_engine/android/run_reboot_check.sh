#!/usr/bin/env bash
# Reopens already seeded synthetic stores after rebooting only a dedicated QA AVD.
set -euo pipefail
if [[ $# -ne 2 ]]; then
  echo 'Usage: run_reboot_check.sh HTTPS_HARNESS_ORIGIN DEDICATED_QA_EMULATOR_SERIAL' >&2
  exit 2
fi
: "${ANDROID_HOME:?Set ANDROID_HOME to the Android SDK directory}"
origin=$1
serial=$2
adb="$ANDROID_HOME/platform-tools/adb"
python3 - "$adb" "$serial" <<'PY'
import subprocess,sys,time
adb,serial=sys.argv[1:]
if not serial.startswith('emulator-'):
    raise SystemExit('Only a dedicated emulator is accepted; no physical device reboot.')
def command(*args):
    return subprocess.run([adb,'-s',serial,*args],capture_output=True,text=True,timeout=5)
name=command('emu','avd','name').stdout.splitlines()[0]
if not name.startswith('profile_desk_qa_'):
    raise SystemExit('Refusing to reboot an AVD outside the dedicated profile_desk_qa_ namespace.')
old=command('shell','cat','/proc/sys/kernel/random/boot_id').stdout.strip()
if not old:raise SystemExit('Could not establish the previous emulator boot identity.')
subprocess.run([adb,'-s',serial,'reboot'],check=True,timeout=10)
deadline=time.monotonic()+120
while time.monotonic()<deadline:
    try:
        new=command('shell','cat','/proc/sys/kernel/random/boot_id').stdout.strip()
        boot=command('shell','getprop','sys.boot_completed').stdout.strip()
        if new and new!=old and boot=='1':
            print('Dedicated emulator completed a new boot.',flush=True)
            break
    except subprocess.TimeoutExpired:
        pass
    time.sleep(1)
else:raise SystemExit('Dedicated emulator did not finish a new boot within 120 seconds.')
PY
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
evidence="$repo_dir/apps/mobile/build/session_engine/instrumentation-evidence"
mkdir -p "$evidence"
"$adb" -s "$serial" shell am instrument -w -r -e class dev.profiledesk.session_engine.ProfileIsolationInstrumentedTest#sixStoresPersistAcrossSeparateProcessAndDeviceReboot -e persistenceStage verifyReboot -e harnessOrigin "$origin" dev.profiledesk.session_engine.test/androidx.test.runner.AndroidJUnitRunner | tee "$evidence/reboot-persistence-verify.txt"
rg -q 'OK \(1 test\)' "$evidence/reboot-persistence-verify.txt"
