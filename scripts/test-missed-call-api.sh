#!/bin/bash
# Test the Missed Call SMS API

echo "=========================================="
echo "🧪 Testing Missed Call SMS API"
echo "=========================================="

API_URL="http://localhost:3001"

echo ""
echo "1. Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s "$API_URL/health")
echo "Response: $HEALTH_RESPONSE"

if echo "$HEALTH_RESPONSE" | grep -q "ok"; then
    echo "✅ API is healthy"
else
    echo "⚠️  API may not be responding correctly"
fi

echo ""
echo "2. Testing SMS receiver endpoint with sample data..."
TEST_RESPONSE=$(curl -s -X POST "$API_URL/sms-receiver" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "+919876543210",
    "message": "Missed call from +919812345678",
    "timestamp": "2026-01-02 10:30:00"
  }')

echo "Response: $TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "success"; then
    echo "✅ SMS API is working!"
else
    echo "⚠️  Check the response above for errors"
fi

echo ""
echo "3. Checking database for recent callbacks..."
mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system -e "
SELECT callback_id, caller_number, callback_status, created_at 
FROM missed_call_callbacks 
ORDER BY created_at DESC 
LIMIT 5;
" 2>/dev/null || echo "⚠️  Could not query database"

echo ""
echo "4. Checking PM2 status..."
pm2 list | grep missed-call-api

echo ""
echo "5. Recent PM2 logs..."
pm2 logs missed-call-api --lines 10 --nostream

echo ""
echo "=========================================="
echo "✅ Test Complete"
echo "=========================================="
echo ""
echo "If everything looks good, configure Android SMS forwarding!"
echo "See: ANDROID_SMS_SETUP.md"

