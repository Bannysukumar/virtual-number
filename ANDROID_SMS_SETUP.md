# Android SMS Forwarding Setup (No Custom App Required)

## Overview
Forward missed call SMS alerts from your Android phone to the server API endpoint.

## Option 1: Using Tasker (Recommended - Free)

### Prerequisites
- Android phone with physical SIM
- Tasker app (free from Play Store)
- SIM that sends missed call alerts

### Setup Steps

1. **Install Tasker**
   - Download from Google Play Store
   - Grant all required permissions

2. **Create SMS Forwarding Profile**
   - Open Tasker → **Profiles** → **+** (New Profile)
   - Name: "Missed Call SMS Forward"
   - Trigger: **Event** → **Received Text**
   - Sender: Leave blank (any sender)
   - Content: `Missed call from` (or your SIM's exact format)

3. **Create Task**
   - **New Task** → Name: "Forward to Server"
   - Add Action: **Net** → **HTTP Request**
   - Method: `POST`
   - URL: `http://YOUR_SERVER_IP:3001/sms-receiver`
   - Headers:
     ```
     Content-Type: application/json
     ```
   - Body:
     ```json
     {
       "from": "%SMSRF",
       "message": "%SMSRB",
       "timestamp": "%DATE %TIME"
     }
     ```

4. **Test**
   - Give yourself a missed call
   - Check server logs: `journalctl -u missed-call-api -f`

## Option 2: Using IFTTT (Free)

1. **Create IFTTT Account**
   - Sign up at ifttt.com
   - Install IFTTT app on Android

2. **Create Applet**
   - **If This**: Android SMS received containing "Missed call"
   - **Then That**: Webhook
   - URL: `http://YOUR_SERVER_IP:3001/sms-receiver`
   - Method: POST
   - Content Type: application/json
   - Body:
     ```json
     {
       "from": "{{FromNumber}}",
       "message": "{{Text}}",
       "timestamp": "{{OccurredAt}}"
     }
     ```

## Option 3: Using SMS Forwarder App (Free)

1. **Install SMS Forwarder**
   - Search "SMS Forwarder" on Play Store
   - Install any free app (e.g., "SMS Forwarder" by DevApps)

2. **Configure**
   - Add forwarding rule:
     - **Keyword**: "Missed call"
     - **Forward URL**: `http://YOUR_SERVER_IP:3001/sms-receiver`
     - **Method**: POST
     - **Format**: JSON
     - **Body Template**:
       ```json
       {
         "from": "{from}",
         "message": "{body}",
         "timestamp": "{date} {time}"
       }
       ```

## Option 4: Using MacroDroid (Free Alternative)

1. **Install MacroDroid**
   - Download from Play Store

2. **Create Macro**
   - Trigger: SMS Received (contains "Missed call")
   - Action: HTTP Request
   - URL: `http://YOUR_SERVER_IP:3001/sms-receiver`
   - Method: POST
   - Body: JSON with variables

## Testing

### Test SMS Format
Send a test SMS to your phone:
```
Missed call from +919876543210
```

### Verify on Server
```bash
# Check API logs
journalctl -u missed-call-api -f

# Test endpoint directly
curl -X POST http://localhost:3001/sms-receiver \
  -H "Content-Type: application/json" \
  -d '{
    "from": "+919876543210",
    "message": "Missed call from +919876543210",
    "timestamp": "2026-01-02 10:30:00"
  }'
```

## Important Notes

1. **SIM Carrier Format**: Different carriers use different SMS formats:
   - Airtel: "Missed call from +91XXXXXXXXXX"
   - Jio: "Missed call from +91XXXXXXXXXX"
   - BSNL: "Missed call from +91XXXXXXXXXX"
   - Vodafone: "Missed call from +91XXXXXXXXXX"

2. **Update Regex**: If your carrier uses a different format, update the regex in `server.js`:
   ```javascript
   const patterns = [
       /(\+91\d{10})/g,           // +91XXXXXXXXXX
       /(Missed call from\s*\+?91?\d{10})/gi,  // Your carrier format
   ];
   ```

3. **Network Access**: Ensure your Android phone can reach the server IP:
   - Same WiFi network, OR
   - Server has public IP, OR
   - Use port forwarding/ngrok for testing

4. **Battery Optimization**: Disable battery optimization for the SMS forwarding app to ensure it runs in background

## Troubleshooting

### SMS Not Forwarding
- Check app permissions (SMS, Internet)
- Verify server IP is reachable
- Check app logs
- Test with manual HTTP request

### Wrong Number Extracted
- Check SMS format from your carrier
- Update regex patterns in `server.js`
- Test regex online: https://regex101.com

### Callback Not Triggering
- Check SMS API logs: `journalctl -u missed-call-api`
- Verify Asterisk is running: `systemctl status asterisk`
- Check callback script: `/usr/local/bin/trigger-callback.sh`

