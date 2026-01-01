#!/bin/bash

# Virtual Phone System - Master Deployment Script
# Run this script on your Contabo VPS (Ubuntu) to deploy the entire system

set -e

echo "=========================================="
echo "Virtual Phone System - Deployment"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use: sudo ./deploy.sh)"
    exit 1
fi

# Check OS
if [ ! -f /etc/os-release ]; then
    echo "❌ Cannot detect OS. This script requires Ubuntu."
    exit 1
fi

. /etc/os-release
if [ "$ID" != "ubuntu" ]; then
    echo "⚠️  Warning: This script is designed for Ubuntu. Detected: $ID"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✅ OS Check: $PRETTY_NAME"
echo ""

# Configuration
INSTALL_ASTERISK=true
INSTALL_WHISPER=true
SETUP_DATABASE=true
SETUP_DASHBOARD=true
SKIP_PROMPTS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-asterisk)
            INSTALL_ASTERISK=false
            shift
            ;;
        --no-whisper)
            INSTALL_WHISPER=false
            shift
            ;;
        --no-database)
            SETUP_DATABASE=false
            shift
            ;;
        --no-dashboard)
            SETUP_DASHBOARD=false
            shift
            ;;
        --yes)
            SKIP_PROMPTS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./deploy.sh [--no-asterisk] [--no-whisper] [--no-database] [--no-dashboard] [--yes]"
            exit 1
            ;;
    esac
done

# Get project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "📁 Project Directory: $PROJECT_DIR"
echo ""

# Step 1: Server Setup
echo "=========================================="
echo "Step 1/7: Server Setup"
echo "=========================================="
if [ -f "setup/server-setup.sh" ]; then
    chmod +x setup/server-setup.sh
    ./setup/server-setup.sh
    echo "✅ Server setup completed"
else
    echo "❌ setup/server-setup.sh not found!"
    exit 1
fi
echo ""

# Step 2: Install Asterisk
if [ "$INSTALL_ASTERISK" = true ]; then
    echo "=========================================="
    echo "Step 2/7: Installing Asterisk PBX"
    echo "=========================================="
    echo "⚠️  This will take 10-20 minutes..."
    
    if [ "$SKIP_PROMPTS" = false ]; then
        read -p "Continue with Asterisk installation? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_ASTERISK=false
        fi
    fi
    
    if [ "$INSTALL_ASTERISK" = true ]; then
        if [ -f "setup/install-asterisk.sh" ]; then
            chmod +x setup/install-asterisk.sh
            ./setup/install-asterisk.sh
            echo "✅ Asterisk installation completed"
        else
            echo "❌ setup/install-asterisk.sh not found!"
        fi
    fi
else
    echo "⏭️  Skipping Asterisk installation (--no-asterisk)"
fi
echo ""

# Step 3: Database Setup
if [ "$SETUP_DATABASE" = true ]; then
    echo "=========================================="
    echo "Step 3/7: Database Setup"
    echo "=========================================="
    
    # Check if MySQL is installed
    if ! command -v mysql &> /dev/null; then
        echo "⚠️  MySQL not found. Installing MySQL..."
        apt-get update
        apt-get install -y mysql-server
        systemctl start mysql
        systemctl enable mysql
    fi
    
    # Get database root password
    if [ "$SKIP_PROMPTS" = false ]; then
        echo "Enter MySQL root password:"
        read -s DB_ROOT_PASS
    else
        DB_ROOT_PASS=""
    fi
    
    # Create database
    if [ -f "database/schema.sql" ]; then
        echo "Creating database..."
        if [ -z "$DB_ROOT_PASS" ]; then
            mysql -u root < database/schema.sql
        else
            mysql -u root -p"$DB_ROOT_PASS" < database/schema.sql
        fi
        echo "✅ Database created"
        
        # Create database user
        echo "Creating database user..."
        DB_USER="voip_user"
        DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        
        if [ -z "$DB_ROOT_PASS" ]; then
            mysql -u root <<EOF
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON virtual_phone_system.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
        else
            mysql -u root -p"$DB_ROOT_PASS" <<EOF
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON virtual_phone_system.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
        fi
        
        echo "✅ Database user created: $DB_USER"
        echo "📝 Database password: $DB_PASS"
        echo "⚠️  SAVE THIS PASSWORD! Update config/database.php and scripts with it."
        
        # Update config file
        if [ -f "config/database.php" ]; then
            sed -i "s/'password' => 'your_password'/'password' => '$DB_PASS'/" config/database.php
            echo "✅ Updated config/database.php"
        fi
    else
        echo "❌ database/schema.sql not found!"
    fi
else
    echo "⏭️  Skipping database setup (--no-database)"
fi
echo ""

# Step 4: Configure Asterisk
if [ "$INSTALL_ASTERISK" = true ]; then
    echo "=========================================="
    echo "Step 4/7: Configuring Asterisk"
    echo "=========================================="
    
    if [ -f "asterisk/config/sip.conf" ] && [ -f "asterisk/config/extensions.conf" ]; then
        # Backup original configs
        if [ -f "/etc/asterisk/sip.conf" ]; then
            cp /etc/asterisk/sip.conf /etc/asterisk/sip.conf.backup.$(date +%Y%m%d_%H%M%S)
        fi
        if [ -f "/etc/asterisk/extensions.conf" ]; then
            cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.$(date +%Y%m%d_%H%M%S)
        fi
        
        # Copy new configs
        cp asterisk/config/sip.conf /etc/asterisk/sip.conf
        cp asterisk/config/extensions.conf /etc/asterisk/extensions.conf
        
        # Generate random passwords for SIP users
        echo "Generating secure passwords for SIP users..."
        for ext in 1001 1002 1003; do
            NEW_PASS=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)
            sed -i "s/secret=ChangeThisPassword123/secret=$NEW_PASS/" /etc/asterisk/sip.conf
            echo "  Extension $ext password: $NEW_PASS"
        done
        
        # Set permissions
        chown -R asterisk:asterisk /etc/asterisk
        chown -R asterisk:asterisk /var/spool/asterisk
        chown -R asterisk:asterisk /var/log/asterisk
        
        # Reload Asterisk
        if systemctl is-active --quiet asterisk; then
            asterisk -rx "core reload" 2>/dev/null || true
            asterisk -rx "sip reload" 2>/dev/null || true
            echo "✅ Asterisk configured and reloaded"
        else
            echo "⚠️  Asterisk not running. Start it with: systemctl start asterisk"
        fi
    else
        echo "❌ Asterisk config files not found!"
    fi
else
    echo "⏭️  Skipping Asterisk configuration"
fi
echo ""

# Step 5: Install Whisper
if [ "$INSTALL_WHISPER" = true ]; then
    echo "=========================================="
    echo "Step 5/7: Installing Whisper.cpp (STT)"
    echo "=========================================="
    
    if [ "$SKIP_PROMPTS" = false ]; then
        read -p "Install Whisper for speech-to-text? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_WHISPER=false
        fi
    fi
    
    if [ "$INSTALL_WHISPER" = true ]; then
        if [ -f "setup/install-whisper.sh" ]; then
            chmod +x setup/install-whisper.sh
            ./setup/install-whisper.sh
            echo "✅ Whisper installation completed"
        else
            echo "❌ setup/install-whisper.sh not found!"
        fi
    fi
else
    echo "⏭️  Skipping Whisper installation (--no-whisper)"
fi
echo ""

# Step 6: Setup Helper Scripts
echo "=========================================="
echo "Step 6/7: Setting Up Helper Scripts"
echo "=========================================="

if [ -d "scripts" ]; then
    # Copy scripts
    cp scripts/*.sh /usr/local/bin/ 2>/dev/null || true
    chmod +x /usr/local/bin/*.sh 2>/dev/null || true
    
    # Update database credentials in scripts if we have them
    if [ -n "$DB_PASS" ]; then
        for script in /usr/local/bin/log-missed-call.sh /usr/local/bin/transcribe-recording.sh /usr/local/bin/process-recordings.sh; do
            if [ -f "$script" ]; then
                sed -i "s/DB_PASS=\"your_password\"/DB_PASS=\"$DB_PASS\"/" "$script"
                sed -i "s/DB_USER=\"voip_user\"/DB_USER=\"$DB_USER\"/" "$script"
            fi
        done
    fi
    
    # Setup cron job
    if [ "$SKIP_PROMPTS" = false ]; then
        read -p "Set up cron job for recording processing? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/process-recordings.sh >> /var/log/voip-processing.log 2>&1") | crontab -
            echo "✅ Cron job added"
        fi
    else
        (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/process-recordings.sh >> /var/log/voip-processing.log 2>&1") | crontab -
        echo "✅ Cron job added"
    fi
    
    echo "✅ Helper scripts configured"
else
    echo "❌ scripts directory not found!"
fi
echo ""

# Step 7: Setup Dashboard
if [ "$SETUP_DASHBOARD" = true ]; then
    echo "=========================================="
    echo "Step 7/7: Setting Up Admin Dashboard"
    echo "=========================================="
    
    # Check for aaPanel or create directory
    DASHBOARD_DIR="/www/wwwroot/voip"
    
    if [ ! -d "/www/wwwroot" ]; then
        # Try common web directories
        if [ -d "/var/www/html" ]; then
            DASHBOARD_DIR="/var/www/html/voip"
        elif [ -d "/var/www" ]; then
            DASHBOARD_DIR="/var/www/voip"
        else
            echo "⚠️  Web directory not found. Creating /var/www/voip"
            mkdir -p /var/www/voip
            DASHBOARD_DIR="/var/www/voip"
        fi
    fi
    
    mkdir -p "$DASHBOARD_DIR"
    
    # Copy dashboard files
    if [ -d "dashboard" ]; then
        cp -r dashboard/* "$DASHBOARD_DIR/"
        cp -r config "$DASHBOARD_DIR/" 2>/dev/null || true
        
        # Update database config if we have credentials
        if [ -n "$DB_PASS" ] && [ -f "$DASHBOARD_DIR/config/database.php" ]; then
            sed -i "s/'password' => 'your_password'/'password' => '$DB_PASS'/" "$DASHBOARD_DIR/config/database.php"
        fi
        
        # Set permissions
        if id "www-data" &>/dev/null; then
            chown -R www-data:www-data "$DASHBOARD_DIR"
        elif id "www" &>/dev/null; then
            chown -R www:www "$DASHBOARD_DIR"
        fi
        chmod -R 755 "$DASHBOARD_DIR"
        
        echo "✅ Dashboard deployed to: $DASHBOARD_DIR"
        echo "📝 Access at: http://$(hostname -I | awk '{print $1}')/voip/"
    else
        echo "❌ dashboard directory not found!"
    fi
else
    echo "⏭️  Skipping dashboard setup (--no-dashboard)"
fi
echo ""

# Final Summary
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "  - Server: Configured"
if [ "$INSTALL_ASTERISK" = true ]; then
    echo "  - Asterisk: Installed and configured"
    echo "    SIP Extensions: 1001, 1002, 1003, 1004, 1005"
    echo "    Check passwords in: /etc/asterisk/sip.conf"
fi
if [ "$SETUP_DATABASE" = true ]; then
    echo "  - Database: Created"
    echo "    User: $DB_USER"
    echo "    Password: $DB_PASS (saved in config files)"
fi
if [ "$INSTALL_WHISPER" = true ]; then
    echo "  - Whisper: Installed"
fi
echo "  - Scripts: Configured"
if [ "$SETUP_DASHBOARD" = true ]; then
    echo "  - Dashboard: Deployed to $DASHBOARD_DIR"
fi
echo ""
echo "🔧 Next Steps:"
echo "  1. Configure SIP client with extension 1001"
echo "  2. Test a call to verify system works"
echo "  3. Access dashboard: http://$(hostname -I | awk '{print $1}')/voip/"
echo "  4. Review and customize: /etc/asterisk/extensions.conf"
echo ""
echo "📚 Documentation:"
echo "  - Full Guide: INSTALLATION.md"
echo "  - Quick Start: QUICKSTART.md"
echo "  - System Design: VIRTUAL_PHONE_SYSTEM_DESIGN.md"
echo ""
echo "=========================================="

