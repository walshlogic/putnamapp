# ZIP File Automation Guide

## Overview

The Clerk of Court website downloads files as **ZIP archives** (e.g., `traffYR.zip`), not direct CSV files. The updated scripts now handle ZIP extraction automatically.

## Updated Process Flow

1. **Download ZIP file** → `traffYR.zip` (or similar)
2. **Extract ZIP** → Find CSV/TXT file inside
3. **Import to Supabase** → Parse CSV and upsert records
4. **App reads from Supabase** → Display data to users

## Updated Scripts

### `download_traffic_citations.py`
- ✅ Downloads ZIP files (`.zip` extension)
- ✅ Automatically extracts ZIP archives
- ✅ Finds CSV/TXT files inside ZIP
- ✅ Returns path to extracted CSV file
- ✅ Handles both ZIP and legacy CSV formats

### `daily_traffic_citations_update.py`
- ✅ Calls download script (handles ZIP extraction)
- ✅ Uses extracted CSV file for import
- ✅ Imports to Supabase `traffic_citations` table

## How It Works

### ZIP Extraction Function

```python
def extract_zip_file(zip_path: Path, extract_to: Path) -> Optional[Path]:
    """
    Extract ZIP file and find the CSV/TXT file inside
    """
    # 1. Open ZIP file
    # 2. List all files inside
    # 3. Extract all files
    # 4. Find CSV/TXT files
    # 5. Return path to CSV/TXT file
```

### Download Process

1. **POST Request** → Downloads ZIP file from website
2. **Content-Type Check** → Detects `application/zip`
3. **Save ZIP** → Saves as `traffYR_YYYYMMDD.zip`
4. **Extract** → Extracts to `zClerkDataUpdate/` folder
5. **Find CSV** → Locates CSV/TXT file inside ZIP
6. **Return Path** → Returns path to CSV for import

## File Structure

```
zClerkDataUpdate/
├── traffYR_20260113.zip          # Downloaded ZIP file
├── traffYR.csv                    # Extracted CSV file (or similar name)
└── traffic_history_20260113.csv  # Legacy CSV (if direct download)
```

## Testing

### Test ZIP Extraction

```bash
# Place a ZIP file in zClerkDataUpdate/
cd /Users/willwalsh/PutnamApp/App
python3 zClerkDataUpdate/daily_traffic_citations_update.py
```

The script will:
1. Find the ZIP file
2. Extract it
3. Find the CSV inside
4. Import to Supabase

### Manual Test

```bash
# Test extraction function directly
python3 -c "
from pathlib import Path
from download_traffic_citations import extract_zip_file
zip_path = Path('zClerkDataUpdate/traffYR.zip')
if zip_path.exists():
    csv_file = extract_zip_file(zip_path, Path('zClerkDataUpdate'))
    print(f'Extracted: {csv_file}')
else:
    print('ZIP file not found')
"
```

## Troubleshooting

### ZIP File Not Found
- Check `zClerkDataUpdate/` folder exists
- Verify ZIP file name matches pattern: `traffYR*.zip` or `*traffic*.zip`

### No CSV in ZIP
- Check ZIP contents: `unzip -l zClerkDataUpdate/traffYR.zip`
- Verify CSV/TXT file exists inside ZIP
- Script will list all files found in ZIP

### Extraction Fails
- Verify ZIP file is not corrupted
- Check file permissions on `zClerkDataUpdate/` folder
- Ensure Python `zipfile` module is available

## Next Steps for Full Automation

To fully automate the process, you need to:

1. **Get Session Cookie Working** - The POST request currently returns `null`
   - Option A: Use browser automation (Selenium/Playwright)
   - Option B: Extract session cookie from browser manually
   - Option C: Contact website admin for API access

2. **Browser Automation** (Recommended)
   ```python
   from selenium import webdriver
   # Navigate to page
   # Right-click download
   # Save ZIP file
   # Extract and import
   ```

3. **Manual Process** (Current)
   - Download ZIP manually
   - Place in `zClerkDataUpdate/`
   - Run import script
   - Script extracts and imports automatically

## Benefits of ZIP Support

✅ **Handles actual file format** - Works with real downloads  
✅ **Automatic extraction** - No manual unzipping needed  
✅ **Backward compatible** - Still works with CSV files  
✅ **Error detection** - Validates ZIP files before extraction  
✅ **File listing** - Shows what's inside ZIP for debugging  
