# Dashboard Design

Build the report in Power BI Desktop with the measures in [`dax_measures.md`](dax_measures.md). Save the file as `powerbi/FUH_Dashboard.pbix` and add screenshots to `/images`.

## Page 1 — Executive Summary

| Visual | Fields |
|---|---|
| KPI cards (4) | Eligible Discharges · 7-Day Rate · 30-Day Rate · Open Care Gaps |
| Gauge or bullet chart | 7-Day Rate vs. 7-Day Goal |
| Line chart | Month × 7-Day Rate and 30-Day Rate |
| Clustered bar | Payer × 7-Day Rate, 30-Day Rate |
| Slicers | Payer, Region, Facility, Age Group |

## Page 2 — Drivers

| Visual | Fields |
|---|---|
| Bar chart | Facility × 7-Day Rate (sorted lowest first) |
| Bar chart | Dx Category × 7-Day Rate |
| Card pair | 7-Day Rate (Appt Scheduled) vs. 7-Day Rate (No Appt) |
| Matrix | Region (rows) × Payer (columns) × 7-Day Rate, with conditional formatting |
| Histogram / column | days_to_followup (1–30) × count of discharges |

## Page 3 — Care Gap Worklist

| Visual | Fields |
|---|---|
| Table | encounter_id, member_id, payer, facility_name, discharge_date, days since discharge, appt scheduled |
| Filter | fuh_30_day = 0 |
| Note | A care coordinator would use this list for outreach calls |

## Design tips

- Use one accent color for "meets goal" and one for "below goal". Keep everything else neutral.
- Put the measure definition (denominator, numerator, exclusions) in a tooltip or info button, so reviewers can see you understand the logic.
- Add a "Data: synthetic" footnote on every page.
