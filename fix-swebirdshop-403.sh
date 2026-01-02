#!/bin/bash
# Fix swebirdshop.com 403 Forbidden Error
# This script checks and restores the swebirdshop.com Nginx configuration

echo "=========================================="
echo "🔍 Diagnosing swebirdshop.com 403 Error"
echo "=========================================="

# Check if Nginx is running
echo ""
echo "1. Checking Nginx status..."
/etc/init.d/nginx status || systemctl status nginx | head -5

# Check Nginx config syntax
echo ""
echo "2. Testing Nginx configuration..."
/www/server/nginx/sbin/nginx -t

# Check swebirdshop.com config file
echo ""
echo "3. Checking swebirdshop.com configuration..."
CONFIG_FILE="/www/server/panel/vhost/nginx/swebirdshop.com.conf"
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ Config file exists: $CONFIG_FILE"
    echo ""
    echo "Current configuration:"
    cat "$CONFIG_FILE"
else
    echo "❌ Config file NOT found: $CONFIG_FILE"
fi

# Check for backup files
echo ""
echo "4. Checking for backup files..."
ls -la /www/server/panel/vhost/nginx/swebirdshop.com.conf* 2>/dev/null || echo "No backup files found"

# Check proxy.conf file
echo ""
echo "5. Checking proxy.conf file..."
PROXY_CONF="/www/server/panel/vhost/proxy/swebirdshop.com/proxy.conf"
if [ -f "$PROXY_CONF" ]; then
    echo "✅ Proxy config exists: $PROXY_CONF"
    echo "First 20 lines:"
    head -20 "$PROXY_CONF"
elif [ -f "${PROXY_CONF}.bak" ]; then
    echo "⚠️  Proxy config is backed up: ${PROXY_CONF}.bak"
    echo "This might be the issue!"
    echo ""
    echo "Restoring proxy.conf..."
    mv "${PROXY_CONF}.bak" "$PROXY_CONF"
    echo "✅ Restored proxy.conf"
fi

# Check website directory permissions
echo ""
echo "6. Checking website directory permissions..."
WEB_DIR="/www/wwwroot/swebirdshop.com"
if [ -d "$WEB_DIR" ]; then
    echo "✅ Website directory exists: $WEB_DIR"
    ls -ld "$WEB_DIR"
    echo ""
    echo "Directory contents (first 5):"
    ls -la "$WEB_DIR" | head -6
else
    echo "❌ Website directory NOT found: $WEB_DIR"
fi

# Check if there are any commented out includes
echo ""
echo "7. Checking for commented includes in main config..."
if grep -q "#.*swebirdshop" /www/server/nginx/conf/nginx.conf 2>/dev/null; then
    echo "⚠️  Found commented swebirdshop references in main config!"
    grep -n "#.*swebirdshop" /www/server/nginx/conf/nginx.conf
fi

# Check error logs
echo ""
echo "8. Checking recent Nginx error logs..."
if [ -f "/www/wwwlogs/swebirdshop.com.error.log" ]; then
    echo "Recent errors:"
    tail -10 /www/wwwlogs/swebirdshop.com.error.log 2>/dev/null || echo "No errors found"
fi

echo ""
echo "=========================================="
echo "🔧 Attempting to fix..."
echo "=========================================="

# Restore proxy.conf if backed up
if [ -f "${PROXY_CONF}.bak" ]; then
    echo "Restoring proxy.conf from backup..."
    mv "${PROXY_CONF}.bak" "$PROXY_CONF"
fi

# Fix permissions
if [ -d "$WEB_DIR" ]; then
    echo "Fixing website directory permissions..."
    chown -R www:www "$WEB_DIR"
    chmod -R 755 "$WEB_DIR"
fi

# Test and reload Nginx
echo ""
echo "Testing Nginx configuration..."
if /www/server/nginx/sbin/nginx -t; then
    echo "✅ Configuration is valid"
    echo ""
    echo "Reloading Nginx..."
    /etc/init.d/nginx reload || systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Configuration has errors - please check above"
fi

echo ""
echo "=========================================="
echo "✅ Diagnostic Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check if swebirdshop.com is accessible now"
echo "2. If still 403, check file permissions: ls -la $WEB_DIR"
echo "3. Check Nginx error logs: tail -f /www/wwwlogs/swebirdshop.com.error.log"
echo "4. Verify config: cat $CONFIG_FILE"

