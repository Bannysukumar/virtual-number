#!/bin/bash
# Fix API configuration and check logs

echo "=========================================="
echo "🔧 Fixing API Configuration"
echo "=========================================="

cd /root/virtual-number/missed-call-sms-api

echo ""
echo "1. Checking current configuration..."
grep -n "port:" server.js | head -3

echo ""
echo "2. Updating CONFIG.port to 3002..."
sed -i "s/port: 3001,/port: 3002,/" server.js

echo ""
echo "3. Verifying changes..."
grep -n "port:" server.js | head -3

echo ""
echo "4. Checking PM2 logs for errors..."
pm2 logs missed-call-api --lines 30 --nostream

echo ""
echo "5. Restarting API..."
pm2 delete missed-call-api
pm2 start server.js --name missed-call-api
pm2 save

echo ""
echo "6. Waiting 5 seconds..."
sleep 5

echo ""
echo "7. Checking if API is listening on port 3002..."
netstat -tlnp | grep :3002 || ss -tlnp | grep :3002

echo ""
echo "8. Testing health endpoint..."
curl -v http://localhost:3002/health 2>&1 | head -20

echo ""
echo "9. Testing SMS endpoint..."
curl -X POST http://localhost:3002/sms-receiver \
  -H "Content-Type: application/json" \
  -d '{"message":"Missed call from +919812345678"}' 2>&1

echo ""
echo "=========================================="
echo "✅ Configuration Fix Complete"
echo "=========================================="

