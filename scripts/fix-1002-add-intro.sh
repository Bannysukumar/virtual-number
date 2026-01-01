#!/bin/bash

# Add proper introduction/greeting to extension 1002
# Use available Asterisk sounds or prepare for custom audio

set -e

echo "Adding introduction/greeting to extension 1002..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.intro.$(date +%Y%m%d_%H%M%S)

# Add a greeting before the menu numbers
# Insert after the NoOp line - add a simple greeting
python3 << 'PYEOF'
import re

with open('/etc/asterisk/extensions.conf', 'r') as f:
    lines = f.readlines()

# Find the thanvish-menu section and add greeting before Wait(1)
new_lines = []
for i, line in enumerate(lines):
    new_lines.append(line)
    # After the NoOp line, add greeting
    if 'thanvish-menu,1,NoOp' in line:
        new_lines.append('exten => thanvish-menu,n,Playback(en_US_f_Allison/vm-youhave)\n')
        new_lines.append('exten => thanvish-menu,n,Wait(0.5)\n')
        new_lines.append('exten => thanvish-menu,n,Playback(en_US_f_Allison/vm-press)\n')
        new_lines.append('exten => thanvish-menu,n,Wait(0.5)\n')

with open('/etc/asterisk/extensions.conf', 'w') as f:
    f.writelines(new_lines)

print("✅ Added greeting/introduction before menu")
PYEOF

# Reload
asterisk -rx "dialplan reload"

echo ""
echo "✅ Added greeting/introduction"
echo ""
echo "⚠️  IMPORTANT: For a custom greeting like 'Welcome to Thanvish Music AI',"
echo "   you need to record an audio file. See HOW_TO_ADD_CUSTOM_AUDIO.md"
echo ""
echo "Current greeting uses available Asterisk sounds (may not be perfect)."
echo "For best results, record custom audio files."
echo ""
echo "Test by calling extension 1002"

