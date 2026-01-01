#!/bin/bash

# Create a simpler, more natural-sounding IVR
# Uses SayAlpha for spelling acronyms, SayPhonetic for words

set -e

echo "Creating simpler, more natural IVR pronunciation..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.simple.$(date +%Y%m%d_%H%M%S)

# Use Python to replace the menu section with better pronunciation
python3 << 'PYEOF'
import re

with open('/etc/asterisk/extensions.conf', 'r') as f:
    lines = f.readlines()

# Find the thanvish-menu section
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

# Create simpler menu with better pronunciation
new_menu = """exten => thanvish-menu,1,NoOp(Thanvish Music AI - Main Menu)
exten => thanvish-menu,n,SayPhonetic(Hi)
exten => thanvish-menu,n,SayPhonetic(this)
exten => thanvish-menu,n,SayPhonetic(is)
exten => thanvish-menu,n,SayAlpha(T H A N V I S H)
exten => thanvish-menu,n,SayAlpha(M U S I C)
exten => thanvish-menu,n,SayAlpha(A I)
exten => thanvish-menu,n,Wait(1)
exten => thanvish-menu,n,SayPhonetic(Press)
exten => thanvish-menu,n,SayNumber(1)
exten => thanvish-menu,n,SayPhonetic(for)
exten => thanvish-menu,n,SayPhonetic(music)
exten => thanvish-menu,n,SayPhonetic(ragas)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayPhonetic(Press)
exten => thanvish-menu,n,SayNumber(2)
exten => thanvish-menu,n,SayPhonetic(for)
exten => thanvish-menu,n,SayPhonetic(thala)
exten => thanvish-menu,n,SayPhonetic(rhythms)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayPhonetic(Press)
exten => thanvish-menu,n,SayNumber(3)
exten => thanvish-menu,n,SayPhonetic(for)
exten => thanvish-menu,n,SayPhonetic(drums)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayPhonetic(Press)
exten => thanvish-menu,n,SayNumber(4)
exten => thanvish-menu,n,SayPhonetic(for)
exten => thanvish-menu,n,SayPhonetic(general)
exten => thanvish-menu,n,SayPhonetic(music)
exten => thanvish-menu,n,SayPhonetic(help)
exten => thanvish-menu,n,WaitExten(15)
exten => thanvish-menu,n,NoOp(Timeout - repeating menu once)
exten => thanvish-menu,n,Goto(internal,thanvish-menu-repeat,1,1)

"""

# Find end of menu (before thanvish-menu-repeat)
for i in range(start_idx, len(lines)):
    if 'thanvish-menu-repeat' in lines[i]:
        end_idx = i
        break

if end_idx is None:
    print("ERROR: Could not find end of menu section")
    exit(1)

# Replace
new_lines = lines[:start_idx] + new_menu.split('\n') + lines[end_idx:]

with open('/etc/asterisk/extensions.conf', 'w') as f:
    f.writelines([l + '\n' if not l.endswith('\n') and l else l for l in new_lines])

print(f"✅ Replaced menu section (lines {start_idx+1} to {end_idx})")
PYEOF

# Also fix the repeat menu
python3 << 'PYEOF'
import re

with open('/etc/asterisk/extensions.conf', 'r') as f:
    lines = f.readlines()

# Find thanvish-menu-repeat section
start_idx = None
end_idx = None

for i, line in enumerate(lines):
    if 'thanvish-menu-repeat,1,' in line:
        start_idx = i
    if start_idx and i > start_idx and ('exten => 1,1,' in line or 'exten => thanvish-hangup' in line):
        end_idx = i
        break

if start_idx is None:
    print("ERROR: Could not find thanvish-menu-repeat section")
    exit(1)

# Create simpler repeat menu
new_repeat = """exten => thanvish-menu-repeat,1,NoOp(Repeating menu after timeout)
exten => thanvish-menu-repeat,n,SayPhonetic(Press)
exten => thanvish-menu-repeat,n,SayNumber(1)
exten => thanvish-menu-repeat,n,SayPhonetic(for)
exten => thanvish-menu-repeat,n,SayPhonetic(ragas)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayPhonetic(Press)
exten => thanvish-menu-repeat,n,SayNumber(2)
exten => thanvish-menu-repeat,n,SayPhonetic(for)
exten => thanvish-menu-repeat,n,SayPhonetic(thala)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayPhonetic(Press)
exten => thanvish-menu-repeat,n,SayNumber(3)
exten => thanvish-menu-repeat,n,SayPhonetic(for)
exten => thanvish-menu-repeat,n,SayPhonetic(drums)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayPhonetic(Press)
exten => thanvish-menu-repeat,n,SayNumber(4)
exten => thanvish-menu-repeat,n,SayPhonetic(for)
exten => thanvish-menu-repeat,n,SayPhonetic(help)
exten => thanvish-menu-repeat,n,WaitExten(15)
exten => thanvish-menu-repeat,n,NoOp(Second timeout - ending call)
exten => thanvish-menu-repeat,n,Goto(internal,thanvish-hangup,1,1)

"""

# Replace
new_lines = lines[:start_idx] + new_repeat.split('\n') + lines[end_idx:]

with open('/etc/asterisk/extensions.conf', 'w') as f:
    f.writelines([l + '\n' if not l.endswith('\n') and l else l for l in new_lines])

print(f"✅ Replaced repeat menu section")
PYEOF

# Fix option responses to be simpler
sed -i 's/SayPhonetic(Y o u)/SayPhonetic(you)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(s e l e c t e d)/SayPhonetic(selected)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(M U S I C)/SayPhonetic(music)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(R A G A S)/SayPhonetic(ragas)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(T H A L A)/SayPhonetic(thala)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(R H Y T H M S)/SayPhonetic(rhythms)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(D R U M S)/SayPhonetic(drums)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(I n f o r m a t i o n)/SayPhonetic(information)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(w i l l)/SayPhonetic(will)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(b e)/SayPhonetic(be)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(a v a i l a b l e)/SayPhonetic(available)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(s o o n)/SayPhonetic(soon)/g' /etc/asterisk/extensions.conf

# Reload
asterisk -rx "dialplan reload"

echo ""
echo "✅ Pronunciation fixed!"
echo "  - SayAlpha for acronyms (THANVISH, MUSIC, AI)"
echo "  - SayPhonetic for whole words (this, is, press, for, music, ragas, etc.)"
echo ""
echo "Test by calling extension 1002"

