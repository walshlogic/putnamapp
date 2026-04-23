#!/usr/bin/env python3
"""
Ingest the Florida Sex Offender Registry CSV into Supabase (public.fl_sor).

- Upserts on person_nbr (unique).
- Normalizes dates, height, weight, victim_minor.
- Stores original row in raw_row JSONB for audit.
- Uses supabase-py (no direct Postgres connection needed).

Usage:
    python3 ingest_fl_sor_supabase.py /path/to/PublicDataFile_clean.csv
"""

from __future__ import annotations

import csv
import os
import sys
import time
from datetime import datetime, date
from pathlib import Path
from typing import Any, Optional

from dotenv import load_dotenv
from supabase import Client, create_client

BATCH_SIZE = 500
PROGRESS_EVERY = 5_000


def parse_two_or_four_digit_year_date(s: str, pivot: int) -> Optional[str]:
    """Return ISO date string or None.

    For two-digit years, pivot decides the century:
      yy >= pivot -> 1900+yy else 2000+yy.
    """
    if not s:
        return None
    s = s.strip()
    if not s or s in ('00000', 'Unknown', 'UNKNOWN'):
        return None
    try:
        return datetime.strptime(s, '%m/%d/%Y').date().isoformat()
    except ValueError:
        pass
    try:
        dt = datetime.strptime(s, '%m/%d/%y')
        yy = dt.year % 100
        year = 1900 + yy if yy >= pivot else 2000 + yy
        return dt.replace(year=year).date().isoformat()
    except ValueError:
        return None


def parse_int(v: Any) -> Optional[int]:
    if v is None:
        return None
    s = str(v).strip()
    if not s or not s.lstrip('-').isdigit():
        return None
    try:
        return int(s)
    except ValueError:
        return None


def parse_height_inches(h: Optional[str]) -> Optional[int]:
    if not h:
        return None
    hs = str(h).strip()
    if not hs.isdigit():
        return None
    try:
        if len(hs) <= 2:
            inches = int(hs)
            return inches if 0 <= inches <= 100 else None
        feet = int(hs[:-2])
        inches = int(hs[-2:])
        if 0 <= inches < 12 and 0 <= feet < 9:
            return feet * 12 + inches
        return None
    except ValueError:
        return None


def parse_bool_yes_no(v: Optional[str]) -> Optional[bool]:
    if v is None:
        return None
    s = str(v).strip().lower()
    if s in ('yes', 'y', 'true', 't', '1'):
        return True
    if s in ('no', 'n', 'false', 'f', '0'):
        return False
    return None


def row_to_record(row: dict, source_file: str, downloaded_at: str) -> Optional[dict]:
    # Normalize header case — accept both UPPER and lower.
    row = {k.upper(): v for k, v in row.items()}
    person_nbr = (row.get('PERSON_NBR') or '').strip()
    if not person_nbr:
        return None

    birth_raw = (row.get('BIRTH_DATE') or '').strip()
    perm_raw = (row.get('PERM_ADDRESS_ADDED') or '').strip()
    temp_raw = (row.get('TEMP_ADDRESS_ADDED') or '').strip()
    trans_raw = (row.get('TRANS_ADDRESS_ADDED') or '').strip()
    height_raw = (row.get('HEIGHT') or '').strip()
    weight_raw = (row.get('WEIGHT') or '').strip()
    victim_raw = (row.get('VICTIM_MINOR') or '').strip()

    return {
        'person_nbr': person_nbr,
        'first_name': (row.get('FIRST_NAME') or '').strip() or None,
        'middle_name': (row.get('MIDDLE_NAME') or '').strip() or None,
        'last_name': (row.get('LAST_NAME') or '').strip() or None,
        'suffix_name': (row.get('SUFFIX_NAME') or '').strip() or None,
        'status': (row.get('STATUS') or '').strip() or None,
        'subject_type': (row.get('SUBJECT_TYPE') or '').strip() or None,
        'race': (row.get('RACE') or '').strip() or None,
        'sex': (row.get('SEX') or '').strip() or None,
        'eye_color': (row.get('EYE_COLOR') or '').strip() or None,
        'hair': (row.get('HAIR') or '').strip() or None,
        'height_raw': height_raw or None,
        'weight_raw': weight_raw or None,
        'height_in': parse_height_inches(height_raw),
        'weight_lbs': parse_int(weight_raw),
        'birth_date_raw': birth_raw or None,
        'birth_date': parse_two_or_four_digit_year_date(birth_raw, pivot=30),
        'dc_number': (row.get('DC_NUMBER') or '').strip() or None,
        'perm_address_added': perm_raw or None,
        'perm_address_added_date': parse_two_or_four_digit_year_date(perm_raw, pivot=80),
        'perm_address_line_1': (row.get('PERM_ADDRESS_LINE_1') or '').strip() or None,
        'perm_address_line_2': (row.get('PERM_ADDRESS_LINE_2') or '').strip() or None,
        'perm_city': (row.get('PERM_CITY') or '').strip() or None,
        'perm_state': (row.get('PERM_STATE') or '').strip() or None,
        'perm_zip5': (row.get('PERM_ZIP5') or '').strip() or None,
        'perm_zip4': (row.get('PERM_ZIP4') or '').strip() or None,
        'perm_county': (row.get('PERM_COUNTY') or '').strip() or None,
        'temp_address_added': temp_raw or None,
        'temp_address_added_date': parse_two_or_four_digit_year_date(temp_raw, pivot=80),
        'temp_address_line_1': (row.get('TEMP_ADDRESS_LINE_1') or '').strip() or None,
        'temp_address_line_2': (row.get('TEMP_ADDRESS_LINE_2') or '').strip() or None,
        'temp_city': (row.get('TEMP_CITY') or '').strip() or None,
        'temp_state': (row.get('TEMP_STATE') or '').strip() or None,
        'temp_zip5': (row.get('TEMP_ZIP5') or '').strip() or None,
        'temp_zip4': (row.get('TEMP_ZIP4') or '').strip() or None,
        'temp_county': (row.get('TEMP_COUNTY') or '').strip() or None,
        'trans_address_added': trans_raw or None,
        'trans_address_added_date': parse_two_or_four_digit_year_date(trans_raw, pivot=80),
        'trans_address_line_1': (row.get('TRANS_ADDRESS_LINE_1') or '').strip() or None,
        'trans_address_line_2': (row.get('TRANS_ADDRESS_LINE_2') or '').strip() or None,
        'trans_city': (row.get('TRANS_CITY') or '').strip() or None,
        'trans_state': (row.get('TRANS_STATE') or '').strip() or None,
        'trans_zip5': (row.get('TRANS_ZIP5') or '').strip() or None,
        'trans_zip4': (row.get('TRANS_ZIP4') or '').strip() or None,
        'trans_county': (row.get('TRANS_COUNTY') or '').strip() or None,
        'victim_minor_raw': victim_raw or None,
        'victim_minor': parse_bool_yes_no(victim_raw),
        'image_url': (row.get('IMAGE_URL') or '').strip() or None,
        'source_file': source_file,
        'source_downloaded_at': downloaded_at,
        'raw_row': row,
    }


def upsert_batch(sb: Client, rows: list, max_retries: int = 4) -> None:
    for attempt in range(1, max_retries + 1):
        try:
            sb.table('fl_sor').upsert(rows, on_conflict='person_nbr').execute()
            return
        except Exception as exc:  # noqa: BLE001
            msg = str(exc)
            if attempt == max_retries:
                raise
            backoff = min(20, 2 ** attempt)
            print(f'   ⚠️  batch failed ({msg[:100]}) retry {attempt}/{max_retries} in {backoff}s')
            time.sleep(backoff)


def main() -> int:
    if len(sys.argv) < 2:
        print('Usage: ingest_fl_sor_supabase.py <csv_path>', file=sys.stderr)
        return 1

    csv_path = Path(sys.argv[1])
    if not csv_path.exists():
        print(f'❌ Not found: {csv_path}', file=sys.stderr)
        return 1

    env_path = Path(__file__).parent.parent / 'assets' / '.env'
    if env_path.exists():
        load_dotenv(env_path)
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    if not url or not key:
        print('❌ Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY', file=sys.stderr)
        return 1

    sb = create_client(url, key)
    print(f'✅ Connected to Supabase. Source: {csv_path}')

    # Full-replace semantics: each monthly file is a complete snapshot of
    # Putnam County, so wipe the table before inserting so that offenders who
    # moved out of the county are removed.
    print('🗑  Clearing existing fl_sor rows...')
    sb.rpc('truncate_fl_sor').execute()

    source_file = csv_path.name
    downloaded_at = datetime.utcnow().isoformat(timespec='seconds') + 'Z'

    batch: list = []
    total_read = 0
    total_upserted = 0
    skipped = 0

    with open(csv_path, newline='', encoding='utf-8', errors='replace') as f:
        reader = csv.DictReader(f)
        for row in reader:
            total_read += 1
            record = row_to_record(row, source_file, downloaded_at)
            if record is None:
                skipped += 1
                continue
            batch.append(record)
            if len(batch) >= BATCH_SIZE:
                upsert_batch(sb, batch)
                total_upserted += len(batch)
                batch.clear()
                if total_read % PROGRESS_EVERY == 0:
                    print(f'   ✅ {total_read:,} read, {total_upserted:,} upserted')

    if batch:
        upsert_batch(sb, batch)
        total_upserted += len(batch)

    print('-' * 50)
    print(f'✅ Done. {total_read:,} rows read, {total_upserted:,} upserted, {skipped} skipped (no person_nbr).')
    return 0


if __name__ == '__main__':
    sys.exit(main())
