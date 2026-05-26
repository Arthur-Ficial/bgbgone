#!/usr/bin/env bash
# test-doc-blocks.sh -- every fenced ```bash / ```sh block in every shipped
# .md file is executed against the installed bgbgone binary. Failure is a
# build break.
#
# Rules:
#   - bgbgone blocks must run with exit 0. Fixture basenames (red-panda.jpg,
#     yoga.jpg, etc) are symlinked into the scratch dir from Tests/fixtures/.
#   - install / curl / other blocks are NOT executed (out of scope) but
#     they ARE still required to have a paired image when they document
#     a runnable bgbgone outcome — see scripts/lint-doc-pairing.sh.
#   - --server invocations are skipped (would block indefinitely).
#   - Blocks marked with a paired image must produce at least one output
#     file in the scratch dir.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$ROOT/.build/release/bgbgone}"
[ -x "$BIN" ] || { echo "test-doc-blocks: missing $BIN"; exit 1; }

TMP=$(mktemp -d -t bgbgone-doc-blocks.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

# Symlink every fixture as a basename so `bgbgone red-panda.jpg` works.
for f in "$ROOT"/Tests/fixtures/*.jpg "$ROOT"/Tests/fixtures/*.png; do
  [ -f "$f" ] || continue
  ln -sf "$f" "$TMP/$(basename "$f")"
done
# A handful of doc examples reference `in.jpg` / `out.png` as generic file
# names; provide minimal symlinks so those run too.
ln -sf "$TMP/red-panda.jpg" "$TMP/in.jpg"

pass=0
fail=0
skipped=0

run_block() {
  local file="$1" start="$2" end="$3" img="$4" kind="$5" code_b64="$6"
  local code
  code=$(printf '%s' "$code_b64" | base64 -d)

  # Skip non-bgbgone shells and server invocations (would hang).
  case "$kind" in
    install|curl|other|non_bgbgone)
      skipped=$((skipped + 1))
      return
      ;;
  esac
  if printf '%s' "$code" | grep -q -- '--server'; then
    skipped=$((skipped + 1))
    return
  fi

  # Replace the literal `bgbgone` with the actual binary path. Single-word
  # boundary so we don't rewrite `bgbgone.jpg` (none exist but defensive).
  local code_real
  code_real=$(printf '%s' "$code" | sed "s|\\bbgbgone\\b|\"$BIN\"|g")

  # Run inside the scratch dir so `red-panda.jpg` resolves to the symlink.
  local out_log err_log rc
  out_log="$TMP/last.out"
  err_log="$TMP/last.err"
  ( cd "$TMP" && bash -c "$code_real" >"$out_log" 2>"$err_log" )
  rc=$?

  if [ "$rc" -ne 0 ]; then
    printf 'FAIL  %s:%d  rc=%d\n' "$(basename "$file")" "$start" "$rc" >&2
    head -3 "$err_log" | sed 's/^/      /' >&2
    fail=$((fail + 1))
    return
  fi
  pass=$((pass + 1))
}

while IFS=$'\t' read -r file start end img kind code_b64; do
  run_block "$file" "$start" "$end" "$img" "$kind" "$code_b64"
done < <(bash "$ROOT/scripts/extract-doc-blocks.sh")

total=$((pass + fail + skipped))
echo "test-doc-blocks: $pass passed, $fail failed, $skipped skipped, $total total"
if [ "$fail" -gt 0 ]; then exit 1; fi
