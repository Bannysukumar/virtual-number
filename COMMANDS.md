# Deployment Commands
## Step-by-Step Commands to Deploy Virtual Phone System

## Prerequisites
- Contabo VPS IP address
- Root/SSH access to server
- Project files ready on Windows

---

## STEP 1: Upload Files to Server (Choose One Method)

### Method A: Using PowerShell SCP (Windows 10/11)

```powershell
# Navigate to project folder
cd "C:\Users\munna\Downloads\New folder (12)"

# Upload all files to server (replace YOUR_SERVER_IP)
scp -r * root@YOUR_SERVER_IP:/root/virtual-phone-system/
```

**Note**: If asked for password, enter your server's root password.

### Method B: Using WinSCP (GUI Method)

1. Download WinSCP: https://winscp.net/eng/download.php
2. Install and open
3. Connect:
   - Host: `YOUR_SERVER_IP`
   - Username: `root`
   - Password: (your server password)
4. Navigate to `/root/` on server
5. Drag and drop all files from Windows folder

### Method C: Using PuTTY/PSFTP

```powershell
# Start PSFTP
psftp root@YOUR_SERVER_IP

# Once connected:
cd /root
lcd "C:\Users\munna\Downloads\New folder (12)"
put -r *
```

---

## STEP 2: Connect to Server via SSH

### Using PowerShell:

```powershell
ssh root@YOUR_SERVER_IP
```

### Using PuTTY:

1. Open PuTTY
2. Enter server IP
3. Click Open
4. Login as `root`

---

## STEP 3: Run Deployment Commands on Server

Once connected to your server via SSH, run these commands:

```bash
# Navigate to project directory
cd /root/virtual-phone-system

# Make deployment script executable
chmod +x deploy.sh

# Make all setup scripts executable
chmod +x setup/*.sh
chmod +x scripts/*.sh

# Run the deployment script
./deploy.sh
```

**During deployment, you'll be prompted for:**
- MySQL root password (if MySQL not installed)
- Confirmation for each step

**To skip prompts (automatic mode):**
```bash
./deploy.sh --yes
```

---

## STEP 4: Verify Installation

After deployment completes, verify everything works:

```bash
# Check Asterisk is running
systemctl status asterisk

# Check Asterisk version
asterisk -rx "core show version"

# Check SIP users are configured
asterisk -rx "sip show peers"

# Check database
mysql -u voip_user -p -e "USE virtual_phone_system; SHOW TABLES;"
# (Password will be shown during deployment)

# Check dashboard is accessible
curl http://localhost/voip/
```

---

## STEP 5: Get SIP Passwords

```bash
# View all SIP user passwords
grep "secret=" /etc/asterisk/sip.conf | grep -v "^;"

# Or view specific extension
grep -A 5 "^\[1001\]" /etc/asterisk/sip.conf | grep secret
```

---

## Alternative: Manual Step-by-Step Deployment

If you prefer manual control instead of automated script:

```bash
# 1. Server setup
cd /root/virtual-phone-system
chmod +x setup/server-setup.sh
./setup/server-setup.sh

# 2. Install Asterisk
chmod +x setup/install-asterisk.sh
./setup/install-asterisk.sh

# 3. Create database
mysql -u root -p < database/schema.sql
# (Enter MySQL root password when prompted)

# 4. Create database user
mysql -u root -p
# Then in MySQL prompt:
CREATE USER 'voip_user'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON virtual_phone_system.* TO 'voip_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# 5. Copy Asterisk configs
cp asterisk/config/sip.conf /etc/asterisk/sip.conf
cp asterisk/config/extensions.conf /etc/asterisk/extensions.conf

# 6. Set permissions
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/spool/asterisk

# 7. Reload Asterisk
asterisk -rx "core reload"

# 8. Install Whisper (optional)
chmod +x setup/install-whisper.sh
./setup/install-whisper.sh

# 9. Setup scripts
cp scripts/*.sh /usr/local/bin/
chmod +x /usr/local/bin/*.sh

# 10. Setup cron
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/process-recordings.sh >> /var/log/voip-processing.log 2>&1") | crontab -

# 11. Deploy dashboard
mkdir -p /www/wwwroot/voip
cp -r dashboard/* /www/wwwroot/voip/
cp -r config /www/wwwroot/voip/
chown -R www:www /www/wwwroot/voip
```

---

## Quick Copy-Paste Commands (All-in-One)

Copy and paste this entire block (replace `YOUR_SERVER_IP`):

```bash
# Connect to server
ssh root@YOUR_SERVER_IP

# Once connected, run:
cd /root/virtual-phone-system && \
chmod +x deploy.sh setup/*.sh scripts/*.sh && \
./deploy.sh --yes
```

---

## Post-Deployment Commands

### View Logs:
```bash
# Asterisk logs
tail -f /var/log/asterisk/messages

# Processing logs
tail -f /var/log/voip-processing.log

# System logs
journalctl -u asterisk -f
```

### Restart Services:
```bash
# Restart Asterisk
systemctl restart asterisk

# Reload Asterisk config (without restart)
asterisk -rx "core reload"
asterisk -rx "sip reload"
```

### Check System Status:
```bash
# Check all services
systemctl status asterisk
systemctl status mysql
systemctl status nginx  # or apache2

# Check disk space
df -h

# Check memory
free -h

# Check active calls
asterisk -rx "core show channels"
```

---

## Troubleshooting Commands

### If Asterisk won't start:
```bash
# Check status
systemctl status asterisk

# View errors
tail -50 /var/log/asterisk/messages

# Start manually
systemctl start asterisk

# Check configuration
asterisk -rx "core show settings"
```

### If SIP not working:
```bash
# Check firewall
ufw status

# Check SIP port is listening
netstat -ulnp | grep 5060

# Enable verbose logging
asterisk -rvvv
```

### If database connection fails:
```bash
# Test MySQL connection
mysql -u voip_user -p virtual_phone_system

# Check database exists
mysql -u root -p -e "SHOW DATABASES;"

# Check user permissions
mysql -u root -p -e "SHOW GRANTS FOR 'voip_user'@'localhost';"
```

---

## Example: Complete Deployment Session

```bash
# 1. Connect
ssh root@192.168.1.100

# 2. Navigate and deploy
cd /root/virtual-phone-system
chmod +x deploy.sh
./deploy.sh

# 3. When prompted, enter MySQL root password
# 4. Wait for installation (25-40 minutes)
# 5. Get SIP passwords
grep "secret=" /etc/asterisk/sip.conf | head -3

# 6. Test Asterisk
asterisk -rx "core show version"

# 7. Check dashboard
curl http://localhost/voip/
```

---

## Quick Reference Card

```bash
# DEPLOYMENT
cd /root/virtual-phone-system && chmod +x deploy.sh && ./deploy.sh

# CHECK STATUS
systemctl status asterisk
asterisk -rx "core show version"

# VIEW PASSWORDS
grep "secret=" /etc/asterisk/sip.conf

# VIEW LOGS
tail -f /var/log/asterisk/messages

# RELOAD CONFIG
asterisk -rx "core reload"

# RESTART SERVICE
systemctl restart asterisk
```

---

**Replace `YOUR_SERVER_IP` with your actual Contabo VPS IP address!**

