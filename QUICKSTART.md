# Quick Start Guide
## Get Your Virtual Phone System Running in 30 Minutes

This is a condensed guide for experienced users. For detailed instructions, see `INSTALLATION.md`.

## Prerequisites Checklist

- [ ] Contabo VPS running Ubuntu 22.04
- [ ] Root SSH access
- [ ] Domain name (optional)
- [ ] Basic Linux knowledge

## Installation Steps

### 1. Clone/Upload Project Files

```bash
cd /root
# Upload project files or clone from repository
```

### 2. Run Server Setup

```bash
chmod +x setup/server-setup.sh
sudo ./setup/server-setup.sh
```

### 3. Install Asterisk

```bash
chmod +x setup/install-asterisk.sh
sudo ./setup/install-asterisk.sh
# Wait 10-20 minutes for compilation
```

### 4. Set Up Database

```bash
# Create database via aaPanel or command line
mysql -u root -p -e "CREATE DATABASE virtual_phone_system;"
mysql -u root -p virtual_phone_system < database/schema.sql

# Create database user
mysql -u root -p -e "CREATE USER 'voip_user'@'localhost' IDENTIFIED BY 'your_secure_password';"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON virtual_phone_system.* TO 'voip_user'@'localhost';"
mysql -u root -p -e "FLUSH PRIVILEGES;"
```

### 5. Configure Asterisk

```bash
# Copy configs
cp asterisk/config/sip.conf /etc/asterisk/sip.conf
cp asterisk/config/extensions.conf /etc/asterisk/extensions.conf

# Edit passwords
nano /etc/asterisk/sip.conf
# Change "ChangeThisPassword123" to secure passwords

# Set permissions
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/spool/asterisk

# Reload
asterisk -rx "core reload"
```

### 6. Install Whisper (Optional - for STT)

```bash
chmod +x setup/install-whisper.sh
sudo ./setup/install-whisper.sh
```

### 7. Set Up Scripts

```bash
# Copy scripts
cp scripts/*.sh /usr/local/bin/
chmod +x /usr/local/bin/*.sh

# Update database credentials in scripts
nano /usr/local/bin/log-missed-call.sh
nano /usr/local/bin/transcribe-recording.sh
nano /usr/local/bin/process-recordings.sh

# Set up cron
crontab -e
# Add: */5 * * * * /usr/local/bin/process-recordings.sh >> /var/log/voip.log 2>&1
```

### 8. Deploy Dashboard

```bash
# Create website in aaPanel
# Domain: voip.yourdomain.com
# Document Root: /www/wwwroot/voip

# Copy files
mkdir -p /www/wwwroot/voip
cp -r dashboard/* /www/wwwroot/voip/
cp -r config /www/wwwroot/voip/

# Update database config
nano /www/wwwroot/voip/config/database.php

# Set permissions
chown -R www:www /www/wwwroot/voip
```

### 9. Test

1. Install SIP client (Zoiper, Linphone)
2. Configure:
   - SIP Address: `sip:1001@your-server-ip`
   - Username: `1001`
   - Password: (from sip.conf)
3. Make a test call
4. Check dashboard: `http://your-server-ip/voip/`

## Default SIP Extensions

- **1001**: Basic auto-answer with greeting
- **1002**: IVR menu system
- **1003**: Voice question recording
- **1004**: Missed call handler
- **1005**: Full call recording

## Common Issues

**Asterisk won't start:**
```bash
systemctl status asterisk
tail -f /var/log/asterisk/messages
```

**SIP calls not working:**
```bash
# Check firewall
ufw status

# Check Asterisk logs
asterisk -rvvv
```

**Dashboard not loading:**
- Check PHP errors in aaPanel
- Verify database credentials
- Check file permissions

## Next Steps

1. Customize call flows in `extensions.conf`
2. Add more SIP users in `sip.conf`
3. Configure domain DNS (if using domain)
4. Set up backups
5. Review security settings

## Support

- Full documentation: `VIRTUAL_PHONE_SYSTEM_DESIGN.md`
- Installation guide: `INSTALLATION.md`
- Check logs: `/var/log/asterisk/messages`

