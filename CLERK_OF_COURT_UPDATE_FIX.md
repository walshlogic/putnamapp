# Clerk of Court Data Update Fix

## Problem Summary

The Clerk of Court data updates stopped working:
- **Traffic Citations**: Last updated 10/30/2025
- **Criminal History**: Last updated 11/14/2025

However, new data is available on the website:
- Traffic History: Last Updated 01-01-2026
- Traffic Tickets - Weekly: Last Updated 01-11-2026
- Criminal Back History: Last Updated 01-01-2026

## Root Causes Identified

1. **Wrong Cron Job Script**: The cron job was running `import_traffic_citations_upsert.py` (import only) instead of `daily_traffic_citations_update.py` (download + import)
2. **No Automated Download for Criminal History**: Criminal history relied on manual file downloads
3. **Website Download Mechanism**: The website uses a right-click context menu system, which requires proper URL detection

## Files Updated

1. **`setup_daily_cron.sh`**: Fixed to use `daily_traffic_citations_update.py` instead of `import_traffic_citations_upsert.py`
2. **`download_traffic_citations.py`**: Enhanced to better handle the website's download mechanism
3. **`download_criminal_back_history.py`**: NEW - Created script to automatically download criminal back history files
4. **`daily_criminal_back_history_update.py`**: Updated to include download step before import

## How to Fix

### Step 1: Update Cron Jobs

Run the setup script to update your cron jobs:

```bash
cd /Users/willwalsh/PutnamApp/App
bash setup_daily_cron.sh
```

This will:
- Replace the old traffic citations cron job with the correct one
- Keep the criminal history cron job (which now includes download)

### Step 2: Test the Scripts Manually

Before relying on cron, test the scripts manually:

#### Test Traffic Citations:
```bash
cd /Users/willwalsh/PutnamApp/App
python3 zClerkDataUpdate/daily_traffic_citations_update.py
```

#### Test Criminal Back History:
```bash
cd /Users/willwalsh/PutnamApp/App
python3 zClerkDataUpdate/daily_criminal_back_history_update.py
```

### Step 3: Configure Download (Optional)

The scripts now automatically use POST requests to download files. The subscription IDs are:
- **Traffic History**: ID 3
- **Criminal Back History**: ID 2

The scripts will automatically use these IDs. However, if you want to override them, you can add to your `.env` file:
```
TRAFFIC_HISTORY_DOWNLOAD_URL=3
CRIMINAL_BACK_HISTORY_DOWNLOAD_URL=2
```

**Note**: The scripts now use POST requests to `https://apps.putnam-fl.com/bocc/putsubs/main.php?action=Subscriptions.download` with the subscription ID, so no manual URL extraction is needed!

### Step 4: Verify Cron Jobs

Check that cron jobs are set up correctly:

```bash
crontab -l | grep -E "(traffic|criminal)"
```

You should see:
- Traffic citations: Runs at 2:00 AM daily using `daily_traffic_citations_update.py`
- Criminal history: Runs at 3:00 AM daily using `daily_criminal_back_history_update.py`

### Step 5: Monitor Logs

Check the logs to ensure scripts are running:

```bash
# View traffic citations log
tail -f /Users/willwalsh/PutnamApp/App/logs/traffic_citations_import.log

# View criminal history log
tail -f /Users/willwalsh/PutnamApp/App/logs/criminal_back_history_import.log
```

## Manual Download (Fallback)

If automated download fails, you can manually download files:

1. **Traffic History**:
   - Download from website to `zClerkDataUpdate/` folder
   - Run: `python3 zClerkDataUpdate/import_traffic_citations_upsert.py`

2. **Criminal Back History**:
   - Download from website to `zClerkDataUpdate/` folder
   - Run: `python3 zClerkDataUpdate/import_criminal_back_history.py`

## Troubleshooting

### Scripts Can't Find Download URLs

If the scripts can't automatically find download URLs:
1. Use browser developer tools (F12) → Network tab
2. Right-click and download a file
3. Find the download request in the Network tab
4. Copy the URL and add it to `.env`

### Download Fails with 403/401 Errors

The website may require authentication or cookies. Options:
1. Use direct download URLs (see Step 3 above)
2. Consider using Selenium/Playwright for browser automation (more complex)
3. Continue with manual downloads

### Files Downloaded But Not Imported

Check:
1. File format matches expected format (pipe-delimited for criminal, CSV for traffic)
2. Supabase credentials are correct in `.env`
3. File permissions allow reading
4. Check import logs for specific errors

## Next Steps

1. ✅ Update cron jobs using `setup_daily_cron.sh`
2. ✅ Test scripts manually
3. ⏳ Get direct download URLs and add to `.env`
4. ⏳ Monitor logs for a few days to ensure updates are working
5. ⏳ Verify data appears in the app

## Notes

- The website shows "Last Updated" dates, but files may be updated more frequently
- Traffic History is a large file (full history), Traffic Tickets - Weekly is smaller
- Criminal Back History is updated less frequently than Traffic Citations
- Both scripts use UPSERT logic, so running them multiple times is safe
