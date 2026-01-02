#!/bin/bash
# Test callback directly with Asterisk CLI

PHONE_NUMBER="${1:-919812345678}"
CONTEXT="outbound-callback"

echo "=========================================="
echo "🧪 Testing Callback Directly"
echo "=========================================="

echo ""
echo "1. Testing Asterisk originate command..."
echo "Command: channel originate Local/${PHONE_NUMBER}@${CONTEXT} application Wait 1"

# Test the command and capture output
OUTPUT=$(asterisk -rx "channel originate Local/${PHONE_NUMBER}@${CONTEXT} application Wait 1" 2>&1)
echo "Output: $OUTPUT"

echo ""
echo "2. Checking if channel was created..."
sleep 2
asterisk -rx "core show channels" | grep -i "${PHONE_NUMBER}\|callback" || echo "No active channels found"

echo ""
echo "3. Checking recent Asterisk logs..."
tail -30 /var/log/asterisk/full | grep -E "callback|${PHONE_NUMBER}|originate|Local/" | tail -10

echo ""
echo "4. Testing with extension 's' instead..."
# Try using extension 's' with the phone number as a variable
asterisk -rx "channel originate Local/s@${CONTEXT} application Wait 1" 2>&1 | head -5

echo ""
echo "5. Checking dialplan for ${CONTEXT}..."
asterisk -rx "dialplan show ${CONTEXT}" | head -20

echo ""
echo "=========================================="
echo "✅ Test Complete"
echo "=========================================="
echo ""
echo "If no errors above, check:"
echo "  - Asterisk logs: tail -f /var/log/asterisk/full"
echo "  - SIP trunk config: grep -A 10 '\[trunk\]' /etc/asterisk/sip.conf"
echo "  - Active channels: asterisk -rx 'core show channels'"

