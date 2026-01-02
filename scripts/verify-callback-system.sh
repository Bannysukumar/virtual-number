#!/bin/bash
# Verify the complete missed call callback system

echo "=========================================="
echo "✅ Verifying Missed Call Callback System"
echo "=========================================="

echo ""
echo "1. Checking API status..."
curl -s http://localhost:3003/health | jq '.' || curl -s http://localhost:3003/health

echo ""
echo "2. Checking recent callbacks in database..."
mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system -e "
SELECT callback_id, caller_number, callback_status, created_at 
FROM missed_call_callbacks 
ORDER BY created_at DESC 
LIMIT 5;
" 2>/dev/null || echo "⚠️  Could not query database"

echo ""
echo "3. Checking PM2 status..."
pm2 list | grep missed-call-api

echo ""
echo "4. Testing SMS endpoint..."
TEST_RESPONSE=$(curl -s -X POST http://localhost:3003/sms-receiver \
  -H "Content-Type: application/json" \
  -d '{
    "from": "+919876543210",
    "message": "Missed call from +919999999999",
    "timestamp": "2026-01-02 10:30:00"
  }')

echo "Response: $TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "success"; then
    echo "✅ SMS endpoint working!"
else
    echo "⚠️  Check response above"
fi

echo ""
echo "5. Checking if callback script exists..."
ls -la /usr/local/bin/trigger-callback.sh

echo ""
echo "6. Checking Asterisk dialplan..."
grep -q "outbound-callback" /etc/asterisk/extensions.conf && echo "✅ Callback dialplan exists" || echo "⚠️  Callback dialplan not found"

echo ""
echo "=========================================="
echo "✅ System Verification Complete"
echo "=========================================="
echo ""
echo "🌐 API Endpoint: http://$(hostname -I | awk '{print $1}'):3003/sms-receiver"
echo ""
echo "📱 Next Steps:"
echo "  1. Configure Android SMS forwarding (see ANDROID_SMS_SETUP.md)"
echo "  2. Update Android app URL to: http://$(hostname -I | awk '{print $1}'):3003/sms-receiver"
echo "  3. Test with real missed call"
echo "  4. Monitor callbacks: pm2 logs missed-call-api"

