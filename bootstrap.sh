#!/bin/bash

set -e

REPO_URL="https://github.com/ShivamSingh2357/DevSetupScripts.git"
TARGET_DIR="$HOME/DevSetupScripts"

echo "🚀 Starting Developer Setup..."

# Clone repo if not exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "📥 Cloning DevSetupScripts..."
    git clone $REPO_URL $TARGET_DIR
else
    echo "🔄 Repo already exists. Updating..."
    cd $TARGET_DIR
    git pull
fi

# Choose which service to set up
echo ""
echo "Which service do you want to set up?"
echo "1) Party Service"
echo "2) Product Catalogue Service"
echo -n "Enter choice (1/2): "
read choice

if [ "$choice" = "1" ]; then
    SCRIPT="$TARGET_DIR/party-service/setup.sh"
elif [ "$choice" = "2" ]; then
    SCRIPT="$TARGET_DIR/product-catalogue-service/setup.sh"
else
    echo "❌ Invalid choice"
    exit 1
fi

echo ""
echo "▶ Running setup script: $SCRIPT"

chmod +x "$SCRIPT"
bash "$SCRIPT"