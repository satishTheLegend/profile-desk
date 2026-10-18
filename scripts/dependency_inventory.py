#!/usr/bin/env python3
"""Record resolved local Dart dependencies and license hashes; no network upload."""
import csv, hashlib, json, re
from pathlib import Path
from urllib.parse import urljoin, urlparse, unquote
root = Path(__file__).resolve().parents[1]
rows = {}
for config in sorted(root.glob('**/.dart_tool/package_config.json')):
    if any(part in {'build', 'example'} for part in config.relative_to(root).parts):
        continue
    for package in json.loads(config.read_text())['packages']:
        path = Path(unquote(urlparse(urljoin(config.as_uri(), package['rootUri'])).path))
        if not path.exists():
            continue
        pubspec = path / 'pubspec.yaml'
        match = re.search(r'^version:\s*[\'\"]?([^\s\'\"]+)', pubspec.read_text(), re.M) if pubspec.exists() else None
        version = match.group(1) if match else 'SDK/local'
        license_file = next((p for p in [path/'LICENSE', path/'LICENSE.md', path/'LICENSE.txt', path/'COPYING'] if p.exists()), None)
        local = path.is_relative_to(root)
        source = 'workspace' if local else ('Flutter SDK' if '/flutter/' in str(path) and '/.pub-cache/' not in str(path) else 'pub.dev resolved cache')
        key = (package['name'], version)
        row = rows.setdefault(key, {
            'package': package['name'], 'version': version, 'source': source,
            'license_file': license_file.name if license_file else 'REVIEW_REQUIRED',
            'license_sha256': hashlib.sha256(license_file.read_bytes()).hexdigest() if license_file else '',
            'used_by': set(),
        })
        row['used_by'].add(str(config.parent.parent.relative_to(root)))
output = root/'docs/dependencies.csv'
with output.open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['package','version','source','license_file','license_sha256','used_by'], lineterminator='\n')
    writer.writeheader()
    for row in sorted(rows.values(), key=lambda r:r['package']):
        row['used_by'] = '; '.join(sorted(row['used_by']))
        writer.writerow(row)
print(f'Recorded {len(rows)} resolved dependencies. License presence/hash is not a legal or vulnerability audit.')
