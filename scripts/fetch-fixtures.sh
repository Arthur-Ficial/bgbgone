#!/bin/bash
# fetch-fixtures.sh — download strict-public-domain Wikimedia images for bgbgone tests.
#
# RULE: every image listed below is squarely public domain (PD-NASA federal-gov work,
# PD-old by age, or PD-Art faithful reproductions of pre-1929 paintings).
# NO Creative Commons. NO CC0 (which is technically a CC tool).
# See Tests/fixtures/LICENSES.md for the per-image PD justification with source links.
#
# Wikimedia Commons Special:FilePath form is used — it's the stable, canonical
# URL that redirects to the current physical location and lets us request a width.
#
# Usage: bash scripts/fetch-fixtures.sh
#        make fixtures

set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$DIR/Tests/fixtures"
mkdir -p "$OUT"

# Wikimedia's User-Agent policy requires a contact identifier.
UA="bgbgone-test-fetcher/0.0.1 (arti.ficial@fullstackoptimization.com)"

# Format: LOCAL_NAME|WIKIMEDIA_FILENAME|WIDTH
FIXTURES=(
  "01-nasa-aldrin-moon.jpg|Aldrin_Apollo_11_original.jpg|1024"
  "02-nasa-mccandless-eva.jpg|Astronaut-EVA.jpg|1024"
  "03-nasa-earthrise.jpg|NASA-Apollo8-Dec24-Earthrise.jpg|1024"
  "04-nasa-hubble-ngc1300.jpg|Hubble2005-01-barred-spiral-galaxy-NGC1300.jpg|1024"
  "05-nasa-apollo11-crew.jpg|Apollo_11_Crew.jpg|1024"
  "06-nasa-mars-curiosity-selfie.jpg|Curiosity_Self-Portrait_at_'Big_Sky'_Drilling_Site.jpg|1024"
  "07-einstein-1921.jpg|Einstein_1921_by_F_Schmutzer_-_restoration.jpg|800"
  "08-tesla-sarony.jpg|Tesla_Sarony.jpg|800"
  "09-wright-brothers-1910.jpg|Wright_Brothers_in_1910.jpg|800"
  "10-mona-lisa.jpg|Mona_Lisa,_by_Leonardo_da_Vinci,_from_C2RMF_retouched.jpg|600"
  "11-great-wave-hokusai.jpg|The_Great_Wave_off_Kanagawa.jpg|1024"
  "12-girl-with-pearl-earring.jpg|1665_Girl_with_a_Pearl_Earring.jpg|600"
  "13-singer-1892.jpg|Singer sewing machines poster 1892.jpg|800"
  "14-underwood-1909.jpg|PSM V75 D640 Underwood typewriter advertisement 1909.jpg|800"
  "15-edison-phonograph.jpg|Edison and phonograph edit2.jpg|800"
  "16-winchester-1909.jpg|Winchester advertisement, Rod and Gun in Canada November 1909, p1.jpg|800"
)

echo "fetching ${#FIXTURES[@]} PD fixtures into $OUT"

ok=0
for entry in "${FIXTURES[@]}"; do
  local_name="${entry%%|*}"
  rest="${entry#*|}"
  wm_name="${rest%%|*}"
  width="${rest##*|}"
  dest="$OUT/$local_name"
  if [ -f "$dest" ] && [ -s "$dest" ]; then
    echo "  ok    $local_name (cached)"
    ok=$((ok + 1))
    continue
  fi
  # URL-encode the filename — bash 4+ has printf %q but we need URL encoding.
  # Use python for portability with the apostrophe in the Curiosity filename.
  enc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$wm_name")
  url="https://commons.wikimedia.org/wiki/Special:FilePath/${enc}?width=${width}"
  echo "  →     $local_name"
  if ! curl -sSfL -A "$UA" -o "$dest" "$url"; then
    echo "        FAILED: $url"
    rm -f "$dest"
    exit 1
  fi
  ok=$((ok + 1))
done

echo "done. $ok files in $OUT"
ls -la "$OUT"
