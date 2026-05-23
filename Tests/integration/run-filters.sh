#!/bin/bash
# RED tests for the --filter chain feature (epic #1).
# Sourced from run.sh; shares $BIN, $FIX, $OUT, $TMP, pass(), fail(), check_png_rgba().
#
# Every test in this file is expected to FAIL until its corresponding ticket
# is implemented. This is the RED phase of TDD (red -> green -> refactor).
# Each test references its ticket number as the test name.
#
# Convention: "TNN #M ..." where TNN is the plan ticket id and #M is the
# GitHub issue number (https://github.com/Arthur-Ficial/bgbgone/issues/M).

# Default fixture for filter tests: easy person on lunar surface.
RED_FIX="$FIX/01-nasa-aldrin-moon.jpg"

# Helper: run a CLI invocation, assert exit 0 and a valid RGBA PNG.
# Usage: red_filter <ticket-id> <issue#> <filter-string> <output-stem>
red_filter() {
    local id="$1" issue="$2" spec="$3" stem="$4"
    local png="$OUT/$stem.png"
    local out
    out=$("$BIN" "$RED_FIX" --filter "$spec" -o "$png" 2>&1); local rc=$?
    if [ $rc -eq 0 ] && check_png_rgba "$png"; then
        pass "$id #$issue filter \"$spec\""
    else
        fail "$id #$issue filter \"$spec\"" "rc=$rc out=$(echo "$out" | head -1)"
    fi
}

# Helper: assert a CLI invocation FAILS with exit code 2 (removal tickets).
# Usage: red_removed <ticket-id> <issue#> <flag> <args...>
red_removed() {
    local id="$1" issue="$2" flag="$3"
    shift 3
    local out
    out=$("$BIN" "$RED_FIX" "$flag" "$@" -o "$OUT/removed-$id.png" 2>&1); local rc=$?
    # RED: today the flag still works (rc=0), test wants rc=2 (flag removed).
    if [ $rc -eq 2 ]; then
        pass "$id #$issue $flag removed"
    else
        fail "$id #$issue $flag removed" "rc=$rc (flag still works)"
    fi
}

echo ""
echo "filter chain RED tests (epic #1)"

# --- Foundation: T0..T4 ---

# T0 #2: swift-argument-parser migration -- --help has typed --filter option.
out=$("$BIN" --help 2>&1); rc=$?
if [ $rc -eq 0 ] && printf '%s' "$out" | grep -qE -- '--filter\b'; then
    pass "T0 #2 --help mentions --filter (swift-argument-parser)"
else
    fail "T0 #2 --help mentions --filter" "rc=$rc"
fi

# T1 #3: filter DSL parser -- --filter accepted at CLI level.
out=$("$BIN" "$RED_FIX" --filter "bg:grayscale" -o "$OUT/t1.png" 2>&1); rc=$?
if [ $rc -eq 0 ] && check_png_rgba "$OUT/t1.png"; then
    pass "T1 #3 --filter accepted by parser"
else
    fail "T1 #3 --filter accepted by parser" "rc=$rc out=$(echo "$out" | head -1)"
fi

# T2 #4: filter registry -- unknown filter exits 2 with diagnostic mentioning the name.
out=$("$BIN" "$RED_FIX" --filter "bg:zzz-no-such-filter" -o "$OUT/t2.png" 2>&1); rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -qi "zzz-no-such-filter"; then
    pass "T2 #4 registry rejects unknown filter with diagnostic"
else
    fail "T2 #4 registry rejects unknown filter" "rc=$rc out=$(echo "$out" | head -1)"
fi

# T3 #5: deferred-flatten refactor invariant -- empty filter chain equals no filter.
out=$("$BIN" "$RED_FIX" -o "$OUT/t3-baseline.png" 2>&1); rc1=$?
out2=$("$BIN" "$RED_FIX" --filter "" -o "$OUT/t3-empty.png" 2>&1); rc2=$?
if [ $rc1 -eq 0 ] && [ $rc2 -eq 0 ] && cmp -s "$OUT/t3-baseline.png" "$OUT/t3-empty.png"; then
    pass "T3 #5 empty filter chain == no filter (deferred-flatten invariant)"
else
    fail "T3 #5 empty filter chain invariant" "rc1=$rc1 rc2=$rc2"
fi

# T4 #6: perf baseline file exists.
if [ -f "$ROOT/performance/baseline.json" ] || [ -f "$ROOT/../Tests/performance/baseline.json" ]; then
    pass "T4 #6 perf baseline.json checked in"
else
    fail "T4 #6 perf baseline.json checked in" "Tests/performance/baseline.json not found"
fi

# --- Filters T5..T53 (one test per filter, all RED) ---

# Tone & colour
red_filter "T5"  "7"  "bg:grayscale"                                        "t05-grayscale"
red_filter "T6"  "8"  "bg:desaturate=0.5"                                   "t06-desaturate"
red_filter "T7"  "9"  "bg:negate"                                           "t07-negate"
red_filter "T8"  "10" "bg:sepia=intensity=0.8"                              "t08-sepia"
red_filter "T9"  "11" "bg:adjust=brightness=0.1:contrast=1.1:saturation=0.9" "t09-adjust"
red_filter "T10" "12" "bg:gamma=1.2"                                        "t10-gamma"
red_filter "T11" "13" "bg:exposure=1.0"                                     "t11-exposure"
red_filter "T12" "14" "bg:hue=120"                                          "t12-hue"
red_filter "T13" "15" "bg:tint=color=#0066ff:amount=0.3"                    "t13-tint"
red_filter "T14" "16" "bg:colorize=color=#ff0000:amount=0.5"                "t14-colorize"
red_filter "T15" "17" "bg:temperature=6500"                                 "t15-temperature"
red_filter "T16" "18" "bg:levels=black=20:white=235:gamma=1.0"              "t16-levels"
red_filter "T17" "19" "bg:vibrance=0.5"                                     "t17-vibrance"
red_filter "T18" "20" "fg:opacity=0.7"                                      "t18-opacity"
red_filter "T19" "21" "bg:duotone=dark=#000080:light=#ffe000"               "t19-duotone"

# Spatial
red_filter "T20" "22" "bg:blur=15"                                          "t20-blur"
red_filter "T21" "23" "bg:box-blur=10"                                      "t21-box-blur"
red_filter "T22" "24" "bg:motion-blur=radius=10:angle=45"                   "t22-motion-blur"
red_filter "T23" "25" "bg:zoom-blur=center=0.5,0.5:amount=20"               "t23-zoom-blur"
red_filter "T24" "26" "fg:sharpen=0.5"                                      "t24-sharpen"
red_filter "T25" "27" "fg:unsharp=radius=2.5:intensity=0.5"                 "t25-unsharp"

# Stylise
red_filter "T26" "28" "all:posterize=4"                                     "t26-posterize"
red_filter "T27" "29" "bg:pixelate=20"                                      "t27-pixelate"
red_filter "T28" "30" "all:edges=intensity=1.0"                             "t28-edges"
red_filter "T29" "31" "all:edge-work=3"                                     "t29-edge-work"
red_filter "T30" "32" "all:emboss"                                          "t30-emboss"
red_filter "T31" "33" "bg:crystallize=20"                                   "t31-crystallize"
red_filter "T32" "34" "bg:pointillize=5"                                    "t32-pointillize"
red_filter "T33" "35" "all:comic"                                           "t33-comic"
red_filter "T34" "36" "all:noise=0.1"                                       "t34-noise"

# Composite-only (refuses fg:/bg: at parse time)
red_filter "T35" "37" "vignette=intensity=0.5:radius=1.5"                   "t35-vignette"
red_filter "T36" "38" "vignette-effect=center=0.5,0.5:radius=1.5"           "t36-vignette-effect"
red_filter "T37" "39" "bloom=intensity=0.5:radius=10"                       "t37-bloom"
red_filter "T38" "40" "gloom=intensity=0.5:radius=10"                       "t38-gloom"

# Also assert parse-time refusal for layer prefix on composite-only filters.
out=$("$BIN" "$RED_FIX" --filter "fg:vignette=10" -o "$OUT/t35-bad.png" 2>&1); rc=$?
if [ $rc -eq 2 ] && printf '%s' "$out" | grep -qi "vignette"; then
    pass "T35 #37 composite-only filter refuses fg: prefix"
else
    fail "T35 #37 composite-only filter refuses fg: prefix" "rc=$rc"
fi

# Mask-aware fg
red_filter "T39" "41" "fg:outline=color=#ffffff:width=3"                    "t39-outline"
red_filter "T40" "42" "fg:glow=color=#ffe080:radius=10:intensity=0.6"       "t40-glow"
red_filter "T41" "43" "fg:shadow=blur=12:offset=4,4:opacity=0.5:color=#000" "t41-shadow"
red_filter "T42" "44" "fg:inner-shadow=blur=6:offset=2,2:opacity=0.5:color=#000" "t42-inner-shadow"
red_filter "T43" "45" "fg:silhouette=color=#ff0000"                         "t43-silhouette"
red_filter "T44" "46" "fg:cutout"                                           "t44-cutout"
red_filter "T45" "47" "fg:matte"                                            "t45-matte"

# Geometric fg
red_filter "T46" "48" "fg:scale=1.2"                                        "t46-scale"
red_filter "T47" "49" "fg:translate=10,-5"                                  "t47-translate"
red_filter "T48" "50" "fg:rotate=15"                                        "t48-rotate"
red_filter "T49" "51" "fg:flip=horizontal"                                  "t49-flip"

# Mask-shape (mask:)
red_filter "T50" "52" "mask:feather=5"                                      "t50-feather"
red_filter "T51" "53" "mask:threshold=0.5"                                  "t51-threshold"
red_filter "T52" "54" "mask:expand=3"                                       "t52-expand"
red_filter "T53" "55" "mask:contract=3"                                     "t53-contract"

# --- Removals T54..T56 (hard-cut: today the flag still works, RED until removed) ---

red_removed "T54" "56" "--scale" "80%"
red_removed "T54" "56" "--position" "center"
red_removed "T55" "57" "--feather" "5"
red_removed "T55" "57" "--threshold" "0.5"
red_removed "T56" "58" "--mask-only"

# --- Housekeeping T57..T61 ---

# T57 #59: JPEG + alpha-producing filter -> exit 1 with helpful diagnostic.
out=$("$BIN" "$RED_FIX" --filter "fg:outline=color=#fff:width=3" -o "$OUT/t57.jpg" 2>&1); rc=$?
if [ $rc -eq 1 ] && printf '%s' "$out" | grep -qi -E "(jpeg|alpha|png)"; then
    pass "T57 #59 JPEG + alpha filter refused with diagnostic"
else
    fail "T57 #59 JPEG + alpha filter refused" "rc=$rc out=$(echo "$out" | head -1)"
fi

# T58 #60: --filters-list discovery command.
out=$("$BIN" --filters-list 2>&1); rc=$?
if [ $rc -eq 0 ] && printf '%s' "$out" | grep -q "grayscale" && printf '%s' "$out" | grep -q "blur"; then
    pass "T58 #60 --filters-list lists registered filters"
else
    fail "T58 #60 --filters-list" "rc=$rc"
fi

# T59 #61: HTTP server accepts `filter` form field.
# Start a temporary local server.
PORT=18790
"$BIN" --server --host 127.0.0.1 --port $PORT --no-origin-check >/dev/null 2>&1 &
SERVER_PID=$!
if wait_for_server "http://127.0.0.1:$PORT/v1.0/bgbgone" >/dev/null 2>&1; then
    dst="$OUT/t59-server.png"
    out=$(curl -fsS -X POST "http://127.0.0.1:$PORT/v1.0/bgbgone" \
        -F "image_file=@$RED_FIX" -F "format=png" -F "filter=bg:grayscale" \
        -o "$dst" 2>&1); rc=$?
    if [ $rc -eq 0 ] && check_png_rgba "$dst"; then
        pass "T59 #61 HTTP /v1.0/bgbgone accepts filter form field"
    else
        fail "T59 #61 HTTP filter form field" "rc=$rc out=$out"
    fi
    stop_server
else
    fail "T59 #61 HTTP filter form field" "server failed to start on port $PORT"
    stop_server
fi

# T60 #62: docs/design.md mentions the filter chain.
if [ -f "$PROJECT_ROOT/docs/design.md" ] && \
   grep -qi "filter" "$PROJECT_ROOT/docs/design.md" && \
   grep -q -- "--filter" "$PROJECT_ROOT/docs/design.md"; then
    pass "T60 #62 docs/design.md documents --filter"
else
    fail "T60 #62 docs/design.md documents --filter" "missing or empty"
fi

# T61 #63: out-of-scope register file exists with the expected entries.
if [ -f "$PROJECT_ROOT/docs/filters-out-of-scope.md" ] && \
   grep -qi "plugin" "$PROJECT_ROOT/docs/filters-out-of-scope.md"; then
    pass "T61 #63 docs/filters-out-of-scope.md present with content"
else
    fail "T61 #63 docs/filters-out-of-scope.md present" "missing or empty"
fi
