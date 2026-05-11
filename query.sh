#!/usr/bin/env bash
# Query a single protein (one FASTA) against the Marchantia HH-suite database.
#
# Usage:
#   ./query.sh <query.fa>                 -> writes <query>.hhr next to the FASTA
#   ./query.sh <query.fa> <out.hhr>       -> custom output path
#   THREADS=8 ./query.sh ...              -> override CPU thread count
#   MARCHANTIA_HHDB=/path/to/prefix ...   -> override DB location

set -euo pipefail

QUERY=${1:?usage: $0 <query.fa> [output.hhr]}
OUT=${2:-${QUERY%.*}.hhr}
DB=${MARCHANTIA_HHDB:-db/marchantia_v7.1}
THREADS=${THREADS:-4}

if [ -z "${HHLIB:-}" ] && [ -n "${CONDA_PREFIX:-}" ]; then
  export HHLIB=$CONDA_PREFIX
fi

[ -s "${DB}_a3m.ffdata" ] || {
  echo "ERROR: DB not found at '$DB' (looked for ${DB}_a3m.ffdata)" >&2
  echo
  echo "Did you fetch it?  ->  make fetch ZENODO_RECORD=<the_record_id>" >&2
  echo "Or set MARCHANTIA_HHDB to your existing DB prefix (without _a3m.ffdata)." >&2
  exit 1
}

echo "[$(date -Is)] hhsearch  query=$QUERY  db=$DB  cpu=$THREADS  out=$OUT"
hhsearch -i "$QUERY" -d "$DB" -o "$OUT" -cpu "$THREADS" -v 1

echo
echo "Top hits (first 10):"
sed -n '/^ No Hit/,/^No 1/p' "$OUT" | head -12
