#!/usr/bin/env bash
# Build + install + launch the app on a connected device in release mode,
# forwarding all flutter_env.json values as --dart-define.
#
# Usage:
#   ./run_release_on_device.sh                # picks first iOS device found
#   ./run_release_on_device.sh <device-id>    # use specific device
#
# List devices: flutter devices
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

ENV_FILE="flutter_env.json"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ $ENV_FILE not found" >&2
  exit 1
fi

DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID=$(/opt/homebrew/bin/flutter devices --machine 2>/dev/null \
              | python3 -c "
import json, sys
try:
    for d in json.load(sys.stdin):
        if d.get('targetPlatform','').startswith('ios') and d.get('emulator') is False:
            print(d['id']); break
except Exception:
    pass
")
  [[ -z "$DEVICE_ID" ]] && { echo "❌ no iOS device detected. connect one or pass id"; exit 2; }
  echo "▶ auto-picked device: $DEVICE_ID"
fi

DEFINES=()
while IFS= read -r line; do
  DEFINES+=("$line")
done < <(python3 -c "
import json
d = json.load(open('$ENV_FILE'))
for k in ('SUPABASE_URL','SUPABASE_ANON_KEY','REVENUECAT_IOS_API_KEY','REVENUECAT_ANDROID_API_KEY','WEATHER_LAT','WEATHER_LON'):
    if d.get(k): print(f'--dart-define={k}={d[k]}')
")

echo "▶ flutter run --release -d $DEVICE_ID (with ${#DEFINES[@]} --dart-define args)"
exec /opt/homebrew/bin/flutter run --release -d "$DEVICE_ID" "${DEFINES[@]}"
