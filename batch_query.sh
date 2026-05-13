#!/usr/bin/env bash
# Query many proteins against the Marchantia HH-suite database.
# Each input produces .hhr + .hits.tsv + .pdf in the output directory.
# Plus an aggregate summary: <outdir>/SUMMARY.tsv + <outdir>/SUMMARY.pdf
#
# Usage:
#   ./batch_query.sh <input_dir> <output_dir> [PARALLEL_JOBS]
#
# Inputs: one .fa or .fasta per protein in <input_dir>/.
#         (Multi-FASTA files must be split first — see docs/FASTA_FORMAT.md.)
# Env:    THREADS  (cpus per hhsearch invocation; default 2)
#         TOP      (top-N hits to parse + plot per query; default 10)
#         MARCHANTIA_HHDB  (DB prefix; default db/marchantia_v7.1)

set -euo pipefail

INDIR=${1:?usage: $0 <input_dir> <output_dir> [PARALLEL_JOBS]}
OUTDIR=${2:?usage: $0 <input_dir> <output_dir> [PARALLEL_JOBS]}
JOBS=${3:-$(( $(nproc 2>/dev/null || echo 8) / 2 ))}
THREADS=${THREADS:-2}
TOP=${TOP:-10}
DB=${MARCHANTIA_HHDB:-db/marchantia_v7.1}

# Auto-activate conda env (one-time create on first run)
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$HERE/scripts/setup_env.sh"

[ -s "${DB}_a3m.ffdata" ] || {
  echo "ERROR: DB not found at '$DB' (looked for ${DB}_a3m.ffdata)" >&2
  exit 1
}

PARSE=$HERE/scripts/parse_hhr.py
PLOT=$HERE/scripts/plot_hhr.py
SUMMARIZE=$HERE/scripts/summarize_batch.py
for s in "$PARSE" "$PLOT" "$SUMMARIZE"; do
  [ -f "$s" ] || { echo "ERROR: missing helper script $s" >&2; exit 1; }
done

mkdir -p "$OUTDIR"
mapfile -t INPUTS < <(ls -1 "$INDIR"/*.fa "$INDIR"/*.fasta 2>/dev/null || true)
N=${#INPUTS[@]}
[ "$N" -gt 0 ] || { echo "no .fa/.fasta in $INDIR"; exit 1; }

echo "[$(date -Is)] $N queries -> $OUTDIR   (parallel=$JOBS, threads/job=$THREADS)"

# One-protein worker — written inline as a function exported for parallel/xargs.
# Doing per-protein: hhsearch -> parse -> plot.
run_one() {
  local fa="$1"
  local name
  name=$(basename "$fa")
  name=${name%.*}
  local hhr="$OUTDIR/$name.hhr"
  local tsv="$OUTDIR/$name.hits.tsv"
  local pdf="$OUTDIR/$name.pdf"
  hhsearch -i "$fa" -d "$DB" -o "$hhr" -cpu "$THREADS" -v 0 > /dev/null
  python "$PARSE" "$hhr" "$tsv" --top "$TOP" 2>/dev/null
  python "$PLOT"  "$tsv" "$pdf" --query-name "$name" --top "$TOP" 2>/dev/null
  echo "  done: $name"
}
export -f run_one
export OUTDIR DB THREADS TOP PARSE PLOT

if command -v parallel >/dev/null 2>&1; then
  printf "%s\n" "${INPUTS[@]}" | parallel --bar -j "$JOBS" run_one
else
  # fallback to xargs
  printf "%s\n" "${INPUTS[@]}" | xargs -n1 -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {}
fi

# Aggregate across all queries
echo "[$(date -Is)] building aggregate summary"
python "$SUMMARIZE" "$OUTDIR" "$OUTDIR/SUMMARY.tsv" "$OUTDIR/SUMMARY.pdf"

echo "[$(date -Is)] done. $N results in $OUTDIR"
echo
echo "=== one-line top-hit summary ==="
column -t -s $'\t' "$OUTDIR/SUMMARY.tsv" | head -$((N + 1))
echo
echo "=== files written ==="
ls -lh "$OUTDIR" | awk 'NR>1 {print "  " $9 "  (" $5 ")"}'
