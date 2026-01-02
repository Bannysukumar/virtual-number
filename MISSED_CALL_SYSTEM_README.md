# Missed Call → SMS → SIP Callback System

Complete system for receiving missed calls via SMS and automatically triggering SIP callbacks with IVR.

## System Architecture

```
User Missed Call
   ↓
SIM Generates SMS Alert
   ↓
Android/GSM Modem Forwards SMS
   ↓
Server API Receives SMS (POST /sms-receiver)
   ↓
Extract Phone Number (Regex)
   ↓
Debounce Check (60 seconds)
   ↓
Log to Database
   ↓
Trigger Asterisk Callback
   ↓
Call Connects to IVR (Extension 1002)
   ↓
Human Voice Greeting & Menu
   ↓
DTMF Input Handling
   ↓
Call Logged & Recorded
```

## Features

✅ **No Paid APIs** - Uses only open-source tools  
✅ **No App Required** - Works with any phone  
✅ **Indian SIM Compatible** - Works with all major carriers  
✅ **Debouncing** - Prevents duplicate callbacks (60s)  
✅ **Retry Logic** - Automatic retry on failure  
✅ **Early Media** - Prevents 11-second timeout  
✅ **Call Logging** - Logs on ANSWER, not HANGUP  
✅ **IVR Tracking** - Tracks menu selections  
✅ **Human Voice** - Natural female voice IVR  

## Installation

### 1. Install Dependencies

```bash
cd missed-call-sms-api
npm install
```

### 2. Setup Database

```bash
mysql -u root -p virtual_phone_system < database/missed-call-schema.sql
```

### 3. Install Scripts

```bash
chmod +x scripts/*.sh
cp scripts/*.sh /usr/local/bin/
```

### 4. Configure Asterisk

```bash
# Backup existing dialplan
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup

# Append callback dialplan
cat asterisk/config/extensions-callback.conf >> /etc/asterisk/extensions.conf

# Reload Asterisk
asterisk -rx "dialplan reload"
```

### 5. Start SMS API

```bash
# Using PM2 (recommended)
pm2 start missed-call-sms-api/server.js --name missed-call-api
pm2 save

# Or using systemd
systemctl start missed-call-api
systemctl enable missed-call-api
```

### 6. Configure Android SMS Forwarding

See [ANDROID_SMS_SETUP.md](ANDROID_SMS_SETUP.md) for detailed instructions.

## Configuration

### SMS API Configuration

Edit `missed-call-sms-api/server.js`:

```javascript
const CONFIG = {
    port: 3001,
    db: {
        host: 'localhost',
        user: 'voip_user',
        password: 'YOUR_PASSWORD',
        database: 'virtual_phone_system'
    },
    debounceSeconds: 60,
    retryAttempts: 1,
    retryDelay: 5000
};
```

### Asterisk Configuration

The callback system uses:
- **Extension 1002**: Main IVR with human voice
- **Context**: `outbound-callback` for callbacks
- **Early Media**: `Progress()` command to prevent timeout

## API Endpoints

### POST /sms-receiver

Receive SMS from Android/GSM modem.

**Request:**
```json
{
  "from": "+919876543210",
  "message": "Missed call from +919812345678",
  "timestamp": "2026-01-02 10:30:00"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Callback initiated",
  "phoneNumber": "+919812345678"
}
```

### GET /health

Health check endpoint.

### GET /callback-status/:phoneNumber

Get callback status for a phone number.

## Database Schema

### missed_call_callbacks

Stores missed call and callback information:

- `caller_number`: Phone number that gave missed call
- `sms_message`: Original SMS text
- `callback_status`: pending, initiated, answered, failed
- `call_id`: Reference to calls table
- `retry_count`: Number of retry attempts

### calls (updated)

Added columns:
- `callback_type`: manual, missed_call, scheduled
- `ivr_option_selected`: Menu option selected
- `early_media_sent`: Whether early media was sent

## Call Flow

### 1. SMS Received
- Android forwards SMS to API
- API extracts phone number using regex
- Checks debounce (60 seconds)

### 2. Callback Triggered
- Logs to `missed_call_callbacks` table
- Calls `/usr/local/bin/trigger-callback.sh`
- Script originates call via Asterisk

### 3. Call Connects
- Asterisk dials caller number
- On answer, routes to extension 1002
- Sends `Progress()` immediately (early media)

### 4. IVR Plays
- Human voice greeting
- Menu options (1-4)
- Waits for DTMF input
- Logs option selection

### 5. Call Ends
- Logs completion to database
- Updates `missed_call_callbacks` status
- Saves recording path

## Troubleshooting

### SMS Not Received

```bash
# Check API logs
journalctl -u missed-call-api -f

# Test endpoint manually
curl -X POST http://localhost:3001/sms-receiver \
  -H "Content-Type: application/json" \
  -d '{"message":"Missed call from +919876543210"}'
```

### Callback Not Triggering

```bash
# Check Asterisk logs
tail -f /var/log/asterisk/full

# Test callback script
/usr/local/bin/trigger-callback.sh +919876543210

# Check PM2/Asterisk status
pm2 list
systemctl status asterisk
```

### Call Drops at 11 Seconds

This is fixed by:
1. `Progress()` command in dialplan
2. Early media sent immediately
3. Recording starts before playback

### Wrong Phone Number Extracted

Update regex in `server.js`:
```javascript
const patterns = [
    /(\+91\d{10})/g,           // +91XXXXXXXXXX
    /(91\d{10})/g,             // 91XXXXXXXXXX
    // Add your carrier's format
];
```

## Monitoring

### Check Recent Callbacks

```bash
mysql -u voip_user -p virtual_phone_system -e "
SELECT caller_number, callback_status, callback_time, duration 
FROM missed_call_callbacks 
ORDER BY created_at DESC 
LIMIT 10;
"
```

### Check Call Logs

```bash
mysql -u voip_user -p virtual_phone_system -e "
SELECT caller_id_number, called_number, call_status, duration, ivr_option_selected 
FROM calls 
WHERE callback_type = 'missed_call'
ORDER BY start_time DESC 
LIMIT 10;
"
```

### Monitor API

```bash
# Real-time logs
journalctl -u missed-call-api -f

# PM2 logs
pm2 logs missed-call-api
```

## Security

1. **API Authentication**: Add API key authentication
2. **IP Whitelist**: Restrict SMS endpoint to known IPs
3. **Rate Limiting**: Implement rate limiting per phone number
4. **HTTPS**: Use HTTPS for production (Let's Encrypt)

## License

Open-source, free to use and modify.

## Support

For issues or questions:
1. Check logs: `journalctl -u missed-call-api`
2. Test components individually
3. Verify database connectivity
4. Check Asterisk dialplan syntax

