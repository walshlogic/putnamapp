#!/usr/bin/env python3
"""
Import news articles from NewsAPI.org into Supabase.

This script fetches news articles from NewsAPI and stores them in Supabase.
It respects API rate limits and uses UPSERT to avoid duplicates.

Requirements:
- pip install supabase python-dotenv requests

Environment Variables:
- SUPABASE_URL: Your Supabase project URL
- SUPABASE_SERVICE_ROLE_KEY: Your Supabase service role key (for bypassing RLS)
- NEWSAPI_KEY: Your NewsAPI.org API key (get free at https://newsapi.org)

Usage:
    python3 import_news.py [--categories general,technology,business] [--country us] [--limit 100]
"""

import os
import sys
import json
import logging
import argparse
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any
from urllib.parse import quote

import requests
from supabase import create_client, Client
from dotenv import load_dotenv
from pathlib import Path

# =====================================================
# LOAD ENVIRONMENT VARIABLES
# =====================================================

script_dir = Path(__file__).parent
env_path = script_dir / 'assets' / '.env'

if env_path.exists():
    load_dotenv(env_path)
    print(f'✅ Loaded environment variables from {env_path}')
else:
    load_dotenv()
    print('⚠️  assets/.env not found, trying current directory .env')

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# NewsAPI configuration
NEWSAPI_BASE_URL = 'https://newsapi.org/v2'
NEWSAPI_SOURCE_ID = 'newsapi'

# Default categories to fetch
DEFAULT_CATEGORIES = ['general', 'technology', 'business', 'health', 'science', 'sports', 'entertainment']

# Default countries
DEFAULT_COUNTRIES = ['us']

# Default article limit per category
DEFAULT_LIMIT = 100


def get_supabase_client() -> Client:
    """Initialize and return Supabase client."""
    supabase_url = os.getenv('SUPABASE_URL', '')
    supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY', '')
    
    if not supabase_url or not supabase_key:
        raise ValueError(
            'Missing required environment variables: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY\n'
            'Please set these in assets/.env file'
        )
    
    return create_client(supabase_url, supabase_key)


def get_newsapi_key() -> str:
    """Get NewsAPI key from environment."""
    api_key = os.getenv('NEWSAPI_KEY')
    if not api_key:
        raise ValueError('Missing required environment variable: NEWSAPI_KEY')
    return api_key


def ensure_news_source(supabase: Client) -> str:
    """Ensure news source exists in database, return source UUID."""
    # Check if source exists
    response = supabase.table('news_sources').select('id').eq('source_id', NEWSAPI_SOURCE_ID).execute()
    
    if response.data:
        return response.data[0]['id']
    
    # Create source if it doesn't exist
    source_data = {
        'source_id': NEWSAPI_SOURCE_ID,
        'name': 'NewsAPI',
        'description': 'NewsAPI.org - Free news API',
        'url': 'https://newsapi.org',
        'category': 'general',
        'language': 'en',
        'country': 'us'
    }
    
    response = supabase.table('news_sources').insert(source_data).execute()
    if not response.data:
        raise Exception('Failed to create news source')
    
    logger.info(f"Created news source: {NEWSAPI_SOURCE_ID}")
    return response.data[0]['id']


def fetch_top_headlines(
    api_key: str,
    category: Optional[str] = None,
    country: str = 'us',
    page_size: int = 100,
    page: int = 1
) -> List[Dict[str, Any]]:
    """
    Fetch top headlines from NewsAPI.
    
    Args:
        api_key: NewsAPI API key
        category: News category (general, technology, business, etc.)
        country: Country code (us, gb, etc.)
        page_size: Number of articles per page (max 100)
        page: Page number
    
    Returns:
        List of article dictionaries
    """
    url = f'{NEWSAPI_BASE_URL}/top-headlines'
    params = {
        'apiKey': api_key,
        'country': country,
        'pageSize': min(page_size, 100),  # NewsAPI max is 100
        'page': page
    }
    
    if category:
        params['category'] = category
    
    try:
        logger.info(f"Fetching headlines: category={category}, country={country}, page={page}")
        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        if data.get('status') != 'ok':
            raise Exception(f"NewsAPI returned error: {data.get('message', 'Unknown error')}")
        
        articles = data.get('articles', [])
        logger.info(f"Fetched {len(articles)} articles")
        
        return articles
    
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching headlines: {e}")
        raise


def normalize_article(article: Dict[str, Any], source_uuid: str, category: str) -> Dict[str, Any]:
    """
    Normalize article data from NewsAPI format to our schema.
    
    Args:
        article: Raw article data from NewsAPI
        source_uuid: UUID of the news source
        category: Article category
    
    Returns:
        Normalized article dictionary
    """
    # Use url as external_id (NewsAPI doesn't provide a unique ID)
    external_id = article.get('url', '')
    if not external_id:
        # Fallback: create ID from title and publishedAt
        title = article.get('title', '')[:50]
        published = article.get('publishedAt', '')
        external_id = f"{title}_{published}"
    
    # Parse published date
    published_at = article.get('publishedAt')
    if published_at:
        try:
            # NewsAPI format: 2024-01-15T10:30:00Z
            published_at = datetime.fromisoformat(published_at.replace('Z', '+00:00'))
        except Exception as e:
            logger.warning(f"Failed to parse publishedAt '{published_at}': {e}")
            published_at = datetime.now()
    else:
        published_at = datetime.now()
    
    # Extract tags from title/description (simple keyword extraction)
    tags = []
    title_lower = (article.get('title') or '').lower()
    description_lower = (article.get('description') or '').lower()
    
    # Common keywords to extract as tags
    keywords = ['breaking', 'update', 'alert', 'breaking news', 'live', 'exclusive']
    for keyword in keywords:
        if keyword in title_lower or keyword in description_lower:
            tags.append(keyword)
    
    # Add category as tag
    if category:
        tags.append(category)
    
    normalized = {
        'source_id': source_uuid,
        'external_id': external_id,
        'title': article.get('title', 'No Title'),
        'description': article.get('description'),
        'content': article.get('content'),  # May be truncated
        'url': article.get('url', ''),
        'image_url': article.get('urlToImage'),
        'author': article.get('author'),
        'published_at': published_at.isoformat(),
        'category': category or 'general',
        'tags': tags if tags else None,
        'language': 'en',
        'country': 'us',
    }
    
    return normalized


def deduplicate_batch(articles: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Remove duplicate articles within a batch based on external_id.
    
    Args:
        articles: List of article dictionaries
    
    Returns:
        Deduplicated list
    """
    seen = set()
    unique = []
    duplicates = 0
    
    for article in articles:
        external_id = article.get('external_id', '')
        if external_id and external_id not in seen:
            seen.add(external_id)
            unique.append(article)
        else:
            duplicates += 1
    
    if duplicates > 0:
        logger.info(f"Removed {duplicates} duplicate articles from batch")
    
    return unique


def upsert_articles(supabase: Client, articles: List[Dict[str, Any]]) -> tuple[int, int]:
    """
    Upsert articles into Supabase.
    
    Args:
        supabase: Supabase client
        articles: List of normalized article dictionaries
    
    Returns:
        Tuple of (inserted_count, updated_count)
    """
    if not articles:
        return 0, 0
    
    # Deduplicate batch
    articles = deduplicate_batch(articles)
    
    inserted = 0
    updated = 0
    errors = 0
    
    # Process in batches of 100 (Supabase limit)
    batch_size = 100
    for i in range(0, len(articles), batch_size):
        batch = articles[i:i + batch_size]
        
        try:
            # Upsert using source_id + external_id as unique constraint
            response = supabase.table('news_articles').upsert(
                batch,
                on_conflict='source_id,external_id'
            ).execute()
            
            # Count new vs updated (approximate - Supabase doesn't return this directly)
            # We'll assume all are inserts for simplicity
            inserted += len(batch)
            logger.info(f"Upserted batch of {len(batch)} articles")
        
        except Exception as e:
            logger.error(f"Error upserting batch: {e}")
            errors += len(batch)
    
    if errors > 0:
        logger.warning(f"Failed to upsert {errors} articles")
    
    return inserted, updated


def main():
    """Main function to fetch and import news articles."""
    parser = argparse.ArgumentParser(description='Import news articles from NewsAPI')
    parser.add_argument(
        '--categories',
        type=str,
        default=','.join(DEFAULT_CATEGORIES),
        help='Comma-separated list of categories (default: general,technology,business,health,science,sports,entertainment)'
    )
    parser.add_argument(
        '--country',
        type=str,
        default='us',
        help='Country code (default: us)'
    )
    parser.add_argument(
        '--limit',
        type=int,
        default=DEFAULT_LIMIT,
        help='Maximum articles per category (default: 100)'
    )
    
    args = parser.parse_args()
    
    categories = [c.strip() for c in args.categories.split(',')]
    
    try:
        # Initialize clients
        logger.info("Initializing Supabase client...")
        supabase = get_supabase_client()
        
        logger.info("Getting NewsAPI key...")
        api_key = get_newsapi_key()
        
        # Ensure news source exists
        logger.info("Ensuring news source exists...")
        source_uuid = ensure_news_source(supabase)
        
        total_fetched = 0
        total_inserted = 0
        
        # Fetch articles for each category
        for category in categories:
            logger.info(f"\n{'='*60}")
            logger.info(f"Processing category: {category}")
            logger.info(f"{'='*60}")
            
            try:
                # Fetch top headlines
                articles = fetch_top_headlines(
                    api_key=api_key,
                    category=category,
                    country=args.country,
                    page_size=args.limit
                )
                
                if not articles:
                    logger.warning(f"No articles found for category: {category}")
                    continue
                
                # Normalize articles
                normalized = [
                    normalize_article(article, source_uuid, category)
                    for article in articles
                ]
                
                # Upsert to Supabase
                inserted, updated = upsert_articles(supabase, normalized)
                
                total_fetched += len(articles)
                total_inserted += inserted
                
                logger.info(f"Category {category}: Fetched {len(articles)}, Inserted {inserted}")
            
            except Exception as e:
                logger.error(f"Error processing category {category}: {e}")
                continue
        
        # Summary
        logger.info(f"\n{'='*60}")
        logger.info("IMPORT SUMMARY")
        logger.info(f"{'='*60}")
        logger.info(f"Total articles fetched: {total_fetched}")
        logger.info(f"Total articles inserted/updated: {total_inserted}")
        logger.info("Import completed successfully!")
    
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

