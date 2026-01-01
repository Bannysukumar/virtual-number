# Complete Virtual Phone Number System Design
## Self-Hosted VoIP/SIP System for Contabo VPS with aaPanel

---

## TABLE OF CONTENTS

1. [Server & Network Preparation](#step-1-server--network-preparation)
2. [Telephony Core (Virtual Number Engine)](#step-2-telephony-core-virtual-number-engine)
3. [SIP ID / Virtual Number Creation](#step-3-sip-id--virtual-number-creation)
4. [Call Flow Design](#step-4-call-flow-design)
5. [Voice Handling](#step-5-voice-handling)
6. [Speech to Text (Free & Self-Hosted)](#step-6-speech-to-text-free--self-hosted)
7. [Database & Data Storage](#step-7-database--data-storage)
8. [AI Voice Agent (Optional – Future Ready)](#step-8-ai-voice-agent-optional--future-ready)
9. [Admin Dashboard (Concept)](#step-9-admin-dashboard-concept)
10. [Legal & Reality Check (India)](#step-10-legal--reality-check-india)
11. [Scalability & Security](#step-11-scalability--security)

---

## STEP 1: SERVER & NETWORK PREPARATION

### Minimum Server Specifications

**Recommended Contabo VPS Configuration:**
- **CPU**: 4 cores (minimum 2 cores)
- **RAM**: 8 GB (minimum 4 GB)
- **Storage**: 100 GB SSD (minimum 50 GB)
- **Bandwidth**: 1 TB/month (minimum 500 GB)
- **OS**: Ubuntu 22.04 LTS (recommended) or Ubuntu 20.04 LTS

**Why These Specs:**
- Asterisk PBX requires moderate CPU for call processing
- RAM needed for concurrent calls (each call ~1-2 MB)
- Storage for call recordings and transcriptions
- Bandwidth for RTP audio streams (each call ~64-128 kbps)

### Required Ports to Open

**SIP Protocol Ports:**
- **Port 5060 (UDP/TCP)**: Primary SIP signaling port
- **Port 5061 (TCP)**: SIP over TLS (encrypted SIP)
- **Ports 10000-20000 (UDP)**: RTP (Real-time Transport Protocol) for voice data

**Web & Management Ports:**
- **Port 80 (TCP)**: HTTP for web interface
- **Port 443 (TCP)**: HTTPS for secure web interface
- **Port 8088 (TCP)**: Asterisk HTTP/AMI (optional, for management)

**Database Ports:**
- **Port 3306 (TCP)**: MySQL/MariaDB (if external access needed, otherwise localhost only)
- **Port 5432 (TCP)**: PostgreSQL (if using PostgreSQL)

**Firewall Rules (UFW - Ubuntu Firewall)**

```bash
# Basic firewall setup commands (conceptual)
ufw allow 22/tcp      # SSH (always keep open)
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw allow 5060/udp    # SIP signaling
ufw allow 5060/tcp    # SIP signaling (TCP)
ufw allow 5061/tcp    # SIP over TLS
ufw allow 10000:20000/udp  # RTP media range
ufw enable
```

**Alternative: iptables Rules**
- Same port ranges, but using iptables syntax
- More granular control but more complex

### DNS Requirements

**Option 1: Domain-Based Setup (Recommended)**
- Register a domain (e.g., `yourdomain.com`)
- Create A record: `sip.yourdomain.com` → Your Contabo VPS IP
- Create SRV record: `_sip._udp.yourdomain.com` → Points to SIP server
- Create SRV record: `_sips._tcp.yourdomain.com` → Points to secure SIP

**Option 2: IP-Based Setup (Simpler, Less Professional)**
- Use direct IP address: `sip:user@YOUR_IP_ADDRESS`
- No DNS needed
- Works for testing but not production-ready

**Why Domain-Based is Better:**
- Professional SIP addresses: `sip:1001@sip.yourdomain.com`
- Easier to remember
- Required for some SIP providers
- Better for security (certificates)

### Static IP Handling on Contabo

**Contabo VPS Details:**
- Contabo provides static IP addresses by default
- No dynamic IP changes (unlike home internet)
- Your IP remains constant: `YOUR_STATIC_IP`

**Configuration:**
- Use Contabo's provided static IP
- No special configuration needed
- Ensure IP is properly configured in Contabo panel
- Verify with: `curl ifconfig.me` or `hostname -I`

**Reverse DNS (PTR Record):**
- Request reverse DNS from Contabo support
- Helps with SIP reputation
- Format: `sip.yourdomain.com` → `YOUR_IP`

---

## STEP 2: TELEPHONY CORE (VIRTUAL NUMBER ENGINE)

### Why Asterisk is Used

**Asterisk Overview:**
- **What it is**: Open-source PBX (Private Branch Exchange) software
- **Role**: Acts as your virtual telephone exchange
- **Function**: Routes calls, handles SIP signaling, manages voice channels

**Key Capabilities:**
- SIP server (receives and sends SIP calls)
- IVR (Interactive Voice Response) system
- Call recording
- Voice prompts and announcements
- Call routing and forwarding
- Conference calling
- Voicemail system

**Why Asterisk Over Alternatives:**
- Most mature open-source PBX
- Extensive documentation
- Large community
- Highly customizable
- Free and open-source
- Runs on Linux

### How Asterisk Acts Like a Mini Telecom Exchange

**Traditional Telecom Exchange:**
```
Caller → Local Exchange → Long Distance → Destination Exchange → Receiver
```

**Your Asterisk System:**
```
Internet Caller → SIP Protocol → Asterisk PBX → SIP Protocol → Destination
```

**Internal Components:**
1. **SIP Channel Driver**: Handles SIP signaling (call setup, teardown)
2. **RTP Engine**: Handles voice data streaming
3. **Dialplan**: Call routing logic (like a switchboard operator)
4. **Applications**: IVR, recording, playback, etc.

**Call Processing Flow:**
- Asterisk receives SIP INVITE (call request)
- Checks dialplan for routing rules
- Establishes RTP media path
- Executes call logic (answer, play prompt, record, etc.)
- Manages call state (ringing, answered, busy, etc.)

### How Virtual Numbers Work Internally

**Concept:**
- Virtual number = SIP address (not a physical phone line)
- Format: `sip:username@domain` or `sip:1001@sip.yourdomain.com`
- Each SIP user = one virtual number/extension

**Internal Mapping:**
```
SIP User: 1001
  ↓
Asterisk User Account (sip.conf)
  ↓
Dialplan Entry (extensions.conf)
  ↓
Call Handling Logic (IVR, recording, etc.)
```

**Number Assignment:**
- You create SIP users manually (e.g., 1001, 1002, 1003)
- Each user has a password/secret
- Each user can receive calls
- No need for telecom provider initially (SIP-to-SIP only)

### Difference Between SIP Address vs PSTN Number

**SIP Address (Virtual Number):**
- Format: `sip:1001@sip.yourdomain.com`
- Works over internet only
- Free to create (unlimited)
- Requires SIP client or gateway
- Cannot directly call mobile/landline phones

**PSTN Number (Real Phone Number):**
- Format: `+91-9876543210` (India mobile/landline)
- Works on traditional phone network
- Requires telecom license/approval
- Can call any phone worldwide
- Requires SIP-to-PSTN gateway (paid service)

**Bridging the Gap:**
- To receive calls from mobile phones → Need SIP-to-PSTN gateway
- To call mobile phones → Need PSTN-to-SIP gateway
- Gateways cost money (e.g., Twilio, Plivo, local Indian providers)
- For testing: Use SIP-to-SIP only (free, but requires SIP app)

### How Calls Flow Inside the System

**Incoming Call Flow:**
```
1. External SIP Client sends INVITE
   ↓
2. Asterisk receives INVITE on port 5060
   ↓
3. Asterisk authenticates caller (if required)
   ↓
4. Asterisk checks dialplan (extensions.conf)
   ↓
5. Dialplan matches destination (e.g., extension 1001)
   ↓
6. Asterisk executes call logic:
   - Answer call
   - Play greeting
   - Start IVR
   - Record response
   ↓
7. RTP media stream established (ports 10000-20000)
   ↓
8. Call continues until hangup
   ↓
9. Asterisk logs call details (CDR - Call Detail Record)
```

**Outbound Call Flow:**
```
1. SIP client dials number
   ↓
2. Asterisk receives dial request
   ↓
3. Dialplan processes number
   ↓
4. Asterisk sends INVITE to destination
   ↓
5. Destination answers
   ↓
6. RTP stream established
   ↓
7. Call active
```

---

## STEP 3: SIP ID / VIRTUAL NUMBER CREATION

### How to Create SIP Users (Virtual Numbers)

**Process Overview:**
1. Edit Asterisk configuration file (`sip.conf` or `pjsip.conf`)
2. Define SIP user account
3. Set password/secret
4. Configure permissions
5. Reload Asterisk configuration

**SIP User Structure:**
```
[1001]                    # SIP username/extension
type=friend               # User type (friend, peer, user)
host=dynamic              # Allow dynamic IP (for mobile clients)
secret=password123        # Password for authentication
context=internal          # Dialplan context
allow=ulaw,alaw           # Audio codecs allowed
```

**Multiple Users:**
- Create as many SIP users as needed
- Each user = one virtual number
- No limit (only server resources)

### Example SIP Formats

**Format 1: Username@Domain**
- `sip:1001@sip.yourdomain.com`
- Professional, domain-based

**Format 2: Username@IP**
- `sip:1001@YOUR_IP_ADDRESS`
- Simple, IP-based

**Format 3: Numeric Extension**
- `1001` (when calling from within system)
- Short format for internal calls

### How External Callers Can Reach It

**Scenario 1: SIP-to-SIP (Free, Internet Only)**
- Caller uses SIP client app (e.g., Zoiper, Linphone)
- Enters SIP address: `sip:1001@sip.yourdomain.com`
- Enters password
- Makes call over internet
- **Limitation**: Both parties need SIP client

**Scenario 2: PSTN-to-SIP (Requires Gateway, Paid)**
- Caller uses regular phone (mobile/landline)
- Dials gateway number (e.g., +91-XXXXX)
- Gateway converts PSTN → SIP
- Forwards to your Asterisk server
- **Cost**: Per-minute charges

**Scenario 3: WebRTC (Browser-Based)**
- Caller uses web browser
- Visits your website
- Clicks "Call" button
- Browser connects via WebRTC
- No app installation needed
- **Advantage**: No mobile app required

### Difference Between SIP-to-SIP vs PSTN-to-SIP Calls

**SIP-to-SIP Calls:**
- Both parties use SIP protocol
- Works over internet
- Free (no per-minute charges)
- Requires SIP client/app
- Good for testing and internal use
- Quality depends on internet

**PSTN-to-SIP Calls:**
- One party uses regular phone (PSTN)
- Other party uses SIP
- Requires gateway service (paid)
- Per-minute charges apply
- Works with any phone
- Quality depends on gateway

**Hybrid Approach:**
- Use SIP-to-SIP for testing/development
- Add PSTN gateway later for production
- Gateway providers: Twilio, Plivo, local Indian providers

### Realistic Limitations of Free SIP Numbers

**What You Get (Free SIP):**
- Unlimited SIP users/extensions
- SIP-to-SIP calling (free)
- Full control over system
- No per-minute charges
- Works 24/7

**What You Don't Get (Without Gateway):**
- Cannot receive calls from mobile/landline directly
- Cannot call mobile/landline directly
- Requires SIP client/app
- Limited to internet users

**To Overcome Limitations:**
- Integrate SIP-to-PSTN gateway (paid)
- Use WebRTC for browser-based calling
- Use mobile SIP apps for testing

### How This Replaces a "SIM-Based Number"

**Traditional SIM Number:**
- Physical SIM card
- Assigned by telecom operator
- Works on cellular network
- Can call/receive from any phone
- Monthly charges + per-minute

**Virtual SIP Number:**
- Software-based
- Assigned by you
- Works on internet
- Can call/receive from SIP clients
- No monthly charges (SIP-to-SIP)

**Replacement Strategy:**
- Use SIP number for automated systems (IVR, AI agent)
- Use SIP gateway to bridge to PSTN when needed
- Cost-effective for high-volume automated calls
- More flexible than SIM-based

---

## STEP 4: CALL FLOW DESIGN

### Flow 1: Basic Auto Answer

**Call Flow Diagram:**
```
[Caller] → [SIP INVITE] → [Asterisk]
                                    ↓
                            [Authenticate Caller]
                                    ↓
                            [Check Dialplan]
                                    ↓
                            [Answer Call Automatically]
                                    ↓
                            [Play Greeting Audio]
                                    ↓
                            [Wait 5 seconds]
                                    ↓
                            [Hangup Call]
                                    ↓
                            [Log Call Details]
```

**Steps:**
1. Call arrives at Asterisk
2. System answers immediately (no ringing)
3. Plays pre-recorded greeting: "Thank you for calling..."
4. Waits for specified duration
5. Hangs up automatically
6. Saves call log to database

**Use Cases:**
- Missed call service
- Call verification
- Simple announcement system

### Flow 2: IVR Flow

**Call Flow Diagram:**
```
[Caller] → [Answer Call] → [Play Main Menu]
                                    ↓
                            "Press 1 for Sales"
                            "Press 2 for Support"
                            "Press 3 for Information"
                                    ↓
                            [Wait for DTMF Input]
                                    ↓
                    ┌───────────────┴───────────────┐
                    ↓                               ↓
            [Press 1]                         [Press 2]
                    ↓                               ↓
        [Route to Sales IVR]              [Route to Support IVR]
                    ↓                               ↓
        [Play Sales Message]              [Play Support Message]
                    ↓                               ↓
            [Record Option]                  [Record Option]
                    ↓                               ↓
            [Save to Database]              [Save to Database]
                    ↓                               ↓
                    └───────────────┬───────────────┘
                                    ↓
                            [Hangup or Return to Menu]
```

**Steps:**
1. Answer call
2. Play main menu with options
3. Wait for caller to press key (DTMF)
4. Route based on key pressed
5. Play sub-menu or information
6. Optionally record response
7. Save selection to database
8. Return to menu or hangup

**DTMF (Dual-Tone Multi-Frequency):**
- Touch-tone signals (0-9, *, #)
- Asterisk detects key presses
- Used for menu navigation

### Flow 3: Voice Question Flow

**Call Flow Diagram:**
```
[Caller] → [Answer Call] → [Play Welcome]
                                    ↓
                            [Ask Question 1]
                            "What is your name?"
                                    ↓
                            [Start Recording]
                                    ↓
                            [Wait for Silence]
                                    ↓
                            [Stop Recording]
                                    ↓
                            [Save Audio File]
                                    ↓
                            [Ask Question 2]
                            "What is your phone number?"
                                    ↓
                            [Start Recording]
                                    ↓
                            [Wait for Silence]
                                    ↓
                            [Stop Recording]
                                    ↓
                            [Save Audio File]
                                    ↓
                            [Ask Question 3]
                            "Any additional comments?"
                                    ↓
                            [Start Recording]
                                    ↓
                            [Wait for Silence]
                                    ↓
                            [Stop Recording]
                                    ↓
                            [Save Audio File]
                                    ↓
                            [Play Thank You Message]
                                    ↓
                            [Hangup]
                                    ↓
                            [Queue Audio for Transcription]
```

**Steps:**
1. Answer call
2. Play welcome message
3. Ask first question
4. Start recording (beep tone)
5. Wait for caller to speak
6. Detect silence (end of response)
7. Stop recording
8. Save audio file with unique name
9. Repeat for next questions
10. Play thank you message
11. Hangup
12. Process recordings in background (transcription)

**Recording Parameters:**
- Format: WAV or MP3
- Naming: `call_YYYYMMDD_HHMMSS_question1.wav`
- Storage: `/var/spool/asterisk/monitor/`
- Duration limit: 60 seconds per question

### Flow 4: Missed Call + Callback Flow

**Call Flow Diagram:**
```
[Caller] → [Makes Call] → [Asterisk Receives]
                                    ↓
                            [Answer Immediately]
                                    ↓
                            [Play: "Thank you for calling"]
                                    ↓
                            [Hangup After 2 seconds]
                                    ↓
                            [Log as "Missed Call"]
                                    ↓
                            [Extract Caller ID]
                                    ↓
                            [Save to Database]
                                    ↓
                            [Trigger Callback Process]
                                    ↓
                    ┌───────────────┴───────────────┐
                    ↓                               ↓
        [Wait 30 seconds]                  [Check Callback Rules]
                    ↓                               ↓
        [Initiate Outbound Call]           [AI Agent or IVR]
                    ↓                               ↓
        [Call Original Caller]             [Ask Questions]
                    ↓                               ↓
        [Answer by Caller]                 [Record Responses]
                    ↓                               ↓
        [Play: "This is a callback"]       [Save to Database]
                    ↓                               ↓
        [Connect to AI Agent or IVR]       [Hangup]
                    ↓
        [Conversation]
                    ↓
        [Hangup]
```

**Steps:**
1. Caller makes call
2. System answers immediately
3. Plays brief message
4. Hangs up quickly (missed call)
5. System logs caller ID
6. Waits specified time (e.g., 30 seconds)
7. System calls back automatically
8. When caller answers, plays message
9. Connects to AI agent or IVR
10. Processes conversation
11. Saves data

**Use Cases:**
- Lead generation
- Customer callback service
- Verification system

---

## STEP 5: VOICE HANDLING

### Audio Formats Used

**Primary Formats:**
- **WAV (PCM)**: Uncompressed, high quality, large file size
- **MP3**: Compressed, good quality, smaller file size
- **OGG**: Open-source compressed format
- **GSM**: Low bandwidth, acceptable quality

**Codec Selection:**
- **G.711 (ulaw/alaw)**: Standard, good quality, 64 kbps
- **G.729**: Compressed, good quality, 8 kbps (license required)
- **Opus**: Modern, excellent quality, variable bitrate
- **GSM**: Free, acceptable quality, 13 kbps

**Recommendation:**
- Use G.711 (ulaw) for recordings (best quality)
- Convert to MP3 for storage (smaller files)
- Use Opus for WebRTC calls

### Recording Storage Structure

**Directory Structure:**
```
/var/spool/asterisk/monitor/
├── YYYY/
│   ├── MM/
│   │   ├── DD/
│   │   │   ├── call_20240115_143022_question1.wav
│   │   │   ├── call_20240115_143022_question2.wav
│   │   │   └── call_20240115_143045_full.wav
```

**Alternative Structure:**
```
/var/recordings/
├── calls/
│   ├── 2024-01-15/
│   │   ├── 1001_incoming_143022.wav
│   │   └── 1001_outgoing_150530.wav
├── questions/
│   ├── 2024-01-15/
│   │   ├── call_143022_q1.wav
│   │   └── call_143022_q2.wav
└── transcriptions/
    ├── 2024-01-15/
    │   └── call_143022_q1.txt
```

### Naming Conventions for Call Recordings

**Format 1: Timestamp-Based**
- `call_YYYYMMDD_HHMMSS.wav`
- Example: `call_20240115_143022.wav`
- Easy to sort chronologically

**Format 2: Caller ID + Timestamp**
- `CALLERID_YYYYMMDD_HHMMSS.wav`
- Example: `919876543210_20240115_143022.wav`
- Easy to find calls from specific number

**Format 3: Extension + Direction + Timestamp**
- `EXT_DIRECTION_YYYYMMDD_HHMMSS.wav`
- Example: `1001_incoming_20240115_143022.wav`
- Shows which extension received call

**Format 4: Question-Based**
- `call_TIMESTAMP_questionN.wav`
- Example: `call_20240115_143022_question1.wav`
- For multi-question flows

**Recommendation:**
- Use Format 2 or 3 for full calls
- Use Format 4 for question recordings
- Include metadata in filename

### Call Duration Tracking

**What is Tracked:**
- **Call Start Time**: When call was answered
- **Call End Time**: When call was hung up
- **Call Duration**: End time - Start time
- **Talk Time**: Actual conversation time (excluding silence)
- **Ring Time**: Time before answer (if applicable)

**Storage:**
- Stored in CDR (Call Detail Record) database
- Fields: start_time, answer_time, end_time, duration, billsec

**Use Cases:**
- Billing (if charging per minute)
- Analytics (average call length)
- Quality monitoring

### Caller ID Handling

**Incoming Caller ID:**
- Extracted from SIP INVITE header
- Format: `From: "Name" <sip:number@domain>`
- Stored as: Name and Number

**Outgoing Caller ID:**
- Set by Asterisk when making outbound calls
- Can be customized per extension
- Format: `CallerID(num)=1001` or `CallerID(name)=Your Company`

**Privacy Considerations:**
- Some callers may hide caller ID
- Handle "Anonymous" or "Private" calls
- Store as "Unknown" if not available

**Storage:**
- Store in database: caller_id_number, caller_id_name
- Use for callback functionality
- Use for call history

### Timestamp Logging

**Timestamps Tracked:**
- **Call Initiated**: When INVITE received
- **Call Answered**: When call connected
- **Recording Started**: When recording begins
- **Recording Stopped**: When recording ends
- **Call Ended**: When call disconnected
- **Transcription Started**: When STT processing begins
- **Transcription Completed**: When STT finishes

**Timezone Handling:**
- Store all timestamps in UTC
- Convert to local time in dashboard
- Handle daylight saving time changes

**Database Fields:**
- `created_at`: Call start time
- `answered_at`: Answer time
- `ended_at`: End time
- `recording_started_at`: Recording start
- `recording_ended_at`: Recording end
- `transcribed_at`: Transcription completion

---

## STEP 6: SPEECH TO TEXT (FREE & SELF-HOSTED)

### How to Integrate Open-Source Speech-to-Text

**Option 1: Whisper.cpp (Recommended)**
- **What it is**: C++ implementation of OpenAI Whisper
- **Advantages**: Fast, accurate, runs locally, no API costs
- **Languages**: Supports 100+ languages including Hindi and English
- **Models**: tiny, base, small, medium, large (larger = more accurate)

**Option 2: Vosk**
- **What it is**: Offline speech recognition toolkit
- **Advantages**: Lightweight, fast, good for real-time
- **Languages**: Multiple language models available
- **Models**: Small (~50 MB) to Large (~2 GB)

**Option 3: DeepSpeech (Mozilla)**
- **What it is**: Open-source STT engine
- **Advantages**: Good accuracy, free
- **Languages**: Primarily English, some other languages

**Recommendation: Whisper.cpp**
- Best accuracy
- Good Hindi support
- Active development
- Can run on CPU (slower) or GPU (faster)

### How Recorded Audio is Converted to Text

**Processing Flow:**
```
[Audio Recording] → [File Detection] → [Queue System]
                                                    ↓
                                            [Audio Preprocessing]
                                                    ↓
                                            [Convert Format if Needed]
                                                    ↓
                                            [Whisper.cpp Processing]
                                                    ↓
                                            [Text Output]
                                                    ↓
                                            [Save to Database]
                                                    ↓
                                            [Link to Recording]
```

**Step-by-Step:**
1. **File Detection**: Monitor recording directory for new files
2. **Queue System**: Add file to processing queue
3. **Audio Preprocessing**: 
   - Convert to required format (WAV, 16kHz, mono)
   - Normalize audio levels
   - Remove noise (optional)
4. **Whisper Processing**:
   - Load Whisper model
   - Process audio file
   - Generate transcription
5. **Post-Processing**:
   - Clean up text (remove filler words, optional)
   - Add punctuation
   - Detect language
6. **Storage**:
   - Save transcription to database
   - Link to original recording
   - Store confidence scores (if available)

**Background Processing:**
- Use cron job or daemon process
- Process files asynchronously (not during call)
- Handle multiple files in queue
- Retry failed transcriptions

### Accuracy Expectations

**Whisper.cpp Accuracy:**
- **English**: 95-98% accuracy (depending on model size)
- **Hindi**: 85-92% accuracy (depending on model and accent)
- **Indian English**: 90-95% accuracy
- **Noisy Audio**: 70-85% accuracy

**Factors Affecting Accuracy:**
- Audio quality (clear vs noisy)
- Speaker accent and clarity
- Background noise
- Model size (larger = more accurate)
- Language (English generally better than Hindi)

**Improving Accuracy:**
- Use larger Whisper model (medium or large)
- Preprocess audio (noise reduction)
- Use better microphone/audio source
- Fine-tune model on your data (advanced)

### Language Support (Indian English / Hindi)

**Whisper Language Support:**
- **English (en)**: Excellent support
- **Hindi (hi)**: Good support
- **Code-Switching**: Can handle English + Hindi mix
- **Regional Languages**: Limited support (Telugu, Tamil, etc.)

**Model Selection:**
- Use `base` or `small` model for speed
- Use `medium` or `large` model for accuracy
- Download Hindi-specific model if available

**Handling Mixed Language:**
- Whisper can detect language automatically
- Can transcribe English-Hindi mix
- May need post-processing for code-switching

### Background Processing Flow

**Architecture:**
```
[Recording Complete] → [File Watcher Detects] → [Add to Queue]
                                                        ↓
                                                [Worker Process]
                                                        ↓
                                                [Check Queue]
                                                        ↓
                                                [Process Next File]
                                                        ↓
                                                [Run Whisper]
                                                        ↓
                                                [Save Result]
                                                        ↓
                                                [Mark Complete]
                                                        ↓
                                                [Check Queue Again]
```

**Implementation Options:**

**Option 1: Cron Job**
- Run every 1-5 minutes
- Check for new recordings
- Process oldest unprocessed file
- Simple but not real-time

**Option 2: Daemon/Service**
- Background service running continuously
- Watches directory for new files
- Processes immediately
- More responsive

**Option 3: Message Queue**
- Use Redis/RabbitMQ for queue
- Multiple workers can process files
- Scalable and robust
- More complex setup

**Recommendation:**
- Start with cron job (simple)
- Upgrade to daemon later (better performance)
- Use message queue for production (scalable)

**Processing Time:**
- Small model: 1-2x real-time (1 minute audio = 1-2 minutes processing)
- Medium model: 2-4x real-time
- Large model: 4-8x real-time
- GPU acceleration: 10-50x faster

---

## STEP 7: DATABASE & DATA STORAGE

### Database Schema Design (Conceptual)

**Calls Table:**
- `call_id` (Primary Key, Auto-increment)
- `caller_id_number` (String, Caller's phone number)
- `caller_id_name` (String, Caller's name if available)
- `called_number` (String, Number that was called - your SIP extension)
- `direction` (Enum: 'incoming', 'outgoing')
- `call_status` (Enum: 'answered', 'busy', 'no-answer', 'failed')
- `start_time` (DateTime, When call started)
- `answer_time` (DateTime, When call was answered)
- `end_time` (DateTime, When call ended)
- `duration` (Integer, Total call duration in seconds)
- `talk_time` (Integer, Actual talk time in seconds)
- `recording_path` (String, Path to full call recording if available)
- `created_at` (DateTime, Record creation timestamp)
- `updated_at` (DateTime, Last update timestamp)

**Callers Table:**
- `caller_id` (Primary Key, Auto-increment)
- `phone_number` (String, Unique, Caller's phone number)
- `name` (String, Caller's name if known)
- `first_call_date` (DateTime, First time this caller called)
- `last_call_date` (DateTime, Most recent call)
- `total_calls` (Integer, Count of calls from this number)
- `notes` (Text, Admin notes about this caller)
- `created_at` (DateTime)
- `updated_at` (DateTime)

**Recordings Table:**
- `recording_id` (Primary Key, Auto-increment)
- `call_id` (Foreign Key, Links to Calls table)
- `recording_type` (Enum: 'full_call', 'question_response', 'greeting')
- `question_number` (Integer, If part of question flow, which question)
- `file_path` (String, Full path to audio file)
- `file_size` (Integer, Size in bytes)
- `duration` (Integer, Recording duration in seconds)
- `format` (String, Audio format: 'wav', 'mp3', etc.)
- `created_at` (DateTime)

**Transcriptions Table:**
- `transcription_id` (Primary Key, Auto-increment)
- `recording_id` (Foreign Key, Links to Recordings table)
- `call_id` (Foreign Key, Links to Calls table for quick access)
- `transcribed_text` (Text, The transcribed text)
- `language` (String, Detected language: 'en', 'hi', etc.)
- `confidence_score` (Float, Confidence level 0-1 if available)
- `processing_time` (Integer, Time taken to transcribe in seconds)
- `model_used` (String, Which STT model was used)
- `status` (Enum: 'pending', 'processing', 'completed', 'failed')
- `created_at` (DateTime)
- `completed_at` (DateTime)

**IVR_Responses Table:**
- `response_id` (Primary Key, Auto-increment)
- `call_id` (Foreign Key, Links to Calls table)
- `menu_level` (Integer, Which menu level)
- `option_pressed` (String, DTMF key pressed: '1', '2', '*', etc.)
- `response_time` (DateTime, When option was pressed)
- `created_at` (DateTime)

**Call_Flows Table:**
- `flow_id` (Primary Key, Auto-increment)
- `flow_name` (String, Name of call flow: 'basic_auto_answer', 'ivr', 'questions')
- `flow_type` (Enum: 'auto_answer', 'ivr', 'questions', 'callback')
- `is_active` (Boolean, Whether flow is currently active)
- `configuration` (JSON, Flow-specific settings)
- `created_at` (DateTime)
- `updated_at` (DateTime)

### What Data is Stored

**Call Metadata:**
- Who called (caller ID)
- When they called (timestamps)
- How long they talked (duration)
- Call outcome (answered, busy, etc.)

**Audio Data:**
- Full call recordings
- Question-specific recordings
- File paths and metadata

**Text Data:**
- Transcribed speech
- Language detection
- Confidence scores

**Interaction Data:**
- IVR menu selections
- Question responses (as text)
- Call flow routing decisions

### How Data is Linked

**Relationships:**
```
Callers (1) ──→ (Many) Calls
Calls (1) ──→ (Many) Recordings
Recordings (1) ──→ (1) Transcriptions
Calls (1) ──→ (Many) IVR_Responses
```

**Query Examples:**
- Get all calls from a specific caller: `Callers → Calls`
- Get all recordings for a call: `Calls → Recordings`
- Get transcription for a recording: `Recordings → Transcriptions`
- Get all IVR responses for a call: `Calls → IVR_Responses`

### Retention Strategy

**Short-Term Storage (Active):**
- Keep all data for 30-90 days
- Fast access for recent calls
- Used for active monitoring

**Long-Term Storage (Archive):**
- Move old data (>90 days) to archive
- Compress recordings
- Store in cheaper storage
- Keep metadata in main database

**Deletion Policy:**
- Delete recordings after X days (configurable)
- Keep transcriptions longer (smaller size)
- Keep call metadata indefinitely (for analytics)
- Comply with legal requirements (if any)

**Backup Strategy:**
- Daily database backups
- Weekly full system backups
- Store backups off-server (cloud storage)
- Test restore procedures regularly

### Privacy & Security Considerations

**Data Privacy:**
- Encrypt sensitive data (caller IDs, recordings)
- Anonymize data for analytics
- Implement access controls
- Log all data access

**Security Measures:**
- Encrypt database at rest
- Use SSL/TLS for data transmission
- Implement authentication for admin access
- Regular security updates
- Firewall rules to limit database access

**Compliance:**
- Follow local data protection laws
- Get consent for recording (play announcement)
- Allow callers to opt-out
- Provide data deletion on request

**Access Control:**
- Role-based access (admin, viewer, etc.)
- Audit logs for all data access
- Limit who can download recordings
- Secure API endpoints

---

## STEP 8: AI VOICE AGENT (OPTIONAL – FUTURE READY)

### How to Connect Local LLM

**LLM Options:**

**Option 1: Ollama (Recommended)**
- **What it is**: Local LLM runner, easy to use
- **Models**: LLaMA, Mistral, CodeLlama, etc.
- **Advantages**: Simple setup, good performance, free
- **Installation**: Single command install
- **API**: REST API for integration

**Option 2: LLaMA.cpp**
- **What it is**: C++ implementation of LLaMA
- **Advantages**: Fast, efficient, runs on CPU
- **Models**: Various LLaMA model sizes
- **Installation**: More complex

**Option 3: Hugging Face Transformers**
- **What it is**: Python library for LLMs
- **Advantages**: Many model options, flexible
- **Models**: Thousands of models available
- **Installation**: Python-based

**Recommendation: Ollama**
- Easiest to set up
- Good documentation
- Active development
- Works well for voice agents

### AI Logic for Question-Answer

**Architecture:**
```
[Caller Speech] → [STT] → [Text] → [LLM Processing] → [Response Text] → [TTS] → [Audio] → [Play to Caller]
```

**Flow:**
1. Caller speaks
2. Speech converted to text (Whisper)
3. Text sent to LLM with context
4. LLM generates response
5. Response converted to speech (TTS)
6. Audio played to caller
7. Loop continues

**Context Management:**
- Maintain conversation history
- Include caller information
- Include call purpose/context
- Include previous responses

**Prompt Engineering:**
- System prompt: Define AI personality and role
- User prompt: Current question/statement
- Context: Previous conversation
- Instructions: How to respond (tone, length, etc.)

### Prompt Handling

**System Prompt Example:**
```
"You are a helpful customer service assistant for [Company Name].
You are friendly, professional, and concise.
You answer questions about products and services.
You speak in a natural, conversational manner.
Keep responses under 30 seconds when spoken.
If you don't know something, offer to connect to a human agent."
```

**Context Injection:**
- Caller's name (if known)
- Caller's history (previous calls)
- Current date/time
- Company information
- Product/service details

**Response Formatting:**
- Remove markdown formatting
- Add natural pauses
- Break long responses into chunks
- Add conversational fillers (optional)

### Conversation Memory

**Short-Term Memory (Current Call):**
- Store conversation history in memory
- Keep last 10-20 exchanges
- Use for context in LLM prompts
- Clear after call ends

**Long-Term Memory (Cross-Call):**
- Store in database
- Link to caller ID
- Retrieve on new calls from same number
- Use for personalization

**Memory Structure:**
```
Conversation_History Table:
- call_id
- exchange_number (1, 2, 3, ...)
- caller_text
- ai_response
- timestamp
- context_used
```

**Retrieval:**
- On new call, fetch previous conversations
- Summarize if too long
- Inject into system prompt
- Update as call progresses

### Human-Like vs IVR-Like Behavior

**Human-Like Behavior:**
- Natural conversation flow
- Handles interruptions
- Asks clarifying questions
- Shows empathy
- Adapts to caller's style
- Uses natural language

**IVR-Like Behavior:**
- Structured menu-driven
- Clear instructions
- Limited options
- Predictable flow
- Faster for simple tasks

**Hybrid Approach:**
- Start with greeting and options
- Allow natural conversation
- Fall back to menu if confused
- Best of both worlds

**Implementation:**
- Use LLM for natural conversation
- Use IVR for structured tasks
- Detect caller intent
- Route accordingly

---

## STEP 9: ADMIN DASHBOARD (CONCEPT)

### Dashboard Overview

**Purpose:**
- Monitor system health
- View call logs and analytics
- Manage recordings and transcriptions
- Configure call flows
- Export data

**Technology Stack (Conceptual):**
- **Frontend**: Web-based (HTML, CSS, JavaScript)
- **Backend**: PHP (aaPanel compatible) or Python/Node.js
- **Database**: MySQL/MariaDB (aaPanel default)
- **Framework**: Laravel, Django, or simple PHP

### Dashboard Features

**1. Dashboard Home Page:**
- Total calls today/week/month
- Active calls (real-time)
- System status (Asterisk running, disk space, etc.)
- Recent calls list
- Quick stats (answered, missed, failed)

**2. Call Logs Page:**
- Table of all calls
- Filters: date range, caller ID, status, duration
- Sortable columns
- Search functionality
- Pagination
- Export to CSV/Excel

**3. Call Recordings Page:**
- List of all recordings
- Play audio in browser
- Download recordings
- Link to transcriptions
- Filter by date, caller, call type
- Delete recordings

**4. Transcriptions Page:**
- List of all transcriptions
- View transcribed text
- Search in transcriptions
- Edit transcriptions (manual correction)
- Export transcriptions
- Link to original recording

**5. Callers Page:**
- List of all callers
- Call history per caller
- Total calls per caller
- Notes/remarks per caller
- Block/unblock callers

**6. Call Flow Configuration:**
- Enable/disable call flows
- Configure IVR menus
- Set greeting messages
- Configure question flows
- Test call flows

**7. Analytics Page:**
- Calls per day/week/month (charts)
- Peak calling hours
- Average call duration
- Call success rate
- Caller demographics (if available)

**8. Settings Page:**
- System configuration
- SIP user management
- Recording settings
- Transcription settings
- Backup configuration
- User management (admin accounts)

### How Dashboard Connects to Backend

**Architecture:**
```
[Web Browser] → [Web Server (Nginx/Apache)] → [PHP/Python Backend] → [MySQL Database] → [Asterisk/CDR]
                                                                         ↓
                                                                    [File System]
                                                                    (Recordings)
```

**Data Flow:**

**Reading Call Data:**
1. Dashboard queries MySQL database
2. Database contains CDR (Call Detail Records) from Asterisk
3. Results displayed in tables/charts

**Reading Recordings:**
1. Dashboard reads file paths from database
2. Serves audio files via web server
3. Streams or downloads to browser

**Reading Transcriptions:**
1. Dashboard queries Transcriptions table
2. Displays text with links to recordings
3. Allows editing and saving

**Writing Configuration:**
1. Admin changes settings in dashboard
2. Backend writes to database
3. Backend updates Asterisk configuration files
4. Asterisk reloads configuration
5. Changes take effect

**Real-Time Updates:**
- Use WebSockets or polling
- Update active calls display
- Show new calls as they happen
- Update statistics periodically

### Integration Points

**Asterisk Integration:**
- **AMI (Asterisk Manager Interface)**: Real-time call monitoring
- **CDR (Call Detail Records)**: Historical call data
- **AGI (Asterisk Gateway Interface)**: Execute scripts during calls
- **Configuration Files**: Modify dialplan, SIP users, etc.

**Database Integration:**
- Read from Calls, Recordings, Transcriptions tables
- Write configuration changes
- Store admin actions (audit log)

**File System Integration:**
- List recording files
- Serve audio files
- Manage file storage
- Clean up old files

**STT Integration:**
- Trigger transcription jobs
- Monitor transcription status
- Display transcription results

---

## STEP 10: LEGAL & REALITY CHECK (INDIA)

### What is Legal in India

**Legal Activities:**
- Operating a SIP/VoIP server for personal/business use
- Receiving calls via SIP (internet-based)
- Automated call answering and IVR systems
- Call recording (with proper consent announcement)
- Using virtual numbers for business purposes
- AI voice agents (as long as not impersonating humans deceptively)

**Gray Areas:**
- Making automated outbound calls (may require compliance)
- Telemarketing (requires registration with TRAI)
- Bulk messaging (requires registration)

**Illegal Activities:**
- Impersonating government officials
- Fraudulent calls
- Harassment or spam calls
- Violating privacy laws

### Why +91 Numbers Need Telecom Approval

**+91 Number Explanation:**
- +91 is India's country code
- Assigned by Department of Telecommunications (DoT)
- Requires telecom license for allocation
- Only licensed operators can issue +91 numbers

**Why You Can't Get +91 Number Easily:**
- Requires telecom license (expensive, complex)
- Must be a registered telecom operator
- Compliance with TRAI regulations
- Infrastructure requirements

**What You Can Do Instead:**
- Use SIP addresses (not +91 numbers)
- Use SIP-to-PSTN gateway (gateway provider has +91 numbers)
- Use virtual numbers from gateway providers (they handle licensing)

### Difference Between Virtual SIP Number and Mobile Number

**Virtual SIP Number:**
- Software-based identifier
- Format: `sip:1001@sip.yourdomain.com`
- Works over internet only
- No telecom license needed
- Free to create
- Cannot directly call mobile/landline

**Mobile Number (+91):**
- Physical SIM card number
- Format: `+91-9876543210`
- Works on cellular network
- Requires telecom license
- Monthly charges + per-minute
- Can call any phone worldwide

**Key Difference:**
- SIP number = Internet identifier (like email address)
- Mobile number = Telecom network identifier (like postal address)

### What is Allowed for Testing, AI, IVR, Callbacks

**Testing:**
- ✅ Testing SIP-to-SIP calls (free, legal)
- ✅ Testing with SIP clients/apps
- ✅ Testing IVR and call flows
- ✅ Testing AI voice agents
- ✅ Testing call recording

**AI Voice Agents:**
- ✅ Legal to use AI for customer service
- ✅ Must disclose it's an AI (if required by law)
- ✅ Cannot impersonate humans deceptively
- ✅ Must comply with data protection laws

**IVR Systems:**
- ✅ Legal to use IVR for business
- ✅ Must provide option to speak to human
- ✅ Must comply with customer service standards

**Callbacks:**
- ✅ Legal to call back customers
- ⚠️ Must comply with DNC (Do Not Call) registry
- ⚠️ Cannot call registered numbers without consent
- ✅ Can call if customer initiated contact

**Automated Outbound Calls:**
- ⚠️ Requires compliance with TRAI regulations
- ⚠️ Must register for promotional calls
- ⚠️ Must follow calling hours restrictions
- ✅ Allowed for transactional calls (with consent)

### Compliance Basics

**TRAI Compliance (If Making Outbound Calls):**
- Register with TRAI for promotional calls
- Follow calling hours (9 AM - 9 PM)
- Maintain DNC (Do Not Call) list
- Provide caller identification
- Record consent for calls

**Data Protection:**
- Comply with IT Act and data protection laws
- Get consent for recording calls
- Secure storage of personal data
- Allow data deletion on request
- Privacy policy required

**Call Recording Consent:**
- Announce that call is being recorded
- Get explicit consent (if required)
- Allow caller to opt-out
- Store consent records

**Best Practices:**
- Always announce call recording
- Provide clear privacy policy
- Allow callers to opt-out
- Secure data storage
- Regular compliance audits

---

## STEP 11: SCALABILITY & SECURITY

### How to Handle More Calls

**Vertical Scaling (Upgrade Server):**
- Increase CPU cores (more concurrent calls)
- Increase RAM (more active calls)
- Increase bandwidth (more simultaneous streams)
- Upgrade storage (more recordings)

**Horizontal Scaling (Multiple Servers):**
- Deploy multiple Asterisk servers
- Use load balancer for SIP traffic
- Distribute calls across servers
- Shared database for call data
- Shared storage for recordings

**Optimization:**
- Use efficient audio codecs (Opus, G.729)
- Compress recordings (MP3 instead of WAV)
- Optimize database queries
- Use caching (Redis) for frequently accessed data
- CDN for serving recordings (if many downloads)

**Concurrent Call Capacity:**
- Rule of thumb: 1 CPU core = 10-20 concurrent calls
- 4 cores = 40-80 concurrent calls
- Depends on codec, features used, server load

### SIP Security (fail2ban, Rate Limits)

**Common SIP Attacks:**
- **SIP Scanning**: Attackers scan for open SIP ports
- **Brute Force**: Attempting to guess SIP passwords
- **SIP Flooding**: Overwhelming server with INVITE requests
- **Toll Fraud**: Unauthorized use of your system to make calls

**Security Measures:**

**1. fail2ban:**
- Monitors SIP logs for failed authentication
- Bans IP addresses after X failed attempts
- Prevents brute force attacks
- Auto-unban after time period

**2. Rate Limiting:**
- Limit calls per IP address per minute
- Limit calls per SIP user per hour
- Prevent SIP flooding
- Configure in Asterisk or firewall

**3. Strong Passwords:**
- Use complex SIP passwords
- Change default passwords
- Use different passwords per user
- Regular password rotation

**4. IP Whitelisting:**
- Allow only trusted IPs (if possible)
- Block known malicious IPs
- Use firewall rules

**5. SIP Encryption:**
- Use SIP over TLS (port 5061)
- Encrypt SIP signaling
- Use SRTP for media encryption
- Prevents eavesdropping

### Prevent Call Abuse

**Abuse Prevention:**
- Rate limiting (calls per hour/day)
- Call duration limits
- Cost limits (if using gateway)
- Monitor for unusual patterns
- Auto-block suspicious numbers

**Monitoring:**
- Track calls per caller ID
- Alert on unusual activity
- Monitor for toll fraud patterns
- Review call logs regularly

**Access Control:**
- Restrict SIP user permissions
- Limit outbound calling (if enabled)
- Use different contexts for different users
- Implement call routing restrictions

### Encryption Options

**SIP Signaling Encryption:**
- **SIP over TLS**: Encrypts SIP messages
- Port 5061 (instead of 5060)
- Requires SSL certificate
- Prevents call interception

**Media Encryption:**
- **SRTP (Secure RTP)**: Encrypts voice data
- Prevents voice eavesdropping
- Works with SIP over TLS
- Requires compatible clients

**Database Encryption:**
- Encrypt sensitive fields (caller IDs, transcriptions)
- Use database encryption at rest
- Encrypt backups
- Use SSL for database connections

**File Encryption:**
- Encrypt recordings (optional)
- Use encrypted file system
- Encrypt backups
- Secure file permissions

### Backup Strategy

**What to Backup:**
- Database (call logs, transcriptions, configuration)
- Recordings (audio files)
- Asterisk configuration files
- System configuration

**Backup Frequency:**
- Database: Daily (automated)
- Recordings: Weekly (or continuous)
- Configuration: After changes
- Full system: Monthly

**Backup Storage:**
- Local backup (on server)
- Remote backup (cloud storage, another server)
- Multiple copies (3-2-1 rule: 3 copies, 2 different media, 1 off-site)

**Backup Tools:**
- **Database**: mysqldump, pg_dump
- **Files**: rsync, tar, cloud sync tools
- **Automation**: Cron jobs, backup scripts
- **Cloud**: AWS S3, Google Cloud Storage, Backblaze

**Restore Testing:**
- Test restore procedures regularly
- Verify backup integrity
- Document restore process
- Keep backup logs

**Disaster Recovery:**
- Document recovery procedures
- Keep recovery time objective (RTO) in mind
- Keep recovery point objective (RPO) in mind
- Test disaster recovery plan

---

## IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Week 1-2)
1. Set up Contabo VPS with Ubuntu
2. Install aaPanel
3. Configure firewall (UFW)
4. Set up domain DNS (if using domain)
5. Install Asterisk
6. Configure basic SIP user
7. Test SIP-to-SIP call

### Phase 2: Core Features (Week 3-4)
1. Configure basic auto-answer flow
2. Set up call recording
3. Implement IVR system
4. Create database schema
5. Set up CDR logging
6. Build basic admin dashboard

### Phase 3: Advanced Features (Week 5-6)
1. Implement question-answer flow
2. Set up Whisper.cpp for STT
3. Configure transcription pipeline
4. Enhance admin dashboard
5. Add analytics and reporting

### Phase 4: Security & Optimization (Week 7-8)
1. Implement fail2ban
2. Set up rate limiting
3. Configure encryption (TLS/SRTP)
4. Optimize performance
5. Set up backup system

### Phase 5: Future Enhancements (Ongoing)
1. Integrate AI voice agent (Ollama)
2. Add WebRTC support
3. Implement callback system
4. Add more call flows
5. Scale infrastructure

---

## CONCLUSION

This system design provides a complete blueprint for building your own virtual phone number system on a Contabo VPS with aaPanel. The architecture is:

- **Self-hosted**: Full control over your system
- **Open-source**: Uses free, open-source tools
- **Scalable**: Can grow with your needs
- **Secure**: Includes security best practices
- **Legal**: Complies with Indian regulations (for allowed use cases)

**Next Steps:**
1. Review this document thoroughly
2. Set up your VPS and install required software
3. Follow the implementation roadmap
4. Test each component before moving to the next
5. Iterate and improve based on your needs

**Remember:**
- Start simple, add complexity gradually
- Test thoroughly before production use
- Monitor system performance
- Keep backups regularly
- Stay compliant with local laws

Good luck with your virtual phone number system!

