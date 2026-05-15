# marchantia_hhdb_user — query the *Marchantia polymorpha* HH-suite database

End-user companion to the build pipeline at
[github.com/Papareddy/hhdb_marchantia](https://github.com/Papareddy/hhdb_marchantia).

> **Zenodo DOI: coming soon.** Public distribution via Zenodo is planned but not yet active. Until then:
> - **Dagdas-lab users**: the DB is already on bwHPC SDS storage — see [§ For Dagdas-lab users](#for-dagdas-lab-users) below.
> - **External users**: please contact [ranjith.bbt@gmail.com](mailto:ranjith.bbt@gmail.com) for a direct copy of the tarball until the Zenodo record is published.

---

## For Dagdas-lab users

The DB is **already extracted and ready to query** on bwHPC SDS:

```
/mnt/sds-hd/sd25l008/resources/marchantia_hhdb_v7.1/
└── db_v1.1/         ← 18,007 profiles (100 % proteome coverage), validated
    └── marchantia_v7.1_{a3m,hhm,cs219}.{ffdata,ffindex}
```

To query from any bwHPC node that has SDS mounted:

```bash
# Activate the bundled conda env (one-time):
mamba env create -f environment.yml      # installs hh-suite + python + pandas + matplotlib
conda activate marchantia_hhdb

export HHLIB=$CONDA_PREFIX
export MARCHANTIA_HHDB=/mnt/sds-hd/sd25l008/resources/marchantia_hhdb_v7.1/db_v1.1/marchantia_v7.1

# Single query — one command, gets you raw .hhr + parsed .tsv + .pdf figure:
./query.sh examples/AtATG5.fa
#   -> results/AtATG5.hhr        full hhsearch output
#   -> results/AtATG5.hits.tsv   top-10 hits, tab-separated
#   -> results/AtATG5.pdf        figure (bar chart + coverage map)

# Batch query (multi-FASTA OR directory of single-FASTAs).
# Output dir is optional — defaults to results/<basename of input>:
./batch_query.sh examples/rqc_batch                          # -> results/rqc_batch/
./batch_query.sh my_queries.fa                               # -> results/my_queries/  (auto-splits multi-FASTA)
./batch_query.sh examples/rqc_batch /my/custom/outdir        # explicit outdir still works
#   -> <outdir>/<id>.{hhr,hits.tsv,pdf}   one set per protein
#   -> <outdir>/SUMMARY.tsv               one row per query (top hit)
#   -> <outdir>/SUMMARY.pdf               aggregate top-hit figure
```

See [`examples/README.md`](examples/README.md) for the bundled
single-query (`AtATG5.fa`) and multi-query (`rqc_batch/` — 6 conserved
RQC factors) test sets, with expected top hits in
[`examples/rqc_batch/EXPECTED_TOP_HITS.tsv`](examples/rqc_batch/EXPECTED_TOP_HITS.tsv).

For interpretation of the `.hhr` output, see [`docs/INTERPRETATION.md`](docs/INTERPRETATION.md).

## Input FASTA — what hhsearch expects

**Line width doesn't matter** — wrap at any width or one long line. But:

| Quirk | Behavior |
|---|---|
| **Multi-FASTA query** (>1 `>` record) | hhsearch processes ONLY the first. Rest ignored silently. **Split first.** |
| Trailing `*` (stop codon) | Tolerated (may warn). |
| `U` (selenocysteine) | Silently → `C`. |
| `B/Z/J` (ambiguity codes) | Treated as `X`. |
| Spaces / numbers / tabs in sequence | Stripped. |
| Windows line endings `\r\n` | If "no input file" error → `dos2unix your.fa`. |
| Lowercase residues | Treated as uppercase (different meaning in A3M only). |
| DNA query | Runs, gives nonsense — needs protein. |
| Very short query (<30 AA) | Results unreliable; ≥50 AA recommended. |

Quick check before searching:
```bash
grep -c '^>' your.fa    # must be 1 (else only first record is searched)
```
Full details + split helpers + parallel batch loop: **[`docs/FASTA_FORMAT.md`](docs/FASTA_FORMAT.md)**.

---

## Three-command setup (for everyone else, after Zenodo is live)

```bash
git clone https://github.com/Papareddy/marchantia_hhdb_user.git
cd marchantia_hhdb_user

# 1. one-time conda env with hh-suite
mamba env create -f environment.yml
conda activate marchantia_hhdb

# 2. fetch + verify the DB (will be ~30-40 GB compressed, ~250 GB unpacked)
#    waiting on Zenodo DOI — Makefile will fetch from Zenodo once published
make fetch ZENODO_RECORD=<doi-number>

# 3. query a factor of interest
./query.sh examples/AtATG5.fa
```

---

## What's in the box

```
marchantia_hhdb_user/
├── README.md
├── LICENSE                MIT
├── Makefile               fetch / verify / extract / clean (Zenodo, when published)
├── environment.yml        hh-suite 3.3.0 only (small env)
├── query.sh               single-protein wrapper → .hhr + .hits.tsv + .pdf
├── batch_query.sh         loop over a dir of FASTAs (parallel via GNU parallel)
├── scripts/
│   ├── parse_hhr.py        .hhr → top-N hits TSV
│   └── plot_hhr.py         hits TSV → ranking + coverage PDF/PNG figure
├── examples/
│   ├── AtATG5.fa                       single-query test (expected Mp1g12840.1)
│   ├── AtATG5_example_output.pdf       reference rendering of the query.sh PDF
│   ├── rqc_batch/                      6 conserved RQC factors (PELO/HBS1L/NEMF/LTN1/ABCE1/ZNF598)
│   ├── rqc_batch/EXPECTED_TOP_HITS.tsv expected Marchantia orthologs
│   └── README.md
└── docs/
    ├── FASTA_FORMAT.md    input requirements, gotchas, multi-FASTA splitting
    └── INTERPRETATION.md  how to read .hhr output + threshold guidance
```

## Citation

If you use this database, please cite **both**:

1. The DB record (Zenodo DOI: forthcoming) — for the data
2. The HH-suite3 paper — for the homology-search method:
   Steinegger M *et al.* (2019) *BMC Bioinformatics* **20**:473. doi:10.1186/s12859-019-3019-7

## License

MIT for the wrapper code (this repo). The DB itself will be licensed CC-BY-4.0 on Zenodo when published.
