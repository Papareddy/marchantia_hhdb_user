# Examples

Drop your own query FASTAs here or use the bundled examples below.

## Single-query example: `AtATG5.fa`

*Arabidopsis thaliana* ATG5 (Autophagy-related protein 5, UniProt Q9FFI2, 337 AA).
A well-characterized housekeeping factor — strong, unambiguous Marchantia ortholog
expected.

```bash
./query.sh examples/AtATG5.fa
# Produces 3 files in results/ (default output dir):
#   results/AtATG5.hhr           raw hhsearch output (full alignments)
#   results/AtATG5.hits.tsv      parsed top-10 hits  (machine-readable)
#   results/AtATG5.pdf           figure: bar chart + coverage map
#
# expected top hit: Mp1g12840.1   Prob=100.0   E-value=3.8e-80
```

A reference rendering of the PDF for AtATG5 is bundled here:
[`AtATG5_example_output.pdf`](AtATG5_example_output.pdf).

## Multi-query example: `rqc_batch/`

Six human RNA-quality-control / ribosome-rescue factors (the full no-go
decay + RQC pathway). All have unambiguous Marchantia orthologs — a useful
sanity-check that the DB covers conserved eukaryotic factors.

```
rqc_batch/
├── ABCE1.fa       Q9BRX2 / human  ATP-binding cassette E1 (yeast Rli1) — ribosome splitting
├── HBS1L.fa       Q9Y450 / human  HBS1-like (yeast Hbs1)               — partner of PELO
├── LTN1.fa        O94822 / human  Listerin (yeast Ltn1)                — E3 for the stalled nascent chain
├── NEMF.fa        O60524 / human  NEMF / Rqc2 (yeast Tae2)             — CAT-tail recruiter
├── PELO.fa        Q9BRX2 / human  Pelota (yeast Dom34)                 — stall recognition
├── ZNF598.fa      Q86UK7 / human  ZNF598 (yeast Hel2)                  — collided-ribosome ubiquitin ligase
└── EXPECTED_TOP_HITS.tsv          expected Marchantia orthologs + scores
```

Run the batch (two equivalent ways; output dir defaults to `results/<basename of input>`):
```bash
# A. as a directory of single-FASTAs (one record per file)
./batch_query.sh examples/rqc_batch              # -> results/rqc_batch/

# B. as a single multi-FASTA file (auto-split internally; UniProt headers detected)
cat examples/rqc_batch/*.fa > /tmp/rqc_multi.fa
./batch_query.sh /tmp/rqc_multi.fa               # -> results/rqc_multi/
```

Each produces, in the output dir:
- `<query>.hhr` / `.hits.tsv` / `.pdf`  — one set per protein (same shape as single-query mode)
- `SUMMARY.tsv` — one row per query with top hit + scores
- `SUMMARY.pdf` — aggregate horizontal bar chart of best-hit probabilities

Expected top hits are tracked in [`rqc_batch/EXPECTED_TOP_HITS.tsv`](rqc_batch/EXPECTED_TOP_HITS.tsv).
Reference renderings bundled here:
- [`rqc_batch/SUMMARY_example_output.pdf`](rqc_batch/SUMMARY_example_output.pdf) — aggregate top-hit figure across all 6 queries
- [`rqc_batch/PELO_example_output.pdf`](rqc_batch/PELO_example_output.pdf) — per-query figure for PELO (stall recognition; expected Mp1g11870.1, Prob=100, E=4.8e-59), showing what each protein gets in batch mode

Total wall: ~2 min on a 4-cpu node (against the SDS DB).

## Add your own

Drop any `<id>.fa` here (one record per file) and the wrappers will pick it up.
Multi-FASTA input must be split first — see [`../docs/FASTA_FORMAT.md`](../docs/FASTA_FORMAT.md).
