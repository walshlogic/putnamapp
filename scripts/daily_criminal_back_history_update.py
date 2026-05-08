#!/usr/bin/env python3
"""
Daily Criminal Back History Update Script
Combines download and import into a single automated process.

This script:
1. Finds the latest criminal_YR files (current year, updated regularly)
2. Imports them into Supabase using UPSERT logic (handles duplicates)
3. Can be run daily via cron/task scheduler
"""

import sys
from pathlib import Path
from datetime import datetime

# Import download and import functions
try:
    from download_criminal_back_history import download_criminal_back_history
    from import_criminal_back_history import main as import_main, get_supabase_client, upsert_csv_file
except ImportError as e:
    print(f'❌ Import error: {e}')
    print('   Make sure download_criminal_back_history.py and import_criminal_back_history.py are in the same directory')
    sys.exit(1)

def main():
    """Main daily update function"""
    print('=' * 60)
    print('🚀 DAILY CRIMINAL BACK HISTORY UPDATE')
    print('=' * 60)
    print(f'📅 Started: {datetime.now()}')
    print()
    
    script_dir = Path(__file__).parent
    
    # Use zClerkDataUpdate folder (single working folder)
    if script_dir.name == 'zClerkDataUpdate':
        temp_data_dir = script_dir
    else:
        temp_data_dir = script_dir / 'zClerkDataUpdate'
    temp_data_dir.mkdir(exist_ok=True, parents=True)
    
    criminal_yr_dir = temp_data_dir / 'criminal_YR'
    criminal_yr_dir.mkdir(exist_ok=True)
    
    print(f'📁 Using data folder: {temp_data_dir}')
    
    # Step 1: Download file (if download script is available)
    print('📥 STEP 1: Downloading Criminal Back History file...')
    print('-' * 60)
    downloaded_files = download_criminal_back_history()
    
    files_to_process = []
    if downloaded_files:
        print(f'✅ Downloaded/Extracted {len(downloaded_files)} file(s):')
        for f in downloaded_files:
            print(f'   - {f.name}')
        files_to_process = downloaded_files
    else:
        print('⚠️  Download failed, checking for existing files...')
        # Step 1b: Find existing criminal files (ZIP or extracted TXT/CSV)
        print('📥 STEP 1b: Finding criminal files...')
        print('-' * 60)
        
        # Look for ZIP files first (criminal_HS.zip or criminal_YR.zip)
        zip_files = []
        zip_files.extend(list(temp_data_dir.glob('criminal_HS*.zip')))
        zip_files.extend(list(temp_data_dir.glob('criminal_YR*.zip')))
        zip_files.extend(list(temp_data_dir.glob('*criminal*.zip')))
        
        if zip_files:
            zip_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
            latest_zip = zip_files[0]
            mtime = datetime.fromtimestamp(latest_zip.stat().st_mtime)
            print(f'✅ Found ZIP file: {latest_zip.name} (modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")})')
            print('   Extracting...')
            
            # Import extraction function
            from download_criminal_back_history import extract_zip_file
            extracted_files = extract_zip_file(latest_zip, temp_data_dir)
            if extracted_files:
                files_to_process = extracted_files
            else:
                print('⚠️  ZIP extraction failed, checking for already-extracted files...')
        
        # Look for TXT/CSV files (already extracted or legacy)
        if not files_to_process:
            yr_files = []
            yr_folders = [
                criminal_yr_dir if criminal_yr_dir else temp_data_dir / 'criminal_YR',
                temp_data_dir / 'criminal_yr',
            ]
            
            for yr_folder in yr_folders:
                if yr_folder.exists() and yr_folder.is_dir():
                    yr_files.extend(list(yr_folder.glob('*.txt')))
                    yr_files.extend(list(yr_folder.glob('*.text')))
                    yr_files.extend(list(yr_folder.glob('*.csv')))
            
            # Also check directly in temp_data_dir for criminal files (from ZIP extraction)
            if temp_data_dir.exists():
                yr_files.extend(list(temp_data_dir.glob('*criminal*.txt')))
                yr_files.extend(list(temp_data_dir.glob('*criminal*.csv')))
            
            # Filter out help.txt files
            yr_files = [f for f in yr_files if f.name.lower() != 'help.txt']
            
            if not yr_files:
                print('❌ No criminal files found')
                print('   Looking in:')
                for yf in yr_folders:
                    print(f'   - {yf}')
                print(f'   - {temp_data_dir} (direct)')
                print(f'\n💡 To download files:')
                print(f'   1. Visit https://apps.putnam-fl.com/bocc/putsubs/main.php')
                print(f'   2. Right-click "Criminal Back History" → "Download Subscription"')
                print(f'   3. Save ZIP file to: {temp_data_dir}/criminal_HS.zip')
                print(f'   4. The script will extract it automatically')
                sys.exit(1)
            
            # Sort by modification time (newest first)
            yr_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
            
            print(f'✅ Found {len(yr_files)} criminal file(s)')
            for f in yr_files:
                mtime = datetime.fromtimestamp(f.stat().st_mtime)
                print(f'   - {f.name} (modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")})')
            
            files_to_process = yr_files
            print(f'\n📄 Will process {len(files_to_process)} file(s)')
    
    if not files_to_process:
        print('❌ No files to process')
        sys.exit(1)
    
    print()
    
    # Step 2: Import all files
    print('📊 STEP 2: Importing to Supabase...')
    print('-' * 60)
    
    try:
        supabase = get_supabase_client()
        print('✅ Connected to Supabase')
        
        total_inserted = 0
        total_skipped = 0
        
        # Process each file
        for idx, file_to_process in enumerate(files_to_process, 1):
            print(f'\n📄 Processing file {idx}/{len(files_to_process)}: {file_to_process.name}')
            print('-' * 60)
            
            result = upsert_csv_file(file_to_process, supabase)
            total_inserted += result["inserted"]
            total_skipped += result["skipped"]
        
        print()
        print('=' * 60)
        print('✅ DAILY UPDATE COMPLETE')
        print('=' * 60)
        print(f'📄 Files processed: {len(files_to_process)}')
        for f in files_to_process:
            print(f'   - {f.name}')
        print(f'📊 Total records processed: {total_inserted}')
        print(f'⚠️  Total records skipped: {total_skipped}')
        print(f'📅 Completed: {datetime.now()}')
        
        sys.exit(0)
        
    except Exception as e:
        print(f'❌ Import error: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()

