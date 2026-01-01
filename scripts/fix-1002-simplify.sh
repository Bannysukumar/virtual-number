#!/bin/bash

# Simplify IVR - remove problematic dir-welcome and fix SayAlpha
# Use simpler approach: just numbers for menu, skip problematic greeting

set -e

echo "Simplifying IVR - removing problematic greeting and fixing SayAlpha..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.simplify.$(date +%Y%m%d_%H%M%S)

# Remove the problematic dir-welcome that says "Welcome to the directory"
sed -i '/Playback(en_US_f_Allison\/dir-welcome)/d' /etc/asterisk/extensions.conf

# Remove problematic dir-welcome and fix SayAlpha
# Try using SayAlpha with individual letters separated, or simplify to numbers only

sed -i '/Playback(en_US_f_Allison\/dir-welcome)/d' /etc/asterisk/extensions.conf

# Remove SayAlpha commands that are causing issues
# Replace with simpler approach - just numbers for menu
sed -i '/SayAlpha(THANVISH)/d' /etc/asterisk/extensions.conf
sed -i '/SayAlpha(MUSIC)/d' /etc/asterisk/extensions.conf
sed -i '/SayAlpha(AI)/d' /etc/asterisk/extensions.conf

# Remove the extra Wait(0.5) that might be causing timing issues
sed -i '/exten => thanvish-menu,n,Wait(0.5)$/d' /etc/asterisk/extensions.conf

echo "✅ Removed problematic greeting and SayAlpha commands"

# Reload
asterisk -rx "dialplan reload"

echo ""
echo "✅ Simplified IVR:"
echo "  - Removed 'Welcome to the directory' greeting"
echo "  - Removed problematic SayAlpha commands"
echo "  - Menu now just says numbers: one, two, three, four"
echo ""
echo "⚠️  For custom greetings and messages, record audio files"
echo "   See: HOW_TO_ADD_CUSTOM_AUDIO.md"
echo ""
echo "Test by calling extension 1002"

