# Interpreting hhsearch / hhblits output

The `.hhr` file is the human-readable result. Its first hit block tells you the
most likely homolog of your query among the *Marchantia polymorpha* primary
proteome.

## Output structure

```
Query         your_factor                ← your input ID
Match_columns 410                        ← query length (in match columns)
No_of_seqs    1 out of 1
Neff          1                          ← effective # sequences in your query MSA
Searched_HMMs 17,905                     ← # DB profiles scanned (= proteome size minus permanent failures)
Date          2026-MM-DD ...
Command       hhsearch -i ... -d ... -o ...

 No Hit                            Prob E-value P-value  Score    SS Cols Query HMM  Template HMM
  1 Mp1g00080.1                    99.9   3e-72   3e-77  423.7   0.0  385   1-410     4-410   (410)
  2 Mp2g15500.1                    98.2   2e-21   2e-26  111.2   0.0  220  10-260    50-300   (412)
  ...

No 1
>Mp1g00080.1
Probab=99.92  E-value=3e-72  Score=423.74  Aligned_cols=385  Identities=72%  Similarity=1.234  ...

Q your_factor    1   M A K L V T ...
Q Consensus      1   m a k l v t ...
                     | | | + | |   <- the 1-line confidence indicator (| > + > .)
T Mp1g00080.1    4   M A K I V T ...
T Consensus      4   m a k i v t ...
```

## Key numbers (what to trust)

| Field | What it is | Threshold for "real" |
|---|---|---|
| **Prob** | HH-suite's posterior probability of true homology (0–100). The most informative single column. | >50 = likely homolog; >90 = essentially certain; >99 = the same protein family |
| **E-value** | Expected hits at this score by chance, given the DB size. | <1e-3 = strong; <1e-10 = unambiguous |
| **Score** | Raw HH alignment score. Mostly useful for ranking similar hits. | — |
| **Cols** | Number of aligned match columns. | A long query getting only a short hit (<30 cols) often means a single shared domain, not full homology |
| **Identities** | Fraction of identical residues in the aligned region. | Reported for transparency; HH-suite's strength is that it works **below 20% identity** where BLAST fails |
| **Neff** | Effective MSA depth for the alignment. | Lower means less information; very low Neff (~1) on the template side suggests the DB hit is itself an orphan profile |

## Common workflow

1. **Skim the ranked list** at the top of the .hhr.
2. **Trust hits with Prob ≥ 90** as homologs.
3. **For 50 ≤ Prob < 90**, check the alignment block (`No 1`, `No 2`, ...): look for a `|` confidence row spanning most of the query, and check that catalytic / structural residues align.
4. **Below Prob 50**: treat as a fishing expedition. Sometimes useful for ancient domain recognition; often false positive.

## "I expected a hit but got nothing"

- Did you query the correct sequence? Make sure your `.fa` has one sequence.
- Is the query unusually short (<60 AA)? HMM-vs-HMM struggles below this.
- Try **hhblits** (iterative, more sensitive) instead of hhsearch:
  ```bash
  hhblits -i your_factor.fa -d db/marchantia_v7.1 -oa3m your_factor.a3m -o your_factor.hhr -n 3 -cpu 4
  ```
- Remember: the DB is a single proteome (~18 k profiles). If the closest *Marchantia* homolog is genuinely absent (e.g. lineage-specific factor), there is nothing to find here. Use UniRef30 for broader phylogenetic reach.

## Programmatic parsing

The .hhr is line-oriented. Quick one-liner to extract top hit:
```bash
awk '/^ No Hit/{getline; getline; print; exit}' your_factor.hhr
```
For Python: there's `hh-suite/scripts/hhresult_to_table.py` (in the hh-suite source) for tabular output.

## References

- HH-suite3 paper — Steinegger M *et al.* (2019) *BMC Bioinformatics* **20**:473.
- HH-suite user guide — https://github.com/soedinglab/hh-suite/blob/master/data/hhsuite-userguide.pdf
