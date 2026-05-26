#!/bin/bash
# For every filter in the catalogue, render a bg:/fg:/all: 3-panel comparison
# against the yoga photo (with --type person) and the woman-singer photo (with
# --type person) so the per-filter doc shows a real fg/bg split next to the
# baseline.
#
# Output: docs/images/filters/panels/{yoga,woman-singer}-<filter>.jpg
# (4-up strip: original | bg:X | fg:X | all:X)
#
# For mask-only filters, the panel just renders mask:X once.
# For composite-only filters, the panel renders composite:X once.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/trash.sh"
BIN="${BIN:-$ROOT/.build/release/bgbgone}"
FIX="$ROOT/Tests/fixtures"
PANEL_OUT="$ROOT/docs/images/filters/panels"
YOGA="$FIX/yoga.jpg"
WOMAN_SINGER="$FIX/woman-singer.jpg"
PANEL_EXAMPLES="$ROOT/scripts/filter-panel-examples.txt"

mkdir -p "$PANEL_OUT"

[ -f "$PANEL_EXAMPLES" ] || { echo "missing $PANEL_EXAMPLES" >&2; exit 1; }
ROWS=$(awk -F'|' 'NF && $1 !~ /^#/ { print }' "$PANEL_EXAMPLES")

label_under() {
    local img="$1" label="$2" out="$3"
    magick "$img" -resize 800x800 -background "#1a2233" -gravity south -splice 0x36 \
        -font Helvetica -pointsize 22 -fill white -gravity south -annotate +0+6 "$label" "$out"
}

panel_for_subject() {
    local subj="$1" tag="$2"
    while IFS='|' read -r name layers args; do
        [ -z "$name" ] && continue
        local out="$PANEL_OUT/${tag}-${name}.jpg"
        local tmp; tmp=$(mktemp -d)
        # Every panel starts with the ORIGINAL source so the reader can see
        # the input pixel state before any layer split. CLAUDE.md "panels
        # always lead with original" rule.
        label_under "$subj" "original" "$tmp/orig-l.jpg"
        case "$layers" in
            all)
                "$BIN" "$subj" --type person --filter "bg:${name}${args}" -o "$tmp/bg.jpg" >/dev/null 2>&1 || { trash_path "$tmp"; continue; }
                "$BIN" "$subj" --type person --filter "fg:${name}${args}" -o "$tmp/fg.jpg" >/dev/null 2>&1 || { trash_path "$tmp"; continue; }
                "$BIN" "$subj" --type person --filter "all:${name}${args}" -o "$tmp/all.jpg" >/dev/null 2>&1 || { trash_path "$tmp"; continue; }
                label_under "$tmp/bg.jpg"  "bg:${name}${args}"  "$tmp/bg-l.jpg"
                label_under "$tmp/fg.jpg"  "fg:${name}${args}"  "$tmp/fg-l.jpg"
                label_under "$tmp/all.jpg" "all:${name}${args}" "$tmp/all-l.jpg"
                magick "$tmp/orig-l.jpg" "$tmp/bg-l.jpg" "$tmp/fg-l.jpg" "$tmp/all-l.jpg" +append "$out"
                ;;
            composite-only)
                "$BIN" "$subj" --type person --filter "composite:${name}${args}" -o "$tmp/all.jpg" >/dev/null 2>&1 || { trash_path "$tmp"; continue; }
                label_under "$tmp/all.jpg" "composite:${name}${args}" "$tmp/all-l.jpg"
                magick "$tmp/orig-l.jpg" "$tmp/all-l.jpg" +append "$out"
                ;;
            fg-only)
                "$BIN" "$subj" --type person --bg color:#1a2233 --filter "fg:${name}${args}" -o "$tmp/fg.jpg" >/dev/null 2>&1 || { trash_path "$tmp"; continue; }
                label_under "$tmp/fg.jpg" "fg:${name}${args}" "$tmp/fg-l.jpg"
                magick "$tmp/orig-l.jpg" "$tmp/fg-l.jpg" +append "$out"
                ;;
            mask-only)
                "$BIN" "$subj" --type person --bg color:#1a2233 --filter "mask:${name}${args}" -o "$tmp/mask.jpg" >/dev/null 2>&1 || { trash_path "$tmp"; continue; }
                label_under "$tmp/mask.jpg" "mask:${name}${args}" "$tmp/mask-l.jpg"
                magick "$tmp/orig-l.jpg" "$tmp/mask-l.jpg" +append "$out"
                ;;
        esac
        trash_path "$tmp"
        echo "  ok  ${tag}-${name}"
    done <<< "$ROWS"
}

echo "panels: yoga subject (--type person)"
panel_for_subject "$YOGA" "yoga"
echo "panels: woman-singer subject (--type person)"
panel_for_subject "$WOMAN_SINGER" "woman-singer"

echo "done. $PANEL_OUT"
ls -1 "$PANEL_OUT" | wc -l | awk '{print "  panels: " $1}'
