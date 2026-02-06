#!/bin/bash
# Test Tor instances to verify they're using different IPs
# Usage: ./test_tor_rotation.sh

echo "================================================"
echo "  Testing Tor IP Rotation"
echo "================================================"
echo ""

# Check if tor instances are running
if ! pgrep -f "tor -f.*instance" > /dev/null; then
    echo "❌ Error: No Tor instances are running!"
    echo "   Start them first with: ./start_tor_instances.sh"
    exit 1
fi

echo "🔍 Checking IP addresses for each Tor instance..."
echo ""

for port in 9050 9052 9054 9056; do
    echo -n "Port $port → "
    
    # Get IP address through this Tor instance
    ip=$(curl --socks5 127.0.0.1:$port -s --max-time 10 https://api.ipify.org 2>/dev/null)
    
    if [ -z "$ip" ]; then
        echo "❌ Failed to connect"
    else
        echo "✅ IP: $ip"
    fi
done

echo ""
echo "================================================"
echo "💡 Each instance should show a different IP!"
echo "   If you see the same IP, wait 60 seconds and"
echo "   run this test again (circuits are rotating)."
echo "================================================"
echo ""
