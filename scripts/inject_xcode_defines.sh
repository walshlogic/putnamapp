#!/usr/bin/env bash
# Inject keys from flutter_env.json as base64-encoded entries into the
# DART_DEFINES line of ios/Flutter/Generated.xcconfig, so Xcode builds
# (Run button, Archive, etc.) pick up the same Supabase/RevenueCat/Weather
# config that ./scripts/run_*_on_device.sh would pass via --dart-define.
#
# Idempotent: existing entries for our keys are removed before re-adding,
# so running this script every build doesn't duplicate. Flutter's own
# system defines (FLUTTER_VERSION, FLUTTER_CHANNEL, etc.) are preserved.
#
# Wired in as a PreAction on the Runner BuildAction in Runner.xcscheme,
# so it runs automatically every time you click Run/Build/Archive in Xcode.
#
# Manual invocation:
#   ./scripts/inject_xcode_defines.sh
#
# Useful when the script is run outside Xcode (e.g., debugging) or to
# pre-warm Generated.xcconfig before the first Xcode build.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="$REPO_DIR/flutter_env.json"
XCCONFIG="$REPO_DIR/ios/Flutter/Generated.xcconfig"

OUR_KEYS=(SUPABASE_URL SUPABASE_ANON_KEY REVENUECAT_IOS_API_KEY REVENUECAT_ANDROID_API_KEY WEATHER_LAT WEATHER_LON)

if [[ ! -f "$ENV_FILE" ]]; then
  echo "▶ inject_xcode_defines: $ENV_FILE not found — skipping (build will fail at runtime if defines are required)" >&2
  exit 0
fi

if [[ ! -f "$XCCONFIG" ]]; then
  echo "▶ inject_xcode_defines: $XCCONFIG not found — run 'flutter pub get' first to generate it" >&2
  exit 0
fi

python3 - "$ENV_FILE" "$XCCONFIG" "${OUR_KEYS[@]}" <<'PY'
import base64, json, re, sys

env_path, xcconfig_path = sys.argv[1], sys.argv[2]
our_keys = sys.argv[3:]
env = json.load(open(env_path))

with open(xcconfig_path) as f:
    lines = f.read().splitlines()

# Find the DART_DEFINES line. Format: DART_DEFINES=b64entry,b64entry,...
def_idx = next((i for i, l in enumerate(lines) if l.startswith('DART_DEFINES=')), None)

if def_idx is None:
    # No DART_DEFINES line yet — append a fresh one with our entries.
    existing = []
else:
    raw = lines[def_idx][len('DART_DEFINES='):].strip()
    existing = [e for e in raw.split(',') if e]

# Drop any prior entries for our keys (idempotency).
def is_ours(b64entry):
    try:
        decoded = base64.b64decode(b64entry).decode('utf-8', errors='replace')
    except Exception:
        return False
    name = decoded.split('=', 1)[0]
    return name in our_keys

kept = [e for e in existing if not is_ours(e)]

# Append fresh entries from flutter_env.json (skip blank/missing values).
added = []
for k in our_keys:
    v = env.get(k, '')
    if not v:
        continue
    encoded = base64.b64encode(f'{k}={v}'.encode()).decode()
    added.append(encoded)

merged_line = 'DART_DEFINES=' + ','.join(kept + added)

if def_idx is None:
    lines.append(merged_line)
else:
    lines[def_idx] = merged_line

with open(xcconfig_path, 'w') as f:
    f.write('\n'.join(lines) + '\n')

print(f'▶ inject_xcode_defines: kept {len(kept)} system defines, injected {len(added)} app defines into DART_DEFINES')
PY
