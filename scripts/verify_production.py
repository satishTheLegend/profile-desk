"""Fail if prohibited debug/data-export surfaces reach production source roots."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
roots=[root/'apps/mobile/lib',root/'packages/session_engine/lib',root/'packages/session_engine/android/src/main',root/'packages/session_engine/ios/session_engine/Sources/session_engine']
patterns={
 'test engine import': r"import .*fake_engine",
 'test origin': r'https?://(?:localhost|127\.0\.0\.1|10\.0\.2\.2)',
 'web native bridge': r'addJavascriptInterface\s*\(',
 'TLS bypass': r'(?:handler|sslErrorHandler)\.proceed\s*\(',
 'Android debug inspection': r'setWebContentsDebuggingEnabled\(true\)',
 'iOS debug inspection': r'isInspectable\s*=\s*true',
 'session extraction': r'getAllCookies\s*\(|CookieManager\.getInstance\(',
}
failures=[]
if re.search(r'(?m)^\s+integration_test\s*:', (root/'apps/mobile/pubspec.yaml').read_text()):
 failures.append('apps/mobile/pubspec.yaml: native integration-test plugin belongs only in isolated QA workspace')
for source in roots:
 for path in source.rglob('*'):
  if not path.is_file() or path.suffix not in {'.dart','.kt','.swift','.xml'}:continue
  text=path.read_text()
  for label,pattern in patterns.items():
   if re.search(pattern,text):failures.append(f'{path.relative_to(root)}: {label}')
if failures:raise SystemExit('\n'.join(failures))
print('Production source exclusions passed. This is source inspection, not artifact/runtime validation.')
