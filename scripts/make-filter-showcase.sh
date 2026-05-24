#!/bin/bash
# Regenerate docs/images/showcase/* and docs/images/filters/* against the
# freshly-installed bgbgone binary. The README Filter Showcase section and
# every per-filter doc reference these assets.
#
# CC0 / Franz CC-BY only - subjects in Tests/fixtures/showcase/, backgrounds
# in Tests/fixtures/showcase/bg/. Sidecar JSONs travel with every fixture.
#
# Classic colour-pop trick: use the source photo as BOTH the subject and the
# background plate (--bg image:<self>). Then bg:grayscale turns the original
# background black-and-white while the subject keeps its colour. This is the
# whole point of having per-layer filters.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$ROOT/.build/release/bgbgone}"
FIX="$ROOT/Tests/fixtures/showcase"
BG="$FIX/bg"
OUT="$ROOT/docs/images/showcase"
FILT_OUT="$ROOT/docs/images/filters"

mkdir -p "$OUT" "$FILT_OUT"

echo "regenerating filter showcase via $BIN"
"$BIN" --version

CORGI="$FIX/Fawn_and_white_Welsh_Corgi_puppy_standing_on_rear_legs_and_sticking_out_the_tongue.jpg"
PANDA="$FIX/Red_Panda__24986761703_.jpg"
YOGA="$FIX/franz-yoga.jpg"
PIPEMAN="$FIX/Bearded_man_smoking_pipe-3013924.jpg"
CAT="$FIX/Tabby_cat_with_blue_eyes-3336579.jpg"
KINGFISHER="$FIX/Eisvogel_kingfisher.jpg"
PARASTOO="$FIX/Parastoo_Ahmadi.jpg"
MATTERHORN="$BG/Matterhorn_sunset_2016__Unsplash_.jpg"
NEBULA="$BG/Flaming_Star_Nebula__IC_405.png"

# ============ 5 README showcase examples ============
# All before/after pairs use the SOURCE photo as its own background plate so
# the original colourful background is what goes grey / blurry / sepia /
# vignetted. This is the actual colour-pop / portrait-mode effect, not a
# studio cutout pasted onto another background.

echo "-- showcase 1: colour-pop (red panda, original bg goes B&W) --"
cp "$PANDA" "$OUT/01-panda-before.jpg"
"$BIN" "$PANDA" --bg "image:$PANDA" --filter "bg:grayscale" -o "$OUT/01-panda-colourpop.jpg" >/dev/null

echo "-- showcase 2: portrait mode (red panda, original bg gets silky blur=60) --"
"$BIN" "$PANDA" --bg "image:$PANDA" --filter "bg:blur=60" -o "$OUT/02-panda-portraitmode.jpg" >/dev/null

echo "-- showcase 3: real die-cut sticker (mask:expand+feather rounds corners; outline + drop shadow) --"
# HYPOTHESIS: "good sticker border" = (1) expanded mask so the white border
# extends beyond the subject silhouette, (2) Gaussian-feathered mask so
# the contour is rounded (no jagged shape-following), (3) thick white
# outline = the visible sticker paper, (4) soft drop shadow underneath
# = the sticker lifting off the page. Chain order:
#   mask:expand=24,feather=12 → dilate + round the matte
#   fg:shadow=…             → big offset shadow under the rounded shape
#   fg:outline=…            → thick white border around the rounded shape
# Before = the ORIGINAL photo (cp, no processing) so the user sees what
# the source actually looks like.
cp "$CORGI" "$OUT/03-corgi-before.jpg"
"$BIN" "$CORGI" --bg "color:#1a2233" \
  --filter "mask:expand=24,feather=12; fg:shadow=blur=40:offset=22,22:opacity=0.7:color=#000,outline=color=#fff:width=28" \
  -o "$OUT/03-corgi-sticker.jpg" >/dev/null
rm -f "$OUT/03-corgi-cutout.png" "$OUT/03-corgi-sticker.png"

echo "-- showcase 4: vintage backdrop (Parastoo Ahmadi, library bookshelves go sepia; subject keeps colour) --"
# HYPOTHESIS: library bookshelves with warm wooden light have rich detail.
# --algo person isolates Parastoo cleanly. bg gets sepia + slight darken +
# desaturate (old-library backdrop); fg keeps original colour (floral dress,
# red lipstick stay vivid). Vignette darkens corners for classic film look.
cp "$PARASTOO" "$OUT/04-parastoo-before.jpg"
"$BIN" "$PARASTOO" --algo person \
  --filter "bg:sepia=1.0,adjust=brightness=-0.15:saturation=0.45; vignette=1.8:1.1" \
  -o "$OUT/04-parastoo-vintage.jpg" >/dev/null
rm -f "$OUT/04-kingfisher-before.jpg" "$OUT/04-kingfisher-vintage.jpg"

# ============ feather progression panel + close-up (restored from removed --feather docs) ============
echo "-- feather progression: 0 / 8 / 16 / 32 px on the corgi against transparent --"
# HYPOTHESIS: feather=0 -> hard razor edge; 8 -> soft halo; 16 -> noticeably
# fuzzy; 32 -> obvious vignette glow at boundary. Composite 4-up for the
# README Edge refinement section.
mkdir -p "$OUT/feather"
for r in 0 8 16 32; do
    if [ "$r" = "0" ]; then
        "$BIN" "$CORGI" -o "$OUT/feather/corgi-f$r.png" >/dev/null
    else
        "$BIN" "$CORGI" --filter "mask:feather=$r" -o "$OUT/feather/corgi-f$r.png" >/dev/null
    fi
    magick "$OUT/feather/corgi-f$r.png" -resize 400x600 -background "#1a2233" -alpha background -flatten -gravity south -splice 0x40 -gravity south -fill white -pointsize 24 -annotate +0+8 "mask:feather=$r" "$OUT/feather/panel-f$r.jpg"
done
magick "$OUT/feather/panel-f0.jpg" "$OUT/feather/panel-f8.jpg" "$OUT/feather/panel-f16.jpg" "$OUT/feather/panel-f32.jpg" +append "$OUT/feather-progression.jpg"
echo "  ok  feather-progression.jpg"

echo "-- feather close-up: hard edge vs soft matte, 400x300 crop around the ear --"
# HYPOTHESIS: corgi is at ~(1200..2400, 800..3500) in the 3126x4682 source.
# Crop an 800x600 window starting at (1200,800) which captures the ears
# where the matte boundary against the navy plate is most obvious.
magick "$OUT/feather/corgi-f0.png" -background "#1a2233" -alpha background -flatten -crop 800x600+1200+800 +repage "$OUT/feather/zoom-f0.jpg"
magick "$OUT/feather/corgi-f16.png" -background "#1a2233" -alpha background -flatten -crop 800x600+1200+800 +repage "$OUT/feather/zoom-f16.jpg"
magick "$OUT/feather/zoom-f0.jpg" "$OUT/feather/zoom-f16.jpg" +append "$OUT/feather-zoom.jpg"
echo "  ok  feather-zoom.jpg"

echo "-- showcase 5b: yoga with --algo person (isolates the main subject from neighbours) --"
# HYPOTHESIS: the yoga photo has several people on adjacent mats. Default
# vn-mask picks up multiple instances. --algo person uses VNGeneratePerson
# SegmentationRequest which is tuned for human subjects and prefers the
# largest / most prominent person.
cp "$YOGA" "$OUT/05-yoga-before.jpg"
"$BIN" "$YOGA" --algo person --filter "bg:blur=40" -o "$OUT/05-yoga-person-portrait.jpg" >/dev/null
"$BIN" "$YOGA" --algo person --filter "bg:grayscale,adjust=brightness=-0.1" -o "$OUT/05-yoga-person-colourpop.jpg" >/dev/null

# ============ One example per filter for docs/filters/<name>.md ============
# Each filter rendered against the same canonical subject (Red Panda over its
# own original background) so per-filter docs all share a baseline. Original
# colourful background ensures bg:/all: filter effects show through clearly.
echo ""
echo "-- per-filter doc assets (Red Panda on original natural background) --"

CANON_BG_ARGS=(--bg "image:$PANDA")
cp "$PANDA" "$FILT_OUT/_baseline.jpg"
echo "  ok  _baseline (cp of source)"

run_filter() {
    local name="$1" chain="$2"
    "$BIN" "$PANDA" "${CANON_BG_ARGS[@]}" --filter "$chain" -o "$FILT_OUT/${name}.jpg" >/dev/null 2>&1 \
        && echo "  ok  $name" \
        || echo "  SKIP $name"
}

run_filter "grayscale"       "bg:grayscale"
run_filter "desaturate"      "bg:desaturate=0.8"
run_filter "negate"          "bg:negate"
run_filter "sepia"           "all:sepia=0.85"
run_filter "adjust"          "bg:adjust=brightness=-0.1:contrast=1.2:saturation=0.5"
run_filter "gamma"           "bg:gamma=1.8"
run_filter "exposure"        "bg:exposure=0.8"
run_filter "hue"             "bg:hue=90"
run_filter "tint"            "bg:tint=color=#ff00ff:amount=0.5"
run_filter "colorize"        "bg:colorize=color=#00bfff:amount=0.9"
run_filter "temperature"     "bg:temperature=3500"
run_filter "levels"          "bg:levels=black=0.1:white=0.9:gamma=1.2"
run_filter "vibrance"        "all:vibrance=0.8"
run_filter "opacity"         "bg:opacity=0.5"
run_filter "duotone"         "bg:duotone=dark=#003366:light=#ffcc00"
run_filter "blur"            "bg:blur=22"
run_filter "box-blur"        "bg:box-blur=14"
run_filter "motion-blur"     "bg:motion-blur=radius=22:angle=45"
run_filter "zoom-blur"       "bg:zoom-blur=center=0.5,0.5:amount=35"
run_filter "sharpen"         "all:sharpen=0.8"
run_filter "unsharp"         "all:unsharp=radius=3:intensity=1.0"
run_filter "posterize"       "all:posterize=4"
run_filter "pixelate"        "bg:pixelate=25"
run_filter "edges"           "all:edges=2.5"
run_filter "edge-work"       "all:edge-work=3"
run_filter "emboss"          "all:emboss"
run_filter "crystallize"     "bg:crystallize=30"
run_filter "pointillize"     "bg:pointillize=15"
run_filter "comic"           "all:comic"
run_filter "noise"           "all:noise=0.3"
run_filter "vignette"        "all:vignette=2:1"
run_filter "vignette-effect" "all:vignette-effect=center=0.5,0.5:radius=1.2:intensity=1.5"
run_filter "bloom"           "all:bloom=1.0:18"
run_filter "gloom"           "all:gloom=1.0:18"
run_filter "outline"         "fg:outline=color=#ffaa00:width=6"
run_filter "glow"            "fg:glow=color=#ffff80:radius=25:intensity=0.8"
run_filter "shadow"          "fg:shadow=blur=14:offset=6,6:opacity=0.6:color=#000"
run_filter "inner-shadow"    "fg:inner-shadow=blur=10:offset=2,2:opacity=0.7:color=#000"
run_filter "silhouette"      "fg:silhouette=color=#005577"
# cutout/mask-shape filters demoed on a contrast bg (otherwise source==bg
# makes the mask boundary invisible — fg pixel == bg pixel).
"$BIN" "$PANDA" --bg color:#1a2233 --filter "fg:cutout" -o "$FILT_OUT/cutout.jpg" >/dev/null 2>&1 && echo "  ok  cutout (contrast bg)" || echo "  SKIP cutout"
run_filter "matte"           "fg:matte"
run_filter "scale"           "fg:scale=0.7"
run_filter "translate"       "fg:translate=120,-60"
run_filter "rotate"          "fg:rotate=15"
run_filter "flip"            "fg:flip=horizontal"
# mask-shape filters need a contrast bg to show the mask boundary change.
"$BIN" "$PANDA" --bg color:#1a2233 --filter "mask:feather=24" -o "$FILT_OUT/feather.jpg" >/dev/null 2>&1 && echo "  ok  feather (contrast bg)" || echo "  SKIP feather"
"$BIN" "$PANDA" --bg color:#1a2233 --filter "mask:threshold=0.5" -o "$FILT_OUT/threshold.jpg" >/dev/null 2>&1 && echo "  ok  threshold (contrast bg)" || echo "  SKIP threshold"
"$BIN" "$PANDA" --bg color:#1a2233 --filter "mask:expand=14" -o "$FILT_OUT/expand.jpg" >/dev/null 2>&1 && echo "  ok  expand (contrast bg)" || echo "  SKIP expand"
"$BIN" "$PANDA" --bg color:#1a2233 --filter "mask:contract=14" -o "$FILT_OUT/contract.jpg" >/dev/null 2>&1 && echo "  ok  contract (contrast bg)" || echo "  SKIP contract"

echo ""
echo "done."
ls -1 "$OUT" | wc -l | awk '{print "  showcase assets: " $1}'
ls -1 "$FILT_OUT" | wc -l | awk '{print "  per-filter assets: " $1}'
