#!/bin/bash
# Fix port 3001 conflict for missed-call-api

echo "=========================================="
echo "🔧 Fixing Port 3001 Conflict"
echo "=========================================="

echo ""
echo "1. Checking what's using port 3001..."
netstat -tlnp | grep :3001 || ss -tlnp | grep :3001

echo ""
echo "2. Checking PM2 processes..."
pm2 list

echo ""
echo "3. Stopping existing missed-call-api..."
pm2 delete missed-call-api 2>/dev/null || true

echo ""
echo "4. Finding process using port 3001..."
PID=$(lsof -ti:3001 2>/dev/null || fuser 3001/tcp 2>/dev/null | awk '{print $NF}' || netstat -tlnp | grep :3001 | awk '{print $7}' | cut -d'/' -f1 | head -1)

if [ -n "$PID" ] && [ "$PID" != "-" ]; then
    echo "Found process $PID using port 3001"
    ps aux | grep $PID | grep -v grep
    echo ""
    read -p "Kill process $PID? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kill -9 $PID 2>/dev/null || true
        echo "✅ Killed process $PID"
        sleep 2
    fi
else
    echo "⚠️  Could not find process using port 3001"
fi

echo ""
echo "5. Starting missed-call-api..."
cd /root/virtual-number/missed-call-sms-api
pm2 start server.js --name missed-call-api
pm2 save

echo ""
echo "6. Waiting 3 seconds..."
sleep 3

echo ""
echo "7. Testing API..."
if curl -s http://localhost:3001/health | grep -q "ok\|healthy"; then
    echo "✅ API is responding!"
    curl -s http://localhost:3001/health | head -1
else
    echo "⚠️  API may not be responding yet"
    echo "Check logs: pm2 logs missed-call-api"
fi

echo ""
echo "8. Testing SMS endpoint..."
TEST_RESPONSE=$(curl -s -X POST http://localhost:3001/sms-receiver \
  -H "Content-Type: application/json" \
  -d '{
    "from": "+919876543210",
    "message": "Missed call from +919812345678",
    "timestamp": "2026-01-02 10:30:00"
  }')

echo "Response: $TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "success\|Callback"; then
    echo "✅ SMS endpoint is working!"
else
    echo "⚠️  Check the response above"
fi

echo ""
echo "=========================================="
echo "✅ Port Conflict Fix Complete"
echo "=========================================="

