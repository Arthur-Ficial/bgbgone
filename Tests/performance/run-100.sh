#!/bin/bash
# 100-image performance scenario for bgbgone.
# Run: bash Tests/performance/run-100.sh [path/to/bgbgone-binary]

set -euo pipefail

BIN="${1:-bgbgone}"
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
FIX="$ROOT/fixtures"
WORK="$DIR/_tmp_100"
IN="$WORK/in"
OUT="$WORK/out"

rm -rf "$WORK"
mkdir -p "$IN" "$OUT"

fixtures=("$FIX"/*.jpg)
if [ "${#fixtures[@]}" -eq 0 ]; then
    echo "error: no fixtures found in $FIX" >&2
    exit 1
fi

for i in $(seq 1 100); do
    src="${fixtures[$(( (i - 1) % ${#fixtures[@]} ))]}"
    printf -v n "%03d" "$i"
    ln -s "$src" "$IN/perf-$n-$(basename "$src")"
done

mapfile -t inputs < <(find "$IN" -type l -name '*.jpg' | sort)

start=$(python3 - <<'PY'
import time
print(time.perf_counter())
PY
)

"$BIN" "${inputs[@]}" --out-dir "$OUT" --quiet

end=$(python3 - <<'PY'
import time
print(time.perf_counter())
PY
)

count=$(find "$OUT" -type f -name '*.png' | wc -l | tr -d ' ')
if [ "$count" -ne 100 ]; then
    echo "error: expected 100 outputs, got $count" >&2
    exit 1
fi

python3 - <<PY
from pathlib import Path
start = float("$start")
end = float("$end")
out = Path("$OUT")
total_bytes = sum(p.stat().st_size for p in out.glob("*.png"))
elapsed = max(end - start, 0.000001)
print("bgbgone 100-image performance")
print(f"  binary:        $BIN")
print(f"  inputs:        100 fixture-backed symlinks")
print(f"  outputs:       {out}")
print(f"  elapsed:       {elapsed:.3f}s")
print(f"  throughput:    {100 / elapsed:.2f} images/s")
print(f"  avg latency:   {elapsed * 1000 / 100:.1f} ms/image")
print(f"  output bytes:  {total_bytes:,}")
PY
