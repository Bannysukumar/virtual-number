#!/bin/bash

# Convert audio files from 16kHz to 8kHz for Asterisk compatibility

set -e

echo "Converting audio files to 8kHz format..."

CUSTOM_DIR="/usr/share/asterisk/sounds/en/custom"

# Check if ffmpeg or sox is available
if command -v ffmpeg &> /dev/null; then
    echo "Using ffmpeg to convert files..."
    for file in "$CUSTOM_DIR"/*.wav; do
        if [ -f "$file" ]; then
            echo "Converting: $(basename $file)"
            ffmpeg -i "$file" -ar 8000 -ac 1 -sample_fmt s16 -y "${file}.tmp" 2>/dev/null
            mv "${file}.tmp" "$file"
        fi
    done
elif command -v sox &> /dev/null; then
    echo "Using sox to convert files..."
    for file in "$CUSTOM_DIR"/*.wav; do
        if [ -f "$file" ]; then
            echo "Converting: $(basename $file)"
            sox "$file" -r 8000 -c 1 -b 16 "${file}.tmp" 2>/dev/null
            mv "${file}.tmp" "$file"
        fi
    done
else
    echo "⚠️  Warning: ffmpeg or sox not found. Installing ffmpeg..."
    apt-get update
    apt-get install -y ffmpeg
    
    for file in "$CUSTOM_DIR"/*.wav; do
        if [ -f "$file" ]; then
            echo "Converting: $(basename $file)"
            ffmpeg -i "$file" -ar 8000 -ac 1 -sample_fmt s16 -y "${file}.tmp" 2>/dev/null
            mv "${file}.tmp" "$file"
        fi
    done
fi

# Set permissions
chown asterisk:asterisk "$CUSTOM_DIR"/*.wav 2>/dev/null || true
chmod 644 "$CUSTOM_DIR"/*.wav 2>/dev/null || true

echo ""
echo "✅ Audio files converted to 8kHz"
echo ""
echo "Verifying format:"
file "$CUSTOM_DIR"/greeting.wav

echo ""
echo "Files ready for Asterisk!"

