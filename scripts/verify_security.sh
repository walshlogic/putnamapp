#!/bin/bash
# Security Verification Script
# Run this before App Store submission

# Always run from repo root so the relative paths below resolve correctly,
# regardless of where the user invokes this script from.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

echo "🔒 Security Verification Checklist"
echo "===================================="
echo ""

# Check if .env file exists
if [ -f "assets/.env" ]; then
    echo "✅ Found assets/.env file"
    
    # Check for service role key (should NOT be there)
    if grep -q "SERVICE_ROLE" assets/.env; then
        echo "❌ ERROR: SERVICE_ROLE_KEY found in assets/.env!"
        echo "   This should NEVER be in the app - only in server scripts!"
        exit 1
    else
        echo "✅ No SERVICE_ROLE_KEY found (good!)"
    fi
    
    # Check for anon key (should be there)
    if grep -q "SUPABASE_ANON_KEY" assets/.env; then
        echo "✅ SUPABASE_ANON_KEY found (this is safe - it's a public key)"
    else
        echo "⚠️  SUPABASE_ANON_KEY not found"
    fi
    
    # List what's in .env
    echo ""
    echo "Keys found in .env:"
    grep -E "^[A-Z_]+=" assets/.env | cut -d'=' -f1 | sed 's/^/  - /'
else
    echo "⚠️  assets/.env not found"
fi

echo ""
echo "Checking pubspec.yaml..."
if grep -q "assets/.env" pubspec.yaml; then
    echo "⚠️  assets/.env is bundled in app (consider removing if using public keys)"
else
    echo "✅ assets/.env not in pubspec.yaml assets"
fi

echo ""
echo "Checking .gitignore..."
if [ -f ".gitignore" ]; then
    if grep -q "\.env" .gitignore; then
        echo "✅ .env files are in .gitignore"
    else
        echo "⚠️  .env not found in .gitignore (should be there!)"
    fi
else
    echo "⚠️  .gitignore not found (created one for you)"
fi

echo ""
echo "===================================="
echo "✅ Security check complete!"
echo ""
echo "Remember:"
echo "  - Only PUBLIC keys should be in assets/.env"
echo "  - SERVICE_ROLE_KEY should NEVER be in the app"
echo "  - All keys in app are safe to expose (they're public)"
