#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/../../../.." && pwd)"
package_root="$project_root/packages/session_engine/ios/session_engine"
output_root="$project_root/build/ios-layout-resource-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$output_root"
swift package --package-path "$package_root" describe --type json > "$output_root/package-description.json"
python3 - "$project_root" "$output_root" <<'PY'
import hashlib, json, os, pathlib, subprocess, sys
root, output = map(pathlib.Path, sys.argv[1:])
package = root / 'packages/session_engine/ios/session_engine'
canonical = root / 'packages/session_engine/layout/workspace_layout.js'
target = next(t for t in json.loads((output / 'package-description.json').read_text())['targets'] if t['name'] == 'session_engine')
resources = [r for r in target['resources'] if pathlib.Path(r['path']).name == 'workspace_layout.js']
assert len(resources) == 1 and 'copy' in resources[0]['rule'], 'Production SPM manifest must copy the shared layout resource'
resource = pathlib.Path(resources[0]['path'])
assert resource.is_file() and not resource.is_symlink(), 'SPM must copy a regular resource into the app bundle'
assert resource.read_bytes() == canonical.read_bytes(), 'SPM resource must match the canonical shared script'
loader_path = package / 'Sources/session_engine/WorkspaceWebView.swift'
loader = loader_path.read_text()
start = loader.index('    private static var bundledLayout: String? {')
end = loader.index('\n    override init(', start)
# Execute the production loader unchanged apart from its visibility. The tiny
# Foundation host permits testing Bundle.module without linking UIKit/Flutter.
loader = loader[start:end].replace('private static var bundledLayout', 'static var bundledLayout', 1)
assert '#if SWIFT_PACKAGE' in loader and 'Bundle.module.url' in loader
probe = output / 'package'
source = probe / 'Sources/LayoutResourceProbe'
source.mkdir(parents=True)
(probe / 'Package.swift').write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "LayoutResourceProbe", products: [.executable(name: "LayoutResourceProbe", targets: ["LayoutResourceProbe"])], targets: [.executableTarget(name: "LayoutResourceProbe", resources: [.copy("workspace_layout.js")])])
''')
(source / 'workspace_layout.js').write_bytes(resource.read_bytes())
expected = hashlib.sha256(canonical.read_bytes()).hexdigest()
(source / 'main.swift').write_text('''import Foundation
import CryptoKit
final class WorkspaceWebView: NSObject {
''' + loader + '''
}
guard let resource = Bundle.module.url(forResource: "workspace_layout", withExtension: "js"),
      let loaded = WorkspaceWebView.bundledLayout else { fatalError("SPM production layout loader failed") }
guard try resource.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]).isRegularFile == true,
      try resource.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == false else { fatalError("Packaged resource must be a regular file") }
let digest = SHA256.hash(data: Data(loaded.utf8)).map { String(format: "%02x", $0) }.joined()
guard digest == "''' + expected + '''" else { fatalError("Bundled layout differs from canonical source") }
let result: [String: Any] = ["result": "PASS", "sha256": digest, "loader": "production Bundle.module branch", "resource": resource.lastPathComponent]
print(String(data: try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]), encoding: .utf8)!)
''')
snapshot = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in [canonical, loader_path, package / 'Package.swift']}
(output / 'source-snapshot.json').write_text(json.dumps(snapshot, indent=2, sort_keys=True) + '\n')
# Exercise the real manifest through a Flutter-like package symlink, and prove
# that a stale regular resource fails manifest evaluation before any app build.
validation = output / 'manifest-validation'
validation_package = validation / 'ios/session_engine'
validation_source = validation_package / 'Sources/session_engine'
validation_source.mkdir(parents=True)
(validation / 'layout').mkdir()
(validation / 'layout/workspace_layout.js').write_bytes(canonical.read_bytes())
(validation_package / 'Package.swift').write_bytes((package / 'Package.swift').read_bytes())
validation_resource = validation_source / 'workspace_layout.js'
validation_resource.write_bytes(canonical.read_bytes())
alias = output / 'package-symlink'
os.symlink(validation_package, alias, target_is_directory=True)
command = ['swift', 'package', '--manifest-cache', 'none', '--package-path', str(alias), 'dump-package']
valid = subprocess.run(command, capture_output=True, text=True, timeout=30)
assert valid.returncode == 0, 'Production manifest must locate canonical source through Flutter-like package symlinks: ' + valid.stderr
validation_resource.write_bytes(canonical.read_bytes() + b'\n')
stale = subprocess.run(command, capture_output=True, text=True, timeout=30)
assert stale.returncode != 0 and 'SPM layout resource is missing or stale' in stale.stderr, 'Production manifest must reject a stale generated resource'
(output / 'manifest-guard-result.json').write_text(json.dumps({'result': 'PASS', 'packageSymlink': True, 'staleResourceRejected': True}) + '\n')
PY
swift run --jobs 1 --package-path "$output_root/package" LayoutResourceProbe > "$output_root/result.json" 2> "$output_root/build.log"
python3 - "$project_root" "$output_root" <<'PY'
import hashlib, json, pathlib, sys
root, output = map(pathlib.Path, sys.argv[1:])
for path, expected in json.loads((output / 'source-snapshot.json').read_text()).items():
    assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, 'Resource input changed during verification: ' + path
assert json.loads((output / 'result.json').read_text())['result'] == 'PASS'
PY
cat "$output_root/result.json"
printf 'Swift Package Manager resource evidence: %s\n' "$output_root"
