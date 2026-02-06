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

echo "🔍 Using latest stable release v0.11.7..."

# Use latest working version
VERSION="v0.11.7"
# Binary is packaged as tar.gz
ARCHIVE_NAME="${BINARY_NAME}.tar.gz"
DOWNLOAD_URL="https://github.com/reacherhq/check-if-email-exists/releases/download/${VERSION}/${ARCHIVE_NAME}"

echo "📥 Downloading from: $DOWNLOAD_URL"

# Download tar.gz archive
if command -v curl &> /dev/null; then
    curl -L -f -o /tmp/check_if_email_exists.tar.gz "$DOWNLOAD_URL" || {
        echo "❌ Download failed with curl"
        exit 1
    }
elif command -v wget &> /dev/null; then
    wget -O /tmp/check_if_email_exists.tar.gz "$DOWNLOAD_URL" || {
        echo "❌ Download failed with wget"
        exit 1
    }
else
    echo "❌ Neither curl nor wget is available"
    exit 1
fi

echo "📦 Extracting binary from archive..."
cd /tmp
tar -xzf check_if_email_exists.tar.gz || {
    echo "❌ Failed to extract archive"
    exit 1
}

# Move binary to /app
mv check_if_email_exists /app/check_if_email_exists || {
    echo "❌ Failed to move binary"
    exit 1
}

# Clean up
rm -f /tmp/check_if_email_exists.tar.gz

# Make binary executable
chmod +x /app/check_if_email_exists

# Verify binary exists and is executable
if [ -f /app/check_if_email_exists ] && [ -x /app/check_if_email_exists ]; then
    echo "✅ Binary downloaded and extracted successfully!"
    echo "✅ Binary is ready to use"
else
    echo "❌ Binary verification failed"
    exit 1
fi
