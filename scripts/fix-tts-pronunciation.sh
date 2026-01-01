#!/bin/bash

# Fix TTS pronunciation issues
# Regenerate audio files with better text formatting for pico2wave

set -e

echo "Fixing TTS pronunciation issues..."

CUSTOM_DIR="/usr/share/asterisk/sounds/en/custom"

# Backup existing files
mkdir -p "$CUSTOM_DIR/backup"
cp "$CUSTOM_DIR"/*.wav "$CUSTOM_DIR/backup/" 2>/dev/null || true

# Regenerate with better pronunciation hints
# Use phonetic spelling or break words differently for pico2wave

echo "Regenerating audio files with improved pronunciation..."

# Greeting - break "Thanvish" into syllables
pico2wave -w "$CUSTOM_DIR/greeting.wav" -l en-US "Hi, this is Than-vish Music A I. How can I help you today?" 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/greeting.wav" "Hi, this is Than-vish Music A I. How can I help you today?" 2>/dev/null || \
echo "Warning: pico2wave may not be available"

# Menu options - use clearer phrasing
pico2wave -w "$CUSTOM_DIR/menu-1.wav" -l en-US "For music ragas, press one." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/menu-1.wav" "For music ragas, press one." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/menu-2.wav" -l en-US "To learn about tala and rhythms, press two." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/menu-2.wav" "To learn about tala and rhythms, press two." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/menu-3.wav" -l en-US "For drums and percussion details, press three." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/menu-3.wav" "For drums and percussion details, press three." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/menu-4.wav" -l en-US "For general music help, press four." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/menu-4.wav" "For general music help, press four." 2>/dev/null || true

# Option responses
pico2wave -w "$CUSTOM_DIR/option-1.wav" -l en-US "You selected music ragas. Information will be available soon." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/option-1.wav" "You selected music ragas. Information will be available soon." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/option-2.wav" -l en-US "You selected tala and rhythms. Information will be available soon." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/option-2.wav" "You selected tala and rhythms. Information will be available soon." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/option-3.wav" -l en-US "You selected drums and percussion. Information will be available soon." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/option-3.wav" "You selected drums and percussion. Information will be available soon." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/option-4.wav" -l en-US "You selected general music help. Information will be available soon." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/option-4.wav" "You selected general music help. Information will be available soon." 2>/dev/null || true

pico2wave -w "$CUSTOM_DIR/invalid.wav" -l en-US "Invalid option. Please try again." 2>/dev/null || \
pico2wave -w "$CUSTOM_DIR/invalid.wav" "Invalid option. Please try again." 2>/dev/null || true

# Convert to 8kHz
echo ""
echo "Converting to 8kHz format..."
if command -v ffmpeg &> /dev/null; then
    for file in "$CUSTOM_DIR"/*.wav; do
        if [ -f "$file" ] && [[ "$file" != *"backup"* ]]; then
            ffmpeg -i "$file" -ar 8000 -ac 1 -sample_fmt s16 -y "${file}.tmp" 2>/dev/null
            mv "${file}.tmp" "$file"
        fi
    done
fi

# Set permissions
chown asterisk:asterisk "$CUSTOM_DIR"/*.wav 2>/dev/null || true
chmod 644 "$CUSTOM_DIR"/*.wav 2>/dev/null || true

echo ""
echo "✅ Audio files regenerated"
echo ""
echo "⚠️  Note: TTS may still mispronounce some words."
echo "   For best quality, record custom audio files with a human voice."
echo "   See HUMAN_VOICE_IVR_SETUP.md for instructions."
echo ""
echo "Test by calling extension 1002"

