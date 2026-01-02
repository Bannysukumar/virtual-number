#!/bin/bash
# Quick script to modify callback to route to IVR for testing

echo "Modifying callback dialplan to route to IVR (for testing)..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.testing.$(date +%Y%m%d_%H%M%S)

# Replace Dial command with Goto to IVR
sed -i 's|Dial(SIP/${CALLER_NUM}@trunk,30,Tt)|Goto(internal,1002,1)|g' /etc/asterisk/extensions.conf
sed -i 's|Dial(SIP/${EXTEN}@trunk,30,Tt)|Goto(internal,1002,1)|g' /etc/asterisk/extensions.conf

# Reload dialplan
asterisk -rx "dialplan reload"

echo "✅ Callback now routes to IVR (extension 1002)"
echo ""
echo "Test with: /usr/local/bin/trigger-callback.sh +919812345678"
echo "The callback will connect to IVR instead of dialing out"

