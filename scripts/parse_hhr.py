#!/usr/bin/env python3
"""Parse an hhsearch .hhr file into a tab-separated table of top hits.

Usage:
    parse_hhr.py <input.hhr> <output.tsv> [--top N]

Output columns:
    rank  hit  prob  e_value  p_value  score  ss  cols  q_start  q_end  t_start  t_end  t_len

Top hit is rank 1. Use the TSV with awk/cut/pandas downstream.
"""
from __future__ import annotations
import argparse
import csv
import re
import sys
from pathlib import Path

# example summary line (fixed-ish columns):
#   1 Mp1g12840.1                    100.0 3.8E-80 2.1E-84  572.0   0.0  334    2-336    19-445 (445)
# Match the trailing pattern: cols q_start-q_end t_start-t_end (t_len)
HIT_RE = re.compile(
    r"^\s*(?P<rank>\d+)\s+"
    r"(?P<hit>\S+).*?"
    r"\s+(?P<prob>[\d.]+)"
    r"\s+(?P<evalue>\S+)"
    r"\s+(?P<pvalue>\S+)"
    r"\s+(?P<score>[\d.]+)"
    r"\s+(?P<ss>[\d.\-]+)"
    r"\s+(?P<cols>\d+)"
    r"\s+(?P<qstart>\d+)-(?P<qend>\d+)"
    r"\s+(?P<tstart>\d+)-(?P<tend>\d+)"
    r"\s*\((?P<tlen>\d+)\)"
)


def parse(hhr_path: Path, top_n: int | None = None) -> list[dict]:
    rows: list[dict] = []
    in_table = False
    with hhr_path.open() as fh:
        for line in fh:
            if line.startswith(" No Hit"):
                in_table = True
                continue
            if not in_table:
                continue
            if not line.strip():               # blank line ends the summary table
                break
            if line.lstrip().startswith("No "):  # entered alignment blocks
                break
            m = HIT_RE.match(line)
            if not m:
                continue
            d = m.groupdict()
            for k in ("rank", "cols", "qstart", "qend", "tstart", "tend", "tlen"):
                d[k] = int(d[k])
            d["prob"] = float(d["prob"])
            d["score"] = float(d["score"])
            d["ss"] = float(d["ss"])
            rows.append(d)
            if top_n and len(rows) >= top_n:
                break
    return rows


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("hhr", type=Path, help="input .hhr file")
    p.add_argument("tsv", type=Path, help="output .tsv file")
    p.add_argument("--top", type=int, default=None,
                   help="keep only the top N hits (default: all)")
    args = p.parse_args()

    rows = parse(args.hhr, top_n=args.top)
    if not rows:
        print(f"[parse_hhr] WARN: no hits parsed from {args.hhr}", file=sys.stderr)

    cols = ["rank", "hit", "prob", "evalue", "pvalue", "score", "ss",
            "cols", "qstart", "qend", "tstart", "tend", "tlen"]
    with args.tsv.open("w", newline="") as out:
        w = csv.DictWriter(out, fieldnames=cols, delimiter="\t",
                           extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    print(f"[parse_hhr] {len(rows)} hits -> {args.tsv}", file=sys.stderr)


if __name__ == "__main__":
    main()
