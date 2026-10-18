#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test tests/device_flows/flutter tests/release_assets packages/session_contract/lib packages/session_contract/test packages/local_registry/lib packages/local_registry/test packages/session_engine/lib
for package in packages/session_contract packages/local_registry apps/mobile; do
  (cd "$package" && flutter analyze && flutter test)
done
(cd packages/session_engine && flutter analyze)
python3 -m unittest discover -s tests/profile_harness/tests -v
python3 -m unittest discover -s tests/device_flows -p test_shell_runner.py -v
node --check tests/profile_harness/web/app.js
node --check tests/profile_harness/web/worker.js
node --check tests/profile_harness/web/shared-worker.js
node --check tests/profile_harness/web/transport.js
node --check packages/session_engine/layout/workspace_layout.js
bash packages/session_engine/ios/NativeTests/sync-layout-resource.sh --check
python3 scripts/verify_production.py
python3 scripts/check_traceability.py
