#!/bin/bash
# Check SIP trunk configuration and fix if needed

echo "=========================================="
echo "🔍 Checking SIP Trunk Configuration"
echo "=========================================="

echo ""
echo "1. Checking if 'trunk' exists in sip.conf..."
if grep -q "^\[trunk\]" /etc/asterisk/sip.conf; then
    echo "✅ SIP trunk 'trunk' exists"
    grep -A 15 "^\[trunk\]" /etc/asterisk/sip.conf
else
    echo "❌ SIP trunk 'trunk' NOT found"
    echo ""
    echo "2. Checking available SIP peers..."
    asterisk -rx "sip show peers" | head -10
    
    echo ""
    echo "3. Checking sip.conf for available trunks/peers..."
    grep "^\[" /etc/asterisk/sip.conf | grep -v "^\[general\]" | grep -v "^\[template" | head -10
fi

echo ""
echo "4. Checking recent Asterisk errors..."
tail -50 /var/log/asterisk/full | grep -iE "error|warning|trunk|dial" | tail -10

echo ""
echo "5. Testing originate with verbose output..."
asterisk -rx "channel originate Local/919812345678@outbound-callback application Wait 1" -vvv 2>&1 | head -20

echo ""
echo "=========================================="
echo "💡 Solution Options"
echo "=========================================="
echo ""
echo "Option 1: Create SIP trunk in /etc/asterisk/sip.conf"
echo "Option 2: Modify dialplan to use existing SIP peer"
echo "Option 3: Use Local channel to route to IVR instead of dialing out"
echo ""
echo "For now, let's check what SIP configuration exists..."

