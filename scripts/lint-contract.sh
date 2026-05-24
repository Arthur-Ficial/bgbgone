#!/bin/bash
# Lint the public CLI/server contract for KISS/DRY/SSOT drift.
#
# This is intentionally grep-based: it catches the cheap regressions that make
# the surface stop being one way to do things. Deeper syntax validation stays in
# lint-docs.sh, which runs real filter chains through the binary.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fails=0

fail() {
    echo "  FAIL $1"
    fails=$((fails + 1))
}

check_no_public_pattern() {
    local label="$1"
    local pattern="$2"
    local matches
    matches=$(grep -RInE -- "$pattern" \
        "$ROOT/README.md" \
        "$ROOT/docs" \
        "$ROOT/Sources/CLI.swift" \
        "$ROOT/Sources/Core/BgBgOneCommand.swift" \
        "$ROOT/Sources/Core/ServerRemovalRequest.swift" \
        "$ROOT/Sources/Server.swift" 2>/dev/null || true)
    if [ -n "$matches" ]; then
        fail "$label"
        echo "$matches" | sed 's/^/       /'
    fi
}

check_contains() {
    local label="$1"
    local file="$2"
    local pattern="$3"
    if ! grep -qE -- "$pattern" "$ROOT/$file"; then
        fail "$label ($file)"
    fi
}

check_count() {
    local label="$1"
    local expected="$2"
    local file="$3"
    local pattern="$4"
    local count
    count=$(grep -cE -- "$pattern" "$ROOT/$file" || true)
    if [ "$count" -ne "$expected" ]; then
        fail "$label: expected $expected, got $count ($file)"
    fi
}

echo "lint-contract: checking one canonical CLI/server surface ..."

check_no_public_pattern "removed CLI alias leaked into public surface" '--bg-color|--bg-image|(^|[^[:alnum:]_-])--to([^[:alnum:]_-]|$)|(^|[^[:alnum:]_-])--algo([^[:alnum:]_-]|$)|(^|[^[:alnum:]_-])--padding([^[:alnum:]_-]|$)|(^|[^[:alnum:]_-])--shadow([^[:alnum:]_-]|$)'
check_no_public_pattern "removed HTTP field leaked into public surface" 'image_file_b64|bg_b64|bg_color|bg_image|image_url|bg_url'
# `algo`, `padding`, and `shadow` HTTP REQUEST fields were collapsed into
# `type`, `crop-margin`, and `shadow-type`. Catch curl form fields and JSON
# REQUEST keys, but the SUCCESS-response `"algo":"vn-mask"` field is legitimate
# (the response tells the user which Vision algorithm actually ran).
check_no_public_pattern "removed HTTP request field algo= leaked into public surface" '-F algo=|-d.*"algo"[[:space:]]*:'
check_no_public_pattern "removed HTTP request field padding= leaked into public surface" '-F padding=|-d.*"padding"[[:space:]]*:'
check_no_public_pattern "removed HTTP request field shadow=true/false leaked into public surface" '-F shadow=(true|false|yes|no|on|off)|-d.*"shadow"[[:space:]]*:[[:space:]]*"(true|false|yes|no|on|off)"'
check_no_public_pattern "removed HTTP compatibility route leaked into public surface" '/v1\.0/bgbgone|/v1\.0/account|(^|[^[:alnum:]_-])/account([^[:alnum:]_-]|$)|(^|[^[:alnum:]_-])/improve([^[:alnum:]_-]|$)'
check_no_public_pattern "not-implementable placeholder leaked into public surface" 'NOT IMPLEMENTABLE|not_implementable|result_b64'
check_no_public_pattern "legacy compatibility wording leaked into public surface" 'compatibility|Compatibility|compat '
check_no_public_pattern "composite-only filter leaked without composite: layer" 'all:(vignette|vignette-effect|bloom|gloom)|;[[:space:]]*(vignette|vignette-effect|bloom|gloom)='

check_count "single --bg option declaration" 1 "Sources/Core/BgBgOneCommand.swift" 'customLong\("bg"\)'
check_count "single --format option declaration" 1 "Sources/Core/BgBgOneCommand.swift" 'customLong\("format"\)'
check_count "single --type option declaration (no --algo duplicate)" 1 "Sources/Core/BgBgOneCommand.swift" 'customLong\("type"\)'
check_count "no --algo option declaration (collapsed into --type)" 0 "Sources/Core/BgBgOneCommand.swift" 'customLong\("algo"\)'
check_count "no --padding option declaration (collapsed into --crop-margin)" 0 "Sources/Core/BgBgOneCommand.swift" 'customLong\("padding"\)'
check_count "no --shadow flag declaration (collapsed into --shadow-type)" 0 "Sources/Core/BgBgOneCommand.swift" 'customLong\("shadow"\)'
check_count "single --crop-margin option declaration" 1 "Sources/Core/BgBgOneCommand.swift" 'customLong\("crop-margin"\)'
check_count "single --shadow-type option declaration" 1 "Sources/Core/BgBgOneCommand.swift" 'customLong\("shadow-type"\)'
check_contains "server background uses shared parser" "Sources/Core/ServerRemovalRequest.swift" 'ConfigBuilder\.parseBackground\(bg\)'
check_contains "server filter uses shared parser" "Sources/Core/ServerRemovalRequest.swift" 'FilterParser\.parse\(raw\)'
check_contains "server filter uses shared registry" "Sources/Core/ServerRemovalRequest.swift" 'FilterRegistry\.validate\(chain\)'
check_contains "CLI/server field parsing uses neutral parser" "Sources/Core/ConfigBuilderFlags.swift" 'ParameterParser\.parseROI'
check_contains "server request field parsing uses neutral parser" "Sources/Core/ServerRemovalRequest.swift" 'ParameterParser\.parseROI'
check_contains "help uses output-format SSOT" "Sources/CLI.swift" 'CLIContract\.outputFormats'
check_contains "server config uses host SSOT" "Sources/Core/Config.swift" 'CLIContract\.serverDefaultHost'
check_contains "server config uses port SSOT" "Sources/Core/Config.swift" 'CLIContract\.serverDefaultPort'
check_contains "server config uses body-limit SSOT" "Sources/Core/Config.swift" 'CLIContract\.serverDefaultMaxBodyMB'

tmp="${TMPDIR:-/tmp}/bgbgone-contract-lint.$$"
if grep -RInE 'ServerCompatibility|ServerFieldParser|ServerAPIError|ServerRectSpec|ServerEdgeInsets|ServerDimension|parseScale|parsePosition|parseFeather|parseThreshold' "$ROOT/Sources" >"$tmp" 2>/dev/null; then
    fail "dead compatibility parser path remains in Sources"
    sed 's/^/       /' "$tmp"
fi
rm -f "$tmp"

if grep -RInE 'aliases:|let aliases|entry\.aliases' "$ROOT/Sources/Core/FilterRegistry.swift" "$ROOT/Sources/CLI.swift" >"$tmp" 2>/dev/null; then
    fail "filter alias plumbing remains in canonical surface"
    sed 's/^/       /' "$tmp"
fi
rm -f "$tmp"

if [ "$fails" -gt 0 ]; then
    echo "lint-contract: $fails failure(s)" >&2
    exit 1
fi

echo "lint-contract: OK"
