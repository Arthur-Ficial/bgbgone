#!/usr/bin/env bash
# lint-block-pairing.sh -- every bgbgone visual-demo block has a paired image.
#
# Rule: any fenced ```bash / ```sh block whose first line invokes `bgbgone`
# on a concrete fixture image MUST have an `![alt](path)` image link within
# 4 lines before or after the closing fence.
#
# Exemptions (NOT required to be paired):
#   - `bgbgone --server ...`             (operational, no visual output)
#   - blocks whose input is a placeholder (`in.jpg`, `photo.jpg`, `<input>`,
#     or shell variables like `$file`) — documentation of the surface, not
#     a demo
#   - CLAUDE.md, docs/server/security.md, docs/design.md — internal /
#     reference docs whose code samples describe behaviour rather than
#     show output
#
# Reason: visual demos must show what they produce. Combined with
# lint-doc-images (no broken paths) and test-doc-blocks (every block runs),
# this gives the triple invariant: every shipped demo is paired AND its
# image resolves AND its code runs against the live binary.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

EXEMPT_FILES=(
  "$ROOT/CLAUDE.md"
  "$ROOT/docs/server/security.md"
  "$ROOT/docs/design.md"
)
is_exempt() {
  local f="$1"
  for e in "${EXEMPT_FILES[@]}"; do
    [ "$f" = "$e" ] && return 0
  done
  return 1
}

FILES=$(find "$ROOT" -type f -name '*.md' \
  ! -path '*/.build/*' ! -path '*/node_modules/*' \
  ! -path '*/docs/archive/*' \
  | sort)

checked=0
fail=0

for md in $FILES; do
  is_exempt "$md" && continue
  while IFS=$'\t' read -r s e first; do
    [ -z "$s" ] && continue
    # Only require pairing for visual-demo bgbgone blocks.
    case "$first" in
      bgbgone\ *|cat\ *bgbgone*|*\|*bgbgone*) ;;
      *) continue ;;
    esac
    # Skip --server blocks (no visual output)
    case "$first" in *--server*) continue ;; esac
    # Skip placeholder/syntax blocks
    case "$first" in
      *in.jpg*|*photo.jpg*|*\<input\>*|*\<image\>*|*\$file*|*\${*) continue ;;
    esac

    checked=$((checked + 1))
    # Lookahead window: 12 lines either side. Wider than 4 because a
    # section often documents the same example through two transports
    # (CLI + curl) before the shared output image.
    lo=$((s - 20)); [ "$lo" -lt 1 ] && lo=1
    hi=$((e + 20))
    if awk -v lo="$lo" -v hi="$hi" 'NR>=lo && NR<=hi' "$md" \
         | grep -qE '!\[[^]]*\]\([^)]+\)'; then
      :
    else
      printf 'UNPAIRED  %s:%d  %s\n' "${md#$ROOT/}" "$s" "$first"
      fail=1
    fi
  done < <(awk '
    BEGIN { in_fence = 0; start = 0; first_line = ""; body_lines = 0 }
    /^```(bash|sh)$/ {
      if (!in_fence) { in_fence = 1; start = NR; first_line = ""; body_lines = 0; next }
    }
    /^```$/ {
      if (in_fence) {
        printf "%d\t%d\t%s\n", start, NR, first_line
        in_fence = 0
        next
      }
    }
    {
      if (in_fence) {
        if (body_lines == 0) first_line = $0
        body_lines++
      }
    }
  ' "$md")
done

if [ "$fail" -eq 0 ]; then
  echo "lint-block-pairing: OK $checked visual-demo block(s), all paired with an image"
fi
exit "$fail"
