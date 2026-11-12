"""
Generate a synthetic behavioral health dataset for the FUH (Follow-Up After
Hospitalization for Mental Illness) dashboard project.

All data is fictional. No real patients, members, or providers are represented.

Usage:
    python scripts/generate_synthetic_data.py            # writes CSVs to ./data
    python scripts/generate_synthetic_data.py --seed 7   # different random draw

Uses only the Python standard library.
"""
import argparse
import csv
import random
from datetime import date, timedelta
from pathlib import Path

MEASUREMENT_YEAR = 2025

PAYERS = {  # payer: (share of members, base 7-day follow-up probability)
    "Medicaid": (0.50, 0.33),
    "Medicare": (0.25, 0.42),
    "Commercial": (0.25, 0.52),
}
REGIONS = ["Montgomery", "Prince George's", "Frederick", "Howard", "Baltimore County"]
REGION_EFFECT = {"Montgomery": 0.06, "Prince George's": -0.05, "Frederick": -0.02,
                 "Howard": 0.04, "Baltimore County": 0.0}

FACILITIES = [
    ("FAC01", "Riverbend Behavioral Hospital"),
    ("FAC02", "Oak Hill Medical Center - Psych Unit"),
    ("FAC03", "Lakeside Psychiatric Institute"),
    ("FAC04", "Northgate Regional Hospital - BH Unit"),
]
FACILITY_EFFECT = {"FAC01": 0.08, "FAC02": -0.04, "FAC03": 0.02, "FAC04": -0.07}

DIAGNOSES = [  # (ICD-10 code, description, category, weight)
    ("F32.2", "Major depressive disorder, single episode, severe", "Depressive disorders", 22),
    ("F33.2", "Major depressive disorder, recurrent, severe", "Depressive disorders", 18),
    ("F31.2", "Bipolar disorder, current episode manic, severe with psychotic features", "Bipolar disorders", 14),
    ("F31.4", "Bipolar disorder, current episode depressed, severe", "Bipolar disorders", 10),
    ("F20.9", "Schizophrenia, unspecified", "Schizophrenia spectrum", 12),
    ("F25.0", "Schizoaffective disorder, bipolar type", "Schizophrenia spectrum", 8),
    ("F43.10", "Post-traumatic stress disorder, unspecified", "Trauma & stressor-related", 9),
    ("F41.1", "Generalized anxiety disorder", "Anxiety disorders", 7),
]
DX_EFFECT = {"Depressive disorders": 0.03, "Bipolar disorders": 0.0,
             "Schizophrenia spectrum": -0.06, "Trauma & stressor-related": 0.02,
             "Anxiety disorders": 0.04}

PROVIDER_TYPES = [  # (type, counts toward FUH?)
    ("Psychiatrist", True), ("Psychiatric Nurse Practitioner", True),
    ("Psychologist", True), ("Licensed Clinical Social Worker", True),
    ("Licensed Professional Counselor", True), ("Primary Care Physician", False),
]
VISIT_SETTINGS = [  # (setting, weight)
    ("Outpatient office", 50), ("Telehealth", 25), ("Community mental health center", 12),
    ("Intensive outpatient (IOP)", 8), ("Partial hospitalization (PHP)", 5),
]

FIRST = ["Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Jamie", "Avery",
         "Quinn", "Drew", "Reese", "Rowan", "Skyler", "Emerson", "Hayden", "Parker"]
LAST = ["Mwangi", "Okafor", "Smith", "Nguyen", "Garcia", "Patel", "Johnson", "Kim",
        "Brown", "Lopez", "Williams", "Davis", "Otieno", "Martin", "Lee", "Clark"]


def rand_date(start: date, end: date) -> date:
    return start + timedelta(days=random.randint(0, (end - start).days))


def weighted(items, weights):
    return random.choices(items, weights=weights, k=1)[0]


def main(out_dir: Path, n_members: int, seed: int) -> None:
    random.seed(seed)
    out_dir.mkdir(parents=True, exist_ok=True)

    # ---------------- providers ----------------
    providers = []
    for i in range(1, 61):
        ptype, counts = weighted(PROVIDER_TYPES, [12, 8, 8, 14, 10, 8])
        providers.append({
            "provider_id": f"PRV{i:04d}",
            "provider_name": f"{random.choice(FIRST)} {random.choice(LAST)}",
            "provider_type": ptype,
            "is_behavioral_health": "Y" if counts else "N",
            "region": random.choice(REGIONS),
        })
    bh_providers = [p for p in providers if p["is_behavioral_health"] == "Y"]
    pcp_providers = [p for p in providers if p["is_behavioral_health"] == "N"]

    # ---------------- members & enrollment ----------------
    members, enrollment = [], []
    payer_names = list(PAYERS)
    for i in range(1, n_members + 1):
        payer = weighted(payer_names, [PAYERS[p][0] for p in payer_names])
        if payer == "Medicare":
            age = random.randint(65, 90) if random.random() < 0.8 else random.randint(30, 64)
        else:
            age = random.randint(6, 64)
        dob = date(MEASUREMENT_YEAR, 7, 1) - timedelta(days=age * 365 + random.randint(0, 364))
        mid = f"MBR{i:06d}"
        members.append({
            "member_id": mid,
            "date_of_birth": dob.isoformat(),
            "sex": random.choice(["F", "M"]),
            "payer": payer,
            "region": random.choice(REGIONS),
        })
        # Most members enrolled all year; ~8% have a gap so continuous-enrollment logic matters.
        if random.random() < 0.92:
            enrollment.append({"member_id": mid, "payer": payer,
                               "start_date": f"{MEASUREMENT_YEAR}-01-01",
                               "end_date": f"{MEASUREMENT_YEAR + 1}-12-31"})
        else:
            gap_start = rand_date(date(MEASUREMENT_YEAR, 2, 1), date(MEASUREMENT_YEAR, 11, 1))
            enrollment.append({"member_id": mid, "payer": payer,
                               "start_date": f"{MEASUREMENT_YEAR}-01-01",
                               "end_date": gap_start.isoformat()})
            enrollment.append({"member_id": mid, "payer": payer,
                               "start_date": (gap_start + timedelta(days=random.randint(20, 60))).isoformat(),
                               "end_date": f"{MEASUREMENT_YEAR + 1}-12-31"})

    # ---------------- inpatient stays & follow-up visits ----------------
    stays, visits = [], []
    stay_n = visit_n = 0
    member_lookup = {m["member_id"]: m for m in members}
    hospitalized = random.sample(members, k=int(n_members * 0.22))

    for m in hospitalized:
        n_stays = weighted([1, 2, 3], [78, 17, 5])
        for _ in range(n_stays):
            stay_n += 1
            fac_id, fac_name = random.choice(FACILITIES)
            code, desc, cat, _ = weighted(DIAGNOSES, [d[3] for d in DIAGNOSES])
            admit = rand_date(date(MEASUREMENT_YEAR, 1, 1), date(MEASUREMENT_YEAR, 12, 20))
            los = max(1, int(random.gauss(7, 3)))
            discharge = admit + timedelta(days=los)
            disposition = weighted(
                ["Home/self-care", "Home with services", "Transfer to another acute facility",
                 "Residential treatment", "Left against medical advice", "Expired"],
                [62, 18, 4, 7, 8, 1])
            appt_scheduled = random.random() < 0.55
            stays.append({
                "encounter_id": f"IP{stay_n:07d}",
                "member_id": m["member_id"],
                "facility_id": fac_id,
                "facility_name": fac_name,
                "admit_date": admit.isoformat(),
                "discharge_date": discharge.isoformat(),
                "principal_dx_code": code,
                "principal_dx_desc": desc,
                "dx_category": cat,
                "discharge_disposition": disposition,
                "followup_appt_scheduled_at_discharge": "Y" if appt_scheduled else "N",
            })
            if disposition == "Expired":
                continue

            # Probability of a qualifying visit within 7 days.
            p7 = PAYERS[m["payer"]][1] + REGION_EFFECT[m["region"]] + FACILITY_EFFECT[fac_id] + DX_EFFECT[cat]
            p7 += 0.18 if appt_scheduled else -0.10
            p7 -= 0.15 if disposition == "Left against medical advice" else 0
            p7 = min(max(p7, 0.05), 0.92)
            p30_extra = 0.45  # chance of follow-up in days 8–30 if none in first 7

            r = random.random()
            if r < p7:
                offset = random.randint(1, 7)
            elif random.random() < p30_extra:
                offset = random.randint(8, 30)
            else:
                offset = random.randint(31, 75) if random.random() < 0.5 else None

            def add_visit(day_offset, provider):
                nonlocal visit_n
                visit_n += 1
                visits.append({
                    "visit_id": f"OP{visit_n:08d}",
                    "member_id": m["member_id"],
                    "visit_date": (discharge + timedelta(days=day_offset)).isoformat(),
                    "provider_id": provider["provider_id"],
                    "visit_setting": weighted([s for s, _ in VISIT_SETTINGS], [w for _, w in VISIT_SETTINGS]),
                    "primary_dx_code": code,
                })

            if offset is not None:
                add_visit(offset, random.choice(bh_providers))
            # Noise: same-day visits (do NOT count) and PCP-only visits (do NOT count).
            if random.random() < 0.06:
                add_visit(0, random.choice(bh_providers))
            if random.random() < 0.15:
                add_visit(random.randint(1, 30), random.choice(pcp_providers))

    def write(name, rows):
        with open(out_dir / name, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
        print(f"  {name:<28} {len(rows):>6,} rows")

    print(f"Writing synthetic data to {out_dir}/")
    write("members.csv", members)
    write("enrollment.csv", enrollment)
    write("providers.csv", providers)
    write("inpatient_stays.csv", stays)
    write("outpatient_visits.csv", visits)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(Path(__file__).resolve().parent.parent / "data"))
    ap.add_argument("--members", type=int, default=6000)
    ap.add_argument("--seed", type=int, default=42)
    a = ap.parse_args()
    main(Path(a.out), a.members, a.seed)
