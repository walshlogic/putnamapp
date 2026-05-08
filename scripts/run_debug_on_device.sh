#!/usr/bin/env bash
# Build + install + launch the app on a connected device or simulator in
# debug mode, forwarding all flutter_env.json values as --dart-define.
#
# Usage:
#   ./scripts/run_debug_on_device.sh                # let flutter pick (simulator if running, else first device)
#   ./scripts/run_debug_on_device.sh <device-id>    # use specific device or simulator
#
# For release-on-device builds (no debug banner, used pre-TestFlight): use run_release_on_device.sh
# List devices: flutter devices
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

ENV_FILE="flutter_env.json"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ $ENV_FILE not found at $REPO_DIR" >&2
  exit 1
fi

DEVICE_ID="${1:-}"

DEFINES=()
while IFS= read -r line; do
  DEFINES+=("$line")
done < <(python3 -c "
import json
d = json.load(open('$ENV_FILE'))
for k in ('SUPABASE_URL','SUPABASE_ANON_KEY','REVENUECAT_IOS_API_KEY','REVENUECAT_ANDROID_API_KEY','WEATHER_LAT','WEATHER_LON'):
    if d.get(k): print(f'--dart-define={k}={d[k]}')
")

if [[ -n "$DEVICE_ID" ]]; then
  echo "▶ flutter run -d $DEVICE_ID (debug, with ${#DEFINES[@]} --dart-define args)"
  exec /opt/homebrew/bin/flutter run -d "$DEVICE_ID" "${DEFINES[@]}"
else
  echo "▶ flutter run (debug, with ${#DEFINES[@]} --dart-define args; flutter picks the device)"
  exec /opt/homebrew/bin/flutter run "${DEFINES[@]}"
fi
