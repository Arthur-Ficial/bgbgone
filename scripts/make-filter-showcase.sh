#!/bin/bash
# Regenerate docs/images/showcase/* and docs/images/filters/* against the
# freshly-installed bgbgone binary. The README Filter Showcase section and
# every per-filter doc reference these assets.
#
# CC0 / Franz CC-BY only - subjects in Tests/fixtures/showcase/, backgrounds in
# Tests/fixtures/showcase/bg/. Sidecar JSONs travel with every fixture.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$ROOT/.build/release/bgbgone}"
FIX="$ROOT/Tests/fixtures/showcase"
OUT="$ROOT/docs/images/showcase"
FILT_OUT="$ROOT/docs/images/filters"

mkdir -p "$OUT" "$FILT_OUT"

# Pretty stderr (no buffering surprises in the README image-make report).
echo "regenerating filter showcase via $BIN"
"$BIN" --version

# ============ 5 README showcase examples ============
echo "-- showcase 1: colour-pop (bg:grayscale on Welsh Corgi) --"
"$BIN" "$FIX/Fawn_and_white_Welsh_Corgi_puppy_standing_on_rear_legs_and_sticking_out_the_tongue.jpg" \
  --bg color:white -o "$OUT/01-corgi-before.jpg" >/dev/null
"$BIN" "$FIX/Fawn_and_white_Welsh_Corgi_puppy_standing_on_rear_legs_and_sticking_out_the_tongue.jpg" \
  --bg color:white --filter "bg:grayscale" -o "$OUT/01-corgi-colourpop.jpg" >/dev/null

echo "-- showcase 2: portrait mode (bg:blur=20 on yoga) --"
"$BIN" "$FIX/franz-yoga.jpg" \
  --bg color:white -o "$OUT/02-yoga-before.jpg" >/dev/null
"$BIN" "$FIX/franz-yoga.jpg" \
  --bg color:white --filter "bg:blur=20" -o "$OUT/02-yoga-portraitmode.jpg" >/dev/null

echo "-- showcase 3: sticker (fg:outline + shadow on corgi, transparent bg) --"
"$BIN" "$FIX/Fawn_and_white_Welsh_Corgi_puppy_standing_on_rear_legs_and_sticking_out_the_tongue.jpg" \
  -o "$OUT/03-corgi-cutout.png" >/dev/null
"$BIN" "$FIX/Fawn_and_white_Welsh_Corgi_puppy_standing_on_rear_legs_and_sticking_out_the_tongue.jpg" \
  --filter "fg:outline=color=#fff:width=4,shadow=blur=12:offset=4,4:opacity=0.5:color=#000" \
  -o "$OUT/03-corgi-sticker.png" >/dev/null

echo "-- showcase 4: vintage (sepia + vignette on bearded pipe man) --"
"$BIN" "$FIX/Bearded_man_smoking_pipe-3013924.jpg" \
  --bg color:white -o "$OUT/04-pipeman-before.jpg" >/dev/null
"$BIN" "$FIX/Bearded_man_smoking_pipe-3013924.jpg" \
  --bg color:white --filter "sepia=0.7,vignette=1:1.2" \
  -o "$OUT/04-pipeman-vintage.jpg" >/dev/null

echo "-- showcase 5: dramatic composite (yoga on Matterhorn + colour-grade) --"
"$BIN" "$FIX/franz-yoga.jpg" \
  --bg "image:$FIX/bg/Matterhorn_sunset_2016__Unsplash_.jpg" \
  -o "$OUT/05-yoga-matterhorn-before.jpg" >/dev/null
"$BIN" "$FIX/franz-yoga.jpg" \
  --bg "image:$FIX/bg/Matterhorn_sunset_2016__Unsplash_.jpg" \
  --filter "bg:adjust=brightness=-0.15:saturation=0.8; fg:adjust=saturation=1.2" \
  -o "$OUT/05-yoga-matterhorn-graded.jpg" >/dev/null

# ============ One example per filter for docs/filters/<name>.md ============
# Each filter rendered against the same canonical subject (red panda) so the
# per-filter docs all show the same baseline + the filtered output.
CANON="$FIX/Red_Panda__24986761703_.jpg"

run_filter() {
    local name="$1" chain="$2"
    "$BIN" "$CANON" --bg color:white --filter "$chain" -o "$FILT_OUT/${name}.jpg" >/dev/null 2>&1 \
        && echo "  ok  $name" \
        || echo "  SKIP $name (filter not applicable on canonical fixture)"
}

echo ""
echo "-- per-filter doc assets --"
"$BIN" "$CANON" --bg color:white -o "$FILT_OUT/_baseline.jpg" >/dev/null
run_filter "grayscale"       "all:grayscale"
run_filter "desaturate"      "all:desaturate=0.7"
run_filter "negate"          "all:negate"
run_filter "sepia"           "all:sepia=0.8"
run_filter "adjust"          "all:adjust=brightness=0.1:contrast=1.2:saturation=0.8"
run_filter "gamma"           "all:gamma=1.8"
run_filter "exposure"        "all:exposure=0.8"
run_filter "hue"             "all:hue=90"
run_filter "tint"            "all:tint=color=#ff00ff:amount=0.5"
run_filter "colorize"        "all:colorize=color=#00bfff:amount=0.9"
run_filter "temperature"     "all:temperature=3500"
run_filter "levels"          "all:levels=black=0.1:white=0.9:gamma=1.2"
run_filter "vibrance"        "all:vibrance=0.8"
run_filter "opacity"         "all:opacity=0.5"
run_filter "duotone"         "all:duotone=dark=#003366:light=#ffcc00"
run_filter "blur"            "all:blur=15"
run_filter "box-blur"        "all:box-blur=10"
run_filter "motion-blur"     "all:motion-blur=radius=15:angle=45"
run_filter "zoom-blur"       "all:zoom-blur=center=0.5,0.5:amount=30"
run_filter "sharpen"         "all:sharpen=0.8"
run_filter "unsharp"         "all:unsharp=radius=3:intensity=1.0"
run_filter "posterize"       "all:posterize=4"
run_filter "pixelate"        "all:pixelate=20"
run_filter "edges"           "all:edges=2.0"
run_filter "edge-work"       "all:edge-work=3"
run_filter "emboss"          "all:emboss"
run_filter "crystallize"     "all:crystallize=30"
run_filter "pointillize"     "all:pointillize=15"
run_filter "comic"           "all:comic"
run_filter "noise"           "all:noise=0.3"
run_filter "vignette"        "all:vignette=2:1"
run_filter "vignette-effect" "all:vignette-effect=center=0.5,0.5:radius=1.5:intensity=1.0"
run_filter "bloom"           "all:bloom=1.0:15"
run_filter "gloom"           "all:gloom=1.0:15"

# fg-only (need their own outputs)
run_filter "outline"      "fg:outline=color=#ffaa00:width=5"
run_filter "glow"         "fg:glow=color=#ffff80:radius=20:intensity=0.7"
run_filter "shadow"       "fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000"
run_filter "inner-shadow" "fg:inner-shadow=blur=8:offset=2,2:opacity=0.6:color=#000"
run_filter "silhouette"   "fg:silhouette=color=#005577"
run_filter "cutout"       "fg:cutout"
run_filter "matte"        "fg:matte"
run_filter "scale"        "fg:scale=0.7"
run_filter "translate"    "fg:translate=80,-40"
run_filter "rotate"       "fg:rotate=15"
run_filter "flip"         "fg:flip=horizontal"

# mask-only
run_filter "feather"   "mask:feather=8"
run_filter "threshold" "mask:threshold=0.5"
run_filter "expand"    "mask:expand=4"
run_filter "contract"  "mask:contract=4"

echo ""
echo "done. \$OUT=$OUT"
echo "done. \$FILT_OUT=$FILT_OUT"
ls -1 "$OUT" | wc -l | awk '{print "  showcase assets: " $1}'
ls -1 "$FILT_OUT" | wc -l | awk '{print "  per-filter assets: " $1}'
