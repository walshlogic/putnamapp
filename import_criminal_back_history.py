#!/usr/bin/env python3
"""
Import Criminal Back History CSV to Supabase with UPSERT support
Handles duplicates by updating existing records and inserting new ones.
Designed for automated imports of Clerk of Court criminal back history files.
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
    
    CSV Format (16 fields):
    0: Case Number (14 ALPHA)
    1: Defendant Last Name (30 ALPHA)
    2: Defendant First Name (30 ALPHA)
    3: Defendant Middle Name (30 ALPHA)
    4: Address Line #1 (50 ALPHA)
    5: City (30 ALPHA)
    6: State (2 ALPHA)
    7: Zipcode (10 ALPHA)
    8: Date of Birth (8 DATE YYYYMMDD)
    9: Clerk File Date (8 DATE YYYYMMDD)
    10: Pros Decision Date (8 DATE YYYYMMDD)
    11: Court Decision Date (8 DATE YYYYMMDD)
    12: Statute Description (50 ALPHA)
    13: Court Action Description (50 ALPHA)
    14: Prosecutor Action Desc (50 ALPHA)
    15: Uniform Case Number (20 ALPHA)
    """
    if len(row) < 16:
        return None
    
    # Parse dates
    date_of_birth = parse_date(row[8]) if len(row) > 8 and row[8] else None
    clerk_file_date = parse_date(row[9]) if len(row) > 9 and row[9] else None
    pros_decision_date = parse_date(row[10]) if len(row) > 10 and row[10] else None
    court_decision_date = parse_date(row[11]) if len(row) > 11 and row[11] else None
    
    # Clean up text fields
    def clean_text(text: str) -> str:
        if not text:
            return ''
        return text.strip()
    
    # Build record
    record = {
        'case_number': clean_text(row[0]) if len(row) > 0 else '',
        'defendant_last_name': clean_text(row[1]) if len(row) > 1 else '',
        'defendant_first_name': clean_text(row[2]) if len(row) > 2 else '',
        'defendant_middle_name': clean_text(row[3]) if len(row) > 3 and row[3] else None,
        'address_line_1': clean_text(row[4]) if len(row) > 4 and row[4] else None,
        'city': clean_text(row[5]) if len(row) > 5 and row[5] else None,
        'state': clean_text(row[6]) if len(row) > 6 and row[6] else None,
        'zipcode': clean_text(row[7]) if len(row) > 7 and row[7] else None,
        'date_of_birth': date_of_birth.date().isoformat() if date_of_birth else None,
        'clerk_file_date': clerk_file_date.date().isoformat() if clerk_file_date else None,
        'pros_decision_date': pros_decision_date.date().isoformat() if pros_decision_date else None,
        'court_decision_date': court_decision_date.date().isoformat() if court_decision_date else None,
        'statute_description': clean_text(row[12]) if len(row) > 12 and row[12] else None,
        'court_action_description': clean_text(row[13]) if len(row) > 13 and row[13] else None,
        'prosecutor_action_description': clean_text(row[14]) if len(row) > 14 and row[14] else None,
        'uniform_case_number': clean_text(row[15]) if len(row) > 15 else '',
    }
    
    # Validate required fields
    if not record['case_number'] or not record['uniform_case_number']:
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
                print(f'❌ File appears to be HTML, not CSV/TXT: {file_path.name}')
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
                        result = supabase.table('criminal_back_history')\
                            .upsert(records, on_conflict='case_number')\
                            .execute()
                        
                        inserted += len(records)
                        print(f'   ✅ Upserted batch: {inserted} records processed (row {line_num})')
                        records = []
                    except Exception as e:
                        print(f'   ❌ Error upserting batch at row {line_num}: {e}')
                        # Try upserting one by one to find the problematic record
                        for rec in records:
                            try:
                                supabase.table('criminal_back_history')\
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
                
                result = supabase.table('criminal_back_history')\
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
    print('🚀 Starting criminal back history UPSERT import...')
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
        
        # Look for criminal history files (CSV or TXT)
        # Files can be directly in zClerkDataUpdate or in subfolders (criminal_YR/, criminal_HS/)
        # Priority: criminal_YR (current year, updated regularly)
        # Then: criminal_HS (historical, updated yearly)
        
        # Look for files directly in zClerkDataUpdate
        csv_files_yr = list(temp_data_dir.glob('*criminal_YR*.csv'))
        csv_files_yr.extend(list(temp_data_dir.glob('*criminal_yr*.csv')))
        csv_files_yr.extend(list(temp_data_dir.glob('*Criminal_YR*.csv')))
        csv_files_yr.extend(list(temp_data_dir.glob('*criminal_YR*.txt')))
        csv_files_yr.extend(list(temp_data_dir.glob('*criminal_yr*.txt')))
        csv_files_yr.extend(list(temp_data_dir.glob('*Criminal_YR*.txt')))
        
        csv_files_hs = list(temp_data_dir.glob('*criminal_HS*.csv'))
        csv_files_hs.extend(list(temp_data_dir.glob('*criminal_hs*.csv')))
        csv_files_hs.extend(list(temp_data_dir.glob('*Criminal_HS*.csv')))
        csv_files_hs.extend(list(temp_data_dir.glob('*criminal_HS*.txt')))
        csv_files_hs.extend(list(temp_data_dir.glob('*criminal_hs*.txt')))
        csv_files_hs.extend(list(temp_data_dir.glob('*Criminal_HS*.txt')))
        
        # Look for files in subdirectories
        # Check criminal_YR folder
        yr_folder = temp_data_dir / 'criminal_YR'
        if yr_folder.exists() and yr_folder.is_dir():
            csv_files_yr.extend(list(yr_folder.glob('*.csv')))
            csv_files_yr.extend(list(yr_folder.glob('*.txt')))
            csv_files_yr.extend(list(yr_folder.glob('*.text')))  # Handle .text extension
            csv_files_yr.extend(list(yr_folder.glob('crimina*.txt')))  # Handle typo: crimina instead of criminal
            csv_files_yr.extend(list(yr_folder.glob('crimina*.text')))
        
        # Check criminal_yr folder (lowercase)
        yr_folder_lower = temp_data_dir / 'criminal_yr'
        if yr_folder_lower.exists() and yr_folder_lower.is_dir():
            csv_files_yr.extend(list(yr_folder_lower.glob('*.csv')))
            csv_files_yr.extend(list(yr_folder_lower.glob('*.txt')))
            csv_files_yr.extend(list(yr_folder_lower.glob('*.text')))
            csv_files_yr.extend(list(yr_folder_lower.glob('crimina*.txt')))
            csv_files_yr.extend(list(yr_folder_lower.glob('crimina*.text')))
        
        # Check criminal_HS folder
        hs_folder = temp_data_dir / 'criminal_HS'
        if hs_folder.exists() and hs_folder.is_dir():
            csv_files_hs.extend(list(hs_folder.glob('*.csv')))
            csv_files_hs.extend(list(hs_folder.glob('*.txt')))
            csv_files_hs.extend(list(hs_folder.glob('*.text')))  # Handle .text extension
        
        # Check criminal_hs folder (lowercase)
        hs_folder_lower = temp_data_dir / 'criminal_hs'
        if hs_folder_lower.exists() and hs_folder_lower.is_dir():
            csv_files_hs.extend(list(hs_folder_lower.glob('*.csv')))
            csv_files_hs.extend(list(hs_folder_lower.glob('*.txt')))
            csv_files_hs.extend(list(hs_folder_lower.glob('*.text')))
        
        # Fallback: any criminal files (CSV or TXT)
        csv_files_fallback = list(temp_data_dir.glob('*criminal*.csv'))
        csv_files_fallback.extend(list(temp_data_dir.glob('*Criminal*.csv')))
        csv_files_fallback.extend(list(temp_data_dir.glob('*criminal*.txt')))
        csv_files_fallback.extend(list(temp_data_dir.glob('*Criminal*.txt')))
        
        # Combine and deduplicate, exclude help.txt files
        all_files = list(set(csv_files_yr + csv_files_hs + csv_files_fallback))
        # Filter out help.txt files
        all_files = [f for f in all_files if f.name.lower() != 'help.txt']
        
        if not all_files:
            print(f'❌ No criminal history files found in {temp_data_dir}')
            print(f'   Looking for files matching:')
            print(f'   - *criminal_YR*.csv or *.txt (current year)')
            print(f'   - *criminal_HS*.csv or *.txt (historical)')
            print(f'   - Files in criminal_YR/ or criminal_HS/ subfolders')
            print(f'   - *criminal*.csv or *.txt (any criminal file)')
            sys.exit(1)
        
        # Sort by modification time (newest first)
        all_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        
        print(f'\n📁 Found {len(all_files)} file(s)')
        for csv_file in all_files:
            mtime = datetime.fromtimestamp(csv_file.stat().st_mtime)
            # Determine file type based on folder or filename
            file_type = 'Unknown'
            if 'criminal_YR' in str(csv_file) or 'criminal_yr' in str(csv_file):
                file_type = 'YR (Current)'
            elif 'criminal_HS' in str(csv_file) or 'criminal_hs' in str(csv_file):
                file_type = 'HS (Historical)'
            print(f'   - {csv_file.name} ({file_type}) - modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")}')
        
        total_inserted = 0
        total_updated = 0
        total_skipped = 0
        
        # Process files: YR files first (most current), then HS files
        files_to_process = []
        
        # Add YR files first (current year, updated regularly)
        # Check both filename and path
        for f in all_files:
            file_path_str = str(f)
            if 'criminal_YR' in file_path_str or 'criminal_yr' in file_path_str:
                files_to_process.append(f)
        
        # Add HS files (historical, yearly update)
        for f in all_files:
            file_path_str = str(f)
            if 'criminal_HS' in file_path_str or 'criminal_hs' in file_path_str:
                if f not in files_to_process:
                    files_to_process.append(f)
        
        # Add any remaining files
        for f in all_files:
            if f not in files_to_process:
                files_to_process.append(f)
        
        # Process each file
        for file_to_process in files_to_process:
            file_type = 'YR (Current)' if '_YR' in file_to_process.name.upper() or '_yr' in file_to_process.name else \
                       'HS (Historical)' if '_HS' in file_to_process.name.upper() or '_hs' in file_to_process.name else \
                       'Unknown'
            print(f'\n📄 Processing file: {file_to_process.name} ({file_type})')
            
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
        print(f'   - Existing records (by case_number) are updated with latest information')
        print(f'   - Handles duplicates automatically')
        print(f'   - Safe to run on criminal_YR files regularly')
        print(f'   - criminal_HS files can be imported once yearly')
        
    except Exception as e:
        print(f'❌ Fatal error: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()

