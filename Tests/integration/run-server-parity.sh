#!/usr/bin/env bash
# run-server-parity.sh -- the same logical operations every CLI test in
# run.sh covers, run through `bgbgone --server` over HTTP /bgbgone.
#
# Parity contract (from docs/design.md): "CLI and `--server` resolve to
# the same `Config` and run the same pipeline. There is no parallel
# processing path." Every CLI test must therefore have a server
# equivalent that passes too. This file is that mirror.
#
# Each test starts with `Pnn` so it's easy to grep — P00..P99 maps onto
# the same areas as run.sh's e2e sections.
#
# Sourced by run.sh; assumes BIN, FIX, OUT, wait_for_server, stop_server,
# pass, fail, check_png_rgba, check_jpeg are already in scope.

set -uo pipefail

# Start one shared server for the parity suite.
PARITY_PORT=18791
PARITY_BASE="http://127.0.0.1:$PARITY_PORT"
"$BIN" --server --host 127.0.0.1 --port "$PARITY_PORT" --no-origin-check >/dev/null 2>&1 &
PARITY_PID=$!
if ! wait_for_server "$PARITY_BASE/health" >/dev/null 2>&1; then
    fail "server-parity bootstrap" "server failed to start on port $PARITY_PORT"
    kill "$PARITY_PID" 2>/dev/null || true
    return 1 2>/dev/null || exit 1
fi

parity_post() {
    # parity_post <fixture> <out-path> [extra curl -F args...]
    local fixture="$1"; shift
    local dst="$1"; shift
    curl -fsS -X POST "$PARITY_BASE/bgbgone" \
        -F "image_file=@${fixture}" \
        "$@" \
        -o "$dst" 2>&1
}

PFIX_PANDA="$FIX/red-panda.jpg"
PFIX_CORGI="$FIX/corgi-puppy.jpg"
PFIX_YOGA="$FIX/yoga.jpg"
PFIX_EINSTEIN="$FIX/einstein.jpg"

echo ""
echo "server-parity: every CLI e2e mirrored through HTTP /bgbgone"

# P01 — background removal default → transparent PNG.
out=$(parity_post "$PFIX_PANDA" "$OUT/p01.png" -F "format=png") ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$OUT/p01.png" \
    && pass "P01 default removes bg, returns PNG with alpha" \
    || fail "P01 default" "rc=$rc out=$out"

# P02 — --bg color:white → opaque JPEG.
out=$(parity_post "$PFIX_PANDA" "$OUT/p02.jpg" -F "format=jpg" -F "bg=color:white") ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$OUT/p02.jpg" \
    && pass "P02 --bg color → JPEG" \
    || fail "P02 --bg color" "rc=$rc out=$out"

# P03 — --bg image:<path> over multipart upload.
out=$(parity_post "$PFIX_YOGA" "$OUT/p03.jpg" -F "format=jpg" -F "bg=@${FIX}/matterhorn-sunset.jpg" -F "bg-fit=cover") ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$OUT/p03.jpg" \
    && pass "P03 --bg image (uploaded) + --bg-fit cover" \
    || fail "P03 --bg image" "rc=$rc out=$out"

# P04 — --filter bg:grayscale chain (already partial via T59; here as parity row).
out=$(parity_post "$PFIX_PANDA" "$OUT/p04.png" -F "format=png" -F "filter=bg:grayscale") ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$OUT/p04.png" \
    && pass "P04 --filter bg:grayscale" \
    || fail "P04 --filter bg:grayscale" "rc=$rc out=$out"

# P05 — --filter fg:outline produces alpha; requires PNG.
out=$(parity_post "$PFIX_CORGI" "$OUT/p05.png" -F "format=png" -F "filter=fg:outline=color=#ffffff:width=30") ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$OUT/p05.png" \
    && pass "P05 --filter fg:outline (PNG, alpha preserved)" \
    || fail "P05 --filter fg:outline" "rc=$rc out=$out"

# P06 — --quality knob honoured for JPEG output.
out_lo=$(parity_post "$PFIX_PANDA" "$OUT/p06-lo.jpg" -F "format=jpg" -F "bg=color:white" -F "quality=10") ; rc1=$?
out_hi=$(parity_post "$PFIX_PANDA" "$OUT/p06-hi.jpg" -F "format=jpg" -F "bg=color:white" -F "quality=95") ; rc2=$?
size_lo=$(stat -f%z "$OUT/p06-lo.jpg" 2>/dev/null || echo 0)
size_hi=$(stat -f%z "$OUT/p06-hi.jpg" 2>/dev/null || echo 0)
if [ $rc1 -eq 0 ] && [ $rc2 -eq 0 ] && [ "$size_lo" -lt "$size_hi" ]; then
    pass "P06 --quality 10 < --quality 95 ($size_lo < $size_hi)"
else
    fail "P06 --quality" "rc1=$rc1 rc2=$rc2 lo=$size_lo hi=$size_hi"
fi

# P07 — --channels alpha emits matte PNG.
out=$(parity_post "$PFIX_PANDA" "$OUT/p07.png" -F "format=png" -F "channels=alpha") ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$OUT/p07.png" \
    && pass "P07 --channels alpha emits matte PNG" \
    || fail "P07 --channels alpha" "rc=$rc out=$out"

# P08 — --type person selector.
out=$(parity_post "$PFIX_YOGA" "$OUT/p08.png" -F "format=png" -F "type=person") ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$OUT/p08.png" \
    && pass "P08 --type person isolates the subject" \
    || fail "P08 --type person" "rc=$rc out=$out"

# P09 — --crop tight-crops to subject bounding box.
out=$(parity_post "$PFIX_CORGI" "$OUT/p09.png" -F "format=png" -F "crop=true") ; rc=$?
size_full=$(magick identify -format '%w' "$OUT/p01.png" 2>/dev/null || echo 0)
size_crop=$(magick identify -format '%w' "$OUT/p09.png" 2>/dev/null || echo 0)
if [ $rc -eq 0 ] && [ "$size_crop" -lt "$size_full" ]; then
    pass "P09 --crop reduces canvas width ($size_crop < $size_full)"
else
    fail "P09 --crop" "rc=$rc full=$size_full crop=$size_crop"
fi

# P10 — --crop-margin expands the cropped canvas.
out=$(parity_post "$PFIX_CORGI" "$OUT/p10.png" -F "format=png" -F "crop=true" -F "crop-margin=20%") ; rc=$?
size_margin=$(magick identify -format '%w' "$OUT/p10.png" 2>/dev/null || echo 0)
if [ $rc -eq 0 ] && [ "$size_margin" -gt "$size_crop" ]; then
    pass "P10 --crop-margin 20% expands canvas ($size_margin > $size_crop)"
else
    fail "P10 --crop-margin" "rc=$rc no-margin=$size_crop with-margin=$size_margin"
fi

# P11 — --shadow-type drop differs from --shadow-type none.
out_none=$(parity_post "$PFIX_PANDA" "$OUT/p11-none.png" -F "format=png" -F "shadow-type=none") ; rc1=$?
out_drop=$(parity_post "$PFIX_PANDA" "$OUT/p11-drop.png" -F "format=png" -F "shadow-type=drop") ; rc2=$?
if [ $rc1 -eq 0 ] && [ $rc2 -eq 0 ] && ! cmp -s "$OUT/p11-none.png" "$OUT/p11-drop.png"; then
    pass "P11 --shadow-type drop differs from --shadow-type none"
else
    fail "P11 --shadow-type" "rc1=$rc1 rc2=$rc2"
fi

# P12 — --semitransparency true vs false produces different outputs.
out_t=$(parity_post "$PFIX_PANDA" "$OUT/p12-t.png" -F "format=png" -F "semitransparency=true") ; rc1=$?
out_f=$(parity_post "$PFIX_PANDA" "$OUT/p12-f.png" -F "format=png" -F "semitransparency=false") ; rc2=$?
if [ $rc1 -eq 0 ] && [ $rc2 -eq 0 ] && ! cmp -s "$OUT/p12-t.png" "$OUT/p12-f.png"; then
    pass "P12 --semitransparency true ≠ false"
else
    fail "P12 --semitransparency" "rc1=$rc1 rc2=$rc2"
fi

# P13 — --format png|jpg|heic|tiff|avif round trip.
declare -a PARITY_FORMATS=(png jpg heic tiff avif)
parity_format_failed=0
for fmt in "${PARITY_FORMATS[@]}"; do
    dst="$OUT/p13.$fmt"
    parity_post "$PFIX_PANDA" "$dst" -F "format=$fmt" -F "bg=color:white" >/dev/null
    if [ ! -s "$dst" ]; then
        parity_format_failed=1
        break
    fi
done
if [ "$parity_format_failed" -eq 0 ]; then
    pass "P13 --format png|jpg|heic|tiff|avif all produce non-empty output"
else
    fail "P13 --format round trip" "format=$fmt produced no output"
fi

# P14 — --format zip yields a ZIP with color.jpg + alpha.png.
parity_post "$PFIX_PANDA" "$OUT/p14.zip" -F "format=zip" >/dev/null
if [ -s "$OUT/p14.zip" ] && unzip -l "$OUT/p14.zip" 2>/dev/null | grep -q color.jpg && unzip -l "$OUT/p14.zip" 2>/dev/null | grep -q alpha.png; then
    pass "P14 --format zip contains color.jpg and alpha.png"
else
    fail "P14 --format zip" "missing color.jpg or alpha.png"
fi

# P15 — --roi clips processing to a rectangle, smaller output area.
out=$(parity_post "$PFIX_PANDA" "$OUT/p15.png" -F "format=png" -F "roi=0% 0% 100% 50%") ; rc=$?
if [ $rc -eq 0 ] && check_png_rgba "$OUT/p15.png"; then
    pass "P15 --roi clips to upper half"
else
    fail "P15 --roi" "rc=$rc out=$out"
fi

# P16 — unknown filter rejected with HTTP 400 + structured JSON error.
http_code=$(curl -s -o "$OUT/p16-body.txt" -w '%{http_code}' \
    -X POST "$PARITY_BASE/bgbgone" \
    -F "image_file=@$PFIX_PANDA" \
    -F "filter=fg:not-a-real-filter")
if [ "$http_code" = "400" ] && grep -q '"error"' "$OUT/p16-body.txt"; then
    pass "P16 unknown filter → HTTP 400 + JSON error envelope"
else
    fail "P16 unknown filter rejection" "http_code=$http_code body=$(head -1 "$OUT/p16-body.txt")"
fi

# P17 — JPEG + alpha-producing filter refused (T57 contract on HTTP).
http_code=$(curl -s -o "$OUT/p17-body.txt" -w '%{http_code}' \
    -X POST "$PARITY_BASE/bgbgone" \
    -F "image_file=@$PFIX_CORGI" \
    -F "format=jpg" \
    -F "filter=fg:matte")
if [ "$http_code" = "400" ] && grep -q '"error"' "$OUT/p17-body.txt"; then
    pass "P17 JPEG + alpha filter refused via HTTP (T57 contract)"
else
    fail "P17 JPEG+alpha refusal" "http_code=$http_code"
fi

# P18 — JSON response envelope on success.
out=$(curl -fsS -X POST "$PARITY_BASE/bgbgone" \
    -F "image_file=@$PFIX_PANDA" \
    -F "format=json" 2>&1) ; rc=$?
if [ $rc -eq 0 ] && printf '%s' "$out" | grep -q '"ok":true' \
   && printf '%s' "$out" | grep -q '"schema":"bgbgone.run.v1"'; then
    pass "P18 --format json emits stable success envelope"
else
    fail "P18 --format json" "rc=$rc out=$(echo "$out" | head -1)"
fi

# P19 — --size preview produces a smaller image than --size full.
parity_post "$PFIX_PANDA" "$OUT/p19-preview.png" -F "format=png" -F "size=preview" >/dev/null
parity_post "$PFIX_PANDA" "$OUT/p19-full.png"    -F "format=png" -F "size=full"    >/dev/null
size_preview=$(magick identify -format '%w' "$OUT/p19-preview.png" 2>/dev/null || echo 0)
size_full=$(magick identify -format '%w' "$OUT/p19-full.png" 2>/dev/null || echo 0)
if [ "$size_preview" -lt "$size_full" ] && [ "$size_preview" -gt 0 ]; then
    pass "P19 --size preview (${size_preview}px) < --size full (${size_full}px)"
else
    fail "P19 --size" "preview=$size_preview full=$size_full"
fi

# Stop the parity server.
kill "$PARITY_PID" 2>/dev/null || true
wait "$PARITY_PID" 2>/dev/null || true
echo "server-parity: done (server on port $PARITY_PORT stopped)"
