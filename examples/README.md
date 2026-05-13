# Examples

Drop your own query FASTAs here or use the bundled examples below.

## Single-query example: `AtATG5.fa`

*Arabidopsis thaliana* ATG5 (Autophagy-related protein 5, UniProt Q9FFI2, 337 AA).
A well-characterized housekeeping factor — strong, unambiguous Marchantia ortholog
expected.

```bash
./query.sh examples/AtATG5.fa
# expected top hit: Mp1g12840.1   Prob=100.0   E-value=3.8e-80
```

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

Run the batch:
```bash
./batch_query.sh examples/rqc_batch examples/rqc_batch/results
# writes results/*.hhr; expected top hits in EXPECTED_TOP_HITS.tsv
```

Total wall: ~3 min on a 4-cpu node, against the v1.1 SDS DB.

## Add your own

Drop any `<id>.fa` here (one record per file) and the wrappers will pick it up.
Multi-FASTA input must be split first — see [`../docs/FASTA_FORMAT.md`](../docs/FASTA_FORMAT.md).
