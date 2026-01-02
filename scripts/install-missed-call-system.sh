#!/bin/bash
# Complete installation script for Missed Call Callback System
# Run this on your server

set -e

echo "=========================================="
echo "🚀 Installing Missed Call Callback System"
echo "=========================================="

# Configuration
SMS_API_DIR="/root/virtual-number/missed-call-sms-api"
SCRIPTS_DIR="/usr/local/bin"
ASTERISK_CONFIG="/etc/asterisk"
DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"
DB_USER="voip_user"
DB_NAME="virtual_phone_system"

echo ""
echo "1. Installing Node.js dependencies..."
cd "$SMS_API_DIR"
if [ ! -d "node_modules" ]; then
    echo "Installing npm packages..."
    npm install
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies already installed"
fi

echo ""
echo "2. Creating database tables..."
if [ -f "/root/virtual-number/database/missed-call-schema.sql" ]; then
    mysql -u root -pf1e23f6271a741c4 "$DB_NAME" < /root/virtual-number/database/missed-call-schema.sql
    echo "✅ Database schema created"
else
    echo "⚠️  Database schema file not found, creating manually..."
    mysql -u root -pf1e23f6271a741c4 "$DB_NAME" << 'SQL'
CREATE TABLE IF NOT EXISTS missed_call_callbacks (
    callback_id INT AUTO_INCREMENT PRIMARY KEY,
    caller_number VARCHAR(50) NOT NULL COMMENT 'Phone number that gave missed call',
    sms_message TEXT DEFAULT NULL COMMENT 'Original SMS message',
    sms_from VARCHAR(50) DEFAULT NULL COMMENT 'SMS sender (SIM number)',
    callback_status ENUM('pending', 'initiated', 'ringing', 'answered', 'failed', 'completed') 
        NOT NULL DEFAULT 'pending',
    call_id INT DEFAULT NULL COMMENT 'Reference to calls table if callback succeeded',
    callback_time DATETIME DEFAULT NULL COMMENT 'When callback was initiated',
    answer_time DATETIME DEFAULT NULL COMMENT 'When callback was answered',
    duration INT DEFAULT 0 COMMENT 'Call duration in seconds',
    error_message TEXT DEFAULT NULL COMMENT 'Error details if callback failed',
    retry_count INT DEFAULT 0 COMMENT 'Number of retry attempts',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_caller_number (caller_number),
    INDEX idx_callback_status (callback_status),
    INDEX idx_callback_time (callback_time),
    INDEX idx_call_id (call_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE calls 
ADD COLUMN IF NOT EXISTS callback_type ENUM('manual', 'missed_call', 'scheduled') 
    DEFAULT NULL COMMENT 'Type of callback';

ALTER TABLE calls 
ADD COLUMN IF NOT EXISTS ivr_option_selected VARCHAR(10) DEFAULT NULL 
    COMMENT 'IVR menu option selected by caller';

ALTER TABLE calls 
ADD COLUMN IF NOT EXISTS early_media_sent TINYINT(1) DEFAULT 0 
    COMMENT 'Whether early media (progress) was sent';

CREATE INDEX IF NOT EXISTS idx_callback_type ON calls(callback_type);
CREATE INDEX IF NOT EXISTS idx_ivr_option ON calls(ivr_option_selected);
SQL
    echo "✅ Database schema created manually"
fi

echo ""
echo "3. Installing scripts..."
cp /root/virtual-number/scripts/log-call-answered.sh "$SCRIPTS_DIR/"
cp /root/virtual-number/scripts/log-call-complete.sh "$SCRIPTS_DIR/"
cp /root/virtual-number/scripts/log-callback.sh "$SCRIPTS_DIR/"
cp /root/virtual-number/scripts/log-ivr-option.sh "$SCRIPTS_DIR/"
cp /root/virtual-number/scripts/trigger-callback.sh "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR"/log-*.sh "$SCRIPTS_DIR"/trigger-callback.sh
echo "✅ Scripts installed and made executable"

echo ""
echo "4. Updating Asterisk dialplan..."
# Backup existing extensions.conf
if [ -f "$ASTERISK_CONFIG/extensions.conf" ]; then
    cp "$ASTERISK_CONFIG/extensions.conf" "$ASTERISK_CONFIG/extensions.conf.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backed up existing dialplan"
fi

# Check if callback dialplan already exists
if ! grep -q "outbound-callback" "$ASTERISK_CONFIG/extensions.conf" 2>/dev/null; then
    echo "Appending callback dialplan..."
    cat /root/virtual-number/asterisk/config/extensions-callback.conf >> "$ASTERISK_CONFIG/extensions.conf"
    echo "✅ Callback dialplan added"
else
    echo "⚠️  Callback dialplan already exists, skipping..."
fi

# Reload Asterisk dialplan
asterisk -rx "dialplan reload" 2>/dev/null || echo "⚠️  Could not reload dialplan (Asterisk may not be running)"
echo "✅ Asterisk dialplan updated"

echo ""
echo "5. Creating log directories..."
mkdir -p /var/log/asterisk
mkdir -p /var/recordings/calls
chown -R asterisk:asterisk /var/log/asterisk /var/recordings 2>/dev/null || true
echo "✅ Log directories created"

echo ""
echo "6. Setting up SMS API service..."
# Check if PM2 is available
if command -v pm2 >/dev/null 2>&1; then
    echo "Using PM2 to manage SMS API..."
    cd "$SMS_API_DIR"
    pm2 delete missed-call-api 2>/dev/null || true
    pm2 start server.js --name missed-call-api
    pm2 save
    echo "✅ SMS API started with PM2"
    echo ""
    echo "PM2 status:"
    pm2 list | grep missed-call-api || echo "Service may need a moment to start"
else
    echo "⚠️  PM2 not found. Install PM2 or run manually:"
    echo "   cd $SMS_API_DIR && node server.js"
fi

echo ""
echo "7. Testing SMS API..."
sleep 3
if curl -s http://localhost:3001/health 2>/dev/null | grep -q "ok"; then
    echo "✅ SMS API is running and responding"
else
    echo "⚠️  SMS API may not be running yet"
    echo "   Check logs: pm2 logs missed-call-api"
    echo "   Or start manually: cd $SMS_API_DIR && node server.js"
fi

echo ""
echo "=========================================="
echo "✅ Installation Complete!"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "  ✅ Node.js dependencies installed"
echo "  ✅ Database tables created"
echo "  ✅ Scripts installed"
echo "  ✅ Asterisk dialplan updated"
echo "  ✅ SMS API service configured"
echo ""
echo "🌐 SMS API Endpoint:"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "  http://$SERVER_IP:3001/sms-receiver"
echo ""
echo "📱 Next Steps:"
echo "  1. Configure Android SMS forwarding (see ANDROID_SMS_SETUP.md)"
echo "  2. Test API: curl -X POST http://localhost:3001/sms-receiver -H 'Content-Type: application/json' -d '{\"message\":\"Missed call from +919876543210\"}'"
echo "  3. Monitor logs: pm2 logs missed-call-api"
echo "  4. Check callbacks: mysql -u $DB_USER -p$DB_PASS $DB_NAME -e 'SELECT * FROM missed_call_callbacks ORDER BY created_at DESC LIMIT 5;'"
echo ""
echo "📚 Documentation:"
echo "  - Quick Start: QUICK_START.md"
echo "  - Android Setup: ANDROID_SMS_SETUP.md"
echo "  - Full Documentation: MISSED_CALL_SYSTEM_README.md"

