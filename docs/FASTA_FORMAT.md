# Input FASTA format — what hhsearch expects

The good news: **line width doesn't matter.** Wrap at 60, 80, 132, or one long line — hhsearch concatenates all non-header lines. But there are real gotchas. Read this once before you spend an afternoon debugging "no hits".

## Minimal valid input

```
>any_id_you_want    arbitrary description
MKLVRKNIEKDNAGQVTLVPEEPEDMWHTYNLVQVGDSLRASTIRKVQTESSTGSVGSNR
VRTTLTLCVEAIDFDSQACQLRVKGTNIQENEYVKMGAYHTIELEPNRQFTLAKKQWDSV
...
```

That's it. One header line starting with `>`, then the protein sequence on any number of following lines.

## Gotchas that bite people in practice

| # | Issue | What happens | Fix |
|---|---|---|---|
| 1 | **Multi-FASTA query** (more than one `>` record in the file) | hhsearch processes ONLY the FIRST record. The rest are silently ignored. | Split into one record per file (see "Splitting" below). |
| 2 | Trailing `*` (stop codon symbol) | Usually tolerated; some versions print a warning. | Strip with `sed -i 's/\*$//' your.fa`. |
| 3 | `U` (selenocysteine) | Silently converted to `C`. Search still works. | No action needed. |
| 4 | `B / Z / J` (ambiguity codes) | Treated as `X` (unknown). | No action needed. |
| 5 | Spaces, numbers, tabs **inside** sequence lines | Stripped. | None — hhsearch handles. |
| 6 | Windows line endings `\r\n` | Usually fine, but if you see "no input file provided" errors, this is the culprit. | `dos2unix your.fa` |
| 7 | Lowercase residues in query | Treated as uppercase. (Lowercase has special meaning **only in A3M format**, not plain FASTA.) | None. |
| 8 | DNA sequence as query | hhsearch runs but gives nonsense — it expects protein. | Translate first. |
| 9 | Very short query (<30 AA) | Profile-profile search needs context; results may be unreliable. | Use only proteins ≥ 50 AA for meaningful hits. |
| 10 | Empty header line (just `>`) | hhsearch may error or give the query a blank name. | Add an ID, e.g. `>my_factor`. |

## Quick sanity check (run before searching)

```bash
head -1 your.fa             # one ">" header
grep -c '^>' your.fa        # should be 1 (else hhsearch ignores the rest)
awk '!/^>/' your.fa | tr -d '\n' | wc -c   # sequence length in AA
awk '!/^>/' your.fa | grep -ic '[^ACDEFGHIKLMNPQRSTVWYBJOUXZ*-]'   # non-AA chars (should be 0)
```

If `grep -c '^>'` reports >1, see **Splitting** below.

## Splitting a multi-FASTA into one file per record

### Option 1 — with seqkit (recommended)
```bash
mamba install -c bioconda seqkit       # if not already
seqkit split -s 1 -O split/ input.fa   # one record per file, named by ID
ls split/
# input.part_001_Mp1g00010.1.fasta
# input.part_002_Mp1g00020.1.fasta
# ...
```

### Option 2 — pure awk (no extra deps)
```bash
mkdir -p split
awk '/^>/ { id = $1; sub(/^>/, "", id); fn = "split/" id ".fa" }
     { print > fn }' input.fa
```

Then loop over the split files:
```bash
DB=/mnt/sds-hd/sd25l008/resources/marchantia_hhdb_v7.1/db_v1/marchantia_v7.1
mkdir -p results
for fa in split/*.fa; do
  out=results/$(basename "$fa" .fa).hhr
  hhsearch -i "$fa" -d "$DB" -o "$out" -cpu 4
done
```

Or with GNU parallel for speed (≈ 5,000 queries/h on a 16-core node):
```bash
ls split/*.fa | parallel --bar -j 8 \
  "hhsearch -i {} -d '$DB' -o results/{/.}.hhr -cpu 2 -v 0"
```

(The wrapper [`batch_query.sh`](../batch_query.sh) in this repo does this for you.)

## Why "only first record" — short hhsearch primer

hhsearch builds a profile-HMM from the query first, then scores it against every HMM in the DB. The HMM-building step is anchored to one query sequence. If you pass a multi-record FASTA, hhsearch interprets it as "this is already an MSA / A3M" and uses only the first sequence as the seed — silently. There's no warning. **Always split first.**

## What about `hhblits` (iterative search)?

Same FASTA rules. `hhblits` is the iterative cousin of `hhsearch` — it builds a deeper MSA across multiple iterations against the same DB. Useful when you suspect a remote homolog and `hhsearch` returns low-probability hits. Usage:
```bash
hhblits -i your.fa -d "$DB" -oa3m your.a3m -o your.hhr -n 3 -e 1e-3 -cpu 4
```

## Reading the .hhr output

See [`INTERPRETATION.md`](INTERPRETATION.md).
