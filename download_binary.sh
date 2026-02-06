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

echo "🔍 Using verified release v0.9.1..."

# Use known working version directly
VERSION="v0.9.1"
DOWNLOAD_URL="https://github.com/reacherhq/check-if-email-exists/releases/download/${VERSION}/${BINARY_NAME}"

echo "📥 Downloading from: $DOWNLOAD_URL"

# Download binary with follow redirects and fail on error
if command -v curl &> /dev/null; then
    curl -L -f -o /app/check_if_email_exists "$DOWNLOAD_URL" || {
        echo "❌ Download failed with curl"
        exit 1
    }
elif command -v wget &> /dev/null; then
    wget -O /app/check_if_email_exists "$DOWNLOAD_URL" || {
        echo "❌ Download failed with wget"
        exit 1
    }
else
    echo "❌ Neither curl nor wget is available"
    exit 1
fi

# Verify the file is actually a binary (ELF format for Linux)
echo "🔍 Verifying file type..."
file_type=$(file /app/check_if_email_exists)
echo "📄 File type: $file_type"

if echo "$file_type" | grep -q "ELF.*executable"; then
    echo "✅ Valid ELF binary detected"
else
    echo "❌ Downloaded file is not a valid binary!"
    echo "File content (first 100 bytes):"
    head -c 100 /app/check_if_email_exists
    exit 1
fi

# Make binary executable
chmod +x /app/check_if_email_exists

# Verify binary exists and is executable
if [ -f /app/check_if_email_exists ] && [ -x /app/check_if_email_exists ]; then
    echo "✅ Binary downloaded successfully!"
    # Don't check version as it may not support --version flag
    echo "✅ Binary is ready to use"
else
    echo "❌ Binary verification failed"
    exit 1
fi
