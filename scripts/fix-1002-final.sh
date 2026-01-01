#!/bin/bash

# Final fix: Remove spaces from SayAlpha and remove unwanted Playback files
# SayAlpha should be: SayAlpha(THANVISH) not SayAlpha(T H A N V I S H)

set -e

echo "Fixing SayAlpha to remove spaces and removing unwanted Playback files..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.final.$(date +%Y%m%d_%H%M%S)

# Fix SayAlpha - remove spaces (SayAlpha should not have spaces)
sed -i 's/SayAlpha(T H A N V I S H)/SayAlpha(THANVISH)/g' /etc/asterisk/extensions.conf
sed -i 's/SayAlpha(M U S I C)/SayAlpha(MUSIC)/g' /etc/asterisk/extensions.conf
sed -i 's/SayAlpha(A I)/SayAlpha(AI)/g' /etc/asterisk/extensions.conf

# Remove the unwanted Playback(en/basic-pbx-ivr-main) line
sed -i '/Playback(en\/basic-pbx-ivr-main)/d' /etc/asterisk/extensions.conf

# Optionally, simplify the greeting - remove dir-welcome if it's not appropriate
# Or keep it if you want a greeting. Let's keep it for now but add a simple menu prompt

# The fixes above should be sufficient

# Reload
asterisk -rx "dialplan reload"

echo ""
echo "✅ Fixed:"
echo "  - SayAlpha now without spaces: SayAlpha(THANVISH) instead of SayAlpha(T H A N V I S H)"
echo "  - Removed unwanted Playback(en/basic-pbx-ivr-main)"
echo ""
echo "The IVR will now:"
echo "  - Play welcome greeting"
echo "  - Spell: T-H-A-N-V-I-S-H M-U-S-I-C A-I (without saying 'space')"
echo "  - Say menu numbers: one, two, three, four"
echo ""
echo "Test by calling extension 1002"

