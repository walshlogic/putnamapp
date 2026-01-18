#!/usr/bin/env python3
"""
Download Traffic Citations CSV from Clerk of Court website
Automatically downloads the monthly "Traffic History" file for daily updates.

This script needs to be customized based on how the Clerk of Court website works.
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

# Direct download URL if you can get it (right-click "Traffic History" link and copy URL)
TRAFFIC_HISTORY_DOWNLOAD_URL = os.getenv('TRAFFIC_HISTORY_DOWNLOAD_URL', '')

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

def download_file(url: str, output_path: Path, timeout: int = 300, method: str = 'GET', data: dict = None, headers: dict = None, session: requests.Session = None) -> bool:
    """
    Download a file from a URL (supports both GET and POST)
    
    Args:
        url: URL to download from
        output_path: Local path to save file
        timeout: Request timeout in seconds
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

def find_traffic_history_link(html_content: str, base_url: str) -> Optional[str]:
    """
    Parse HTML to find the Traffic History download link
    
    The website uses a right-click context menu system. We need to find:
    1. JavaScript functions that handle downloads
    2. API endpoints in JavaScript code
    3. Data attributes or IDs that identify the Traffic History dataset
    """
    try:
        import re
        
        # Pattern 1: Look for JavaScript download functions
        # Common patterns: downloadSubscription(id), downloadFile(id), etc.
        js_patterns = [
            r'downloadSubscription\s*\(\s*["\']?(\d+)["\']?\s*\)',  # downloadSubscription(3)
            r'downloadFile\s*\(\s*["\']?(\d+)["\']?\s*\)',
            r'function\s+\w*download\w*\s*\([^)]*\)\s*\{[^}]*["\'](\d+)["\']',
        ]
        
        # Pattern 2: Look for API endpoints in JavaScript
        api_patterns = [
            r'["\']([^"\']*download[^"\']*subscription[^"\']*)["\']',
            r'["\']([^"\']*api[^"\']*download[^"\']*)["\']',
            r'["\']([^"\']*putsubs[^"\']*download[^"\']*)["\']',
        ]
        
        # Pattern 3: Look for Traffic History dataset ID (from the table)
        # The table shows "3" for Traffic History
        traffic_history_id = '3'
        
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
        
        # Pattern 4: Try to construct download URL based on common patterns
        # Based on the website structure, try common download URL patterns
        base_path = base_url.rstrip('/')
        possible_urls = [
            f"{base_path}/download.php?id={traffic_history_id}",
            f"{base_path}/putsubs/download.php?id={traffic_history_id}",
            f"{base_path}/bocc/putsubs/download.php?id={traffic_history_id}",
            f"{base_path}/download_subscription.php?id={traffic_history_id}",
            f"{base_path}/putsubs/download_subscription.php?id={traffic_history_id}",
        ]
        
        # Try using BeautifulSoup if available for better parsing
        try:
            from bs4 import BeautifulSoup
            soup = BeautifulSoup(html_content, 'html.parser')
            
            # Look for table rows with Traffic History
            rows = soup.find_all('tr')
            for row in rows:
                cells = row.find_all('td')
                if len(cells) >= 2:
                    # Check if this row contains "Traffic History"
                    row_text = row.get_text().lower()
                    if 'traffic' in row_text and 'history' in row_text and 'weekly' not in row_text:
                        # Look for data attributes or IDs that might contain the subscription ID
                        row_id = row.get('id', '')
                        data_id = row.get('data-id', '')
                        
                        # Try to find download link in the row (actual <a> tags only)
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
        
        # Fallback: Try simple string search for href patterns (but validate them)
        pattern = r'href=["\']([^"\']*traffic[^"\']*history[^"\']*)["\']'
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

def extract_zip_file(zip_path: Path, extract_to: Path) -> Optional[Path]:
    """
    Extract ZIP file and find the CSV/TXT file inside
    
    Returns:
        Path to extracted CSV/TXT file, or None if failed
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
            
            # Find CSV or TXT files
            csv_files = []
            for f in file_list:
                file_path = extract_to / f
                if file_path.exists():
                    if f.lower().endswith('.csv') or f.lower().endswith('.txt'):
                        csv_files.append(file_path)
            
            if csv_files:
                # Return the first CSV/TXT file found
                return csv_files[0]
            else:
                print('⚠️  No CSV/TXT files found in ZIP')
                return None
                
    except zipfile.BadZipFile:
        print(f'❌ Invalid ZIP file: {zip_path}')
        return None
    except Exception as e:
        print(f'❌ Error extracting ZIP: {e}')
        import traceback
        traceback.print_exc()
        return None

def download_traffic_history() -> Optional[Path]:
    """
    Download Traffic History file from Clerk of Court website
    
    The file is downloaded as a ZIP (traffYR.zip) which needs to be extracted.
    Uses POST request to: https://apps.putnam-fl.com/bocc/putsubs/main.php?action=Subscriptions.download
    with subscription ID 3 (Traffic History)
    
    Returns:
        Path to extracted CSV file, or None if failed
    """
    print('🚀 Starting Traffic History download...')
    print(f'📅 Time: {datetime.now()}')
    print('-' * 60)
    
    # Method 1: Direct download URL (if configured - for GET requests)
    if TRAFFIC_HISTORY_DOWNLOAD_URL and not TRAFFIC_HISTORY_DOWNLOAD_URL.startswith('http'):
        # If it's just an ID, use POST method
        subscription_id = TRAFFIC_HISTORY_DOWNLOAD_URL
    elif TRAFFIC_HISTORY_DOWNLOAD_URL:
        print('📥 Using direct download URL (GET)...')
        filename = f'traffYR_{datetime.now().strftime("%Y%m%d")}.zip'
        zip_output_path = DOWNLOAD_DIR / filename
        
        if download_file(TRAFFIC_HISTORY_DOWNLOAD_URL, zip_output_path):
            # Extract ZIP file
            extracted_file = extract_zip_file(zip_output_path, DOWNLOAD_DIR)
            if extracted_file:
                return extracted_file
        return None
    else:
        subscription_id = '3'  # Default: Traffic History subscription ID
    
    # Method 2: Use POST request to download endpoint
    download_url = 'https://apps.putnam-fl.com/bocc/putsubs/main.php?action=Subscriptions.download'
    zip_filename = f'traffYR_{datetime.now().strftime("%Y%m%d")}.zip'
    zip_output_path = DOWNLOAD_DIR / zip_filename
    
    print(f'📥 Using POST request to download subscription ID: {subscription_id}')
    
    # Get session cookie first
    print('🍪 Getting session cookie...')
    session = get_session_cookie(CLERK_OF_COURT_URL)
    
    # POST data: id=3 for Traffic History
    post_data = {'id': subscription_id}
    
    if download_file(download_url, zip_output_path, method='POST', data=post_data, session=session):
        # Check if downloaded file is actually a ZIP
        if zipfile.is_zipfile(zip_output_path):
            print('✅ Downloaded ZIP file, extracting...')
            extracted_file = extract_zip_file(zip_output_path, DOWNLOAD_DIR)
            if extracted_file:
                return extracted_file
        else:
            # Might be CSV directly (legacy)
            print('⚠️  Downloaded file is not a ZIP, treating as CSV')
            return zip_output_path
    
    # Method 3: Check for existing ZIP files
    print('⚠️  POST download failed - checking for existing ZIP files...')
    zip_files = list(DOWNLOAD_DIR.glob('traffYR*.zip'))
    zip_files.extend(list(DOWNLOAD_DIR.glob('*traffic*.zip')))
    zip_files.extend(list(DOWNLOAD_DIR.glob('*Traffic*.zip')))
    
    if zip_files:
        zip_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        latest_zip = zip_files[0]
        mtime = datetime.fromtimestamp(latest_zip.stat().st_mtime)
        print(f'✅ Found existing ZIP file: {latest_zip.name} (modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")})')
        
        # Extract ZIP file
        extracted_file = extract_zip_file(latest_zip, DOWNLOAD_DIR)
        if extracted_file:
            return extracted_file
    
    # Method 4: Check for existing CSV files (already extracted)
    print('⚠️  No ZIP files found - checking for existing CSV files...')
    csv_files = list(DOWNLOAD_DIR.glob('*traffic*.csv'))
    csv_files.extend(list(DOWNLOAD_DIR.glob('*Traffic*.csv')))
    
    if csv_files:
        csv_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        latest_file = csv_files[0]
        mtime = datetime.fromtimestamp(latest_file.stat().st_mtime)
        print(f'✅ Found existing CSV file: {latest_file.name} (modified: {mtime.strftime("%Y-%m-%d %H:%M:%S")})')
        print('   Using existing file instead of downloading')
        return latest_file
    
    # No files found
    print(f'❌ No existing files found in {DOWNLOAD_DIR}')
    print('   The automated download requires authentication.')
    print('   Please manually download the file:')
    print('   1. Visit https://apps.putnam-fl.com/bocc/putsubs/main.php')
    print('   2. Right-click "Traffic History" → "Download Subscription"')
    print(f'   3. Save ZIP file to: {DOWNLOAD_DIR}/traffYR.zip')
    print('   4. The script will extract it automatically')
    return None

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
    global CLERK_OF_COURT_URL, TRAFFIC_HISTORY_DOWNLOAD_URL
    CLERK_OF_COURT_URL = os.getenv('CLERK_OF_COURT_URL', '')
    TRAFFIC_HISTORY_DOWNLOAD_URL = os.getenv('TRAFFIC_HISTORY_DOWNLOAD_URL', '')
    
    # Download file
    downloaded_file = download_traffic_history()
    
    if downloaded_file:
        print('-' * 60)
        print(f'✅ Success! File downloaded: {downloaded_file}')
        print(f'\n💡 Next step: Run import script')
        print(f'   python3 import_traffic_citations_upsert.py')
        sys.exit(0)
    else:
        print('-' * 60)
        print('❌ Download failed')
        print('\n💡 Options:')
        print('   1. Check .env file for CLERK_OF_COURT_URL or TRAFFIC_HISTORY_DOWNLOAD_URL')
    print('   2. Manually download file to zClerkDataUpdate/ folder')
        print('   3. Update download script with correct website structure')
        sys.exit(1)

if __name__ == '__main__':
    main()
