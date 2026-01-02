#!/bin/bash
# Change missed-call-api to use port 3002

echo "=========================================="
echo "🔧 Changing Missed Call API Port to 3002"
echo "=========================================="

cd /root/virtual-number/missed-call-sms-api

echo ""
echo "1. Updating server.js to use port 3002..."
# Update the port in server.js
sed -i "s/const PORT = CONFIG.port || 3001/const PORT = CONFIG.port || 3002/" server.js
sed -i "s/port: 3001/port: 3002/" server.js

# Also update CONFIG.port if it exists
sed -i "s/CONFIG = {/CONFIG = {/" server.js
sed -i "/port: 3001/ s/3001/3002/" server.js

echo "✅ Port updated to 3002"

echo ""
echo "2. Verifying changes..."
grep -n "3002\|port" server.js | head -5

echo ""
echo "3. Stopping existing missed-call-api..."
pm2 delete missed-call-api 2>/dev/null || true

echo ""
echo "4. Starting missed-call-api on port 3002..."
pm2 start server.js --name missed-call-api
pm2 save

echo ""
echo "5. Waiting 3 seconds for startup..."
sleep 3

echo ""
echo "6. Testing API on port 3002..."
HEALTH_RESPONSE=$(curl -s http://localhost:3002/health)
echo "Health response: $HEALTH_RESPONSE"

if echo "$HEALTH_RESPONSE" | grep -q "ok\|healthy\|missed-call"; then
    echo "✅ API is responding on port 3002!"
else
    echo "⚠️  API may not be responding correctly"
    echo "Check logs: pm2 logs missed-call-api"
fi

echo ""
echo "7. Testing SMS endpoint..."
SMS_RESPONSE=$(curl -s -X POST http://localhost:3002/sms-receiver \
  -H "Content-Type: application/json" \
  -d '{
    "from": "+919876543210",
    "message": "Missed call from +919812345678",
    "timestamp": "2026-01-02 10:30:00"
  }')

echo "SMS response: $SMS_RESPONSE"

if echo "$SMS_RESPONSE" | grep -q "success\|Callback\|phoneNumber"; then
    echo "✅ SMS endpoint is working!"
else
    echo "⚠️  SMS endpoint may have issues"
    echo "Check logs: pm2 logs missed-call-api"
fi

echo ""
echo "=========================================="
echo "✅ Port Change Complete"
echo "=========================================="
echo ""
echo "API Endpoint: http://$(hostname -I | awk '{print $1}'):3002/sms-receiver"
echo ""
echo "PM2 Status:"
pm2 list | grep missed-call-api

