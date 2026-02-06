#!/bin/bash
# Start multiple Tor instances for proxy rotation
# Usage: ./start_tor_instances.sh

set -e  # Exit on error

echo "================================================"
echo "  Multi-Tor Instance Launcher"
echo "================================================"
echo ""

# Check if tor is installed
if ! command -v tor &> /dev/null; then
    echo "❌ Error: Tor is not installed!"
    echo "   Install with: brew install tor"
    exit 1
fi

# Check if instances are already running
if pgrep -f "tor -f.*instance" > /dev/null; then
    echo "⚠️  Warning: Tor instances are already running!"
    echo "   Stop them first with: ./stop_tor_instances.sh"
    exit 1
fi

echo "🚀 Starting Tor instances..."
echo ""

# Start instance 1
tor -f ~/.tor/instance1/torrc > /dev/null 2>&1 &
echo "✅ Started Tor instance 1 → Port 9050 (SOCKS) / 9051 (Control)"

# Start instance 2
tor -f ~/.tor/instance2/torrc > /dev/null 2>&1 &
echo "✅ Started Tor instance 2 → Port 9052 (SOCKS) / 9053 (Control)"

# Start instance 3
tor -f ~/.tor/instance3/torrc > /dev/null 2>&1 &
echo "✅ Started Tor instance 3 → Port 9054 (SOCKS) / 9055 (Control)"

# Start instance 4
tor -f ~/.tor/instance4/torrc > /dev/null 2>&1 &
echo "✅ Started Tor instance 4 → Port 9056 (SOCKS) / 9057 (Control)"

echo ""
echo "⏳ Waiting for Tor instances to initialize..."
sleep 10

# Check if all instances are listening
echo ""
echo "🔍 Verifying ports are listening..."
for port in 9050 9052 9054 9056; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo "   ✅ Port $port is active"
    else
        echo "   ❌ Port $port is NOT active"
    fi
done

echo ""
echo "================================================"
echo "✨ All Tor instances started successfully!"
echo "================================================"
echo ""
echo "💡 Tips:"
echo "   • Stop instances: ./stop_tor_instances.sh"
echo "   • Check logs: tail -f ~/.tor/instance1/tor.log"
echo "   • Test IPs: curl --socks5 127.0.0.1:9050 https://api.ipify.org"
echo ""
echo "🎯 Your FastAPI app is ready to use all 4 proxy ports!"
echo ""
