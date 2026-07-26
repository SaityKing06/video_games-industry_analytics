# Video Game Industry Analytics Study
**SQL · Excel · Power BI/Tableau** | Apr – Jun 2026

Analyzed 16,000+ video game sales records to identify key drivers of financial
success across publishers, platforms, and genres — including a custom "Game
Success Score" algorithm and an interactive BI dashboard.

## Files in this repo

| File | What it is |
|---|---|
| `video_games_raw.csv` | Raw, uncleaned 16,899-record dataset (contains duplicates, missing values, inconsistent labels — the "before" state) |
| `cleaning_and_analysis.sql` | SQL script that cleans the raw data and runs all analysis (publisher market share, regional/genre performance, sales trends, platform performance, Game Success Score) |
| `video_games_for_tableau.csv` | Cleaned, analysis-ready dataset (16,668 records) with the Game Success Score merged in — ready to load into Tableau/Power BI |
| `Video_Game_Industry_Analytics.xlsx` | Excel workbook: cleaned data, Success Score leaderboard, publisher/genre/platform/trend analysis, with charts |
| `power_bi_dashboard.html` | Interactive dashboard (KPIs, market share, regional/genre breakdown, platform performance, Success Score leaderboard) |
| `Video_Game_Industry_Analytics_Report.md` | Full methodology, cleaning log, scoring algorithm, findings, and recommendations |

## Methodology

1. **Data cleaning (SQL):** deduplicated records, standardized inconsistent platform
   labels, corrected sign errors in sales figures, flagged (rather than guessed)
   missing publisher/year values, and recomputed global sales as the sum of
   regional sales for consistency. 231 duplicate/erroneous rows were removed,
   leaving 16,668 analysis-ready records.
2. **Game Success Score:** a custom 0–100 metric blending commercial performance
   (45%), critic reception (30%), user reception (15%), and regional reach (10%),
   so titles can be ranked on more than raw sales alone.
3. **Analysis:** publisher market share, regional sales by genre, platform
   performance, and year-over-year sales trends.

See `Video_Game_Industry_Analytics_Report.md` for full findings and recommendations.

## Note on the data

The underlying records are a simulated dataset engineered to match the structure,
scale, and real-world messiness of an industry sales export (16k+ titles,
2000–2026, 30 publishers, 17 platforms), built for this portfolio project.
