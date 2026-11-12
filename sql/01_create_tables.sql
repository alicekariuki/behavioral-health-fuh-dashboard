/* =====================================================================
   FUH Dashboard - table definitions (SQL Server / T-SQL)
   Load the CSV files in /data into these tables (e.g., SSMS Import Flat
   File wizard, BULK INSERT, or Power Query).
   ===================================================================== */

CREATE TABLE members (
    member_id      VARCHAR(12)  NOT NULL PRIMARY KEY,
    date_of_birth  DATE         NOT NULL,
    sex            CHAR(1)      NOT NULL,
    payer          VARCHAR(20)  NOT NULL,   -- Medicaid / Medicare / Commercial
    region         VARCHAR(40)  NOT NULL
);

CREATE TABLE enrollment (
    member_id   VARCHAR(12) NOT NULL REFERENCES members (member_id),
    payer       VARCHAR(20) NOT NULL,
    start_date  DATE        NOT NULL,
    end_date    DATE        NOT NULL
);

CREATE TABLE providers (
    provider_id           VARCHAR(10) NOT NULL PRIMARY KEY,
    provider_name         VARCHAR(80) NOT NULL,
    provider_type         VARCHAR(60) NOT NULL,
    is_behavioral_health  CHAR(1)     NOT NULL,   -- Y = counts as a mental health provider
    region                VARCHAR(40) NOT NULL
);

CREATE TABLE inpatient_stays (
    encounter_id                          VARCHAR(12)  NOT NULL PRIMARY KEY,
    member_id                             VARCHAR(12)  NOT NULL REFERENCES members (member_id),
    facility_id                           VARCHAR(10)  NOT NULL,
    facility_name                         VARCHAR(80)  NOT NULL,
    admit_date                            DATE         NOT NULL,
    discharge_date                        DATE         NOT NULL,
    principal_dx_code                     VARCHAR(10)  NOT NULL,
    principal_dx_desc                     VARCHAR(120) NOT NULL,
    dx_category                           VARCHAR(40)  NOT NULL,
    discharge_disposition                 VARCHAR(60)  NOT NULL,
    followup_appt_scheduled_at_discharge  CHAR(1)      NOT NULL
);

CREATE TABLE outpatient_visits (
    visit_id         VARCHAR(12) NOT NULL PRIMARY KEY,
    member_id        VARCHAR(12) NOT NULL REFERENCES members (member_id),
    visit_date       DATE        NOT NULL,
    provider_id      VARCHAR(10) NOT NULL REFERENCES providers (provider_id),
    visit_setting    VARCHAR(40) NOT NULL,
    primary_dx_code  VARCHAR(10) NOT NULL
);
