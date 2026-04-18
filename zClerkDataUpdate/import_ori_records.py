#!/usr/bin/env python3
"""
Import ORI (Official Records Index) files from Putnam County Clerk of Court.

Pipe-delimited format:
book|page|file_date|from_party|to_party|instrument_number|transaction_code|description

Extracts ZIP files (oriweekly.zip, oriyear.zip, orimaster.zip) in this folder
and upserts into public.ori_records.
"""

import os
import sys
import time
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Iterable, List, Tuple, Dict, Any

from dotenv import load_dotenv
from supabase import create_client, Client

DATA_DIR = Path(__file__).parent
BATCH_SIZE = 500
PROGRESS_EVERY = 10_000
MAX_RETRIES = 5


def get_supabase_client() -> Client:
    env_path = Path(__file__).parent.parent / 'assets' / '.env'
    if env_path.exists():
        load_dotenv(env_path)
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    if not url or not key:
        print('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
        sys.exit(1)
    return create_client(url, key)


def extract_ori_zip(zip_path: Path) -> List[Path]:
    """Extract ORI zip and return paths to data .txt files (not help)."""
    print(f'📦 Extracting {zip_path.name}...')
    extracted: List[Path] = []
    with zipfile.ZipFile(zip_path, 'r') as zf:
        zf.extractall(DATA_DIR)
        for name in zf.namelist():
            if name.lower().endswith('.txt') and 'help' not in name.lower():
                p = DATA_DIR / name
                if p.exists():
                    extracted.append(p)
                    print(f'   → {p.name} ({p.stat().st_size / 1024 / 1024:.1f} MB)')
    return extracted


def parse_date(raw: str):
    raw = raw.strip()
    if not raw:
        return None
    for fmt in ('%m-%d-%Y', '%Y-%m-%d', '%m/%d/%Y'):
        try:
            return datetime.strptime(raw, fmt).date().isoformat()
        except ValueError:
            continue
    return None


def parse_int(raw: str):
    raw = raw.strip()
    if not raw:
        return None
    try:
        return int(raw)
    except ValueError:
        return None


def clean(raw: str):
    raw = raw.strip()
    return raw if raw else None


def parse_file(path: Path) -> Iterable[Dict[str, Any]]:
    """Yield dicts matching ori_records columns."""
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for line_num, line in enumerate(f, 1):
            line = line.rstrip('\n').rstrip('\r')
            if not line:
                continue
            parts = line.split('|')
            if len(parts) < 8:
                continue
            book = parse_int(parts[0])
            page = parse_int(parts[1])
            if book is None or page is None:
                continue
            instrument = clean(parts[5])
            if not instrument:
                continue
            yield {
                'book_number': book,
                'page_number': page,
                'file_date': parse_date(parts[2]),
                'from_party': clean(parts[3]),
                'to_party': clean(parts[4]),
                'instrument_number': instrument,
                'transaction_code': (clean(parts[6]) or '')[:5] or None,
                'description': clean(parts[7]) if len(parts) > 7 else None,
            }


def upsert_batch(sb: Client, rows: List[Dict[str, Any]]) -> int:
    if not rows:
        return 0
    seen: Dict[Tuple, Dict[str, Any]] = {}
    for r in rows:
        key = (
            r['instrument_number'],
            r['book_number'],
            r['page_number'],
            r['from_party'] or '',
            r['to_party'] or '',
        )
        seen[key] = r
    deduped = list(seen.values())

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            sb.table('ori_records').upsert(
                deduped,
                on_conflict='instrument_number,book_number,page_number,from_party,to_party',
                ignore_duplicates=True,
            ).execute()
            return len(deduped)
        except Exception as exc:  # noqa: BLE001
            msg = str(exc)
            is_timeout = 'timeout' in msg.lower() or '57014' in msg
            if attempt == MAX_RETRIES or not is_timeout:
                raise
            backoff = min(30, 2 ** attempt)
            print(f'   ⚠️  batch failed ({msg[:80]}...), retry {attempt}/{MAX_RETRIES} in {backoff}s')
            time.sleep(backoff)
    return 0


def import_file(sb: Client, path: Path) -> Dict[str, int]:
    print(f'\n📄 Importing {path.name}...')
    batch: List[Dict[str, Any]] = []
    total = 0
    upserted = 0
    for row in parse_file(path):
        batch.append(row)
        total += 1
        if len(batch) >= BATCH_SIZE:
            upserted += upsert_batch(sb, batch)
            batch = []
            if total % PROGRESS_EVERY == 0:
                print(f'   ✅ {total:,} rows read, {upserted:,} upserted')
    if batch:
        upserted += upsert_batch(sb, batch)
    print(f'   ✅ Final: {total:,} rows read, {upserted:,} upserted')
    return {'read': total, 'upserted': upserted}


def main() -> None:
    sb = get_supabase_client()
    print('✅ Connected to Supabase')

    # Process in size order: weekly → year → master
    order = ['oriweekly.zip', 'oriyear.zip', 'orimaster.zip']
    zips = [DATA_DIR / n for n in order if (DATA_DIR / n).exists()]

    files: List[Path] = []
    for zp in zips:
        files.extend(extract_ori_zip(zp))

    # Also pick up any loose Rec_*.txt already extracted
    for p in DATA_DIR.glob('Rec_*.txt'):
        if p not in files:
            files.append(p)

    if not files:
        print('❌ No ORI files to import')
        sys.exit(1)

    print(f'\n🚀 Importing {len(files)} file(s)...')
    grand_total = 0
    for path in files:
        result = import_file(sb, path)
        grand_total += result['upserted']

    print('\n' + '=' * 60)
    print(f'✅ DONE. Total upserted: {grand_total:,}')
    print('=' * 60)


if __name__ == '__main__':
    main()
