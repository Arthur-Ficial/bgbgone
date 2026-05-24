#!/bin/bash
# Optional sustained-throughput scenario for bgbgone (parameterised).
#
# Companion to run-100.sh — NOT part of `make release`. Opt-in via
# `make test-performance-1000` / `-10000` / `-100000`. Each target
# passes a different invocation count to this script; everything
# else (batch=100, fixtures, README-update mechanism, determinism
# check) is the same.
#
# Design: N batch invocations of 100 fixture-backed inputs each =
# (N * 100) total image operations per pass. Models the kind of
# repeated batches a heavy user runs throughout a day. The 100-image
# batch is the same one the release-gate exercises.
#
# Inputs are symlinks to the same 16 strict-PD Wikimedia fixtures
# (NASA imagery, pre-1929 portraits, public-domain art; 95KB-665KB
# JPEGs of real people / objects) cycled into 100 named symlinks.
# Determinism check: every invocation must produce identical total
# output bytes. The README result line is re-written on every run
# so repeated invocations always show the current measurement.
#
# Run: bash Tests/performance/run-sustained.sh BIN INVOCATIONS

set -euo pipefail

BIN="${1:-bgbgone}"
INVOCATIONS="${2:-10}"

case "$INVOCATIONS" in
    ''|*[!0-9]*)
        echo "error: INVOCATIONS must be a positive integer, got '$INVOCATIONS'" >&2
        exit 1
        ;;
esac
if [ "$INVOCATIONS" -lt 1 ]; then
    echo "error: INVOCATIONS must be >= 1" >&2
    exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_ROOT="$(cd "$DIR/.." && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
source "$REPO_ROOT/scripts/trash.sh"
FIX="$TEST_ROOT/fixtures"
BATCH=100
TOTAL=$(( BATCH * INVOCATIONS ))
WORK="$DIR/_tmp_sustained_${INVOCATIONS}"
IN="$WORK/in"
OUT="$WORK/out"
STATS="$WORK/stats.tsv"
README="$REPO_ROOT/README.md"

trash_path "$WORK"
mkdir -p "$IN" "$OUT"
: > "$STATS"

fixtures=("$FIX"/*.jpg)
if [ "${#fixtures[@]}" -eq 0 ]; then
    echo "error: no fixtures found in $FIX" >&2
    exit 1
fi

for i in $(seq 1 "$BATCH"); do
    src="${fixtures[$(( (i - 1) % ${#fixtures[@]} ))]}"
    printf -v n "%03d" "$i"
    ln -s "$src" "$IN/perf-$n-$(basename "$src")"
done

inputs=("$IN"/perf-*.jpg)
if [ "${#inputs[@]}" -ne "$BATCH" ]; then
    echo "error: expected $BATCH input symlinks, got ${#inputs[@]}" >&2
    exit 1
fi

# Width for the invocation index in the progress log: max(2, log10(N)+1).
width=${#INVOCATIONS}
if [ "$width" -lt 2 ]; then width=2; fi

echo "bgbgone $INVOCATIONS x $BATCH = $TOTAL image operations:"
for run in $(seq 1 "$INVOCATIONS"); do
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

    out_count=$(find "$OUT" -type f -name '*.png' | wc -l | tr -d ' ')
    if [ "$out_count" -ne "$BATCH" ]; then
        echo "error: invocation $run expected $BATCH outputs, got $out_count" >&2
        exit 1
    fi

    python3 - "$start" "$end" "$OUT" "$STATS" "$run" "$BATCH" "$INVOCATIONS" "$width" <<'PY'
from pathlib import Path
import sys

start = float(sys.argv[1])
end = float(sys.argv[2])
out = Path(sys.argv[3])
stats = Path(sys.argv[4])
run = int(sys.argv[5])
batch = int(sys.argv[6])
invocations = int(sys.argv[7])
width = int(sys.argv[8])
total_bytes = sum(p.stat().st_size for p in out.glob("*.png"))
elapsed = max(end - start, 0.000001)
with stats.open("a") as fh:
    fh.write(f"{elapsed:.9f}\t{total_bytes}\n")
print(f"  invocation {run:0{width}d}/{invocations}: {elapsed:.3f}s, {batch / elapsed:.2f} images/s, {elapsed * 1000 / batch:.1f} ms/image, {total_bytes:,} bytes")
PY
done

python3 - "$BIN" "$OUT" "$STATS" "$README" "$INVOCATIONS" "$BATCH" "$TOTAL" <<'PY'
from pathlib import Path
import re
import sys

binary = sys.argv[1]
out = Path(sys.argv[2])
stats_path = Path(sys.argv[3])
readme = Path(sys.argv[4])
invocations = int(sys.argv[5])
batch = int(sys.argv[6])
total = int(sys.argv[7])

rows = []
for line in stats_path.read_text().splitlines():
    elapsed, total_bytes = line.split("\t")
    rows.append((float(elapsed), int(total_bytes)))

if len(rows) != invocations:
    raise SystemExit(f"error: expected {invocations} performance rows, got {len(rows)}")

byte_values = {total_bytes for _, total_bytes in rows}
if len(byte_values) != 1:
    pretty = ", ".join(f"{value:,}" for value in sorted(byte_values))
    raise SystemExit(f"error: output bytes changed across invocations: {pretty}")

total_elapsed = sum(elapsed for elapsed, _ in rows)
throughput = total / total_elapsed
latency = total_elapsed * 1000 / total
per_batch_bytes = rows[-1][1]

line = (
    f"Average over {invocations} release-binary invocations of {batch}: "
    f"**{total} image operations in {total_elapsed:.3f} s, "
    f"{throughput:.2f} images/s, {latency:.1f} ms/image** with "
    f"{per_batch_bytes:,} output bytes verified per invocation. On-device, "
    "no network, no GPU contention with another process."
)

text = readme.read_text()
pattern = re.compile(
    rf"Average over {invocations} release-binary invocations of {batch}: "
    rf"\*\*{total} image operations in [^*]+\*\* with [^.]+ output bytes "
    r"verified per invocation\. On-device, no network, no GPU contention "
    r"with another process\."
)
updated, replaced = pattern.subn(line, text)
if replaced != 1:
    raise SystemExit(f"error: README sustained-throughput line for {invocations}x{batch} not found or not unique")
readme.write_text(updated)

print(f"bgbgone {invocations} x {batch} = {total} sustained image operations")
print(f"  binary:        {binary}")
print(f"  invocations:   {invocations} of {batch} images each")
print(f"  outputs:       {out}")
print(f"  total elapsed: {total_elapsed:.3f}s")
print(f"  throughput:    {throughput:.2f} images/s")
print(f"  avg latency:   {latency:.1f} ms/image")
print(f"  output bytes:  {per_batch_bytes:,} per invocation (identical across all {invocations})")
print("  README:        updated")
PY
