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

echo "-- showcase 2: portrait mode (red panda, original bg gets silky blur) --"
"$BIN" "$PANDA" --bg "image:$PANDA" --filter "bg:blur=22" -o "$OUT/02-panda-portraitmode.jpg" >/dev/null

echo "-- showcase 3: sticker (corgi cutout vs corgi outline+shadow) --"
"$BIN" "$CORGI" -o "$OUT/03-corgi-cutout.png" >/dev/null
"$BIN" "$CORGI" \
  --filter "fg:outline=color=#fff:width=6,shadow=blur=14:offset=6,6:opacity=0.55:color=#000" \
  -o "$OUT/03-corgi-sticker.png" >/dev/null

echo "-- showcase 4: vintage (pipe-man, sepia+vignette on original bg) --"
cp "$PIPEMAN" "$OUT/04-pipeman-before.jpg"
"$BIN" "$PIPEMAN" --bg "image:$PIPEMAN" --filter "sepia=0.85,vignette=1.5:1.2" -o "$OUT/04-pipeman-vintage.jpg" >/dev/null

echo "-- showcase 5: dramatic composite (yoga on Matterhorn, fg+bg colour-graded) --"
"$BIN" "$YOGA" --bg "image:$MATTERHORN" -o "$OUT/05-yoga-matterhorn-before.jpg" >/dev/null
"$BIN" "$YOGA" --bg "image:$MATTERHORN" \
  --filter "bg:adjust=brightness=-0.18:saturation=0.7; fg:adjust=saturation=1.25:brightness=0.05" \
  -o "$OUT/05-yoga-matterhorn-graded.jpg" >/dev/null

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
run_filter "cutout"          "fg:cutout"
run_filter "matte"           "fg:matte"
run_filter "scale"           "fg:scale=0.7"
run_filter "translate"       "fg:translate=120,-60"
run_filter "rotate"          "fg:rotate=15"
run_filter "flip"            "fg:flip=horizontal"
run_filter "feather"         "mask:feather=8"
run_filter "threshold"       "mask:threshold=0.5"
run_filter "expand"          "mask:expand=4"
run_filter "contract"        "mask:contract=4"

echo ""
echo "done."
ls -1 "$OUT" | wc -l | awk '{print "  showcase assets: " $1}'
ls -1 "$FILT_OUT" | wc -l | awk '{print "  per-filter assets: " $1}'
