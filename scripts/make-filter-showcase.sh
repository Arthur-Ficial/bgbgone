#!/bin/bash
# Regenerate docs/images/showcase/* and docs/images/filters/* against the
# freshly-installed bgbgone binary. The README Filter Showcase section and
# every per-filter doc reference these assets.
#
# CC0 / Franz CC-BY only. All subjects + backgrounds live flat in
# Tests/fixtures/. See Tests/fixtures/LICENSES.md for provenance.
#
# Classic colour-pop trick: use the source photo as BOTH the subject and the
# background plate (--bg image:<self>). Then bg:grayscale turns the original
# background black-and-white while the subject keeps its colour. This is the
# whole point of having per-layer filters.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/trash.sh"
BIN="${BIN:-$ROOT/.build/release/bgbgone}"
FIX="$ROOT/Tests/fixtures"
BG="$FIX"
OUT="$ROOT/docs/images/showcase"
FILT_OUT="$ROOT/docs/images/filters"

mkdir -p "$OUT" "$FILT_OUT"

echo "regenerating filter showcase via $BIN"
"$BIN" --version

CORGI="$FIX/corgi-puppy.jpg"
PANDA="$FIX/red-panda.jpg"
YOGA="$FIX/yoga.jpg"
PIPEMAN="$FIX/man-with-pipe.jpg"
CAT="$FIX/tabby-cat.jpg"
KINGFISHER="$FIX/kingfisher.jpg"
WOMAN_SINGER="$FIX/woman-singer.jpg"
MATTERHORN="$BG/matterhorn-sunset.jpg"
NEBULA="$BG/nebula-flaming-star.png"

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

echo "-- showcase 3: die-cut sticker (cropped to cutout, transparent bg, hard white border on checkerboard) --"
# Real die-cut sticker recipe:
#   1. fg:outline=color=#fff:width=30  → hard solid white border, no blur, no halo
#   2. --crop --crop-margin 8%         → tight-crop to subject bbox + 8% breathing room
#   3. NO --bg                          → output is PNG with alpha transparency
# The README then composites the transparent PNG onto a fine checkerboard
# so users see the actual transparency (the sticker sits on a "blank"
# surface, exactly as a printed sticker would on a desk).
cp "$CORGI" "$OUT/03-corgi-before.jpg"

WORK_STICKER=$(mktemp -d -t corgi-sticker.XXXXXX)
# Two-step: (1) cutout + crop produces a transparent PNG of just the subject;
# (2) running outline ON that transparent PNG adds the white border while
# preserving transparency outside the outline. (One-step with `fg:outline`
# alone keeps the original photo background visible outside the outline,
# which is wrong for a die-cut sticker.)
"$BIN" "$CORGI" \
  --crop --crop-margin "8%" \
  -o "$WORK_STICKER/cutout.png" >/dev/null
"$BIN" "$WORK_STICKER/cutout.png" \
  --filter "fg:outline=color=#fff:width=30" \
  -o "$WORK_STICKER/sticker.png" >/dev/null

# Build a fine checkerboard the size of the sticker PNG and composite.
magick \( -size 20x20 xc:'#cccccc' \) \( -size 20x20 xc:'#aaaaaa' \) +append "$WORK_STICKER/r1.png"
magick \( -size 20x20 xc:'#aaaaaa' \) \( -size 20x20 xc:'#cccccc' \) +append "$WORK_STICKER/r2.png"
magick "$WORK_STICKER/r1.png" "$WORK_STICKER/r2.png" -append "$WORK_STICKER/cb-tile.png"

SW=$(magick identify -format '%w' "$WORK_STICKER/sticker.png")
SH=$(magick identify -format '%h' "$WORK_STICKER/sticker.png")
magick "$WORK_STICKER/cb-tile.png" -write mpr:cb +delete \
  -size "${SW}x${SH}" tile:mpr:cb PNG24:"$WORK_STICKER/cb-bg.png"
magick PNG24:"$WORK_STICKER/cb-bg.png" PNG32:"$WORK_STICKER/sticker.png" \
  -composite PNG24:"$OUT/03-corgi-sticker.png"
rm -rf "$WORK_STICKER"
# Trash the stale .jpg (replaced by .png with checkerboard).
trash_path "$OUT/03-corgi-cutout.png" "$OUT/03-corgi-sticker.jpg"

echo "-- showcase 4: motion-radial backdrop (woman-singer, bg gets zoom-blur from subject centre; subject stays sharp) --"
# HYPOTHESIS: bg:zoom-blur radiates streaks outward from the chosen
# centre while --type person keeps the subject in razor focus. Reads as
# motion / drama / cover-art lighting without losing the subject.
cp "$WOMAN_SINGER" "$OUT/04-woman-singer-before.jpg"
"$BIN" "$WOMAN_SINGER" --type person \
  --bg "image:$WOMAN_SINGER" \
  --filter "bg:zoom-blur=center=0.5,0.45:amount=60" \
  -o "$OUT/04-woman-singer-zoom-blur.jpg" >/dev/null
trash_path "$OUT/04-kingfisher-before.jpg" "$OUT/04-kingfisher-vintage.jpg"

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

echo "-- showcase 5b: yoga with --type person (isolates the main subject from neighbours) --"
# HYPOTHESIS: the yoga photo has several people on adjacent mats. Default
# vn-mask picks up multiple instances. --type person uses VNGeneratePerson
# SegmentationRequest which is tuned for human subjects and prefers the
# largest / most prominent person.
cp "$YOGA" "$OUT/05-yoga-before.jpg"
"$BIN" "$YOGA" --type person --filter "bg:blur=40" -o "$OUT/05-yoga-person-portrait.jpg" >/dev/null
"$BIN" "$YOGA" --type person --filter "bg:grayscale,adjust=brightness=-0.1" -o "$OUT/05-yoga-person-colourpop.jpg" >/dev/null

# ============ One example per filter for docs/filters/<name>.md ============
# Each filter rendered against the same canonical subject (Red Panda over its
# own original background) so per-filter docs all share a baseline.
# Original colourful background ensures fg: filter effects show through
# clearly with the bg preserved as a visual anchor.
echo ""
echo "-- per-filter doc baseline (Red Panda on original natural background) --"

cp "$PANDA" "$FILT_OUT/_baseline.jpg"
echo "  ok  _baseline (cp of source)"

# Per-filter showcase images (docs/images/filters/<name>.jpg) are
# rendered by scripts/gen-docs.sh in the same pass as the markdown that
# documents them. Single source of truth: gen-docs.sh prints the
# bgbgone invocation AND executes it. Do not duplicate that here.

echo ""
echo "done."
ls -1 "$OUT" | wc -l | awk '{print "  showcase assets: " $1}'
ls -1 "$FILT_OUT" | wc -l | awk '{print "  per-filter assets: " $1}'
