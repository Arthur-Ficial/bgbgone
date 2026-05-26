#!/usr/bin/env bash
# lint-version-policy.sh -- enforce DEVELOPMENT.md rule #14:
#
#   "Auto-bump only on a real release."
#
# `.version` may be touched ONLY by `make bump-patch` / `bump-minor` /
# `bump-major`, and those targets are reachable ONLY as a prerequisite of
# `make release`. Every other Makefile target (build, install, test,
# docs, readme-images, all-images, every lint) is idempotent against
# `.version`.
#
# This lint statically inspects the Makefile and fails the build if it
# spots `bump-patch` / `bump-minor` / `bump-major` outside of:
#
#   - the .PHONY list
#   - their own target definitions (line starts with `<bump>:`)
#   - the prerequisites of `release:` (line starts with `release:`)
#
# Anything else means rule #14 has regressed.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MK="$ROOT/Makefile"

[ -f "$MK" ] || { echo "lint-version-policy: missing $MK"; exit 1; }

fail=0

check_one() {
  local needle="$1"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local linenum="${line%%:*}"
    local content="${line#*:}"
    # Strip trailing comment.
    local stripped
    stripped=$(printf '%s' "$content" | sed -E 's/[[:space:]]*#.*$//')

    # Allowed forms:
    #   .PHONY: ... <needle> ...
    #   <needle>:                                  (target definition)
    #   release: ... <needle> ...                  (prerequisite of release)
    if [[ "$stripped" == *.PHONY:* ]]; then continue; fi
    if [[ "$stripped" =~ ^[[:space:]]*${needle}: ]]; then continue; fi
    if [[ "$stripped" =~ ^release: ]]; then continue; fi

    echo "lint-version-policy: FAIL Makefile:$linenum  illegal occurrence of '$needle'"
    echo "                            line: $content"
    echo "                            allowed only on .PHONY, '${needle}:' target def, or 'release:' prereq."
    fail=1
  done < <(grep -nE "(^|[[:space:]])${needle}([[:space:]]|:|$)" "$MK")
}

for n in bump-patch bump-minor bump-major; do
  check_one "$n"
done

if [ "$fail" -eq 0 ]; then
  echo "lint-version-policy: OK bump targets only appear on .PHONY, target defs, and 'release:' prereq"
fi
exit "$fail"
