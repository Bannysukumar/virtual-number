#!/bin/bash

# Setup Human Voice IVR for Thanvish Music AI
# Uses pico2wave (free TTS) to generate natural-sounding female voice

set -e

echo "=========================================="
echo "Thanvish Music AI - Human Voice IVR Setup"
echo "=========================================="
echo ""

# Check if pico2wave is installed
if ! command -v pico2wave &> /dev/null; then
    echo "Installing pico2wave (Text-to-Speech)..."
    apt-get update
    apt-get install -y libttspico-utils
fi

# Create custom sounds directory
CUSTOM_DIR="/usr/share/asterisk/sounds/en/custom"
mkdir -p "$CUSTOM_DIR"
chown asterisk:asterisk "$CUSTOM_DIR"
chmod 755 "$CUSTOM_DIR"

echo "✅ Created custom sounds directory: $CUSTOM_DIR"
echo ""

# Generate audio files using pico2wave
# pico2wave has a female voice option that sounds natural

echo "Generating audio files with human-like female voice..."
echo ""

# Greeting
echo "Generating greeting..."
pico2wave -w "$CUSTOM_DIR/greeting.wav" -l en-US "Hi, this is Thanvish Music AI. How can I help you today?" 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/greeting.wav" "Hi, this is Thanvish Music AI. How can I help you today?" 2>/dev/null || \
echo "Warning: pico2wave may not be available, you'll need to record audio files manually"

# Menu options
echo "Generating menu options..."
pico2wave -w "$CUSTOM_DIR/menu-1.wav" -l en-US "For music ragas, press 1." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/menu-1.wav" "For music ragas, press 1." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/menu-2.wav" -l en-US "To learn about thala and rhythms, press 2." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/menu-2.wav" "To learn about thala and rhythms, press 2." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/menu-3.wav" -l en-US "For drums and percussion details, press 3." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/menu-3.wav" "For drums and percussion details, press 3." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/menu-4.wav" -l en-US "For general music help, press 4." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/menu-4.wav" "For general music help, press 4." 2>/dev/null || true

# Option responses
echo "Generating option responses..."
pico2wave -w "$CUSTOM_DIR/option-1.wav" -l en-US "You selected music ragas. Information will be available soon." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/option-1.wav" "You selected music ragas. Information will be available soon." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/option-2.wav" -l en-US "You selected thala and rhythms. Information will be available soon." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/option-2.wav" "You selected thala and rhythms. Information will be available soon." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/option-3.wav" -l en-US "You selected drums and percussion. Information will be available soon." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/option-3.wav" "You selected drums and percussion. Information will be available soon." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/option-4.wav" -l en-US "You selected general music help. Information will be available soon." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/option-4.wav" "You selected general music help. Information will be available soon." 2>/dev/null || true

# Invalid option
pico2wave -w "$CUSTOM_DIR/invalid.wav" -l en-US "Invalid option. Please try again." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/invalid.wav" "Invalid option. Please try again." 2>/dev/null || true

# Convert all WAV files to correct format (8kHz, 16-bit, mono)
echo ""
echo "Converting audio files to Asterisk format (8kHz, 16-bit, mono)..."

if command -v ffmpeg &> /dev/null; then
    for file in "$CUSTOM_DIR"/*.wav; do
        if [ -f "$file" ]; then
            ffmpeg -i "$file" -ar 8000 -ac 1 -sample_fmt s16 -y "${file}.tmp" 2>/dev/null && mv "${file}.tmp" "$file" || true
        fi
    done
elif command -v sox &> /dev/null; then
    for file in "$CUSTOM_DIR"/*.wav; do
        if [ -f "$file" ]; then
            sox "$file" -r 8000 -c 1 -b 16 "${file}.tmp" 2>/dev/null && mv "${file}.tmp" "$file" || true
        fi
    done
else
    echo "⚠️  Warning: ffmpeg or sox not found. Audio files may need manual conversion."
    echo "   Install: apt-get install -y ffmpeg (or sox)"
fi

# Set permissions
chown asterisk:asterisk "$CUSTOM_DIR"/*.wav 2>/dev/null || true
chmod 644 "$CUSTOM_DIR"/*.wav 2>/dev/null || true

echo "✅ Audio files generated"
echo ""

# Check if files were created
if ls "$CUSTOM_DIR"/*.wav 1> /dev/null 2>&1; then
    echo "Generated files:"
    ls -lh "$CUSTOM_DIR"/*.wav
    echo ""
else
    echo "⚠️  No audio files generated. You may need to record them manually."
    echo "   See HOW_TO_ADD_CUSTOM_AUDIO.md for instructions"
    echo ""
fi

echo "Next step: Update dialplan to use these audio files"
echo "Run: ./scripts/update-dialplan-human-voice.sh"

