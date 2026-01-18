#!/usr/bin/env python3
"""
Import Traffic Citations CSV to Supabase with UPSERT support
Handles duplicates by updating existing records and inserting new ones.
Designed for daily automated imports of monthly Clerk of Court files.
"""

import os
import sys
import csv
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional
from supabase import create_client, Client
from dotenv import load_dotenv

# =====================================================
# LOAD ENVIRONMENT VARIABLES
# =====================================================

script_dir = Path(__file__).parent
project_root = script_dir if (script_dir / 'assets').exists() else script_dir.parent
env_path = project_root / 'assets' / '.env'

if env_path.exists():
    load_dotenv(env_path)
    print(f'✅ Loaded environment variables from {env_path}')
else:
    load_dotenv()
    print('⚠️  assets/.env not found, trying current directory .env')

# =====================================================
# CONFIGURATION
# =====================================================

SUPABASE_URL = os.getenv('SUPABASE_URL', '')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', '')

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    print('❌ Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in assets/.env')
    sys.exit(1)

# =====================================================
# SUPABASE SETUP
# =====================================================

def get_supabase_client() -> Client:
    """Initialize and return Supabase client"""
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# =====================================================
# CSV PARSING
# =====================================================

def parse_date(date_str: str) -> Optional[datetime]:
    """Parse YYYYMMDD date string to datetime"""
    if not date_str or len(date_str) < 8:
        return None
    try:
        return datetime.strptime(date_str[:8], '%Y%m%d')
    except ValueError:
        return None

def parse_csv_row(row: List[str]) -> Optional[Dict]:
    """
    Parse a CSV row (pipe-delimited) into a dictionary
    
    NEW FILE LAYOUT (19 fields):
    0: violation date (yyyymmdd)
    1: citation number (7 characters) - CHANGED from license plate
    2: check digit (1 character) - NEW FIELD
    3: last name (up to 20 characters)
    4: first name (up to 20 characters)
    5: middle name (up to 20 characters)
    6: address (up to 50 characters)
    7: city (up to 30 characters)
    8: state (2 characters)
    9: zip (5 characters)
    10: fine amount ($) - NEW FIELD
    11: dl state (2 characters) - driver's license state
    12: dl number (up to 20 characters) - driver's license number
    13: dob (yyyymmdd)
    14: sex (M or F)
    15: charge description (up to 40 characters) - violation description
    16: case number (16 characters)
    17: disposition date (yyyymmdd)
    18: Uniform Case Num (20 alpha) - NEW FIELD, replaces full_case_number
    """
    if len(row) < 19:
        return None
    
    # Parse dates
    citation_date = parse_date(row[0])
    date_of_birth = parse_date(row[13]) if len(row) > 13 and row[13] else None
    disposition_date = parse_date(row[17]) if len(row) > 17 and row[17] else None
    
    if not citation_date:
        return None
    
    # Clean up text fields
    def clean_text(text: str) -> str:
        if not text:
            return ''
        return text.strip()
    
    def clean_money(text: str) -> Optional[str]:
        """Clean fine amount, remove $ and convert to numeric string"""
        if not text or not text.strip():
            return None
        cleaned = text.strip().replace('$', '').replace(',', '')
        return cleaned if cleaned else None
    
    # Build record
    record = {
        'citation_date': citation_date.date().isoformat(),
        'case_number': clean_text(row[16]) if len(row) > 16 else '',
        'full_case_number': clean_text(row[18]) if len(row) > 18 else '',  # Uniform Case Num
        'violation_description': clean_text(row[15]) if len(row) > 15 else '',
        'citation_number': clean_text(row[1]) if len(row) > 1 and row[1] else None,  # NEW: citation number (was license_plate)
        'check_digit': clean_text(row[2]) if len(row) > 2 and row[2] else None,  # NEW: check digit
        'fine_amount': clean_money(row[10]) if len(row) > 10 and row[10] else None,  # NEW: fine amount
        'dl_state': clean_text(row[11]) if len(row) > 11 and row[11] else None,  # NEW: driver's license state
        'last_name': clean_text(row[3]) if len(row) > 3 else '',
        'first_name': clean_text(row[4]) if len(row) > 4 else '',
        'middle_name': clean_text(row[5]) if len(row) > 5 and row[5] else None,
        'date_of_birth': date_of_birth.date().isoformat() if date_of_birth else None,
        'gender': clean_text(row[14]) if len(row) > 14 and row[14] else None,
        'license_number': clean_text(row[12]) if len(row) > 12 and row[12] else None,  # dl number
        'address': clean_text(row[6]) if len(row) > 6 and row[6] else None,
        'city': clean_text(row[7]) if len(row) > 7 and row[7] else None,
        'state': clean_text(row[8]) if len(row) > 8 and row[8] else None,
        'zip_code': clean_text(row[9]) if len(row) > 9 and row[9] else None,
        'disposition_date': disposition_date.date().isoformat() if disposition_date else None,
    }
    
    # Validate required fields
    if not record['case_number'] or not record['full_case_number']:
        return None
    
    return record

def deduplicate_batch(records: List[Dict]) -> List[Dict]:
    """
    Remove duplicate case_numbers from a batch, keeping the last occurrence.
    This prevents PostgreSQL ON CONFLICT errors when multiple rows have the same case_number.
    """
    seen = {}
    deduplicated = []
    
    # Process records in order, keeping the last occurrence of each case_number
    for record in records:
        case_num = record.get('case_number')
        if case_num:
            seen[case_num] = record
    
    # Return deduplicated records
    return list(seen.values())

def upsert_csv_file(file_path: Path, supabase: Client, batch_size: int = 1000) -> Dict[str, int]:
    """
    Import a CSV file into Supabase using UPSERT logic.
    Updates existing records (by case_number) and inserts new ones.
    
    Returns dict with counts: {'inserted': X, 'updated': Y, 'skipped': Z}
    """
    print(f'\n📄 Processing file: {file_path.name}')
    print(f'   Path: {file_path}')
    
    if not file_path.exists():
        print(f'❌ File not found: {file_path}')
        return {'inserted': 0, 'updated': 0, 'skipped': 0}
    
    # Check if file is HTML (invalid download)
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            first_line = f.readline().strip()
            if first_line.startswith('<!DOCTYPE') or first_line.startswith('<html') or '<html' in first_line.lower():
                print(f'❌ File appears to be HTML, not CSV: {file_path.name}')
                print(f'   This usually means the download failed. Please manually download the file.')
                return {'inserted': 0, 'updated': 0, 'skipped': 0}
    except Exception:
        pass
    
    records = []
    skipped = 0
    inserted = 0
    updated = 0
    duplicates_in_batch = 0
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # Read file and split by pipe delimiter
            for line_num, line in enumerate(f, 1):
                # Remove BOM if present
                if line_num == 1 and line.startswith('\ufeff'):
                    line = line[1:]
                
                # Split by pipe
                row = line.strip().split('|')
                
                # Skip empty rows
                if not row or len(row) < 2:
                    skipped += 1
                    continue
                
                # Parse row
                record = parse_csv_row(row)
                if not record:
                    skipped += 1
                    if line_num <= 5:  # Show first few errors
                        print(f'   ⚠️  Skipped row {line_num}: Invalid format')
                    continue
                
                records.append(record)
                
                # Upsert in batches
                if len(records) >= batch_size:
                    try:
                        # Deduplicate batch to prevent ON CONFLICT errors
                        original_count = len(records)
                        records = deduplicate_batch(records)
                        if len(records) < original_count:
                            duplicates_in_batch += (original_count - len(records))
                        
                        # Use upsert: insert or update on conflict with case_number
                        # PostgreSQL will update existing records and insert new ones
                        result = supabase.table('traffic_citations')\
                            .upsert(records, on_conflict='case_number')\
                            .execute()
                        
                        # Note: Supabase doesn't return counts of inserted vs updated
                        # We'll estimate based on whether records existed before
                        inserted += len(records)
                        print(f'   ✅ Upserted batch: {inserted} records processed (row {line_num})')
                        records = []
                    except Exception as e:
                        print(f'   ❌ Error upserting batch at row {line_num}: {e}')
                        # Try upserting one by one to find the problematic record
                        for rec in records:
                            try:
                                supabase.table('traffic_citations')\
                                    .upsert([rec], on_conflict='case_number')\
                                    .execute()
                                inserted += 1
                            except Exception as insert_error:
                                print(f'      ⚠️  Failed to upsert: {rec.get("case_number", "unknown")} - {insert_error}')
                        records = []
        
        # Upsert remaining records
        if records:
            try:
                # Deduplicate final batch
                original_count = len(records)
                records = deduplicate_batch(records)
                if len(records) < original_count:
                    duplicates_in_batch += (original_count - len(records))
                
                result = supabase.table('traffic_citations')\
                    .upsert(records, on_conflict='case_number')\
                    .execute()
                inserted += len(records)
                print(f'   ✅ Upserted final batch: {inserted} total records processed')
            except Exception as e:
                print(f'   ❌ Error upserting final batch: {e}')
        
        print(f'\n✅ Import complete!')
        print(f'   Total processed: {inserted}')
        print(f'   Total skipped: {skipped}')
        if duplicates_in_batch > 0:
            print(f'   Duplicates removed from batches: {duplicates_in_batch}')
        print(f'   Note: Processed count includes both new inserts and updates')
        
        return {'inserted': inserted, 'updated': 0, 'skipped': skipped}
        
    except Exception as e:
        print(f'❌ Error reading file: {e}')
        import traceback
        traceback.print_exc()
        return {'inserted': 0, 'updated': 0, 'skipped': 0}

# =====================================================
# MAIN EXECUTION
# =====================================================

def main():
    """Main import function"""
    print('🚀 Starting traffic citations UPSERT import...')
    print(f'📅 Time: {datetime.now()}')
    print('-' * 60)
    
    try:
        # Initialize Supabase
        supabase = get_supabase_client()
        print('✅ Connected to Supabase')
        
        # Find CSV files in zClerkDataUpdate folder
        script_dir = Path(__file__).parent
        if script_dir.name == 'zClerkDataUpdate':
            temp_data_dir = script_dir
        else:
            temp_data_dir = script_dir / 'zClerkDataUpdate'
        
        if not temp_data_dir.exists():
            print(f'❌ zClerkDataUpdate directory not found: {temp_data_dir}')
            sys.exit(1)
        
        # Look for traffic citation CSV files
        # Priority: files matching "traffic" or "Traffic History" pattern
        csv_files = list(temp_data_dir.glob('*traffic*.csv'))
        csv_files.extend(list(temp_data_dir.glob('*Traffic*.csv')))
        
        if not csv_files:
            print(f'❌ No traffic citation CSV files found in {temp_data_dir}')
            print(f'   Looking for files matching: *traffic*.csv or *Traffic*.csv')
            sys.exit(1)
        
        # Sort by modification time (newest first)
        csv_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        
        print(f'\n📁 Found {len(csv_files)} CSV file(s)')
        for csv_file in csv_files:
            mtime = datetime.fromtimestamp(csv_file.stat().st_mtime)
            print(f'   - {csv_file.name} (modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")})')
        
        total_inserted = 0
        total_updated = 0
        total_skipped = 0
        
        # Process the most recent file (or all files if needed)
        # For daily updates, typically only process the newest file
        file_to_process = csv_files[0]
        print(f'\n📄 Processing most recent file: {file_to_process.name}')
        
        result = upsert_csv_file(file_to_process, supabase)
        total_inserted += result['inserted']
        total_updated += result['updated']
        total_skipped += result['skipped']
        
        # Summary
        print('-' * 60)
        print(f'✅ Import complete!')
        print(f'   Total processed: {total_inserted}')
        print(f'   Total skipped: {total_skipped}')
        print(f'\n💡 Note: This script uses UPSERT logic.')
        print(f'   - New records are inserted')
        print(f'   - Existing records (by case_number) are updated')
        print(f'   - Safe to run daily on the same file')
        
    except Exception as e:
        print(f'❌ Fatal error: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()

