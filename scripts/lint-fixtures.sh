#!/usr/bin/env bash
# lint-fixtures.sh -- enforce SSOT for Tests/fixtures/
#
# Every image in Tests/fixtures/ MUST appear in Tests/fixtures/LICENSES.md.
# Every row in LICENSES.md MUST point at an existing file.
# Fails the build on any drift.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/Tests/fixtures"
REGISTRY="$DIR/LICENSES.md"

[ -f "$REGISTRY" ] || { echo "lint-fixtures: missing $REGISTRY"; exit 1; }

ON_DISK=$(cd "$DIR" && find . -maxdepth 1 -type f \
  \( -name '*.jpg' -o -name '*.png' \) | sed 's|^\./||' | sort)
IN_REGISTRY=$(grep -oE '^\| `[a-z0-9_-]+\.(jpg|png)`' "$REGISTRY" \
  | sed -E 's/^\| `(.+)`$/\1/' | sort -u)

fail=0
disk_count=0
reg_count=0

# Disk -> registry
while IFS= read -r f; do
  [ -z "$f" ] && continue
  disk_count=$((disk_count + 1))
  if ! printf '%s\n' "$IN_REGISTRY" | grep -qx "$f"; then
    echo "lint-fixtures: FAIL $f is in Tests/fixtures/ but missing from LICENSES.md"
    fail=1
  fi
done <<< "$ON_DISK"

# Registry -> disk
while IFS= read -r f; do
  [ -z "$f" ] && continue
  reg_count=$((reg_count + 1))
  if [ ! -f "$DIR/$f" ]; then
    echo "lint-fixtures: FAIL $f is in LICENSES.md but missing from Tests/fixtures/"
    fail=1
  fi
done <<< "$IN_REGISTRY"

if [ "$fail" -eq 0 ]; then
  echo "lint-fixtures: OK $disk_count files, $reg_count rows, 1:1"
fi
exit "$fail"
