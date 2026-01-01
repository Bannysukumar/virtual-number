# Human Voice IVR Setup Guide

## Overview

This guide helps you convert the existing IVR to use a natural, human-like female voice instead of robotic TTS.

## Features

- ✅ Natural, soft, human-sounding female voice
- ✅ No robotic or IVR-style tone
- ✅ Normal speaking speed, friendly and polite
- ✅ Clear pronunciation
- ✅ Pre-generated audio files (fast, reliable)
- ✅ Call recording starts immediately
- ✅ Two-way audio works correctly
- ✅ Menu repeats once if no input
- ✅ All calls logged to database

## Quick Setup

```bash
cd /root/virtual-number
git pull origin main
chmod +x scripts/setup-complete-human-voice.sh
./scripts/setup-complete-human-voice.sh
```

This will:
1. Install pico2wave (free TTS)
2. Generate all audio files
3. Convert to Asterisk format (8kHz, 16-bit, mono)
4. Update dialplan to use human voice

## Manual Setup

### Step 1: Install TTS (if not already installed)

```bash
apt-get update
apt-get install -y libttspico-utils
```

### Step 2: Generate Audio Files

```bash
chmod +x scripts/setup-human-voice-ivr.sh
./scripts/setup-human-voice-ivr.sh
```

This generates:
- `greeting.wav` - "Hi, this is Thanvish Music AI. How can I help you today?"
- `menu-1.wav` - "For music ragas, press 1."
- `menu-2.wav` - "To learn about thala and rhythms, press 2."
- `menu-3.wav` - "For drums and percussion details, press 3."
- `menu-4.wav` - "For general music help, press 4."
- `option-1.wav` through `option-4.wav` - Option confirmations
- `invalid.wav` - "Invalid option. Please try again."

### Step 3: Update Dialplan

```bash
chmod +x scripts/update-dialplan-human-voice.sh
./scripts/update-dialplan-human-voice.sh
```

## Using Custom Recorded Audio (Better Quality)

If you want to record your own audio files with a professional voice:

### Step 1: Record Audio Files

Record WAV files with your messages using:
- **Windows**: Audacity (free), Windows Sound Recorder
- **Linux**: `arecord`, Audacity
- **Online**: Online WAV recorder/converter

**Required Format:**
- Format: WAV
- Sample Rate: 8000 Hz (8 kHz)
- Bit Depth: 16-bit
- Channels: Mono (1 channel)
- Codec: PCM

### Step 2: Convert to Correct Format

```bash
# Using ffmpeg
ffmpeg -i input.wav -ar 8000 -ac 1 -sample_fmt s16 output.wav

# Using sox
sox input.wav -r 8000 -c 1 -b 16 output.wav
```

### Step 3: Upload to Server

```bash
# Create directory
mkdir -p /usr/share/asterisk/sounds/en/custom

# Upload files (use SCP, SFTP, or copy directly)
scp greeting.wav root@your-server:/usr/share/asterisk/sounds/en/custom/
scp menu-*.wav root@your-server:/usr/share/asterisk/sounds/en/custom/
scp option-*.wav root@your-server:/usr/share/asterisk/sounds/en/custom/
scp invalid.wav root@your-server:/usr/share/asterisk/sounds/en/custom/

# Set permissions
chown asterisk:asterisk /usr/share/asterisk/sounds/en/custom/*.wav
chmod 644 /usr/share/asterisk/sounds/en/custom/*.wav
```

### Step 4: Update Dialplan

```bash
chmod +x scripts/update-dialplan-human-voice.sh
./scripts/update-dialplan-human-voice.sh
```

## Alternative TTS Options

### Option 1: pico2wave (Current - Free, Good Quality)

```bash
pico2wave -w output.wav -l en-US "Your text here"
```

### Option 2: espeak (Free, More Robotic)

```bash
espeak -s 150 -v en+f3 -w output.wav "Your text here"
```

### Option 3: Festival (Free, Better Quality)

```bash
echo "Your text here" | text2wave -o output.wav
```

### Option 4: Coqui TTS (Open Source, Best Quality - Requires GPU)

For best quality, you can use Coqui TTS (requires more setup):
```bash
# Install Coqui TTS
pip install TTS

# Generate audio
tts --text "Your text here" --out_path output.wav --model_name tts_models/en/ljspeech/tacotron2-DDC
```

## IVR Flow

### Greeting
"Hi, this is Thanvish Music AI. How can I help you today?"

### Menu Options
1. "For music ragas, press 1."
2. "To learn about thala and rhythms, press 2."
3. "For drums and percussion details, press 3."
4. "For general music help, press 4."

### Option Responses
- Option 1: "You selected music ragas. Information will be available soon."
- Option 2: "You selected thala and rhythms. Information will be available soon."
- Option 3: "You selected drums and percussion. Information will be available soon."
- Option 4: "You selected general music help. Information will be available soon."

### Invalid Option
"Invalid option. Please try again."

## Testing

1. Call extension 1002 from your SIP client
2. You should hear the natural greeting
3. Listen to the menu options
4. Press 1, 2, 3, or 4 to test
5. Press an invalid key to test error handling

## Verification

```bash
# Check audio files exist
ls -lh /usr/share/asterisk/sounds/en/custom/

# Check dialplan loaded
asterisk -rx "dialplan show internal" | grep -A 10 "thanvish-menu"

# Test audio playback
asterisk -rx "core show settings" | grep soundsdir

# Check call logs
mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system -e "SELECT * FROM calls ORDER BY call_id DESC LIMIT 1;"
```

## Troubleshooting

### Audio files not playing

1. Check file format:
```bash
file /usr/share/asterisk/sounds/en/custom/greeting.wav
```

2. Check permissions:
```bash
ls -la /usr/share/asterisk/sounds/en/custom/
```

3. Check Asterisk can access files:
```bash
asterisk -rx "core show settings" | grep soundsdir
```

### TTS not generating files

1. Check pico2wave is installed:
```bash
which pico2wave
```

2. Try manual generation:
```bash
pico2wave -w /tmp/test.wav "Test message"
```

3. Check file was created:
```bash
ls -lh /tmp/test.wav
```

### Dialplan not loading

1. Check syntax:
```bash
asterisk -rx "dialplan reload"
asterisk -rx "dialplan show internal" | grep thanvish-menu
```

2. Check logs:
```bash
tail -50 /var/log/asterisk/full | grep -i error
```

## File Locations

- Audio files: `/usr/share/asterisk/sounds/en/custom/`
- Dialplan: `/etc/asterisk/extensions.conf`
- Call recordings: `/var/recordings/calls/`
- Logs: `/var/log/asterisk/full`

## Next Steps

- Customize greeting and menu text
- Add more menu options
- Integrate with AI voice agent (future)
- Add language options (Hindi, etc.)

