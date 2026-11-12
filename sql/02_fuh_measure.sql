/* =====================================================================
   FUH measure logic (SQL Server / T-SQL)
   Follow-Up After Hospitalization for Mental Illness - simplified version

   Output: one row per eligible index discharge, with 7-day and 30-day
   compliance flags. This view is the fact table for the Power BI model.

   Simplified rules used in this portfolio project (see README):
     Denominator
       - Acute inpatient discharge with a principal mental health diagnosis
       - Discharged January 1 - December 1 of the measurement year
       - Member age 6 or older on the discharge date
       - Continuously enrolled from discharge date through 30 days after
     Exclusions
       - Member died during the stay
       - Transferred to another acute or a residential facility
       - Readmitted to inpatient care within 30 days (only the later
         discharge is counted, if it is eligible)
     Numerator
       - Visit with a behavioral health provider AFTER the discharge date
         (a visit on the day of discharge does not count)
       - 7-day rate: within 7 days; 30-day rate: within 30 days
   ===================================================================== */

CREATE VIEW vw_fuh_measure AS
WITH discharges AS (
    SELECT
        s.encounter_id,
        s.member_id,
        s.facility_id,
        s.facility_name,
        s.admit_date,
        s.discharge_date,
        s.principal_dx_code,
        s.dx_category,
        s.discharge_disposition,
        s.followup_appt_scheduled_at_discharge,
        m.payer,
        m.region,
        m.sex,
        FLOOR(DATEDIFF(DAY, m.date_of_birth, s.discharge_date) / 365.25) AS age_at_discharge,
        /* next inpatient admission for the same member, if any */
        LEAD(s.admit_date) OVER (PARTITION BY s.member_id
                                 ORDER BY s.admit_date, s.encounter_id) AS next_admit_date
    FROM inpatient_stays AS s
    JOIN members AS m
        ON m.member_id = s.member_id
),

eligible AS (
    SELECT d.*
    FROM discharges AS d
    WHERE d.discharge_date BETWEEN '2025-01-01' AND '2025-12-01'
      AND d.age_at_discharge >= 6
      /* continuous enrollment: one span covers discharge through +30 days */
      AND EXISTS (
            SELECT 1
            FROM enrollment AS e
            WHERE e.member_id = d.member_id
              AND e.start_date <= d.discharge_date
              AND e.end_date   >= DATEADD(DAY, 30, d.discharge_date)
      )
      /* exclusions */
      AND d.discharge_disposition NOT IN ('Expired',
                                          'Transfer to another acute facility',
                                          'Residential treatment')
      AND (d.next_admit_date IS NULL
           OR d.next_admit_date > DATEADD(DAY, 30, d.discharge_date))
),

first_followup AS (
    /* earliest qualifying behavioral health visit after discharge */
    SELECT
        el.encounter_id,
        MIN(v.visit_date) AS first_bh_visit_date
    FROM eligible AS el
    JOIN outpatient_visits AS v
        ON  v.member_id  = el.member_id
        AND v.visit_date >  el.discharge_date
        AND v.visit_date <= DATEADD(DAY, 30, el.discharge_date)
    JOIN providers AS p
        ON  p.provider_id = v.provider_id
        AND p.is_behavioral_health = 'Y'
    GROUP BY el.encounter_id
)

SELECT
    el.encounter_id,
    el.member_id,
    el.payer,
    el.region,
    el.sex,
    el.age_at_discharge,
    CASE WHEN el.age_at_discharge BETWEEN 6 AND 17 THEN '6-17'
         WHEN el.age_at_discharge BETWEEN 18 AND 64 THEN '18-64'
         ELSE '65+' END                                     AS age_group,
    el.facility_id,
    el.facility_name,
    el.admit_date,
    el.discharge_date,
    DATEDIFF(DAY, el.admit_date, el.discharge_date)         AS length_of_stay,
    el.principal_dx_code,
    el.dx_category,
    el.discharge_disposition,
    el.followup_appt_scheduled_at_discharge,
    ff.first_bh_visit_date,
    DATEDIFF(DAY, el.discharge_date, ff.first_bh_visit_date) AS days_to_followup,
    CASE WHEN ff.first_bh_visit_date <= DATEADD(DAY, 7, el.discharge_date)
         THEN 1 ELSE 0 END                                  AS fuh_7_day,
    CASE WHEN ff.first_bh_visit_date IS NOT NULL
         THEN 1 ELSE 0 END                                  AS fuh_30_day
FROM eligible AS el
LEFT JOIN first_followup AS ff
    ON ff.encounter_id = el.encounter_id;
