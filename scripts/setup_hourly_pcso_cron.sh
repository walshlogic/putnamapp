#!/bin/bash
# Setup PCSO jail log import cron job (runs hourly)
# This script adds a cron job to run import_pcso_bookings.py every hour

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
CRON_LOG="$REPO_DIR/logs/pcso_bookings_import.log"

# Create logs directory if it doesn't exist
mkdir -p "$REPO_DIR/logs"

# Create cron entry (runs hourly at :05)
CRON_ENTRY="5 * * * * cd $REPO_DIR && /usr/bin/python3 $SCRIPT_DIR/import_pcso_bookings.py >> $CRON_LOG 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "import_pcso_bookings.py"; then
    echo "⚠️  Cron job for import_pcso_bookings.py already exists"
    echo "Current cron jobs:"
    crontab -l | grep "import_pcso_bookings.py"
    echo ""
    read -p "Do you want to replace it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove existing entry and add new one
        (crontab -l 2>/dev/null | grep -v "import_pcso_bookings.py"; echo "$CRON_ENTRY") | crontab -
        echo "✅ Cron job updated successfully"
    else
        echo "❌ Cancelled. No changes made."
        exit 0
    fi
else
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    echo "✅ Cron job added successfully"
fi

echo ""
echo "📋 Current cron jobs:"
crontab -l | grep "import_pcso_bookings.py"
echo ""
echo "📝 Logs will be written to: $CRON_LOG"
echo ""
echo "💡 To remove this cron job, run:"
echo "   crontab -e"
echo "   (then delete the line containing import_pcso_bookings.py)"
echo ""
echo "⚠️  IMPORTANT: Before this will work, you need to:"
echo "   1. Ensure assets/.env has SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY"
echo "   2. (Optional) Set PCSO_JAIL_LOG_URL if the default changes"
echo "   3. Test the script manually: python3 import_pcso_bookings.py"

