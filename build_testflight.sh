#!/usr/bin/env bash
# Build a release IPA for TestFlight.
#
# Reads flutter_env.json (gitignored — contains Supabase/RevenueCat/Weather keys)
# and forwards every key as --dart-define so AppConfig.String.fromEnvironment
# resolves at compile time. This matches the pattern Apple's TestFlight IPAs
# need since the app expects all config at build time, not runtime.
#
# Usage:
#   ./build_testflight.sh                # full IPA build
#   ./build_testflight.sh --verify       # pre-flight: validate env + clean output
#
# Output: build/ios/ipa/Runner.ipa (or putnamlife.ipa depending on pubspec)
# Upload step after this script:
#   Option A (GUI): open Transporter.app on macOS, drag the .ipa in, Deliver.
#   Option B (CLI): xcrun altool --upload-app --type ios -f <path> \
#                   --apiKey <id> --apiIssuer <uuid>
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

ENV_FILE="flutter_env.json"
REQUIRED_KEYS=(SUPABASE_URL SUPABASE_ANON_KEY)
OPTIONAL_KEYS=(REVENUECAT_IOS_API_KEY REVENUECAT_ANDROID_API_KEY WEATHER_LAT WEATHER_LON)

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ $ENV_FILE not found at $(pwd)" >&2
  echo "   (gitignored — restore from a backup or reconstruct from Supabase dashboard)" >&2
  exit 1
fi

# Build --dart-define args; fail hard if required keys are missing or empty.
DEFINES=()
while IFS= read -r line; do
  DEFINES+=("$line")
done < <(python3 - "$ENV_FILE" "${REQUIRED_KEYS[@]}" -- "${OPTIONAL_KEYS[@]}" <<'PY'
import json, sys
path = sys.argv[1]
args = sys.argv[2:]
sep_idx = args.index('--')
required = args[:sep_idx]
optional = args[sep_idx+1:]
d = json.load(open(path))
missing = [k for k in required if not d.get(k)]
if missing:
    sys.stderr.write(f"❌ missing required keys in {path}: {', '.join(missing)}\n")
    sys.exit(2)
for k in required + optional:
    v = d.get(k, '')
    if v:
        print(f"--dart-define={k}={v}")
PY
)

if [[ "${1:-}" == "--verify" ]]; then
  echo "✅ env file: $ENV_FILE"
  echo "✅ dart-define keys populated: ${#DEFINES[@]}"
  # Show only key names, never values
  python3 -c "
import json, sys
d = json.load(open('$ENV_FILE'))
for k, v in d.items():
    print(f'   {k}: {len(str(v))} chars')
"
  echo
  echo "✅ ready to build. Run without --verify to produce the IPA."
  exit 0
fi

echo "▶ flutter clean"
/opt/homebrew/bin/flutter clean > /dev/null

# Try online pub get first; if it fails (e.g., pub.dev advisories endpoint
# returning 403 on some networks), fall back to --offline using cached deps.
echo "▶ flutter pub get"
if ! /opt/homebrew/bin/flutter pub get > /dev/null 2>&1; then
  echo "   online pub get failed — retrying with --offline (uses ~/.pub-cache)"
  /opt/homebrew/bin/flutter pub get --offline > /dev/null
  PUB_OFFLINE=1
else
  PUB_OFFLINE=0
fi

# When pub get came from cache, also pass --no-pub to flutter build so it
# doesn't re-run a network pub get internally and crash on the same 403.
BUILD_FLAGS=()
[[ "$PUB_OFFLINE" == "1" ]] && BUILD_FLAGS+=(--no-pub)

echo "▶ flutter build ipa --release ${BUILD_FLAGS[*]} (with ${#DEFINES[@]} --dart-define args)"
/opt/homebrew/bin/flutter build ipa --release "${BUILD_FLAGS[@]}" "${DEFINES[@]}"

IPA=$(ls -t "$REPO"/build/ios/ipa/*.ipa 2>/dev/null | head -1)
if [[ -z "$IPA" ]]; then
  echo "❌ build completed but no IPA found under build/ios/ipa/" >&2
  exit 3
fi

echo
echo "✅ IPA ready: $IPA"
echo "   size: $(du -h "$IPA" | cut -f1)"
echo
echo "📤 next step — upload to App Store Connect / TestFlight:"
echo "   Option A (GUI):  open -a Transporter '$IPA'"
echo "   Option B (CLI):  xcrun altool --upload-app --type ios -f '$IPA' \\"
echo "                                  --apiKey <key-id> --apiIssuer <issuer-uuid>"
