#!/bin/bash

# Quick fix script for call hanging up after 11 seconds
# Run as root on the server

set -e

echo "=========================================="
echo "Fixing Call Issues - Step by Step"
echo "=========================================="

# Step 1: Backup configs
echo "Step 1: Backing up configurations..."
cp /etc/asterisk/sip.conf /etc/asterisk/sip.conf.backup.$(date +%Y%m%d_%H%M%S)
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backups created"

# Step 2: Add externip to sip.conf
echo ""
echo "Step 2: Adding external IP to sip.conf..."
if ! grep -q "externip=185.216.203.209" /etc/asterisk/sip.conf; then
    sed -i '/^bindaddr=0.0.0.0/a externip=185.216.203.209\nlocalnet=192.168.0.0/255.255.0.0\nlocalnet=10.0.0.0/255.0.0.0\nlocalnet=172.16.0.0/255.240.0.0' /etc/asterisk/sip.conf
    echo "✅ External IP added"
else
    echo "⚠️  External IP already exists"
fi

# Step 3: Create recording directories
echo ""
echo "Step 3: Creating recording directories..."
mkdir -p /var/recordings/calls
mkdir -p /var/recordings/questions
chown -R asterisk:asterisk /var/recordings
chmod -R 755 /var/recordings
echo "✅ Recording directories created"

# Step 4: Copy log-call.sh script
echo ""
echo "Step 4: Installing call logging script..."
if [ -f "scripts/log-call.sh" ]; then
    cp scripts/log-call.sh /usr/local/bin/log-call.sh
    chmod +x /usr/local/bin/log-call.sh
    chown asterisk:asterisk /usr/local/bin/log-call.sh
    echo "✅ Logging script installed"
else
    echo "⚠️  scripts/log-call.sh not found - create it manually"
fi

# Step 5: Update log-missed-call.sh password
echo ""
echo "Step 5: Updating log-missed-call.sh password..."
if [ -f "/usr/local/bin/log-missed-call.sh" ]; then
    sed -i 's/DB_PASS="your_password"/DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"/' /usr/local/bin/log-missed-call.sh
    echo "✅ Password updated"
else
    echo "⚠️  log-missed-call.sh not found"
fi

# Step 6: Instructions for manual dialplan fix
echo ""
echo "=========================================="
echo "MANUAL STEPS REQUIRED:"
echo "=========================================="
echo ""
echo "1. Edit /etc/asterisk/extensions.conf"
echo "2. Replace extension 1002 section with the fixed version from FIX_CALL_ISSUES.md"
echo "3. Save and reload:"
echo "   asterisk -rx 'sip reload'"
echo "   asterisk -rx 'dialplan reload'"
echo ""
echo "=========================================="
echo "Verification Commands:"
echo "=========================================="
echo "asterisk -rx 'sip show settings' | grep externip"
echo "asterisk -rx 'dialplan show 1002'"
echo "ls -la /var/recordings/calls/"
echo ""
echo "=========================================="
echo "✅ Configuration fixes applied!"
echo "=========================================="

