#!/bin/bash
# Debug callback trigger to see what's happening

PHONE_NUMBER="${1:-919812345678}"
CONTEXT="outbound-callback"

echo "=========================================="
echo "🔍 Debugging Callback Trigger"
echo "=========================================="

echo ""
echo "1. Testing originate with verbose output..."
asterisk -rx "channel originate Local/${PHONE_NUMBER}@${CONTEXT} application Wait 1" -vvv 2>&1

echo ""
echo "2. Checking dialplan match..."
asterisk -rx "dialplan show ${CONTEXT}" | grep -A 5 "_X."

echo ""
echo "3. Testing with extension 's'..."
asterisk -rx "channel originate Local/s@${CONTEXT} application Wait 1" 2>&1

echo ""
echo "4. Checking for errors in Asterisk..."
tail -100 /var/log/asterisk/full | grep -iE "error|warning|${PHONE_NUMBER}|${CONTEXT}" | tail -10

echo ""
echo "5. Testing alternative originate syntax..."
# Try using the phone number directly as extension
asterisk -rx "dialplan show ${CONTEXT}" | grep "_X."

echo ""
echo "6. Checking if Local channel type is available..."
asterisk -rx "module show like chan_local" | grep -i "chan_local"

echo ""
echo "7. Testing with explicit channel type..."
asterisk -rx "channel originate Local/${PHONE_NUMBER}@${CONTEXT} extension s@${CONTEXT}" 2>&1

echo ""
echo "=========================================="
echo "💡 Alternative: Use AMI (Asterisk Manager Interface)"
echo "=========================================="
echo ""
echo "If CLI originate doesn't work, we can use AMI:"
echo ""
echo "Check if AMI is enabled:"
asterisk -rx "manager show status" | head -5

echo ""
echo "If AMI is enabled, we can use it to originate calls with variables"

