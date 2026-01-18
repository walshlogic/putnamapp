# Clerk Data Update (Manual ZIP)

This folder contains the scripts and data files used to update Clerk of Court
records in Supabase. Keep ZIP files and extracted TXT/CSV files in this same
folder.

## Setup

- Ensure `assets/.env` exists in the project root with:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
- Install Python deps (prevents the urllib3 LibreSSL warning):
  - `pip3 install -r ../requirements_traffic_citations.txt`
  - Optional:
    - `CLERK_OF_COURT_URL`
    - `TRAFFIC_HISTORY_DOWNLOAD_URL`
    - `CRIMINAL_BACK_HISTORY_DOWNLOAD_URL`

## Manual Update Process

1. Download the latest ZIP file(s) from the Clerk of Court site.
2. Save the ZIP(s) into this folder:
   - Traffic: `traffYR.zip` (or similar)
   - Criminal: `criminal_HS.zip` / `criminal_YR.zip`
3. Run the single script from this folder:
   - All-in-one:
     - `python3 clerk_data_update_all.py`
    
*************************************************
** Walsh Note: To run the script from terminal **
   python3 daily_traffic_citations_update.py
*************************************************

The script will:
- Extract ZIP files into this folder
- Locate the newest TXT/CSV files
- UPSERT the data into Supabase
  - UPSERT uses `case_number` as the unique key, so reprocessing files is safe
- Auto-delete processed ZIP/TXT/help files after a successful run

## Optional Direct Import (No Download)

- Traffic only (optional):
  - Yearly: `python3 import_traffic_citations_upsert.py`
  - Weekly: `python3 import_traffic_weekly_upsert.py`
- Criminal only (optional):
  - `python3 import_criminal_back_history.py`

These will import the latest extracted TXT/CSV files found in this folder.
