#!/bin/bash
# Final fix for swebirdshop.com Next.js application
# Fix PM2 config and Nginx proxy

echo "=========================================="
echo "🔧 Final Fix for swebirdshop.com"
echo "=========================================="

WEB_ROOT="/www/wwwroot/swebirdshop.com"
PM2_CONFIG="$WEB_ROOT/ecosystem.config.js"
PROXY_CONF="/www/server/panel/vhost/nginx/proxy/swebirdshop.com/proxy.conf"

echo ""
echo "1. Fixing PM2 ecosystem.config.js..."
if [ -f "$PM2_CONFIG" ]; then
    # Backup original
    cp "$PM2_CONFIG" "${PM2_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update cwd to current root directory
    cat > "$PM2_CONFIG" << 'EOF'
module.exports = {
  apps: [{
    name: 'swebirdshop',
    script: 'npm',
    args: 'start',
    cwd: '/www/wwwroot/swebirdshop.com',
    interpreter: '/usr/bin/node',
    interpreter_args: '',
    env: {
      NODE_ENV: 'production',
      PATH: '/usr/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    }
  }]
}
EOF
    echo "✅ Updated PM2 config - cwd now points to: $WEB_ROOT"
    cat "$PM2_CONFIG"
else
    echo "❌ PM2 config not found: $PM2_CONFIG"
fi

echo ""
echo "2. Creating/updating Nginx proxy configuration..."
mkdir -p "$(dirname $PROXY_CONF)"

cat > "$PROXY_CONF" << 'EOF'
location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
    proxy_read_timeout 300s;
    proxy_connect_timeout 75s;
}
EOF
echo "✅ Created/updated proxy config pointing to port 3000"
cat "$PROXY_CONF"

echo ""
echo "3. Restarting PM2 with updated config..."
cd "$WEB_ROOT"
pm2 delete swebirdshop 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save

echo ""
echo "4. Checking PM2 status..."
pm2 list | grep swebirdshop

echo ""
echo "5. Checking if app is listening on port 3000..."
sleep 2
if netstat -tlnp 2>/dev/null | grep -q ":3000 " || ss -tlnp 2>/dev/null | grep -q ":3000 "; then
    echo "✅ App is listening on port 3000"
    netstat -tlnp 2>/dev/null | grep ":3000 " || ss -tlnp 2>/dev/null | grep ":3000 "
else
    echo "⚠️  App may not be listening on port 3000 yet - check PM2 logs"
    echo "   Run: pm2 logs swebirdshop"
fi

echo ""
echo "6. Testing Nginx configuration..."
/www/server/nginx/sbin/nginx -t

echo ""
echo "7. Reloading Nginx..."
/etc/init.d/nginx reload

echo ""
echo "=========================================="
echo "✅ Fix Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check website: https://swebirdshop.com"
echo "2. If still not working, check PM2 logs: pm2 logs swebirdshop"
echo "3. Check Nginx error logs: tail -f /www/wwwlogs/swebirdshop.com.error.log"
echo "4. Verify app is running: pm2 list"
echo "5. Check port: netstat -tlnp | grep 3000"

