#!/usr/bin/env bash
# Install a daily cron job to import Clerk of Court ZIP files placed in
# zClerkDataUpdate/. Runs at 3:30 AM (offset from PCSO :54, news :03).
#
# Workflow: download ZIPs from the Clerk of Court website manually
# (apps.putnam-fl.com/bocc/putsubs/main.php), drop them in zClerkDataUpdate/
# with their conventional names (criminal_HS.zip, criminal_YR.zip, traffYR.zip,
# traffWK.zip, oriyear.zip, etc.). Cron picks them up next 3:30 AM,
# extracts + upserts to Supabase via clerk_data_update_all.py, then
# auto-deletes the processed ZIPs/TXTs.
#
# If no ZIPs are present, the cron logs "no files" and exits cleanly —
# safe to run nightly regardless of whether you've dropped anything.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/zClerkDataUpdate"
LOG_FILE="$SCRIPT_DIR/logs/clerk_update.log"
PYTHON_BIN="$SCRIPT_DIR/.venv/bin/python3"
[ -x "$PYTHON_BIN" ] || PYTHON_BIN="/usr/bin/python3"

CRON_SCRIPT="$DATA_DIR/clerk_data_update_all.py"
CRON_TIME_MIN="30"
CRON_TIME_HOUR="3"
CRON_ENTRY="$CRON_TIME_MIN $CRON_TIME_HOUR * * * cd $DATA_DIR && $PYTHON_BIN $CRON_SCRIPT >> $LOG_FILE 2>&1"

# Top 100 lists refresh — runs at 4:00 AM (after clerk import at 3:30,
# before PCSO scrape at :54). Recomputes the YTD/12/24/36-month
# pre-calculated rankings via the calculate_top_100_lists() Postgres
# function, called through the Management API helper.
TOP100_LOG="$SCRIPT_DIR/logs/top_100_refresh.log"
TOP100_HELPER="$SCRIPT_DIR/ingest/ppa_trim/scripts/mgmt_api_load.sh"
TOP100_ENTRY="0 4 * * * cd $SCRIPT_DIR && $TOP100_HELPER \"select public.calculate_top_100_lists();\" >> $TOP100_LOG 2>&1"

mkdir -p "$SCRIPT_DIR/logs"

if [[ ! -f "$CRON_SCRIPT" ]]; then
  echo "❌ $CRON_SCRIPT not found" >&2
  exit 1
fi

echo "=========================================="
echo "Daily Clerk of Court + Top 100 Setup"
echo "=========================================="
echo "  Repo:        $SCRIPT_DIR"
echo "  Data dir:    $DATA_DIR"
echo "  Python:      $PYTHON_BIN"
echo "  Clerk job:   3:30 AM daily — clerk_data_update_all.py"
echo "  Top 100 job: 4:00 AM daily — calculate_top_100_lists() via Management API"
echo "  Logs:        $LOG_FILE"
echo "               $TOP100_LOG"
echo

# Strip any prior versions of clerk-related cron entries (old broken setup,
# per-script entries, etc.). Match patterns broadly so any previous setup
# is replaced atomically.
EXISTING=$(crontab -l 2>/dev/null || true)
CLEAN=$(printf '%s\n' "$EXISTING" \
  | grep -v "clerk_data_update_all.py" \
  | grep -v "daily_traffic_citations_update.py" \
  | grep -v "daily_criminal_back_history_update.py" \
  | grep -v "import_traffic_citations_upsert.py" \
  | grep -v "import_criminal_back_history.py" \
  | grep -v "calculate_top_100_lists" \
  || true)

REMOVED=$(diff <(printf '%s' "$EXISTING") <(printf '%s' "$CLEAN") | grep -c '^<' || true)
if [[ "$REMOVED" -gt 0 ]]; then
  echo "🧹 removed $REMOVED prior daily-job cron entr$([[ "$REMOVED" == "1" ]] && echo "y" || echo "ies")"
fi

# Install the fresh entries (clerk + top100)
printf '%s\n%s\n%s\n' "$CLEAN" "$CRON_ENTRY" "$TOP100_ENTRY" | grep -v '^$' | crontab -

echo "✅ cron installed:"
crontab -l | grep -E "clerk_data_update_all.py|calculate_top_100_lists"
echo
echo "manual tests:"
echo "  clerk:    $PYTHON_BIN $CRON_SCRIPT"
echo "  top 100:  $TOP100_HELPER \"select public.calculate_top_100_lists();\""
echo "tail logs:"
echo "  $LOG_FILE"
echo "  $TOP100_LOG"
