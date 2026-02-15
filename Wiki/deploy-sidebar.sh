#!/bin/bash
# Deploy sidebar to TaesLab Wiki
#
# This script automates the deployment of the _Sidebar.md file to the GitHub Wiki.
# It requires that you have write access to the TaesLab wiki repository.

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
    if git pull origin master; then
        echo "✓ Wiki repository updated successfully"
    else
        echo "Error: Failed to update wiki repository. Check your network connection and git credentials."
        exit 1
    fi
    cd ..
else
    echo "Cloning wiki repository..."
    if git clone "$WIKI_REPO"; then
        echo "✓ Wiki repository cloned successfully"
    else
        echo "Error: Failed to clone wiki repository. Check your network connection and repository access."
        exit 1
    fi
fi

# Copy sidebar file
echo "Copying sidebar file..."
cp "$SIDEBAR_FILE" "$WIKI_DIR/_Sidebar.md"

# Commit and push
echo "Committing changes..."
cd "$WIKI_DIR"
git add _Sidebar.md

if git diff --cached --quiet; then
    echo "No changes to commit. Sidebar is already up to date."
else
    if git commit -m "Update sidebar page order"; then
        echo "✓ Changes committed successfully"
    else
        echo "Error: Failed to commit changes"
        cd ..
        exit 1
    fi
    
    echo "Pushing to wiki repository..."
    if git push origin master; then
        echo
        echo "✓ Sidebar deployed successfully!"
    else
        echo "Error: Failed to push changes. Check your git credentials and repository access."
        cd ..
        exit 1
    fi
fi

cd ..
echo
echo "Done! Visit https://github.com/ctorrescuadra/TaesLab/wiki to see the changes."
