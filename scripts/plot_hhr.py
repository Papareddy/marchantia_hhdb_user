#!/usr/bin/env python3
"""Plot top hits + coverage diagram from an hhsearch hits TSV.

Usage:
    plot_hhr.py <hits.tsv> <output.pdf> [--query-name NAME] [--top N]

Produces a single PDF (or PNG if extension is .png) with two panels:
    A. Top-N hits ranked by probability (horizontal bar chart)
    B. Coverage map: query span + template span for the top 5 hits

Reads the TSV produced by parse_hhr.py.
"""
from __future__ import annotations
import argparse
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # headless on HPC
import matplotlib.pyplot as plt
import pandas as pd


def make_figure(df: pd.DataFrame, query_name: str, out_path: Path, top: int = 10) -> None:
    df = df.head(top).copy()
    if df.empty:
        print("[plot_hhr] no hits to plot", file=sys.stderr)
        return

    fig, (ax_bar, ax_cov) = plt.subplots(
        2, 1, figsize=(9, 1.5 + 0.4 * len(df) + 2.6),
        gridspec_kw=dict(height_ratios=[1.2, 1.0], hspace=0.5),
        constrained_layout=True,    # silences the tight_layout warning
    )

    # ---------- A. probability bars ----------
    colors = ["#2c7fb8" if p >= 90 else "#7fcdbb" if p >= 50 else "#c7e9b4"
              for p in df["prob"]]
    ax_bar.barh(df["hit"][::-1], df["prob"][::-1], color=colors[::-1],
                edgecolor="black", linewidth=0.4)
    ax_bar.set_xlim(0, 102)
    ax_bar.set_xlabel("Probability (HH-suite)")
    ax_bar.set_title(f"Top {len(df)} Marchantia hits for {query_name}", fontsize=11)
    for spine in ("top", "right"):
        ax_bar.spines[spine].set_visible(False)
    # annotate E-values (preserve the original scientific notation string)
    for i, (_, row) in enumerate(df[::-1].iterrows()):
        ax_bar.text(min(row["prob"] + 1, 101), i, f"E={row['evalue']}",
                    va="center", fontsize=7, color="#444")
    # NOTE: evalue is read as a string by pandas because the column has mixed
    # forms like "3.8E-80" and "28". If pandas inferred it as float we'd lose
    # the scientific notation. Force str dtype on read.

    # ---------- B. coverage map (top 5) ----------
    top5 = df.head(5).copy()
    # query length = max qend (the hhsearch summary doesn't store qlen explicitly here)
    qlen = int(max(top5["qend"].max(), 1))
    # template length per hit is tlen (already a column)
    y_offsets = list(range(len(top5)))
    for i, (_, row) in enumerate(top5.iterrows()):
        y = len(top5) - 1 - i
        # query bar (top half)
        ax_cov.barh(y + 0.18, qlen, left=0, height=0.18, color="#dddddd",
                    edgecolor="black", linewidth=0.3)
        ax_cov.barh(y + 0.18, row["qend"] - row["qstart"], left=row["qstart"],
                    height=0.18, color="#2c7fb8", edgecolor="black", linewidth=0.3)
        # template bar (bottom half, scaled to its own length so each row is a relative coord)
        tlen = int(row["tlen"])
        scale = qlen / tlen if tlen else 1.0
        ax_cov.barh(y - 0.18, tlen * scale, left=0, height=0.18,
                    color="#dddddd", edgecolor="black", linewidth=0.3)
        ax_cov.barh(y - 0.18, (row["tend"] - row["tstart"]) * scale,
                    left=row["tstart"] * scale, height=0.18, color="#fd8d3c",
                    edgecolor="black", linewidth=0.3)
        ax_cov.text(qlen * 1.02, y, f"{row['hit']}  ({tlen} aa)", va="center",
                    fontsize=8, color="#333")

    ax_cov.set_yticks(y_offsets)
    ax_cov.set_yticklabels([])
    ax_cov.set_xlabel(f"Position  (query: {qlen} match cols)")
    ax_cov.set_xlim(0, qlen * 1.30)
    ax_cov.set_title("Coverage: query (blue, top) vs template (orange, bottom)  — top 5",
                     fontsize=10, loc="left")
    for spine in ("top", "right"):
        ax_cov.spines[spine].set_visible(False)

    fig.savefig(out_path, dpi=150)
    print(f"[plot_hhr] wrote {out_path}", file=sys.stderr)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("tsv", type=Path, help="input hits .tsv (from parse_hhr.py)")
    p.add_argument("out", type=Path, help="output figure (.pdf or .png)")
    p.add_argument("--query-name", default="query", help="header label")
    p.add_argument("--top", type=int, default=10, help="number of hits to plot")
    args = p.parse_args()

    df = pd.read_csv(args.tsv, sep="\t",
                     dtype={"evalue": str, "pvalue": str})  # keep scientific notation
    make_figure(df, args.query_name, args.out, top=args.top)


if __name__ == "__main__":
    main()
