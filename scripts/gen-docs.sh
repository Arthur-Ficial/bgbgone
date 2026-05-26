#!/usr/bin/env bash
# gen-docs.sh -- one entry point, one template per doc type.
#
# Reads `bgbgone --filters-list --json` and renders:
#   - docs/filters/<name>.md         (49 pages, one template)
#   - docs/filters/README.md         (filter index)
#
# Per-subject sections (yoga, woman-singer) are emitted ONLY if the
# matching panel image exists on disk. No section -> no broken link.
# This invariant is enforced by scripts/lint-doc-images.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$ROOT/.build/release/bgbgone}"
TMPL_DIR="$ROOT/scripts/templates"
OUT_DIR="$ROOT/docs/filters"
PANELS_DIR="$ROOT/docs/images/filters/panels"

[ -x "$BIN" ] || { echo "gen-docs: missing binary $BIN; run 'make build' first"; exit 1; }
command -v jq   >/dev/null || { echo "gen-docs: requires jq"; exit 1; }
command -v perl >/dev/null || { echo "gen-docs: requires perl"; exit 1; }

mkdir -p "$OUT_DIR"

JSON=$("$BIN" --filters-list --json)
COUNT=$(printf '%s' "$JSON" | jq 'length')

render() {
  local tmpl="$1"; shift
  TPL_PATH="$tmpl" perl -e '
    use strict; use warnings;
    open my $fh, "<", $ENV{TPL_PATH} or die "open $ENV{TPL_PATH}: $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    for my $k (@ARGV) {
      my $v = exists $ENV{$k} ? $ENV{$k} : "";
      $text =~ s/\Q{{${k}}}\E/$v/g;
    }
    print $text;
  ' -- "$@"
}

# Build a per-subject section: a heading + code block whose invocations
# target the subject fixture + the panel image. Emits "" if the panel
# image isn't present on disk (no broken link).
subject_section() {
  local subject="$1" name="$2" entry="$3"
  local panel="$PANELS_DIR/${subject}-${name}.jpg"
  [ -f "$panel" ] || { printf ''; return; }

  local lines=""
  while IFS= read -r layer; do
    [ -z "$layer" ] && continue
    case "$layer" in
      composite|fg|mask)
        lines+="bgbgone ${subject}.jpg --type person --bg color:#1a2233 --filter \"${layer}:${name}\""$'\n'
        ;;
      bg|all)
        lines+="bgbgone ${subject}.jpg --type person --bg \"image:${subject}.jpg\" --filter \"${layer}:${name}\""$'\n'
        ;;
    esac
  done < <(jq -r '.layers[]' <<<"$entry")

  printf '\n\n## Per-layer panels — %s (`--type person`)\n\n```bash\n%s```\n\nPanels (`original | bg | fg | all`):\n\n![`%s` panels on %s](../images/filters/panels/%s-%s.jpg)' \
    "$subject" "$lines" "$name" "$subject" "$subject" "$name"
}

# ---- per-filter pages ----
TMPL_FILTER="$TMPL_DIR/filter.md.tmpl"
[ -f "$TMPL_FILTER" ] || { echo "gen-docs: missing $TMPL_FILTER"; exit 1; }

i=0
while IFS= read -r entry; do
  export NAME=$(jq -r '.name'             <<<"$entry")
  export DOC=$(jq -r '.doc'                <<<"$entry")
  export SIGNATURE=$(jq -r '.signature'    <<<"$entry")
  export LAYERS=$(jq -r '.layers | join(", ")' <<<"$entry")
  first_layer=$(jq -r '.layers[0]'         <<<"$entry")
  example=$(jq -r '.examples[0] // .name'  <<<"$entry")
  export EXAMPLE_CHAIN="${first_layer}:${example}"
  produces_alpha=$(jq -r '.producesAlpha'  <<<"$entry")
  if [ "$produces_alpha" = "true" ]; then
    export ALPHA_NOTE="| **Note** | introduces alpha — use PNG output or pass \`--bg\` |"
  else
    export ALPHA_NOTE=""
  fi

  export YOGA_SECTION=$(subject_section "yoga" "$NAME" "$entry")
  export WOMAN_SINGER_SECTION=$(subject_section "woman-singer" "$NAME" "$entry")

  render "$TMPL_FILTER" NAME DOC SIGNATURE LAYERS EXAMPLE_CHAIN ALPHA_NOTE YOGA_SECTION WOMAN_SINGER_SECTION > "$OUT_DIR/${NAME}.md"
  i=$((i + 1))
done < <(printf '%s' "$JSON" | jq -c '.[]')

# ---- filter index ----
TMPL_INDEX="$TMPL_DIR/filter-index.md.tmpl"
[ -f "$TMPL_INDEX" ] || { echo "gen-docs: missing $TMPL_INDEX"; exit 1; }

row_jq='"| [`\(.name)`](\(.name).md) | `\(.signature)` | \(.doc) |"'

export COUNT
export ALL_LAYER_ROWS=$(jq -r ".[] | select(.layers | (contains([\"all\"]) and contains([\"bg\"]) and contains([\"fg\"]))) | $row_jq" <<<"$JSON")
export COMPOSITE_ROWS=$(jq -r ".[] | select(.layers == [\"composite\"]) | $row_jq" <<<"$JSON")
export FG_ROWS=$(jq -r ".[] | select(.layers == [\"fg\"]) | $row_jq" <<<"$JSON")
export MASK_ROWS=$(jq -r ".[] | select(.layers == [\"mask\"]) | $row_jq" <<<"$JSON")

render "$TMPL_INDEX" COUNT ALL_LAYER_ROWS COMPOSITE_ROWS FG_ROWS MASK_ROWS > "$OUT_DIR/README.md"

echo "gen-docs: wrote $i per-filter pages + index"
