# Deploying from Windows
## How to Upload and Run on Your Contabo VPS

Since you're on Windows, you need to deploy this to your Linux VPS server. Here's how:

## Option 1: Upload via SCP (Recommended)

### Step 1: Install WinSCP (Free SFTP Client)

1. Download WinSCP: https://winscp.net/eng/download.php
2. Install and open WinSCP

### Step 2: Connect to Your Server

1. **Host name**: `your-server-ip`
2. **Username**: `root`
3. **Password**: (your server password)
4. **Protocol**: SFTP
5. Click **Login**

### Step 3: Upload Project Files

1. In WinSCP, navigate to `/root/` on the server (right panel)
2. Navigate to your project folder on Windows (left panel)
3. Select all files and folders
4. Drag and drop to `/root/virtual-phone-system/` on server
5. Wait for upload to complete

### Step 4: Connect via SSH and Deploy

1. In WinSCP, click **Session** → **New Session** → **SSH**
2. Or use PuTTY (included with WinSCP)
3. Connect to your server
4. Run:

```bash
cd /root/virtual-phone-system
chmod +x deploy.sh
./deploy.sh
```

## Option 2: Upload via PowerShell (Windows 10/11)

### Step 1: Use SCP Command

```powershell
# Navigate to project folder
cd "C:\Users\munna\Downloads\New folder (12)"

# Upload entire folder to server
scp -r * root@your-server-ip:/root/virtual-phone-system/
```

### Step 2: Connect via SSH

```powershell
# Connect to server
ssh root@your-server-ip

# Once connected, run:
cd /root/virtual-phone-system
chmod +x deploy.sh
./deploy.sh
```

## Option 3: Use Git (If You Have Repository)

### On Windows:

```powershell
# If you have Git installed
cd C:\Users\munna\Downloads
git clone your-repository-url virtual-phone-system
cd virtual-phone-system
```

### On Server (via SSH):

```bash
ssh root@your-server-ip
cd /root
git clone your-repository-url virtual-phone-system
cd virtual-phone-system
chmod +x deploy.sh
./deploy.sh
```

## Option 4: Manual File-by-File Upload

If you prefer manual control:

1. **Create directory on server:**
   ```bash
   ssh root@your-server-ip
   mkdir -p /root/virtual-phone-system
   ```

2. **Upload files via WinSCP** (drag and drop each folder)

3. **Run deployment:**
   ```bash
   cd /root/virtual-phone-system
   chmod +x deploy.sh
   ./deploy.sh
   ```

## Quick Test After Deployment

Once deployed, test from Windows:

### 1. Install SIP Client on Windows

Download **Zoiper** (free SIP client):
- Website: https://www.zoiper.com/
- Install and open Zoiper

### 2. Configure SIP Account

1. Open Zoiper
2. Click **Add Account**
3. Enter:
   - **Account Name**: My Virtual Phone
   - **Username**: `1001`
   - **Password**: (check on server: `grep "secret=" /etc/asterisk/sip.conf | head -1`)
   - **Domain**: `your-server-ip` (or `sip.yourdomain.com` if configured)
   - **Register**: Yes

4. Click **OK**

### 3. Make Test Call

1. In Zoiper, dial: `1001`
2. You should hear the greeting
3. Check dashboard: `http://your-server-ip/voip/`

## What Happens During Deployment

The `deploy.sh` script will:

1. ✅ **Server Setup** (5 minutes)
   - Configure firewall
   - Create directories
   - Install dependencies

2. ✅ **Install Asterisk** (10-20 minutes)
   - Download and compile Asterisk PBX
   - Set up service

3. ✅ **Database Setup** (2 minutes)
   - Create database
   - Import schema
   - Create user

4. ✅ **Configure Asterisk** (1 minute)
   - Copy configuration files
   - Generate secure passwords
   - Reload service

5. ✅ **Install Whisper** (5-10 minutes, optional)
   - Install speech-to-text engine

6. ✅ **Setup Scripts** (1 minute)
   - Copy helper scripts
   - Configure cron jobs

7. ✅ **Deploy Dashboard** (1 minute)
   - Copy web files
   - Set permissions

**Total Time**: ~25-40 minutes

## Troubleshooting Upload Issues

### "Permission Denied" Error

```bash
# On server, fix permissions
chmod 755 /root
chmod 755 /root/virtual-phone-system
```

### Files Not Uploading

- Check disk space: `df -h`
- Check file permissions on Windows
- Try uploading in smaller batches

### Connection Timeout

- Check firewall on server
- Verify SSH is enabled: `systemctl status ssh`
- Check Contabo firewall rules

## Next Steps After Deployment

1. **Get SIP Passwords:**
   ```bash
   ssh root@your-server-ip
   grep "secret=" /etc/asterisk/sip.conf
   ```

2. **Configure SIP Client** (see above)

3. **Test System:**
   - Make test call
   - Check dashboard
   - Review logs

4. **Customize:**
   - Edit `/etc/asterisk/extensions.conf`
   - Add more SIP users
   - Configure domain

## Need Help?

- **Deployment Guide**: See `DEPLOY.md`
- **Installation Guide**: See `INSTALLATION.md`
- **System Design**: See `VIRTUAL_PHONE_SYSTEM_DESIGN.md`

---

**Ready?** Upload files to your server and run `./deploy.sh`!

