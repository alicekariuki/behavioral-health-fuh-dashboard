# DAX Measures

The Power BI model uses **`vw_fuh_measure`** (or `data/fuh_measure_output.csv`) as the fact table, named `FUH` in the model, plus a `Date` table related on `discharge_date`.

## Date table

```DAX
Date =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2025, 1, 1 ), DATE ( 2025, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month Number", MONTH ( [Date] ),
    "Month", FORMAT ( [Date], "MMM" ),
    "Quarter", "Q" & QUARTER ( [Date] )
)
```

Mark it as a date table and sort `Month` by `Month Number`.

## Core measures

```DAX
Eligible Discharges = COUNTROWS ( FUH )

7-Day Follow-Ups = SUM ( FUH[fuh_7_day] )

30-Day Follow-Ups = SUM ( FUH[fuh_30_day] )

7-Day Rate = DIVIDE ( [7-Day Follow-Ups], [Eligible Discharges] )

30-Day Rate = DIVIDE ( [30-Day Follow-Ups], [Eligible Discharges] )

Open Care Gaps = [Eligible Discharges] - [30-Day Follow-Ups]

Avg Days to Follow-Up = AVERAGE ( FUH[days_to_followup] )

Avg Length of Stay = AVERAGE ( FUH[length_of_stay] )
```

## Goal comparison

Set the goals to whatever your organization targets. The values below are placeholders.

```DAX
7-Day Goal = 0.50

30-Day Goal = 0.70

7-Day Gap to Goal = [7-Day Rate] - [7-Day Goal]

7-Day Status =
IF ( [7-Day Rate] >= [7-Day Goal], "Meeting goal", "Below goal" )
```

## Appointment-scheduling impact

```DAX
7-Day Rate (Appt Scheduled) =
CALCULATE ( [7-Day Rate], FUH[followup_appt_scheduled_at_discharge] = "Y" )

7-Day Rate (No Appt) =
CALCULATE ( [7-Day Rate], FUH[followup_appt_scheduled_at_discharge] = "N" )

Scheduling Lift (pts) = ( [7-Day Rate (Appt Scheduled)] - [7-Day Rate (No Appt)] ) * 100
```

## Trend

```DAX
7-Day Rate 3-Mo Rolling =
CALCULATE (
    [7-Day Rate],
    DATESINPERIOD ( 'Date'[Date], MAX ( 'Date'[Date] ), -3, MONTH )
)
```

## Validation

Compare the dashboard against `sql/03_summary_queries.sql`. With the default seed (42), the results should be:

| Check | Expected |
|---|---|
| Eligible discharges | 1,249 |
| 7-day rate | 44.1% |
| 30-day rate | 69.1% |
| 7-day rate, appointment scheduled vs. not | 56.8% vs. 29.8% |
