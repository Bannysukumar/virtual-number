#!/bin/bash
# Find what's using port 3002 and fix it

echo "=========================================="
echo "🔍 Finding Port 3002 Conflict"
echo "=========================================="

echo ""
echo "1. Checking what's using port 3002..."
lsof -i :3002 2>/dev/null || netstat -tlnp | grep :3002

echo ""
echo "2. Checking all Node.js processes..."
ps aux | grep node | grep -v grep

echo ""
echo "3. Checking PM2 processes..."
pm2 list

echo ""
echo "4. Testing what's actually responding on port 3002..."
curl -v http://localhost:3002/ 2>&1 | head -30

echo ""
echo "5. Checking if our API process is running..."
cd /root/virtual-number/missed-call-sms-api
pm2 logs missed-call-api --lines 10 --nostream

echo ""
echo "6. Checking server.js startup..."
# Check if server.js has any syntax errors
node -c server.js && echo "✅ server.js syntax is valid" || echo "❌ server.js has syntax errors"

echo ""
echo "7. Testing server.js directly (will fail to bind, but shows if it loads)..."
timeout 2 node server.js 2>&1 | head -10 || true

echo ""
echo "=========================================="
echo "🔧 Suggested Fix"
echo "=========================================="
echo ""
echo "If port 3002 is used by another service, try port 3003:"
echo "  cd /root/virtual-number/missed-call-sms-api"
echo "  sed -i 's/port: 3002/port: 3003/g' server.js"
echo "  pm2 delete missed-call-api"
echo "  pm2 start server.js --name missed-call-api"
echo "  pm2 save"

