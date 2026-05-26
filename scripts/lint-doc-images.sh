#!/usr/bin/env bash
# lint-doc-images.sh -- no broken image references in any shipped .md.
#
# Every ![alt](path) in every .md under the repo (excluding .build, archive,
# node_modules) MUST resolve to an existing file. Paths are resolved relative
# to the .md file's directory.
#
# Fails the build on any broken link.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FILES=$(find "$ROOT" -type f -name '*.md' \
  ! -path '*/.build/*' ! -path '*/node_modules/*' \
  ! -path '*/docs/archive/*' \
  | sort)

fail=0
checked=0

for md in $FILES; do
  md_dir=$(dirname "$md")
  # Strip inline code spans (single backticks) and fenced code blocks before
  # extraction, so prose like `![alt](path)` inside backticks doesn't trip
  # the linter.
  stripped=$(perl -0777 -pe '
    s/```.*?```//gs;
    s/`[^`\n]*`//g;
  ' "$md")
  # Extract every ![alt](path) occurrence. Strip optional title after path.
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    # Skip external URLs (http/https) and data: URIs - those don't need to be
    # local files.
    case "$path" in
      http://*|https://*|data:*) continue ;;
    esac
    # Strip URL fragment if present.
    path_no_frag="${path%%#*}"
    # Resolve relative to the .md file.
    if [[ "$path_no_frag" = /* ]]; then
      abs="$path_no_frag"
    else
      abs="$md_dir/$path_no_frag"
    fi
    checked=$((checked + 1))
    if [ ! -f "$abs" ]; then
      printf 'BROKEN  %s -> %s\n' "${md#$ROOT/}" "$path"
      fail=1
    fi
  done < <(printf '%s' "$stripped" | grep -oE '!\[[^]]*\]\(([^)]+)\)' \
            | sed -E 's/!\[[^]]*\]\(([^)]+)\)/\1/')
done

if [ "$fail" -eq 0 ]; then
  echo "lint-doc-images: OK $checked image link(s), 0 broken"
fi
exit "$fail"
