#!/bin/bash
# Hardcore doc syntax linter: extract every `--filter "<chain>"` from every
# tracked markdown file (README.md, docs/**.md, DEVELOPMENT.md) and parse
# each chain against the real bgbgone parser+registry. Any chain that fails
# (parser error rc=2) is a documentation bug.
#
# Catches: misspelled filter names, missing args, invalid layers, wrong
# argument keys. Run by `make release` so a typo never ships.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$ROOT/.build/release/bgbgone}"
FIX="$ROOT/Tests/fixtures/01-nasa-aldrin-moon.jpg"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ ! -x "$BIN" ]; then
    echo "lint-docs: binary not found at $BIN - run 'swift build -c release' first" >&2
    exit 1
fi
if [ ! -f "$FIX" ]; then
    echo "lint-docs: fixture not found at $FIX" >&2
    exit 1
fi

MD_FILES=$(find "$ROOT" \( -name README.md -o -name DEVELOPMENT.md -o -path "*/docs/*.md" -o -path "*/docs/filters/*.md" \) -not -path "*/.build/*")
FILE_COUNT=$(echo "$MD_FILES" | wc -l | tr -d ' ')

echo "lint-docs: validating --filter chains in $FILE_COUNT markdown files ..."

fails=0
checked=0
for f in $MD_FILES; do
    # Extract --filter "..." occurrences. Handles "quoted" form only (the
    # canonical doc form). One per line.
    while IFS= read -r chain; do
        [ -z "$chain" ] && continue
        # Skip grammar placeholders / shell-variable references.
        case "$chain" in
            \<*\>|\$*) continue ;;
        esac
        checked=$((checked + 1))
        # Use --filters-list as a parse-only target: bgbgone runs the
        # ConfigBuilder which validates the chain, then short-circuits to
        # printing the catalogue without invoking Vision. Sub-second per chain.
        out=$("$BIN" --filter "$chain" --filters-list 2>&1); rc=$?
        if [ $rc -eq 2 ]; then
            echo "  FAIL ${f#$ROOT/} -- chain: '$chain'"
            echo "       $(echo "$out" | head -4 | tail -3)"
            fails=$((fails + 1))
        fi
    done < <(grep -oE '\-\-filter +"[^"]*"' "$f" 2>/dev/null | sed -E 's/^--filter +"//; s/"$//')
done

if [ "$fails" -gt 0 ]; then
    echo "" >&2
    echo "lint-docs: $fails invalid --filter chain(s) out of $checked checked" >&2
    exit 1
fi

echo "lint-docs: OK ($checked --filter chain(s) validated across $FILE_COUNT files)"
