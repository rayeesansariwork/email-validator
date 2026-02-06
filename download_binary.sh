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

# GitHub release URL (using latest release)
RELEASE_URL="https://github.com/reacherhq/check-if-email-exists/releases/latest/download/${BINARY_NAME}"

echo "📥 Downloading from: $RELEASE_URL"

# Download binary
if command -v curl &> /dev/null; then
    curl -L -o /app/check_if_email_exists "$RELEASE_URL"
elif command -v wget &> /dev/null; then
    wget -O /app/check_if_email_exists "$RELEASE_URL"
else
    echo "❌ Neither curl nor wget is available"
    exit 1
fi

# Make binary executable
chmod +x /app/check_if_email_exists

# Verify binary works
if /app/check_if_email_exists --version; then
    echo "✅ Binary downloaded and verified successfully!"
else
    echo "❌ Binary verification failed"
    exit 1
fi
