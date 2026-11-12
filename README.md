# Behavioral Health Follow-Up (FUH) Dashboard

**How many patients see a mental health provider within 7 and 30 days of leaving a psychiatric hospital, and what drives the gaps?**

![SQL](https://img.shields.io/badge/SQL_Server-T--SQL-CC2927?logo=microsoftsqlserver&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-DAX-F2C811?logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-data_generation-3776AB?logo=python&logoColor=white)
![Data](https://img.shields.io/badge/data-100%25_synthetic-lightgrey)

> 📸 *Add a dashboard screenshot here once the Power BI report is built:* `![Dashboard](images/dashboard_overview.png)`

---

## Business problem

Follow-up care soon after a psychiatric hospitalization lowers the risk of readmission and crisis. Health plans and hospitals report this as a national quality measure (Follow-Up After Hospitalization for Mental Illness, or FUH), and it's tied to quality ratings and value-based payments.

A behavioral health quality team wants to know:

1. What are our 7-day and 30-day follow-up rates?
2. Which payers, facilities, regions, and diagnosis groups are falling behind?
3. Does scheduling the aftercare appointment **before** discharge make a difference?
4. Which patients still need outreach right now?

## Key findings (synthetic data, measurement year 2025)

| Metric | Result |
|---|---|
| Eligible discharges | **1,249** |
| 7-day follow-up rate | **44.1%** |
| 30-day follow-up rate | **69.1%** |

- **Scheduling the aftercare appointment at discharge nearly doubles the 7-day rate**: 56.8% when scheduled vs. 29.8% when not. This is the clearest lever for improvement.
- **Medicaid members trail** Commercial members by 18 points on the 7-day rate (39.4% vs. 57.6%).
- **Facility variation is about 10 points** (40.0% to 49.8%). The best-performing facility's discharge process could serve as a model for the others.
- **Schizophrenia spectrum** discharges have the lowest 7-day rate (38.3%), which points to a need for targeted care coordination.

**Recommendation:** Make a scheduled aftercare appointment a required step in the discharge checklist. Start with the two lowest-performing facilities, and add a 48-hour outreach call for Medicaid members who leave without an appointment.

## Measure logic (simplified)

| Component | Rule used in this project |
|---|---|
| **Denominator** | Acute inpatient discharges with a principal mental health diagnosis, Jan 1 – Dec 1, age 6+, continuously enrolled from discharge through 30 days after |
| **Exclusions** | Died during stay · transferred to another acute or residential facility · readmitted within 30 days (only the later discharge is counted) |
| **Numerator (7-day)** | Visit with a behavioral health provider 1–7 days after discharge (same-day visits don't count) |
| **Numerator (30-day)** | Same, within 1–30 days |

> This is a teaching version of the measure, built to show analytic approach. It is **not** the official NCQA HEDIS® specification, which uses value sets and more detailed rules. HEDIS® is a registered trademark of NCQA.

## Repository structure

```
├── data/
│   ├── members.csv, enrollment.csv, providers.csv
│   ├── inpatient_stays.csv, outpatient_visits.csv
│   ├── fuh_measure_output.csv     ← measure results (Power BI fact table)
│   └── DATA_DICTIONARY.md
├── sql/
│   ├── 01_create_tables.sql       ← table definitions
│   ├── 02_fuh_measure.sql         ← denominator, exclusions, numerator (view)
│   └── 03_summary_queries.sql     ← rates by payer, facility, month, dx + worklist
├── powerbi/
│   ├── dax_measures.md            ← all DAX measures + validation numbers
│   └── dashboard_design.md        ← page-by-page layout
├── scripts/
│   └── generate_synthetic_data.py ← rebuilds the dataset (standard library only)
└── images/                        ← dashboard screenshots
```

## How to run it

1. **Data:** Use the CSVs in `/data`, or regenerate them with `python scripts/generate_synthetic_data.py`.
2. **SQL:** In SQL Server, run `01_create_tables.sql`, load the CSVs, and then run `02_fuh_measure.sql` and `03_summary_queries.sql`.
3. **Power BI:** Connect to `vw_fuh_measure` (or load `data/fuh_measure_output.csv`), add the measures from `powerbi/dax_measures.md`, and follow `powerbi/dashboard_design.md`.

## Skills demonstrated

- Turning a quality-measure specification into SQL logic: denominators, exclusions, continuous enrollment, and look-forward windows
- Window functions (`LEAD`) to detect readmissions, plus `EXISTS` subqueries and CTEs
- Validating results: the SQL output was cross-checked against an independent calculation
- DAX: rates, goal comparison, rolling trends, and segment comparisons
- Turning numbers into an actionable recommendation for a clinical operations audience

## About the data

All data is **synthetic**, generated with fixed random patterns. No real patient, member, provider, or facility information is used, and facility names are fictional.

---

**Alice Kariuki** · Healthcare Data Analyst | PMP | CSM · [LinkedIn](https://www.linkedin.com/in/alice-kariuki-195a843a6)
