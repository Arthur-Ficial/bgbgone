#!/usr/bin/env bash
# Full-image filter delta audit.
#
# For every shipped filter:
#   1. state the pixel hypothesis from filter-delta-audit.txt,
#   2. render the same fixture without the filter,
#   3. render it with the filter,
#   4. fail if the filtered image is effectively unchanged.

set -uo pipefail

BIN="${1:-bgbgone}"
if [[ "$BIN" == */* ]]; then
    BIN="$(cd "$(dirname "$BIN")" && pwd)/$(basename "$BIN")"
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
source "$ROOT/scripts/trash.sh"

FIX="$ROOT/Tests/fixtures/red-panda.jpg"
SPEC="$DIR/filter-delta-audit.txt"
OUT="${2:-$DIR/_tmp/filter-delta-audit}"

trash_path "$OUT"
mkdir -p "$OUT"

failures=0
checked=0

known_filters() {
    "$BIN" --filters-list --json | jq -r '.[].name' | sort
}

audit_filters() {
    awk -F'|' 'NF && $1 !~ /^#/ { print $1 }' "$SPEC" | sort
}

missing=$(comm -23 <(known_filters) <(audit_filters))
extra=$(comm -13 <(known_filters) <(audit_filters))
if [ -n "$missing" ] || [ -n "$extra" ]; then
    [ -n "$missing" ] && printf 'filter-delta-audit: missing spec rows: %s\n' "$missing" >&2
    [ -n "$extra" ] && printf 'filter-delta-audit: extra spec rows: %s\n' "$extra" >&2
    exit 1
fi

bg_arg() {
    case "$1" in
        source) printf 'image:%s' "$FIX" ;;
        solid:*) printf 'color:%s' "${1#solid:}" ;;
        *) printf '%s' "$1" ;;
    esac
}

changed_percent() {
    local base="$1" filtered="$2" ae total
    ae=$(magick compare -metric AE "$base" "$filtered" null: 2>&1 >/dev/null || true)
    ae=${ae%% *}
    total=$(magick identify -format '%[fx:w*h]' "$base")
    awk -v ae="$ae" -v total="$total" 'BEGIN { printf "%.6f", (ae / total) * 100 }'
}

while IFS='|' read -r name layer background min_pct example hypothesis; do
    [ -n "${name:-}" ] || continue
    [[ "$name" == \#* ]] && continue

    checked=$((checked + 1))
    bg=$(bg_arg "$background")
    chain="$layer:$example"
    base="$OUT/$name-baseline.png"
    filtered="$OUT/$name-filtered.png"
    err="$OUT/$name.err"

    printf '  %s\n' "$name"
    printf '    hypothesis: %s\n' "$hypothesis"

    if ! "$BIN" "$FIX" --bg "$bg" --size preview -o "$base" >/dev/null 2>"$err"; then
        printf '    FAIL baseline render: %s\n' "$(head -1 "$err")"
        failures=$((failures + 1))
        continue
    fi

    if ! "$BIN" "$FIX" --bg "$bg" --size preview --filter "$chain" -o "$filtered" >/dev/null 2>"$err"; then
        printf '    FAIL filtered render (%s): %s\n' "$chain" "$(head -1 "$err")"
        failures=$((failures + 1))
        continue
    fi

    pct=$(changed_percent "$base" "$filtered")
    if awk -v pct="$pct" -v min="$min_pct" 'BEGIN { exit !(pct > min) }'; then
        printf '    OK changed %.6f%% with --filter "%s"\n' "$pct" "$chain"
    else
        printf '    FAIL changed %.6f%%, expected > %s%% with --filter "%s"\n' "$pct" "$min_pct" "$chain"
        failures=$((failures + 1))
    fi
done < "$SPEC"

printf 'filter-delta-audit: %d checked, %d failed\n' "$checked" "$failures"
[ "$failures" -eq 0 ]
