#!/usr/bin/env python3
"""
Run all available Clerk of Court imports based on files present in this folder.
Processes: traffic yearly (traffYR), traffic weekly (traffWK), criminal history.
"""

import re
import sys
from datetime import datetime
from pathlib import Path

try:
    from download_traffic_citations import extract_zip_file as extract_traffic_zip
    from download_criminal_back_history import extract_zip_file as extract_criminal_zip
    from import_traffic_citations_upsert import get_supabase_client as get_supabase_client, upsert_csv_file as upsert_traffic
    from import_criminal_back_history import upsert_csv_file as upsert_criminal
except ImportError as e:
    print(f'❌ Import error: {e}')
    print('   Make sure required scripts are in the same directory')
    sys.exit(1)


DATA_DIR = Path(__file__).parent


def _parse_traffic_range(name: str):
    match = re.search(r'traffic_(\d{8})_(\d{8})', name)
    if not match:
        return None
    try:
        start = datetime.strptime(match.group(1), '%Y%m%d').date()
        end = datetime.strptime(match.group(2), '%Y%m%d').date()
        return start, end
    except ValueError:
        return None


def _find_traffic_files():
    traffic_files = []

    weekly_zips = sorted(DATA_DIR.glob('traffWK*.zip'), key=lambda p: p.stat().st_mtime, reverse=True)
    if weekly_zips:
        extracted = extract_traffic_zip(weekly_zips[0], DATA_DIR)
        if extracted:
            if isinstance(extracted, list):
                traffic_files.extend(extracted)
            else:
                traffic_files.append(extracted)

    yearly_zips = sorted(DATA_DIR.glob('traffYR*.zip'), key=lambda p: p.stat().st_mtime, reverse=True)
    if yearly_zips:
        extracted = extract_traffic_zip(yearly_zips[0], DATA_DIR)
        if extracted:
            if isinstance(extracted, list):
                traffic_files.extend(extracted)
            else:
                traffic_files.append(extracted)

    if not traffic_files:
        traffic_files.extend(list(DATA_DIR.glob('traffic_*_*.txt')))
        traffic_files.extend(list(DATA_DIR.glob('traffic_*_*.csv')))

    # De-dup and sort by date range (weekly first, then yearly)
    unique = []
    seen = set()
    for f in traffic_files:
        if f.exists() and f.name not in seen and 'help' not in f.name.lower():
            unique.append(f)
            seen.add(f.name)

    def sort_key(path: Path):
        date_range = _parse_traffic_range(path.name)
        if not date_range:
            return (999999, path.stat().st_mtime)
        start, end = date_range
        span = (end - start).days
        return (span, -path.stat().st_mtime)

    unique.sort(key=sort_key)
    return unique


def _find_criminal_files():
    criminal_files = []

    criminal_zips = []
    criminal_zips.extend(DATA_DIR.glob('criminal_HS*.zip'))
    criminal_zips.extend(DATA_DIR.glob('criminal_YR*.zip'))
    criminal_zips = sorted(criminal_zips, key=lambda p: p.stat().st_mtime, reverse=True)

    if criminal_zips:
        criminal_files.extend(extract_criminal_zip(criminal_zips[0], DATA_DIR) or [])
    else:
        criminal_files.extend(list(DATA_DIR.glob('criminal_*.txt')))
        criminal_files.extend(list(DATA_DIR.glob('criminal_*.csv')))

    # De-dup and remove help.txt
    unique = []
    seen = set()
    for f in criminal_files:
        if f.exists() and f.name not in seen and f.name.lower() != 'help.txt':
            unique.append(f)
            seen.add(f.name)

    unique.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return unique


def _cleanup_files(processed_files: list[Path]) -> None:
    files_to_delete = []
    for f in processed_files:
        try:
            if f.exists() and f.is_file() and f.parent == DATA_DIR:
                files_to_delete.append(f)
        except OSError:
            continue

    # Also remove ZIP files after successful import
    zip_patterns = [
        'traffWK*.zip',
        'traffYR*.zip',
        'criminal_HS*.zip',
        'criminal_YR*.zip',
    ]
    for pattern in zip_patterns:
        files_to_delete.extend(DATA_DIR.glob(pattern))

    # Remove help files extracted from ZIPs
    files_to_delete.extend(DATA_DIR.glob('trafhelp.txt'))
    files_to_delete.extend(DATA_DIR.glob('help.txt'))

    # De-duplicate and delete
    unique = []
    seen = set()
    for f in files_to_delete:
        if f not in seen:
            unique.append(f)
            seen.add(f)

    if unique:
        print('\n🧹 Cleanup: removing processed ZIP/TXT files...')
        for f in unique:
            try:
                if f.exists() and f.is_file() and f.parent == DATA_DIR:
                    f.unlink()
                    print(f'   ✅ Removed {f.name}')
            except OSError as e:
                print(f'   ⚠️  Could not remove {f.name}: {e}')


def main() -> None:
    print('=' * 60)
    print('🚀 CLERK DATA UPDATE (ALL)')
    print('=' * 60)
    print(f'📅 Started: {datetime.now()}')
    print()

    supabase = get_supabase_client()
    print('✅ Connected to Supabase')

    traffic_files = _find_traffic_files()
    criminal_files = _find_criminal_files()

    if not traffic_files and not criminal_files:
        print('❌ No files found to process')
        print(f'   Folder: {DATA_DIR}')
        sys.exit(1)

    total_traffic = 0
    total_criminal = 0

    if traffic_files:
        print('\n🚦 Traffic files to process:')
        for f in traffic_files:
            print(f'   - {f.name}')
        for f in traffic_files:
            result = upsert_traffic(f, supabase)
            total_traffic += result['inserted']

    if criminal_files:
        print('\n⚖️  Criminal files to process:')
        for f in criminal_files:
            print(f'   - {f.name}')
        for f in criminal_files:
            result = upsert_criminal(f, supabase)
            total_criminal += result['inserted']

    print()
    print('=' * 60)
    print('✅ ALL UPDATES COMPLETE')
    print('=' * 60)
    print(f'📊 Traffic records processed: {total_traffic}')
    print(f'📊 Criminal records processed: {total_criminal}')
    print(f'📅 Completed: {datetime.now()}')

    _cleanup_files(traffic_files + criminal_files)


if __name__ == '__main__':
    main()
