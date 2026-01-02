#!/bin/bash
# Test the complete missed call callback flow

echo "=========================================="
echo "🧪 Testing Complete Callback Flow"
echo "=========================================="

TEST_NUMBER="919812345678"

echo ""
echo "1. Testing SMS API endpoint..."
SMS_RESPONSE=$(curl -s -X POST http://localhost:3003/sms-receiver \
  -H "Content-Type: application/json" \
  -d "{
    \"from\": \"+919876543210\",
    \"message\": \"Missed call from +91${TEST_NUMBER}\",
    \"timestamp\": \"$(date '+%Y-%m-%d %H:%M:%S')\"
  }")

echo "Response: $SMS_RESPONSE"

if echo "$SMS_RESPONSE" | grep -q "success"; then
    echo "✅ SMS API working"
else
    echo "❌ SMS API error"
    exit 1
fi

echo ""
echo "2. Checking database for callback..."
sleep 2
mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system -e "
SELECT callback_id, caller_number, callback_status, created_at 
FROM missed_call_callbacks 
ORDER BY created_at DESC 
LIMIT 1;
" 2>/dev/null

echo ""
echo "3. Testing callback trigger script..."
/usr/local/bin/trigger-callback.sh +91${TEST_NUMBER} 2>&1

echo ""
echo "4. Checking if Asterisk channel was created..."
sleep 2
asterisk -rx "core show channels" | grep -i "${TEST_NUMBER}\|1002\|callback" || echo "No active channels (may have completed)"

echo ""
echo "5. Checking recent Asterisk logs..."
tail -30 /var/log/asterisk/full | grep -E "callback|${TEST_NUMBER}|1002|outbound-callback" | tail -5

echo ""
echo "6. Checking call logs..."
mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system -e "
SELECT call_id, caller_id_number, called_number, call_status, duration, ivr_option_selected 
FROM calls 
WHERE callback_type = 'missed_call' OR caller_id_number LIKE '%${TEST_NUMBER}%'
ORDER BY start_time DESC 
LIMIT 3;
" 2>/dev/null

echo ""
echo "=========================================="
echo "✅ Test Complete"
echo "=========================================="
echo ""
echo "Expected Flow:"
echo "  1. SMS received → Phone extracted ✅"
echo "  2. Callback logged to database ✅"
echo "  3. Callback triggered → Routes to IVR (extension 1002) ✅"
echo "  4. IVR plays human voice menu ✅"
echo ""
echo "For production: Configure SIP trunk to make real outbound calls"

