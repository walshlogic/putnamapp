#!/usr/bin/env python3
"""
Download Criminal Back History CSV from Clerk of Court website
Downloads the "Criminal Back History" dataset (ID: 2) from the subscription site.

This script attempts to download the file automatically, but may require
manual download if the website uses complex JavaScript authentication.
"""

import os
import sys
import requests
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Optional
from dotenv import load_dotenv

# =====================================================
# CONFIGURATION
# =====================================================

# Clerk of Court website URL
CLERK_OF_COURT_URL = os.getenv('CLERK_OF_COURT_URL', 'https://apps.putnam-fl.com/bocc/putsubs/main.php')

# Direct download URL if you can get it (right-click "Criminal Back History" link and copy URL)
CRIMINAL_BACK_HISTORY_DOWNLOAD_URL = os.getenv('CRIMINAL_BACK_HISTORY_DOWNLOAD_URL', '')

# Download directory (use zClerkDataUpdate folder)
script_dir = Path(__file__).parent
if script_dir.name == 'zClerkDataUpdate':
    DOWNLOAD_DIR = script_dir
else:
    DOWNLOAD_DIR = script_dir / 'zClerkDataUpdate'
DOWNLOAD_DIR.mkdir(exist_ok=True, parents=True)

# =====================================================
# FILE DOWNLOAD
# =====================================================

def get_session_cookie(base_url: str) -> requests.Session:
    """
    Get a session cookie by visiting the main page first
    
    Returns:
        requests.Session with cookies set
    """
    session = requests.Session()
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
        }
        session.get(base_url, headers=headers, timeout=30)
        return session
    except Exception as e:
        print(f'⚠️  Warning: Could not get session cookie: {e}')
        return session

def download_file(url: str, output_path: Path, timeout: int = 600, method: str = 'GET', data: dict = None, headers: dict = None, session: requests.Session = None) -> bool:
    """
    Download a file from a URL (supports both GET and POST)
    
    Args:
        url: URL to download from
        output_path: Local path to save file
        timeout: Request timeout in seconds (longer for large files)
        method: HTTP method ('GET' or 'POST')
        data: Data to send with POST request
        headers: Custom headers to include
        session: requests.Session object (for cookies)
    
    Returns:
        True if successful, False otherwise
    """
    try:
        print(f'📥 Downloading from: {url}')
        print(f'💾 Saving to: {output_path}')
        if method == 'POST':
            print(f'📤 Using POST method with data: {data}')
        
        # Default headers
        default_headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'Accept-Language': 'en-US,en;q=0.9',
            'X-Requested-With': 'XMLHttpRequest',
            'Origin': 'https://apps.putnam-fl.com',
            'Referer': 'https://apps.putnam-fl.com/bocc/putsubs/main.php',
        }
        
        if headers:
            default_headers.update(headers)
        
        # Use session if provided, otherwise create new request
        if session is None:
            session = requests
        
        # For POST requests, don't use stream initially to check JSON response
        # For GET requests, use stream for large files
        use_stream = method != 'POST'
        
        # Make request
        if method == 'POST':
            if isinstance(session, requests.Session):
                response = session.post(url, data=data, stream=use_stream, timeout=timeout, headers=default_headers)
            else:
                response = requests.post(url, data=data, stream=use_stream, timeout=timeout, headers=default_headers)
        else:
            if isinstance(session, requests.Session):
                response = session.get(url, stream=True, timeout=timeout, headers=default_headers)
            else:
                response = requests.get(url, stream=True, timeout=timeout, headers=default_headers)
        
        response.raise_for_status()
        
        # For POST requests, check content type first
        content_type = response.headers.get('content-type', '').lower()
        if method == 'POST':
            # Check if it's a ZIP file by content-type or file signature
            is_zip = False
            if 'application/zip' in content_type or 'application/x-zip-compressed' in content_type:
                is_zip = True
            elif len(response.content) >= 4:
                # Check ZIP file signature: PK\x03\x04
                if response.content[:4] == b'PK\x03\x04':
                    is_zip = True
                    print('   Detected ZIP file by signature')
            
            if is_zip:
                # Ensure output path has .zip extension
                if not output_path.suffix.lower() == '.zip':
                    output_path = output_path.with_suffix('.zip')
                
                # Save as ZIP file
                downloaded = len(response.content)
                with open(output_path, 'wb') as f:
                    f.write(response.content)
                print(f'✅ Download complete: {output_path.name}')
                print(f'   Size: {downloaded / 1024 / 1024:.2f} MB')
                print(f'   File type: ZIP')
                return True
            
            response_text = response.text.strip()
            
            # Check if it's JSON
            if 'application/json' in content_type or response_text.startswith('{') or response_text == 'null' or response_text.startswith('['):
                try:
                    import json
                    json_data = response.json()
                    print(f'⚠️  Server returned JSON response: {json_data}')
                    
                    # Check if JSON contains a download URL
                    if isinstance(json_data, dict):
                        if 'url' in json_data:
                            # Follow redirect URL
                            redirect_url = json_data['url']
                            print(f'🔄 Following redirect URL: {redirect_url}')
                            return download_file(redirect_url, output_path, timeout=timeout, method='GET', session=session)
                        elif 'error' in json_data:
                            print(f'❌ Server error: {json_data["error"]}')
                            return False
                        elif 'message' in json_data:
                            print(f'❌ Server message: {json_data["message"]}')
                            return False
                    
                    # If it's just null, might need session or different approach
                    if json_data is None or json_data == 'null':
                        print('⚠️  Server returned null - session cookie might not be working')
                        print('   The website may require authentication or a different approach')
                        return False
                except (ValueError, json.JSONDecodeError) as e:
                    print(f'⚠️  Could not parse JSON: {e}')
                    # Continue to try downloading as file
            
            # If not JSON or JSON parsing failed, write response content
            downloaded = len(response.content)
            if downloaded < 100:  # Less than 100 bytes is suspicious
                content_preview = response_text[:200]
                print(f'⚠️  Downloaded file is very small ({downloaded} bytes)')
                print(f'   Content preview: {content_preview}')
                if 'null' in content_preview.lower() or 'error' in content_preview.lower():
                    return False
            
            with open(output_path, 'wb') as f:
                f.write(response.content)
            
            print(f'✅ Download complete: {output_path.name}')
            print(f'   Size: {downloaded / 1024 / 1024:.2f} MB')
            return True
        
        # For GET requests, use streaming download
        # Get file size if available
        total_size = int(response.headers.get('content-length', 0))
        if total_size > 0:
            print(f'📊 File size: {total_size / 1024 / 1024:.2f} MB')
        
        # Download with progress
        downloaded = 0
        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0 and downloaded % (1024 * 1024 * 10) == 0:  # Print every 10 MB
                        percent = (downloaded / total_size) * 100
                        print(f'   Progress: {percent:.1f}% ({downloaded / 1024 / 1024:.1f} MB)')
        
        # Check if file is too small (likely an error)
        if downloaded < 100:  # Less than 100 bytes is suspicious
            print(f'⚠️  Downloaded file is very small ({downloaded} bytes)')
            return False
        
        print(f'✅ Download complete: {output_path.name}')
        print(f'   Size: {downloaded / 1024 / 1024:.2f} MB')
        return True
        
    except requests.exceptions.RequestException as e:
        print(f'❌ Download error: {e}')
        return False
    except Exception as e:
        print(f'❌ Unexpected error: {e}')
        import traceback
        traceback.print_exc()
        return False

def find_criminal_back_history_link(html_content: str, base_url: str) -> Optional[str]:
    """
    Parse HTML to find the Criminal Back History download link
    
    The website shows dataset ID "2" for Criminal Back History.
    """
    try:
        import re
        
        # Pattern 1: Look for API endpoints in JavaScript
        api_patterns = [
            r'["\']([^"\']*download[^"\']*subscription[^"\']*)["\']',
            r'["\']([^"\']*api[^"\']*download[^"\']*)["\']',
            r'["\']([^"\']*putsubs[^"\']*download[^"\']*)["\']',
        ]
        
        # Criminal Back History dataset ID (from the table)
        criminal_back_history_id = '2'
        
        # Try to find download URL patterns
        for pattern in api_patterns:
            matches = re.findall(pattern, html_content, re.IGNORECASE)
            for match in matches:
                if match and ('download' in match.lower() or 'api' in match.lower()):
                    if match.startswith('http'):
                        return match
                    elif match.startswith('/'):
                        base = base_url.rstrip('/')
                        return f"{base}{match}"
                    else:
                        base = base_url.rstrip('/')
                        return f"{base}/{match}"
        
        # Pattern 2: Try to construct download URL based on common patterns
        base_path = base_url.rstrip('/')
        possible_urls = [
            f"{base_path}/download.php?id={criminal_back_history_id}",
            f"{base_path}/putsubs/download.php?id={criminal_back_history_id}",
            f"{base_path}/bocc/putsubs/download.php?id={criminal_back_history_id}",
            f"{base_path}/download_subscription.php?id={criminal_back_history_id}",
            f"{base_path}/putsubs/download_subscription.php?id={criminal_back_history_id}",
        ]
        
        # Try using BeautifulSoup if available
        try:
            from bs4 import BeautifulSoup
            soup = BeautifulSoup(html_content, 'html.parser')
            
            # Look for table rows with Criminal Back History
            rows = soup.find_all('tr')
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 2:
                    # Check if this row contains "Criminal Back History"
                    row_text = row.get_text().lower()
                    if 'criminal' in row_text and 'back' in row_text and 'history' in row_text:
                        # Look for download link in the row (actual <a> tags only)
                        links = row.find_all('a', href=True)
                        for link in links:
                            href = link.get('href', '').strip()
                            # Validate it's a real URL, not HTML text
                            if href and href.startswith(('http://', 'https://', '/', '?')):
                                # Make sure it's not HTML text
                                if '<' not in href and '>' not in href and 'strong' not in href.lower():
                                    if href.startswith('http'):
                                        return href
                                    elif href.startswith('/'):
                                        return f"{base_path}{href}"
                                    elif href.startswith('?'):
                                        return f"{base_path}{href}"
        except ImportError:
            pass
        
        # Fallback: Try simple string search (but validate them)
        pattern = r'href=["\']([^"\']*criminal[^"\']*back[^"\']*history[^"\']*)["\']'
        matches = re.findall(pattern, html_content, re.IGNORECASE)
        for match in matches:
            href = match.strip()
            # Validate it's a real URL, not HTML text
            if href and '<' not in href and '>' not in href and 'strong' not in href.lower():
                if href.startswith('http'):
                    return href
                elif href.startswith('/'):
                    base = base_url.rstrip('/')
                    return f"{base}{href}"
                elif href.startswith('?'):
                    base = base_url.rstrip('/')
                    return f"{base}{href}"
        
        # Don't return invalid URLs - return None instead
        return None
        
    except Exception as e:
        print(f'⚠️  Error parsing HTML: {e}')
        return None

def extract_zip_file(zip_path: Path, extract_to: Path) -> list[Path]:
    """
    Extract ZIP file and find all CSV/TXT files inside
    
    Returns:
        List of paths to extracted CSV/TXT files (excluding help.txt), or empty list if failed
    """
    try:
        print(f'📦 Extracting ZIP file: {zip_path.name}')
        
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            # List all files in ZIP
            file_list = zip_ref.namelist()
            print(f'   Found {len(file_list)} file(s) in ZIP:')
            for f in file_list:
                print(f'     - {f}')
            
            # Extract all files
            zip_ref.extractall(extract_to)
            print(f'✅ Extracted to: {extract_to}')
            
            # Find CSV or TXT files (excluding help.txt)
            csv_files = []
            for f in file_list:
                file_path = extract_to / f
                if file_path.exists():
                    if (f.lower().endswith('.csv') or f.lower().endswith('.txt')) and f.lower() != 'help.txt':
                        csv_files.append(file_path)
            
            if csv_files:
                print(f'✅ Found {len(csv_files)} data file(s) to process')
                return csv_files
            else:
                print('⚠️  No CSV/TXT files found in ZIP (excluding help.txt)')
                return []
                
    except zipfile.BadZipFile:
        print(f'❌ Invalid ZIP file: {zip_path}')
        return []
    except Exception as e:
        print(f'❌ Error extracting ZIP: {e}')
        import traceback
        traceback.print_exc()
        return []

def download_criminal_back_history() -> list[Path]:
    """
    Download Criminal Back History file from Clerk of Court website
    
    The file is downloaded as a ZIP (criminal_HS.zip or criminal_YR.zip) which needs to be extracted.
    Uses POST request to: https://apps.putnam-fl.com/bocc/putsubs/main.php?action=Subscriptions.download
    with subscription ID 2 (Criminal Back History)
    
    Returns:
        List of paths to extracted TXT/CSV files, or empty list if failed
    """
    print('🚀 Starting Criminal Back History download...')
    print(f'📅 Time: {datetime.now()}')
    print('-' * 60)
    
    # Method 1: Direct download URL (if configured - for GET requests)
    if CRIMINAL_BACK_HISTORY_DOWNLOAD_URL and not CRIMINAL_BACK_HISTORY_DOWNLOAD_URL.startswith('http'):
        # If it's just an ID, use POST method
        subscription_id = CRIMINAL_BACK_HISTORY_DOWNLOAD_URL
    elif CRIMINAL_BACK_HISTORY_DOWNLOAD_URL:
        print('📥 Using direct download URL (GET)...')
        filename = f'criminal_HS_{datetime.now().strftime("%Y%m%d")}.zip'
        zip_output_path = DOWNLOAD_DIR / filename
        
        if download_file(CRIMINAL_BACK_HISTORY_DOWNLOAD_URL, zip_output_path):
            # Extract ZIP file
            extracted_files = extract_zip_file(zip_output_path, DOWNLOAD_DIR)
            if extracted_files:
                return extracted_files
        return []
    else:
        subscription_id = '2'  # Default: Criminal Back History subscription ID
    
    # Method 2: Use POST request to download endpoint
    download_url = 'https://apps.putnam-fl.com/bocc/putsubs/main.php?action=Subscriptions.download'
    zip_filename = f'criminal_HS_{datetime.now().strftime("%Y%m%d")}.zip'
    zip_output_path = DOWNLOAD_DIR / zip_filename
    
    print(f'📥 Using POST request to download subscription ID: {subscription_id}')
    
    # Get session cookie first
    print('🍪 Getting session cookie...')
    session = get_session_cookie(CLERK_OF_COURT_URL)
    
    # POST data: id=2 for Criminal Back History
    post_data = {'id': subscription_id}
    
    if download_file(download_url, zip_output_path, method='POST', data=post_data, session=session):
        # Check if downloaded file is actually a ZIP
        if zipfile.is_zipfile(zip_output_path):
            print('✅ Downloaded ZIP file, extracting...')
            extracted_files = extract_zip_file(zip_output_path, DOWNLOAD_DIR)
            if extracted_files:
                return extracted_files
        else:
            # Might be TXT directly (legacy)
            print('⚠️  Downloaded file is not a ZIP, treating as TXT')
            return [zip_output_path]
    
    # Method 3: Check for existing ZIP files (criminal_HS.zip or criminal_YR.zip)
    print('⚠️  POST download failed - checking for existing ZIP files...')
    zip_files = list(DOWNLOAD_DIR.glob('criminal_HS*.zip'))
    zip_files.extend(list(DOWNLOAD_DIR.glob('criminal_YR*.zip')))
    zip_files.extend(list(DOWNLOAD_DIR.glob('*criminal*.zip')))
    zip_files.extend(list(DOWNLOAD_DIR.glob('*Criminal*.zip')))
    
    if zip_files:
        zip_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        latest_zip = zip_files[0]
        mtime = datetime.fromtimestamp(latest_zip.stat().st_mtime)
        print(f'✅ Found existing ZIP file: {latest_zip.name} (modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")})')
        
        # Extract ZIP file
        extracted_files = extract_zip_file(latest_zip, DOWNLOAD_DIR)
        if extracted_files:
            return extracted_files
    
    # Method 4: Check for existing TXT files (already extracted or legacy)
    print('⚠️  No ZIP files found - checking for existing TXT files...')
    txt_files = list(DOWNLOAD_DIR.glob('*criminal*.txt'))
    txt_files.extend(list(DOWNLOAD_DIR.glob('*Criminal*.txt')))
    
    # Also check in criminal_YR folder
    yr_folder = DOWNLOAD_DIR / 'criminal_YR'
    if yr_folder.exists():
        txt_files.extend(list(yr_folder.glob('*.txt')))
        txt_files.extend(list(yr_folder.glob('*.csv')))
    
    # Filter out help.txt
    txt_files = [f for f in txt_files if f.name.lower() != 'help.txt']
    
    if txt_files:
        txt_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        print(f'✅ Found {len(txt_files)} existing TXT file(s)')
        for f in txt_files:
            mtime = datetime.fromtimestamp(f.stat().st_mtime)
            print(f'   - {f.name} (modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")})')
        print('   Using existing files instead of downloading')
        return txt_files
    
    # No files found
    print(f'❌ No existing files found in {DOWNLOAD_DIR}')
    print('   The automated download requires authentication.')
    print('   Please manually download the file:')
    print('   1. Visit https://apps.putnam-fl.com/bocc/putsubs/main.php')
    print('   2. Right-click "Criminal Back History" → "Download Subscription"')
    print(f'   3. Save ZIP file to: {DOWNLOAD_DIR}/criminal_HS.zip')
    print('   4. The script will extract it automatically')
    return []

# =====================================================
# MAIN EXECUTION
# =====================================================

def main():
    """Main download function"""
    # Load environment variables
    script_dir = Path(__file__).parent
    project_root = script_dir if (script_dir / 'assets').exists() else script_dir.parent
    env_path = project_root / 'assets' / '.env'
    
    if env_path.exists():
        load_dotenv(env_path)
        print(f'✅ Loaded environment variables from {env_path}')
    else:
        load_dotenv()
        print('⚠️  assets/.env not found, trying current directory .env')
    
    # Update global config from env
    global CLERK_OF_COURT_URL, CRIMINAL_BACK_HISTORY_DOWNLOAD_URL
    CLERK_OF_COURT_URL = os.getenv('CLERK_OF_COURT_URL', CLERK_OF_COURT_URL)
    CRIMINAL_BACK_HISTORY_DOWNLOAD_URL = os.getenv('CRIMINAL_BACK_HISTORY_DOWNLOAD_URL', '')
    
    # Download file
    downloaded_file = download_criminal_back_history()
    
    if downloaded_file:
        print('-' * 60)
        print(f'✅ Success! File downloaded: {downloaded_file}')
        print(f'\n💡 Next step: Run import script')
        print(f'   python3 import_criminal_back_history.py')
        sys.exit(0)
    else:
        print('-' * 60)
        print('❌ Download failed')
        print('\n💡 Options:')
        print('   1. Check .env file for CLERK_OF_COURT_URL or CRIMINAL_BACK_HISTORY_DOWNLOAD_URL')
        print('   2. Manually download file to zClerkDataUpdate/ folder')
        print('   3. Update download script with correct website structure')
        sys.exit(1)

if __name__ == '__main__':
    main()
