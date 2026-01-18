#!/bin/bash
# Setup script for daily traffic citations import via cron
# This script helps set up the cron job automatically

SCRIPT_DIR="/Users/willwalsh/PutnamApp/App"
DATA_DIR="$SCRIPT_DIR/zClerkDataUpdate"
PYTHON_PATH="/usr/bin/python3"
TRAFFIC_SCRIPT="$DATA_DIR/daily_traffic_citations_update.py"
CRIMINAL_SCRIPT="$DATA_DIR/daily_criminal_back_history_update.py"
TRAFFIC_LOG="$SCRIPT_DIR/logs/traffic_citations_import.log"
CRIMINAL_LOG="$SCRIPT_DIR/logs/criminal_back_history_import.log"
TRAFFIC_TIME="2"  # 2 AM daily
CRIMINAL_TIME="3"  # 3 AM daily (1 hour after traffic)

echo "=========================================="
echo "Daily Clerk of Court Data Import Setup"
echo "=========================================="
echo ""
echo "Traffic Citations:"
echo "  Script: $TRAFFIC_SCRIPT"
echo "  Log: $TRAFFIC_LOG"
echo "  Time: Daily at $TRAFFIC_TIME:00 AM"
echo ""
echo "Criminal Back History:"
echo "  Script: $CRIMINAL_SCRIPT"
echo "  Log: $CRIMINAL_LOG"
echo "  Time: Daily at $CRIMINAL_TIME:00 AM"
echo ""

# Create logs directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/logs"

# Create cron entries
TRAFFIC_CRON="0 $TRAFFIC_TIME * * * cd $DATA_DIR && $PYTHON_PATH $TRAFFIC_SCRIPT >> $TRAFFIC_LOG 2>&1"
CRIMINAL_CRON="0 $CRIMINAL_TIME * * * cd $DATA_DIR && $PYTHON_PATH $CRIMINAL_SCRIPT >> $CRIMINAL_LOG 2>&1"

echo "Cron entries to be added:"
echo "$TRAFFIC_CRON"
echo "$CRIMINAL_CRON"
echo ""

# Check if cron entries already exist
TRAFFIC_EXISTS=false
CRIMINAL_EXISTS=false

if crontab -l 2>/dev/null | grep -q "daily_traffic_citations_update.py\|import_traffic_citations_upsert.py"; then
    TRAFFIC_EXISTS=true
fi

if crontab -l 2>/dev/null | grep -q "daily_criminal_back_history_update.py"; then
    CRIMINAL_EXISTS=true
fi

if [ "$TRAFFIC_EXISTS" = true ] || [ "$CRIMINAL_EXISTS" = true ]; then
    echo "⚠️  Some cron jobs already exist!"
    echo ""
    echo "Current crontab entries:"
    crontab -l 2>/dev/null | grep -E "(daily_traffic_citations_update|import_traffic_citations_upsert|daily_criminal_back_history_update)" || echo "  (none found)"
    echo ""
    read -p "Do you want to replace them? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled. No changes made."
        exit 0
    fi
    # Remove old entries (both old and new script names)
    crontab -l 2>/dev/null | grep -v "daily_traffic_citations_update.py" | grep -v "import_traffic_citations_upsert.py" | grep -v "daily_criminal_back_history_update.py" | crontab -
fi

# Add new cron entries
(crontab -l 2>/dev/null; echo "$TRAFFIC_CRON"; echo "$CRIMINAL_CRON") | crontab -

echo "✅ Cron jobs added successfully!"
echo ""
echo "To verify, run: crontab -l"
echo "To test traffic citations manually: $PYTHON_PATH $TRAFFIC_SCRIPT"
echo "To test download only: $PYTHON_PATH $DATA_DIR/download_traffic_citations.py"
echo "To test criminal history manually: $PYTHON_PATH $CRIMINAL_SCRIPT"
echo "To view traffic logs: tail -f $TRAFFIC_LOG"
echo "To view criminal logs: tail -f $CRIMINAL_LOG"
echo ""

