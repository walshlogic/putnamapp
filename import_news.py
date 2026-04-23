#!/usr/bin/env python3
"""
Import local-first news for the Putnam+Life app.

Strategy: Google News RSS with tiered queries.
  Tier 1: Putnam County FL (hyper-local)
  Tier 2: Northeast Florida
  Tier 3: Central Florida
  Tier 4: State of Florida
  Tier 5: US national headlines

Deduplicates across tiers (higher tier wins), filters to US-only sources,
lazy-fetches og:image for new articles, prunes each tier to the N most
recent articles.

Environment:
  SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY — required
  NEWS_KEEP_PER_TIER — optional, default 200
  NEWS_IMAGE_TIMEOUT_SEC — optional, default 6
  NEWS_IMAGE_FETCH_BUDGET_SEC — optional, default 300 (cap total image time)

Usage:
  python3 import_news.py               # normal run
  python3 import_news.py --dry-run     # parse + report, no DB writes
  python3 import_news.py --no-images   # skip og:image fetch
"""
import argparse
import hashlib
import html
import logging
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple
from urllib.parse import quote, urlparse

import feedparser
import requests
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from supabase import Client, create_client

script_dir = Path(__file__).parent
env_path = script_dir / 'assets' / '.env'
if env_path.exists():
    load_dotenv(env_path)
else:
    load_dotenv()

(script_dir / 'logs').mkdir(exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(script_dir / 'logs' / 'news_import.log'),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger('news')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
KEEP_PER_TIER = int(os.getenv('NEWS_KEEP_PER_TIER', '200'))
IMAGE_TIMEOUT_SEC = int(os.getenv('NEWS_IMAGE_TIMEOUT_SEC', '6'))
IMAGE_BUDGET_SEC = int(os.getenv('NEWS_IMAGE_FETCH_BUDGET_SEC', '300'))

USER_AGENT = (
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
)

SOURCE_ID = 'google_news_rss'
SOURCE_NAME = 'Google News RSS'

# tier_number → (category_label, display_name, full Google News RSS URL)
# Tiers 1-4 are search queries for regional specificity.
# Tier 5 uses the NATION topic endpoint (US domestic news only; excludes WORLD/international).
_NEWS_BASE = 'https://news.google.com/rss'
_QP = '&hl=en-US&gl=US&ceid=US:en'

TIERS: List[Tuple[int, str, str, str]] = [
    (1, 'local_putnam',    'Putnam County',
     f'{_NEWS_BASE}/search?q={quote("\"Putnam County\" Florida OR Palatka OR Interlachen OR Welaka OR \"Crescent City\"")}{_QP}'),
    (2, 'ne_florida',      'Northeast Florida',
     f'{_NEWS_BASE}/search?q={quote("\"Northeast Florida\" OR Jacksonville OR \"St. Johns County\" OR \"Clay County\" OR \"Flagler County\" OR \"Duval County\"")}{_QP}'),
    (3, 'central_florida', 'Central Florida',
     f'{_NEWS_BASE}/search?q={quote("\"Central Florida\" OR Orlando OR \"Marion County Florida\" OR \"Lake County Florida\" OR \"Volusia County\"")}{_QP}'),
    (4, 'state_florida',   'State of Florida',
     f'{_NEWS_BASE}/search?q={quote("Florida state government OR \"Florida Legislature\" OR \"Ron DeSantis\"")}{_QP}'),
    (5, 'us_headlines',    'US National',
     f'{_NEWS_BASE}/headlines/section/topic/NATION?{_QP.lstrip("&")}'),
]

# Drop articles whose source domain ends in one of these TLDs (non-US feeds).
_NON_US_TLD_BLOCK = {
    '.ca', '.uk', '.au', '.nz', '.in', '.ru', '.cn', '.jp', '.kr', '.de',
    '.fr', '.it', '.es', '.mx', '.br', '.ar', '.cl', '.ng', '.za', '.ie',
}

# Foreign outlets that use .com domains — blocklist by name (case-insensitive substring).
_NON_US_OUTLETS = {
    'the guardian', 'guardian',
    'bbc', 'bbc news',
    'al jazeera', 'aljazeera',
    'financial times', 'ft.com',
    'france 24', 'france24',
    'deutsche welle', 'dw news',
    'rt news', 'russia today', 'sputnik',
    'south china morning post', 'scmp',
    'the globe and mail', 'globe and mail',
    'cbc news', 'ctv news',
    'the times of india', 'times of india',
    'xinhua', "people's daily",
    'daily mail', 'the sun',
    'the telegraph', 'daily telegraph',
    'reuters uk',
    'dw.com',
}


def external_id_from_url(url: str) -> str:
    """Stable hash of a URL for dedup + external_id column."""
    return hashlib.sha1(url.encode('utf-8')).hexdigest()[:32]


def normalize_title(title: str) -> str:
    """Lowercased, punctuation-stripped title for similarity dedup."""
    t = re.sub(r'\s+-\s+[^-]+$', '', title or '')
    t = re.sub(r'[^\w\s]', ' ', t.lower())
    t = re.sub(r'\s+', ' ', t).strip()
    return t


def is_us_source(link: str, outlet: str = '') -> bool:
    try:
        host = urlparse(link).hostname or ''
    except Exception:
        return False
    host = host.lower()
    for tld in _NON_US_TLD_BLOCK:
        if host.endswith(tld):
            return False
    outlet_lc = (outlet or '').lower().strip()
    if outlet_lc:
        for bad in _NON_US_OUTLETS:
            if bad in outlet_lc:
                return False
    return True


def parse_feed(url: str, tier: int, category: str) -> List[Dict[str, Any]]:
    try:
        resp = requests.get(url, headers={'User-Agent': USER_AGENT}, timeout=30)
        resp.raise_for_status()
    except Exception as exc:
        logger.warning('feed fetch failed tier=%d: %s', tier, exc)
        return []
    d = feedparser.parse(resp.content)
    items: List[Dict[str, Any]] = []
    for entry in d.entries:
        link = entry.get('link', '').strip()
        if not link:
            continue
        title_raw = html.unescape(entry.get('title', '') or '').strip()
        if not title_raw:
            continue
        m = re.search(r'^(.*)\s-\s([^-]+)$', title_raw)
        if m:
            title_clean, outlet = m.group(1).strip(), m.group(2).strip()
        else:
            title_clean, outlet = title_raw, (entry.get('source', {}).get('title') or '')
        src = entry.get('source', {}).get('href') or entry.get('source', {}).get('url') or ''
        if not is_us_source(src or link, outlet):
            continue
        desc_html = entry.get('summary', '') or ''
        desc_text = BeautifulSoup(desc_html, 'html.parser').get_text(' ', strip=True)
        published = None
        if getattr(entry, 'published_parsed', None):
            try:
                published = datetime(*entry.published_parsed[:6], tzinfo=timezone.utc).isoformat()
            except Exception:
                pass
        items.append({
            'title': title_clean,
            'description': desc_text[:500] if desc_text else None,
            'url': link,
            'source_url': src,
            'author': outlet or None,
            'published_at': published,
            'category': category,
            'tier': tier,
            'norm_title': normalize_title(title_clean),
            'external_id': external_id_from_url(link),
            'language': 'en',
            'country': 'us',
        })
    logger.info('tier=%d fetched %d items', tier, len(items))
    return items


def dedup_articles(by_tier: Dict[int, List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
    """Keep one article per (normalized_title | external_id). Higher tier wins."""
    seen_urls: Set[str] = set()
    seen_titles: Set[str] = set()
    out: List[Dict[str, Any]] = []
    for tier in sorted(by_tier.keys()):
        for a in by_tier[tier]:
            if a['external_id'] in seen_urls:
                continue
            if a['norm_title'] in seen_titles:
                continue
            seen_urls.add(a['external_id'])
            seen_titles.add(a['norm_title'])
            out.append(a)
    return out


def fetch_og_image(url: str, timeout: int = IMAGE_TIMEOUT_SEC) -> Optional[str]:
    try:
        resp = requests.get(
            url, headers={'User-Agent': USER_AGENT}, timeout=timeout,
            allow_redirects=True,
        )
        if resp.status_code != 200 or 'html' not in resp.headers.get('content-type', ''):
            return None
        soup = BeautifulSoup(resp.content, 'html.parser')
        for prop in ('og:image', 'twitter:image', 'og:image:secure_url'):
            tag = soup.find('meta', attrs={'property': prop}) or soup.find('meta', attrs={'name': prop})
            if tag and tag.get('content'):
                return tag['content'].strip()
    except Exception:
        return None
    return None


def upsert_source(sb: Client) -> str:
    """Ensure the single catch-all source row exists; return its UUID id."""
    existing = sb.table('news_sources').select('id').eq('source_id', SOURCE_ID).limit(1).execute().data
    if existing:
        return existing[0]['id']
    row = sb.table('news_sources').insert({
        'source_id': SOURCE_ID,
        'name': SOURCE_NAME,
        'description': 'Aggregated tiered queries against Google News RSS (local→regional→state→national).',
        'url': 'https://news.google.com/',
        'category': 'aggregator',
        'language': 'en',
        'country': 'us',
    }).execute().data
    return row[0]['id']


def get_existing_external_ids(sb: Client) -> Set[str]:
    ids: Set[str] = set()
    page = 0
    size = 1000
    while True:
        data = sb.table('news_articles').select('external_id').range(page * size, page * size + size - 1).execute().data
        if not data:
            break
        for r in data:
            if r.get('external_id'):
                ids.add(r['external_id'])
        if len(data) < size:
            break
        page += 1
    return ids


def prune_per_tier(sb: Client, category: str, keep: int = KEEP_PER_TIER) -> int:
    rows = (
        sb.table('news_articles')
        .select('id, published_at')
        .eq('category', category)
        .order('published_at', desc=True)
        .limit(10000)
        .execute().data
    )
    if len(rows) <= keep:
        return 0
    to_delete = [r['id'] for r in rows[keep:]]
    deleted = 0
    for i in range(0, len(to_delete), 100):
        chunk = to_delete[i:i + 100]
        sb.table('news_articles').delete().in_('id', chunk).execute()
        deleted += len(chunk)
    return deleted


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dry-run', action='store_true', help='Parse + dedup + log summary, no DB writes')
    ap.add_argument('--no-images', action='store_true', help='Skip og:image fetch entirely')
    args = ap.parse_args()

    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        logger.error('missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in env')
        sys.exit(1)

    logger.info('=' * 60)
    logger.info('📰 News import (dry_run=%s, no_images=%s, keep_per_tier=%d)',
                args.dry_run, args.no_images, KEEP_PER_TIER)
    logger.info('=' * 60)

    by_tier: Dict[int, List[Dict[str, Any]]] = {}
    for tier, category, display, url in TIERS:
        logger.info('▶ Tier %d — %s', tier, display)
        by_tier[tier] = parse_feed(url, tier, category)

    raw_total = sum(len(v) for v in by_tier.values())
    deduped = dedup_articles(by_tier)
    logger.info('raw=%d deduped=%d (dropped=%d)', raw_total, len(deduped), raw_total - len(deduped))

    by_tier_dedup: Dict[int, int] = {}
    for a in deduped:
        by_tier_dedup[a['tier']] = by_tier_dedup.get(a['tier'], 0) + 1
    for t, _, display, _ in TIERS:
        logger.info('  tier %d (%s): %d articles kept', t, display, by_tier_dedup.get(t, 0))

    if args.dry_run:
        logger.info('--- SAMPLE (first 3 of each tier) ---')
        for t, _, display, _ in TIERS:
            logger.info('• tier %d (%s):', t, display)
            for a in [x for x in deduped if x['tier'] == t][:3]:
                logger.info('    %s — %s', a.get('author') or '?', a['title'])
        logger.info('dry-run: no DB writes')
        return

    sb = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    logger.info('✅ Supabase connected')

    src_uuid = upsert_source(sb)
    existing_ids = get_existing_external_ids(sb)
    logger.info('📦 existing articles in DB: %d', len(existing_ids))

    new_articles = [a for a in deduped if a['external_id'] not in existing_ids]
    logger.info('🆕 new articles to ingest: %d', len(new_articles))

    if not args.no_images and new_articles:
        logger.info('🖼  fetching og:image for up to %d new articles (budget %ds)...',
                    len(new_articles), IMAGE_BUDGET_SEC)
        deadline = time.time() + IMAGE_BUDGET_SEC
        got = 0
        for a in new_articles:
            if time.time() > deadline:
                logger.info('   image budget exhausted')
                break
            img = fetch_og_image(a['url'])
            if img:
                a['image_url'] = img
                got += 1
        logger.info('🖼  got %d images', got)

    rows = []
    for a in new_articles:
        rows.append({
            'source_id': src_uuid,
            'external_id': a['external_id'],
            'title': a['title'],
            'description': a.get('description'),
            'url': a['url'],
            'image_url': a.get('image_url'),
            'author': a.get('author'),
            'published_at': a.get('published_at') or datetime.now(timezone.utc).isoformat(),
            'category': a['category'],
            'language': 'en',
            'country': 'us',
        })

    inserted = 0
    batch = 100
    for i in range(0, len(rows), batch):
        chunk = rows[i:i + batch]
        sb.table('news_articles').upsert(chunk, on_conflict='external_id').execute()
        inserted += len(chunk)
    logger.info('✅ upserted %d articles', inserted)

    for _, category, display, _ in TIERS:
        deleted = prune_per_tier(sb, category, KEEP_PER_TIER)
        if deleted:
            logger.info('🧹 pruned %s: removed %d older articles (kept top %d)', display, deleted, KEEP_PER_TIER)

    logger.info('=' * 60)
    logger.info('📰 DONE')
    logger.info('=' * 60)


if __name__ == '__main__':
    main()
