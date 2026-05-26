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
FIX="$ROOT/Tests/fixtures/showcase"
PANEL_OUT="$ROOT/docs/images/filters/panels"
YOGA="$FIX/yoga.jpg"
WOMAN_SINGER="$FIX/woman-singer.jpg"

mkdir -p "$PANEL_OUT"

# Filter table: name | layers | example-args
# layers: "all" for fg/bg/all triple; "composite-only" for composite-only; "fg-only";
#         "mask-only"
ROWS=$(cat <<'EOF'
grayscale|all|
desaturate|all|=0.8
negate|all|
sepia|all|=0.85
adjust|all|=brightness=0.1:contrast=1.2:saturation=0.6
gamma|all|=1.8
exposure|all|=0.8
hue|all|=90
tint|all|=color=#ff00ff:amount=0.5
colorize|all|=color=#00bfff:amount=0.9
temperature|all|=3500
levels|all|=black=0.1:white=0.9:gamma=1.2
vibrance|all|=0.8
opacity|all|=0.5
duotone|all|=dark=#003366:light=#ffcc00
blur|all|=22
box-blur|all|=14
motion-blur|all|=radius=22:angle=45
zoom-blur|all|=center=0.5,0.5:amount=35
sharpen|all|=0.8
unsharp|all|=radius=3:intensity=1.0
posterize|all|=4
pixelate|all|=25
edges|all|=2.5
edge-work|all|=3
emboss|all|
crystallize|all|=30
pointillize|all|=15
comic|all|
noise|all|=0.3
vignette|composite-only|=2:1
vignette-effect|composite-only|=center=0.5,0.5:radius=1.2:intensity=1.5
bloom|composite-only|=1.0:18
gloom|composite-only|=1.0:18
outline|fg-only|=color=#ffaa00:width=8
glow|fg-only|=color=#ffff80:radius=25:intensity=0.8
shadow|fg-only|=blur=14:offset=6,6:opacity=0.6:color=#000
inner-shadow|fg-only|=blur=10:offset=2,2:opacity=0.7:color=#000
silhouette|fg-only|=color=#005577
cutout|fg-only|
matte|fg-only|
scale|fg-only|=0.7
translate|fg-only|=120,-60
rotate|fg-only|=15
flip|fg-only|=horizontal
feather|mask-only|=24
threshold|mask-only|=0.5
expand|mask-only|=14
contract|mask-only|=14
EOF
)

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
