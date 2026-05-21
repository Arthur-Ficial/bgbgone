#!/bin/bash
# Integration tests for bgbgone CLI.
# Run: bash Tests/integration/run.sh [path/to/bgbgone-binary]
#
# Tests are organized by feature group. Every test prints OK or FAIL with a reason.
# Exit non-zero on any failure.

set -uo pipefail

BIN="${1:-bgbgone}"
if [[ "$BIN" == */* ]]; then
    BIN="$(cd "$(dirname "$BIN")" && pwd)/$(basename "$BIN")"
fi
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$DIR/../.." && pwd)"
FIX="$ROOT/fixtures"
OUT="$DIR/_out"
TMP="$DIR/_tmp"

rm -rf "$OUT" "$TMP"
mkdir -p "$OUT" "$TMP"

PASSED=0
FAILED=0
FAILS=()

pass() { echo "  OK   $1"; PASSED=$((PASSED + 1)); }
fail() { echo "  FAIL $1: $2"; FAILED=$((FAILED + 1)); FAILS+=("$1: $2"); }

# Verify a path is a PNG with alpha (RGBA).
check_png_rgba() {
    local file="$1"
    [ -f "$file" ] || return 1
    # PNG signature is the first 8 bytes 89 50 4E 47 0D 0A 1A 0A
    head -c 8 "$file" | xxd -p | grep -qi '^89504e470d0a1a0a$' || return 2
    return 0
}

check_jpeg() {
    local file="$1"
    [ -f "$file" ] || return 1
    head -c 3 "$file" | xxd -p | grep -qi '^ffd8ff$' || return 2
    return 0
}

echo ""
echo "Integration tests for: $BIN"
echo "================================="
echo "Fixtures dir: $FIX"
echo "Output dir:   $OUT"
echo ""

# --- CLI basics ---
echo "CLI basics"

out=$("$BIN" --version 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q "^bgbgone v" && pass "--version" \
    || fail "--version" "rc=$rc out=$out"

expected_version=$(cat "$PROJECT_ROOT/.version")
[ $rc -eq 0 ] && [ "$out" = "bgbgone v$expected_version" ] && pass "--version matches .version ($expected_version)" \
    || fail "--version matches .version" "expected bgbgone v$expected_version, got $out"

out=$("$BIN" --help 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -qi "USAGE:" && pass "--help" \
    || fail "--help" "rc=$rc"

out=$("$BIN" -h 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -qi "USAGE:" && pass "-h alias" \
    || fail "-h alias" "rc=$rc"

out=$("$BIN" --check 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -qi "macOS" && pass "--check" \
    || fail "--check" "rc=$rc out=$out"

# --- Exit codes ---
echo ""
echo "Exit codes"

"$BIN" --made-up-flag >/dev/null 2>&1 ; rc=$?
[ $rc -eq 2 ] && pass "unknown flag -> exit 2" || fail "unknown flag" "expected exit 2, got $rc"

"$BIN" /nonexistent/path/image.jpg -o /tmp/x.png >/dev/null 2>&1 ; rc=$?
[ $rc -eq 1 ] && pass "nonexistent input -> exit 1" || fail "nonexistent input" "expected exit 1, got $rc"

out=$("$BIN" "$FIX/07-einstein-1921.jpg" "$FIX/08-tesla-sarony.jpg" -o "$OUT/one.png" 2>&1) ; rc=$?
[ $rc -eq 1 ] && echo "$out" | grep -q "multiple inputs" && pass "multiple inputs with -o -> exit 1 before processing" \
    || fail "multiple inputs with -o" "expected exit 1 and multiple-input message, got rc=$rc out=$out"

out=$("$BIN" "$FIX/07-einstein-1921.jpg" -o "$OUT/one.png" --out-dir "$OUT/conflict" 2>&1) ; rc=$?
[ $rc -eq 1 ] && echo "$out" | grep -q -- "--out-dir" && pass "-o with --out-dir rejected" \
    || fail "-o with --out-dir" "expected exit 1, got rc=$rc out=$out"

out=$(cat "$FIX/07-einstein-1921.jpg" | "$BIN" --out-dir "$OUT/stdin-outdir" 2>&1 >/dev/null) ; rc=$?
[ $rc -eq 1 ] && echo "$out" | grep -q "stdin" && pass "stdin with --out-dir rejected" \
    || fail "stdin with --out-dir" "expected exit 1, got rc=$rc out=$out"

out=$("$BIN" "$FIX/09-wright-brothers-1910.jpg" --multi -o "$OUT/person.png" 2>&1) ; rc=$?
[ $rc -eq 1 ] && echo "$out" | grep -q -- "--multi" && pass "--multi with -o rejected" \
    || fail "--multi with -o" "expected exit 1, got rc=$rc out=$out"

bad_parent="$TMP/not-a-directory"
printf "not a directory" > "$bad_parent"
out=$("$BIN" "$FIX/07-einstein-1921.jpg" -o "$bad_parent/out.png" 2>&1) ; rc=$?
[ $rc -eq 1 ] && echo "$out" | grep -q "output parent" && pass "output parent path that is a file -> exit 1" \
    || fail "output parent path" "expected exit 1, got rc=$rc out=$out"

# Refuse to write binary to a terminal — but only when stdout is a TTY.
# When this script runs, stdout is piped (not a TTY), so this case can't be
# tested portably without `script(1)`. Skip — covered by unit test.
pass "refuse-TTY (covered by unit tests)"

# --- Fixtures present ---
echo ""
echo "Fixtures"

FIXTURE_COUNT=$(ls -1 "$FIX"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
if [ "$FIXTURE_COUNT" -ge 10 ]; then
    pass "≥10 fixtures present ($FIXTURE_COUNT)"
else
    fail "fixtures" "expected ≥10, got $FIXTURE_COUNT (run 'make fixtures')"
fi

[ -f "$FIX/LICENSES.md" ] && pass "fixtures LICENSES.md present" || fail "fixtures" "LICENSES.md missing"

# --- e2e: bg removal across all fixtures ---
echo ""
echo "e2e: background removal (12 fixtures)"

for src in "$FIX"/*.jpg; do
    base=$(basename "$src" .jpg)
    dst="$OUT/${base}-cutout.png"
    out=$("$BIN" "$src" -o "$dst" 2>&1) ; rc=$?
    if [ $rc -ne 0 ]; then
        fail "$base" "rc=$rc out=$out"
        continue
    fi
    if [ ! -s "$dst" ]; then
        fail "$base" "no output file written"
        continue
    fi
    # PNG header sniff
    head -c 8 "$dst" | xxd -p | tr -d '\n' | grep -qi '^89504e470d0a1a0a' \
        || { fail "$base" "output not a PNG"; continue; }
    pass "$base"
done

# --- e2e: --bg color replacement on one fixture ---
echo ""
echo "e2e: --bg color replacement"

src="$FIX/07-einstein-1921.jpg"
dst="$OUT/einstein-on-white.jpg"
out=$("$BIN" "$src" --bg "color:#ffffff" --to jpg -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && [ -s "$dst" ] && pass "--bg color:#fff (einstein)" || fail "--bg color" "rc=$rc out=$out"

# --- e2e: --json output ---
echo ""
echo "e2e: --json output"

src="$FIX/02-nasa-mccandless-eva.jpg"
dst="$OUT/eva.png"
out=$("$BIN" "$src" -o "$dst" --json 2>&1) ; rc=$?
echo "$out" | grep -q '"output"' && pass "--json has output field" || fail "--json" "rc=$rc out=$out"
echo "$out" | grep -q '"algo"' && pass "--json has algo field" || fail "--json" "no algo field"

AUTO_JSON_DIR="$TMP/auto-json"
mkdir -p "$AUTO_JSON_DIR"
cp "$src" "$AUTO_JSON_DIR/eva.jpg"
out=$(cd "$AUTO_JSON_DIR" && "$BIN" eva.jpg --json --quiet 2>&1) ; rc=$?
if [ $rc -eq 0 ] && echo "$out" | grep -q '"output":"eva_bgbgone.png"' && check_png_rgba "$AUTO_JSON_DIR/eva_bgbgone.png"; then
    pass "--json without -o writes eva_bgbgone.png and keeps stdout JSON-only"
else
    fail "--json auto output" "rc=$rc out=$out"
fi

# --- e2e: output format inference ---
echo ""
echo "e2e: output format inference"

src="$FIX/07-einstein-1921.jpg"
dst="$OUT/einstein-inferred.jpg"
out=$("$BIN" "$src" -o "$dst" --quiet 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$dst" && pass "-o out.jpg infers JPEG and opaque background" \
    || fail "-o jpg inference" "rc=$rc out=$out"

dst="$OUT/einstein-redirect.jpg"
out=$("$BIN" "$src" --quiet > "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$dst" && pass "> out.jpg infers JPEG when macOS exposes stdout path" \
    || fail "stdout jpg inference" "rc=$rc out=$out"

# --- e2e: --bg image replacement ---
echo ""
echo "e2e: --bg image replacement"

# Use a galaxy as the background, the astronaut as the foreground.
src="$FIX/02-nasa-mccandless-eva.jpg"
bg="$FIX/04-nasa-hubble-ngc1300.jpg"
dst="$OUT/eva-on-galaxy.jpg"
out=$("$BIN" "$src" --bg "image:$bg" --to jpg -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && [ -s "$dst" ] && pass "--bg image (eva on galaxy)" || fail "--bg image" "rc=$rc out=$out"

# Variants of --bg-fit shouldn't break the pipeline
for fit in cover contain center tile; do
    dst="$OUT/eva-fit-$fit.jpg"
    out=$("$BIN" "$src" --bg "image:$bg" --bg-fit "$fit" --to jpg -o "$dst" 2>&1) ; rc=$?
    [ $rc -eq 0 ] && [ -s "$dst" ] && pass "--bg-fit $fit" || fail "--bg-fit $fit" "rc=$rc"
done

# --- e2e: --to format conversions ---
echo ""
echo "e2e: --to format conversions"

src="$FIX/07-einstein-1921.jpg"
for fmt in png jpg heic avif tiff; do
    dst="$OUT/einstein.$fmt"
    out=$("$BIN" "$src" --bg "color:white" --to "$fmt" -o "$dst" 2>&1) ; rc=$?
    if [ $rc -eq 0 ] && [ -s "$dst" ]; then
        pass "--to $fmt"
    else
        fail "--to $fmt" "rc=$rc out=$out"
    fi
done

# Removed formats and algorithms must be rejected with a parser error, not silently
# accepted then failed at framework level. They never existed for the user.
for fmt in webp bmp gif; do
    out=$("$BIN" "$src" --to "$fmt" -o "$OUT/dummy.$fmt" 2>&1) ; rc=$?
    [ $rc -eq 2 ] && pass "--to $fmt rejected at parse (rc=2)" \
        || fail "--to $fmt rejection" "expected rc=2, got rc=$rc out=$out"
done
for algo in vn-remove sky bogus; do
    out=$("$BIN" "$src" --algo "$algo" -o "$OUT/dummy.png" 2>&1) ; rc=$?
    [ $rc -eq 2 ] && pass "--algo $algo rejected at parse (rc=2)" \
        || fail "--algo $algo rejection" "expected rc=2, got rc=$rc out=$out"
done

# --- e2e: --quality knob honored for jpg ---
echo ""
echo "e2e: --quality"

src="$FIX/05-nasa-apollo11-crew.jpg"
d_low="$OUT/crew-q10.jpg"
d_high="$OUT/crew-q95.jpg"
"$BIN" "$src" --bg "color:black" --to jpg --quality 10 -o "$d_low" 2>/dev/null
"$BIN" "$src" --bg "color:black" --to jpg --quality 95 -o "$d_high" 2>/dev/null
if [ -s "$d_low" ] && [ -s "$d_high" ]; then
    s_low=$(stat -f '%z' "$d_low")
    s_high=$(stat -f '%z' "$d_high")
    if [ "$s_low" -lt "$s_high" ]; then
        pass "--quality 10 < --quality 95 ($s_low < $s_high)"
    else
        fail "--quality" "expected low<high, got $s_low >= $s_high"
    fi
else
    fail "--quality" "outputs missing"
fi

# --- e2e: --mask-only emits a meaningful grayscale-ish file ---
echo ""
echo "e2e: --mask-only"

src="$FIX/02-nasa-mccandless-eva.jpg"
dst="$OUT/eva-mask.png"
out=$("$BIN" "$src" --mask-only -o "$dst" 2>&1) ; rc=$?
if [ $rc -eq 0 ] && [ -s "$dst" ]; then
    head -c 8 "$dst" | xxd -p | tr -d '\n' | grep -qi '^89504e470d0a1a0a' && pass "--mask-only emits PNG" \
        || fail "--mask-only" "output not PNG"
else
    fail "--mask-only" "rc=$rc out=$out"
fi

# --- e2e: stdin pipe in, stdout pipe out ---
echo ""
echo "e2e: pipe in / pipe out"

dst="$OUT/eva-via-pipe.png"
cat "$FIX/02-nasa-mccandless-eva.jpg" | "$BIN" > "$dst" 2>/dev/null
rc=$?
if [ $rc -eq 0 ] && [ -s "$dst" ]; then
    head -c 8 "$dst" | xxd -p | tr -d '\n' | grep -qi '^89504e470d0a1a0a' && pass "cat in.jpg | bgbgone > out.png" \
        || fail "pipe" "stdout not PNG"
else
    fail "pipe" "rc=$rc"
fi

# --- e2e: batch with --out-dir ---
echo ""
echo "e2e: batch --out-dir"

BATCH_OUT="$OUT/batch"
mkdir -p "$BATCH_OUT"
"$BIN" "$FIX/01-nasa-aldrin-moon.jpg" "$FIX/02-nasa-mccandless-eva.jpg" "$FIX/03-nasa-earthrise.jpg" \
    --out-dir "$BATCH_OUT" 2>/dev/null
rc=$?
count=$(ls -1 "$BATCH_OUT"/*.png 2>/dev/null | wc -l | tr -d ' ')
if [ $rc -eq 0 ] && [ "$count" -eq 3 ]; then
    pass "batch --out-dir produced 3 files"
else
    fail "batch" "rc=$rc count=$count"
fi

# --- e2e: --feather softens edges ---
echo ""
echo "e2e: --feather"

src="$FIX/02-nasa-mccandless-eva.jpg"
"$BIN" "$src" --feather 0 -o "$OUT/eva-f0.png" 2>/dev/null
"$BIN" "$src" --feather 8 -o "$OUT/eva-f8.png" 2>/dev/null
"$BIN" "$src" --feather 16 -o "$OUT/eva-f16.png" 2>/dev/null
if [ -s "$OUT/eva-f0.png" ] && [ -s "$OUT/eva-f8.png" ]; then
    sz0=$(stat -f '%z' "$OUT/eva-f0.png")
    sz8=$(stat -f '%z' "$OUT/eva-f8.png")
    [ "$sz0" -ne "$sz8" ] && pass "--feather changes output (size $sz0 != $sz8)" \
        || fail "--feather" "feather=0 and feather=8 produced identical files"
else
    fail "--feather" "outputs missing"
fi

# Regression: feather > 0 used to silently disable background removal because the
# Gaussian-blurred mask came back in sRGB rather than DeviceGray. The corner pixel
# of a cutout against space must be fully transparent regardless of feather radius.
for r in 0 8 16; do
    out=$("$BIN" "$src" --feather "$r" -o "$OUT/eva-f$r.png" 2>&1) ; rc=$?
    if [ $rc -ne 0 ] || [ ! -s "$OUT/eva-f$r.png" ]; then
        fail "--feather $r corner alpha" "no output (rc=$rc out=$out)"
        continue
    fi
    corner=$(magick "$OUT/eva-f$r.png" -format '%[pixel:p{5,5}]' info: 2>/dev/null)
    case "$corner" in
        *",0)"|*"a=0)"|*"none"*) pass "--feather $r corner alpha == 0 (bg removed)" ;;
        *) fail "--feather $r corner alpha" "expected transparent corner, got $corner" ;;
    esac
done

# --- e2e: --threshold changes matte decisively ---
echo ""
echo "e2e: --threshold"

src="$FIX/02-nasa-mccandless-eva.jpg"
"$BIN" "$src" --threshold 0.20 -o "$OUT/eva-threshold-020.png" 2>/dev/null
"$BIN" "$src" --threshold 0.80 -o "$OUT/eva-threshold-080.png" 2>/dev/null
if [ -s "$OUT/eva-threshold-020.png" ] && [ -s "$OUT/eva-threshold-080.png" ]; then
    if cmp -s "$OUT/eva-threshold-020.png" "$OUT/eva-threshold-080.png"; then
        fail "--threshold" "threshold 0.20 and 0.80 produced identical output"
    else
        pass "--threshold changes the output matte"
    fi
else
    fail "--threshold" "outputs missing"
fi

# --- e2e: --crop tightens to subject bbox ---
echo ""
echo "e2e: --crop"

src="$FIX/02-nasa-mccandless-eva.jpg"
"$BIN" "$src" -o "$OUT/eva-uncropped.png" 2>/dev/null
"$BIN" "$src" --crop -o "$OUT/eva-cropped.png" 2>/dev/null
if [ -s "$OUT/eva-uncropped.png" ] && [ -s "$OUT/eva-cropped.png" ]; then
    cmp=$(python3 - <<PY
from PIL import Image
a = Image.open("$OUT/eva-uncropped.png").size
b = Image.open("$OUT/eva-cropped.png").size
print("ok" if b[0] < a[0] and b[1] < a[1] else f"bad uncropped={a} cropped={b}")
PY
)
    [ "$cmp" = "ok" ] && pass "--crop reduces canvas to subject" || fail "--crop" "$cmp"
else
    fail "--crop" "outputs missing"
fi

# --- e2e: --padding enlarges cropped subject canvas ---
echo ""
echo "e2e: --padding"

src="$FIX/02-nasa-mccandless-eva.jpg"
"$BIN" "$src" --crop -o "$OUT/eva-crop-only.png" 2>/dev/null
"$BIN" "$src" --crop --padding 10% -o "$OUT/eva-crop-padded.png" 2>/dev/null
if [ -s "$OUT/eva-crop-only.png" ] && [ -s "$OUT/eva-crop-padded.png" ]; then
    cmp=$(python3 - <<PY
from PIL import Image
a = Image.open("$OUT/eva-crop-only.png").size
b = Image.open("$OUT/eva-crop-padded.png").size
print("ok" if b[0] > a[0] and b[1] > a[1] else f"bad crop={a} padded={b}")
PY
)
    [ "$cmp" = "ok" ] && pass "--padding 10% expands --crop canvas" || fail "--padding" "$cmp"
else
    fail "--padding" "outputs missing"
fi

# --- e2e: --shadow adds visible pixels under the cutout ---
echo ""
echo "e2e: --shadow"

src="$FIX/07-einstein-1921.jpg"
"$BIN" "$src" --bg color:white -o "$OUT/einstein-no-shadow.png" 2>/dev/null
"$BIN" "$src" --bg color:white --shadow -o "$OUT/einstein-shadow.png" 2>/dev/null
if [ -s "$OUT/einstein-no-shadow.png" ] && [ -s "$OUT/einstein-shadow.png" ]; then
    if cmp -s "$OUT/einstein-no-shadow.png" "$OUT/einstein-shadow.png"; then
        fail "--shadow" "shadow and non-shadow output were identical"
    else
        pass "--shadow changes composited output"
    fi
else
    fail "--shadow" "outputs missing"
fi

# --- e2e: --bg-fit tile is distinct from cover ---
echo ""
echo "e2e: --bg-fit tile"

src="$FIX/07-einstein-1921.jpg"
bg="$FIX/03-nasa-earthrise.jpg"
"$BIN" "$src" --bg "image:$bg" --bg-fit cover -o "$OUT/einstein-cover.png" 2>/dev/null
"$BIN" "$src" --bg "image:$bg" --bg-fit tile -o "$OUT/einstein-tile.png" 2>/dev/null
if [ -s "$OUT/einstein-cover.png" ] && [ -s "$OUT/einstein-tile.png" ]; then
    if cmp -s "$OUT/einstein-cover.png" "$OUT/einstein-tile.png"; then
        fail "--bg-fit tile" "tile and cover produced identical output"
    else
        pass "--bg-fit tile uses distinct tiling behavior"
    fi
else
    fail "--bg-fit tile" "outputs missing"
fi

# --- e2e: --multi multi-instance output ---
echo ""
echo "e2e: --multi"

# The number of detected instances depends on Vision's interpretation. For correctness we
# require: at least one file is produced AND its name follows the --instance-naming template
# ({base}-{n}.{ext}). The "N instances = N files" semantic is covered by the unit-test
# InstanceNaming.expand suite.
src="$FIX/09-wright-brothers-1910.jpg"
MULTI_OUT="$OUT/multi"
mkdir -p "$MULTI_OUT"
out=$("$BIN" "$src" --multi --out-dir "$MULTI_OUT" 2>&1) ; rc=$?
count=$(ls -1 "$MULTI_OUT"/*.png 2>/dev/null | wc -l | tr -d ' ')
template_match=$(ls -1 "$MULTI_OUT" | grep -c -E '09-wright-brothers-1910-[0-9]+\.png$' || true)
if [ $rc -eq 0 ] && [ "$count" -ge 1 ] && [ "$template_match" -ge 1 ]; then
    pass "--multi produced $count file(s) matching template"
else
    fail "--multi" "rc=$rc count=$count template_match=$template_match out=$out"
fi

MULTI_DEFAULT_IN="$TMP/multi-default/input"
MULTI_DEFAULT_CWD="$TMP/multi-default/cwd"
mkdir -p "$MULTI_DEFAULT_IN" "$MULTI_DEFAULT_CWD"
cp "$src" "$MULTI_DEFAULT_IN/team.jpg"
out=$(cd "$MULTI_DEFAULT_CWD" && "$BIN" "$MULTI_DEFAULT_IN/team.jpg" --multi 2>&1) ; rc=$?
sidecar_count=$(ls -1 "$MULTI_DEFAULT_IN"/team-*.png 2>/dev/null | wc -l | tr -d ' ')
cwd_count=$(ls -1 "$MULTI_DEFAULT_CWD"/team-*.png 2>/dev/null | wc -l | tr -d ' ')
if [ $rc -eq 0 ] && [ "$sidecar_count" -ge 1 ] && [ "$cwd_count" -eq 0 ]; then
    pass "--multi without --out-dir writes beside input, not cwd"
else
    fail "--multi default output dir" "rc=$rc sidecar=$sidecar_count cwd=$cwd_count out=$out"
fi

# Custom naming template
MULTI2_OUT="$OUT/multi2"
mkdir -p "$MULTI2_OUT"
"$BIN" "$src" --multi --instance-naming "subject_{n:02}.{ext}" --out-dir "$MULTI2_OUT" 2>/dev/null
cm=$(ls -1 "$MULTI2_OUT" | grep -c -E '^subject_[0-9]{2}\.png$' || true)
[ "$cm" -ge 1 ] && pass "--instance-naming custom template (subject_NN.png)" \
    || fail "--instance-naming" "no files matched template"

# --- e2e: NetworkGuard install does not crash the process ---
echo ""
echo "e2e: NetworkGuard install"

# Indirect probe — if NetworkGuard.install() blew up at process start, --version would not
# emit. We re-check that here as a regression guard.
out=$("$BIN" --version 2>&1)
echo "$out" | grep -q "^bgbgone v" && pass "binary starts after NetworkGuard install" || fail "NetworkGuard" "no version output"

# --- Summary ---
echo ""
echo "================================="
if [ $FAILED -eq 0 ]; then
    echo "OK: $PASSED passed, 0 failed"
    exit 0
else
    echo "FAIL: $PASSED passed, $FAILED failed"
    for f in "${FAILS[@]}"; do echo "  - $f"; done
    exit 1
fi
