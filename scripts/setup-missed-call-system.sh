#!/bin/bash
# Complete setup script for Missed Call to SIP Callback System
# Run this on your Linux server (aaPanel)

set -e

echo "=========================================="
echo "🚀 Setting Up Missed Call Callback System"
echo "=========================================="

# Configuration
SMS_API_PORT=3001
SMS_API_DIR="/www/wwwroot/missed-call-api"
SCRIPTS_DIR="/usr/local/bin"
ASTERISK_CONFIG="/etc/asterisk"

echo ""
echo "1. Installing Node.js dependencies..."
cd "$(dirname "$0")/../missed-call-sms-api"
if [ ! -d "node_modules" ]; then
    npm install
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies already installed"
fi

echo ""
echo "2. Creating database tables..."
mysql -u root -pf1e23f6271a741c4 virtual_phone_system < "$(dirname "$0")/../database/missed-call-schema.sql"
echo "✅ Database schema created"

echo ""
echo "3. Installing scripts..."
cp "$(dirname "$0")/log-call-answered.sh" "$SCRIPTS_DIR/"
cp "$(dirname "$0")/log-call-complete.sh" "$SCRIPTS_DIR/"
cp "$(dirname "$0")/log-callback.sh" "$SCRIPTS_DIR/"
cp "$(dirname "$0")/log-ivr-option.sh" "$SCRIPTS_DIR/"
cp "$(dirname "$0")/trigger-callback.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR"/*.sh
echo "✅ Scripts installed"

echo ""
echo "4. Updating Asterisk dialplan..."
# Backup existing extensions.conf
cp "$ASTERISK_CONFIG/extensions.conf" "$ASTERISK_CONFIG/extensions.conf.backup.$(date +%Y%m%d_%H%M%S)"

# Append callback dialplan
cat "$(dirname "$0")/../asterisk/config/extensions-callback.conf" >> "$ASTERISK_CONFIG/extensions.conf"

# Reload Asterisk dialplan
asterisk -rx "dialplan reload"
echo "✅ Asterisk dialplan updated"

echo ""
echo "5. Setting up SMS API service..."
# Create systemd service for SMS API
cat > /etc/systemd/system/missed-call-api.service << EOF
[Unit]
Description=Missed Call SMS Receiver API
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=$(pwd)
Environment=NODE_ENV=production
ExecStart=/usr/bin/node $(pwd)/server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable missed-call-api
systemctl start missed-call-api
echo "✅ SMS API service started"

echo ""
echo "6. Creating log directories..."
mkdir -p /var/log/asterisk
mkdir -p /var/recordings/calls
chown -R asterisk:asterisk /var/log/asterisk /var/recordings
echo "✅ Log directories created"

echo ""
echo "7. Testing SMS API..."
sleep 2
if curl -s http://localhost:$SMS_API_PORT/health | grep -q "ok"; then
    echo "✅ SMS API is running"
else
    echo "⚠️  SMS API may not be running - check logs: journalctl -u missed-call-api"
fi

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "SMS API Endpoint: http://$(hostname -I | awk '{print $1}'):$SMS_API_PORT/sms-receiver"
echo ""
echo "Next steps:"
echo "1. Configure Android SMS forwarding (see ANDROID_SMS_SETUP.md)"
echo "2. Test with: curl -X POST http://localhost:$SMS_API_PORT/sms-receiver -H 'Content-Type: application/json' -d '{\"message\":\"Missed call from +919876543210\"}'"
echo "3. Check logs: pm2 logs missed-call-api"
echo "4. Monitor callbacks: mysql -u voip_user -p virtual_phone_system -e 'SELECT * FROM missed_call_callbacks ORDER BY created_at DESC LIMIT 10;'"

