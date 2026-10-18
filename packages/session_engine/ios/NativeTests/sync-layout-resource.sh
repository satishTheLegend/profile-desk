#!/bin/bash
set -euo pipefail
plugin_root="$(cd "$(dirname "$0")/../.." && pwd)"
python3 - "$plugin_root" "$@" <<'PY'
import hashlib, os, pathlib, sys, tempfile
root = pathlib.Path(sys.argv[1]).resolve()
if sys.argv[2:] not in [[], ['--check']]: raise SystemExit('Usage: sync-layout-resource.sh [--check]')
check_only = sys.argv[2:] == ['--check']
source = root / 'layout/workspace_layout.js'
destination = root / 'ios/session_engine/Sources/session_engine/workspace_layout.js'
data = source.read_bytes()
if destination.is_symlink() or not destination.exists() or destination.read_bytes() != data:
    if check_only: raise SystemExit('SPM layout resource is stale; run packages/session_engine/ios/NativeTests/sync-layout-resource.sh')
    fd, path = tempfile.mkstemp(prefix='.workspace-layout-', dir=destination.parent)
    try:
        with os.fdopen(fd, 'wb') as output:
            output.write(data)
        os.chmod(path, 0o644)
        os.replace(path, destination)
    finally:
        if os.path.exists(path): os.unlink(path)
assert not destination.is_symlink() and destination.read_bytes() == data
print('SPM layout resource ' + ('verified: ' if check_only else 'synchronized: ') + hashlib.sha256(data).hexdigest())
PY
