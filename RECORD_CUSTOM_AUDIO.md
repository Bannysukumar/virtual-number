# How to Record Custom Audio Files for Perfect Pronunciation

## Problem
TTS (pico2wave) is mispronouncing words:
- "Thanvish" → "Ben Whitney"
- "ragas" → "rockets"
- "thala" → "salad"
- "rhythms" → "raisins"
- "drums" → "drafts"
- "help" → "health"

## Solution: Record Custom Audio Files

### Step 1: Record Audio Files

**Required Format:**
- Format: WAV
- Sample Rate: 8000 Hz (8 kHz)
- Bit Depth: 16-bit
- Channels: Mono (1 channel)
- Codec: PCM

**Tools:**
- **Windows**: Audacity (free), Windows Voice Recorder
- **Linux**: `arecord`, Audacity
- **Online**: Online WAV recorder/converter
- **Mobile**: Voice recorder app (then convert)

### Step 2: Record These Files

Record these exact phrases with a clear, friendly female voice:

1. **greeting.wav**: "Hi, this is Thanvish Music AI. How can I help you today?"
2. **menu-1.wav**: "For music ragas, press 1."
3. **menu-2.wav**: "To learn about thala and rhythms, press 2."
4. **menu-3.wav**: "For drums and percussion details, press 3."
5. **menu-4.wav**: "For general music help, press 4."
6. **option-1.wav**: "You selected music ragas. Information will be available soon."
7. **option-2.wav**: "You selected thala and rhythms. Information will be available soon."
8. **option-3.wav**: "You selected drums and percussion. Information will be available soon."
9. **option-4.wav**: "You selected general music help. Information will be available soon."
10. **invalid.wav**: "Invalid option. Please try again."

### Step 3: Convert to Correct Format

**Using Audacity (Recommended):**
1. Record your audio
2. Go to: Tracks → Resample → Set to 8000 Hz
3. Go to: Tracks → Mix → Mix Stereo Down to Mono
4. Export as: WAV (Microsoft) signed 16-bit PCM

**Using ffmpeg (if you have a file):**
```bash
ffmpeg -i input.wav -ar 8000 -ac 1 -sample_fmt s16 output.wav
```

**Using sox:**
```bash
sox input.wav -r 8000 -c 1 -b 16 output.wav
```

### Step 4: Upload to Server

```bash
# On your server, create directory (if not exists)
mkdir -p /usr/share/asterisk/sounds/en/custom

# Upload files using SCP (from your computer)
scp greeting.wav root@your-server-ip:/usr/share/asterisk/sounds/en/custom/
scp menu-*.wav root@your-server-ip:/usr/share/asterisk/sounds/en/custom/
scp option-*.wav root@your-server-ip:/usr/share/asterisk/sounds/en/custom/
scp invalid.wav root@your-server-ip:/usr/share/asterisk/sounds/en/custom/

# Or copy directly if you have access
cp *.wav /usr/share/asterisk/sounds/en/custom/

# Set permissions
chown asterisk:asterisk /usr/share/asterisk/sounds/en/custom/*.wav
chmod 644 /usr/share/asterisk/sounds/en/custom/*.wav
```

### Step 5: Verify Format

```bash
# Check format
file /usr/share/asterisk/sounds/en/custom/greeting.wav

# Should show: 8000 Hz, mono, 16-bit
```

### Step 6: Test

```bash
# No need to reload dialplan - files are already referenced
# Just test the call
```

## Alternative: Use Online TTS Services

If you want better TTS quality:

1. **Google Text-to-Speech** (requires API key)
2. **Amazon Polly** (requires AWS account)
3. **Microsoft Azure TTS** (requires Azure account)
4. **ElevenLabs** (paid, excellent quality)

Then convert to 8kHz WAV format.

## Quick Test Script

After uploading files, test:

```bash
# Test if Asterisk can play the file
asterisk -rx "core show settings" | grep soundsdir

# Check file format
file /usr/share/asterisk/sounds/en/custom/greeting.wav

# Call extension 1002 and listen
```

## Tips for Recording

1. **Use a quiet room** - reduce background noise
2. **Speak clearly** - enunciate each word
3. **Normal pace** - not too fast, not too slow
4. **Friendly tone** - warm and welcoming
5. **Consistent volume** - same level for all files
6. **Test playback** - listen to each file before uploading

## Current Status

Your IVR is working but TTS pronunciation needs improvement. Recording custom audio files will give you perfect pronunciation and a professional sound.

