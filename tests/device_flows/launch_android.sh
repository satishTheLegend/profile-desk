#!/usr/bin/env bash
set -euo pipefail
serial="${1:?provide a dedicated emulator/device serial}"
package="${2:?provide the installed app package}"
case "$package" in dev.profiledesk.profile_desk|dev.profiledesk.profile_desk.dev|dev.profiledesk.profile_desk.qa) ;; *) echo 'Unexpected package' >&2; exit 2;; esac
adb_path="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
"$adb_path" -s "$serial" shell am force-stop "$package"
"$adb_path" -s "$serial" shell am start -W -n "$package/dev.profiledesk.profile_desk.MainActivity"
# A short bounded observation catches immediate startup crashes, not later failures.
sleep 3
"$adb_path" -s "$serial" shell pidof "$package"
