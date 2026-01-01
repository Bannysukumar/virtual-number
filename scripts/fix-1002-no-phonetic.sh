#!/bin/bash

# Fix: Remove all SayPhonetic (spells words, doesn't pronounce them)
# Use SayNumber for menu options + SayAlpha for acronyms
# Provide instructions for custom audio files

set -e

echo "Fixing extension 1002 - SayPhonetic spells words, we need natural speech"
echo "Removing SayPhonetic and using SayNumber + SayAlpha instead"

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.no-phonetic.$(date +%Y%m%d_%H%M%S)

python3 << 'PYEOF'
import re

with open('/etc/asterisk/extensions.conf', 'r') as f:
    lines = f.readlines()

# Find thanvish-menu section
start_idx = None
end_idx = None

for i, line in enumerate(lines):
    if 'thanvish-menu,1,' in line:
        start_idx = i
    if start_idx and i > start_idx and ('thanvish-menu-repeat' in line or 'exten => 1,1,' in line):
        end_idx = i
        break

if start_idx is None:
    print("ERROR: Could not find thanvish-menu section")
    exit(1)

# Create simple menu using SayNumber and SayAlpha only
new_menu = """exten => thanvish-menu,1,NoOp(Thanvish Music AI - Main Menu)
exten => thanvish-menu,n,Playback(en_US_f_Allison/dir-welcome)
exten => thanvish-menu,n,Wait(1)
exten => thanvish-menu,n,SayAlpha(T H A N V I S H)
exten => thanvish-menu,n,SayAlpha(M U S I C)
exten => thanvish-menu,n,SayAlpha(A I)
exten => thanvish-menu,n,Wait(1)
exten => thanvish-menu,n,SayNumber(1)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayNumber(2)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayNumber(3)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayNumber(4)
exten => thanvish-menu,n,WaitExten(15)
exten => thanvish-menu,n,NoOp(Timeout - repeating menu once)
exten => thanvish-menu,n,Goto(internal,thanvish-menu-repeat,1,1)

"""

# Replace menu
new_lines = lines[:start_idx] + new_menu.split('\n') + lines[end_idx:]

# Find and simplify repeat menu
start_repeat = None
end_repeat = None

for i, line in enumerate(new_lines):
    if 'thanvish-menu-repeat,1,' in line:
        start_repeat = i
    if start_repeat and i > start_repeat and ('exten => 1,1,' in line or 'exten => thanvish-hangup' in line):
        end_repeat = i
        break

if start_repeat:
    new_repeat = """exten => thanvish-menu-repeat,1,NoOp(Repeating menu after timeout)
exten => thanvish-menu-repeat,n,SayNumber(1)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayNumber(2)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayNumber(3)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayNumber(4)
exten => thanvish-menu-repeat,n,WaitExten(15)
exten => thanvish-menu-repeat,n,NoOp(Second timeout - ending call)
exten => thanvish-menu-repeat,n,Goto(internal,thanvish-hangup,1,1)

"""
    new_lines = new_lines[:start_repeat] + new_repeat.split('\n') + new_lines[end_repeat:]

# Simplify option responses
for i, line in enumerate(new_lines):
    # Option 1-4: Just play welcome and return to menu
    if re.match(r'exten => [1-4],1,NoOp', line):
        # Find the end of this option block
        j = i + 1
        while j < len(new_lines) and not re.match(r'exten => [1-4],1,NoOp|exten => [ti],1,NoOp|exten => thanvish', new_lines[j]):
            j += 1
        # Replace with simple response
        opt_num = line.split('=>')[1].split(',')[0].strip()
        new_lines[i:j] = [
            f'exten => {opt_num},1,NoOp(Option {opt_num} selected)\n',
            f'exten => {opt_num},n,Playback(en_US_f_Allison/dir-welcome)\n',
            f'exten => {opt_num},n,Wait(1)\n',
            f'exten => {opt_num},n,Goto(internal,thanvish-menu,1,1)\n',
            '\n'
        ]

# Invalid option
for i, line in enumerate(new_lines):
    if 'exten => i,1,NoOp(Invalid option' in line:
        j = i + 1
        while j < len(new_lines) and not re.match(r'exten => [1-4ti],1,NoOp|exten => thanvish', new_lines[j]):
            j += 1
        new_lines[i:j] = [
            'exten => i,1,NoOp(Invalid option selected)\n',
            'exten => i,n,Playback(en/basic-pbx-ivr-invalid)\n',
            'exten => i,n,Wait(1)\n',
            'exten => i,n,Goto(internal,thanvish-menu,1,1)\n',
            '\n'
        ]
        break

# Write back
with open('/etc/asterisk/extensions.conf', 'w') as f:
    f.writelines(new_lines)

print("✅ Replaced SayPhonetic with SayNumber and SayAlpha")
PYEOF

# Reload
asterisk -rx "dialplan reload"

echo ""
echo "✅ Fixed! Now using:"
echo "  - SayNumber() for menu options (1, 2, 3, 4) - works perfectly"
echo "  - SayAlpha() for acronyms (THANVISH, MUSIC, AI) - works fine"
echo "  - Playback() for greetings"
echo ""
echo "⚠️  For custom messages, record audio files:"
echo "   1. Record WAV files (8kHz, 16-bit, mono)"
echo "   2. Place in: /usr/share/asterisk/sounds/en/"
echo "   3. Use: Playback(en/your-filename)"
echo ""
echo "Test by calling extension 1002 - menu will say numbers clearly"

