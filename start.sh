#!/bin/bash
# Container startup script - starts Tor instances and FastAPI server

set -e

echo "================================================"
echo "  Email Validator with Multi-Tor Rotation"
echo "================================================"
echo ""

echo "🚀 Starting Tor instances..."

# Start all Tor instances in background
tor -f /root/.tor/instance1/torrc &
echo "✅ Started Tor instance 1 (port 9050)"

tor -f /root/.tor/instance2/torrc &
echo "✅ Started Tor instance 2 (port 9052)"

tor -f /root/.tor/instance3/torrc &
echo "✅ Started Tor instance 3 (port 9054)"

tor -f /root/.tor/instance4/torrc &
echo "✅ Started Tor instance 4 (port 9056)"

echo ""
echo "⏳ Waiting for Tor instances to bootstrap (120 seconds)..."
sleep 120

echo ""
echo "🔍 Checking Tor instance status..."
for port in 9050 9052 9054 9056; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo "   ✅ Port $port is active"
    else
        echo "   ⚠️  Port $port is not ready yet"
    fi
done

echo ""
echo "🌐 Starting FastAPI server on port 8001..."
python3 /app/app.py
