#!/bin/bash

# Virtual Phone System - Server Setup Script
# This script prepares the Ubuntu server for the virtual phone system

set -e

echo "=========================================="
echo "Virtual Phone System - Server Setup"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt-get install -y \
    build-essential \
    wget \
    curl \
    git \
    vim \
    net-tools \
    ufw \
    fail2ban \
    htop \
    unzip \
    software-properties-common

# Configure firewall
echo "Configuring firewall (UFW)..."
ufw --force enable
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw allow 5060/udp    # SIP signaling
ufw allow 5060/tcp    # SIP signaling (TCP)
ufw allow 5061/tcp    # SIP over TLS
ufw allow 10000:20000/udp  # RTP media range

echo "Firewall configured. Ports opened:"
ufw status

# Create necessary directories
echo "Creating directory structure..."
mkdir -p /var/spool/asterisk/monitor
mkdir -p /var/recordings/calls
mkdir -p /var/recordings/questions
mkdir -p /var/recordings/transcriptions
mkdir -p /var/log/asterisk
chown -R asterisk:asterisk /var/spool/asterisk 2>/dev/null || true
chown -R asterisk:asterisk /var/log/asterisk 2>/dev/null || true

# Set timezone (optional - adjust as needed)
echo "Setting timezone to UTC..."
timedatectl set-timezone UTC

# Install fail2ban for SIP protection
echo "Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

echo "=========================================="
echo "Server setup completed!"
echo "=========================================="
echo "Next steps:"
echo "1. Install Asterisk: ./setup/install-asterisk.sh"
echo "2. Set up database: mysql -u root -p < database/schema.sql"
echo "3. Configure Asterisk files"
echo "=========================================="

