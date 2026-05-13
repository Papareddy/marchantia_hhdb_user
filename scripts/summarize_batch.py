#!/usr/bin/env python3
"""Aggregate per-query hits TSVs into a single SUMMARY.tsv + SUMMARY.pdf.

Usage:
    summarize_batch.py <results_dir> <summary.tsv> <summary.pdf>

Reads <results_dir>/*.hits.tsv (one per query), extracts the rank-1 hit of each,
and produces:
    summary.tsv  — one row per query (query, top_hit, prob, evalue, score, cols)
    summary.pdf  — horizontal bar chart of top-hit probabilities across queries
"""
from __future__ import annotations
import argparse
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("results_dir", type=Path)
    p.add_argument("summary_tsv", type=Path)
    p.add_argument("summary_pdf", type=Path)
    a = p.parse_args()

    rows = []
    for tsv in sorted(a.results_dir.glob("*.hits.tsv")):
        try:
            df = pd.read_csv(tsv, sep="\t",
                             dtype={"evalue": str, "pvalue": str})
        except Exception as e:
            print(f"[summarize] skip {tsv.name}: {e}", file=sys.stderr)
            continue
        if df.empty:
            print(f"[summarize] no hits in {tsv.name}", file=sys.stderr)
            continue
        top = df.iloc[0]
        rows.append({
            "query":   tsv.stem.replace(".hits", ""),
            "top_hit": top["hit"],
            "prob":    float(top["prob"]),
            "evalue":  top["evalue"],
            "score":   float(top["score"]),
            "cols":    int(top["cols"]),
            "q_start": int(top["qstart"]),
            "q_end":   int(top["qend"]),
            "t_start": int(top["tstart"]),
            "t_end":   int(top["tend"]),
            "t_len":   int(top["tlen"]),
        })
    if not rows:
        sys.exit("[summarize] no per-query TSVs found")

    s = pd.DataFrame(rows).sort_values("prob", ascending=False)
    s.to_csv(a.summary_tsv, sep="\t", index=False)
    print(f"[summarize] {len(s)} queries -> {a.summary_tsv}", file=sys.stderr)

    # plot: ranked bar of top-hit probability per query
    fig, ax = plt.subplots(figsize=(9, 1.0 + 0.45 * len(s)),
                           constrained_layout=True)
    colors = ["#2c7fb8" if p >= 90 else "#7fcdbb" if p >= 50 else "#c7e9b4"
              for p in s["prob"]]
    labels = [f"{q}  →  {h}" for q, h in zip(s["query"], s["top_hit"])]
    ax.barh(labels[::-1], s["prob"][::-1], color=colors[::-1],
            edgecolor="black", linewidth=0.4)
    for i, (_, row) in enumerate(s[::-1].iterrows()):
        ax.text(min(row["prob"] + 1, 101), i, f"E={row['evalue']}",
                va="center", fontsize=7, color="#444")
    ax.set_xlim(0, 102)
    ax.set_xlabel("Probability of best Marchantia hit")
    ax.set_title(f"Batch top-hit summary — {len(s)} queries", fontsize=11)
    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)
    fig.savefig(a.summary_pdf, dpi=150)
    print(f"[summarize] wrote {a.summary_pdf}", file=sys.stderr)


if __name__ == "__main__":
    main()
