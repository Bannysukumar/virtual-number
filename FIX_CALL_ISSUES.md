# FIX: Call Hanging Up After 11 Seconds - Root Cause & Solutions

## ROOT CAUSE ANALYSIS

### Problem 1: NAT/External IP Missing
**What's broken:** Asterisk doesn't know its public IP (185.216.203.209), so RTP packets are sent to private IP addresses that Zoiper can't reach.

**Why it causes 11-second hangup:**
- One-way audio (server → client works, client → server fails)
- Asterisk detects no incoming RTP packets
- `WaitExten(10)` times out after 10 seconds
- Call hangs up due to no audio activity

### Problem 2: Dialplan Timeout Logic
**What's broken:** Extension 1002 uses `WaitExten(10)` which times out, then jumps to `1002-options,s,1` which doesn't exist properly.

**Current broken flow:**
```
1002 → Answer() → Wait(1) → Background(main-menu) → WaitExten(10) → [TIMEOUT] → Goto(1002-options,s,1) → [NO VALID EXTENSION] → Hangup
```

### Problem 3: No Call Logging
**What's broken:** Extension 1002 has ZERO database logging. No call record is created at start or end.

**Why:** No `System()` call to log script, no `h` extension handler.

### Problem 4: No Recording Started
**What's broken:** Extension 1002 doesn't start any recording, so even if call completes, there's no file to process.

---

## FIX 1: Add External IP to sip.conf

**File:** `/etc/asterisk/sip.conf`

**Add after line 7 (`bindaddr=0.0.0.0`):**
```
externip=185.216.203.209
localnet=192.168.0.0/255.255.0.0
localnet=10.0.0.0/255.0.0.0
localnet=172.16.0.0/255.240.0.0
```

**Why:** Tells Asterisk to advertise public IP in SDP, so RTP packets go to correct address.

---

## FIX 2: Fix Extension 1002 Dialplan

**File:** `/etc/asterisk/extensions.conf`

**REPLACE the entire 1002 section (lines 30-53) with:**

```
; Extension 1002 - IVR Flow (FIXED)
exten => 1002,1,NoOp(Call to extension 1002 - IVR from ${CALLERID(num)})
exten => 1002,n,Set(CALL_START=${EPOCH})
exten => 1002,n,Set(CALLER_NUM=${CALLERID(num)})
exten => 1002,n,Set(CALLED_NUM=${EXTEN})
exten => 1002,n,Answer()
exten => 1002,n,Set(ANSWER_TIME=${EPOCH})
exten => 1002,n,Wait(1)
exten => 1002,n,Set(RECORDING_DIR=/var/recordings/calls)
exten => 1002,n,System(mkdir -p ${RECORDING_DIR})
exten => 1002,n,Set(RECORDING_FILE=${STRFTIME(${EPOCH},,%Y%m%d_%H%M%S)}_${CALLER_NUM}_${EXTEN})
exten => 1002,n,MixMonitor(${RECORDING_DIR}/${RECORDING_FILE}.wav)
exten => 1002,n,NoOp(Recording started: ${RECORDING_FILE}.wav)
exten => 1002,n,Background(main-menu)
exten => 1002,n,WaitExten(30)
exten => 1002,n,Goto(1002-options,s,1)

exten => 1002-options,1,NoOp(IVR Menu Options)
exten => 1,1,NoOp(Option 1 selected)
exten => 1,n,Playback(sales)
exten => 1,n,Goto(1002-options,s,1)
exten => 2,1,NoOp(Option 2 selected)
exten => 2,n,Playback(support)
exten => 2,n,Goto(1002-options,s,1)
exten => 3,1,NoOp(Option 3 selected)
exten => 3,n,Playback(information)
exten => 3,n,Goto(1002-options,s,1)
exten => t,1,NoOp(Timeout - ending call)
exten => t,n,Playback(vm-goodbye)
exten => t,n,Goto(1002-hangup,1,1)
exten => i,1,NoOp(Invalid option)
exten => i,n,Playback(invalid)
exten => i,n,Goto(1002-options,s,1)
exten => s,1,NoOp(Start of IVR menu)
exten => s,n,Goto(1002-options,1,1)

exten => 1002-hangup,1,NoOp(Call ending - logging to database)
exten => 1002-hangup,n,Set(CALL_END=${EPOCH})
exten => 1002-hangup,n,Set(CALL_DURATION=$[${CALL_END} - ${CALL_START}])
exten => 1002-hangup,n,Set(TALK_TIME=$[${CALL_END} - ${ANSWER_TIME}])
exten => 1002-hangup,n,System(/usr/local/bin/log-call.sh "${CALLER_NUM}" "${CALLED_NUM}" "${CALL_START}" "${ANSWER_TIME}" "${CALL_END}" "${CALL_DURATION}" "${TALK_TIME}" "${RECORDING_DIR}/${RECORDING_FILE}.wav" "ivr")
exten => 1002-hangup,n,Hangup()

exten => h,1,NoOp(Hangup handler for 1002)
exten => h,n,Set(CALL_END=${EPOCH})
exten => h,n,Set(CALL_DURATION=$[${CALL_END} - ${CALL_START}])
exten => h,n,Set(TALK_TIME=$[${CALL_END} - ${ANSWER_TIME}])
exten => h,n,System(/usr/local/bin/log-call.sh "${CALLER_NUM}" "${CALLED_NUM}" "${CALL_START}" "${ANSWER_TIME}" "${CALL_END}" "${CALL_DURATION}" "${TALK_TIME}" "${RECORDING_DIR}/${RECORDING_FILE}.wav" "ivr")
exten => h,n,NoOp(Call logged)
```

**Key changes:**
1. Increased `WaitExten(10)` to `WaitExten(30)` - gives more time for DTMF
2. Added `MixMonitor()` BEFORE menu - starts recording immediately
3. Added `s` extension in `1002-options` - prevents invalid context jump
4. Added `1002-hangup` context - ensures DB logging before hangup
5. Added `h` extension - logs call even if unexpected hangup
6. Set variables at start - captures caller info early

---

## FIX 3: Create Call Logging Script

**File:** `/usr/local/bin/log-call.sh`

**Create with this content:**

```bash
#!/bin/bash

# Log call to database
# Usage: log-call.sh caller_num called_num start_time answer_time end_time duration talk_time recording_path flow_type

CALLER_NUM="${1:-unknown}"
CALLED_NUM="${2:-unknown}"
START_TIME="${3}"
ANSWER_TIME="${4}"
END_TIME="${5}"
DURATION="${6:-0}"
TALK_TIME="${7:-0}"
RECORDING_PATH="${8}"
FLOW_TYPE="${9:-ivr}"

# Database credentials
DB_USER="voip_user"
DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"
DB_NAME="virtual_phone_system"

# Convert epoch to MySQL datetime
START_DT=$(date -d "@${START_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "${START_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$(date '+%Y-%m-%d %H:%M:%S')")
ANSWER_DT=$(date -d "@${ANSWER_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "${ANSWER_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$START_DT")
END_DT=$(date -d "@${END_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "${END_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$(date '+%Y-%m-%d %H:%M:%S')")

# Determine call status
if [ "$TALK_TIME" -gt 0 ]; then
    CALL_STATUS="answered"
else
    CALL_STATUS="no-answer"
fi

# Insert call record
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO calls (
    caller_id_number,
    called_number,
    direction,
    call_status,
    start_time,
    answer_time,
    end_time,
    duration,
    talk_time,
    recording_path,
    flow_type
) VALUES (
    '$CALLER_NUM',
    '$CALLED_NUM',
    'incoming',
    '$CALL_STATUS',
    '$START_DT',
    '$ANSWER_DT',
    '$END_DT',
    $DURATION,
    $TALK_TIME,
    ${RECORDING_PATH:+'$RECORDING_PATH'},
    '$FLOW_TYPE'
);

UPDATE callers 
SET 
    last_call_date = '$END_DT',
    total_calls = total_calls + 1
WHERE phone_number = '$CALLER_NUM';

INSERT INTO callers (phone_number, first_call_date, last_call_date, total_calls)
SELECT '$CALLER_NUM', '$END_DT', '$END_DT', 1
WHERE NOT EXISTS (SELECT 1 FROM callers WHERE phone_number = '$CALLER_NUM');
EOF

exit 0
```

**Make executable:**
```bash
chmod +x /usr/local/bin/log-call.sh
chown asterisk:asterisk /usr/local/bin/log-call.sh
```

**Why:** Centralized logging script that handles all call types, ensures DB insert happens even if recording fails.

---

## FIX 4: Ensure Recording Directory Exists

**Run once:**
```bash
mkdir -p /var/recordings/calls
mkdir -p /var/recordings/questions
chown -R asterisk:asterisk /var/recordings
chmod -R 755 /var/recordings
```

**Why:** MixMonitor fails silently if directory doesn't exist.

---

## FIX 5: Update log-missed-call.sh Password

**File:** `/usr/local/bin/log-missed-call.sh`

**Change line 12:**
```bash
DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"
```

**Why:** Script has placeholder password, won't work otherwise.

---

## IMPLEMENTATION STEPS

### Step 1: Backup Current Configs
```bash
cp /etc/asterisk/sip.conf /etc/asterisk/sip.conf.backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup
```

### Step 2: Apply sip.conf Fix
```bash
# Edit sip.conf
nano /etc/asterisk/sip.conf
# Add externip and localnet lines after bindaddr
```

### Step 3: Apply extensions.conf Fix
```bash
# Edit extensions.conf
nano /etc/asterisk/extensions.conf
# Replace 1002 section with fixed version
```

### Step 4: Create Logging Script
```bash
# Create log-call.sh with content above
nano /usr/local/bin/log-call.sh
chmod +x /usr/local/bin/log-call.sh
chown asterisk:asterisk /usr/local/bin/log-call.sh
```

### Step 5: Create Recording Directories
```bash
mkdir -p /var/recordings/calls /var/recordings/questions
chown -R asterisk:asterisk /var/recordings
chmod -R 755 /var/recordings
```

### Step 6: Update log-missed-call.sh Password
```bash
sed -i 's/DB_PASS="your_password"/DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"/' /usr/local/bin/log-missed-call.sh
```

### Step 7: Reload Asterisk
```bash
asterisk -rx "sip reload"
asterisk -rx "dialplan reload"
asterisk -rx "core reload"
```

### Step 8: Verify Configuration
```bash
# Check externip is set
asterisk -rx "sip show settings" | grep externip

# Check dialplan loaded
asterisk -rx "dialplan show 1002"

# Check recording directory
ls -la /var/recordings/calls/
```

---

## TESTING PROCEDURE

### Test 1: Verify NAT Configuration
```bash
# Check Asterisk sees external IP
asterisk -rx "sip show settings" | grep externip
# Should show: externip: 185.216.203.209
```

### Test 2: Make Test Call
1. Call extension 1002 from Zoiper
2. Wait for menu to play
3. Press a DTMF key (1, 2, or 3)
4. Verify menu loops back
5. Let call timeout or hang up manually

### Test 3: Verify Recording Created
```bash
ls -la /var/recordings/calls/
# Should see .wav file with timestamp
```

### Test 4: Verify Database Entry
```bash
mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system -e "SELECT * FROM calls ORDER BY call_id DESC LIMIT 1;"
# Should show call record with all fields populated
```

### Test 5: Check Dashboard
- Open http://185.216.203.209/
- Verify call appears in dashboard
- Check recording path is populated

---

## EXPECTED BEHAVIOR AFTER FIX

✅ **Call stays active** - No 11-second hangup  
✅ **Two-way audio works** - RTP packets flow correctly  
✅ **Recording starts immediately** - MixMonitor creates .wav file  
✅ **Call logged to DB** - Entry appears in dashboard  
✅ **DTMF input works** - Menu options respond  
✅ **Timeout handled** - Call logs even if no input  

---

## TROUBLESHOOTING

### If call still hangs up:
1. Check RTP ports are open: `netstat -ulnp | grep 10000`
2. Verify externip: `asterisk -rx "sip show settings"`
3. Check Asterisk logs: `tail -f /var/log/asterisk/full`

### If no recording:
1. Check directory permissions: `ls -la /var/recordings/`
2. Check Asterisk can write: `sudo -u asterisk touch /var/recordings/calls/test.wav`
3. Check MixMonitor logs: `grep MixMonitor /var/log/asterisk/full`

### If no DB entry:
1. Test script manually: `/usr/local/bin/log-call.sh "1001" "1002" "$(date +%s)" "$(date +%s)" "$(date +%s)" "10" "8" "/test.wav" "ivr"`
2. Check MySQL connection: `mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system -e "SELECT 1;"`
3. Check script permissions: `ls -la /usr/local/bin/log-call.sh`

---

## SUMMARY

**Root Causes Fixed:**
1. ✅ NAT/external IP configuration
2. ✅ Dialplan timeout and context issues
3. ✅ Missing call logging
4. ✅ Missing recording initialization
5. ✅ Missing hangup handler

**Result:** Calls will stay active, record properly, and log to database.

