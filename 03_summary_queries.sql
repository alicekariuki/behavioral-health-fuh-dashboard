/* =====================================================================
   FUH summary queries (SQL Server / T-SQL)
   Run after 02_fuh_measure.sql. These match the Power BI visuals and are
   useful for validating the dashboard numbers.
   ===================================================================== */

/* 1. Overall rates */
SELECT
    COUNT(*)                                        AS eligible_discharges,
    SUM(fuh_7_day)                                  AS followup_7_day,
    SUM(fuh_30_day)                                 AS followup_30_day,
    ROUND(100.0 * SUM(fuh_7_day)  / COUNT(*), 1)    AS rate_7_day_pct,
    ROUND(100.0 * SUM(fuh_30_day) / COUNT(*), 1)    AS rate_30_day_pct
FROM vw_fuh_measure;

/* 2. Rates by payer */
SELECT
    payer,
    COUNT(*)                                        AS eligible_discharges,
    ROUND(100.0 * SUM(fuh_7_day)  / COUNT(*), 1)    AS rate_7_day_pct,
    ROUND(100.0 * SUM(fuh_30_day) / COUNT(*), 1)    AS rate_30_day_pct
FROM vw_fuh_measure
GROUP BY payer
ORDER BY rate_7_day_pct;

/* 3. Rates by discharging facility */
SELECT
    facility_name,
    COUNT(*)                                        AS eligible_discharges,
    ROUND(100.0 * SUM(fuh_7_day)  / COUNT(*), 1)    AS rate_7_day_pct,
    ROUND(100.0 * SUM(fuh_30_day) / COUNT(*), 1)    AS rate_30_day_pct
FROM vw_fuh_measure
GROUP BY facility_name
ORDER BY rate_7_day_pct;

/* 4. Impact of scheduling the follow-up appointment before discharge */
SELECT
    followup_appt_scheduled_at_discharge            AS appt_scheduled,
    COUNT(*)                                        AS eligible_discharges,
    ROUND(100.0 * SUM(fuh_7_day) / COUNT(*), 1)     AS rate_7_day_pct
FROM vw_fuh_measure
GROUP BY followup_appt_scheduled_at_discharge;

/* 5. Monthly trend */
SELECT
    YEAR(discharge_date)                            AS discharge_year,
    MONTH(discharge_date)                           AS discharge_month,
    COUNT(*)                                        AS eligible_discharges,
    ROUND(100.0 * SUM(fuh_7_day)  / COUNT(*), 1)    AS rate_7_day_pct,
    ROUND(100.0 * SUM(fuh_30_day) / COUNT(*), 1)    AS rate_30_day_pct
FROM vw_fuh_measure
GROUP BY YEAR(discharge_date), MONTH(discharge_date)
ORDER BY discharge_year, discharge_month;

/* 6. Rates by diagnosis category */
SELECT
    dx_category,
    COUNT(*)                                        AS eligible_discharges,
    ROUND(100.0 * SUM(fuh_7_day)  / COUNT(*), 1)    AS rate_7_day_pct,
    ROUND(100.0 * SUM(fuh_30_day) / COUNT(*), 1)    AS rate_30_day_pct
FROM vw_fuh_measure
GROUP BY dx_category
ORDER BY rate_7_day_pct;

/* 7. Care gap worklist: discharges still open (no follow-up yet) -
      the list a care coordinator would call from */
SELECT
    encounter_id,
    member_id,
    payer,
    facility_name,
    discharge_date,
    dx_category,
    followup_appt_scheduled_at_discharge
FROM vw_fuh_measure
WHERE fuh_30_day = 0
ORDER BY discharge_date DESC;
