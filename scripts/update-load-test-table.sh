#!/bin/bash
# Reads the three perf-stats artifacts produced by:
#   Tests/performance/run-100.sh         -> _tmp_100/stats.tsv          (5 x 100)
#   Tests/performance/run-sustained.sh   -> _tmp_sustained_{10,100}/stats.tsv
# and re-renders the "Industry-scale load test" table in README.md
# between the LOAD-TEST-TABLE markers.
#
# Each row reports total wall time, per-image latency, and throughput
# for the full scale (100, 1000, 10000 image operations).
#
# Run after `make load-test-table` or after running the three perf
# scripts manually. Idempotent — running it twice produces the same
# README bytes.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PERF="$REPO_ROOT/Tests/performance"
README="$REPO_ROOT/README.md"

S100="$PERF/_tmp_100/stats.tsv"
S1K="$PERF/_tmp_sustained_10/stats.tsv"
S10K="$PERF/_tmp_sustained_100/stats.tsv"

for f in "$S100" "$S1K" "$S10K"; do
    if [ ! -s "$f" ]; then
        echo "error: missing stats file $f" >&2
        echo "       run 'make load-test-table' first" >&2
        exit 1
    fi
done

python3 - "$S100" "$S1K" "$S10K" "$README" <<'PY'
from pathlib import Path
import re
import sys

stats_paths = sys.argv[1:4]
readme = Path(sys.argv[4])

def read_stats(path):
    elapsed = []
    byte_set = set()
    for line in Path(path).read_text().splitlines():
        e, b = line.split("\t")
        elapsed.append(float(e))
        byte_set.add(int(b))
    if len(byte_set) != 1:
        raise SystemExit(f"non-deterministic byte counts in {path}: {sorted(byte_set)}")
    return elapsed

def fmt_time(seconds: float) -> str:
    if seconds < 1.0:
        return f"{seconds * 1000:.0f} ms"
    if seconds < 60.0:
        return f"{seconds:.2f} s"
    if seconds < 3600.0:
        m = int(seconds // 60)
        s = seconds - 60 * m
        return f"{m} min {s:.0f} s"
    h = int(seconds // 3600)
    rem = seconds - 3600 * h
    m = int(rem // 60)
    s = rem - 60 * m
    return f"{h} h {m} min {s:.0f} s"

def fmt_per_image(seconds: float) -> str:
    ms = seconds * 1000.0
    if ms < 1.0:
        return f"{ms * 1000:.0f} us"
    return f"{ms:.1f} ms"

def fmt_throughput(images_per_sec: float) -> str:
    return f"{images_per_sec:.2f} img/s"

# 100 scale: 5 invocations of 100 images each; report the per-batch average
# (representative time for one 100-image batch on this hardware).
e100 = read_stats(stats_paths[0])
if len(e100) != 5:
    raise SystemExit(f"expected 5 rows in 100-scale stats, got {len(e100)}")
total_time_100 = sum(e100) / len(e100)
n_100 = 100

# 1000 / 10000 scales: each invocation is 100 images; total wall time
# is the sum of all invocation timings.
e1k = read_stats(stats_paths[1])
e10k = read_stats(stats_paths[2])

for label, elapsed, expected in (("1000", e1k, 10), ("10000", e10k, 100)):
    if len(elapsed) != expected:
        raise SystemExit(f"expected {expected} rows in {label}-scale stats, got {len(elapsed)}")

scales = [
    ("100",     n_100, total_time_100),
    ("1 000",   1000,  sum(e1k)),
    ("10 000",  10000, sum(e10k)),
]

# Build Markdown table. Header includes the column meanings; rows are
# the scale label, total time, per-image latency, throughput.
rows = []
rows.append("| Images | Total time | Per image | Throughput |")
rows.append("|-------:|-----------:|----------:|-----------:|")
for label, n, total in scales:
    rows.append(
        f"| {label} | {fmt_time(total)} | "
        f"{fmt_per_image(total / n)} | {fmt_throughput(n / total)} |"
    )
table = "\n".join(rows)

text = readme.read_text()
pattern = re.compile(
    r"<!-- LOAD-TEST-TABLE-START -->.*?<!-- LOAD-TEST-TABLE-END -->",
    re.DOTALL,
)
replacement = (
    "<!-- LOAD-TEST-TABLE-START -->\n"
    + table
    + "\n<!-- LOAD-TEST-TABLE-END -->"
)
updated, count = pattern.subn(replacement, text)
if count != 1:
    raise SystemExit(
        "error: README must contain exactly one LOAD-TEST-TABLE marker "
        f"pair; found {count}"
    )
readme.write_text(updated)
print("update-load-test-table: rewrote table in README.md")
for label, n, total in scales:
    print(
        f"  {label:>7s} pics  total={fmt_time(total):>12s}  "
        f"per={fmt_per_image(total / n):>8s}  thr={fmt_throughput(n / total):>12s}"
    )
PY
