#!/usr/bin/env python3
"""
Backfill PCSO jail log bookings by date range.

Submits the jail.aspx search form with a date range (always Both Current And
Released → TypeJailSearch=2), paginates all results via AddMoreResults, and
upserts into Supabase. Logs each chunk to public.scrape_runs.

Usage:
    python3 backfill_pcso_bookings.py --start-date 2025-06-15 --end-date 2025-06-15
    python3 backfill_pcso_bookings.py --start-date 2025-01-01 --end-date 2025-12-31
    python3 backfill_pcso_bookings.py --start-date 2025-06-15 --end-date 2025-06-15 --dry-run
"""
import argparse
import json
import logging
import os
import re
import signal
import subprocess
import sys
import time
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

import requests
from bs4 import BeautifulSoup
from dotenv import load_dotenv

script_dir = Path(__file__).parent
# Repo layout: script lives in scripts/, env file lives at <repo>/assets/.env.
# Try repo-root first, fall back to next-to-script for the older layout.
repo_dir = script_dir.parent
env_path_repo = repo_dir / 'assets' / '.env'
env_path_local = script_dir / 'assets' / '.env'
if env_path_repo.exists():
    load_dotenv(env_path_repo)
elif env_path_local.exists():
    load_dotenv(env_path_local)
else:
    load_dotenv()

import import_pcso_bookings as hourly

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(script_dir / 'logs' / 'pcso_bookings_backfill.log'),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger('backfill')

BASE = 'https://smartweb.pcso.us/smartwebclient'
JAIL_URL = f'{BASE}/jail.aspx'
ADD_MORE_URL = f'{BASE}/Jail.aspx/AddMoreResults'

USER_AGENT = (
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
)

REQUEST_TIMEOUT = 60
PAGE_SIZE = 20  # PCSO returns up to 20 per AddMoreResults call
INTER_CHUNK_PAUSE_SEC = 1.0  # Be polite between date-range searches
INTER_PAGE_PAUSE_SEC = 0.3   # Between paginated AddMoreResults calls

CRON_PLIST = Path.home() / 'Library' / 'LaunchAgents' / 'com.pcso.scrape.hourly.plist'
RESTORE_HELPER = Path('/tmp/pcso_restore_cron.sh')


def _launchctl(action: str) -> Tuple[int, str]:
    """Run launchctl {action} on the cron plist. Returns (rc, combined_output)."""
    if not CRON_PLIST.exists():
        return (0, f'plist not found: {CRON_PLIST} (nothing to {action})')
    try:
        r = subprocess.run(
            ['launchctl', action, str(CRON_PLIST)],
            capture_output=True, text=True, timeout=10,
        )
        return (r.returncode, (r.stdout + r.stderr).strip())
    except Exception as exc:
        return (1, f'{type(exc).__name__}: {exc}')


def disable_cron():
    rc, out = _launchctl('unload')
    logger.info('🛑 cron disable rc=%d %s', rc, out)
    # Write a restore helper so the user can re-enable manually after a hard crash
    RESTORE_HELPER.write_text(
        f'#!/usr/bin/env bash\nlaunchctl load "{CRON_PLIST}"\necho "cron re-enabled"\n'
    )
    RESTORE_HELPER.chmod(0o755)
    logger.info('   (manual restore if needed: bash %s)', RESTORE_HELPER)


def enable_cron():
    rc, out = _launchctl('load')
    logger.info('▶ cron enable rc=%d %s', rc, out)
    try:
        RESTORE_HELPER.unlink(missing_ok=True)
    except Exception:
        pass


def load_completed_days(supabase, start: date, end: date) -> Set[Tuple[str, str]]:
    """Read scrape_runs for successful day-chunks already done in [start, end]."""
    try:
        rows = (
            supabase.table('scrape_runs')
            .select('begin_date, end_date, ok')
            .gte('begin_date', start.isoformat())
            .lte('end_date', (end + timedelta(days=1)).isoformat())
            .eq('ok', True)
            .limit(10000)
            .execute()
            .data
        ) or []
    except Exception as exc:
        logger.warning('could not load scrape_runs for resume: %s', exc)
        return set()
    completed: Set[Tuple[str, str]] = set()
    for r in rows:
        b = (r.get('begin_date') or '')[:10]
        e = (r.get('end_date') or '')[:10]
        if b and e:
            completed.add((b, e))
    return completed


def _fetch_initial_page(session: requests.Session) -> Dict[str, str]:
    """GET jail.aspx and extract the ASP.NET form state fields."""
    resp = session.get(JAIL_URL, timeout=REQUEST_TIMEOUT, headers={'User-Agent': USER_AGENT})
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, 'html.parser')
    state: Dict[str, str] = {}
    for name in ('__VIEWSTATE', '__VIEWSTATEGENERATOR', '__EVENTVALIDATION'):
        tag = soup.find('input', {'name': name})
        state[name] = tag.get('value', '') if tag else ''
    return state


def _submit_search(
    session: requests.Session,
    state: Dict[str, str],
    begin_mdY: str,
    end_mdY: str,
) -> str:
    """POST the jail.aspx form with date range + TypeSearch=2. Returns response HTML."""
    form = {
        '__EVENTTARGET': '',
        '__EVENTARGUMENT': '',
        '__VIEWSTATE': state.get('__VIEWSTATE', ''),
        '__VIEWSTATEGENERATOR': state.get('__VIEWSTATEGENERATOR', ''),
        '__EVENTVALIDATION': state.get('__EVENTVALIDATION', ''),
        'txbLastName': '',
        'txbFirstName': '',
        'txbMiddleName': '',
        'tbBeginDate': begin_mdY,
        'tbEndDate': end_mdY,
        'tbBeginReleaseDate': '',
        'tbEndReleaseDate': '',
        'TypeSearch': '2',               # Both Current And Released (always)
        'SearchSortOption': '0',         # Sort by Name
        'SearchOrderOption': '0',        # Ascending
        'btnSumit': 'Submit',            # PCSO spelled it this way in the markup
    }
    resp = session.post(
        JAIL_URL,
        data=form,
        timeout=REQUEST_TIMEOUT,
        headers={
            'User-Agent': USER_AGENT,
            'Referer': JAIL_URL,
            'Content-Type': 'application/x-www-form-urlencoded',
        },
    )
    resp.raise_for_status()
    return resp.text


def _paginate(
    session: requests.Session,
    begin_mdY: str,
    end_mdY: str,
    records_loaded: int,
) -> Tuple[str, int, int]:
    """Call AddMoreResults. Returns (html_fragment, results_returned, results_attempted)."""
    payload = {
        'FirstName': '',
        'MiddleName': '',
        'LastName': '',
        'BeginBookDate': begin_mdY,
        'EndBookDate': end_mdY,
        'BeginReleaseDate': '',
        'EndReleaseDate': '',
        'TypeJailSearch': 2,
        'RecordsLoaded': records_loaded,
        'SortOption': 0,
        'SortOrder': 0,
        'IsDefault': False,
    }
    resp = session.post(
        ADD_MORE_URL,
        data=json.dumps(payload),
        timeout=REQUEST_TIMEOUT,
        headers={
            'User-Agent': USER_AGENT,
            'Referer': JAIL_URL,
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'X-Requested-With': 'XMLHttpRequest',
        },
    )
    resp.raise_for_status()
    data = resp.json()['d']['Data']
    return (data['data'] or '', int(data['resultsReturned']), int(data['resultsAttempted']))


def _parse_bookings_from_html(html: str) -> List[Dict[str, Any]]:
    """Extract booking dicts from any HTML chunk (initial page or AddMoreResults fragment)."""
    if not html or not html.strip():
        return []
    soup = BeautifulSoup(html, 'html.parser')
    results: List[Dict[str, Any]] = []
    info_tables = [
        table
        for table in soup.find_all('table')
        if not (table.get('class') and 'JailViewCharges' in table.get('class'))
        and table.find(string=re.compile(r'Booking No:', re.IGNORECASE))
    ]
    for table in info_tables:
        try:
            booking = hourly._parse_booking_info_table(table)
            if booking:
                results.append(booking)
        except Exception as exc:
            logger.warning('Parse error on one booking table: %s', exc)
    return results


def _released_date_from_raw(raw_text: Optional[str]) -> Optional[str]:
    """TRIM parser doesn't pick up Released date — extract from raw card text."""
    if not raw_text:
        return None
    m = re.search(
        r'Released:\s*(\d{1,2}/\d{1,2}/\d{4})\s+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)',
        raw_text,
        re.IGNORECASE,
    )
    if not m:
        m = re.search(r'Released:\s*(\d{1,2}/\d{1,2}/\d{4})', raw_text, re.IGNORECASE)
    if not m:
        return None
    date_str = m.group(1) + (f' {m.group(2)}' if m.lastindex and m.lastindex >= 2 else '')
    return hourly._to_utc_iso_safe(date_str)


def scrape_chunk(begin: date, end: date) -> List[Dict[str, Any]]:
    """Scrape a single date-range chunk. Returns list of booking dicts."""
    begin_mdY = begin.strftime('%m/%d/%Y')
    end_mdY = end.strftime('%m/%d/%Y')
    logger.info('▶ Scraping %s → %s', begin_mdY, end_mdY)

    session = requests.Session()
    state = _fetch_initial_page(session)
    initial_html = _submit_search(session, state, begin_mdY, end_mdY)
    bookings = _parse_bookings_from_html(initial_html)
    records_loaded = len(bookings)
    logger.info('   initial page: %d bookings', records_loaded)

    # Paginate. Stop when resultsAttempted > resultsReturned (server says "no more").
    while True:
        time.sleep(INTER_PAGE_PAUSE_SEC)
        try:
            html_frag, ret, attempted = _paginate(session, begin_mdY, end_mdY, records_loaded)
        except Exception as exc:
            logger.warning('   pagination error at offset %d: %s', records_loaded, exc)
            break
        if ret == 0:
            break
        more = _parse_bookings_from_html(html_frag)
        bookings.extend(more)
        records_loaded += ret
        logger.info('   +%d (total %d) [attempted=%d]', ret, records_loaded, attempted)
        if attempted > ret:
            break  # Server signaled end of matches
        if ret < PAGE_SIZE:
            break  # Partial page = end

    # Backfill released_date from raw_card_text where possible
    for b in bookings:
        if not b.get('released_date'):
            b['released_date'] = _released_date_from_raw(b.get('raw_card_text'))

    logger.info('   ✅ chunk total: %d bookings', len(bookings))
    return bookings


def log_scrape_run(
    supabase,
    begin: date,
    end: date,
    ok: bool,
    bookings_upserted: int,
    charges_written: int,
    error_text: Optional[str] = None,
) -> None:
    try:
        supabase.table('scrape_runs').insert({
            'begin_date': begin.isoformat(),
            'end_date': end.isoformat(),
            'ok': ok,
            'bookings_upserted': bookings_upserted,
            'charges_written': charges_written,
            'error_text': error_text,
        }).execute()
    except Exception as exc:
        logger.warning('scrape_runs log failed: %s', exc)


def daterange_chunks(start: date, end: date, chunk_days: int):
    """Yield (chunk_start, chunk_end) tuples walking from start → end."""
    cur = start
    step = timedelta(days=chunk_days - 1) if chunk_days > 1 else timedelta(0)
    while cur <= end:
        last = min(cur + step, end)
        yield (cur, last)
        cur = last + timedelta(days=1)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--start-date', required=True, help='YYYY-MM-DD (inclusive)')
    ap.add_argument('--end-date', required=True, help='YYYY-MM-DD (inclusive)')
    ap.add_argument('--chunk-days', type=int, default=1,
                    help='Days per search chunk. Default 1 (safest — PCSO returns ~500 cap on wider ranges).')
    ap.add_argument('--dry-run', action='store_true', help='Parse but do not upsert or log')
    ap.add_argument('--no-photos', action='store_true',
                    help='Skip photo sync (photos ON by default — synced inline with bookings)')
    ap.add_argument('--skip-charges', action='store_true', help='Skip charges sync')
    ap.add_argument('--no-cron-toggle', action='store_true',
                    help='Do not disable the hourly launchd cron during this run')
    args = ap.parse_args()

    start = datetime.strptime(args.start_date, '%Y-%m-%d').date()
    end = datetime.strptime(args.end_date, '%Y-%m-%d').date()
    if end < start:
        ap.error('--end-date must be >= --start-date')

    logger.info('=' * 60)
    logger.info('🏛️  PCSO backfill: %s → %s (chunk=%d days, dry_run=%s)',
                start, end, args.chunk_days, args.dry_run)
    logger.info('=' * 60)

    supabase = None
    completed: Set[Tuple[str, str]] = set()
    if not args.dry_run:
        supabase = hourly.get_supabase_client()
        logger.info('✅ Supabase connected')
        completed = load_completed_days(supabase, start, end)
        if completed:
            logger.info('⏭  resume: %d day-chunks already complete (will skip)', len(completed))

    cron_was_toggled = False
    if not args.dry_run and not args.no_cron_toggle:
        disable_cron()
        cron_was_toggled = True

    def _on_signal(signum, frame):
        logger.warning('⚠️  signal %d received — restoring cron and exiting', signum)
        if cron_was_toggled:
            enable_cron()
        sys.exit(130)
    signal.signal(signal.SIGINT, _on_signal)
    signal.signal(signal.SIGTERM, _on_signal)

    totals = {'chunks': 0, 'skipped': 0, 'bookings': 0, 'charges': 0, 'errors': 0}

    try:
        for (cstart, cend) in daterange_chunks(start, end, args.chunk_days):
            totals['chunks'] += 1
            key = (cstart.isoformat(), cend.isoformat())
            if key in completed:
                totals['skipped'] += 1
                continue
            error_text: Optional[str] = None
            upserted = 0
            charges_written = 0
            try:
                bookings = scrape_chunk(cstart, cend)
                if args.dry_run:
                    logger.info('   [dry-run] would upsert %d bookings', len(bookings))
                    for b in bookings[:3]:
                        logger.info('     • %s %s booked=%s released=%s charges=%d',
                                    b.get('booking_no'), b.get('name'),
                                    b.get('booking_date'), b.get('released_date'),
                                    len(b.get('charges') or []))
                    totals['bookings'] += len(bookings)
                    continue

                if bookings:
                    prev_photos = hourly.PCSO_SYNC_PHOTOS
                    prev_charges = hourly.PCSO_SYNC_CHARGES
                    hourly.PCSO_SYNC_PHOTOS = not args.no_photos
                    hourly.PCSO_SYNC_CHARGES = not args.skip_charges
                    try:
                        result = hourly.upsert_bookings(bookings, supabase)
                    finally:
                        hourly.PCSO_SYNC_PHOTOS = prev_photos
                        hourly.PCSO_SYNC_CHARGES = prev_charges
                    upserted = result.get('inserted', 0)
                    charges_written = result.get('charges_synced', 0) or 0
                    totals['bookings'] += upserted
                    totals['charges'] += charges_written
            except Exception as exc:
                error_text = f'{type(exc).__name__}: {exc}'
                totals['errors'] += 1
                logger.exception('❌ chunk %s → %s failed: %s', cstart, cend, exc)

            if not args.dry_run:
                log_scrape_run(
                    supabase, cstart, cend,
                    ok=(error_text is None),
                    bookings_upserted=upserted,
                    charges_written=charges_written,
                    error_text=error_text,
                )

            time.sleep(INTER_CHUNK_PAUSE_SEC)

        logger.info('=' * 60)
        logger.info('📊 DONE — %d chunks (%d skipped via resume), %d bookings, %d charges, %d errors',
                    totals['chunks'], totals['skipped'], totals['bookings'],
                    totals['charges'], totals['errors'])
        logger.info('=' * 60)
    finally:
        if cron_was_toggled:
            enable_cron()


if __name__ == '__main__':
    (script_dir / 'logs').mkdir(exist_ok=True)
    main()
