# Examples

Drop your query FASTAs in this folder, then:

```bash
./query.sh examples/your_factor.fa
```

Each FASTA should contain one protein sequence. Multi-record FASTAs work but
hhsearch only uses the first record.

## Suggested test queries (post-DB-build)

After `make fetch` you can sanity-check the install with any *Marchantia*
protein that's known to have homologs in the same proteome. Examples (replace
with real IDs once the DB is published):

```bash
# A well-conserved housekeeping factor — should self-hit + find paralogs
./query.sh examples/MpRPS6.fa

# A factor of biological interest
./query.sh examples/MpHB1.fa
```

For a many-query batch:
```bash
./batch_query.sh examples/ results/ 10
```
