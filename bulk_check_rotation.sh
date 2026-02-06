#!/bin/bash
# bulk_check_rotation.sh
# Usage: ./bulk_check_rotation.sh emails.txt

if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file.txt>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="results_rotation_$(date +%Y%m%d_%H%M%S).jsonl"
BINARY="./target/release/check_if_email_exists"
FROM_EMAIL="reacher.email@gmail.com"      # ← CHANGE THIS

# Your Tor / proxy ports - add/remove as needed
PROXY_PORTS=("9050" "9052" "9054" "9056")  # All 4 Tor instances active!

echo "Starting bulk verification with proxy rotation"
echo "Proxies: ${PROXY_PORTS[*]}"
echo "Delay between checks: 4 seconds"
echo "----------------------------------------"

count=0
proxy_index=0

while IFS= read -r email || [[ -n "$email" ]]; do
    [[ -z "$email" ]] && continue
    
    current_port=${PROXY_PORTS[$proxy_index]}
    
    echo -n "[$((count+1))] $email (port $current_port) → "
    
    result=$($BINARY \
        --proxy-host "127.0.0.1" \
        --proxy-port "$current_port" \
        --from-email "$FROM_EMAIL" \
        "$email" 2>/dev/null)
    
    echo "$result" >> "$OUTPUT_FILE"
    
    status=$(echo "$result" | grep -o '"is_reachable": "[^"]*"' | cut -d'"' -f4)
    echo "${status:-ERROR}"
    
    # Rotate proxy
    proxy_index=$(( (proxy_index + 1) % ${#PROXY_PORTS[@]} ))
    
    ((count++))
    sleep 1
done < "$INPUT_FILE"

echo "----------------------------------------"
echo "Finished - checked $count emails"
echo "Results → $OUTPUT_FILE"
echo "Tip: Use jq to analyze:"
echo "  cat $OUTPUT_FILE | jq -r '.input + \" → \" + .is_reachable'"