#!/bin/bash

set -e

REPO_URL="https://github.com/ShivamSingh2357/DevSetupScripts.git"
TARGET_DIR="$HOME/DevSetupScripts"

echo "🚀 Starting Developer Setup..."

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Unsupported OS: $OSTYPE"
    exit 1
fi

# Install Homebrew on macOS if not installed
if [ "$OS" = "macos" ] && ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install git if not installed
if ! command -v git &> /dev/null; then
    echo "📦 Installing git..."
    if [ "$OS" = "macos" ]; then
        brew install git
    elif [ "$OS" = "linux" ]; then
        sudo apt-get update
        sudo apt-get install -y git
    fi
fi

# Install GitHub CLI if not installed
if ! command -v gh &> /dev/null; then
    echo "📦 Installing GitHub CLI..."
    if [ "$OS" = "macos" ]; then
        brew install gh
    elif [ "$OS" = "linux" ]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y gh
    fi
fi

# Authenticate with GitHub
echo "🔐 Authenticating with GitHub..."
gh auth login

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
read choice < /dev/tty

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