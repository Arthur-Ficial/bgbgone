#!/bin/bash
# 5x100-image performance scenario for bgbgone.
# Run: bash Tests/performance/run-100.sh [path/to/bgbgone-binary]

set -euo pipefail

BIN="${1:-bgbgone}"
DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_ROOT="$(cd "$DIR/.." && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
source "$REPO_ROOT/scripts/trash.sh"
FIX="$TEST_ROOT/fixtures"
WORK="$DIR/_tmp_100"
IN="$WORK/in"
OUT="$WORK/out"
STATS="$WORK/stats.tsv"
README="$REPO_ROOT/README.md"
RUNS=5

trash_path "$WORK"
mkdir -p "$IN" "$OUT"
: > "$STATS"

# Subject fixtures only - background-plate fixtures (matterhorn, nebulae)
# have no foreground subject and would fail with BGBG_NORESULT_NO_SUBJECT.
BG_PLATES_RE='matterhorn-sunset|nebula-flaming-star|nebula-flying-dragon'
fixtures=()
for f in "$FIX"/*.jpg; do
    base=$(basename "$f" .jpg)
    [[ "$base" =~ $BG_PLATES_RE ]] && continue
    fixtures+=("$f")
done
if [ "${#fixtures[@]}" -eq 0 ]; then
    echo "error: no fixtures found in $FIX" >&2
    exit 1
fi

for i in $(seq 1 100); do
    src="${fixtures[$(( (i - 1) % ${#fixtures[@]} ))]}"
    printf -v n "%03d" "$i"
    ln -s "$src" "$IN/perf-$n-$(basename "$src")"
done

inputs=("$IN"/perf-*.jpg)
if [ "${#inputs[@]}" -ne 100 ]; then
    echo "error: expected 100 input symlinks, got ${#inputs[@]}" >&2
    exit 1
fi

for run in $(seq 1 "$RUNS"); do
    trash_path "$OUT"
    mkdir -p "$OUT"

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
        echo "error: run $run expected 100 outputs, got $count" >&2
        exit 1
    fi

    python3 - "$start" "$end" "$OUT" "$STATS" "$run" <<'PY'
from pathlib import Path
import sys

start = float(sys.argv[1])
end = float(sys.argv[2])
out = Path(sys.argv[3])
stats = Path(sys.argv[4])
run = int(sys.argv[5])
total_bytes = sum(p.stat().st_size for p in out.glob("*.png"))
elapsed = max(end - start, 0.000001)
with stats.open("a") as fh:
    fh.write(f"{elapsed:.9f}\t{total_bytes}\n")
print(f"  run {run}: {elapsed:.3f}s, {100 / elapsed:.2f} images/s, {elapsed * 1000 / 100:.1f} ms/image, {total_bytes:,} bytes")
PY
done

python3 - "$BIN" "$OUT" "$STATS" "$README" "$RUNS" <<'PY'
from pathlib import Path
import re
import sys

binary = sys.argv[1]
out = Path(sys.argv[2])
stats_path = Path(sys.argv[3])
readme = Path(sys.argv[4])
runs = int(sys.argv[5])

rows = []
for line in stats_path.read_text().splitlines():
    elapsed, total_bytes = line.split("\t")
    rows.append((float(elapsed), int(total_bytes)))

if len(rows) != runs:
    raise SystemExit(f"error: expected {runs} performance rows, got {len(rows)}")

byte_values = {total_bytes for _, total_bytes in rows}
if len(byte_values) != 1:
    pretty = ", ".join(f"{value:,}" for value in sorted(byte_values))
    raise SystemExit(f"error: output bytes changed across runs: {pretty}")

avg_elapsed = sum(elapsed for elapsed, _ in rows) / runs
throughput = 100 / avg_elapsed
latency = avg_elapsed * 1000 / 100
total_bytes = rows[-1][1]

line = (
    f"Average over 5 release-binary runs: **100 images in {avg_elapsed:.3f} s, "
    f"{throughput:.2f} images/s, {latency:.1f} ms/image** with "
    f"{total_bytes:,} output bytes verified per run. On-device, no network, "
    "no GPU contention with another process."
)

text = readme.read_text()
pattern = re.compile(
    r"(?:Measured release-binary run|Average over 5 release-binary runs): "
    r"\*\*100 images in [^*]+\*\* with [^.]+ output bytes verified(?: per run)?\. "
    r"On-device, no network, no GPU contention with another process\."
)
updated, count = pattern.subn(line, text)
if count == 1:
    readme.write_text(updated)
elif count > 1:
    raise SystemExit("error: README performance line is not unique")
else:
    print(f"  README:        no performance line found; skipping update")

print("bgbgone 5x100-image performance")
print(f"  binary:        {binary}")
print("  inputs:        100 fixture-backed symlinks")
print(f"  runs:          {runs}")
print(f"  outputs:       {out}")
print(f"  avg elapsed:   {avg_elapsed:.3f}s")
print(f"  throughput:    {throughput:.2f} images/s")
print(f"  avg latency:   {latency:.1f} ms/image")
print(f"  output bytes:  {total_bytes:,} per run")
print(f"  README:        updated (count={count})")
PY
