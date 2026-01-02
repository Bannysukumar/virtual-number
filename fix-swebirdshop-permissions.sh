#!/bin/bash
# Fix permissions for swebirdshop.com Node.js app

echo "=========================================="
echo "🔧 Fixing swebirdshop.com Permissions"
echo "=========================================="

WEB_ROOT="/www/wwwroot/swebirdshop.com"

echo ""
echo "1. Fixing permissions on website directory..."
chown -R www:www "$WEB_ROOT"
find "$WEB_ROOT" -type f -exec chmod 644 {} \;
find "$WEB_ROOT" -type d -exec chmod 755 {} \;

echo ""
echo "2. Fixing execute permissions on node_modules binaries..."
if [ -d "$WEB_ROOT/node_modules/.bin" ]; then
    find "$WEB_ROOT/node_modules/.bin" -type f -exec chmod +x {} \;
    echo "✅ Fixed execute permissions on node_modules/.bin"
    ls -la "$WEB_ROOT/node_modules/.bin/next" 2>/dev/null || echo "⚠️  next binary not found"
else
    echo "❌ node_modules/.bin directory not found"
fi

echo ""
echo "3. Fixing execute permissions on all node_modules..."
if [ -d "$WEB_ROOT/node_modules" ]; then
    # Make sure all executable files in node_modules have execute permission
    find "$WEB_ROOT/node_modules" -type f -name "*.js" -exec chmod +x {} \; 2>/dev/null || true
    find "$WEB_ROOT/node_modules" -type f -path "*/bin/*" -exec chmod +x {} \; 2>/dev/null || true
    echo "✅ Fixed execute permissions on node_modules"
fi

echo ""
echo "4. Checking if .next build directory exists..."
if [ -d "$WEB_ROOT/.next" ]; then
    echo "✅ .next directory exists"
    chown -R www:www "$WEB_ROOT/.next"
    find "$WEB_ROOT/.next" -type d -exec chmod 755 {} \;
    find "$WEB_ROOT/.next" -type f -exec chmod 644 {} \;
else
    echo "⚠️  .next directory not found - app may need to be built"
    echo "   Run: cd $WEB_ROOT && npm run build"
fi

echo ""
echo "5. Restarting PM2..."
pm2 delete swebirdshop 2>/dev/null || true
cd "$WEB_ROOT"
pm2 start ecosystem.config.js
pm2 save

echo ""
echo "6. Waiting 5 seconds for app to start..."
sleep 5

echo ""
echo "7. Checking PM2 status..."
pm2 list | grep swebirdshop

echo ""
echo "8. Checking PM2 logs for errors..."
pm2 logs swebirdshop --lines 10 --nostream

echo ""
echo "9. Checking if port 3000 is listening..."
if netstat -tlnp 2>/dev/null | grep -q ":3000 " || ss -tlnp 2>/dev/null | grep -q ":3000 "; then
    echo "✅ App is listening on port 3000!"
    netstat -tlnp 2>/dev/null | grep ":3000 " || ss -tlnp 2>/dev/null | grep ":3000 "
else
    echo "⚠️  App is not listening on port 3000 yet"
    echo "   Check logs: pm2 logs swebirdshop"
fi

echo ""
echo "10. Testing local connection..."
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 | grep -q "200\|301\|302"; then
    echo "✅ App is responding on port 3000!"
else
    echo "⚠️  App may not be responding yet"
    echo "   Response: $(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 2>/dev/null)"
fi

echo ""
echo "=========================================="
echo "✅ Permission Fix Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check website: https://swebirdshop.com"
echo "2. If still not working, check logs: pm2 logs swebirdshop"
echo "3. If .next doesn't exist, build the app: cd $WEB_ROOT && npm run build"

