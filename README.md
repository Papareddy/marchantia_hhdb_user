# marchantia_hhdb_user — query the *Marchantia polymorpha* HH-suite database

End-user companion to the build pipeline at
[github.com/Papareddy/hhdb_marchantia](https://github.com/Papareddy/hhdb_marchantia).

> **Zenodo DOI: coming soon.** Public distribution via Zenodo is planned but not yet active. Until then:
> - **Dağdaş-lab users**: the DB is already on bwHPC SDS storage — see [§ For Dağdaş-lab users](#for-dağdaş-lab-users) below.
> - **External users**: please contact [ranjith.bbt@gmail.com](mailto:ranjith.bbt@gmail.com) for a direct copy of the tarball until the Zenodo record is published.

---

## For Dağdaş-lab users

The DB is **already extracted and ready to query** on bwHPC SDS:

```
/mnt/sds-hd/sd25l008/resources/marchantia_hhdb_v7.1/
├── db_v1/                                          ← initial build (97.55 % coverage, 17,565/18,007 proteins)
│   └── marchantia_v7.1_{a3m,hhm,cs219}.{ffdata,ffindex}
└── db_v1.1/                                        ← retry with longer timeouts (≥99.4 % coverage, ETA tomorrow)
    └── marchantia_v7.1_{a3m,hhm,cs219}.{ffdata,ffindex}
```

To query from any bwHPC node that has SDS mounted:

```bash
# Activate any conda env with hh-suite 3.3.0
# (or: mamba create -n hhq -c bioconda hhsuite=3.3.0 && conda activate hhq)
export HHLIB=$CONDA_PREFIX

# Query your factor of interest:
hhsearch \
    -i your_factor.fa \
    -d /mnt/sds-hd/sd25l008/resources/marchantia_hhdb_v7.1/db_v1.1/marchantia_v7.1 \
    -o your_factor.hhr \
    -cpu 4
```

(Use `db_v1` until `db_v1.1` is reported complete in the build pipeline's run report.)

For batch queries, see [`batch_query.sh`](batch_query.sh).
For interpretation of the `.hhr` output, see [`docs/INTERPRETATION.md`](docs/INTERPRETATION.md).

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
./query.sh examples/your_factor.fa
```

---

## What's in the box

```
marchantia_hhdb_user/
├── README.md
├── LICENSE                MIT
├── Makefile               fetch / verify / extract / clean (Zenodo, when published)
├── environment.yml        hh-suite 3.3.0 only (small env)
├── query.sh               single-protein hhsearch wrapper
├── batch_query.sh         loop over a dir of FASTAs (parallel via GNU parallel)
├── examples/
│   └── README.md          add your own .fa files here
└── docs/
    └── INTERPRETATION.md  how to read .hhr output + threshold guidance
```

## Citation

If you use this database, please cite **both**:

1. The DB record (Zenodo DOI: forthcoming) — for the data
2. The HH-suite3 paper — for the homology-search method:
   Steinegger M *et al.* (2019) *BMC Bioinformatics* **20**:473. doi:10.1186/s12859-019-3019-7

## License

MIT for the wrapper code (this repo). The DB itself will be licensed CC-BY-4.0 on Zenodo when published.
