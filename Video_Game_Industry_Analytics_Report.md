# Video Game Industry Analytics Study
**SQL · Excel · Power BI** | Apr – Jun 2026

## 1. Overview

This study analyzes 16,899 raw video game sales records spanning 30 publishers, 17
platform label variants, and release years 2000–2026, to identify what drives
commercial success in the games industry and to produce a reusable ranking
metric — the **Game Success Score** — for comparing titles across platforms and
genres.

*Dataset note: the underlying records are a simulated dataset engineered to match
the structure, scale, and real-world messiness (duplicates, missing fields,
inconsistent labels, data-entry errors) of an industry sales export, built for
this portfolio study.*

## 2. Data Cleaning (SQL)

Raw data was loaded into SQLite and cleaned with `cleaning_and_analysis.sql`:

| Issue | Count | Resolution |
|---|---|---|
| Duplicate records | 253 | Deduplicated on Name + Platform + Year + Publisher, keeping the first-seen row |
| Inconsistent platform labels (`ps4`, `XBOX ONE`, `switch`…) | ~845 rows | Standardized to canonical platform names |
| Negative sales values (entry errors) | ~84 rows | Corrected with `ABS()` |
| Missing `Year` | ~500 rows | Left null and flagged (`Year_Missing_Flag`) rather than imputed |
| Missing `Publisher` | ~334 rows | Recoded to `Unknown/Unreported` and flagged rather than guessed |
| Missing `Critic_Score` / `User_Score` | ~2,500 / 1,670 rows | Left null in the cleaned table; neutrally imputed (50 / 5.0) only inside the Success Score calculation so a title isn't penalized for lacking review data |
| Extra whitespace / inconsistent casing in titles | ~670 rows | Trimmed |
| `Global_Sales` inconsistent with regional components | all rows | Recomputed as `NA + EU + JP + Other` for internal consistency |

**Result:** 16,668 analysis-ready records (231 rows removed as duplicates/unrecoverable errors).

## 3. Game Success Score — Custom Algorithm

A single 0–100 score blends commercial and critical performance so titles can be
ranked on more than raw sales alone:

```
Success Score = 45% × normalized Global Sales     (commercial performance, vs. top seller)
              + 30% × Critic Score (0–100 scale)   (critical reception)
              + 15% × User Score  ×10 (0–100 scale) (audience reception)
              + 10% × Region Reach / 4 × 100        (# of regions each contributing >5% of sales)
```

Region Reach rewards titles with broad geographic appeal (a title that sells only
in one region scores lower on this component than one with balanced NA/EU/JP/Other
sales), which surfaces globally-resonant titles rather than just regional blockbusters.

## 4. Key Findings

- **Publisher concentration is moderate, not dominated by one player.** The top
  publisher holds roughly 4.6% of total global sales, and the top 12 publishers are
  within a ~3.3–4.6% share band — no single publisher commands outsized market power
  in this dataset, suggesting a competitive, fragmented publishing landscape.
- **Platform genre performance is broad-based.** Platform (action/platformer) and
  Role-Playing titles lead cumulative global sales, but the spread across the top 8
  genres is narrow (~$367M–$488M), indicating genre choice alone is a weak predictor
  of success — execution and publisher backing matter more than category.
- **Regional demand is NA/EU-led with a secondary JP/Other tail** across virtually
  every genre, so a regional launch strategy weighted toward NA+EU with a
  right-sized JP localization budget is broadly supportable across genre lines.
- **Sales-per-title varies more by platform than raw volume does** — some platforms
  release fewer titles but at higher average sales per title, indicating platform
  selection affects expected return per release even when overall market size looks similar.
- **High Success Scores aren't always top-selling titles.** Several titles rank
  highly on the Success Score despite modest global sales, because strong critic/
  user reception and broad regional reach pull their blended score up — showing
  the score surfaces critically-loved, broadly-appealing titles that a pure sales
  ranking would miss.

## 5. Recommendations for Publishing / Development Strategy

1. **Prioritize regional reach, not just peak-region sales.** Titles with balanced
   sales across NA/EU/JP/Other scored measurably higher on the blended Success
   Score — build localization and regional marketing budgets into titles expected
   to travel, rather than concentrating spend in a single home region.
2. **Treat genre as a secondary lever, publisher execution as primary.** Since
   genre-level sales are relatively flat, portfolio decisions should weight team
   track record and quality bar (critic/user score) at least as heavily as genre
   trend-chasing.
3. **Use the Success Score (not raw sales) to greenlight sequels/remasters.** A
   title with modest sales but strong reception and reach is a better long-term
   franchise bet than a one-region hit with mediocre reviews.
4. **Match platform strategy to expected sales-per-title, not just installed base
   size** — the platform-performance analysis shows meaningful variance in average
   revenue per release across platforms that publishers can use to prioritize SKUs.

## 6. Deliverables

| File | Description |
|---|---|
| `video_games_raw.csv` | Raw, uncleaned 16,899-record extract |
| `cleaning_and_analysis.sql` | Full SQL cleaning + analysis script (SQLite dialect) |
| `Video_Game_Industry_Analytics.xlsx` | Cleaned data, Success Score, publisher/genre/platform/trend analysis, charts |
| `power_bi_dashboard.html` | Interactive Power BI–style dashboard (KPIs, market share, regional/genre, platform, Success Score leaderboard) |
| `Video_Game_Industry_Analytics_Report.md` | This methodology & findings report |
