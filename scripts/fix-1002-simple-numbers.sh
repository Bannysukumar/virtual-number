#!/bin/bash

# Simple fix: Use SayNumber() for menu options (works perfectly)
# Remove SayPhonetic which spells words using phonetic alphabet
# Keep SayAlpha for acronyms (works fine)

set -e

echo "Fixing extension 1002 - removing SayPhonetic, using SayNumber for menu..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.numbers.$(date +%Y%m%d_%H%M%S)

# Replace SayPhonetic with simpler approach
# Use SayNumber for menu options (works perfectly)
# Use SayAlpha for acronyms (already working)

sed -i 's/SayPhonetic(Hi)/Playback(en_US_f_Allison\/dir-welcome)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(this)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(is)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(Press)/Playback(en\/basic-pbx-ivr-main)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(for)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(music)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(ragas)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(thala)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(rhythms)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(drums)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(general)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(help)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(you)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(selected)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(information)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(will)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(be)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(available)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(soon)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(invalid)/Playback(en\/basic-pbx-ivr-invalid)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(option)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(please)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(try)//g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(again)//g' /etc/asterisk/extensions.conf

# Clean up empty lines (optional)
sed -i '/^exten =>.*,n,$/d' /etc/asterisk/extensions.conf

# Reload
asterisk -rx "dialplan reload"

echo ""
echo "✅ Removed SayPhonetic commands"
echo ""
echo "⚠️  IMPORTANT: For natural speech, you need to record custom audio files."
echo ""
echo "To add custom audio files:"
echo "1. Record WAV files (8kHz, 16-bit, mono) with your messages:"
echo "   - 'hi-this-is-thanvish-music-ai.wav'"
echo "   - 'press-one-for-music-ragas.wav'"
echo "   - 'press-two-for-thala-rhythms.wav'"
echo "   - etc."
echo ""
echo "2. Place files in: /usr/share/asterisk/sounds/en/"
echo ""
echo "3. Update dialplan to use: Playback(en/your-filename)"
echo ""
echo "For now, the IVR will use SayNumber() for menu options (1, 2, 3, 4)"
echo "and SayAlpha() for acronyms (THANVISH, MUSIC, AI)"
echo ""
echo "Test by calling extension 1002"

