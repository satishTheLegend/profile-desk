#!/usr/bin/env python3
"""Regenerate typed contracts/localizations and fail on source drift."""
import hashlib
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BRIDGE = (
    "packages/session_contract/lib/src/messages.g.dart",
    "packages/session_engine/android/src/main/kotlin/dev/profiledesk/session_engine/Messages.g.kt",
    "packages/session_engine/ios/session_engine/Sources/session_engine/Messages.g.swift",
)


def snapshot():
    paths = [ROOT / name for name in BRIDGE]
    paths.extend((ROOT / "apps/mobile/lib/l10n").glob("*.dart"))
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in paths}


before = snapshot()
subprocess.run(["./scripts/generate_bridge.sh"], cwd=ROOT, check=True)
subprocess.run(["flutter", "gen-l10n"], cwd=ROOT / "apps/mobile", check=True)
after = snapshot()
changed = sorted(key for key in before.keys() | after.keys()
                 if before.get(key) != after.get(key))
if changed:
    raise SystemExit("Generated source drift; review and retain regenerated files: "
                     + ", ".join(changed))
print("PASS: Pigeon bindings and Flutter localization regenerate identically.")
