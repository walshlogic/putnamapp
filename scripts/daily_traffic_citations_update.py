#!/usr/bin/env python3
"""
Daily Traffic Citations Update Script
Combines download and import into a single automated process.

This script:
1. Downloads the latest Traffic History file from Clerk of Court
2. Imports it into Supabase using UPSERT logic (handles duplicates)
3. Can be run daily via cron/task scheduler
"""

import sys
from pathlib import Path
from datetime import datetime

# Import download and import functions
try:
    from download_traffic_citations import download_traffic_history
    from import_traffic_citations_upsert import main as import_main, get_supabase_client, upsert_csv_file
except ImportError as e:
    print(f'❌ Import error: {e}')
    print('   Make sure download_traffic_citations.py and import_traffic_citations_upsert.py are in the same directory')
    sys.exit(1)

def main():
    """Main daily update function"""
    print('=' * 60)
    print('🚀 DAILY TRAFFIC CITATIONS UPDATE')
    print('=' * 60)
    print(f'📅 Started: {datetime.now()}')
    print()
    
    script_dir = Path(__file__).parent
    if script_dir.name == 'zClerkDataUpdate':
        temp_data_dir = script_dir
    else:
        temp_data_dir = script_dir / 'zClerkDataUpdate'
    temp_data_dir.mkdir(exist_ok=True, parents=True)
    
    # Step 1: Download file
    print('📥 STEP 1: Downloading Traffic History file...')
    print('-' * 60)
    downloaded_file = download_traffic_history()
    
    if not downloaded_file:
        print('\n⚠️  Download failed, checking for existing files...')
        # Look for existing files (download_traffic_history already checked, but check again here as fallback)
        csv_files = list(temp_data_dir.glob('*traffic*.csv'))
        csv_files.extend(list(temp_data_dir.glob('*Traffic*.csv')))
        
        if csv_files:
            csv_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
            downloaded_file = csv_files[0]
            mtime = datetime.fromtimestamp(downloaded_file.stat().st_mtime)
            print(f'✅ Found existing file: {downloaded_file.name} (modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")})')
        else:
            print('❌ No files found. Cannot proceed.')
            print(f'\n💡 To download files manually:')
            print('   1. Visit https://apps.putnam-fl.com/bocc/putsubs/main.php')
            print('   2. Right-click "Traffic History" → "Download Subscription"')
            print(f'   3. Save to: {temp_data_dir}/traffic_history_YYYYMMDD.csv')
            sys.exit(1)
    
    print()
    
    # Step 2: Import file
    print('📊 STEP 2: Importing to Supabase...')
    print('-' * 60)
    
    try:
        supabase = get_supabase_client()
        print('✅ Connected to Supabase')
        
        result = upsert_csv_file(downloaded_file, supabase)
        
        print()
        print('=' * 60)
        print('✅ DAILY UPDATE COMPLETE')
        print('=' * 60)
        print(f'📄 File processed: {downloaded_file.name}')
        print(f'📊 Records processed: {result["inserted"]}')
        print(f'⚠️  Records skipped: {result["skipped"]}')
        print(f'📅 Completed: {datetime.now()}')
        
        sys.exit(0)
        
    except Exception as e:
        print(f'❌ Import error: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()

