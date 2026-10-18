#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
flutter --version
for package in packages/session_contract packages/local_registry packages/session_engine apps/mobile; do
  (cd "$package" && flutter pub get --enforce-lockfile)
done
