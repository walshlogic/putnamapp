#!/bin/bash
# Project Cleanup Script
# Removes build artifacts and temporary files to reduce project size

set -e  # Exit on error

echo "🧹 Putnam App - Project Cleanup"
echo "================================"
echo ""

# Confirm before proceeding
read -p "This will delete build artifacts and temporary files. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 1
fi

# Calculate sizes before cleanup
echo "📊 Calculating sizes..."
BUILD_SIZE=$(du -sh build 2>/dev/null | cut -f1 || echo "0")
BACKUP_SIZE=$(du -sh temp_12-01_backup 2>/dev/null | cut -f1 || echo "0")
LOGS_SIZE=$(du -sh logs 2>/dev/null | cut -f1 || echo "0")

echo ""
echo "Files to be removed:"
echo "  - build/          : $BUILD_SIZE"
echo "  - temp_12-01_backup/ : $BACKUP_SIZE"
echo "  - logs/           : $LOGS_SIZE"
echo ""

read -p "Proceed with cleanup? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 1
fi

echo ""
echo "🗑️  Removing files..."

# Remove build artifacts (safe - will be regenerated)
if [ -d "build" ]; then
    echo "  Removing build/..."
    rm -rf build/
    echo "    ✅ Removed build artifacts"
else
    echo "  ⏭️  build/ not found (already clean)"
fi

# Remove backup directory
if [ -d "temp_12-01_backup" ]; then
    echo "  Removing temp_12-01_backup/..."
    rm -rf temp_12-01_backup/
    echo "    ✅ Removed backup directory"
else
    echo "  ⏭️  temp_12-01_backup/ not found"
fi

# Remove logs
if [ -d "logs" ]; then
    echo "  Removing logs/..."
    rm -rf logs/
    echo "    ✅ Removed log files"
else
    echo "  ⏭️  logs/ not found"
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "💡 Next steps:"
echo "  1. Run 'flutter clean' to clean Flutter cache"
echo "  2. Run 'flutter pub get' to restore dependencies"
echo "  3. Run 'flutter analyze' to check code quality"
echo "  4. Rebuild when ready: 'flutter build ios --release'"
echo ""
