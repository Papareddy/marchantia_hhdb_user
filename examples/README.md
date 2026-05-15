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
# A. as a single multi-FASTA file (auto-split internally; UniProt headers detected)
#    Bundled as examples/my_rqc_factors.fasta — same 6 sequences, one file
./batch_query.sh examples/my_rqc_factors.fasta   # -> results/my_rqc_factors/

# B. as a directory of single-FASTAs (one record per file)
./batch_query.sh examples/rqc_batch              # -> results/rqc_batch/
```

Each produces, in the output dir:
- `<query>.hhr` / `.hits.tsv` / `.pdf`  — one set per protein (same shape as single-query mode)
- `SUMMARY.tsv` — one row per query with top hit + scores
- `SUMMARY.pdf` — aggregate horizontal bar chart of best-hit probabilities

Expected top hits are tracked in [`rqc_batch/EXPECTED_TOP_HITS.tsv`](rqc_batch/EXPECTED_TOP_HITS.tsv).
A full reference bundle from a real run against `db_v1.1` is committed under
[`rqc_batch/example_outputs/`](rqc_batch/example_outputs/) — the **exact files
you'd get** by running `./batch_query.sh examples/rqc_batch`:

| File                                        | What it is                                     |
|---------------------------------------------|------------------------------------------------|
| `<ID>.hhr`     (6 files, 14K–520K each)     | raw `hhsearch` output with full alignments     |
| `<ID>.hits.tsv` (6 files)                   | parsed top-10 hits per query                   |
| `<ID>.pdf`     (6 files)                    | per-query figure (bar chart + coverage map)    |
| `SUMMARY.tsv`                               | one row per query with top hit + scores        |
| `SUMMARY.pdf`                               | aggregate horizontal bar chart                 |

Top hits (from the bundled `SUMMARY.tsv`, db_v1.1):
- ABCE1  → Mp8g05210.1   Prob=100   E=5e-105    (ribosome splitting / Rli1)
- HBS1L  → Mp6g18130.1   Prob=100   E=1.2e-73   (PELO partner / Hbs1)
- LTN1   → Mp7g07340.1   Prob=100   E=4e-132    (E3 ligase / Ltn1)
- NEMF   → Mp1g00940.1   Prob=100   E=2e-157    (CAT-tail / Rqc2)
- PELO   → Mp1g11870.1   Prob=100   E=4.9e-59   (stall recognition / Dom34)
- ZNF598 → Mp5g21820.1   Prob=100   E=1.1e-53   (collision E3 / Hel2)

Total wall: ~2 min on a 4-cpu node (against the SDS DB).

## Add your own

Drop any `<id>.fa` here (one record per file) and the wrappers will pick it up.
Multi-FASTA input must be split first — see [`../docs/FASTA_FORMAT.md`](../docs/FASTA_FORMAT.md).
