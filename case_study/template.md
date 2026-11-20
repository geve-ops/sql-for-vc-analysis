# Case study: six VC questions about Greek deep tech, answered in SQL

Data as of the weekly run of **{{as_of}}**. Every table below is the output of a query in [queries/](queries/), run by [build_report.py](build_report.py) against the kit's DuckDB database. Nothing is typed in by hand, and no figure is estimated: a round size is used only when the source records an exact amount, and currencies are never converted.

**The universe:** the 69 companies on the deal-flow tracker's watchlist, which are the Include and Borderline companies of the [Greek Deep Tech Market Map](https://github.com/geve-ops/greek-deeptech-market-map). Weekly signals come from the [deal-flow tracker](https://github.com/geve-ops/vc-dealflow-tracker): GitHub, Google News, job boards and the EU's [CORDIS](https://cordis.europa.eu/) project database. Round sizes, dates and investors come from the market map, which keeps a source link for every company; those links are in the tables that quote a figure.

**The four target funds** are Big Pi Ventures, Marathon VC, Metavallon VC and Velocity Partners. egg (Eurobank) has no tagged holding on the watchlist, so it does not appear.

| # | Question | Short answer |
|---|---|---|
| 1 | [Where is the universe, and how visible is it?](#1-where-is-the-universe-and-how-visible-is-it) | Health & Biotech is the most backed sector; Space & Defense shows the most activity. |
| 2 | [Which funds lead, and do the target funds co-invest?](#2-which-greek-funds-lead-and-do-the-target-funds-co-invest) | Almost never: one shared company across the four. |
| 3 | [How is recent capital spread?](#3-how-is-recent-capital-spread) | Small euro seeds, larger dollar rounds, and one EUR 300M outlier. |
| 4 | [Who brings in EU research money?](#4-who-brings-in-eu-research-money) | Mostly companies no Greek fund holds. |
| 5 | [What drives week-over-week momentum?](#5-what-drives-week-over-week-momentum) | Hiring and GitHub. No funding point came from an actual round. |
| 6 | [Who should a fund call this month?](#6-who-should-a-fund-call-this-month) | Seven companies in the raising window with no Greek investor. |

---

## 1. Where is the universe, and how visible is it?

A fund first wants to know where the companies are and how much it can see of each sector: how many already have a Greek investor, how many have a round size it can trust, and how many showed any activity in the last four weekly runs.

{{table:01_sector_coverage}}

{{sql:01_sector_coverage}}

**So what.**
- Four sectors (Health & Biotech, Robotics & Drones, AI & Machine Learning, Space & Defense) hold 48 of the 69 companies.
- Health & Biotech is the most crowded for a new investor: 10 of its 13 companies already have a current Greek fund.
- Space & Defense has the most companies producing signals (6 of 11) but only 4 with a Greek fund. That is the sector where activity runs ahead of local backing.
- Semiconductors & Hardware has a confirmed round size for only 1 of its 7 companies. Any sizing view of that sector needs primary diligence first.

## 2. Which Greek funds lead, and do the target funds co-invest?

`greek_funds` holds several funds in one cell, so the query splits it into one row per fund and company, then joins the result to itself to find pairs of funds that hold the same company.

{{chart:fund_holdings}}

{{table:02_fund_overlap}}

{{sql:02_fund_overlap}}

Every pair of Greek funds that currently share a company:

{{table:02b_fund_pairs}}

{{sql:02b_fund_pairs}}

**So what.**
- By count of watchlist holdings, Genesis Ventures (9) leads, ahead of Marathon VC (8), Big Pi Ventures (7) and Metavallon VC (7).
- The four target funds share exactly one company with each other: Anodyne Nanotech, held by Big Pi Ventures and Velocity Partners. Marathon VC and Metavallon VC do not share a single company with another target fund.
- Where Greek funds do co-invest, the partner is usually a smaller early-stage fund: Evercurious VC has 4 Greek co-investors and Genesis Ventures 3. For a target fund, those two are the most likely route to a local syndicate.
- Nine pairs of funds share ten holdings, out of 35 current holdings in all: Greek funds mostly invest in parallel, not in syndicates.

## 3. How is recent capital spread?

Rounds dated January 2025 or later, from the market map's `last_round_amount` and `last_round_date`. A round counts only when the text starts with a currency and an exact amount, the date is not marked UNVERIFIED, and the money is not a grant.

{{chart:recent_rounds}}

{{table:03_recent_rounds}}

{{sql:03_recent_rounds}}

<details><summary>The 21 rounds behind the summary, with sources</summary>

{{table:03b_recent_rounds_list}}

{{sql:03b_recent_rounds_list}}
</details>

Recent rounds left out, and why:

{{table:03c_recent_rounds_excluded}}

{{sql:03c_recent_rounds_excluded}}

**So what.**
- The typical euro round is small: the median of the 10 EUR rounds is EUR 1.18M, and 8 of the 10 are under EUR 5M.
- Rounds recorded in dollars are larger: the median of the 10 USD rounds is USD 6.75M.
- The euro total is one company: Open Cosmos's EUR 300M is 89.6% of the EUR 334.93M raised. The EUR total also includes OQ Technology's EUR 25M, which is EIB venture debt, not equity. Medians, not totals, describe this market.
- Six recent rounds are left out because the source gives only an approximation, a lower bound or an unverified date. Axelera AI's "More than USD 250M" is the largest of them.

## 4. Who brings in EU research money?

CORDIS projects that the tracker matched to each company in the latest snapshot. `project_eu_eur_m` is the EU contribution to the **whole project**, shared by all its partners. It is a measure of how big the consortia are, not of the company's own grant income, and it must not be read as company funding.

{{chart:eu_grants}}

{{table:04_eu_grants}}

{{sql:04_eu_grants}}

{{table:04b_grants_vs_vc}}

{{sql:04b_grants_vs_vc}}

**So what.**
- The five companies with the most CORDIS projects (Core Innovation and Technology 26, Satways 18, SquareDev 13, Prisma Electronics 10, Altus LSA 9) have no Greek fund behind them.
- Across the watchlist, companies with EU projects are less often VC-backed (9 of 21, 42.9%) than companies without (26 of 48, 54.2%).
- Grant-heavy companies are a sourcing list a fund can act on: teams that already run EU consortia and report to the Commission, and that have not raised from local VC. Whether they want equity at all is the first question to ask.
- Axelera AI has fewer projects (8) but the largest project budgets (EUR 243.3M across its projects), all of them still running.

## 5. What drives week-over-week momentum?

The tracker scores each company every week (funding headline 5 points, EU grant signed 3, press 1, new job posting 1, GitHub activity; each signal capped). This query adds the points up by signal for each run and uses `LAG` for the change from the week before.

{{chart:weekly_signals}}

{{table:05_weekly_signals}}

{{sql:05_weekly_signals}}

Every headline that earned funding points:

{{table:05b_funding_headlines}}

{{sql:05b_funding_headlines}}

The Top Movers ranking with and without those points:

{{table:05c_momentum_check}}

{{sql:05c_momentum_check}}

**So what.**
- Hiring is the signal that grew: 4 points in the first run, 10 to 11 in the last two. GitHub is steady at 4 to 10 points a week. One caveat: the tracker scores each city of a multi-city job as a new role. On 16 November Hack The Box earned the maximum 5 hiring points for 3 new postings, one of them listed six times (exercise 3.06 lists them).
- Funding points made up 25 of the 114 points in the four runs, and none of the six headlines behind them announces a new round: they are a return-on-investment study, reports of investment *interest*, and a payload-hosting contract. The headline classifier matches words like "investment" and "secures".
- That error moves the ranking. OQ Technology is third by momentum, but 18th without funding points; Open Cosmos drops from sixth to tenth. The top two (Axelera AI, Hack The Box) do not change.
- The fix belongs in the tracker: award funding points only when the headline carries an amount or a round label, and keep the rest as press.

## 6. Who should a fund call this month?

Companies whose last dated round was 15 to 24 months before the latest run, the usual gap before the next round, joined to their Greek investors, open job postings and four-week score. Acquired companies are left out.

{{table:06_call_list}}

{{sql:06_call_list}}

**So what.**
- 12 companies are in the window, and 7 of them have no Greek investor: Achira AI, Bitloops, Brainomix, Intryc, Keragon, Robenso and SquareDev.
- Brainomix has the highest four-week score in the window. Achira AI (7 open roles, last round USD 33M) and Intryc (5 open roles, USD 3.1M) list open roles but posted none new in four weeks, so their listings may be stale; exercise 3.05 shows how to check.
- Two of those leads have open questions in the market map: Achira AI's HQ and Greek presence and Brainomix's Greek office are marked UNVERIFIED. That check comes before the first call.
- For existing holders, Corsmed (Big Pi Ventures, 23 months) and Delian Alliance Industries (Marathon VC, 16 months) are inside the window: time to prepare the follow-on decision.

---

## Limits of this analysis

- **Small sample.** 69 companies and four weekly runs. The counts describe this watchlist, not the whole Greek ecosystem, and four weeks cannot show a trend.
- **Selection.** The watchlist is the market map's Include and Borderline companies. Companies the map missed are missing here too.
- **Round data.** Round sizes are the last round only, as recorded in the market map. Six recent rounds are excluded for approximate or unverified figures, and earlier rounds are not counted.
- **Fund tags.** `greek_funds` comes from the market map's `investors` column. A holding a source does not mention is missing.
- **Grants.** CORDIS projects are matched by company name, and the amounts are whole-project EU contributions shared by all partners.
- **Signals.** Funding headlines are tagged by keyword (section 5 shows the cost). A company with no GitHub organisation, job board or EU project can only score through news, so a low score means "nothing visible", not "nothing happening".

The data dictionary and the full list of limits are in [docs/data_dictionary.md](../docs/data_dictionary.md).

To rebuild this page: `python run_all.py` from the repository root, or `python case_study/build_report.py` after `python build_db.py`.
