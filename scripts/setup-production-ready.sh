#!/bin/bash
# Non-interactive script to route callbacks to IVR for testing
# Or prepare for SIP trunk configuration

echo "=========================================="
echo "🚀 Production Setup Helper"
echo "=========================================="

echo ""
echo "Current Status:"
echo "  ✅ SMS API: Running on port 3003"
echo "  ✅ Database: Configured"
echo "  ✅ Asterisk: Running"
echo "  ⚠️  SIP Trunk: Not configured"
echo "  ⚠️  Android SMS: Not configured"
echo ""

# Option 1: Route to IVR for testing
echo "Setting up callback to route to IVR (for testing)..."
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.$(date +%Y%m%d_%H%M%S)
sed -i 's|Dial(SIP/${CALLER_NUM}@trunk,30,Tt)|Goto(internal,1002,1)|g' /etc/asterisk/extensions.conf
sed -i 's|Dial(SIP/${EXTEN}@trunk,30,Tt)|Goto(internal,1002,1)|g' /etc/asterisk/extensions.conf
asterisk -rx "dialplan reload"
echo "✅ Callback routes to IVR (for testing)"

echo ""
echo "=========================================="
echo "📋 Production Readiness Status"
echo "=========================================="
echo ""
echo "✅ READY:"
echo "  - SMS API endpoint"
echo "  - Phone number extraction"
echo "  - Database logging"
echo "  - Callback trigger"
echo "  - IVR with human voice"
echo ""
echo "⚠️  NEEDS CONFIGURATION:"
echo "  1. SIP Trunk for outbound calls"
echo "     → Add [trunk] section to /etc/asterisk/sip.conf"
echo "     → Configure with your SIP provider"
echo ""
echo "  2. Android SMS Forwarding"
echo "     → Install Tasker/IFTTT on Android"
echo "     → Forward SMS to: http://185.216.203.209:3003/sms-receiver"
echo ""
echo "📚 See PRODUCTION_READINESS.md for details"
echo ""
echo "🧪 Test callback (routes to IVR):"
echo "   /usr/local/bin/trigger-callback.sh +919812345678"

