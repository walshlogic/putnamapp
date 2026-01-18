#!/bin/bash

# Run the agency stats job if it hasn't run within the last hour.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/calculate_agency_stats.py"
LOG_DIR="$PROJECT_ROOT/logs"
LAST_RUN_FILE="$LOG_DIR/agency_stats_last_run.txt"

mkdir -p "$LOG_DIR"

NOW_TS=$(date +%s)
LAST_TS=0
if [ -f "$LAST_RUN_FILE" ]; then
  LAST_TS=$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)
fi

if [ $((NOW_TS - LAST_TS)) -lt 3600 ]; then
  exit 0
fi

PYTHON3=$(which python3)
if [ -z "$PYTHON3" ]; then
  echo "❌ Error: python3 not found in PATH" >> "$LOG_DIR/agency_stats_cron.log"
  exit 1
fi

cd "$SCRIPT_DIR" || exit 1
$PYTHON3 "$PYTHON_SCRIPT" >> "$LOG_DIR/agency_stats_cron.log" 2>&1
date +%s > "$LAST_RUN_FILE"
