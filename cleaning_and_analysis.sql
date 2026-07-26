/* =========================================================
   VIDEO GAME INDUSTRY ANALYTICS STUDY
   SQL Data Cleaning & Analysis Script
   Source: video_games_raw.csv  (16,899 raw records)
   ========================================================= */

-- -------------------------------------------------
-- 0. Load raw data into staging table (raw_games)
--    (loaded via `.import` / pandas.to_sql before running this script)
-- -------------------------------------------------

-- -------------------------------------------------
-- 1. INSPECT DATA QUALITY ISSUES
-- -------------------------------------------------
-- Count of missing values by column
SELECT
  SUM(CASE WHEN Year IS NULL THEN 1 ELSE 0 END)        AS missing_year,
  SUM(CASE WHEN Publisher IS NULL THEN 1 ELSE 0 END)   AS missing_publisher,
  SUM(CASE WHEN Critic_Score IS NULL THEN 1 ELSE 0 END) AS missing_critic,
  SUM(CASE WHEN User_Score IS NULL THEN 1 ELSE 0 END)   AS missing_user_score,
  COUNT(*)                                              AS total_rows
FROM raw_games;

-- Duplicate rows (same Name, Platform, Year, Publisher)
SELECT Name, Platform, Year, Publisher, COUNT(*) AS cnt
FROM raw_games
GROUP BY Name, Platform, Year, Publisher
HAVING COUNT(*) > 1;

-- Invalid year values (outside plausible console era)
SELECT DISTINCT Year FROM raw_games WHERE Year < 1980 OR Year > 2026;

-- Inconsistent platform labels
SELECT DISTINCT Platform FROM raw_games ORDER BY Platform;

-- Negative sales values (data entry errors)
SELECT * FROM raw_games WHERE NA_Sales < 0 OR EU_Sales < 0 OR JP_Sales < 0 OR Other_Sales < 0;

-- -------------------------------------------------
-- 2. BUILD CLEANED TABLE
-- -------------------------------------------------
DROP TABLE IF EXISTS games_clean;

CREATE TABLE games_clean AS
WITH standardized AS (
  SELECT
    Rank,
    TRIM(Name)                                                     AS Name_raw,
    -- Title-case-ish clean name (trim + collapse case for grouping/display)
    TRIM(Name)                                                     AS Name,
    -- Standardize platform labels to canonical values
    CASE
      WHEN LOWER(TRIM(Platform)) IN ('ps4')                        THEN 'PS4'
      WHEN LOWER(TRIM(Platform)) IN ('playstation 5','ps5')        THEN 'PS5'
      WHEN LOWER(TRIM(Platform)) IN ('xbox one','xbox_one')        THEN 'Xbox One'
      WHEN LOWER(TRIM(Platform)) IN ('switch','nintendo switch')   THEN 'Nintendo Switch'
      WHEN LOWER(TRIM(Platform)) IN ('pc')                         THEN 'PC'
      WHEN LOWER(TRIM(Platform)) IN ('xbox360','xbox 360')         THEN 'Xbox 360'
      ELSE Platform
    END AS Platform,
    -- Null out impossible years; leave real years as-is
    CASE WHEN Year BETWEEN 1990 AND 2026 THEN Year ELSE NULL END   AS Year,
    Genre,
    Publisher,   -- NULLs are kept and flagged (see Publisher_Flag) rather than guessed
    -- Fix sign errors on sales figures
    ABS(NA_Sales)    AS NA_Sales,
    ABS(EU_Sales)    AS EU_Sales,
    ABS(JP_Sales)    AS JP_Sales,
    ABS(Other_Sales) AS Other_Sales,
    ROUND(ABS(NA_Sales)+ABS(EU_Sales)+ABS(JP_Sales)+ABS(Other_Sales), 2) AS Global_Sales,
    Critic_Score,
    User_Score,
    CASE WHEN Publisher IS NULL THEN 1 ELSE 0 END AS Publisher_Missing_Flag,
    CASE WHEN Year IS NULL THEN 1 ELSE 0 END      AS Year_Missing_Flag
  FROM raw_games
),
deduped AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY Name, Platform, Year, Publisher
      ORDER BY Rank
    ) AS rn
  FROM standardized
)
SELECT
  Rank, Name, Platform, Year, Genre,
  COALESCE(Publisher, 'Unknown/Unreported') AS Publisher,
  NA_Sales, EU_Sales, JP_Sales, Other_Sales, Global_Sales,
  Critic_Score, User_Score, Publisher_Missing_Flag, Year_Missing_Flag
FROM deduped
WHERE rn = 1;                      -- drop duplicate rows

-- -------------------------------------------------
-- 3. GAME SUCCESS SCORE (custom weighted algorithm)
--    Blends commercial performance + critical/user reception
--    into a single 0-100 ranking metric.
--
--    Success Score =
--        45% * normalized Global Sales   (commercial performance)
--      + 30% * normalized Critic Score   (critical reception)
--      + 15% * normalized User Score     (audience reception)
--      + 10% * normalized Regional Reach (# of regions with >5% of sales)
-- -------------------------------------------------
DROP TABLE IF EXISTS game_success_score;

CREATE TABLE game_success_score AS
WITH bounds AS (
  SELECT MAX(Global_Sales) AS max_sales FROM games_clean
),
scored AS (
  SELECT
    g.Rank, g.Name, g.Platform, g.Year, g.Genre, g.Publisher,
    g.Global_Sales, g.Critic_Score, g.User_Score,
    -- regional reach: how many of the 4 regions contributed a meaningful share
    ( (CASE WHEN g.Global_Sales > 0 AND g.NA_Sales/g.Global_Sales    > 0.05 THEN 1 ELSE 0 END) +
      (CASE WHEN g.Global_Sales > 0 AND g.EU_Sales/g.Global_Sales    > 0.05 THEN 1 ELSE 0 END) +
      (CASE WHEN g.Global_Sales > 0 AND g.JP_Sales/g.Global_Sales    > 0.05 THEN 1 ELSE 0 END) +
      (CASE WHEN g.Global_Sales > 0 AND g.Other_Sales/g.Global_Sales > 0.05 THEN 1 ELSE 0 END)
    ) AS Region_Reach,
    b.max_sales
  FROM games_clean g CROSS JOIN bounds b
)
SELECT
  Rank, Name, Platform, Year, Genre, Publisher, Global_Sales, Critic_Score, User_Score, Region_Reach,
  ROUND(
    45.0 * (Global_Sales / NULLIF(max_sales,0)) * 100 / 100
    + 30.0 * (COALESCE(Critic_Score,50) / 100.0)
    + 15.0 * (COALESCE(User_Score,5) / 10.0)
    + 10.0 * (Region_Reach / 4.0)
  , 1) AS Success_Score
FROM scored
ORDER BY Success_Score DESC;

-- -------------------------------------------------
-- 4. PUBLISHER MARKET SHARE
-- -------------------------------------------------
SELECT
  Publisher,
  COUNT(*)                                   AS Titles_Published,
  ROUND(SUM(Global_Sales), 1)                AS Total_Global_Sales_M,
  ROUND(100.0 * SUM(Global_Sales) / (SELECT SUM(Global_Sales) FROM games_clean), 2) AS Market_Share_Pct,
  ROUND(AVG(Critic_Score), 1)                AS Avg_Critic_Score
FROM games_clean
WHERE Publisher <> 'Unknown/Unreported'
GROUP BY Publisher
ORDER BY Total_Global_Sales_M DESC;

-- -------------------------------------------------
-- 5. REGIONAL PERFORMANCE BY GENRE
-- -------------------------------------------------
SELECT
  Genre,
  ROUND(SUM(NA_Sales),1)    AS NA_Sales_M,
  ROUND(SUM(EU_Sales),1)    AS EU_Sales_M,
  ROUND(SUM(JP_Sales),1)    AS JP_Sales_M,
  ROUND(SUM(Other_Sales),1) AS Other_Sales_M,
  ROUND(SUM(Global_Sales),1) AS Global_Sales_M
FROM games_clean
GROUP BY Genre
ORDER BY Global_Sales_M DESC;

-- -------------------------------------------------
-- 6. SALES TRENDS OVER TIME
-- -------------------------------------------------
SELECT
  Year,
  COUNT(*)                    AS Titles_Released,
  ROUND(SUM(Global_Sales),1)  AS Global_Sales_M,
  ROUND(AVG(Critic_Score),1)  AS Avg_Critic_Score
FROM games_clean
WHERE Year IS NOT NULL
GROUP BY Year
ORDER BY Year;

-- -------------------------------------------------
-- 7. PLATFORM PERFORMANCE
-- -------------------------------------------------
SELECT
  Platform,
  COUNT(*)                    AS Titles_Released,
  ROUND(SUM(Global_Sales),1)  AS Global_Sales_M,
  ROUND(AVG(Global_Sales),2)  AS Avg_Sales_Per_Title_M,
  ROUND(AVG(Critic_Score),1)  AS Avg_Critic_Score
FROM games_clean
GROUP BY Platform
ORDER BY Global_Sales_M DESC;

-- -------------------------------------------------
-- 8. TOP 25 GAMES BY SUCCESS SCORE
-- -------------------------------------------------
SELECT * FROM game_success_score LIMIT 25;
