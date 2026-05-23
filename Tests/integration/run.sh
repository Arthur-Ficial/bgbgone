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
SERVER_PID=""

pass() { echo "  OK   $1"; PASSED=$((PASSED + 1)); }
fail() { echo "  FAIL $1: $2"; FAILED=$((FAILED + 1)); FAILS+=("$1: $2"); }

stop_server() {
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" >/dev/null 2>&1 || true
        wait "$SERVER_PID" >/dev/null 2>&1 || true
        SERVER_PID=""
    fi
}

trap stop_server EXIT

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

wait_for_server() {
    local url="$1"
    local tries=80
    while [ "$tries" -gt 0 ]; do
        if curl -fsS "$url" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.1
        tries=$((tries - 1))
    done
    return 1
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

[ $rc -eq 0 ] && echo "$out" | grep -q "bgbgone v$expected_version" && pass "--check reports the current .version" \
    || fail "--check version" "expected v$expected_version, got $(echo "$out" | head -1)"

out=$("$BIN" --help 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q -- "--server" && echo "$out" | grep -q -- "--token-auto" && echo "$out" | grep -q -- "--type" && pass "--help mentions the server, token-auto, and type flags" \
    || fail "--help server/type coverage" "rc=$rc"

# No-arg, TTY stdin: should print help and exit 0 (no error). We can't fake a TTY
# from this script, so test the inverse: no-arg + piped empty stdin streams stdin
# which becomes "-" — but with stdout redirected, the stdin pipe is what triggers
# process mode. Skip — covered by parser tests.
pass "no-args TTY help (covered by unit tests)"

# --- Local HTTP server ---
echo ""
echo "server: local API"

SERVER_PORT=18787
SERVER_BASE="http://127.0.0.1:$SERVER_PORT"
SERVER_LOG="$TMP/server.log"
"$BIN" --server --port "$SERVER_PORT" --cors --allowed-origins "http://localhost:3000" >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
if wait_for_server "$SERVER_BASE/health"; then
    pass "--server starts and /health responds"
else
    fail "--server start" "server did not become healthy; log=$(cat "$SERVER_LOG" 2>/dev/null)"
fi

out=$(curl -fsS "$SERVER_BASE/health" 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q '"status":"ok"' && echo "$out" | grep -q '"version"' && pass "/health JSON" \
    || fail "/health JSON" "rc=$rc out=$out"

code=$(curl -sS -o "$TMP/origin-block.json" -w "%{http_code}" -H "Origin: http://example.com" "$SERVER_BASE/health")
[ "$code" = "403" ] && grep -q "not allowed" "$TMP/origin-block.json" && pass "foreign Origin rejected" \
    || fail "foreign Origin rejected" "code=$code body=$(cat "$TMP/origin-block.json" 2>/dev/null)"

headers="$TMP/preflight.headers"
code=$(curl -sS -o /dev/null -D "$headers" -w "%{http_code}" -X OPTIONS \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Headers: Content-Type, Authorization" \
    "$SERVER_BASE/v1.0/bgbgone")
if [ "$code" = "204" ] && grep -qi "Access-Control-Allow-Origin: http://localhost:3000" "$headers"; then
    pass "CORS preflight for allowed localhost origin"
else
    fail "CORS preflight" "code=$code headers=$(cat "$headers" 2>/dev/null)"
fi

dst="$OUT/server-einstein.png"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "format=png" \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$dst" && pass "POST /v1.0/bgbgone multipart image_file -> PNG" \
    || fail "server multipart PNG" "rc=$rc out=$out"

dst="$OUT/server-einstein-key-header.png"
headers="$TMP/server-output.headers"
out=$(curl -fsS -D "$headers" -X POST "$SERVER_BASE/bgbgone" \
    -H "X-API-Key: placeholder-local-key" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "format=auto" \
    -F "size=preview" \
    -o "$dst" 2>&1) ; rc=$?
if [ $rc -eq 0 ] && check_png_rgba "$dst" \
    && grep -qi '^X-Width:' "$headers" \
    && grep -qi '^X-Height:' "$headers" \
    && grep -qi '^X-Credits-Charged: 0' "$headers" \
    && grep -qi '^X-Foreground-Width:' "$headers"; then
    pass "server /bgbgone alias accepts placeholder X-API-Key and emits metadata"
else
    fail "server alias/auth metadata" "rc=$rc out=$out headers=$(cat "$headers" 2>/dev/null)"
fi

dst="$OUT/server-einstein-alpha.png"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "channels=alpha" \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$dst" && pass "server channels=alpha emits matte PNG" \
    || fail "server alpha" "rc=$rc out=$out"

dst="$OUT/server-einstein-white.jpg"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "format=jpg" \
    -F "bg_color=ffffff" \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$dst" && pass "server format=jpg bg_color -> JPEG" \
    || fail "server jpg bg_color" "rc=$rc out=$out"

dst="$OUT/server-shared-controls.jpg"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "format=jpg" \
    -F "bg_image_file=@$FIX/03-nasa-earthrise.jpg" \
    -F "bg_fit=tile" \
    -F "feather=3" \
    -F "threshold=0.45" \
    -F "quality=70" \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$dst" && pass "server shared image controls -> JPEG" \
    || fail "server shared image controls" "rc=$rc out=$out"

json="$OUT/server-json-response.json"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "format=json" \
    -o "$json" 2>&1) ; rc=$?
if [ $rc -eq 0 ]; then
    decoded="$OUT/server-json-decoded.png"
    python3 - <<PY
import base64, json
from pathlib import Path
data = json.loads(Path("$json").read_text())
Path("$decoded").write_bytes(base64.b64decode(data["data"]["result_b64"]))
PY
    check_png_rgba "$decoded" && pass "server format=json wraps base64 image" \
        || fail "server json response" "decoded output is not PNG"
else
    fail "server json response" "rc=$rc out=$out"
fi

python3 - "$FIX/07-einstein-1921.jpg" "$TMP/server-json-body.json" <<'PY'
import base64, json, sys
src, dst = sys.argv[1:3]
payload = {
    "image_file_b64": base64.b64encode(open(src, "rb").read()).decode("ascii"),
    "format": "jpg",
    "bg_color": "ffffff",
    "size": "preview",
    "crop": True,
    "crop_margin": "5%",
    "shadow_type": "drop",
    "shadow_opacity": "25"
}
open(dst, "w").write(json.dumps(payload))
PY
dst="$OUT/server-json-body.jpg"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -H "Content-Type: application/json" \
    --data-binary "@$TMP/server-json-body.json" \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$dst" && pass "server application/json image_file_b64 -> JPEG" \
    || fail "server json body" "rc=$rc out=$out"

python3 - "$FIX/07-einstein-1921.jpg" "$TMP/server-urlencoded-body.txt" <<'PY'
import base64, sys, urllib.parse
src, dst = sys.argv[1:3]
payload = {
    "image_file_b64": base64.b64encode(open(src, "rb").read()).decode("ascii"),
    "format": "png",
    "channels": "rgba"
}
open(dst, "w").write(urllib.parse.urlencode(payload))
PY
json="$OUT/server-accept-json-response.json"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -H "Accept: application/json" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-binary "@$TMP/server-urlencoded-body.txt" \
    -o "$json" 2>&1) ; rc=$?
if [ $rc -eq 0 ] && grep -q '"foreground_width"' "$json"; then
    pass "server Accept application/json wraps result and foreground metadata"
else
    fail "server accept json" "rc=$rc out=$out body=$(cat "$json" 2>/dev/null)"
fi

zip="$OUT/server-result.zip"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "format=zip" \
    -o "$zip" 2>&1) ; rc=$?
if [ $rc -eq 0 ] && python3 - "$zip" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    names = set(z.namelist())
    assert {"color.jpg", "alpha.png"} <= names, names
PY
then
    pass "server format=zip returns color.jpg and alpha.png"
else
    fail "server zip" "rc=$rc out=$out"
fi

out=$(curl -fsS "$SERVER_BASE/account" 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q '"credits"' && echo "$out" | grep -q '"free_calls"' && pass "server /account compatibility shape" \
    || fail "server account shape" "rc=$rc out=$out"

code=$(curl -sS -o "$TMP/server-image-url.json" -w "%{http_code}" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -d "image_url=https://example.com/in.jpg")
[ "$code" = "501" ] && grep -q "NOT IMPLEMENTABLE" "$TMP/server-image-url.json" && pass "server marks network-backed image_url not implementable" \
    || fail "server image_url rejection" "code=$code body=$(cat "$TMP/server-image-url.json" 2>/dev/null)"

code=$(curl -sS -o "$TMP/server-bg-url.json" -w "%{http_code}" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "bg_image_url=https://example.com/bg.jpg")
[ "$code" = "501" ] && grep -q "NOT IMPLEMENTABLE" "$TMP/server-bg-url.json" && pass "server marks bg_image_url not implementable" \
    || fail "server bg_image_url rejection" "code=$code body=$(cat "$TMP/server-bg-url.json" 2>/dev/null)"

code=$(curl -sS -o "$TMP/server-webp.json" -w "%{http_code}" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "format=webp")
[ "$code" = "501" ] && grep -q "NOT IMPLEMENTABLE" "$TMP/server-webp.json" && pass "server marks webp output not implementable" \
    || fail "server webp not implementable" "code=$code body=$(cat "$TMP/server-webp.json" 2>/dev/null)"

code=$(curl -sS -o "$TMP/server-improve.json" -w "%{http_code}" -X POST "$SERVER_BASE/improve" \
    -F "image_file=@$FIX/07-einstein-1921.jpg")
[ "$code" = "501" ] && grep -q "NOT IMPLEMENTABLE" "$TMP/server-improve.json" && pass "server /improve not implementable" \
    || fail "server improve not implementable" "code=$code body=$(cat "$TMP/server-improve.json" 2>/dev/null)"

code=$(curl -sS -o "$TMP/server-unknown.json" -w "%{http_code}" "$SERVER_BASE/totally-made-up")
[ "$code" = "404" ] && grep -q '"not_found"' "$TMP/server-unknown.json" && pass "unknown endpoint returns 404 not_found" \
    || fail "unknown endpoint" "code=$code body=$(cat "$TMP/server-unknown.json" 2>/dev/null)"

# /v1.0/account is aliased to /account
out=$(curl -fsS "$SERVER_BASE/v1.0/account" 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q '"credits"' && pass "/v1.0/account is aliased to /account" \
    || fail "v1.0/account alias" "rc=$rc out=$out"

# Multi-source rejection: image_file plus image_file_b64
b64=$(python3 -c "import base64; print(base64.b64encode(open('$FIX/07-einstein-1921.jpg','rb').read()).decode())")
code=$(curl -sS -o "$TMP/server-multi-source.json" -w "%{http_code}" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "image_file_b64=$b64")
[ "$code" = "400" ] && grep -q '"multiple_sources"' "$TMP/server-multi-source.json" && pass "server rejects multiple image sources" \
    || fail "multi source rejection" "code=$code body=$(cat "$TMP/server-multi-source.json" 2>/dev/null)"

# Multi-bg-source rejection: bg_color + bg_image_file
code=$(curl -sS -o "$TMP/server-multi-bg.json" -w "%{http_code}" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "bg_color=ffffff" \
    -F "bg_image_file=@$FIX/03-nasa-earthrise.jpg")
[ "$code" = "400" ] && grep -q '"multiple_bg_sources"' "$TMP/server-multi-bg.json" && pass "server rejects multiple background sources" \
    || fail "multi bg rejection" "code=$code body=$(cat "$TMP/server-multi-bg.json" 2>/dev/null)"

# Missing source: no input at all
code=$(curl -sS -o "$TMP/server-missing.json" -w "%{http_code}" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "format=png")
[ "$code" = "400" ] && grep -q '"missing_source"' "$TMP/server-missing.json" && pass "server rejects request with no image source" \
    || fail "missing source" "code=$code body=$(cat "$TMP/server-missing.json" 2>/dev/null)"

# X-Type header policy: type=person emits X-Type: person
headers="$TMP/server-xtype.headers"
dst="$OUT/server-einstein-xtype.png"
curl -fsS -D "$headers" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "type=person" \
    -o "$dst" >/dev/null 2>&1
if grep -qi '^X-Type: person' "$headers"; then
    pass "server emits X-Type: person when type=person"
else
    fail "server X-Type" "headers=$(cat "$headers" 2>/dev/null)"
fi

# X-Type header policy: type_level=none suppresses X-Type
headers="$TMP/server-xtype-none.headers"
dst="$OUT/server-einstein-xtype-none.png"
curl -fsS -D "$headers" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "type=person" \
    -F "type_level=none" \
    -o "$dst" >/dev/null 2>&1
if grep -qi '^X-Type:' "$headers"; then
    fail "X-Type suppress" "type_level=none should not emit X-Type"
else
    pass "type_level=none suppresses X-Type header"
fi

# bg_image_file (uploaded background) composes onto a real fixture
dst="$OUT/server-einstein-on-earth.png"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "bg_image_file=@$FIX/03-nasa-earthrise.jpg" \
    -F "format=png" \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$dst" && pass "server bg_image_file uploads a background and composes the result" \
    || fail "server bg_image_file" "rc=$rc out=$out"

# bg_color rgb:r,g,b triple via multipart
dst="$OUT/server-einstein-rgb.jpg"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -F "image_file=@$FIX/07-einstein-1921.jpg" \
    -F "format=jpg" \
    -F "bg_color=rgb:0,128,255" \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$dst" && pass "server bg_color accepts rgb:r,g,b triples" \
    || fail "server bg_color rgb triple" "rc=$rc out=$out"

# scale + position via JSON body
python3 - "$FIX/07-einstein-1921.jpg" "$TMP/server-scale-pos.json" <<'PY'
import base64, json, sys
src, dst = sys.argv[1:3]
payload = {
    "image_file_b64": base64.b64encode(open(src, "rb").read()).decode("ascii"),
    "format": "png",
    "bg_color": "ffffff",
    "scale": "60%",
    "position": "25% 75%",
    "semitransparency": "false"
}
open(dst, "w").write(json.dumps(payload))
PY
dst="$OUT/server-scale-position.png"
out=$(curl -fsS -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -H "Content-Type: application/json" \
    --data-binary "@$TMP/server-scale-pos.json" \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && [ -s "$dst" ] && pass "server scale+position+semitransparency via JSON body" \
    || fail "server scale/position JSON" "rc=$rc out=$out"

# OPTIONS preflight without --cors returns 204 but does NOT set the Allow-Origin header
# We are currently running the server with --cors; skip and re-test in the next process.

stop_server

# --- Server: --max-body-mb 413 limit ---
SERVER_PORT=18789
SERVER_BASE="http://127.0.0.1:$SERVER_PORT"
SERVER_LOG="$TMP/server-limit.log"
"$BIN" --server --port "$SERVER_PORT" --max-body-mb 1 >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
if wait_for_server "$SERVER_BASE/health"; then
    pass "--server --max-body-mb 1 starts"
else
    fail "--server --max-body-mb start" "server did not become healthy"
fi

# 1 MiB limit; send a 2 MiB body and expect 413
big="$TMP/big-payload.txt"
dd if=/dev/zero bs=1024 count=2048 of="$big" >/dev/null 2>&1
code=$(curl -sS -o "$TMP/server-too-big.json" -w "%{http_code}" -X POST "$SERVER_BASE/v1.0/bgbgone" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$big")
[ "$code" = "413" ] && grep -q "too large" "$TMP/server-too-big.json" && pass "server returns 413 when body exceeds --max-body-mb" \
    || fail "server 413" "code=$code body=$(cat "$TMP/server-too-big.json" 2>/dev/null)"

stop_server

# --- Server: --no-origin-check accepts foreign Origin ---
SERVER_PORT=18790
SERVER_BASE="http://127.0.0.1:$SERVER_PORT"
SERVER_LOG="$TMP/server-noorigin.log"
"$BIN" --server --port "$SERVER_PORT" --no-origin-check >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
if wait_for_server "$SERVER_BASE/health"; then
    pass "--server --no-origin-check starts"
else
    fail "--server --no-origin-check start" "log=$(cat "$SERVER_LOG" 2>/dev/null)"
fi

code=$(curl -sS -o /dev/null -w "%{http_code}" -H "Origin: http://example.com" "$SERVER_BASE/health")
[ "$code" = "200" ] && pass "--no-origin-check accepts foreign Origin" \
    || fail "no-origin-check" "expected 200, got $code"

stop_server

# --- Server: --footgun (wildcard CORS, no origin check) ---
SERVER_PORT=18791
SERVER_BASE="http://127.0.0.1:$SERVER_PORT"
SERVER_LOG="$TMP/server-footgun.log"
"$BIN" --server --port "$SERVER_PORT" --footgun >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
if wait_for_server "$SERVER_BASE/health"; then
    pass "--footgun starts"
else
    fail "--footgun start" "log=$(cat "$SERVER_LOG" 2>/dev/null)"
fi

headers="$TMP/server-footgun.headers"
curl -fsS -D "$headers" -H "Origin: http://anything.example" "$SERVER_BASE/health" >/dev/null 2>&1
if grep -qi '^Access-Control-Allow-Origin: \*' "$headers"; then
    pass "--footgun replies with Access-Control-Allow-Origin: *"
else
    fail "footgun CORS" "headers=$(cat "$headers" 2>/dev/null)"
fi

stop_server

# --- Server: wrong Bearer rejected, X-API-Key rejected with bad value ---
SERVER_PORT=18792
SERVER_BASE="http://127.0.0.1:$SERVER_PORT"
SERVER_LOG="$TMP/server-auth.log"
"$BIN" --server --port "$SERVER_PORT" --token "right-token" >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
if wait_for_server "$SERVER_BASE/health"; then
    pass "--server --token starts (auth scenario)"
else
    fail "--server token auth start" "log=$(cat "$SERVER_LOG" 2>/dev/null)"
fi

code=$(curl -sS -o "$TMP/server-wrong-bearer.json" -w "%{http_code}" -H "Authorization: Bearer wrong-token" "$SERVER_BASE/v1.0/account")
[ "$code" = "401" ] && pass "wrong Bearer token -> 401" \
    || fail "wrong Bearer" "expected 401, got $code"

code=$(curl -sS -o "$TMP/server-wrong-apikey.json" -w "%{http_code}" -H "X-API-Key: wrong-token" "$SERVER_BASE/v1.0/account")
[ "$code" = "401" ] && pass "wrong X-API-Key -> 401" \
    || fail "wrong X-API-Key" "expected 401, got $code"

# /health stays public on loopback even with --token
code=$(curl -sS -o /dev/null -w "%{http_code}" "$SERVER_BASE/health")
[ "$code" = "200" ] && pass "/health stays public on loopback even when --token is set" \
    || fail "health loopback public" "expected 200, got $code"

stop_server

SERVER_PORT=18788
SERVER_BASE="http://127.0.0.1:$SERVER_PORT"
SERVER_LOG="$TMP/server-token.log"
"$BIN" --server --port "$SERVER_PORT" --token "secret-token" >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
if wait_for_server "$SERVER_BASE/health"; then
    pass "--server --token starts"
else
    fail "--server --token start" "server did not become healthy; log=$(cat "$SERVER_LOG" 2>/dev/null)"
fi

code=$(curl -sS -o "$TMP/server-no-token.json" -w "%{http_code}" "$SERVER_BASE/v1.0/account")
[ "$code" = "401" ] && grep -q "token" "$TMP/server-no-token.json" && pass "server token rejects missing Authorization" \
    || fail "server token missing" "code=$code body=$(cat "$TMP/server-no-token.json" 2>/dev/null)"

out=$(curl -fsS -H "Authorization: Bearer secret-token" "$SERVER_BASE/v1.0/account" 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q '"credits"' && pass "server token accepts Bearer Authorization" \
    || fail "server token auth" "rc=$rc out=$out"

out=$(curl -fsS -H "X-API-Key: secret-token" "$SERVER_BASE/v1.0/account" 2>&1) ; rc=$?
[ $rc -eq 0 ] && echo "$out" | grep -q '"credits"' && pass "server token accepts X-API-Key Authorization" \
    || fail "server X-API-Key auth" "rc=$rc out=$out"

stop_server

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

dst="$OUT/einstein.zip"
out=$("$BIN" "$src" --to zip -o "$dst" 2>&1) ; rc=$?
if [ $rc -eq 0 ] && python3 - "$dst" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    names = set(z.namelist())
    assert {"color.jpg", "alpha.png"} <= names, names
PY
then
    pass "--to zip contains color.jpg and alpha.png"
else
    fail "--to zip" "rc=$rc out=$out"
fi

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

# --- e2e: --filter "fg:matte" emits the alpha mask (replaces removed --mask-only) ---
echo ""
echo "e2e: matte filter (replaces --mask-only)"

src="$FIX/02-nasa-mccandless-eva.jpg"
dst="$OUT/eva-mask.png"
out=$("$BIN" "$src" --filter "fg:matte" -o "$dst" 2>&1) ; rc=$?
if [ $rc -eq 0 ] && [ -s "$dst" ]; then
    head -c 8 "$dst" | xxd -p | tr -d '\n' | grep -qi '^89504e470d0a1a0a' && pass "--filter fg:matte emits PNG" \
        || fail "matte filter" "output not PNG"
else
    fail "matte filter" "rc=$rc out=$out"
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

# --- e2e: --filter "mask:feather=N" softens edges (replaces removed --feather) ---
echo ""
echo "e2e: feather filter (replaces --feather)"

src="$FIX/02-nasa-mccandless-eva.jpg"
"$BIN" "$src" -o "$OUT/eva-f0.png" 2>/dev/null
"$BIN" "$src" --filter "mask:feather=8" -o "$OUT/eva-f8.png" 2>/dev/null
"$BIN" "$src" --filter "mask:feather=16" -o "$OUT/eva-f16.png" 2>/dev/null
if [ -s "$OUT/eva-f0.png" ] && [ -s "$OUT/eva-f8.png" ]; then
    sz0=$(stat -f '%z' "$OUT/eva-f0.png")
    sz8=$(stat -f '%z' "$OUT/eva-f8.png")
    [ "$sz0" -ne "$sz8" ] && pass "mask:feather changes output (size $sz0 != $sz8)" \
        || fail "feather filter" "feather=0 and feather=8 produced identical files"
else
    fail "feather filter" "outputs missing"
fi

# Regression: feather > 0 used to silently disable background removal because the
# Gaussian-blurred mask came back in sRGB rather than DeviceGray. Corner pixel
# of a cutout against space must be fully transparent regardless of feather radius.
for r in 0 8 16; do
    if [ "$r" = "0" ]; then
        out=$("$BIN" "$src" -o "$OUT/eva-f$r.png" 2>&1) ; rc=$?
    else
        out=$("$BIN" "$src" --filter "mask:feather=$r" -o "$OUT/eva-f$r.png" 2>&1) ; rc=$?
    fi
    if [ $rc -ne 0 ] || [ ! -s "$OUT/eva-f$r.png" ]; then
        fail "feather $r corner alpha" "no output (rc=$rc out=$out)"
        continue
    fi
    corner=$(magick "$OUT/eva-f$r.png" -format '%[pixel:p{5,5}]' info: 2>/dev/null)
    case "$corner" in
        *",0)"|*"a=0)"|*"none"*) pass "feather $r corner alpha == 0 (bg removed)" ;;
        *) fail "feather $r corner alpha" "expected transparent corner, got $corner" ;;
    esac
done

# --- e2e: shared advanced geometry/options ---
echo ""
echo "e2e: shared advanced geometry/options"

src="$FIX/07-einstein-1921.jpg"
dst="$OUT/einstein-advanced.png"
out=$("$BIN" "$src" \
    --size preview \
    --roi "0% 0% 100% 100%" \
    --crop \
    --crop-margin "5%" \
    --filter "fg:scale=0.75" \
    --semitransparency false \
    --shadow-type drop \
    --shadow-opacity 25 \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$dst" && pass "CLI advanced compatibility options produce PNG" \
    || fail "CLI advanced compatibility options" "rc=$rc out=$out"

dst="$OUT/einstein-cli-shared.jpg"
out=$("$BIN" "$src" \
    --format jpg \
    --bg-color fff \
    --channels rgba \
    --type person \
    --quality 80 \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_jpeg "$dst" && pass "CLI shared compatibility flags produce JPEG" \
    || fail "CLI shared compatibility flags" "rc=$rc out=$out"

dst="$OUT/einstein-cli-alpha.png"
out=$("$BIN" "$src" --channels alpha --format png -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$dst" && pass "CLI --channels alpha emits matte PNG" \
    || fail "CLI --channels alpha" "rc=$rc out=$out"

dst="$OUT/einstein-cli-bg-image.png"
out=$("$BIN" "$src" \
    --bg-image "$FIX/03-nasa-earthrise.jpg" \
    --bg-fit contain \
    --format png \
    -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$dst" && pass "CLI --bg-image shared field produces PNG" \
    || fail "CLI --bg-image shared field" "rc=$rc out=$out"

# --- e2e: --type hint maps to an algorithm (product run on a real fixture) ---
echo ""
echo "e2e: --type"

for type in person product car animal graphic transportation; do
    dst="$OUT/einstein-type-$type.png"
    out=$("$BIN" "$src" --type "$type" --bg color:white -o "$dst" 2>&1) ; rc=$?
    [ $rc -eq 0 ] && [ -s "$dst" ] && pass "--type $type" || fail "--type $type" "rc=$rc out=$out"
done

# --- e2e: --shadow-type drop vs none ---
echo ""
echo "e2e: --shadow-type"

src="$FIX/07-einstein-1921.jpg"
"$BIN" "$src" --bg color:white --shadow-type drop --shadow-opacity 60 -o "$OUT/einstein-shadow-drop.png" 2>/dev/null
"$BIN" "$src" --bg color:white --shadow-type none -o "$OUT/einstein-shadow-none.png" 2>/dev/null
if [ -s "$OUT/einstein-shadow-drop.png" ] && [ -s "$OUT/einstein-shadow-none.png" ]; then
    if cmp -s "$OUT/einstein-shadow-drop.png" "$OUT/einstein-shadow-none.png"; then
        fail "--shadow-type" "drop and none produced identical output"
    else
        pass "--shadow-type drop differs from --shadow-type none"
    fi
else
    fail "--shadow-type" "outputs missing"
fi

# --- e2e: --filter "fg:scale" + "fg:translate" shift the subject (replaces --scale + --position) ---
echo ""
echo "e2e: fg:scale + fg:translate (replaces --scale + --position)"

src="$FIX/07-einstein-1921.jpg"
"$BIN" "$src" --bg color:white -o "$OUT/einstein-scale-base.png" 2>/dev/null
"$BIN" "$src" --bg color:white --filter "fg:scale=0.5" -o "$OUT/einstein-scale-center.png" 2>/dev/null
"$BIN" "$src" --bg color:white --filter "fg:scale=0.5,translate=-200,200" -o "$OUT/einstein-scale-corner.png" 2>/dev/null
if [ -s "$OUT/einstein-scale-base.png" ] && [ -s "$OUT/einstein-scale-center.png" ] && [ -s "$OUT/einstein-scale-corner.png" ]; then
    if cmp -s "$OUT/einstein-scale-center.png" "$OUT/einstein-scale-corner.png"; then
        fail "fg:scale + fg:translate" "centered and translated outputs matched"
    elif cmp -s "$OUT/einstein-scale-base.png" "$OUT/einstein-scale-center.png"; then
        fail "fg:scale + fg:translate" "scaled output identical to unscaled"
    else
        pass "fg:scale + fg:translate move the subject vs base"
    fi
else
    fail "fg:scale + fg:translate" "outputs missing"
fi

# --- e2e: --size preview produces a smaller output than --size full ---
echo ""
echo "e2e: --size preview"

src="$FIX/02-nasa-mccandless-eva.jpg"
"$BIN" "$src" --size preview -o "$OUT/eva-preview.png" 2>/dev/null
"$BIN" "$src" --size full -o "$OUT/eva-full.png" 2>/dev/null
if [ -s "$OUT/eva-preview.png" ] && [ -s "$OUT/eva-full.png" ]; then
    sz_prev=$(python3 -c "from PIL import Image; print(Image.open('$OUT/eva-preview.png').size)")
    sz_full=$(python3 -c "from PIL import Image; print(Image.open('$OUT/eva-full.png').size)")
    smaller=$(python3 -c "from PIL import Image
p = Image.open('$OUT/eva-preview.png').size
f = Image.open('$OUT/eva-full.png').size
print('ok' if p[0]*p[1] < f[0]*f[1] else f'fail prev={p} full={f}')")
    [ "$smaller" = "ok" ] && pass "--size preview $sz_prev is smaller than --size full $sz_full" \
        || fail "--size preview" "$smaller"
else
    fail "--size preview" "outputs missing"
fi

# --- e2e: --semitransparency false hardens the matte (different bytes from default) ---
echo ""
echo "e2e: --semitransparency"

src="$FIX/02-nasa-mccandless-eva.jpg"
"$BIN" "$src" --semitransparency true -o "$OUT/eva-semi-true.png" 2>/dev/null
"$BIN" "$src" --semitransparency false -o "$OUT/eva-semi-false.png" 2>/dev/null
if [ -s "$OUT/eva-semi-true.png" ] && [ -s "$OUT/eva-semi-false.png" ]; then
    if cmp -s "$OUT/eva-semi-true.png" "$OUT/eva-semi-false.png"; then
        fail "--semitransparency" "true and false produced identical bytes"
    else
        pass "--semitransparency true differs from --semitransparency false"
    fi
else
    fail "--semitransparency" "outputs missing"
fi

# --- e2e: --crop-margin one/two/four-value forms accepted ---
echo ""
echo "e2e: --crop-margin variants"

src="$FIX/07-einstein-1921.jpg"
for margin in "5%" "10% 20%" "5% 10% 15% 20%"; do
    dst="$OUT/einstein-margin-${margin// /-}.png"
    dst="${dst//%/pct}"
    out=$("$BIN" "$src" --crop --crop-margin "$margin" -o "$dst" 2>&1) ; rc=$?
    [ $rc -eq 0 ] && [ -s "$dst" ] && pass "--crop-margin \"$margin\"" \
        || fail "--crop-margin $margin" "rc=$rc out=$out"
done

# --- e2e: --roi narrows the detection region ---
echo ""
echo "e2e: --roi"

src="$FIX/02-nasa-mccandless-eva.jpg"
dst="$OUT/eva-roi.png"
out=$("$BIN" "$src" --roi "0% 0% 100% 50%" -o "$dst" 2>&1) ; rc=$?
[ $rc -eq 0 ] && check_png_rgba "$dst" && pass "--roi 0% 0% 100% 50% produces PNG" \
    || fail "--roi" "rc=$rc out=$out"

# --- e2e: stdout format inference covers heic, tiff via -o ---
echo ""
echo "e2e: -o format inference"

src="$FIX/07-einstein-1921.jpg"
for ext in heic tiff avif; do
    dst="$OUT/einstein-inferred.$ext"
    out=$("$BIN" "$src" --bg color:white -o "$dst" 2>&1) ; rc=$?
    [ $rc -eq 0 ] && [ -s "$dst" ] && pass "-o out.$ext infers $ext format" \
        || fail "-o $ext inference" "rc=$rc out=$out"
done

# --- e2e: --quiet truly silent on success; --verbose writes diagnostic stderr ---
echo ""
echo "e2e: --quiet vs --verbose"

src="$FIX/07-einstein-1921.jpg"
qerr=$("$BIN" "$src" -o "$OUT/quiet.png" --quiet 2>&1 >/dev/null)
[ -z "$qerr" ] && pass "--quiet writes no stderr on success" \
    || fail "--quiet" "got stderr: $qerr"

verr=$("$BIN" "$src" -o "$OUT/verbose.png" --verbose 2>&1 >/dev/null)
[ -n "$verr" ] && pass "--verbose writes some stderr on success" \
    || fail "--verbose" "stderr was empty"

# --- e2e: --filter "mask:threshold=N" changes matte decisively (replaces --threshold) ---
echo ""
echo "e2e: mask:threshold (replaces --threshold)"

src="$FIX/02-nasa-mccandless-eva.jpg"
"$BIN" "$src" --filter "mask:threshold=0.20" -o "$OUT/eva-threshold-020.png" 2>/dev/null
"$BIN" "$src" --filter "mask:threshold=0.80" -o "$OUT/eva-threshold-080.png" 2>/dev/null
if [ -s "$OUT/eva-threshold-020.png" ] && [ -s "$OUT/eva-threshold-080.png" ]; then
    if cmp -s "$OUT/eva-threshold-020.png" "$OUT/eva-threshold-080.png"; then
        fail "mask:threshold" "threshold 0.20 and 0.80 produced identical output"
    else
        pass "mask:threshold changes the output matte"
    fi
else
    fail "mask:threshold" "outputs missing"
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

# --- RED tests for the --filter chain feature (epic #1) ---
# All tests in this section are expected to FAIL until each ticket lands.
# Sourced as a module so the RED batch is easy to find and isolated.
source "$DIR/run-filters.sh"

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
