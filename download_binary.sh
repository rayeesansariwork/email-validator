#!/bin/bash
# Download check_if_email_exists binary from GitHub releases

set -e

echo "📦 Downloading check_if_email_exists binary..."

# Detect architecture
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Map architecture names
case "$ARCH" in
    x86_64)
        ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Determine binary name based on OS
if [ "$OS" = "linux" ]; then
    BINARY_NAME="check_if_email_exists-${ARCH}-unknown-linux-gnu"
elif [ "$OS" = "darwin" ]; then
    BINARY_NAME="check_if_email_exists-${ARCH}-apple-darwin"
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

echo "🔍 Fetching latest release info from GitHub API..."

# Use GitHub API to get the latest release download URL
API_URL="https://api.github.com/repos/reacherhq/check-if-email-exists/releases/latest"

# Get the download URL for our binary
DOWNLOAD_URL=$(curl -s "$API_URL" | grep "browser_download_url.*${BINARY_NAME}" | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "❌ Could not find binary for ${BINARY_NAME}"
    echo "🔄 Trying direct download from latest release..."
    # Fallback to try v0.9.1 which we know exists
    DOWNLOAD_URL="https://github.com/reacherhq/check-if-email-exists/releases/download/v0.9.1/${BINARY_NAME}"
fi

echo "📥 Downloading from: $DOWNLOAD_URL"

# Download binary with follow redirects
if command -v curl &> /dev/null; then
    curl -L -f -o /app/check_if_email_exists "$DOWNLOAD_URL" || {
        echo "❌ Download failed"
        exit 1
    }
elif command -v wget &> /dev/null; then
    wget -O /app/check_if_email_exists "$DOWNLOAD_URL" || {
        echo "❌ Download failed"
        exit 1
    }
else
    echo "❌ Neither curl nor wget is available"
    exit 1
fi

# Make binary executable
chmod +x /app/check_if_email_exists

# Verify binary exists and is executable
if [ -f /app/check_if_email_exists ] && [ -x /app/check_if_email_exists ]; then
    echo "✅ Binary downloaded successfully!"
    # Try to run version check, but don't fail if it doesn't support --version
    /app/check_if_email_exists --version 2>/dev/null || echo "✅ Binary is executable"
else
    echo "❌ Binary verification failed"
    exit 1
fi
