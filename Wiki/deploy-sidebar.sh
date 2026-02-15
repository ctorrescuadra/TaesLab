#!/bin/bash
# Deploy sidebar to TaesLab Wiki
#
# This script automates the deployment of the _Sidebar.md file to the GitHub Wiki.
# It requires that you have write access to the TaesLab wiki repository.

set -e  # Exit on error

WIKI_REPO="https://github.com/ctorrescuadra/TaesLab.wiki.git"
WIKI_DIR="TaesLab.wiki"
SIDEBAR_FILE="Wiki/_Sidebar.md"

echo "TaesLab Wiki Sidebar Deployment"
echo "================================"
echo

# Check if sidebar file exists
if [ ! -f "$SIDEBAR_FILE" ]; then
    echo "Error: $SIDEBAR_FILE not found!"
    exit 1
fi

# Clone or update wiki repository
if [ -d "$WIKI_DIR" ]; then
    echo "Wiki repository already exists, updating..."
    cd "$WIKI_DIR"
    git pull origin master
    cd ..
else
    echo "Cloning wiki repository..."
    git clone "$WIKI_REPO"
fi

# Copy sidebar file
echo "Copying sidebar file..."
cp "$SIDEBAR_FILE" "$WIKI_DIR/_Sidebar.md"

# Commit and push
echo "Committing changes..."
cd "$WIKI_DIR"
git add _Sidebar.md

if git diff --cached --quiet; then
    echo "No changes to commit."
else
    git commit -m "Update sidebar page order"
    echo "Pushing to wiki repository..."
    git push origin master
    echo
    echo "✓ Sidebar deployed successfully!"
fi

cd ..
echo
echo "Done! Visit https://github.com/ctorrescuadra/TaesLab/wiki to see the changes."
