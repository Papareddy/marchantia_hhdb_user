#!/usr/bin/env bash
# Query a single protein (one FASTA) against the Marchantia HH-suite database.
# ONE command -> .hhr (raw) + .hits.tsv (parsed top hits) + .pdf (figure).
#
# Usage:
#   ./query.sh <query.fa>                 -> writes <query>.hhr/.hits.tsv/.pdf next to the FASTA
#   ./query.sh <query.fa> <out_prefix>    -> writes <prefix>.hhr/.hits.tsv/.pdf
#   THREADS=8 ./query.sh ...              -> override CPU thread count
#   TOP=20    ./query.sh ...              -> override top-N hits to keep (default 10)
#   MARCHANTIA_HHDB=/path/to/prefix ...   -> override DB location

set -euo pipefail

QUERY=${1:?usage: $0 <query.fa> [output_prefix]}
PREFIX=${2:-${QUERY%.*}}
DB=${MARCHANTIA_HHDB:-db/marchantia_v7.1}
THREADS=${THREADS:-4}
TOP=${TOP:-10}

# Auto-activate conda env (one-time create on first run). Skip if already loaded.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$HERE/scripts/setup_env.sh"

[ -s "${DB}_a3m.ffdata" ] || {
  echo "ERROR: DB not found at '$DB' (looked for ${DB}_a3m.ffdata)" >&2
  echo "Fix: set MARCHANTIA_HHDB to your DB prefix (without _a3m.ffdata)," >&2
  echo "     or run 'make fetch ZENODO_RECORD=<id>' once Zenodo is live." >&2
  exit 1
}

# Bundled scripts live in scripts/ relative to this file
PARSE=$HERE/scripts/parse_hhr.py
PLOT=$HERE/scripts/plot_hhr.py
for s in "$PARSE" "$PLOT"; do
  [ -f "$s" ] || { echo "ERROR: missing helper script $s" >&2; exit 1; }
done

HHR="${PREFIX}.hhr"
TSV="${PREFIX}.hits.tsv"
PDF="${PREFIX}.pdf"
NAME=$(basename "$PREFIX")

echo "[$(date -Is)] hhsearch  $QUERY  cpu=$THREADS  ->  $HHR"
hhsearch -i "$QUERY" -d "$DB" -o "$HHR" -cpu "$THREADS" -v 1 > /dev/null

echo "[$(date -Is)] parse top $TOP hits  ->  $TSV"
python "$PARSE" "$HHR" "$TSV" --top "$TOP"

echo "[$(date -Is)] plot figure         ->  $PDF"
python "$PLOT" "$TSV" "$PDF" --query-name "$NAME" --top "$TOP"

echo
echo "=== top hits ==="
column -t -s $'\t' "$TSV" | head -$((TOP + 1))
echo
echo "=== files ==="
ls -lh "$HHR" "$TSV" "$PDF" | awk '{print "  " $9 "  (" $5 ")"}'
