#!/usr/bin/env bash
# Query many proteins in parallel against the Marchantia HH-suite database.
#
# Usage:
#   ./batch_query.sh <input_dir> <output_dir> [JOBS]
#
# input_dir  : directory of .fa / .fasta files
# output_dir : where to write the .hhr results
# JOBS       : how many hhsearch processes in parallel (default = $(nproc) / 4)
#
# Each hhsearch uses THREADS cpus internally; total cpu usage = JOBS * THREADS.

set -euo pipefail

INDIR=${1:?usage: $0 <input_dir> <output_dir> [JOBS]}
OUTDIR=${2:?usage: $0 <input_dir> <output_dir> [JOBS]}
JOBS=${3:-$(( $(nproc) / 4 ))}
THREADS=${THREADS:-4}
DB=${MARCHANTIA_HHDB:-db/marchantia_v7.1}

mkdir -p "$OUTDIR"
[ -s "${DB}_a3m.ffdata" ] || { echo "ERROR: DB not found at $DB" >&2; exit 1; }
if [ -z "${HHLIB:-}" ] && [ -n "${CONDA_PREFIX:-}" ]; then
  export HHLIB=$CONDA_PREFIX
fi

count=$(ls -1 "$INDIR"/*.fa "$INDIR"/*.fasta 2>/dev/null | wc -l)
echo "[$(date -Is)] $count queries -> $OUTDIR  (parallel=$JOBS, threads/job=$THREADS)"

ls -1 "$INDIR"/*.fa "$INDIR"/*.fasta 2>/dev/null | \
  parallel --bar -j "$JOBS" \
    "hhsearch -i {} -d '$DB' -o '$OUTDIR'/{/.}.hhr -cpu $THREADS -v 0"

echo "[$(date -Is)] done. results in $OUTDIR"
ls "$OUTDIR" | wc -l | xargs echo "results count:"
