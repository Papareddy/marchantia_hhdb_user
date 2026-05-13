#!/usr/bin/env bash
# Query many proteins against the Marchantia HH-suite database.
# Each input produces .hhr + .hits.tsv + .pdf in the output directory.
# Plus an aggregate summary: <outdir>/SUMMARY.tsv + <outdir>/SUMMARY.pdf
#
# Usage:
#   ./batch_query.sh <input> [output_dir] [PARALLEL_JOBS]
#
#   <input> can be either:
#     - a DIRECTORY of single-record .fa/.fasta files (one protein per file), or
#     - a single MULTI-FASTA file (>1 record); auto-split into <outdir>/_split/
#
#   [output_dir] defaults to: results/<basename of input, extension stripped>
#     e.g.  ./batch_query.sh examples/rqc_batch        -> results/rqc_batch/
#           ./batch_query.sh my_queries.fa             -> results/my_queries/
#
# Env:    THREADS  (cpus per hhsearch invocation; default 2)
#         TOP      (top-N hits to parse + plot per query; default 10)
#         MARCHANTIA_HHDB  (DB prefix; default db/marchantia_v7.1)

set -euo pipefail

INPUT=${1:?usage: $0 <input_dir_OR_multifasta> [output_dir] [PARALLEL_JOBS]}
# Default output dir: results/<basename of input, .fa/.fasta stripped>
_in_base=$(basename "$INPUT")
_in_base=${_in_base%.fa}
_in_base=${_in_base%.fasta}
OUTDIR=${2:-results/${_in_base}}
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

# ---- Resolve INPUT to a directory of one-record FASTAs ----
if [ -d "$INPUT" ]; then
  INDIR="$INPUT"
  echo "[$(date -Is)] input is a directory: $INDIR"
elif [ -f "$INPUT" ]; then
  # multi-FASTA: auto-split into <outdir>/_split/
  INDIR="$OUTDIR/_split"
  echo "[$(date -Is)] input is a multi-FASTA: $INPUT  ->  auto-splitting to $INDIR/"
  mkdir -p "$INDIR"
  rm -f "$INDIR"/*.fa 2>/dev/null || true
  awk -v dir="$INDIR" '
    /^>/ {
      # take first whitespace token as the identifier
      hdr = $0; sub(/^>/, "", hdr);
      first = hdr; sub(/[ \t].*/, "", first);
      # UniProt pipe format ">sp|ACC|NAME ..." -> take NAME (last pipe segment)
      n = split(first, a, "|");
      id = (n >= 3) ? a[n] : first;
      # sanitize file name: keep only [A-Za-z0-9_.-]
      gsub(/[^A-Za-z0-9_.-]/, "_", id);
      fname = dir "/" id ".fa";
    }
    { print > fname }
  ' "$INPUT"
  echo "[$(date -Is)] split into $(ls "$INDIR"/*.fa | wc -l) files"
else
  echo "ERROR: input '$INPUT' is neither a directory nor a file" >&2
  exit 1
fi

mapfile -t INPUTS < <(ls -1 "$INDIR"/*.fa "$INDIR"/*.fasta 2>/dev/null || true)
N=${#INPUTS[@]}
[ "$N" -gt 0 ] || { echo "no .fa/.fasta found"; exit 1; }

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
