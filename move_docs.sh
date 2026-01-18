#!/bin/bash
# Script to move all markdown documentation files outside the project

# Get the project root directory
PROJECT_DIR="/Users/willwalsh/PutnamApp/App"
DOCS_DIR="/Users/willwalsh/PutnamApp/Documentation"

# Create docs directory if it doesn't exist
mkdir -p "$DOCS_DIR"

echo "📚 Moving documentation files..."
echo "From: $PROJECT_DIR"
echo "To:   $DOCS_DIR"
echo ""

# Move all .md files from project root (excluding subdirectories)
cd "$PROJECT_DIR"
count=0
for file in *.md; do
    if [ -f "$file" ]; then
        echo "  Moving: $file"
        mv "$file" "$DOCS_DIR/"
        ((count++))
    fi
done

echo ""
echo "✅ Moved $count documentation files"
echo ""
echo "Files are now in: $DOCS_DIR"
echo ""
echo "Note: Files in .vscode/ and Pods/ were left untouched"
