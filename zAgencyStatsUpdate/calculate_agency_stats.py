#!/usr/bin/env python3
"""
Calculate and store agency statistics in Supabase.

This script calculates statistics for all law enforcement agencies in Putnam County
and stores them in the agency_stats table. Should be run twice daily via cron.

Agencies:
- pcso (Putnam County Sheriff's Office)
- palatka_pd (Palatka Police Department)
- interlachen_pd (Interlachen Police Department)
- welaka_pd (Welaka Police Department)
- school_pd (Putnam County School District Police Department)
- fhp (Florida Highway Patrol)
- fwc (Florida Fish and Wildlife Conservation Commission)
"""

import os
import sys
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any
from collections import defaultdict

from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
from pathlib import Path

script_dir = Path(__file__).parent
project_root = script_dir if (script_dir / 'assets').exists() else script_dir.parent
env_path = project_root / 'assets' / '.env'

if env_path.exists():
    load_dotenv(env_path)
    print(f'✅ Loaded environment variables from {env_path}')
else:
    load_dotenv()
    print('⚠️  assets/.env not found, trying current directory .env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')  # Use service role key for writes

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    print("ERROR: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in assets/.env")
    print(f"SUPABASE_URL: {'SET' if SUPABASE_URL else 'MISSING'}")
    print(f"SUPABASE_SERVICE_ROLE_KEY: {'SET' if SUPABASE_SERVICE_ROLE_KEY else 'MISSING'}")
    sys.exit(1)

# Agency configurations
AGENCIES = [
    {'id': 'pcso', 'name': 'PUTNAM COUNTY SHERIFF\'S OFFICE', 'search_term': 'PUTNAM COUNTY SHERIFF'},
    {'id': 'palatka_pd', 'name': 'PALATKA POLICE DEPARTMENT', 'search_term': 'PALATKA POLICE DEPARTMENT'},
    {'id': 'interlachen_pd', 'name': 'INTERLACHEN POLICE DEPARTMENT', 'search_term': 'INTERLACHEN POLICE DEPARTMENT'},
    {'id': 'welaka_pd', 'name': 'WELAKA POLICE DEPARTMENT', 'search_term': 'WELAKA POLICE DEPARTMENT'},
    {'id': 'school_pd', 'name': 'PUTNAM COUNTY SCHOOL DISTRICT POLICE DEPARTMENT', 'search_term': 'SCHOOL DISTRICT POLICE'},
    {'id': 'fhp', 'name': 'FLORIDA HIGHWAY PATROL', 'search_term': 'FLORIDA HIGHWAY PATROL'},
    {'id': 'fwc', 'name': 'FLORIDA FISH AND WILDLIFE CONSERVATION COMMISSION (FWC)', 'search_term': 'FISH AND WILDLIFE'},
]

BOOKINGS_TABLE = 'recent_bookings_with_charges'
AGENCY_STATS_TABLE = 'agency_stats'

# Calculate date range: last 5 years
def get_date_range():
    """Get start date for last 5 years of data."""
    now = datetime.now()
    start_year = now.year - 4  # 2025 - 4 = 2021
    start_date = datetime(start_year, 1, 1)
    return start_date


def expand_race_code(code: str) -> str:
    """Expand race codes to full names."""
    race_map = {
        'B': 'BLACK',
        'W': 'WHITE',
        'H': 'HISPANIC',
        'A': 'ASIAN',
        'I': 'NATIVE AMERICAN',
    }
    return race_map.get(code.upper(), code.upper())


def calculate_agency_stats(supabase: Client, agency: Dict[str, str]) -> Dict[str, Any]:
    """
    Calculate statistics for a single agency.
    
    Returns a dictionary with all statistics ready to insert into Supabase.
    """
    agency_id = agency['id']
    agency_name = agency['name']
    search_term = agency['search_term']
    
    print(f"\n[{agency_id}] Calculating stats for {agency_name}...")
    print(f"[{agency_id}] Search term: '{search_term}'")
    
    # Get date range
    start_date = get_date_range()
    print(f"[{agency_id}] Fetching bookings from {start_date.year} to {datetime.now().year} (last 5 years)")
    
    # Fetch all bookings from last 5 years (paginated)
    # Use date filter in query for efficiency
    all_bookings = []
    offset = 0
    batch_size = 1000
    
    max_retries = 3
    fetch_failed = False
    while True:
        attempt = 0
        while attempt < max_retries:
            try:
                response = supabase.table(BOOKINGS_TABLE)\
                    .select('booking_date,name,gender,race,charges,raw_card_text')\
                    .gte('booking_date', start_date.isoformat())\
                    .order('booking_date', desc=False)\
                    .range(offset, offset + batch_size - 1)\
                    .execute()
                
                batch = response.data if hasattr(response, 'data') else []
                if not batch:
                    break
                    
                all_bookings.extend(batch)
                print(f"[{agency_id}] Fetched batch: offset={offset}, got {len(batch)} records, total so far: {len(all_bookings)}")
                
                if len(batch) < batch_size:
                    break
                    
                offset += batch_size
                break
            except Exception as e:
                attempt += 1
                print(f"[{agency_id}] Error fetching bookings (attempt {attempt}/{max_retries}): {e}")
                if attempt >= max_retries:
                    fetch_failed = True
                    import traceback
                    traceback.print_exc()
                else:
                    import time
                    time.sleep(2 * attempt)
        if fetch_failed or (batch is not None and len(batch) < batch_size):
            break
    
    print(f"[{agency_id}] Total bookings fetched: {len(all_bookings)}")
    if fetch_failed:
        raise RuntimeError(f"Fetch failed for {agency_id}; aborting stats calculation to avoid partial totals.")
    
    def _charge_matches_agency(charge: Any, term: str) -> bool:
        """Return True if a charge record matches the agency search term."""
        if not isinstance(charge, dict):
            return False
        term_upper = term.upper()
        # Preferred: explicit agency field (if present)
        agency_value = charge.get('agency', '') or ''
        if agency_value and term_upper in str(agency_value).upper():
            return True
        # Fallback: case number may include agency text in older data
        case_number = charge.get('case_number', '') or charge.get('caseNumber', '')
        if case_number and term_upper in str(case_number).upper():
            return True
        return False

    # Filter bookings for this agency
    # Check if ANY charge matches agency (by agency field or case_number)
    # Fallback to raw_card_text if charges are missing in the view.
    agency_bookings = []
    unique_names = set()
    bookings_without_charges = 0
    bookings_with_empty_charges = 0
    sample_case_numbers = []
    bookings_matched_by_raw_text = 0
    charges_with_agency_field = 0
    total_charge_records = 0
    
    for booking in all_bookings:
        # Check charges for agency match
        # Use 'charges' column (not 'charge_details')
        charges = booking.get('charges', [])
        if isinstance(charges, str):
            try:
                charges = json.loads(charges)
            except:
                charges = []
        
        # Debug: Track bookings without charges
        if charges is None:
            bookings_without_charges += 1
            # Fall back to raw card text match if available
            raw_text = booking.get('raw_card_text', '') or ''
            if raw_text and search_term.upper() in raw_text.upper():
                agency_bookings.append(booking)
                bookings_matched_by_raw_text += 1
                name = booking.get('name', '').strip()
                if name:
                    unique_names.add(name)
            continue
        
        if not charges or len(charges) == 0:
            bookings_with_empty_charges += 1
            # Fall back to raw card text match if available
            raw_text = booking.get('raw_card_text', '') or ''
            if raw_text and search_term.upper() in raw_text.upper():
                agency_bookings.append(booking)
                bookings_matched_by_raw_text += 1
                name = booking.get('name', '').strip()
                if name:
                    unique_names.add(name)
            continue
        
        has_match = False
        for charge in charges:
            # Handle dict format (most common)
            if isinstance(charge, dict):
                total_charge_records += 1
                agency_value = charge.get('agency', '') or ''
                if agency_value:
                    charges_with_agency_field += 1
                case_number = charge.get('case_number', '') or charge.get('caseNumber', '')
                if case_number and len(sample_case_numbers) < 5:
                    sample_case_numbers.append(str(case_number))
                if _charge_matches_agency(charge, search_term):
                    has_match = True
                    break

        # Even if charges exist, include raw text match to catch mixed-agency cases
        if not has_match:
            raw_text = booking.get('raw_card_text', '') or ''
            if raw_text and search_term.upper() in raw_text.upper():
                has_match = True
                bookings_matched_by_raw_text += 1
        
        if has_match:
            agency_bookings.append(booking)
            name = booking.get('name', '').strip()
            if name:
                unique_names.add(name)
    
    if total_charge_records > 0 and charges_with_agency_field == 0:
        raise RuntimeError(
            f"[{agency_id}] Safety check failed: charges JSON has no 'agency' field. "
            "Update charges table/view to include agency before calculating stats."
        )

    print(f"[{agency_id}] Found {len(agency_bookings)} bookings for this agency")
    print(f"[{agency_id}] Unique persons: {len(unique_names)}")
    print(f"[{agency_id}] Bookings without charges: {bookings_without_charges}")
    print(f"[{agency_id}] Bookings with empty charges: {bookings_with_empty_charges}")
    print(f"[{agency_id}] Bookings matched by raw text: {bookings_matched_by_raw_text}")
    if sample_case_numbers:
        print(f"[{agency_id}] Sample case numbers: {sample_case_numbers[:3]}")
    
    if not agency_bookings:
        return {
            'agency_id': agency_id,
            'agency_name': agency_name,
            'total_bookings': 0,
            'total_charges': 0,
            'unique_persons': 0,
            'average_charges_per_booking': 0.0,
            'bookings_by_year': {},
            'bookings_by_gender': {},
            'bookings_by_race': {},
            'charges_by_level_and_degree': [],
        }
    
    # Calculate statistics
    total_bookings = len(agency_bookings)
    unique_persons = len(unique_names)
    
    # Count charges and build level/degree structure
    total_charges = 0
    level_degree_map = defaultdict(lambda: defaultdict(int))  # {level: {degree: count}}
    
    bookings_by_year = defaultdict(int)
    bookings_by_gender = defaultdict(int)
    bookings_by_race = defaultdict(int)
    
    for booking in agency_bookings:
        # Parse booking date
        booking_date = datetime.fromisoformat(booking['booking_date'].replace('Z', '+00:00'))
        year = booking_date.year
        bookings_by_year[year] += 1
        
        # Gender
        gender = booking.get('gender', '').strip().upper() or 'UNKNOWN'
        bookings_by_gender[gender] += 1
        
        # Race
        race_code = booking.get('race', '').strip().upper() or 'UNKNOWN'
        race = expand_race_code(race_code)
        bookings_by_race[race] += 1
        
        # Process charges
        # Use 'charges' column (not 'charge_details')
        charges = booking.get('charges', [])
        if isinstance(charges, str):
            try:
                charges = json.loads(charges)
            except:
                charges = []
        
        for charge in charges:
            # Only process charges that match this agency
            if isinstance(charge, dict):
                if _charge_matches_agency(charge, search_term):
                    total_charges += 1
                    
                    # Get level - check 'level' field (maps: 'F' -> FELONY, 'M' -> MISDEMEANOR)
                    level_code = charge.get('level', '').upper()
                    if level_code == 'F':
                        level = 'FELONY'
                    elif level_code == 'M':
                        level = 'MISDEMEANOR'
                    else:
                        level = level_code if level_code else 'UNKNOWN'
                    
                    # Get degree - check 'degree' field
                    degree = charge.get('degree', '').upper() or 'UNKNOWN'
                    
                    level_degree_map[level][degree] += 1
    
    # Convert level_degree_map to list format
    charges_by_level_and_degree = []
    for level, degree_map in level_degree_map.items():
        total_for_level = sum(degree_map.values())
        charges_by_level_and_degree.append({
            'level': level,
            'totalCount': total_for_level,
            'byDegree': dict(degree_map)
        })
    
    # Calculate average
    average_charges = total_charges / total_bookings if total_bookings > 0 else 0.0
    
    print(f"[{agency_id}] Statistics calculated:")
    print(f"  - Total bookings: {total_bookings}")
    print(f"  - Total charges: {total_charges}")
    print(f"  - Unique persons: {unique_persons}")
    print(f"  - Average charges per booking: {average_charges:.2f}")
    print(f"  - Years: {sorted(bookings_by_year.keys())}")
    
    return {
        'agency_id': agency_id,
        'agency_name': agency_name,
        'total_bookings': total_bookings,
        'total_charges': total_charges,
        'unique_persons': unique_persons,
        'average_charges_per_booking': round(average_charges, 2),
        'bookings_by_year': dict(bookings_by_year),
        'bookings_by_gender': dict(bookings_by_gender),
        'bookings_by_race': dict(bookings_by_race),
        'charges_by_level_and_degree': charges_by_level_and_degree,
    }


def upsert_agency_stats(supabase: Client, stats: Dict[str, Any]):
    """Insert agency stats into Supabase."""
    agency_id = stats['agency_id']
    calculated_at = datetime.now().isoformat()
    
    # Prepare data for insert
    # Supabase handles JSONB automatically - pass Python dicts/lists directly
    data = {
        'agency_id': stats['agency_id'],
        'agency_name': stats['agency_name'],
        'total_bookings': stats['total_bookings'],
        'total_charges': stats['total_charges'],
        'unique_persons': stats['unique_persons'],
        'average_charges_per_booking': stats['average_charges_per_booking'],
        'bookings_by_year': stats['bookings_by_year'],  # Python dict - Supabase converts to JSONB
        'bookings_by_gender': stats['bookings_by_gender'],  # Python dict
        'bookings_by_race': stats['bookings_by_race'],  # Python dict
        'charges_by_level_and_degree': stats['charges_by_level_and_degree'],  # Python list
        'calculated_at': calculated_at,
    }
    
    try:
        # Insert new record (unique constraint on agency_id + calculated_at ensures no duplicates)
        response = supabase.table(AGENCY_STATS_TABLE).insert(data).execute()
        print(f"[{agency_id}] ✅ Successfully stored stats (calculated_at: {calculated_at})")
        return True
    except Exception as e:
        print(f"[{agency_id}] ❌ Error storing stats: {e}")
        return False


def main():
    """Main function to calculate and store all agency stats."""
    print("=" * 60)
    print("AGENCY STATS CALCULATION")
    print("=" * 60)
    print(f"Started at: {datetime.now().isoformat()}")
    
    # Create Supabase client with service role key
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    success_count = 0
    error_count = 0
    
    # Calculate stats for each agency
    for agency in AGENCIES:
        try:
            stats = calculate_agency_stats(supabase, agency)
            if upsert_agency_stats(supabase, stats):
                success_count += 1
            else:
                error_count += 1
        except Exception as e:
            print(f"[{agency['id']}] ❌ Fatal error: {e}")
            error_count += 1
    
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Successfully calculated: {success_count}/{len(AGENCIES)}")
    print(f"Errors: {error_count}/{len(AGENCIES)}")
    print(f"Completed at: {datetime.now().isoformat()}")
    
    if error_count > 0:
        sys.exit(1)


if __name__ == '__main__':
    main()

