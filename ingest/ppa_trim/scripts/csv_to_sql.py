#!/usr/bin/env python3
"""
Convert parsed TRIM CSVs to batched SQL INSERT files for MCP execute_sql.

Reads CSVs from work/out/ and writes one or more .sql files per table to
work/sql/ with multi-row INSERTs. Target batch size ~1.5MB per file so each
MCP call stays well under any reasonable payload cap.
"""
import csv, sys
from pathlib import Path

OUT = Path(sys.argv[1])   # work/out
SQL = Path(sys.argv[2])   # work/sql
SQL.mkdir(parents=True, exist_ok=True)

TARGET_BYTES = 1_500_000  # ~1.5MB per SQL file

# Column order + numeric/bool cols per staging table.
# numeric/bool cols are emitted as NULL when empty; text cols are always quoted
# unless empty (then NULL). Empty numeric = NULL.
TABLES = {
    "parcels": {
        "stg":  "ppa.stg_parcels",
        "text_cols": {
            "parcel_number","physical_address","legal_description",
            "owner_name","co_owner_name","mailing_addr1","mailing_addr2",
            "mailing_city","mailing_state","mailing_zip","petition_deadline",
        },
        "bool_cols": {"continued_on_roll"},
    },
    "assessment_reductions": {
        "stg":  "ppa.stg_ar",
        "text_cols": {"parcel_number","description","tax_district"},
        "bool_cols": set(),
    },
    "exemptions": {
        "stg":  "ppa.stg_ex",
        "text_cols": {"parcel_number","description","tax_district"},
        "bool_cols": set(),
    },
    "taxing_authorities": {
        "stg":  "ppa.stg_ta",
        "text_cols": {"parcel_number","authority_type","authority_label"},
        "bool_cols": set(),
    },
    "non_ad_valorem": {
        "stg":  "ppa.stg_nav",
        "text_cols": {"parcel_number","description"},
        "bool_cols": set(),
    },
    "public_hearings": {
        "stg":  "ppa.stg_ph",
        "text_cols": {
            "county_meeting","county_place","schools_meeting","schools_place",
            "wmd_meeting","wmd_place","municipality_meeting","municipality_place",
        },
        "bool_cols": set(),
    },
}

def fmt_value(val, col, text_cols, bool_cols):
    """Format one value as a SQL literal. Empty -> NULL."""
    if val == "" or val is None:
        return "NULL"
    if col in bool_cols:
        return "TRUE" if val.lower() in ("true","1","t","yes") else "FALSE"
    if col in text_cols:
        return "'" + val.replace("'", "''") + "'"
    # numeric (int/numeric): pass through; we already parsed in parse_trim.py
    return val

def emit(name, spec):
    csv_path = OUT / f"{name}.csv"
    with open(csv_path, "r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        headers = next(reader)
        col_list = ",".join(headers)
        insert_prefix = f"INSERT INTO {spec['stg']} ({col_list}) VALUES\n"

        batch_idx = 0
        batch_buf = []
        batch_size = 0
        row_count = 0

        def flush():
            nonlocal batch_idx, batch_buf, batch_size
            if not batch_buf:
                return
            path = SQL / f"{name}_{batch_idx:04d}.sql"
            with open(path, "w", encoding="utf-8") as out:
                out.write(insert_prefix)
                out.write(",\n".join(batch_buf))
                out.write(";\n")
            batch_idx += 1
            batch_buf = []
            batch_size = 0

        for row in reader:
            vals = [
                fmt_value(v, headers[i], spec["text_cols"], spec["bool_cols"])
                for i, v in enumerate(row)
            ]
            tuple_str = "(" + ",".join(vals) + ")"
            t_bytes = len(tuple_str) + 2  # plus ",\n"
            if batch_size + t_bytes + len(insert_prefix) > TARGET_BYTES and batch_buf:
                flush()
            batch_buf.append(tuple_str)
            batch_size += t_bytes
            row_count += 1

        flush()
        print(f"  {name:25s} {row_count:>7} rows -> {batch_idx} files", file=sys.stderr)

for name, spec in TABLES.items():
    emit(name, spec)
print("Done.", file=sys.stderr)
