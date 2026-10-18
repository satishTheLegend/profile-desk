#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root/packages/session_contract"
dart run pigeon --input pigeons/session_api.dart
dart format lib/src/messages.g.dart
