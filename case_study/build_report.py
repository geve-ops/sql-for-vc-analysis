"""Run the case-study queries and write case_study/README.md and the charts in case_study/charts/.

    python case_study/build_report.py

The text lives in case_study/template.md. Placeholders:
    {{table:NAME}}   result of queries/NAME.sql as a Markdown table
    {{sql:NAME}}     the query itself, in a collapsed block
    {{chart:NAME}}   a chart drawn by the function of that name below
    {{as_of}}        date of the latest weekly run in the data
"""

import os
import re
import sys
from urllib.parse import urlparse

import duckdb
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DB = os.path.join(ROOT, "dealflow.duckdb")
QUERIES = os.path.join(HERE, "queries")
CHARTS = os.path.join(HERE, "charts")

# Light chart surface and the first categorical slots of the reference palette.
SURFACE, INK, INK_2, GRID, MUTED = "#fcfcfb", "#0b0b0b", "#52514e", "#e6e5e0", "#b5b3ab"
SERIES = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4"]

plt.rcParams.update({
    "font.family": "DejaVu Sans", "font.size": 10, "text.color": INK, "axes.labelcolor": INK_2,
    "axes.edgecolor": GRID, "xtick.color": INK_2, "ytick.color": INK_2, "figure.facecolor": SURFACE,
    "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE, "svg.hashsalt": "sql-learning-kit",
})


def query(con, name):
    with open(os.path.join(QUERIES, f"{name}.sql"), encoding="utf-8") as f:
        rel = con.sql(f.read())
    return rel.columns, rel.fetchall()


# --- tables ----------------------------------------------------------------------------------

def fmt(value):
    if value is None:
        return "-"
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, float):
        return f"{value:,.2f}".rstrip("0").rstrip(".") if value != int(value) else f"{int(value):,}"
    text = str(value)
    if text.startswith("http"):
        host = urlparse(text).netloc.removeprefix("www.")
        return f"[{host}]({text})"
    return text.replace("|", ",").replace("\n", " ")


def markdown_table(cols, rows):
    numeric = [all(isinstance(r[i], (int, float)) and not isinstance(r[i], bool) for r in rows if r[i] is not None)
               for i in range(len(cols))]
    out = ["| " + " | ".join(cols) + " |",
           "|" + "|".join("---:" if n else "---" for n in numeric) + "|"]
    out += ["| " + " | ".join(fmt(v) for v in r) + " |" for r in rows]
    return "\n".join(out)


# --- charts ----------------------------------------------------------------------------------

def finish(fig, ax, name, title, note):
    fig.text(0.01, 0.97, title, fontsize=12, fontweight="bold", va="top")
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.tick_params(length=0)
    fig.text(0.01, 0.01, note, fontsize=8, color=INK_2)
    fig.tight_layout(rect=(0, 0.04, 1, 0.92))
    os.makedirs(CHARTS, exist_ok=True)
    path = os.path.join(CHARTS, f"{name}.png")
    fig.savefig(path, dpi=150, metadata={"Software": None})
    plt.close(fig)
    return f"![{title}](charts/{name}.png)"


def fund_holdings(con):
    cols, rows = query(con, "02_fund_overlap")
    rows = sorted(rows, key=lambda r: (-r[1], r[0]))[::-1]
    fig, ax = plt.subplots(figsize=(8, 4.2))
    colors = [SERIES[0] if r[4] else MUTED for r in rows]
    ax.barh([r[0] for r in rows], [r[1] for r in rows], color=colors, height=0.6)
    for i, r in enumerate(rows):
        ax.text(r[1] + 0.15, i, str(r[1]), va="center", fontsize=9, color=INK)
    ax.xaxis.set_visible(False)
    return finish(fig, ax, "fund_holdings", "Current holdings on the watchlist, by Greek fund",
                  "Blue: the four target funds. Grey: other Greek funds. Source: market map investors column.")


def weekly_signals(con):
    cols, rows = query(con, "05_weekly_signals")
    signals = ["funding", "grants", "press", "hiring", "github"]
    fig, ax = plt.subplots(figsize=(8, 4.2))
    labels = [r[0].strftime("%d %b") for r in rows]
    bottom = [0] * len(rows)
    for k, sig in enumerate(signals):
        vals = [r[cols.index(sig)] for r in rows]
        ax.bar(labels, vals, bottom=bottom, color=SERIES[k], width=0.55, label=sig,
               edgecolor=SURFACE, linewidth=1.5)
        bottom = [b + v for b, v in zip(bottom, vals)]
    for i, total in enumerate(bottom):
        ax.text(i, total + 0.8, str(total), ha="center", fontsize=9, color=INK)
    ax.set_ylabel("points, all 69 companies")
    ax.yaxis.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.legend(ncol=5, frameon=False, loc="upper left", bbox_to_anchor=(0, 1.02), fontsize=9)
    ax.set_ylim(0, max(bottom) * 1.25)
    return finish(fig, ax, "weekly_signals", "Weekly score points by signal",
                  "Source: vc-dealflow-tracker data/scores.csv, weekly runs 26 Oct to 16 Nov 2026.")


def eu_grants(con):
    cols, rows = query(con, "04_eu_grants")
    rows = list(reversed(rows))
    fig, ax = plt.subplots(figsize=(8, 4.6))
    colors = [MUTED if r[6] == "-" else SERIES[0] for r in rows]
    ax.barh([r[0] for r in rows], [r[2] for r in rows], color=colors, height=0.6)
    for i, r in enumerate(rows):
        ax.text(r[2] + 0.3, i, str(r[2]), va="center", fontsize=9, color=INK)
    ax.xaxis.set_visible(False)
    return finish(fig, ax, "eu_grants", "CORDIS projects per company (top 12)",
                  "Blue: a Greek fund currently holds it. Grey: no current Greek fund. Source: CORDIS, via the tracker.")


def recent_rounds(con):
    sql = open(os.path.join(QUERIES, "03_recent_rounds.sql"), encoding="utf-8").read()
    # Reuse the query's own filtering: the CTE "rounds" plus the same WHERE as the summary.
    cte = sql[sql.index("WITH rounds"):sql.index("SELECT currency")]
    rows = con.sql(cte + "SELECT currency, amount_m, company FROM rounds "
                         "WHERE currency <> '' AND round_month >= DATE '2025-01-01'").fetchall()
    order = ["EUR", "USD", "GBP"]
    fig, ax = plt.subplots(figsize=(8, 3.4))
    for r in rows:
        y = order.index(r[0])
        ax.scatter(r[1], y, s=46, color=SERIES[0], edgecolor=SURFACE, linewidth=1.5, zorder=3)
    for cur in order:
        amounts = sorted(r[1] for r in rows if r[0] == cur)
        top = [r for r in rows if r[0] == cur and r[1] == amounts[-1]][0]
        ax.annotate(top[2].split(" (")[0], (top[1], order.index(cur)), xytext=(0, 9),
                    textcoords="offset points", ha="center", fontsize=8, color=INK_2)
    ax.set_xscale("log")
    ax.set_xticks([0.5, 1, 2, 5, 10, 20, 50, 100, 300])
    ax.set_xticklabels(["0.5", "1", "2", "5", "10", "20", "50", "100", "300"])
    ax.set_xlabel("round size, millions in the stated currency (log scale)")
    ax.set_yticks(range(len(order)))
    ax.set_yticklabels(order)
    ax.set_ylim(-0.6, len(order) - 0.4)
    ax.xaxis.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    return finish(fig, ax, "recent_rounds", "Confirmed round sizes since January 2025",
                  "One dot per round. Currencies are not converted. Sources: market map source_link column.")


CHART_FUNCS = {f.__name__: f for f in (fund_holdings, weekly_signals, eu_grants, recent_rounds)}


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if not os.path.exists(DB):
        sys.exit("dealflow.duckdb not found. Build it first:  python build_db.py")
    con = duckdb.connect(DB, read_only=True)
    with open(os.path.join(HERE, "template.md"), encoding="utf-8") as f:
        text = f.read()

    as_of = con.sql("SELECT max(date) FROM scores").fetchall()[0][0]

    def fill(m):
        kind, name = m.group(1), m.group(2)
        if kind == "table":
            return markdown_table(*query(con, name))
        if kind == "sql":
            with open(os.path.join(QUERIES, f"{name}.sql"), encoding="utf-8") as f:
                sql = f.read().strip()
            return (f"<details><summary>SQL: <code>queries/{name}.sql</code></summary>\n\n"
                    f"```sql\n{sql}\n```\n</details>")
        if kind == "chart":
            return CHART_FUNCS[name](con)
        raise ValueError(f"unknown placeholder {m.group(0)}")

    text = re.sub(r"\{\{(table|sql|chart):([\w]+)\}\}", fill, text)
    text = text.replace("{{as_of}}", f"{as_of.day} {as_of:%B %Y}")
    left = re.findall(r"\{\{[^}]*\}\}", text)
    if left:
        sys.exit(f"Unfilled placeholders: {left}")
    out = os.path.join(HERE, "README.md")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(f"Wrote case_study/README.md and {len(CHART_FUNCS)} charts (data as of {as_of})")


if __name__ == "__main__":
    main()
