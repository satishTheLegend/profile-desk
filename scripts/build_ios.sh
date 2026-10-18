#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
flavor="${1:-development}"
target="${2:-simulator}"
case "$flavor" in development|qa|production) ;; *) exit 2;; esac
cd "$project_root/apps/mobile"
if [[ "$target" == simulator ]]; then
  flutter build ios --simulator --debug --flavor "$flavor"
elif [[ "$target" == device-unsigned ]]; then
  flutter build ios --release --no-codesign --flavor "$flavor"
else
  echo 'Use simulator or device-unsigned. Signing is configured separately.' >&2
  exit 2
fi
