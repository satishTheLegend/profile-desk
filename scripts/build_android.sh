#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
flavor="${1:-development}"
mode="${2:-debug}"
case "$flavor" in development|qa|production) ;; *) exit 2;; esac
case "$mode" in debug|profile|release) ;; *) exit 2;; esac
cd "$project_root/apps/mobile"
flutter build apk --flavor "$flavor" "--$mode"
