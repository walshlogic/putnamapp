#!/usr/bin/env python3
"""
Import PCSO jail log bookings from PCSO website into Supabase.

This script scrapes/fetches booking data from PCSO website and stores it in Supabase.
It uses UPSERT to avoid duplicates and update existing records.

Requirements:
- pip install supabase python-dotenv requests beautifulsoup4 (if scraping HTML)

Environment Variables:
- SUPABASE_URL: Your Supabase project URL
- SUPABASE_SERVICE_ROLE_KEY: Your Supabase service role key (for bypassing RLS)
- PCSO_JAIL_LOG_URL: PCSO jail log website URL (optional, can be hardcoded)
- PCSO_BOOKINGS_TABLE: Base table to upsert bookings into (not a view)
- PCSO_BOOKINGS_HAS_CHARGES: Whether the base table has a JSONB "charges" column
- PCSO_SKIP_INCOMPLETE: Skip bookings missing required fields (default: true)
- PCSO_CHARGES_TABLE: Charges table name (default: charges)
- PCSO_SYNC_CHARGES: Sync charges to charges table (default: true)
- PCSO_PHOTO_BASE_URL: Source photo URL base (default: PCSO site)
- PCSO_PHOTOS_BUCKET: Supabase storage bucket name (default: pcso-booking-photos)
- PCSO_SYNC_PHOTOS: Sync photos into storage (default: true)

Usage:
    python3 import_pcso_bookings.py
"""

import os
import sys
import json
import logging
import re
from datetime import datetime
from typing import List, Dict, Optional, Any
from pathlib import Path
from zoneinfo import ZoneInfo

import requests
from supabase import create_client, Client
from dotenv import load_dotenv

# Try to import dateutil for date parsing (optional)
try:
    from dateutil import parser as date_parser
    HAS_DATEUTIL = True
except ImportError:
    HAS_DATEUTIL = False

# Try to import BeautifulSoup (required for HTML parsing)
try:
    from bs4 import BeautifulSoup
    HAS_BEAUTIFULSOUP = True
except ImportError:
    HAS_BEAUTIFULSOUP = False

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
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(script_dir / 'logs' / 'pcso_bookings_import.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

# =====================================================
# CONFIGURATION
# =====================================================

# PCSO Jail Log URL (default to the known URL if not in env)
PCSO_JAIL_LOG_URL = os.getenv('PCSO_JAIL_LOG_URL', 'https://smartweb.pcso.us/smartwebclient/jail.aspx')
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
PCSO_BOOKINGS_TABLE = os.getenv('PCSO_BOOKINGS_TABLE', 'bookings')
PCSO_BOOKINGS_HAS_CHARGES = os.getenv('PCSO_BOOKINGS_HAS_CHARGES', 'false').lower() in (
    '1',
    'true',
    'yes',
)
PCSO_SKIP_INCOMPLETE = os.getenv('PCSO_SKIP_INCOMPLETE', 'true').lower() in (
    '1',
    'true',
    'yes',
)
PCSO_CHARGES_TABLE = os.getenv('PCSO_CHARGES_TABLE', 'charges')
PCSO_SYNC_CHARGES = os.getenv('PCSO_SYNC_CHARGES', 'true').lower() in (
    '1',
    'true',
    'yes',
)
PCSO_PHOTO_BASE_URL = os.getenv(
    'PCSO_PHOTO_BASE_URL',
    'https://smartweb.pcso.us/smartwebclient/ViewImage.aspx?bookno=',
)
PCSO_PHOTOS_BUCKET = os.getenv('PCSO_PHOTOS_BUCKET', 'pcso-booking-photos')
PCSO_SYNC_PHOTOS = os.getenv('PCSO_SYNC_PHOTOS', 'true').lower() in (
    '1',
    'true',
    'yes',
)

# Batch size for database inserts
BATCH_SIZE = 100

# =====================================================
# SUPABASE CLIENT
# =====================================================

def get_supabase_client() -> Client:
    """Get Supabase client with service role key"""
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError(
            'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in environment variables'
        )
    
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# =====================================================
# DATA FETCHING (TO BE IMPLEMENTED)
# =====================================================

def fetch_pcso_bookings() -> List[Dict[str, Any]]:
    """
    Fetch booking data from PCSO website by scraping HTML.
    
    Scrapes https://smartweb.pcso.us/smartwebclient/jail.aspx
    Parses HTML tables to extract booking information.
    
    Returns:
        List of booking dictionaries with fields matching Supabase schema
    """
    logger.info('📥 Fetching PCSO jail log data...')
    
    if not PCSO_JAIL_LOG_URL:
        logger.error('❌ PCSO_JAIL_LOG_URL not configured')
        raise ValueError('PCSO_JAIL_LOG_URL must be set in environment variables or use default URL')
    
    if not HAS_BEAUTIFULSOUP:
        logger.error('❌ BeautifulSoup4 not installed. Install with: pip install beautifulsoup4')
        raise ImportError('BeautifulSoup4 is required for HTML parsing')
    
    from bs4 import BeautifulSoup
    
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
        }
        logger.info(f'🌐 Fetching from: {PCSO_JAIL_LOG_URL}')
        response = requests.get(PCSO_JAIL_LOG_URL, timeout=60, headers=headers)
        response.raise_for_status()
        
        logger.info(f'✅ Received HTML response (size: {len(response.text)} bytes)')
        
        # Parse HTML
        soup = BeautifulSoup(response.text, 'html.parser')
        bookings: List[Dict[str, Any]] = []
        
        # Parse booking info tables directly to avoid mismatched names/photos
        info_tables = [
            table
            for table in soup.find_all('table')
            if not (table.get('class') and 'JailViewCharges' in table.get('class'))
            and table.find(string=re.compile(r'Booking No:', re.IGNORECASE))
        ]
        logger.info(f'📦 Found {len(info_tables)} booking info tables')
        for table in info_tables:
            try:
                booking_data = _parse_booking_info_table(table)
                if booking_data:
                    bookings.append(booking_data)
            except Exception as e:
                logger.warning(f'⚠️  Error parsing booking table: {e}')
                continue
        
        if not bookings:
            # Fallback: parse by booking numbers if tables weren't detected
            page_text = soup.get_text(separator='\n')
            booking_pattern = r'PCSO\d{2}JBN\d{6}'
            booking_numbers = re.findall(booking_pattern, page_text)
            unique_booking_numbers = sorted(list(set(booking_numbers)), reverse=True)
            
            logger.info(f'📊 Found {len(unique_booking_numbers)} unique booking numbers')
            
            if not unique_booking_numbers:
                logger.warning('⚠️  No booking numbers found in HTML. Page structure may have changed.')
                logger.warning(f'   First 500 chars of HTML: {response.text[:500]}')
                return []
            
            for booking_no in unique_booking_numbers:
                try:
                    booking_data = _parse_booking_from_html(soup, booking_no)
                    if booking_data:
                        bookings.append(booking_data)
                except Exception as e:
                    logger.warning(f'⚠️  Error parsing booking {booking_no}: {e}')
                    continue
        
        logger.info(f'✅ Successfully parsed {len(bookings)} bookings')
        return bookings
        
    except requests.exceptions.RequestException as e:
        logger.error(f'❌ HTTP error fetching PCSO data: {e}')
        raise
    except Exception as e:
        logger.error(f'❌ Error fetching PCSO data: {e}')
        import traceback
        traceback.print_exc()
        raise


def _parse_booking_block(block_text: str) -> Optional[Dict[str, Any]]:
    booking_no_match = re.search(r'PCSO\d{2}JBN\d{6}', block_text)
    if not booking_no_match:
        return None
    booking_no = booking_no_match.group(0)
    return _parse_booking_from_text(block_text, booking_no)


def _to_utc_iso_safe(date_str: str) -> Optional[str]:
    if not date_str:
        return None
    candidate = date_str.strip()
    formats = [
        '%m/%d/%Y %I:%M %p',
        '%m/%d/%Y %H:%M',
        '%m/%d/%Y',
    ]
    for fmt in formats:
        try:
            local_dt = datetime.strptime(candidate, fmt).replace(
                tzinfo=ZoneInfo('America/New_York'),
            )
            return local_dt.astimezone(ZoneInfo('UTC')).isoformat()
        except Exception:
            continue
    return None


def _parse_booking_info_table(table) -> Optional[Dict[str, Any]]:
    header = table.find('td', class_='SearchHeader')
    if not header:
        return None
    header_text = ' '.join(header.stripped_strings)
    if not header_text:
        return None
    
    def _extract_header_name(text: str) -> Dict[str, str]:
        match = re.search(
            r'^(.*?)\s+\(([BW])/?\s*(MALE|FEMALE|M|F)\s*\)',
            text,
            re.IGNORECASE,
        )
        if not match:
            return {'name': text.strip(), 'race': '', 'gender': ''}
        name = match.group(1).strip()
        race = match.group(2).upper()
        gender_raw = match.group(3).upper()
        gender = 'Male' if gender_raw.startswith('M') else 'Female'
        return {'name': name, 'race': race, 'gender': gender}
    
    header_info = _extract_header_name(header_text)
    
    def _find_value(label: str) -> str:
        for td in table.find_all('td', class_='InmateInfoGridTd'):
            label_text = td.get_text(' ', strip=True)
            if label_text.startswith(label):
                value_td = td.find_next_sibling('td')
                if value_td:
                    return value_td.get_text(' ', strip=True)
        return ''
    
    booking_no = _find_value('Booking No')
    if not booking_no:
        # Try to find a booking number anywhere in the table
        booking_match = re.search(r'PCSO\d{2}JBN\d{6}', table.get_text(' ', strip=True))
        if booking_match:
            booking_no = booking_match.group(0)
        else:
            return None
    
    booking_data = {
        'booking_no': booking_no,
        'mni_no': _find_value('MniNo'),
        'name': header_info['name'],
        'status': _find_value('Status'),
        'booking_date': None,
        'age_on_booking_date': None,
        'bond_amount': _find_value('Bond Amount'),
        'address_given': _find_value('Address Given'),
        'holds_text': None,
        'race': header_info['race'],
        'gender': header_info['gender'],
        'released_date': None,
        'photo_url': f'{PCSO_PHOTO_BASE_URL}{booking_no}',
        'charges': [],
        'raw_card_text': table.get_text('\n', strip=True),
    }
    
    # Booking date
    booking_date_str = _find_value('Booking Date')
    if booking_date_str:
        booking_data['booking_date'] = _to_utc_iso_safe(booking_date_str)
    
    # Age
    age_str = _find_value('Age On Booking Date')
    if age_str.isdigit():
        booking_data['age_on_booking_date'] = int(age_str)
    
    # Holds - look for a nearby holds table before the next booking info table
    holds_texts: List[str] = []
    next_info_table = table.find_next(
        lambda tag: tag.name == 'table'
        and tag is not table
        and tag.find(string=re.compile(r'Booking No:', re.IGNORECASE)),
    )
    for next_table in table.find_all_next('table'):
        if next_table == next_info_table:
            break
        if next_table.get('id') == 'JailViewHolds':
            hold_cells = next_table.find_all('td')
            for cell in hold_cells:
                cell_text = cell.get_text(' ', strip=True)
                if cell_text and cell_text.upper() != 'HOLDS':
                    holds_texts.append(cell_text)
            break
    if holds_texts:
        booking_data['holds_text'] = ' '.join(holds_texts)

    # Charges - look for the CHARGES table (not HOLDS) before the next booking info table
    charges_table = None
    for next_table in table.find_all_next('table'):
        if next_table == next_info_table:
            break
        table_id = next_table.get('id', '')
        table_classes = next_table.get('class') or []
        if table_id == 'JailViewHolds':
            continue
        if table_id == 'JailViewCharges' or 'JailViewCharges' in table_classes:
            charges_table = next_table
            break
    if charges_table:
        booking_data['charges'] = _extract_charges_from_table(charges_table)
    
    return booking_data


def _extract_charges_from_table(table) -> List[Dict[str, Any]]:
    charges: List[Dict[str, Any]] = []
    rows = table.find_all('tr')
    for row in rows:
        cells = [cell.get_text(' ', strip=True) for cell in row.find_all('td')]
        if not cells:
            continue
        if any(cell.upper() == 'STATUTE' for cell in cells):
            continue
        # Expected: [expander, statute, case number, charge, degree, level, bond]
        if len(cells) >= 7:
            statute = cells[1].strip()
            case_number = cells[2].strip()
            charge = cells[3].strip()
            degree = cells[4].strip()
            level = cells[5].strip()
            bond = cells[6].strip()
        elif len(cells) >= 6:
            statute = cells[0].strip()
            case_number = cells[1].strip()
            charge = cells[2].strip()
            degree = cells[3].strip()
            level = cells[4].strip()
            bond = cells[5].strip()
        else:
            continue
        if not charge or charge.upper() == 'CHARGE':
            continue
        charges.append(
            {
                'statute': statute,
                'case_number': case_number,
                'charge': charge,
                'degree': degree,
                'level': level,
                'bond': bond,
            }
        )
    return charges


def _parse_booking_from_html(soup: BeautifulSoup, booking_no: str) -> Optional[Dict[str, Any]]:
    """
    Parse a single booking from HTML soup using the booking number.
    
    Args:
        soup: BeautifulSoup object of the page
        booking_no: Booking number to find and parse
        
    Returns:
        Dictionary with booking data or None if not found
    """
    from datetime import datetime
    
    # Find the element containing this booking number
    # Look for text containing the booking number
    booking_elements = soup.find_all(string=re.compile(re.escape(booking_no)))
    
    if not booking_elements:
        return None
    
    def _has_booking_fields(text: str) -> bool:
        return (
            'Booking Date' in text
            or 'Booking Dt' in text
            or 'Status:' in text
            or 'MniNo' in text
        )
    
    # Get the parent container (likely a table row or div), then walk up
    booking_container = None
    for element in booking_elements:
        candidate = element.find_parent(['tr', 'div', 'td', 'table'])
        current = candidate
        for _ in range(7):
            if not current:
                break
            candidate_text = current.get_text(separator='\n', strip=True)
            if _has_booking_fields(candidate_text):
                booking_container = current
                break
            current = current.parent
        if booking_container:
            break
    
    if not booking_container:
        # Try to get surrounding context
        parent = booking_elements[0].parent
        if parent:
            booking_container = parent.find_parent(['tr', 'div', 'table'])
    
    # Extract text content
    container_text = ''
    if booking_container:
        container_text = booking_container.get_text(separator='\n', strip=True)
    
    page_text = soup.get_text(separator='\n')
    if not container_text or container_text.strip() == booking_no or len(container_text) < 20:
        # Fallback: pull a window around the booking number from full page text
        idx = page_text.find(booking_no)
        if idx != -1:
            start = max(0, idx - 2000)
            end = min(len(page_text), idx + 2500)
            container_text = page_text[start:end].strip()
    
    if 'Booking Date' not in container_text and 'Booking Dt' not in container_text:
        # Fallback: extract the full booking block between Booking No markers
        block_pattern = (
            r'Booking No:\s*' + re.escape(booking_no) + r'[\s\S]*?'
            r'(?=Booking No:\s*PCSO|$)'
        )
        block_match = re.search(block_pattern, page_text)
        if block_match:
            block_text = block_match.group(0).strip()
            if ('Booking Date' in block_text or 'Booking Dt' in block_text
                    or len(block_text) > len(container_text)):
                container_text = block_text
    
    return _parse_booking_from_text(container_text, booking_no, page_text)


def _parse_booking_from_text(
    container_text: str,
    booking_no: str,
    page_text: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    # Parse booking data from text
    booking_data = {
        'booking_no': booking_no,
        'mni_no': '',
        'name': '',
        'status': '',
        'booking_date': None,
        'age_on_booking_date': None,
        'bond_amount': '',
        'address_given': '',
        'holds_text': None,
        'race': '',
        'gender': '',
        'released_date': None,
        'photo_url': f'{PCSO_PHOTO_BASE_URL}{booking_no}',
        'charges': [],
        'raw_card_text': container_text,
    }
    
    # Extract MniNo (pattern: PCSO##MNI######)
    mni_match = re.search(r'PCSO\d{2}MNI\d{6}', container_text)
    if mni_match:
        booking_data['mni_no'] = mni_match.group(0)
    
    # Extract name (usually before booking number, format: LAST, FIRST MIDDLE)
    name_match = re.search(
        r'([A-Z][A-Z\s,]+?)\s+\([BW]/?\s*(?:MALE|FEMALE|M|F)',
        container_text,
    )
    if name_match:
        booking_data['name'] = name_match.group(1).strip()
    
    # Extract race and gender (format: (B/ MALE) or (W/ FEMALE))
    race_gender_match = re.search(r'\(([BW])/?\s*(MALE|FEMALE|M|F)', container_text, re.IGNORECASE)
    if race_gender_match:
        booking_data['race'] = race_gender_match.group(1)
        gender_code = race_gender_match.group(2).upper()
        booking_data['gender'] = 'Male' if gender_code.startswith('M') else 'Female'
    
    # Extract status (Status: In Jail or Status: Released)
    status_match = re.search(r'Status:\s*(In Jail|Released)', container_text, re.IGNORECASE)
    if status_match:
        booking_data['status'] = status_match.group(1)
    
    # Extract booking date (handle varied label formats and time formats)
    date_patterns = [
        r'Booking Date[^0-9]*(\d{1,2}/\d{1,2}/\d{4})\s+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)',
        r'Booking Date[^0-9]*(\d{1,2}/\d{1,2}/\d{4})',
        r'Booking Dt[^0-9]*(\d{1,2}/\d{1,2}/\d{4})\s+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)',
        r'Booking Dt[^0-9]*(\d{1,2}/\d{1,2}/\d{4})',
        r'Booked[^0-9]*(\d{1,2}/\d{1,2}/\d{4})\s+(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)',
        r'Booked[^0-9]*(\d{1,2}/\d{1,2}/\d{4})',
    ]
    for pattern in date_patterns:
        date_match = re.search(pattern, container_text, re.IGNORECASE)
        if not date_match:
            continue
        if date_match.lastindex and date_match.lastindex >= 2:
            date_str = f"{date_match.group(1)} {date_match.group(2)}"
            try:
                if re.search(r'(AM|PM)', date_str, re.IGNORECASE):
                    booking_data['booking_date'] = _to_utc_iso_safe(
                        date_str,
                    )
                else:
                    booking_data['booking_date'] = _to_utc_iso_safe(
                        date_str,
                    )
            except Exception:
                pass
        else:
            date_str = date_match.group(1)
            try:
                booking_data['booking_date'] = _to_utc_iso_safe(
                    date_str,
                )
            except Exception:
                pass
        if booking_data['booking_date']:
            break
    
    if not booking_data['booking_date'] and page_text:
        # Final fallback: look for a booking date near the booking number
        near_patterns = [
            r'Booking No:\s*' + re.escape(booking_no) + r'[\s\S]{0,400}?'
            r'Booking Date[^0-9]*(\d{1,2}/\d{1,2}/\d{4})\s+'
            r'(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)',
            r'Booking Date[^0-9]*(\d{1,2}/\d{1,2}/\d{4})\s+'
            r'(\d{1,2}:\d{2}(?::\d{2})?\s*(?:AM|PM)?)[\s\S]{0,400}?'
            r'Booking No:\s*' + re.escape(booking_no),
        ]
        for pattern in near_patterns:
            date_match = re.search(pattern, page_text, re.IGNORECASE)
            if not date_match:
                continue
            date_str = f"{date_match.group(1)} {date_match.group(2)}"
            booking_data['booking_date'] = _to_utc_iso_safe(
                date_str,
            )
            if booking_data['booking_date']:
                break
    
    # Extract age
    age_match = re.search(r'Age On Booking Date:\s*(\d+)', container_text, re.IGNORECASE)
    if age_match:
        try:
            booking_data['age_on_booking_date'] = int(age_match.group(1))
        except Exception:
            pass
    
    # Extract bond amount
    bond_match = re.search(r'Bond Amount:\s*([^\n]+)', container_text, re.IGNORECASE)
    if bond_match:
        booking_data['bond_amount'] = bond_match.group(1).strip()
    
    # Extract address
    address_match = re.search(r'Address Given:([^\n]+)', container_text, re.IGNORECASE)
    if address_match:
        booking_data['address_given'] = address_match.group(1).strip()
    
    # Extract holds
    holds_match = re.search(r'HOLDS\s+([^\n]+)', container_text, re.IGNORECASE)
    if holds_match:
        booking_data['holds_text'] = holds_match.group(1).strip()
    
    # Extract charges - look for charge rows
    # Charges appear in a table format with STATUTE, COURT CASE NUMBER, CHARGE, etc.
    charges = []
    charge_rows = re.split(r'\n', container_text)
    
    for row in charge_rows:
        row_text = row.strip()
        if not row_text:
            continue
        # Look for charge patterns - usually has statute number
        charge_match = re.search(r'(\d+\.\d+(?:\.\d+)?[a-z]?)\s+([^\s]+)\s+\(([^)]+)\)\s+([A-Z][^0-9]+)', row_text)
        if charge_match:
            charge_data = {
                'statute': charge_match.group(1),
                'case_number': charge_match.group(2),
                'agency': charge_match.group(3),
                'charge': charge_match.group(4).strip(),
                'degree': None,
                'level': None,
                'bond': None,
            }
            
            # Try to extract degree and level
            degree_match = re.search(r'\b([TFSN])\s+([FM])\b', row_text)
            if degree_match:
                charge_data['degree'] = degree_match.group(1)
                charge_data['level'] = degree_match.group(2)
            
            # Extract bond amount for this charge
            bond_match = re.search(r'\$\d+(?:\.\d{2})?|NO BOND', row_text)
            if bond_match:
                charge_data['bond'] = bond_match.group(0)
            
            charges.append(charge_data)
    
    booking_data['charges'] = charges
    
    return booking_data

# =====================================================
# DATA PROCESSING
# =====================================================

def normalize_booking(booking_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Normalize booking data to match Supabase schema.
    
    Expected Supabase fields:
    - booking_no (primary key)
    - mni_no
    - name
    - status
    - booking_date
    - age_on_booking_date
    - bond_amount
    - address_given
    - holds_text
    - race
    - gender
    - released_date
    - charges (JSONB array)
    """
    # Map PCSO data fields to Supabase schema
    # Handle both direct field names and potential variations
    
    # Parse booking_date (handle ISO strings and datetime objects)
    booking_date = booking_data.get('booking_date') or booking_data.get('bookingDate') or booking_data.get('booked_at')
    if isinstance(booking_date, str) and HAS_DATEUTIL:
        try:
            # Try parsing ISO format
            booking_date = date_parser.parse(booking_date).isoformat()
        except:
            pass  # Keep original string if parsing fails
    
    # Parse released_date
    released_date = booking_data.get('released_date') or booking_data.get('releasedDate')
    if isinstance(released_date, str) and HAS_DATEUTIL:
        try:
            released_date = date_parser.parse(released_date).isoformat()
        except:
            pass  # Keep original string if parsing fails
    
    charges: List[Dict[str, Any]] = []
    if PCSO_BOOKINGS_HAS_CHARGES:
        # Ensure charges is a list
        charges = booking_data.get('charges', [])
        if not isinstance(charges, list):
            charges = []
    
    normalized = {
        'booking_no': booking_data.get('booking_no') or booking_data.get('bookingNo') or '',
        'mni_no': booking_data.get('mni_no') or booking_data.get('mniNo') or '',
        'name': booking_data.get('name') or '',
        'status': booking_data.get('status') or '',
        'booking_date': booking_date,
        'age_on_booking_date': booking_data.get('age_on_booking_date') or booking_data.get('ageOnBookingDate') or booking_data.get('age'),
        'bond_amount': booking_data.get('bond_amount') or booking_data.get('bondAmount') or booking_data.get('bond') or '',
        'address_given': booking_data.get('address_given') or booking_data.get('addressGiven') or booking_data.get('address') or '',
        'holds_text': booking_data.get('holds_text') or booking_data.get('holdsText') or booking_data.get('holds') or None,
        'race': booking_data.get('race') or '',
        'gender': booking_data.get('gender') or '',
        'released_date': released_date,
        'photo_url': booking_data.get('photo_url') or '',
        'raw_card_text': booking_data.get('raw_card_text') or '',
    }
    if PCSO_BOOKINGS_HAS_CHARGES:
        normalized['charges'] = charges  # JSONB array - should already be in correct format
    
    # Validate required fields
    if not normalized['booking_no']:
        logger.warning(
            '⚠️  Skipping booking with no booking_no: %s',
            booking_data.get('name', 'unknown'),
        )
        return None
    if PCSO_SKIP_INCOMPLETE:
        if not normalized.get('booking_date'):
            logger.warning('⚠️  Skipping booking %s: missing booking_date', normalized['booking_no'])
            return None
        if not normalized.get('name'):
            logger.warning('⚠️  Skipping booking %s: missing name', normalized['booking_no'])
            return None
    
    return normalized

# =====================================================
# DATABASE OPERATIONS
# =====================================================

def upsert_bookings(bookings: List[Dict[str, Any]], supabase: Client) -> Dict[str, int]:
    """
    Upsert bookings into Supabase.
    
    Uses booking_no as unique identifier.
    Updates existing records, inserts new ones.
    
    Returns:
        Dict with counts: {'inserted': X, 'updated': Y, 'skipped': Z}
    """
    if not bookings:
        logger.warning('⚠️  No bookings to import')
        return {'inserted': 0, 'updated': 0, 'skipped': 0}
    
    # De-duplicate by booking_no to avoid ON CONFLICT DO UPDATE errors
    deduped: Dict[str, Dict[str, Any]] = {}
    for booking in bookings:
        booking_no = booking.get('booking_no') or booking.get('bookingNo')
        if not booking_no:
            continue
        existing = deduped.get(booking_no)
        if not existing:
            deduped[booking_no] = booking
            continue
        # Prefer the record with more complete data
        existing_charges = existing.get('charges') or []
        new_charges = booking.get('charges') or []
        if (len(new_charges) > len(existing_charges)
                or (booking.get('name') and not existing.get('name'))):
            deduped[booking_no] = booking
    bookings = list(deduped.values())
    logger.info(f'📊 Processing {len(bookings)} bookings...')
    
    inserted = 0
    updated = 0
    skipped = 0
    
    try:
        charges_by_booking: Dict[str, List[Dict[str, Any]]] = {}
        for booking in bookings:
            booking_no = booking.get('booking_no') or booking.get('bookingNo')
            charges = booking.get('charges') or []
            if booking_no and isinstance(charges, list) and charges:
                charges_by_booking[booking_no] = charges

        # Process in batches
        for i in range(0, len(bookings), BATCH_SIZE):
            batch = bookings[i:i + BATCH_SIZE]
            normalized_batch = []
            
            # Normalize each booking, skipping invalid ones
            for b in batch:
                normalized = normalize_booking(b)
                if normalized:
                    normalized_batch.append(normalized)
                else:
                    skipped += 1
            
            if not normalized_batch:
                logger.warning(f'   Batch {i // BATCH_SIZE + 1}: No valid bookings to process')
                continue
            
            # Upsert batch
            response = supabase.table(PCSO_BOOKINGS_TABLE)\
                .upsert(normalized_batch, on_conflict='booking_no')\
                .execute()
            
            # Count results (Supabase doesn't return detailed counts, so estimate)
            inserted += len(normalized_batch)
            
            logger.info(f'   Processed batch {i // BATCH_SIZE + 1}: {len(normalized_batch)} bookings (skipped: {skipped})')
        
        logger.info(f'✅ Import complete: {inserted} bookings processed')

        charges_synced = 0
        if PCSO_SYNC_CHARGES and charges_by_booking:
            charges_synced = _sync_charges(charges_by_booking, supabase)
        photos_synced = 0
        photo_failures = 0
        if PCSO_SYNC_PHOTOS:
            photos_synced, photo_failures = _sync_photos(bookings, supabase)
        return {
            'inserted': inserted,
            'updated': 0,
            'skipped': skipped,
            'charges_synced': charges_synced,
            'photos_synced': photos_synced,
            'photo_failures': photo_failures,
        }
        
    except Exception as e:
        logger.error(f'❌ Error upserting bookings: {e}')
        import traceback
        traceback.print_exc()
        raise


def _sync_charges(
    charges_by_booking: Dict[str, List[Dict[str, Any]]],
    supabase: Client,
) -> int:
    logger.info(f'🧾 Syncing charges for {len(charges_by_booking)} bookings...')
    total_charges = 0
    for booking_no, charges in charges_by_booking.items():
        if not charges:
            continue
        # Replace existing charges for this booking
        supabase.table(PCSO_CHARGES_TABLE).delete().eq('booking_no', booking_no).execute()
        charge_rows = []
        for idx, charge in enumerate(charges):
            charge_rows.append({
                'booking_no': booking_no,
                'charge': charge.get('charge', ''),
                'statute': charge.get('statute', ''),
                'case_number': charge.get('case_number', ''),
                'agency': charge.get('agency', ''),
                'degree': charge.get('degree', ''),
                'level': charge.get('level', ''),
                'bond': charge.get('bond', ''),
                'charge_order': idx + 1,
            })
        supabase.table(PCSO_CHARGES_TABLE).insert(charge_rows).execute()
        total_charges += len(charge_rows)
    logger.info(f'🧾 Charges synced: {total_charges}')
    return total_charges


def _sync_photos(bookings: List[Dict[str, Any]], supabase: Client) -> tuple[int, int]:
    if not SUPABASE_URL:
        return (0, 0)
    public_base = f'{SUPABASE_URL}/storage/v1/object/public/{PCSO_PHOTOS_BUCKET}/'
    storage = supabase.storage.from_(PCSO_PHOTOS_BUCKET)
    synced = 0
    failed = 0
    for booking in bookings:
        booking_no = booking.get('booking_no') or booking.get('bookingNo')
        if not booking_no:
            continue
        photo_url = booking.get('photo_url') or f'{PCSO_PHOTO_BASE_URL}{booking_no}'
        try:
            resp = requests.get(photo_url, timeout=20)
            content_type = resp.headers.get('content-type', 'image/jpeg')
            if resp.status_code != 200 or 'image' not in content_type:
                continue
            storage.upload(
                f'{booking_no}.jpg',
                resp.content,
                file_options={
                    'content-type': content_type,
                    'upsert': 'true',
                },
            )
            supabase.table(PCSO_BOOKINGS_TABLE).update(
                {'photo_url': f'{public_base}{booking_no}.jpg'},
            ).eq('booking_no', booking_no).execute()
            synced += 1
        except Exception as e:
            logger.warning('⚠️  Photo sync failed for %s: %s', booking_no, e)
            failed += 1
    logger.info(f'🖼️  Photos synced: {synced} (failed: {failed})')
    return (synced, failed)

# =====================================================
# MAIN FUNCTION
# =====================================================

def main():
    """Main import function"""
    logger.info('=' * 60)
    logger.info('🚀 PCSO JAIL LOG IMPORT')
    logger.info('=' * 60)
    logger.info(f'📅 Started: {datetime.now()}')
    logger.info('')
    
    try:
        # Get Supabase client
        supabase = get_supabase_client()
        logger.info('✅ Connected to Supabase')
        
        # Fetch bookings from PCSO
        bookings = fetch_pcso_bookings()
        
        if not bookings:
            logger.warning('⚠️  No bookings fetched. Check fetch_pcso_bookings() implementation.')
            logger.warning('   This script needs to be customized for PCSO website structure.')
            sys.exit(1)
        
        # Upsert to database
        result = upsert_bookings(bookings, supabase)
        
        logger.info('')
        logger.info('=' * 60)
        logger.info('✅ IMPORT COMPLETE')
        logger.info('=' * 60)
        logger.info(f'📊 Records processed: {result["inserted"]}')
        if result.get('charges_synced') is not None:
            logger.info(f'🧾 Charges synced: {result["charges_synced"]}')
        if result.get('photos_synced') is not None:
            logger.info(
                f'🖼️  Photos synced: {result["photos_synced"]} '
                f'(failed: {result.get("photo_failures", 0)})',
            )
        logger.info(f'📅 Completed: {datetime.now()}')
        
        sys.exit(0)
        
    except Exception as e:
        logger.error(f'❌ Import error: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    # Create logs directory if it doesn't exist
    (script_dir / 'logs').mkdir(exist_ok=True)
    
    main()

