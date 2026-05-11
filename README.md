# marchantia_hhdb_user — query the *Marchantia polymorpha* HH-suite database

End-user companion to the build pipeline at
[github.com/Papareddy/hhdb_marchantia](https://github.com/Papareddy/hhdb_marchantia).

The DB itself is hosted on **Zenodo** (DOI: `10.5281/zenodo.XXXXXXX` — *placeholder; will be filled in once the build completes and the tarball is uploaded*). This repo doesn't ship the DB — `make fetch` pulls it.

## Three-command setup

```bash
git clone https://github.com/Papareddy/marchantia_hhdb_user.git
cd marchantia_hhdb_user

# 1. one-time conda env with hh-suite
mamba env create -f environment.yml
conda activate marchantia_hhdb

# 2. fetch + verify the DB (~30-40 GB compressed, ~250 GB unpacked)
make fetch

# 3. query a factor of interest
./query.sh examples/your_factor.fa
# -> writes examples/your_factor.hhr with top hits
```

## What's in the box

```
marchantia_hhdb_user/
├── README.md
├── LICENSE                MIT
├── Makefile               fetch / verify / extract / clean
├── environment.yml        hh-suite 3.3.0 only (small env)
├── query.sh               single-protein hhsearch wrapper
├── batch_query.sh         loop over a dir of FASTAs (parallel)
├── examples/
│   └── README.md          add your own .fa files here
└── docs/
    └── INTERPRETATION.md  how to read .hhr output + threshold guidance
```

## Citation

If you use this database, please cite **both**:

1. The DB record (Zenodo DOI above) — for the data
2. The HH-suite3 paper — for the homology-search method:
   Steinegger M *et al.* (2019) *BMC Bioinformatics* **20**:473. doi:10.1186/s12859-019-3019-7

See also [`docs/INTERPRETATION.md`](docs/INTERPRETATION.md).

## License

MIT for the wrapper code (this repo). The DB itself (on Zenodo) is licensed CC-BY-4.0.
