#!/usr/bin/env python3
"""
Import Traffic Weekly CSV/TXT to Supabase with UPSERT support.
This script targets the weekly traffic file (traffWK.zip).
"""

import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, Tuple

try:
    from download_traffic_citations import extract_zip_file
    from import_traffic_citations_upsert import get_supabase_client, upsert_csv_file
except ImportError as e:
    print(f'❌ Import error: {e}')
    print('   Make sure required scripts are in the same directory')
    sys.exit(1)

DATA_DIR = Path(__file__).parent


def _parse_date_range(name: str) -> Optional[Tuple[datetime, datetime]]:
    match = re.search(r'traffic_(\d{8})_(\d{8})', name)
    if not match:
        return None
    try:
        start = datetime.strptime(match.group(1), '%Y%m%d')
        end = datetime.strptime(match.group(2), '%Y%m%d')
        return start, end
    except ValueError:
        return None


def _find_weekly_file() -> Optional[Path]:
    # Prefer weekly ZIP if present
    weekly_zips = sorted(DATA_DIR.glob('traffWK*.zip'), key=lambda p: p.stat().st_mtime, reverse=True)
    if weekly_zips:
        extracted_files = extract_zip_file(weekly_zips[0], DATA_DIR)
        if extracted_files:
            # Prefer the shortest date range (weekly)
            extracted_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
            return extracted_files[0]

    # Fallback: choose traffic file with the smallest date range
    traffic_files = list(DATA_DIR.glob('traffic_*_*.txt'))
    traffic_files.extend(list(DATA_DIR.glob('traffic_*_*.csv')))
    if not traffic_files:
        return None

    best_file = None
    best_span_days = None
    for f in traffic_files:
        date_range = _parse_date_range(f.name)
        if not date_range:
            continue
        start, end = date_range
        span_days = (end - start).days
        if best_span_days is None or span_days < best_span_days:
            best_span_days = span_days
            best_file = f

    return best_file


def main() -> None:
    print('🚀 Starting weekly traffic UPSERT import...')
    print(f'📅 Time: {datetime.now()}')
    print('-' * 60)

    weekly_file = _find_weekly_file()
    if not weekly_file:
        print('❌ No weekly traffic file found in zClerkDataUpdate')
        print('   Expected: traffWK.zip or traffic_YYYYMMDD_YYYYMMDD.txt')
        sys.exit(1)

    print(f'📄 Weekly file: {weekly_file.name}')

    supabase = get_supabase_client()
    print('✅ Connected to Supabase')

    result = upsert_csv_file(weekly_file, supabase)
    print('-' * 60)
    print('✅ Weekly import complete')
    print(f'📄 File processed: {weekly_file.name}')
    print(f'📊 Records processed: {result["inserted"]}')
    print(f'⚠️  Records skipped: {result["skipped"]}')


if __name__ == '__main__':
    main()
