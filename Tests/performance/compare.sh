#!/bin/bash
# Compare a current perf run against Tests/performance/baseline.json.
# Asserts each fixture's no_filter_ms is within +2% of the baseline value.
# Exits 0 on success, 1 on regression.

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
BASELINE="$DIR/baseline.json"
CURRENT="${1:-$DIR/current.json}"

if [ ! -f "$BASELINE" ]; then
    echo "compare.sh: baseline.json not found at $BASELINE" >&2
    exit 1
fi
if [ ! -f "$CURRENT" ]; then
    echo "compare.sh: current.json not found at $CURRENT" >&2
    echo "compare.sh: pass it as the first arg, or run perf-100 to capture one." >&2
    exit 1
fi

# Per-fixture comparison: parse JSON via jq if present, else fall back to grep+awk.
if ! command -v jq >/dev/null 2>&1; then
    echo "compare.sh: jq is required for full comparison" >&2
    exit 1
fi

FAILS=0
for fixture in $(jq -r '.fixtures | keys[]' "$BASELINE"); do
    base_ms=$(jq -r ".fixtures[\"$fixture\"].no_filter_ms" "$BASELINE")
    cur_ms=$(jq -r ".fixtures[\"$fixture\"].no_filter_ms // empty" "$CURRENT")
    if [ -z "$cur_ms" ] || [ "$cur_ms" = "null" ]; then
        echo "compare.sh: $fixture missing in current run" >&2
        FAILS=$((FAILS + 1))
        continue
    fi
    threshold=$(echo "$base_ms * 1.02" | bc -l)
    over=$(echo "$cur_ms > $threshold" | bc -l)
    if [ "$over" = "1" ]; then
        echo "REGRESSION: $fixture current=${cur_ms}ms > baseline+2%=${threshold}ms" >&2
        FAILS=$((FAILS + 1))
    else
        echo "OK: $fixture current=${cur_ms}ms <= baseline+2%=${threshold}ms"
    fi
done

if [ "$FAILS" -gt 0 ]; then
    echo "compare.sh: $FAILS regression(s)" >&2
    exit 1
fi
echo "compare.sh: no regressions"
exit 0
