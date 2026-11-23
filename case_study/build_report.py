"""Run the case-study queries and write case_study/README.md and the charts in case_study/charts/.

    python case_study/build_report.py

The text lives in case_study/template.md, and the findings table on the front page in
case_study/findings.md. No table and no number in either is typed by hand. Placeholders:
    {{table:NAME}}            result of queries/NAME.sql as a Markdown table
    {{sql:NAME}}              the query itself, in a collapsed block
    {{chart:NAME}}            a chart drawn by the function of that name below
    {{fact:METRIC}}           one named figure from queries/00_key_figures.sql
    {{cell:NAME|KEY=VAL|COL}} one value from a query result: column COL of the row where KEY = VAL
    {{as_of}}                 date of the latest weekly run in the data
"""

import os
import re
import sys
from urllib.parse import urlparse

import duckdb
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DB = os.path.join(ROOT, "dealflow.duckdb")
QUERIES = os.path.join(HERE, "queries")
CHARTS = os.path.join(HERE, "charts")

# Light chart surface and the first categorical slots of the reference palette.
SURFACE, INK, INK_2, GRID, MUTED = "#fcfcfb", "#0b0b0b", "#52514e", "#e6e5e0", "#b5b3ab"
SERIES = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4"]

plt.rcParams.update(
    {
        "font.family": "DejaVu Sans",
        "font.size": 10,
        "text.color": INK,
        "axes.labelcolor": INK_2,
        "axes.edgecolor": GRID,
        "xtick.color": INK_2,
        "ytick.color": INK_2,
        "figure.facecolor": SURFACE,
        "axes.facecolor": SURFACE,
        "savefig.facecolor": SURFACE,
        "svg.hashsalt": "sql-learning-kit",
    }
)


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
    numeric = [
        all(isinstance(r[i], (int, float)) and not isinstance(r[i], bool) for r in rows if r[i] is not None)
        for i in range(len(cols))
    ]
    out = ["| " + " | ".join(cols) + " |", "|" + "|".join("---:" if n else "---" for n in numeric) + "|"]
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
    _cols, rows = query(con, "02_fund_overlap")
    rows = sorted(rows, key=lambda r: (-r[1], r[0]))[::-1]
    fig, ax = plt.subplots(figsize=(8, 4.2))
    colors = [SERIES[0] if r[4] else MUTED for r in rows]
    ax.barh([r[0] for r in rows], [r[1] for r in rows], color=colors, height=0.6)
    for i, r in enumerate(rows):
        ax.text(r[1] + 0.15, i, str(r[1]), va="center", fontsize=9, color=INK)
    ax.xaxis.set_visible(False)
    return finish(
        fig,
        ax,
        "fund_holdings",
        "Current holdings on the watchlist, by Greek fund",
        "Blue: target funds (egg has no tagged holding). Grey: other Greek funds. Source: market map investors column.",
    )


def weekly_signals(con):
    cols, rows = query(con, "05_weekly_signals")
    all_signals = ["funding", "grants", "press", "hiring", "github"]
    # A signal with no points in any run is left out of the bars and named in the note instead.
    signals = [sig for sig in all_signals if any(r[cols.index(sig)] for r in rows)]
    empty = [sig for sig in all_signals if sig not in signals]
    fig, ax = plt.subplots(figsize=(8, 4.2))
    labels = [r[0].strftime("%d %b") for r in rows]
    bottom = [0] * len(rows)
    for sig in signals:
        vals = [r[cols.index(sig)] for r in rows]
        color = SERIES[all_signals.index(sig)]
        ax.bar(labels, vals, bottom=bottom, color=color, width=0.55, label=sig, edgecolor=SURFACE, linewidth=1.5)
        bottom = [b + v for b, v in zip(bottom, vals, strict=False)]
    for i, total in enumerate(bottom):
        ax.text(i, total + 0.8, str(total), ha="center", fontsize=9, color=INK)
    ax.set_ylabel("points, all 69 companies")
    ax.yaxis.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.legend(ncol=5, frameon=False, loc="upper left", bbox_to_anchor=(0, 1.02), fontsize=9)
    ax.set_ylim(0, max(bottom) * 1.25)
    return finish(
        fig,
        ax,
        "weekly_signals",
        "Weekly score points by signal",
        "Source: vc-dealflow-tracker data/scores.csv, weekly runs 26 Oct to 16 Nov 2026, rescored after the fix."
        + (f" No points from: {', '.join(empty)}." if empty else ""),
    )


def eu_grants(con):
    _cols, rows = query(con, "04_eu_grants")
    rows = list(reversed(rows))
    fig, ax = plt.subplots(figsize=(8, 4.6))
    colors = [MUTED if r[6] == "-" else SERIES[0] for r in rows]
    ax.barh([r[0] for r in rows], [r[2] for r in rows], color=colors, height=0.6)
    for i, r in enumerate(rows):
        ax.text(r[2] + 0.3, i, str(r[2]), va="center", fontsize=9, color=INK)
    ax.xaxis.set_visible(False)
    return finish(
        fig,
        ax,
        "eu_grants",
        "CORDIS projects per company (top 12)",
        "Blue: held by a current Greek fund. Grey: no current Greek fund. Source: CORDIS, via the tracker.",
    )


def recent_rounds(con):
    rows = con.sql("""
        SELECT r.currency, r.amount_m, d.company
        FROM analytics.fct_last_round AS r
        JOIN analytics.dim_company AS d ON d.company_id = r.company_id
        WHERE d.on_watchlist AND r.is_usable AND r.round_month >= DATE '2025-01-01'
    """).fetchall()
    order = ["EUR", "USD", "GBP"]
    fig, ax = plt.subplots(figsize=(8, 3.4))
    for r in rows:
        ax.scatter(r[1], order.index(r[0]), s=46, color=SERIES[0], edgecolor=SURFACE, linewidth=1.5, zorder=3)
    for cur in order:
        top = max((r for r in rows if r[0] == cur), key=lambda r: r[1])
        ax.annotate(
            top[2].split(" (")[0],
            (top[1], order.index(cur)),
            xytext=(0, 9),
            textcoords="offset points",
            ha="center",
            fontsize=8,
            color=INK_2,
        )
    ax.set_xscale("log")
    ax.set_xticks([0.5, 1, 2, 5, 10, 20, 50, 100, 300])
    ax.set_xticklabels(["0.5", "1", "2", "5", "10", "20", "50", "100", "300"])
    ax.set_xlabel("round size, millions in the stated currency (log scale)")
    ax.set_yticks(range(len(order)))
    ax.set_yticklabels(order)
    ax.set_ylim(-0.6, len(order) - 0.4)
    ax.xaxis.grid(True, color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    return finish(
        fig,
        ax,
        "recent_rounds",
        "Confirmed round sizes since January 2025",
        "One dot per round. Currencies are not converted. Sources: market map source_link column.",
    )


def ranking_shift(con):
    cols, rows = query(con, "05c_momentum_check")
    now, pub, name = cols.index("rank"), cols.index("rank_as_published"), cols.index("company")
    rows = [r for r in rows if r[now] is not None and r[pub] is not None]
    fig, ax = plt.subplots(figsize=(8, 5.2))
    for r in rows:
        moved = r[now] - r[pub] >= 2  # fell: its published rank rested on points the fix removed
        color, width, z = (SERIES[1], 2.2, 3) if moved else (MUTED, 1.2, 2)
        ax.plot([0, 1], [r[pub], r[now]], color=color, linewidth=width, zorder=z, solid_capstyle="round")
        ax.scatter([0, 1], [r[pub], r[now]], s=28, color=color, edgecolor=SURFACE, linewidth=1.2, zorder=z + 1)
        label = r[name].split(" (")[0]
        weight = "bold" if moved else "normal"
        ax.text(-0.04, r[pub], f"{label}  {r[pub]}", ha="right", va="center", fontsize=8.5, color=INK, weight=weight)
        ax.text(1.04, r[now], f"{r[now]}  {label}", ha="left", va="center", fontsize=8.5, color=INK, weight=weight)
    ax.set_xlim(-0.9, 1.9)
    ax.set_ylim(max(max(r[now], r[pub]) for r in rows) + 0.7, 0.3)
    ax.set_xticks([0, 1])
    ax.set_xticklabels(["as first published", "now"], fontsize=10, color=INK)
    ax.xaxis.set_ticks_position("top")
    ax.yaxis.set_visible(False)
    ax.spines["bottom"].set_visible(False)
    return finish(
        fig,
        ax,
        "ranking_shift",
        "Top Movers rank, as first published and after the tracker's fix",
        "Orange: fell once misfired points were removed; the rest moved up. Model: fct_weekly_score_original_rule.",
    )


CHART_FUNCS = {f.__name__: f for f in (fund_holdings, weekly_signals, eu_grants, recent_rounds, ranking_shift)}


# --- README banner ---------------------------------------------------------------------------

BANNER = os.path.join(ROOT, "docs", "banner.svg")


def banner(con, as_of):
    """Write docs/banner.svg. Every figure on it is computed here, so it cannot drift from the repo."""
    from xml.sax.saxutils import escape

    def count_files(folder, ext):
        return len([f for f in os.listdir(os.path.join(ROOT, folder)) if f.endswith(ext)])

    one = lambda sql: con.sql(sql).fetchall()[0][0]  # noqa: E731
    stats = [
        (one("SELECT count(*) FROM analytics.dim_company"), "companies"),
        (one("SELECT count(*) FROM analytics.dim_company WHERE on_watchlist"), "tracked weekly"),
        (count_files("models", ".sql"), "tested models"),
        (count_files(os.path.join("tests", "data_quality"), ".sql"), "data-quality rules"),
        (count_files("answers", ".sql"), "exercises"),
    ]
    cols, rows = query(con, "05c_momentum_check")
    now, pub, name = cols.index("rank"), cols.index("rank_as_published"), cols.index("company")
    rows = [r for r in rows if r[now] is not None and r[pub] is not None]
    fell = sorted((r for r in rows if r[now] - r[pub] >= 2), key=lambda r: r[pub])

    # An editorial page: paper, ink, one accent colour, a serif title, thin rules, a captioned figure.
    W, H = 1280, 400
    PAPER, INK_, GREY, RULE, ACCENT = "#fbfaf7", "#1a1a1a", "#6b6a66", "#d9d6cd", "#d0571f"
    sans = "font-family=\"'Segoe UI','Helvetica Neue',Helvetica,Arial,sans-serif\""
    serif = "font-family=\"Georgia,'Times New Roman',serif\""
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" '
        'aria-labelledby="t d">',
        '<title id="t">SQL for VC analysis: Greek deep tech deal flow</title>',
        f'<desc id="d">{stats[0][0]} companies, {stats[1][0]} tracked weekly, {stats[2][0]} tested models, '
        f"{stats[3][0]} data-quality rules, {stats[4][0]} exercises. Data as of {as_of:%d %B %Y}.</desc>",
        f'<rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" fill="{PAPER}" stroke="{RULE}"/>',
        f"<g {sans}>",
        f'<text x="64" y="76" fill="{GREY}" font-size="16">Gerald Velas, portfolio project</text>',
        f'<text x="62" y="142" fill="{INK_}" font-size="60" {serif}>SQL for VC analysis</text>',
        f'<text x="64" y="186" fill="{GREY}" font-size="21">'
        "Greek deep tech deal flow, modelled and tested in DuckDB</text>",
        f'<line x1="64" y1="226" x2="740" y2="226" stroke="{INK_}" stroke-width="1"/>',
    ]
    # Key figures, set like a table row: number above, label below, thin rules between.
    x, colw = 64, 136
    for i, (value, label) in enumerate(stats):
        if i:
            out.append(f'<line x1="{x - 18}" y1="246" x2="{x - 18}" y2="320" stroke="{RULE}"/>')
        out += [
            f'<text x="{x}" y="290" fill="{INK_}" font-size="42" {serif}>{value}</text>',
            f'<text x="{x}" y="316" fill="{GREY}" font-size="14">{escape(label)}</text>',
        ]
        x += colw
    out.append(
        f'<text x="64" y="362" fill="{GREY}" font-size="13">Data from the Greek Deep Tech Market Map and the '
        f"vc-dealflow-tracker, frozen at the run of {as_of.day} {as_of:%B %Y}.</text>"
    )

    # The figure: how the audit changed the Top Movers ranking.
    fx = 836
    x0, x1, top, step = fx + 44, fx + 214, 140, 23.5
    y = lambda rank: top + (rank - 1) * step  # noqa: E731
    out += [
        f'<line x1="{fx}" y1="56" x2="{fx}" y2="370" stroke="{RULE}"/>',
        f'<text x="{fx + 24}" y="76" fill="{INK_}" font-size="15" font-weight="600">'
        "How the audit changed the ranking</text>",
        f'<text x="{fx + 24}" y="96" fill="{GREY}" font-size="12.5">Top Movers rank, before and after the '
        "tracker's scoring fix</text>",
        f'<text x="{x0}" y="{top - 16}" fill="{GREY}" font-size="11.5" text-anchor="middle">before</text>',
        f'<text x="{x1}" y="{top - 16}" fill="{GREY}" font-size="11.5" text-anchor="middle">after</text>',
    ]
    for r in sorted(rows, key=lambda r: r in fell):  # highlighted lines drawn last, on top
        hot = r in fell
        color, width = (ACCENT, 2.4) if hot else ("#b8b5ad", 1.2)
        out.append(
            f'<line x1="{x0}" y1="{y(r[pub]):.1f}" x2="{x1}" y2="{y(r[now]):.1f}" stroke="{color}" '
            f'stroke-width="{width}"/>'
        )
        for cx, rank in ((x0, r[pub]), (x1, r[now])):
            out.append(f'<circle cx="{cx}" cy="{y(rank):.1f}" r="{3.2 if hot else 2.4}" fill="{color}"/>')
    for r in rows:
        out.append(
            f'<text x="{x0 - 12}" y="{y(r[pub]) + 4:.1f}" fill="{GREY}" font-size="11" text-anchor="end">'
            f"{r[pub]}</text>"
        )
    for r in fell:
        label = escape(r[name].split(" (")[0])
        out.append(
            f'<text x="{x1 + 10}" y="{y(r[now]) + 4:.1f}" fill="{ACCENT}" font-size="12">'
            f"{label}, {r[pub]} to {r[now]}</text>"
        )
    out += [
        f'<text x="{fx + 24}" y="{y(len(rows)) + 30:.1f}" fill="{GREY}" font-size="11">'
        "Source: case study, section 5. Orange: ranks that rested on misread headlines.</text>",
        "</g>",
        "</svg>",
        "",
    ]
    with open(BANNER, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


PLACEHOLDER = re.compile(r"\{\{(table|sql|chart|fact|cell):([^}]+)\}\}")


class Report:
    """Fills the placeholders of a template from the database. Query results are cached."""

    def __init__(self, con):
        self.con = con
        self.results = {}

    def result(self, name):
        if name not in self.results:
            self.results[name] = query(self.con, name)
        return self.results[name]

    def fact(self, metric):
        _cols, rows = self.result("00_key_figures")
        found = [r[1] for r in rows if r[0] == metric]
        if not found:
            raise KeyError(f"no key figure {metric!r} in queries/00_key_figures.sql")
        return fmt(found[0])

    def cell(self, spec):
        # {{cell:QUERY|KEY_COLUMN=VALUE|COLUMN}} picks one value out of a query result.
        name, match, column = spec.split("|")
        key, value = match.split("=", 1)
        cols, rows = self.result(name)
        hits = [r for r in rows if str(r[cols.index(key)]) == value]
        if len(hits) != 1:
            raise KeyError(f"{spec}: {len(hits)} rows match, expected 1")
        return fmt(hits[0][cols.index(column)])

    def fill(self, text, as_of):
        def one(m):
            kind, arg = m.group(1), m.group(2)
            if kind == "table":
                return markdown_table(*self.result(arg))
            if kind == "sql":
                with open(os.path.join(QUERIES, f"{arg}.sql"), encoding="utf-8") as f:
                    sql = f.read().strip()
                return (
                    f"<details><summary>SQL: <code>queries/{arg}.sql</code></summary>\n\n```sql\n{sql}\n```\n</details>"
                )
            if kind == "chart":
                return CHART_FUNCS[arg](self.con)
            if kind == "fact":
                return self.fact(arg)
            return self.cell(arg)

        text = PLACEHOLDER.sub(one, text).replace("{{as_of}}", f"{as_of.day} {as_of:%B %Y}")
        left = re.findall(r"\{\{[^}]*\}\}", text)
        if left:
            sys.exit(f"Unfilled placeholders: {left}")
        return text


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if not os.path.exists(DB):
        sys.exit("dealflow.duckdb not found. Build it first:  python build_db.py")
    con = duckdb.connect(DB, read_only=True)
    report = Report(con)
    as_of = con.sql("SELECT max(date) FROM scores").fetchall()[0][0]

    with open(os.path.join(HERE, "template.md"), encoding="utf-8") as f:
        text = report.fill(f.read(), as_of)
    with open(os.path.join(HERE, "README.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)

    # The findings table on the project's front page comes from the same queries.
    with open(os.path.join(HERE, "findings.md"), encoding="utf-8") as f:
        findings = report.fill(f.read(), as_of).strip()
    readme = os.path.join(ROOT, "README.md")
    with open(readme, encoding="utf-8") as f:
        front = f.read()
    start, end = "<!-- findings:start -->", "<!-- findings:end -->"
    if start not in front or end not in front:
        sys.exit("README.md has no findings markers")
    front = front[: front.index(start) + len(start)] + "\n" + findings + "\n" + front[front.index(end) :]
    with open(readme, "w", encoding="utf-8", newline="\n") as f:
        f.write(front)
    banner(con, as_of)
    print(
        f"Wrote case_study/README.md, the README findings, {len(CHART_FUNCS)} charts "
        f"and docs/banner.svg (data as of {as_of})"
    )


if __name__ == "__main__":
    main()
