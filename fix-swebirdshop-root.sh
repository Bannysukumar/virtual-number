#!/bin/bash
# Fix swebirdshop.com root directory issue
# The website files are in e-commerce-website-build subdirectory

echo "=========================================="
echo "🔧 Fixing swebirdshop.com Root Directory"
echo "=========================================="

WEB_ROOT="/www/wwwroot/swebirdshop.com"
SUBDIR="$WEB_ROOT/e-commerce-website-build"

echo ""
echo "1. Checking website structure..."
ls -la "$WEB_ROOT"

echo ""
echo "2. Checking subdirectory contents..."
if [ -d "$SUBDIR" ]; then
    echo "✅ Subdirectory exists: $SUBDIR"
    echo ""
    echo "Contents:"
    ls -la "$SUBDIR" | head -10
    
    # Check if there's an index file in subdirectory
    if [ -f "$SUBDIR/index.php" ] || [ -f "$SUBDIR/index.html" ]; then
        echo ""
        echo "✅ Found index file in subdirectory"
    fi
else
    echo "❌ Subdirectory not found"
    exit 1
fi

echo ""
echo "3. Checking current root directory..."
if [ -f "$WEB_ROOT/index.php" ] || [ -f "$WEB_ROOT/index.html" ]; then
    echo "✅ Index file exists in root"
else
    echo "❌ No index file in root - this is the problem!"
fi

echo ""
echo "=========================================="
echo "🔧 Fixing..."
echo "=========================================="

# Option 1: Move files from subdirectory to root (backup first)
echo ""
echo "Option 1: Moving files from subdirectory to root..."
echo "Creating backup first..."

# Backup current root (if has files)
if [ "$(ls -A $WEB_ROOT 2>/dev/null | grep -v '^\.')" ]; then
    BACKUP_DIR="${WEB_ROOT}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backing up current root to: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -r "$WEB_ROOT"/* "$BACKUP_DIR/" 2>/dev/null || true
fi

# Move files from subdirectory to root
echo "Moving files from $SUBDIR to $WEB_ROOT..."
cd "$SUBDIR"
find . -maxdepth 1 -not -name '.' -not -name '..' -exec mv {} "$WEB_ROOT/" \;

# Fix permissions
echo "Fixing permissions..."
chown -R www:www "$WEB_ROOT"
find "$WEB_ROOT" -type f -exec chmod 644 {} \;
find "$WEB_ROOT" -type d -exec chmod 755 {} \;

# Remove empty subdirectory
if [ -d "$SUBDIR" ] && [ -z "$(ls -A $SUBDIR 2>/dev/null)" ]; then
    echo "Removing empty subdirectory..."
    rmdir "$SUBDIR" 2>/dev/null || true
fi

echo ""
echo "4. Verifying fix..."
if [ -f "$WEB_ROOT/index.php" ] || [ -f "$WEB_ROOT/index.html" ]; then
    echo "✅ Index file now exists in root!"
    ls -la "$WEB_ROOT" | grep -E "index\.(php|html)"
else
    echo "⚠️  Still no index file - checking what was moved..."
    ls -la "$WEB_ROOT" | head -10
fi

echo ""
echo "5. Reloading Nginx..."
/www/server/nginx/sbin/nginx -t && /etc/init.d/nginx reload

echo ""
echo "=========================================="
echo "✅ Fix Complete"
echo "=========================================="
echo ""
echo "The website should now be accessible at: https://swebirdshop.com"
echo ""
echo "If files were moved, check: ls -la $WEB_ROOT"

