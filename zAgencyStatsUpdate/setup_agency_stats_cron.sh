#!/bin/bash

# =====================================================
# SETUP CRON JOB FOR AGENCY STATS CALCULATION
# =====================================================
# This script sets up a cron job to calculate and store
# agency statistics hourly, with a catch-up run on reboot.
# =====================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/calculate_agency_stats.py"
RUN_WRAPPER="$SCRIPT_DIR/run_agency_stats_if_needed.sh"
LOG_DIR="$PROJECT_ROOT/logs"

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "❌ Error: $PYTHON_SCRIPT not found!"
    exit 1
fi

# Check if wrapper script exists
if [ ! -f "$RUN_WRAPPER" ]; then
    echo "❌ Error: $RUN_WRAPPER not found!"
    exit 1
fi

# Make Python script executable
chmod +x "$PYTHON_SCRIPT"
chmod +x "$RUN_WRAPPER"

# Get Python 3 path
PYTHON3=$(which python3)
if [ -z "$PYTHON3" ]; then
    echo "❌ Error: python3 not found in PATH"
    exit 1
fi

echo "📋 Setting up cron job for agency stats calculation..."
echo "   Script: $PYTHON_SCRIPT"
echo "   Python: $PYTHON3"
echo ""
echo "⏰ Schedule: Hourly (at minute 0) + catch-up on reboot"
echo ""

# Create temporary crontab file
TEMP_CRON=$(mktemp)

# Get existing crontab
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# Remove any existing agency stats cron entries
grep -v "calculate_agency_stats.py" "$TEMP_CRON" > "${TEMP_CRON}.new" || true
mv "${TEMP_CRON}.new" "$TEMP_CRON"

# Add new cron entries (hourly + reboot catch-up)
echo "# Agency Stats Calculation - Hourly" >> "$TEMP_CRON"
echo "0 * * * * $RUN_WRAPPER" >> "$TEMP_CRON"
echo "@reboot $RUN_WRAPPER" >> "$TEMP_CRON"

# Install new crontab
crontab "$TEMP_CRON"

# Clean up
rm "$TEMP_CRON"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo "✅ Cron job installed successfully!"
echo ""
echo "📝 To view cron jobs:"
echo "   crontab -l"
echo ""
echo "📝 To remove cron jobs:"
echo "   crontab -e"
echo ""
echo "📝 To test the script manually:"
echo "   cd $SCRIPT_DIR && $PYTHON3 $PYTHON_SCRIPT"
echo ""
echo "📝 To view logs:"
echo "   tail -f $LOG_DIR/agency_stats_cron.log"

