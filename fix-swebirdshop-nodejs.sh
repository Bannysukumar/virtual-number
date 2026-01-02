#!/bin/bash
# Fix swebirdshop.com for Node.js application
# Check if it's a Node.js app and configure accordingly

echo "=========================================="
echo "🔧 Fixing swebirdshop.com Node.js App"
echo "=========================================="

WEB_ROOT="/www/wwwroot/swebirdshop.com"

echo ""
echo "1. Checking application structure..."
cd "$WEB_ROOT"
ls -la

echo ""
echo "2. Checking for Node.js indicators..."
if [ -f "ecosystem.config.js" ]; then
    echo "✅ Found PM2 config (ecosystem.config.js)"
    cat ecosystem.config.js
fi

if [ -f "package.json" ]; then
    echo "✅ Found package.json"
    cat package.json | head -20
fi

echo ""
echo "3. Checking app directory..."
if [ -d "app" ]; then
    echo "✅ App directory exists"
    echo "Contents:"
    ls -la app/ | head -15
    
    # Check for index files in app directory
    if [ -f "app/index.html" ]; then
        echo "✅ Found app/index.html"
    fi
    if [ -f "app/index.php" ]; then
        echo "✅ Found app/index.php"
    fi
    if [ -d "app/build" ] || [ -d "app/dist" ] || [ -d "app/public" ]; then
        echo "✅ Found build/dist/public directory"
        ls -la app/ | grep -E "(build|dist|public)"
    fi
fi

echo ""
echo "4. Checking for build output directories..."
if [ -d "build" ] || [ -d "dist" ] || [ -d "public" ]; then
    echo "✅ Found build/dist/public in root"
    ls -la | grep -E "(build|dist|public)"
fi

echo ""
echo "=========================================="
echo "🔧 Configuring Nginx for Node.js App"
echo "=========================================="

# Check if this is a Node.js app that needs proxy
if [ -f "ecosystem.config.js" ] || [ -f "package.json" ]; then
    echo ""
    echo "This appears to be a Node.js application."
    echo "Checking PM2 status..."
    
    # Check if app is running via PM2
    if command -v pm2 >/dev/null 2>&1; then
        echo ""
        echo "PM2 processes:"
        pm2 list
        
        # Check ecosystem config for port
        if [ -f "ecosystem.config.js" ]; then
            PORT=$(grep -oP 'port[:\s]+\K\d+' ecosystem.config.js | head -1)
            if [ -n "$PORT" ]; then
                echo ""
                echo "✅ Found port in config: $PORT"
            fi
        fi
    fi
    
    echo ""
    echo "⚠️  Node.js apps typically need:"
    echo "   1. PM2 running the app on a port (e.g., 3000, 8080)"
    echo "   2. Nginx proxy configuration to forward requests to that port"
    echo ""
    echo "Checking current proxy configuration..."
    
    PROXY_CONF="/www/server/panel/vhost/nginx/proxy/swebirdshop.com/proxy.conf"
    if [ -f "$PROXY_CONF" ]; then
        echo "✅ Proxy config exists:"
        cat "$PROXY_CONF"
    else
        echo "❌ No proxy config found - need to create one"
        echo ""
        echo "Creating proxy configuration..."
        mkdir -p "$(dirname $PROXY_CONF)"
        
        # Try to detect port from ecosystem.config.js
        PORT=3000
        if [ -f "ecosystem.config.js" ]; then
            DETECTED_PORT=$(grep -oP 'port[:\s]+\K\d+' ecosystem.config.js | head -1)
            if [ -n "$DETECTED_PORT" ]; then
                PORT=$DETECTED_PORT
            fi
        fi
        
        cat > "$PROXY_CONF" << EOF
location / {
    proxy_pass http://127.0.0.1:$PORT;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_cache_bypass \$http_upgrade;
}
EOF
        echo "✅ Created proxy config pointing to port $PORT"
        echo ""
        echo "⚠️  IMPORTANT: Make sure your Node.js app is running on port $PORT"
        echo "   Check with: pm2 list"
        echo "   Start with: pm2 start ecosystem.config.js"
    fi
fi

# If it's a static site, check for index in subdirectories
echo ""
echo "5. Checking for static files..."
if [ -d "app/public" ]; then
    echo "Found app/public - checking for index..."
    if [ -f "app/public/index.html" ]; then
        echo "✅ Found app/public/index.html"
        echo "Creating symlink..."
        ln -sf app/public/index.html index.html 2>/dev/null || true
    fi
elif [ -d "app/build" ]; then
    echo "Found app/build - checking for index..."
    if [ -f "app/build/index.html" ]; then
        echo "✅ Found app/build/index.html"
        echo "Creating symlink..."
        ln -sf app/build/index.html index.html 2>/dev/null || true
    fi
elif [ -d "app/dist" ]; then
    echo "Found app/dist - checking for index..."
    if [ -f "app/dist/index.html" ]; then
        echo "✅ Found app/dist/index.html"
        echo "Creating symlink..."
        ln -sf app/dist/index.html index.html 2>/dev/null || true
    fi
fi

echo ""
echo "6. Final check for index files..."
cd "$WEB_ROOT"
if [ -f "index.html" ] || [ -f "index.php" ]; then
    echo "✅ Index file found!"
    ls -la index.*
else
    echo "⚠️  Still no index file in root"
    echo ""
    echo "Current directory structure:"
    find . -maxdepth 2 -name "index.*" -type f 2>/dev/null | head -10
fi

echo ""
echo "7. Reloading Nginx..."
/www/server/nginx/sbin/nginx -t && /etc/init.d/nginx reload

echo ""
echo "=========================================="
echo "✅ Configuration Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. If Node.js app: Ensure PM2 is running: pm2 list"
echo "2. If Node.js app: Start app if needed: pm2 start ecosystem.config.js"
echo "3. Check website: https://swebirdshop.com"
echo "4. Check logs: tail -f /www/wwwlogs/swebirdshop.com.error.log"

