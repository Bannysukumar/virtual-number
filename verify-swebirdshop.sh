#!/bin/bash
# Verify swebirdshop.com is working correctly

echo "=========================================="
echo "🔍 Verifying swebirdshop.com Status"
echo "=========================================="

echo ""
echo "1. Checking PM2 status..."
pm2 list | grep swebirdshop

echo ""
echo "2. Checking PM2 logs (last 20 lines)..."
pm2 logs swebirdshop --lines 20 --nostream

echo ""
echo "3. Checking if port 3000 is listening..."
if command -v netstat >/dev/null 2>&1; then
    netstat -tlnp 2>/dev/null | grep ":3000 " || echo "⚠️  Port 3000 not found with netstat"
elif command -v ss >/dev/null 2>&1; then
    ss -tlnp 2>/dev/null | grep ":3000 " || echo "⚠️  Port 3000 not found with ss"
else
    echo "⚠️  netstat/ss not available"
fi

echo ""
echo "4. Testing local connection to port 3000..."
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 | grep -q "200\|301\|302"; then
    echo "✅ App is responding on port 3000"
    curl -I http://127.0.0.1:3000 2>/dev/null | head -5
else
    echo "⚠️  App may not be responding on port 3000"
    echo "   Response code: $(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 2>/dev/null)"
fi

echo ""
echo "5. Checking Nginx proxy configuration..."
if [ -f "/www/server/panel/vhost/nginx/proxy/swebirdshop.com/proxy.conf" ]; then
    echo "✅ Proxy config exists:"
    cat /www/server/panel/vhost/nginx/proxy/swebirdshop.com/proxy.conf
else
    echo "❌ Proxy config not found!"
fi

echo ""
echo "6. Checking recent Nginx error logs..."
tail -10 /www/wwwlogs/swebirdshop.com.error.log 2>/dev/null || echo "No error log found"

echo ""
echo "7. Testing website via Nginx..."
if curl -s -o /dev/null -w "%{http_code}" https://swebirdshop.com 2>/dev/null | grep -q "200\|301\|302"; then
    echo "✅ Website is accessible via HTTPS!"
    echo "   Response code: $(curl -s -o /dev/null -w "%{http_code}" https://swebirdshop.com 2>/dev/null)"
else
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://swebirdshop.com 2>/dev/null)
    echo "⚠️  Website may not be accessible"
    echo "   Response code: $HTTP_CODE"
fi

echo ""
echo "=========================================="
echo "✅ Verification Complete"
echo "=========================================="

