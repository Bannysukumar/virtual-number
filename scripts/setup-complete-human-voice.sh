#!/bin/bash

# Complete setup for Human Voice IVR
# Runs both audio generation and dialplan update

set -e

echo "=========================================="
echo "Thanvish Music AI - Complete Human Voice IVR Setup"
echo "=========================================="
echo ""

# Step 1: Generate audio files
echo "Step 1/2: Generating audio files..."
chmod +x scripts/setup-human-voice-ivr.sh
./scripts/setup-human-voice-ivr.sh

echo ""
echo "Step 2/2: Updating dialplan..."
chmod +x scripts/update-dialplan-human-voice.sh
./scripts/update-dialplan-human-voice.sh

echo ""
echo "=========================================="
echo "✅ Human Voice IVR Setup Complete!"
echo "=========================================="
echo ""
echo "Features:"
echo "  ✅ Natural female voice greeting"
echo "  ✅ Human-like menu flow"
echo "  ✅ Call recording (starts immediately)"
echo "  ✅ Two-way audio"
echo "  ✅ Menu repeats once on timeout"
echo "  ✅ Call logging to database"
echo ""
echo "Test by calling extension 1002"
echo ""

