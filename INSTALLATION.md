# Installation Guide
## Virtual Phone System - Step by Step Setup

This guide will walk you through setting up the complete virtual phone system on your Contabo VPS with aaPanel.

## Prerequisites

- Contabo VPS with Ubuntu 22.04 LTS
- Root/SSH access to server
- Domain name (optional but recommended)
- Basic Linux command line knowledge

## Step 1: Initial Server Setup

### 1.1 Connect to Your Server

```bash
ssh root@your-server-ip
```

### 1.2 Update System

```bash
apt-get update && apt-get upgrade -y
```

### 1.3 Run Server Setup Script

```bash
cd /root
# Upload or clone the project files
chmod +x setup/server-setup.sh
sudo ./setup/server-setup.sh
```

This will:
- Install essential packages
- Configure firewall (UFW)
- Create necessary directories
- Set up fail2ban

## Step 2: Install aaPanel (If Not Already Installed)

```bash
wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && sudo bash install.sh aapanel
```

Follow the installation prompts and note your login credentials.

## Step 3: Install Asterisk PBX

```bash
chmod +x setup/install-asterisk.sh
sudo ./setup/install-asterisk.sh
```

This will:
- Install all dependencies
- Download and compile Asterisk
- Set up Asterisk service
- Configure basic settings

**Note**: Compilation may take 10-20 minutes depending on server specs.

### 3.1 Verify Asterisk Installation

```bash
systemctl status asterisk
asterisk -rx "core show version"
```

## Step 4: Configure Database

### 4.1 Create Database via aaPanel

1. Login to aaPanel: `http://your-server-ip:7800`
2. Go to **Database** → **MySQL**
3. Create new database: `virtual_phone_system`
4. Create database user: `voip_user`
5. Grant all privileges to user on database

### 4.2 Import Database Schema

```bash
mysql -u root -p < database/schema.sql
```

Or via aaPanel MySQL management interface.

### 4.3 Update Database Credentials

Edit `config/database.php` with your database credentials:

```php
'username' => 'voip_user',
'password' => 'your_actual_password',
```

## Step 5: Configure Asterisk

### 5.1 Copy Configuration Files

```bash
# Backup original configs
cp /etc/asterisk/sip.conf /etc/asterisk/sip.conf.backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup

# Copy new configs
cp asterisk/config/sip.conf /etc/asterisk/sip.conf
cp asterisk/config/extensions.conf /etc/asterisk/extensions.conf
```

### 5.2 Edit SIP Configuration

Edit `/etc/asterisk/sip.conf`:

1. Change default passwords for SIP users (1001, 1002, 1003)
2. Update domain if using domain-based SIP
3. Adjust RTP port range if needed

### 5.3 Edit Extensions Configuration

Edit `/etc/asterisk/extensions.conf`:

1. Review call flows for extensions 1001-1005
2. Adjust paths and settings as needed
3. Add your own custom flows

### 5.4 Set Permissions

```bash
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/spool/asterisk
chown -R asterisk:asterisk /var/log/asterisk
```

### 5.5 Reload Asterisk

```bash
asterisk -rx "core reload"
asterisk -rx "sip reload"
```

## Step 6: Install Whisper.cpp (Speech-to-Text)

```bash
chmod +x setup/install-whisper.sh
sudo ./setup/install-whisper.sh
```

This will:
- Install Whisper.cpp dependencies
- Compile Whisper.cpp
- Download base model (~150 MB)

**Note**: For better accuracy, you can download larger models (small, medium, large) but they require more processing power.

## Step 7: Set Up Helper Scripts

### 7.1 Copy Scripts

```bash
cp scripts/*.sh /usr/local/bin/
chmod +x /usr/local/bin/*.sh
```

### 7.2 Update Script Credentials

Edit each script and update database credentials:

- `/usr/local/bin/log-missed-call.sh`
- `/usr/local/bin/transcribe-recording.sh`
- `/usr/local/bin/process-recordings.sh`

### 7.3 Set Up Cron Jobs

```bash
crontab -e
```

Add these lines:

```cron
# Process recordings every 5 minutes
*/5 * * * * /usr/local/bin/process-recordings.sh >> /var/log/voip-processing.log 2>&1

# Clean old recordings (older than 90 days) - daily at 2 AM
0 2 * * * find /var/recordings -type f -mtime +90 -delete
```

## Step 8: Set Up Admin Dashboard

### 8.1 Create Website in aaPanel

1. Login to aaPanel
2. Go to **Website** → **Add Site**
3. Domain: `voip.yourdomain.com` (or use IP)
4. Document Root: `/www/wwwroot/voip`
5. PHP Version: 7.4 or higher

### 8.2 Upload Dashboard Files

```bash
# Create directory
mkdir -p /www/wwwroot/voip

# Copy dashboard files
cp -r dashboard/* /www/wwwroot/voip/
cp -r config /www/wwwroot/voip/

# Set permissions
chown -R www:www /www/wwwroot/voip
chmod -R 755 /www/wwwroot/voip
```

### 8.3 Configure Database Connection

Edit `/www/wwwroot/voip/config/database.php` with your credentials.

### 8.4 Access Dashboard

Open browser: `http://your-server-ip/voip/` or `http://voip.yourdomain.com`

## Step 9: Configure DNS (If Using Domain)

### 9.1 Create DNS Records

Add these records in your domain DNS:

- **A Record**: `sip.yourdomain.com` → Your VPS IP
- **SRV Record**: `_sip._udp.yourdomain.com` → `sip.yourdomain.com:5060`
- **SRV Record**: `_sips._tcp.yourdomain.com` → `sip.yourdomain.com:5061`

### 9.2 Update SIP Configuration

Edit `/etc/asterisk/sip.conf` and set your domain in the `[general]` section.

## Step 10: Test the System

### 10.1 Test SIP Connection

Install a SIP client on your phone/computer:
- **Android**: Zoiper, Linphone
- **iOS**: Groundwire, Linphone
- **Windows/Mac**: Zoiper, X-Lite

Configure SIP client:
- **SIP Address**: `sip:1001@sip.yourdomain.com` (or `sip:1001@your-ip`)
- **Username**: `1001`
- **Password**: (password from sip.conf)
- **Server**: `sip.yourdomain.com` (or your IP)

### 10.2 Make Test Call

1. Call extension 1001 (basic auto-answer)
2. Call extension 1002 (IVR menu)
3. Call extension 1003 (voice questions)

### 10.3 Check Dashboard

1. Login to admin dashboard
2. Verify calls appear in call logs
3. Check recordings are being saved
4. Verify transcriptions are processing

## Step 11: Security Hardening

### 11.1 Change Default Passwords

- Change all SIP user passwords in `sip.conf`
- Change database passwords
- Change aaPanel admin password

### 11.2 Configure fail2ban for SIP

Create `/etc/fail2ban/filter.d/asterisk.conf`:

```ini
[Definition]
failregex = NOTICE.* .*: Registration from '.*' failed for '<HOST>(:\d+)?' - Wrong password
            NOTICE.* .*: Registration from '.*' failed for '<HOST>(:\d+)?' - No matching peer found
            NOTICE.* .*: Registration from '.*' failed for '<HOST>(:\d+)?' - Username/auth mismatch
ignoreregex =
```

Create `/etc/fail2ban/jail.d/asterisk.conf`:

```ini
[asterisk]
enabled = true
port = 5060,5061
filter = asterisk
logpath = /var/log/asterisk/messages
maxretry = 5
bantime = 3600
```

Restart fail2ban:

```bash
systemctl restart fail2ban
```

## Troubleshooting

### Asterisk Not Starting

```bash
# Check logs
tail -f /var/log/asterisk/messages

# Check status
systemctl status asterisk

# Start manually
systemctl start asterisk
```

### SIP Calls Not Working

1. Check firewall: `ufw status`
2. Check Asterisk logs: `tail -f /var/log/asterisk/messages`
3. Verify SIP user credentials
4. Test with `asterisk -rvvv` (verbose mode)

### Recordings Not Processing

1. Check script permissions: `ls -la /usr/local/bin/*.sh`
2. Check cron logs: `grep CRON /var/log/syslog`
3. Manually run: `/usr/local/bin/process-recordings.sh`
4. Check database connection in scripts

### Dashboard Not Loading

1. Check PHP errors: `/www/wwwroot/voip/error.log`
2. Verify database connection in `config/database.php`
3. Check file permissions: `ls -la /www/wwwroot/voip/`
4. Check Nginx/Apache error logs via aaPanel

## Next Steps

1. **Customize Call Flows**: Edit `extensions.conf` for your needs
2. **Add More SIP Users**: Add more virtual numbers in `sip.conf`
3. **Integrate PSTN Gateway**: For receiving calls from regular phones
4. **Set Up AI Voice Agent**: Follow Step 8 in design document
5. **Configure Backups**: Set up automated backups

## Support

For detailed system design and architecture, see `VIRTUAL_PHONE_SYSTEM_DESIGN.md`.

For issues:
1. Check logs: `/var/log/asterisk/messages`
2. Check dashboard logs
3. Review configuration files
4. Test each component individually

