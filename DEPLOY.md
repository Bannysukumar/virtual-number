# Deployment Guide
## How to Run the Virtual Phone System

## Prerequisites

Before running, ensure you have:
1. **Contabo VPS** with Ubuntu 22.04 LTS
2. **SSH access** to your server
3. **Root or sudo privileges**

## Quick Deployment (Automated)

### Step 1: Upload Project to Server

**Option A: Using SCP (from your local machine)**
```bash
scp -r . root@your-server-ip:/root/virtual-phone-system/
```

**Option B: Using Git (if you have a repository)**
```bash
ssh root@your-server-ip
cd /root
git clone your-repository-url virtual-phone-system
cd virtual-phone-system
```

**Option C: Manual Upload**
- Use FTP/SFTP client (FileZilla, WinSCP)
- Upload all files to `/root/virtual-phone-system/` on your server

### Step 2: Run Deployment Script

```bash
ssh root@your-server-ip
cd /root/virtual-phone-system
chmod +x deploy.sh
./deploy.sh
```

The script will:
- ✅ Set up the server (firewall, directories)
- ✅ Install Asterisk PBX
- ✅ Create and configure database
- ✅ Install Whisper.cpp (speech-to-text)
- ✅ Configure Asterisk with default settings
- ✅ Set up helper scripts and cron jobs
- ✅ Deploy admin dashboard

**Interactive Mode:**
The script will prompt you for:
- MySQL root password
- Confirmation for each major step

**Non-Interactive Mode:**
```bash
./deploy.sh --yes
```

**Selective Installation:**
```bash
# Skip Whisper (if you don't need STT)
./deploy.sh --no-whisper

# Skip dashboard (if deploying separately)
./deploy.sh --no-dashboard

# Install only Asterisk
./deploy.sh --no-whisper --no-dashboard --no-database
```

### Step 3: Verify Installation

```bash
# Check Asterisk status
systemctl status asterisk

# Check Asterisk version
asterisk -rx "core show version"

# Check database
mysql -u voip_user -p -e "USE virtual_phone_system; SHOW TABLES;"

# Check dashboard
curl http://localhost/voip/
```

## Manual Deployment (Step by Step)

If you prefer manual control, follow `INSTALLATION.md` for detailed step-by-step instructions.

## Post-Deployment Configuration

### 1. Get SIP User Passwords

After deployment, check SIP passwords:
```bash
grep "secret=" /etc/asterisk/sip.conf
```

### 2. Configure SIP Client

Install a SIP client on your phone/computer:
- **Android**: Zoiper, Linphone
- **iOS**: Groundwire, Linphone  
- **Windows/Mac**: Zoiper, X-Lite

**SIP Configuration:**
- **SIP Address**: `sip:1001@your-server-ip` (or `sip:1001@sip.yourdomain.com` if using domain)
- **Username**: `1001`
- **Password**: (from sip.conf)
- **Server**: `your-server-ip` (or `sip.yourdomain.com`)

### 3. Test the System

1. **Make a test call** to extension 1001
2. **Check Asterisk logs**: `tail -f /var/log/asterisk/messages`
3. **Access dashboard**: `http://your-server-ip/voip/`
4. **Verify call appears** in dashboard

### 4. Configure Domain (Optional)

If you have a domain:

1. **DNS Records:**
   - A Record: `sip.yourdomain.com` → Your VPS IP
   - SRV Record: `_sip._udp.yourdomain.com` → `sip.yourdomain.com:5060`

2. **Update Asterisk:**
   ```bash
   nano /etc/asterisk/sip.conf
   # Update domain settings in [general] section
   ```

3. **Reload Asterisk:**
   ```bash
   asterisk -rx "sip reload"
   ```

## Troubleshooting

### Asterisk Not Starting

```bash
# Check status
systemctl status asterisk

# Check logs
tail -f /var/log/asterisk/messages

# Start manually
systemctl start asterisk

# Check configuration
asterisk -rx "core show settings"
```

### SIP Calls Not Working

```bash
# Check firewall
ufw status

# Check SIP is listening
netstat -ulnp | grep 5060

# Enable verbose logging
asterisk -rvvv

# Test SIP registration
asterisk -rx "sip show peers"
```

### Dashboard Not Loading

```bash
# Check web server
systemctl status nginx  # or apache2

# Check PHP
php -v

# Check file permissions
ls -la /www/wwwroot/voip/

# Check error logs
tail -f /var/log/nginx/error.log  # or apache2/error.log
```

### Database Connection Issues

```bash
# Test connection
mysql -u voip_user -p virtual_phone_system

# Check credentials in config
cat /www/wwwroot/voip/config/database.php

# Verify database exists
mysql -u root -p -e "SHOW DATABASES;"
```

## Running on Windows (Development/Testing)

**Note**: The full system requires Linux. However, you can:

1. **Use WSL2 (Windows Subsystem for Linux)**
   ```bash
   wsl --install
   # Then follow Linux instructions in WSL
   ```

2. **Use VirtualBox/VMware**
   - Install Ubuntu VM
   - Follow Linux deployment instructions

3. **Use Docker** (if Docker setup is created)
   - Run Linux containers on Windows

4. **Deploy to Cloud VPS**
   - Use Contabo VPS (recommended)
   - Or any Linux VPS provider

## System Management

### Start/Stop Services

```bash
# Asterisk
systemctl start asterisk
systemctl stop asterisk
systemctl restart asterisk

# MySQL
systemctl start mysql
systemctl restart mysql

# Web Server (Nginx/Apache)
systemctl start nginx
systemctl restart nginx
```

### View Logs

```bash
# Asterisk logs
tail -f /var/log/asterisk/messages
tail -f /var/log/asterisk/full

# System logs
journalctl -u asterisk -f

# Processing logs
tail -f /var/log/voip-processing.log
```

### Reload Configuration

```bash
# Reload Asterisk
asterisk -rx "core reload"
asterisk -rx "sip reload"

# Reload web server
systemctl reload nginx
```

## Security Checklist

After deployment:

- [ ] Change all default SIP passwords
- [ ] Change database passwords
- [ ] Configure fail2ban for SIP
- [ ] Set up SSL certificate for dashboard
- [ ] Configure firewall rules
- [ ] Set up regular backups
- [ ] Review file permissions

## Next Steps

1. ✅ System is deployed and running
2. 📱 Configure SIP clients
3. 🧪 Test all call flows
4. 🎨 Customize call flows in `extensions.conf`
5. 📊 Monitor via dashboard
6. 🔒 Implement security hardening
7. 📈 Scale as needed

## Support

- **Full Documentation**: `VIRTUAL_PHONE_SYSTEM_DESIGN.md`
- **Installation Guide**: `INSTALLATION.md`
- **Quick Start**: `QUICKSTART.md`
- **Check Logs**: `/var/log/asterisk/messages`

---

**Ready to deploy?** Run `./deploy.sh` on your Linux VPS!

