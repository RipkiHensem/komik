"""Small static guard for secrets accidentally committed to the demo repo.

This is not a dependency audit or a penetration test.
"""

import base64
import json
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
tracked = [
    name.decode()
    for name in subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=ROOT
    ).split(b"\0")
    if name
]

issues: list[str] = []
private_extensions = {".jks", ".keystore", ".p12", ".pfx", ".pem"}
private_key_marker = b"BEGIN " + b"PRIVATE KEY"
for name in tracked:
    path = ROOT / name
    if path.suffix.lower() in private_extensions or path.name.lower().startswith(
        ".env"
    ):
        issues.append(f"Sensitive filename tracked: {name}")
    if path.is_file() and private_key_marker in path.read_bytes():
        issues.append(f"Private key block tracked: {name}")

dart_source = (
    ROOT / "comicstream_app/lib/core/constants/app_constants.dart"
).read_text(encoding="utf-8")
match = re.search(r"supabaseAnonKey\s*=\s*'([^']+)'", dart_source)
if match is None:
    issues.append("Supabase client key could not be classified")
else:
    try:
        payload = match.group(1).split(".")[1]
        padded = payload + "=" * (-len(payload) % 4)
        role = json.loads(base64.urlsafe_b64decode(padded))["role"]
        if role != "anon":
            issues.append("Supabase client key is not an anon key")
    except (IndexError, KeyError, ValueError, json.JSONDecodeError):
        issues.append("Supabase client key is not a readable anon JWT")

auth_source = (ROOT / "comicstream_app/lib/data/services/auth_service.dart").read_text(
    encoding="utf-8"
)
if ".rpc('get_email_by_username'" in auth_source or '"get_email_by_username"' in auth_source:
    issues.append("Public username-to-email RPC remains in the app")

if issues:
    for issue in issues:
        print(f"FAIL: {issue}")
    sys.exit(1)

print(f"PASS: {len(tracked)} tracked files checked; no private key files or blocks")
print("PASS: embedded Supabase client key has anon role")
print("PASS: app no longer calls username-to-email RPC")
