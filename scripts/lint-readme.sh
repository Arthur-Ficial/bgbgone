#!/bin/bash
# Hard lint: README must never reference flags hard-removed in v1.0.0
# (T54/T55/T56). Their replacements all live under --filter "...".
#
# Allowed exceptions (explicit citation that the flag was removed):
#   - lines that contain "hard-remove" / "removed in" / "replaces removed" /
#     "hard-removed in" / "cannot combine" - those are documentation OF the
#     removal.
# Anything else fails the lint and exits non-zero.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
README="$ROOT/README.md"

FORBIDDEN_PATTERNS=(
  '--feather +[0-9]'
  '--feather +<'
  '--threshold +[0-9]'
  '--threshold +<'
  '--scale +[0-9]'
  '--scale +<'
  '--position +[0-9]'
  '--position +"'
  '--position +<'
  '--position +center'
  '--mask-only'
)

fails=0
echo "lint-readme: scanning $README ..."

for pat in "${FORBIDDEN_PATTERNS[@]}"; do
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        if echo "$line" | grep -qE 'hard-remove|removed in|replaces removed|hard-removed in|cannot combine'; then
            continue
        fi
        echo "  FAIL [$pat]: $line"
        fails=$((fails + 1))
    done < <(grep -nE "$pat" "$README" 2>/dev/null || true)
done

if [ "$fails" -gt 0 ]; then
    echo "" >&2
    echo "lint-readme: $fails forbidden removed-flag reference(s)" >&2
    echo "Replacements:" >&2
    echo "  --mask-only    -> --filter \"fg:matte\"" >&2
    echo "  --feather N    -> --filter \"mask:feather=N\"" >&2
    echo "  --threshold N  -> --filter \"mask:threshold=N\"" >&2
    echo "  --scale F      -> --filter \"fg:scale=F\"" >&2
    echo "  --position X Y -> --filter \"fg:translate=dx,dy\"" >&2
    exit 1
fi

echo "lint-readme: OK"
