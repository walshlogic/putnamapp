#!/bin/bash
# Setup hourly news import cron job
# This script adds a cron job to run import_news.py every hour

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CRON_LOG="$SCRIPT_DIR/logs/news_import.log"

# Create logs directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/logs"

# Create cron entry (runs at the top of every hour)
CRON_ENTRY="0 * * * * cd $SCRIPT_DIR && /usr/bin/python3 import_news.py >> $CRON_LOG 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "import_news.py"; then
    echo "⚠️  Cron job for import_news.py already exists"
    echo "Current cron jobs:"
    crontab -l | grep "import_news.py"
    echo ""
    read -p "Do you want to replace it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove existing entry and add new one
        (crontab -l 2>/dev/null | grep -v "import_news.py"; echo "$CRON_ENTRY") | crontab -
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
crontab -l | grep "import_news.py"
echo ""
echo "📝 Logs will be written to: $CRON_LOG"
echo ""
echo "💡 To remove this cron job, run:"
echo "   crontab -e"
echo "   (then delete the line containing import_news.py)"


