# Quick Start Guide - Missed Call Callback System

## 🚀 Fast Setup (5 Minutes)

### Step 1: Install & Configure

```bash
cd /root/virtual-number

# Install Node.js dependencies
cd missed-call-sms-api
npm install

# Setup database
mysql -u root -pf1e23f6271a741c4 virtual_phone_system < ../database/missed-call-schema.sql

# Install scripts
chmod +x ../scripts/*.sh
cp ../scripts/*.sh /usr/local/bin/

# Update Asterisk dialplan
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup
cat ../asterisk/config/extensions-callback.conf >> /etc/asterisk/extensions.conf
asterisk -rx "dialplan reload"
```

### Step 2: Start SMS API

```bash
cd /root/virtual-number/missed-call-sms-api

# Using PM2 (recommended)
pm2 start server.js --name missed-call-api
pm2 save

# Or manually
node server.js
```

### Step 3: Configure Android SMS Forwarding

**Easiest Method - Tasker:**

1. Install Tasker (free)
2. Create Profile: SMS Received (contains "Missed call")
3. Create Task: HTTP Request
   - URL: `http://YOUR_SERVER_IP:3001/sms-receiver`
   - Method: POST
   - Body:
     ```json
     {
       "from": "%SMSRF",
       "message": "%SMSRB",
       "timestamp": "%DATE %TIME"
     }
     ```

### Step 4: Test

```bash
# Test SMS API
curl -X POST http://localhost:3001/sms-receiver \
  -H "Content-Type: application/json" \
  -d '{
    "from": "+919876543210",
    "message": "Missed call from +919812345678",
    "timestamp": "2026-01-02 10:30:00"
  }'

# Check callback status
mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system \
  -e "SELECT * FROM missed_call_callbacks ORDER BY created_at DESC LIMIT 5;"
```

## ✅ Verification Checklist

- [ ] SMS API running: `curl http://localhost:3001/health`
- [ ] Asterisk running: `systemctl status asterisk`
- [ ] Database tables created: Check `missed_call_callbacks` table
- [ ] Android SMS forwarding configured
- [ ] Test missed call → SMS → Callback flow

## 🔧 Configuration Files

- **SMS API**: `missed-call-sms-api/server.js` (port, database, debounce)
- **Asterisk**: `/etc/asterisk/extensions.conf` (dialplan)
- **Scripts**: `/usr/local/bin/*.sh` (logging, callbacks)

## 📱 Android Setup Options

1. **Tasker** (Free) - Most flexible
2. **IFTTT** (Free) - Simple webhook
3. **SMS Forwarder App** (Free) - Dedicated app
4. **MacroDroid** (Free) - Tasker alternative

See [ANDROID_SMS_SETUP.md](ANDROID_SMS_SETUP.md) for detailed instructions.

## 🐛 Troubleshooting

### SMS Not Received
```bash
# Check API logs
journalctl -u missed-call-api -f
# or
pm2 logs missed-call-api
```

### Callback Not Triggering
```bash
# Test callback script
/usr/local/bin/trigger-callback.sh +919876543210

# Check Asterisk logs
tail -f /var/log/asterisk/full
```

### Call Drops Early
- Check `Progress()` command in dialplan
- Verify early media is sent
- Check RTP ports are open (10000-20000)

## 📊 Monitor System

```bash
# Recent callbacks
mysql -u voip_user -p virtual_phone_system \
  -e "SELECT caller_number, callback_status, callback_time FROM missed_call_callbacks ORDER BY created_at DESC LIMIT 10;"

# Recent calls
mysql -u voip_user -p virtual_phone_system \
  -e "SELECT caller_id_number, call_status, duration, ivr_option_selected FROM calls WHERE callback_type='missed_call' ORDER BY start_time DESC LIMIT 10;"
```

## 🎯 Next Steps

1. Configure your SIP trunk for outbound calls
2. Test with real missed call
3. Monitor logs for any issues
4. Adjust IVR menu as needed
5. Set up dashboard to view callbacks

For detailed documentation, see [MISSED_CALL_SYSTEM_README.md](MISSED_CALL_SYSTEM_README.md)

