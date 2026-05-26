#!/usr/bin/env bash
# gen-docs.sh -- single source of truth for per-filter docs.
#
# For every filter in `bgbgone --filters-list --json`, this script:
#   1. Picks the preferred layer (fg > bg > all > composite > mask) so
#      the main example always demonstrates the filter on the SUBJECT
#      with the background preserved as a visual anchor.
#   2. Builds ONE bgbgone invocation string.
#   3. Executes that string to render docs/images/filters/<name>.jpg.
#   4. Emits the EXACT same string into docs/filters/<name>.md.
#
# Result: the code block above each image is literally the command that
# produced the image. No drift between "what we documented" and "what
# we shipped". DRY + KISS.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$ROOT/.build/release/bgbgone}"
TMPL_DIR="$ROOT/scripts/templates"
OUT_DIR="$ROOT/docs/filters"
IMG_DIR="$ROOT/docs/images/filters"
PANELS_DIR="$IMG_DIR/panels"
FIX_DIR="$ROOT/Tests/fixtures"

[ -x "$BIN" ] || { echo "gen-docs: missing binary $BIN; run 'make build' first"; exit 1; }
command -v jq   >/dev/null || { echo "gen-docs: requires jq"; exit 1; }
command -v perl >/dev/null || { echo "gen-docs: requires perl"; exit 1; }

mkdir -p "$OUT_DIR" "$IMG_DIR"

JSON=$("$BIN" --filters-list --json)
COUNT=$(printf '%s' "$JSON" | jq 'length')

# Pick the demo layer for a filter's main example. Always prefer fg
# (subject-only filter; background preserved as anchor); only fall back
# to bg / all / composite / mask if fg is not a valid layer.
preferred_layer() {
  local layers_csv="$1"
  for candidate in fg bg all composite mask; do
    case ",${layers_csv}," in *,${candidate},*) echo "$candidate"; return ;; esac
  done
  echo "${layers_csv%%,*}"
}

# Build the canonical bgbgone invocation string for a filter. Same
# string is both displayed in the doc and executed to render the asset.
# Always passes --bg "image:red-panda.jpg" so the unfiltered background
# is the visual anchor, then writes a JPEG into docs/images/filters/.
invocation_for() {
  local layer="$1" name="$2" example="$3"
  printf 'bgbgone red-panda.jpg --bg "image:red-panda.jpg" --filter "%s:%s" -o red-panda-%s.jpg' \
    "$layer" "$example" "$name"
}

# Curl equivalent of `invocation_for` for the local HTTP server. The
# server accepts the same options as the CLI (parity contract). Same
# output - we reuse the CLI-rendered asset; the server suite asserts
# byte-equivalence in run-server-parity.sh.
server_invocation_for() {
  local layer="$1" name="$2" example="$3"
  printf 'curl -X POST http://127.0.0.1:8787/bgbgone \\\n  -F "image_file=@red-panda.jpg" \\\n  -F "bg=@red-panda.jpg" \\\n  -F "filter=%s:%s" \\\n  -F "format=jpg" \\\n  -o red-panda-%s.jpg' \
    "$layer" "$example" "$name"
}

# Run the invocation against the live binary; output lands at the
# absolute path under IMG_DIR. The displayed command uses relative
# names so the user can copy-paste; the renderer rewrites them to the
# real fixture + asset paths.
render_invocation() {
  local layer="$1" name="$2" example="$3"
  local fixture="$FIX_DIR/red-panda.jpg"
  local out="$IMG_DIR/${name}.jpg"
  "$BIN" "$fixture" --bg "image:$fixture" \
    --filter "${layer}:${example}" \
    -o "$out" >/dev/null
}

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

# Per-subject section: emit only if the matching panel image exists.
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

TMPL_FILTER="$TMPL_DIR/filter.md.tmpl"
[ -f "$TMPL_FILTER" ] || { echo "gen-docs: missing $TMPL_FILTER"; exit 1; }

i=0
rendered=0
while IFS= read -r entry; do
  export NAME=$(jq -r '.name'             <<<"$entry")
  export DOC=$(jq -r '.doc'                <<<"$entry")
  export SIGNATURE=$(jq -r '.signature'    <<<"$entry")
  export LAYERS=$(jq -r '.layers | join(", ")' <<<"$entry")
  example=$(jq -r '.examples[0] // .name'  <<<"$entry")
  layers_csv=$(jq -r '.layers | join(",")' <<<"$entry")

  LAYER=$(preferred_layer "$layers_csv")
  export EXAMPLE_INVOCATION=$(invocation_for "$LAYER" "$NAME" "$example")
  export EXAMPLE_SERVER=$(server_invocation_for "$LAYER" "$NAME" "$example")
  export EXAMPLE_CHAIN="${LAYER}:${example}"

  # Render the asset using the same chain. Any failure here is a bug
  # (the filter is in the registry but cannot render against red-panda).
  if render_invocation "$LAYER" "$NAME" "$example" 2>/dev/null; then
    rendered=$((rendered + 1))
  else
    echo "gen-docs: WARN failed to render $NAME ($LAYER:$example)" >&2
  fi

  produces_alpha=$(jq -r '.producesAlpha'  <<<"$entry")
  if [ "$produces_alpha" = "true" ]; then
    export ALPHA_NOTE="| **Note** | introduces alpha — output here is JPEG over the source bg; use \`-o out.png\` for true transparent output |"
  else
    export ALPHA_NOTE=""
  fi

  export YOGA_SECTION=$(subject_section "yoga" "$NAME" "$entry")
  export WOMAN_SINGER_SECTION=$(subject_section "woman-singer" "$NAME" "$entry")

  render "$TMPL_FILTER" NAME DOC SIGNATURE LAYERS EXAMPLE_INVOCATION EXAMPLE_SERVER EXAMPLE_CHAIN ALPHA_NOTE YOGA_SECTION WOMAN_SINGER_SECTION > "$OUT_DIR/${NAME}.md"
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

echo "gen-docs: wrote $i per-filter pages, rendered $rendered assets in $IMG_DIR/"
