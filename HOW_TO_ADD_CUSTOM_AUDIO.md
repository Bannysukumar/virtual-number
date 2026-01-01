# How to Add Custom Audio Files for Natural IVR Speech

## Problem
`SayPhonetic` in Asterisk spells words using the NATO phonetic alphabet (Hotel, India, Tango...) instead of pronouncing them naturally. For natural speech, you need to record custom audio files.

## Solution: Record Custom Audio Files

### Step 1: Record Audio Files

Record WAV files with your messages. Use a clear, professional voice.

**Required Audio Format:**
- **Format**: WAV
- **Sample Rate**: 8000 Hz (8 kHz)
- **Bit Depth**: 16-bit
- **Channels**: Mono (1 channel)
- **Codec**: PCM

**Tools to Record:**
- **Windows**: Audacity (free), Windows Sound Recorder
- **Linux**: `arecord`, Audacity
- **Online**: Online WAV converter/recorder

### Step 2: Create Required Audio Files

Record these files for the Thanvish Music AI IVR:

1. **greeting.wav** - "Hi, this is Thanvish Music AI"
2. **menu-option-1.wav** - "Press 1 for Music Ragas"
3. **menu-option-2.wav** - "Press 2 for Thala Rhythms"
4. **menu-option-3.wav** - "Press 3 for Drums"
5. **menu-option-4.wav** - "Press 4 for General Music Help"
6. **option-1-selected.wav** - "You selected Music Ragas. Information will be available soon."
7. **option-2-selected.wav** - "You selected Thala Rhythms. Information will be available soon."
8. **option-3-selected.wav** - "You selected Drums. Information will be available soon."
9. **option-4-selected.wav** - "You selected General Music Help. Information will be available soon."
10. **invalid-option.wav** - "Invalid option. Please try again."

### Step 3: Convert to Correct Format (if needed)

If your audio is not in the correct format, convert it:

**Using ffmpeg:**
```bash
ffmpeg -i input.wav -ar 8000 -ac 1 -sample_fmt s16 output.wav
```

**Using sox:**
```bash
sox input.wav -r 8000 -c 1 -b 16 output.wav
```

### Step 4: Upload Files to Server

```bash
# Create directory for custom sounds
mkdir -p /usr/share/asterisk/sounds/en/custom

# Upload files (use SCP, SFTP, or copy directly)
# Example with SCP from Windows:
# scp greeting.wav root@your-server-ip:/usr/share/asterisk/sounds/en/custom/

# Or copy files directly on server
cp greeting.wav /usr/share/asterisk/sounds/en/custom/
cp menu-option-*.wav /usr/share/asterisk/sounds/en/custom/
cp option-*-selected.wav /usr/share/asterisk/sounds/en/custom/
cp invalid-option.wav /usr/share/asterisk/sounds/en/custom/

# Set correct permissions
chown asterisk:asterisk /usr/share/asterisk/sounds/en/custom/*.wav
chmod 644 /usr/share/asterisk/sounds/en/custom/*.wav
```

### Step 5: Update Dialplan

Update `/etc/asterisk/extensions.conf` to use your custom audio files:

```ini
; Thanvish Music AI - Main Menu
exten => thanvish-menu,1,NoOp(Thanvish Music AI - Main Menu)
exten => thanvish-menu,n,Playback(en/custom/greeting)
exten => thanvish-menu,n,Wait(1)
exten => thanvish-menu,n,Playback(en/custom/menu-option-1)
exten => thanvish-menu,n,Wait(0.5)
exten => thanvish-menu,n,Playback(en/custom/menu-option-2)
exten => thanvish-menu,n,Wait(0.5)
exten => thanvish-menu,n,Playback(en/custom/menu-option-3)
exten => thanvish-menu,n,Wait(0.5)
exten => thanvish-menu,n,Playback(en/custom/menu-option-4)
exten => thanvish-menu,n,WaitExten(15)
exten => thanvish-menu,n,Goto(internal,thanvish-menu-repeat,1,1)

; Option handlers
exten => 1,1,NoOp(Option 1 selected - Music Ragas)
exten => 1,n,Playback(en/custom/option-1-selected)
exten => 1,n,Wait(1)
exten => 1,n,Goto(internal,thanvish-menu,1,1)

exten => 2,1,NoOp(Option 2 selected - Thala Rhythms)
exten => 2,n,Playback(en/custom/option-2-selected)
exten => 2,n,Wait(1)
exten => 2,n,Goto(internal,thanvish-menu,1,1)

exten => 3,1,NoOp(Option 3 selected - Drums)
exten => 3,n,Playback(en/custom/option-3-selected)
exten => 3,n,Wait(1)
exten => 3,n,Goto(internal,thanvish-menu,1,1)

exten => 4,1,NoOp(Option 4 selected - General Music Help)
exten => 4,n,Playback(en/custom/option-4-selected)
exten => 4,n,Wait(1)
exten => 4,n,Goto(internal,thanvish-menu,1,1)

exten => i,1,NoOp(Invalid option selected)
exten => i,n,Playback(en/custom/invalid-option)
exten => i,n,Wait(1)
exten => i,n,Goto(internal,thanvish-menu,1,1)
```

### Step 6: Reload Dialplan

```bash
asterisk -rx "dialplan reload"
```

### Step 7: Test

Call extension 1002 and verify all audio files play correctly.

## Alternative: Use Text-to-Speech (TTS)

For automated audio generation, you can use TTS services:

1. **Google Text-to-Speech API** (requires API key)
2. **Amazon Polly** (requires AWS account)
3. **Local TTS**: `espeak`, `festival`, `pico2wave` (Linux)

**Example with pico2wave:**
```bash
# Install pico2wave
apt-get install libttspico-utils

# Generate audio
pico2wave -w greeting.wav -l en-US "Hi, this is Thanvish Music AI"
pico2wave -w menu-option-1.wav -l en-US "Press 1 for Music Ragas"

# Convert to correct format
ffmpeg -i greeting.wav -ar 8000 -ac 1 -sample_fmt s16 greeting-8k.wav
```

## Quick Test Script

Create a test script to verify audio files:

```bash
#!/bin/bash
# test-audio.sh

AUDIO_DIR="/usr/share/asterisk/sounds/en/custom"

for file in greeting.wav menu-option-1.wav menu-option-2.wav menu-option-3.wav menu-option-4.wav; do
    if [ -f "$AUDIO_DIR/$file" ]; then
        echo "✅ $file exists"
        file "$AUDIO_DIR/$file"
    else
        echo "❌ $file missing"
    fi
done
```

## Notes

- Audio files must be in WAV format, 8kHz, 16-bit, mono
- File names should be lowercase with hyphens (no spaces)
- Use `Playback(en/custom/filename)` in dialplan (without .wav extension)
- Test each file individually before updating the dialplan
- Keep backup of original dialplan before making changes

