#!/bin/bash
# Stop all Tor instances
# Usage: ./stop_tor_instances.sh

echo "================================================"
echo "  Stopping Multi-Tor Instances"
echo "================================================"
echo ""

# Check if any tor instances are running
if ! pgrep -f "tor -f.*instance" > /dev/null; then
    echo "ℹ️  No Tor instances are currently running."
    exit 0
fi

echo "🛑 Stopping all Tor instances..."
pkill -f "tor -f.*instance"

# Wait a moment for processes to terminate
sleep 2

# Verify all stopped
if pgrep -f "tor -f.*instance" > /dev/null; then
    echo "⚠️  Some instances didn't stop gracefully, forcing..."
    pkill -9 -f "tor -f.*instance"
    sleep 1
fi

echo ""
echo "✅ All Tor instances stopped successfully!"
echo ""
