#!/bin/bash

# Virtual Phone System - Asterisk Installation Script
# Installs Asterisk PBX on Ubuntu

set -e

echo "=========================================="
echo "Installing Asterisk PBX"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Install dependencies
echo "Installing Asterisk dependencies..."
apt-get update
apt-get install -y \
    build-essential \
    wget \
    libssl-dev \
    libncurses5-dev \
    libnewt-dev \
    libxml2-dev \
    linux-headers-$(uname -r) \
    libsqlite3-dev \
    uuid-dev \
    libjansson-dev \
    libcurl4-openssl-dev \
    libpcap-dev \
    libsrtp2-dev \
    libedit-dev \
    liblua5.2-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libcodec2-dev \
    libgsm1-dev \
    libmpg123-dev \
    libmp3lame-dev \
    libvorbis-dev \
    libopus-dev \
    libsndfile1-dev \
    sox \
    libsox-fmt-all

# Download Asterisk (latest stable version)
ASTERISK_VERSION="20.8.0"
ASTERISK_DIR="/usr/src/asterisk-${ASTERISK_VERSION}"

if [ ! -d "$ASTERISK_DIR" ]; then
    echo "Downloading Asterisk ${ASTERISK_VERSION}..."
    cd /usr/src
    wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}.tar.gz
    tar -xzf asterisk-${ASTERISK_VERSION}.tar.gz
    rm asterisk-${ASTERISK_VERSION}.tar.gz
fi

# Configure and compile Asterisk
echo "Configuring Asterisk..."
cd $ASTERISK_DIR
contrib/scripts/get_mp3_source.sh
./configure --with-jansson-bundled

echo "Compiling Asterisk (this may take 10-20 minutes)..."
make menuselect.makeopts
menuselect/menuselect \
    --enable app_macro \
    --enable app_playback \
    --enable app_record \
    --enable app_voicemail \
    --enable chan_sip \
    --enable res_srtp \
    --enable format_mp3 \
    --enable format_wav \
    --enable format_gsm \
    --enable format_ogg \
    --enable cdr_mysql \
    --disable BUILD_NATIVE

make
make install
make config
make samples

# Create asterisk user if it doesn't exist
if ! id "asterisk" &>/dev/null; then
    useradd -r -d /var/lib/asterisk -s /bin/false asterisk
fi

# Set permissions
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/lib/asterisk
chown -R asterisk:asterisk /var/spool/asterisk
chown -R asterisk:asterisk /var/log/asterisk
chown -R asterisk:asterisk /usr/lib/asterisk

# Enable and start Asterisk
systemctl enable asterisk
systemctl start asterisk

# Verify installation
sleep 2
if systemctl is-active --quiet asterisk; then
    echo "Asterisk is running!"
    asterisk -rx "core show version"
else
    echo "Warning: Asterisk may not have started properly. Check logs: /var/log/asterisk/messages"
fi

echo "=========================================="
echo "Asterisk installation completed!"
echo "=========================================="
echo "Next steps:"
echo "1. Configure SIP users: Edit /etc/asterisk/sip.conf"
echo "2. Configure dialplan: Edit /etc/asterisk/extensions.conf"
echo "3. Reload Asterisk: asterisk -rx 'core reload'"
echo "=========================================="

