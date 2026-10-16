#!/usr/bin/env python3
"""Fast, dependency-free safety checks for the Dog Road Runner repo."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN_NAMES = {"*.jks", "*.keystore", "key.properties", "google-services.json"}
IGNORED = {".git", ".dart_tool", "build", "node_modules"}


def main() -> int:
    bad = []
    for path in ROOT.rglob("*"):
        if any(part in IGNORED for part in path.parts):
            continue
        if path.is_file() and (path.name in FORBIDDEN_NAMES or path.suffix in {".jks", ".keystore"}):
            bad.append(path.relative_to(ROOT).as_posix())
    if bad:
        print("Preflight failed: prohibited credential/keystore files found:")
        for name in bad:
            print(f"  {name}")
        return 1
    result = subprocess.run(
        ["git", "diff", "--check", "HEAD"], cwd=ROOT,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False
    )
    if result.returncode:
        print(result.stdout, end="")
        print("Preflight failed: whitespace/conflict-marker check.")
        return result.returncode
    print("Preflight passed: no prohibited credential files; git diff is clean.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
