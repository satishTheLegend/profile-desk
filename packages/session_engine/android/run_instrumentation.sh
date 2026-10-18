#!/usr/bin/env bash
# Runs only the synthetic Android test APK; never clears or modifies the real app.
set -euo pipefail
if [[ $# -ne 3 ]]; then
  echo 'Usage: run_instrumentation.sh PUBLIC_CA_PEM HTTPS_HARNESS_ORIGIN EMULATOR_SERIAL' >&2
  exit 2
fi
: "${ANDROID_HOME:?Set ANDROID_HOME to the Android SDK directory}"
: "${JAVA_HOME:?Set JAVA_HOME to a compatible JDK}"
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
"$repo_dir/packages/session_engine/android/prepare_harness_certificate.sh" "$1"
origin=$2
serial=$3
switches=${PROFILE_DESK_SWITCHES:-0}
if ! [[ $switches =~ ^[0-9]+$ ]] || (( switches > 200 )); then
  echo 'PROFILE_DESK_SWITCHES must be between 0 and 200' >&2
  exit 2
fi
adb="$ANDROID_HOME/platform-tools/adb"
package=dev.profiledesk.session_engine.test
class=dev.profiledesk.session_engine.ProfileIsolationInstrumentedTest
cd "$repo_dir/apps/mobile/android"
./gradlew :session_engine:assembleDebugAndroidTest :session_engine:testDebugUnitTest --console=plain
apk="$repo_dir/apps/mobile/build/session_engine/outputs/apk/androidTest/debug/session_engine-debug-androidTest.apk"
"$adb" -s "$serial" install -r -t "$apk"
# Only this known synthetic test package is cleared; production variants are distinct.
"$adb" -s "$serial" shell pm clear "$package"
evidence="$repo_dir/apps/mobile/build/session_engine/instrumentation-evidence"
mkdir -p "$evidence"
"$adb" -s "$serial" shell am instrument -w -r -e class "$class" -e harnessOrigin "$origin" -e switches "$switches" "$package/androidx.test.runner.AndroidJUnitRunner" | tee "$evidence/prepare.txt"
# am instrument can return shell success when JUnit fails; inspect its result explicitly.
rg -q 'OK \(8 tests\)' "$evidence/prepare.txt"
"$adb" -s "$serial" shell am force-stop "$package"
"$adb" -s "$serial" shell am instrument -w -r -e class "$class#nativeCleanupJournalAcrossProcessRestart" -e lifecycleStage verify "$package/androidx.test.runner.AndroidJUnitRunner" | tee "$evidence/clean-start-verify.txt"
rg -q 'OK \(1 test\)' "$evidence/clean-start-verify.txt"
"$adb" -s "$serial" shell am force-stop "$package"
"$adb" -s "$serial" shell am instrument -w -r -e class "$class#sixStoresPersistAcrossSeparateProcessAndDeviceReboot" -e persistenceStage verifyProcess -e harnessOrigin "$origin" "$package/androidx.test.runner.AndroidJUnitRunner" | tee "$evidence/process-persistence-verify.txt"
rg -q 'OK \(1 test\)' "$evidence/process-persistence-verify.txt"
echo "Synthetic instrumentation evidence: $evidence"
