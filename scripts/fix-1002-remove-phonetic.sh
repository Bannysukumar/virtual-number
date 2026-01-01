#!/bin/bash

# Simple fix: Remove all SayPhonetic lines (they spell words, don't pronounce them)
# Keep SayNumber (works perfectly) and SayAlpha (works fine)

set -e

echo "Removing SayPhonetic commands - they spell words using phonetic alphabet"
echo "Keeping SayNumber and SayAlpha which work correctly"

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.remove-phonetic.$(date +%Y%m%d_%H%M%S)

# Remove all SayPhonetic lines from thanvish sections
sed -i '/thanvish-menu.*SayPhonetic/d' /etc/asterisk/extensions.conf
sed -i '/thanvish-menu-repeat.*SayPhonetic/d' /etc/asterisk/extensions.conf
sed -i '/exten => [1-4].*SayPhonetic/d' /etc/asterisk/extensions.conf
sed -i '/exten => i.*SayPhonetic/d' /etc/asterisk/extensions.conf
sed -i '/exten => t.*SayPhonetic/d' /etc/asterisk/extensions.conf

# Clean up any double blank lines
sed -i '/^$/N;/^\n$/d' /etc/asterisk/extensions.conf

# Reload
asterisk -rx "dialplan reload"

echo ""
echo "✅ Removed all SayPhonetic commands"
echo ""
echo "The IVR now uses:"
echo "  - SayNumber() for menu options (1, 2, 3, 4)"
echo "  - SayAlpha() for acronyms (THANVISH, MUSIC, AI)"
echo "  - Playback() for greetings"
echo ""
echo "⚠️  For custom speech, you need to record audio files."
echo "   See: scripts/create-custom-audio.sh (to be created)"
echo ""
echo "Test by calling extension 1002"

