#!/usr/bin/env bash
# Build the showcase strips embedded in README.md.
#
# Strategy: bgbgone produces cutouts / replacements, ImageMagick composes
# them into labeled grids that show source + intermediate + final for
# every use case. All inputs are strict-PD Wikimedia fixtures.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FX="$ROOT/Tests/fixtures"
OUT="$ROOT/docs/images"
WORK="$(mktemp -d -t bgbgone-readme.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

# Pin to the freshly-built release binary if one exists, otherwise fall back to
# `bgbgone` on PATH. Required because `bgbgone` on PATH can resolve to an older
# installed binary (e.g. /opt/homebrew/bin/bgbgone), which silently makes the
# README assets reflect the wrong release.
if [ -x "$ROOT/.build/release/bgbgone" ]; then
    BGBGONE="$ROOT/.build/release/bgbgone"
elif [ -x "/usr/local/bin/bgbgone" ]; then
    BGBGONE="/usr/local/bin/bgbgone"
else
    BGBGONE="$(command -v bgbgone)"
fi
echo "make-readme-examples: using $BGBGONE ($("$BGBGONE" --version 2>/dev/null || echo unknown))"

# macOS fonts (ImageMagick can't auto-discover them on macOS without a font-cache).
FONT_SANS="/System/Library/Fonts/HelveticaNeue.ttc"
FONT_BOLD="/System/Library/Fonts/Helvetica.ttc"

mkdir -p "$OUT" "$WORK/panels"

# ---- helpers ----------------------------------------------------------------

# Render a panel: image (resized + checkerboard for transparency) + caption strip.
# usage: panel <src-image> <label> <out-path> [panel-width] [panel-height]
# Build the checkerboard tile once, as a PNG24 (sRGB true-colour) so that any
# composite inherits an RGB colourspace. pattern:checkerboard is grayscale by
# default and ImageMagick's auto-detection downcasts gray-only composites to
# grayscale, which silently kills the colour in every example. PNG24: defeats
# that auto-detection.
CB_TILE="$WORK/cb-tile.png"
{
    magick \( -size 20x20 xc:'#cccccc' \) \( -size 20x20 xc:'#aaaaaa' \) +append "$WORK/r1.png"
    magick \( -size 20x20 xc:'#aaaaaa' \) \( -size 20x20 xc:'#cccccc' \) +append "$WORK/r2.png"
    magick "$WORK/r1.png" "$WORK/r2.png" -append "$CB_TILE"
}

panel() {
    local src="$1" label="$2" dst="$3"
    local pw="${4:-420}" ph="${5:-360}"
    local ih=$((ph - 56))   # leave 56px for caption

    magick "$CB_TILE" -write mpr:cb +delete \
        -size "${pw}x${ih}" tile:mpr:cb \
        PNG24:"$WORK/cb.png"

    magick "$src" -resize "${pw}x${ih}" -background none -gravity center \
        -extent "${pw}x${ih}" PNG32:"$WORK/fit.png"

    magick PNG24:"$WORK/cb.png" PNG32:"$WORK/fit.png" -composite \
        PNG24:"$WORK/img.png"

    magick -size "${pw}x56" canvas:white \
        -gravity center -pointsize 18 -font "$FONT_SANS" \
        -fill '#222' -annotate +0+0 "$label" \
        PNG24:"$WORK/cap.png"

    magick PNG24:"$WORK/img.png" PNG24:"$WORK/cap.png" -append PNG24:"$dst"
}

# Concatenate panels into one row, optionally with a top title bar.
row() {
    local out="$1"; shift
    local title="$1"; shift
    if [ -n "$title" ]; then
        local total_w=0
        for p in "$@"; do
            w=$(magick identify -format "%w" "$p")
            total_w=$((total_w + w))
        done
        magick -size "${total_w}x44" canvas:'#101820' \
            -gravity center -pointsize 20 -font "$FONT_BOLD" \
            -fill white -annotate +0+0 "$title" PNG24:"$WORK/title.png"
        magick "$@" +append "$WORK/row.png"
        magick "$WORK/title.png" "$WORK/row.png" -append "$out"
    else
        magick "$@" +append "$out"
    fi
}

# Stack rows vertically.
stack() {
    local out="$1"; shift
    magick "$@" -append "$out"
}

# Shorthand to bgbgone a source with extra flags into a temp file.
bg() {
    local src="$1" tag="$2"; shift 2
    local dst="$WORK/$(basename "$src" .jpg)-$tag.png"
    "$BGBGONE" "$src" "$@" -o "$dst" --quiet
    echo "$dst"
}

# ---- 1) Cutout grid: all 12 PD fixtures, source → transparent ---------------

echo "==> cutout-grid (12 source → cutout pairs)"
i=0
for f in "$FX"/[0-9][0-9]-*.jpg; do
    base=$(basename "$f" .jpg)
    label_src=$(echo "$base" | sed -E 's/^[0-9]+-//; s/-/ /g')
    cut="$WORK/$base-cut.png"
    "$BGBGONE" "$f" -o "$cut" --quiet
    panel "$f"  "src · $label_src"  "$WORK/panels/grid-$i-a.png" 360 300
    panel "$cut" "cutout"           "$WORK/panels/grid-$i-b.png" 360 300
    i=$((i + 1))
done

# 4 columns of (src, cutout) pairs = 8 cells per row. Rows scale with fixture count.
rowtmp=()
n=0
for f in "$FX"/[0-9][0-9]-*.jpg; do
    rowtmp+=("$WORK/panels/grid-$n-a.png" "$WORK/panels/grid-$n-b.png")
    n=$((n + 1))
done
total_panels=${#rowtmp[@]}
panels_per_row=8
num_rows=$(( (total_panels + panels_per_row - 1) / panels_per_row ))
row_files=()
for r in $(seq 0 $((num_rows - 1))); do
    s=$((r * panels_per_row))
    args=()
    for k in $(seq 0 $((panels_per_row - 1))); do
        idx=$((s + k))
        if [ $idx -lt $total_panels ]; then
            args+=("${rowtmp[$idx]}")
        fi
    done
    row "$WORK/cutout-row-$r.png" "" "${args[@]}"
    row_files+=("$WORK/cutout-row-$r.png")
done
num_subjects=$((total_panels / 2))
magick -size "$(magick identify -format '%w' "${row_files[0]}")x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "bgbgone in.jpg > out.png — works across $num_subjects different subjects, zero config" \
    "$WORK/cutout-title.png"
stack "$OUT/showcase-cutouts.png" "$WORK/cutout-title.png" "${row_files[@]}"
echo "    -> $OUT/showcase-cutouts.png ($num_subjects subjects)"

# ---- 2) Color backgrounds: same subjects, many colors ----------------------

echo "==> color-backgrounds"
mkdir -p "$WORK/colors"

color_strip() {
    # color_strip <fixture> <out>
    local src="$1" out="$2"
    local base=$(basename "$src" .jpg)
    panel "$src" "src" "$WORK/colors/$base-src.png" 320 320

    "$BGBGONE" "$src" --bg color:white -o "$WORK/colors/$base-white.png" --quiet
    panel "$WORK/colors/$base-white.png" "--bg color:white" \
          "$WORK/colors/$base-white-p.png" 320 320

    "$BGBGONE" "$src" --bg color:black -o "$WORK/colors/$base-black.png" --quiet
    panel "$WORK/colors/$base-black.png" "--bg color:black" \
          "$WORK/colors/$base-black-p.png" 320 320

    "$BGBGONE" "$src" --bg color:#0066cc -o "$WORK/colors/$base-brand.png" --quiet
    panel "$WORK/colors/$base-brand.png" "--bg color:#0066cc" \
          "$WORK/colors/$base-brand-p.png" 320 320

    "$BGBGONE" "$src" --bg color:rgb:0,200,0 -o "$WORK/colors/$base-green.png" --quiet
    panel "$WORK/colors/$base-green.png" "--bg color:rgb:0,200,0" \
          "$WORK/colors/$base-green-p.png" 320 320

    row "$out" "" \
        "$WORK/colors/$base-src.png" \
        "$WORK/colors/$base-white-p.png" \
        "$WORK/colors/$base-black-p.png" \
        "$WORK/colors/$base-brand-p.png" \
        "$WORK/colors/$base-green-p.png"
}

color_strip "$FX/07-einstein-1921.jpg" "$WORK/colors/row-einstein.png"
color_strip "$FX/08-tesla-sarony.jpg"  "$WORK/colors/row-tesla.png"
color_strip "$FX/02-nasa-mccandless-eva.jpg" "$WORK/colors/row-eva.png"

magick -size "$(magick identify -format '%w' "$WORK/colors/row-einstein.png")x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "--bg color:<#hex | named | rgb:r,g,b> — one flag, any colour, three subjects" \
    "$WORK/colors/title.png"
stack "$OUT/showcase-colors.png" \
    "$WORK/colors/title.png" \
    "$WORK/colors/row-einstein.png" \
    "$WORK/colors/row-tesla.png" \
    "$WORK/colors/row-eva.png"
echo "    -> $OUT/showcase-colors.png"

# ---- 3) Image backgrounds: cover/contain/tile/center ------------------------

echo "==> image-backgrounds (fit modes)"
mkdir -p "$WORK/imgbg"

# Use NASA Earthrise as the "image background", Einstein as subject.
BG_BEACH="$FX/03-nasa-earthrise.jpg"     # used as bg
BG_NEBULA="$FX/04-nasa-hubble-ngc1300.jpg"
BG_WAVE="$FX/11-great-wave-hokusai.jpg"

# fit mode comparison (single subject + single bg)
SUB="$FX/07-einstein-1921.jpg"
panel "$SUB" "src" "$WORK/imgbg/0-src.png" 360 320
panel "$BG_BEACH" "bg image" "$WORK/imgbg/0-bg.png" 360 320

for mode in cover contain tile center; do
    "$BGBGONE" "$SUB" --bg "image:$BG_BEACH" --bg-fit "$mode" \
        -o "$WORK/imgbg/einstein-$mode.png" --quiet
    panel "$WORK/imgbg/einstein-$mode.png" "--bg-fit $mode" \
          "$WORK/imgbg/einstein-$mode-p.png" 360 320
done

row "$WORK/imgbg/row1.png" "" \
    "$WORK/imgbg/0-src.png" \
    "$WORK/imgbg/0-bg.png" \
    "$WORK/imgbg/einstein-cover-p.png" \
    "$WORK/imgbg/einstein-contain-p.png" \
    "$WORK/imgbg/einstein-tile-p.png" \
    "$WORK/imgbg/einstein-center-p.png"

# Subject variation: same subject on three different bg images
SUB2="$FX/02-nasa-mccandless-eva.jpg"
panel "$SUB2" "src" "$WORK/imgbg/2-src.png" 360 320

"$BGBGONE" "$SUB2" --bg "image:$BG_NEBULA" -o "$WORK/imgbg/eva-nebula.png" --quiet
panel "$BG_NEBULA" "bg: hubble nebula" "$WORK/imgbg/2-bg-a.png" 360 320
panel "$WORK/imgbg/eva-nebula.png" "result" "$WORK/imgbg/eva-nebula-p.png" 360 320

"$BGBGONE" "$SUB2" --bg "image:$BG_WAVE" -o "$WORK/imgbg/eva-wave.png" --quiet
panel "$BG_WAVE" "bg: hokusai wave" "$WORK/imgbg/2-bg-b.png" 360 320
panel "$WORK/imgbg/eva-wave.png" "result" "$WORK/imgbg/eva-wave-p.png" 360 320

row "$WORK/imgbg/row2.png" "" \
    "$WORK/imgbg/2-src.png" \
    "$WORK/imgbg/2-bg-a.png" \
    "$WORK/imgbg/eva-nebula-p.png" \
    "$WORK/imgbg/2-bg-b.png" \
    "$WORK/imgbg/eva-wave-p.png"

# Pad the row to match width of row1
W1=$(magick identify -format '%w' "$WORK/imgbg/row1.png")
W2=$(magick identify -format '%w' "$WORK/imgbg/row2.png")
if [ "$W2" -lt "$W1" ]; then
    magick "$WORK/imgbg/row2.png" -background '#101820' -gravity center -extent "${W1}x" "$WORK/imgbg/row2.png"
fi

magick -size "${W1}x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "--bg image:<path>  •  --bg-fit cover|contain|tile|center" \
    "$WORK/imgbg/title.png"

stack "$OUT/showcase-image-bg.png" \
    "$WORK/imgbg/title.png" \
    "$WORK/imgbg/row1.png" \
    "$WORK/imgbg/row2.png"
echo "    -> $OUT/showcase-image-bg.png"

# ---- 5) Edge refinement: feather progression, crop, padding, shadow --------

echo "==> edge-refinement"
mkdir -p "$WORK/edge"

ESUB="$FX/07-einstein-1921.jpg"

# Feather progression on white bg so edges are visible.
for fpx in 0 1 4 8 16; do
    "$BGBGONE" "$ESUB" --bg color:white --feather "$fpx" \
        -o "$WORK/edge/feather-$fpx.png" --quiet
    panel "$WORK/edge/feather-$fpx.png" "--feather $fpx" \
          "$WORK/edge/feather-$fpx-p.png" 320 320
done

row "$WORK/edge/row-feather.png" "" \
    "$WORK/edge/feather-0-p.png" \
    "$WORK/edge/feather-1-p.png" \
    "$WORK/edge/feather-4-p.png" \
    "$WORK/edge/feather-8-p.png" \
    "$WORK/edge/feather-16-p.png"

# crop / padding / shadow / mask-only
panel "$ESUB" "src" "$WORK/edge/src.png" 320 320

"$BGBGONE" "$ESUB" --crop -o "$WORK/edge/crop.png" --quiet
panel "$WORK/edge/crop.png" "--crop" "$WORK/edge/crop-p.png" 320 320

"$BGBGONE" "$ESUB" --crop --padding 10% -o "$WORK/edge/pad.png" --quiet
panel "$WORK/edge/pad.png" "--crop --padding 10%" "$WORK/edge/pad-p.png" 320 320

"$BGBGONE" "$ESUB" --bg color:white --shadow -o "$WORK/edge/shadow.png" --quiet
panel "$WORK/edge/shadow.png" "--bg color:white --shadow" "$WORK/edge/shadow-p.png" 320 320

"$BGBGONE" "$ESUB" --mask-only -o "$WORK/edge/mask.png" --quiet
panel "$WORK/edge/mask.png" "--mask-only (alpha matte)" "$WORK/edge/mask-p.png" 320 320

row "$WORK/edge/row-misc.png" "" \
    "$WORK/edge/src.png" \
    "$WORK/edge/crop-p.png" \
    "$WORK/edge/pad-p.png" \
    "$WORK/edge/shadow-p.png" \
    "$WORK/edge/mask-p.png"

W=$(magick identify -format '%w' "$WORK/edge/row-feather.png")
magick -size "${W}x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "--feather progression (0 → 16 px)" \
    "$WORK/edge/t1.png"
magick -size "${W}x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "--crop  ·  --padding  ·  --shadow  ·  --mask-only" \
    "$WORK/edge/t2.png"

stack "$OUT/showcase-edges.png" \
    "$WORK/edge/t1.png" \
    "$WORK/edge/row-feather.png" \
    "$WORK/edge/t2.png" \
    "$WORK/edge/row-misc.png"
echo "    -> $OUT/showcase-edges.png"

# Close-up around a foreground edge: feather must soften alpha only, not blur RGB.
ZOOM_SUB="$FX/02-nasa-mccandless-eva.jpg"
"$BGBGONE" "$ZOOM_SUB" --feather 0 -o "$WORK/edge/zoom-f0.png" --quiet
"$BGBGONE" "$ZOOM_SUB" --feather 8 -o "$WORK/edge/zoom-f8.png" --quiet

zoom_panel() {
    local src="$1" label="$2" dst="$3"
    local crop="${4:-360x360+710+265}"

    magick "$CB_TILE" -write mpr:cb +delete \
        -size 360x360 tile:mpr:cb PNG24:"$WORK/edge/zoom-cb.png"
    magick "$src" -crop "$crop" +repage -resize 360x360! \
        -background none -gravity center -extent 360x360 PNG32:"$WORK/edge/zoom-cut.png"
    magick PNG24:"$WORK/edge/zoom-cb.png" PNG32:"$WORK/edge/zoom-cut.png" \
        -composite PNG24:"$WORK/edge/zoom-img.png"
    magick -size 360x56 canvas:white \
        -gravity center -pointsize 18 -font "$FONT_SANS" -fill '#222' \
        -annotate +0+0 "$label" PNG24:"$WORK/edge/zoom-cap.png"
    magick PNG24:"$WORK/edge/zoom-img.png" PNG24:"$WORK/edge/zoom-cap.png" \
        -append PNG24:"$dst"
}

zoom_panel "$WORK/edge/zoom-f0.png" "--feather 0 (hard edge)" "$WORK/edge/zoom-f0-p.png"
zoom_panel "$WORK/edge/zoom-f8.png" "--feather 8 (soft matte)" "$WORK/edge/zoom-f8-p.png"
row "$WORK/edge/feather-zoom-row.png" "Edge refinement — --feather close-up around the subject outline" \
    "$WORK/edge/zoom-f0-p.png" \
    "$WORK/edge/zoom-f8-p.png"
cp "$WORK/edge/feather-zoom-row.png" "$OUT/feather-zoom.png"
echo "    -> $OUT/feather-zoom.png"

# Mask breakdown: source → alpha matte → final transparent cutout.
MB_SUB="$FX/02-nasa-mccandless-eva.jpg"
"$BGBGONE" "$MB_SUB" --mask-only -o "$WORK/edge/mb-mask.png" --quiet
"$BGBGONE" "$MB_SUB" -o "$WORK/edge/mb-cutout.png" --quiet
panel "$MB_SUB" "src" "$WORK/edge/mb-src-p.png" 360 320
panel "$WORK/edge/mb-mask.png" "--mask-only" "$WORK/edge/mb-mask-p.png" 360 320
panel "$WORK/edge/mb-cutout.png" "cutout" "$WORK/edge/mb-cutout-p.png" 360 320
row "$WORK/edge/mask-breakdown-row.png" "input → grayscale matte → transparent cutout" \
    "$WORK/edge/mb-src-p.png" \
    "$WORK/edge/mb-mask-p.png" \
    "$WORK/edge/mb-cutout-p.png"
cp "$WORK/edge/mask-breakdown-row.png" "$OUT/mask-breakdown.png"
echo "    -> $OUT/mask-breakdown.png"

# ---- 6) Algorithm comparison ------------------------------------------------

echo "==> algorithm-comparison"
mkdir -p "$WORK/algo"

algo_row() {
    # algo_row <fixture> <out>
    # Subjects chosen to make algorithms visibly diverge: Mars selfie has a rover,
    # an orange sky and a rocky ground; Wright Brothers has two people on grass;
    # Mona Lisa has a painted figure with no real-world sky.
    local src="$1" out="$2"
    local base=$(basename "$src" .jpg)
    panel "$src" "src" "$WORK/algo/$base-src.png" 320 320
    for a in vn-mask person saliency; do
        "$BGBGONE" "$src" --algo "$a" -o "$WORK/algo/$base-$a.png" --quiet
        panel "$WORK/algo/$base-$a.png" "--algo $a" \
              "$WORK/algo/$base-$a-p.png" 320 320
    done
    row "$out" "" \
        "$WORK/algo/$base-src.png" \
        "$WORK/algo/$base-vn-mask-p.png" \
        "$WORK/algo/$base-person-p.png" \
        "$WORK/algo/$base-saliency-p.png"
}

algo_row "$FX/06-nasa-mars-curiosity-selfie.jpg" "$WORK/algo/row-mars.png"
algo_row "$FX/09-wright-brothers-1910.jpg"       "$WORK/algo/row-wright.png"
algo_row "$FX/10-mona-lisa.jpg"                  "$WORK/algo/row-mona.png"

W=$(magick identify -format '%w' "$WORK/algo/row-mars.png")
magick -size "${W}x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "--algo: rover · two people · painted figure (every supported algorithm side by side)" \
    PNG24:"$WORK/algo/title.png"
stack "$OUT/showcase-algos.png" \
    "$WORK/algo/title.png" \
    "$WORK/algo/row-mars.png" \
    "$WORK/algo/row-wright.png" \
    "$WORK/algo/row-mona.png"
echo "    -> $OUT/showcase-algos.png"

# ---- 7) Mona Lisa world tour (using only documented PD fixtures) -----------

echo "==> mona-lisa-tour (PD-only backgrounds)"
mkdir -p "$WORK/ml"

ML="$FX/10-mona-lisa.jpg"

panel "$ML" "src · mona lisa (da vinci, c.1503)" "$WORK/ml/src.png" 360 320

"$BGBGONE" "$ML" --bg color:white -o "$WORK/ml/white.png" --quiet
panel "$WORK/ml/white.png" "--bg color:white" "$WORK/ml/p1.png" 360 320

"$BGBGONE" "$ML" --bg color:black -o "$WORK/ml/black.png" --quiet
panel "$WORK/ml/black.png" "--bg color:black" "$WORK/ml/p2.png" 360 320

# Real PD bg images, each labelled with source fixture so claims are verifiable.
"$BGBGONE" "$ML" --bg "image:$FX/04-nasa-hubble-ngc1300.jpg" \
    -o "$WORK/ml/galaxy.png" --quiet
panel "$WORK/ml/galaxy.png" "--bg image:hubble-ngc1300 (NASA, PD)" "$WORK/ml/p3.png" 360 320

"$BGBGONE" "$ML" --bg "image:$FX/01-nasa-aldrin-moon.jpg" \
    -o "$WORK/ml/moon.png" --quiet
panel "$WORK/ml/moon.png" "--bg image:aldrin-moon (NASA, PD)" "$WORK/ml/p4.png" 360 320

"$BGBGONE" "$ML" --bg "image:$FX/11-great-wave-hokusai.jpg" \
    -o "$WORK/ml/wave.png" --quiet
panel "$WORK/ml/wave.png" "--bg image:great-wave (Hokusai, PD-old)" "$WORK/ml/p5.png" 360 320

"$BGBGONE" "$ML" --bg "image:$FX/06-nasa-mars-curiosity-selfie.jpg" \
    -o "$WORK/ml/mars.png" --quiet
panel "$WORK/ml/mars.png" "--bg image:mars-curiosity (NASA, PD)" "$WORK/ml/p6.png" 360 320

# Three rows × four columns. Seven distinct backgrounds (src + colour:white +
# colour:black + four PD image:<path> backgrounds), 12 panels total — DRY,
# no filler, no caveat panels.
panel "$ML" "src · mona lisa (da vinci, c.1503)"      "$WORK/ml/src2.png" 360 320
panel "$WORK/ml/white.png" "--bg color:white"          "$WORK/ml/p1b.png" 360 320

row "$WORK/ml/row1.png" "" "$WORK/ml/src.png"  "$WORK/ml/p1.png" "$WORK/ml/p2.png" "$WORK/ml/p3.png"
row "$WORK/ml/row2.png" "" "$WORK/ml/p4.png"   "$WORK/ml/p5.png" "$WORK/ml/p6.png" "$WORK/ml/src2.png"

W=$(magick identify -format '%w' "$WORK/ml/row1.png")
magick -size "${W}x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "Mona Lisa — six PD backgrounds, one CLI call each" \
    PNG24:"$WORK/ml/title.png"
stack "$OUT/mona-lisa-tour.png" "$WORK/ml/title.png" "$WORK/ml/row1.png" "$WORK/ml/row2.png"
echo "    -> $OUT/mona-lisa-tour.png"

# ---- 8) Pipeline composition: bgbgone + auge -------------------------------
# Uses the REAL output of `auge --classify` on the cutout — no fabricated labels.

echo "==> pipeline (real auge classify output)"
mkdir -p "$WORK/pipe"
PSRC="$FX/06-nasa-mars-curiosity-selfie.jpg"
"$BGBGONE" "$PSRC" -o "$WORK/pipe/cut.png" --quiet
"$BGBGONE" "$PSRC" --bg color:black --to jpg -o "$WORK/pipe/black.jpg" --quiet
panel "$PSRC" "1. src · curiosity selfie" "$WORK/pipe/p1.png" 360 320
panel "$WORK/pipe/cut.png" "2. bgbgone (cutout)" "$WORK/pipe/p2.png" 360 320
panel "$WORK/pipe/black.jpg" "3. bgbgone --bg color:black --to jpg" "$WORK/pipe/p3.png" 360 320

# Capture real auge output on the cutout (not fabricated).
AUGE_OUT=$(auge --classify "$WORK/pipe/black.jpg" --top 5 2>/dev/null || echo "auge not installed")
# Format as annotation text (multi-line). Pad first line as command.
AUGE_TEXT="\$ auge --classify cut.jpg --top 5

$AUGE_OUT"
magick -size 360x304 canvas:'#0d1f3a' \
    -gravity northwest -pointsize 16 -font "$FONT_SANS" -fill '#e0e7ff' \
    -annotate +18+20 "$AUGE_TEXT" \
    "$WORK/pipe/p4-img.png"
magick -size 360x56 canvas:white \
    -gravity center -pointsize 18 -font "$FONT_SANS" -fill '#222' \
    -annotate +0+0 "4. real auge --classify output" "$WORK/pipe/p4-cap.png"
magick "$WORK/pipe/p4-img.png" "$WORK/pipe/p4-cap.png" -append "$WORK/pipe/p4.png"

row "$WORK/pipe/row.png" "" \
    "$WORK/pipe/p1.png" "$WORK/pipe/p2.png" "$WORK/pipe/p3.png" "$WORK/pipe/p4.png"

W=$(magick identify -format '%w' "$WORK/pipe/row.png")
magick -size "${W}x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "pipeline · bgbgone → auge: cleaner cutouts make downstream AI more accurate" \
    "$WORK/pipe/title.png"
stack "$OUT/showcase-pipeline.png" "$WORK/pipe/title.png" "$WORK/pipe/row.png"
echo "    -> $OUT/showcase-pipeline.png"

# ---- 9) Products: vintage PD ads → cutout → hilarious new context ----------
# For each product fixture: src → --mask-only (alpha matte) → cutout → recomposed
# onto a wildly out-of-context PD background. All steps are real bgbgone calls.

echo "==> products (with --mask-only and absurd new contexts)"
mkdir -p "$WORK/prod"

# product_row <fixture> <new-context-fixture> <caption-for-new-context> <out-row>
product_row() {
    local src="$1" bgfx="$2" newcap="$3" out="$4"
    local base=$(basename "$src" .jpg)

    panel "$src" "src · $base" "$WORK/prod/$base-src.png" 320 360

    "$BGBGONE" "$src" --mask-only -o "$WORK/prod/$base-mask.png" --quiet
    panel "$WORK/prod/$base-mask.png" "--mask-only (alpha matte)" "$WORK/prod/$base-mask-p.png" 320 360

    "$BGBGONE" "$src" -o "$WORK/prod/$base-cut.png" --quiet
    panel "$WORK/prod/$base-cut.png" "cutout (transparent)" "$WORK/prod/$base-cut-p.png" 320 360

    "$BGBGONE" "$src" --bg "image:$bgfx" -o "$WORK/prod/$base-new.png" --quiet
    panel "$WORK/prod/$base-new.png" "$newcap" "$WORK/prod/$base-new-p.png" 320 360

    row "$out" "" \
        "$WORK/prod/$base-src.png" \
        "$WORK/prod/$base-mask-p.png" \
        "$WORK/prod/$base-cut-p.png" \
        "$WORK/prod/$base-new-p.png"
}

product_row "$FX/16-pierce-arrow-1909.jpg" \
            "$FX/01-nasa-aldrin-moon.jpg" \
            "--bg image:lunar surface" \
            "$WORK/prod/row-car.png"

product_row "$FX/14-underwood-1909.jpg" \
            "$FX/03-nasa-earthrise.jpg" \
            "--bg image:earthrise" \
            "$WORK/prod/row-typewriter.png"

product_row "$FX/15-edison-phonograph.jpg" \
            "$FX/04-nasa-hubble-ngc1300.jpg" \
            "--bg image:hubble-ngc1300" \
            "$WORK/prod/row-edison.png"

product_row "$FX/13-singer-1892.jpg" \
            "$FX/11-great-wave-hokusai.jpg" \
            "--bg image:great-wave" \
            "$WORK/prod/row-singer.png"

W=$(magick identify -format '%w' "$WORK/prod/row-typewriter.png")
magick -size "${W}x52" canvas:'#101820' \
    -gravity center -pointsize 22 -font "$FONT_BOLD" -fill white \
    -annotate +0+0 "Products — src · --mask-only · cutout · composed onto a new background" \
    PNG24:"$WORK/prod/title.png"
stack "$OUT/showcase-products.png" \
    "$WORK/prod/title.png" \
    "$WORK/prod/row-car.png" \
    "$WORK/prod/row-typewriter.png" \
    "$WORK/prod/row-edison.png" \
    "$WORK/prod/row-singer.png"
echo "    -> $OUT/showcase-products.png"

echo
echo "All showcase strips written to $OUT/"
ls -lh "$OUT/" | tail -20
