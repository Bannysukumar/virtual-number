#!/bin/bash

# Script to update extension 1002 with Thanvish Music AI IVR flow
# Preserves all existing fixes (recording, logging, etc.)

set -e

echo "=========================================="
echo "Updating Extension 1002 - Thanvish Music AI IVR"
echo "=========================================="

# Backup current config
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.thanvish.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Use Python to replace extension 1002 section
python3 << 'PYEOF'
import re

# Read current extensions.conf
with open('/etc/asterisk/extensions.conf', 'r') as f:
    lines = f.readlines()

# Find start and end of extension 1002 section
start_idx = None
end_idx = None

for i, line in enumerate(lines):
    # Find start of extension 1002 (look for comment or exten line)
    if start_idx is None and ('Extension 1002' in line or (line.strip().startswith('exten => 1002,1') and 'IVR' in line)):
        start_idx = i
    # Find end (next extension or context)
    if start_idx is not None and i > start_idx:
        if line.strip().startswith('; Extension 1003') or (line.strip().startswith('exten => 1003,1')):
            end_idx = i
            break
        # Also stop at next context
        if line.strip().startswith('[') and 'internal' not in line.lower():
            end_idx = i
            break

if start_idx is None:
    print("ERROR: Could not find extension 1002 section")
    exit(1)

if end_idx is None:
    # If no end found, use end of file
    end_idx = len(lines)

print(f"Found extension 1002 section: lines {start_idx+1} to {end_idx}")

# Read the new IVR dialplan
new_ivr = """; Extension 1002 - Thanvish Music AI IVR Flow
exten => 1002,1,NoOp(Call to extension 1002 - Thanvish Music AI IVR from ${CALLERID(num)})
exten => 1002,n,Set(CALL_START=${EPOCH})
exten => 1002,n,Set(CALLER_NUM=${CALLERID(num)})
exten => 1002,n,Set(CALLED_NUM=${EXTEN})
exten => 1002,n,Answer()
exten => 1002,n,Set(ANSWER_TIME=${EPOCH})
exten => 1002,n,Wait(1)
exten => 1002,n,Set(RECORDING_DIR=/var/recordings/calls)
exten => 1002,n,System(mkdir -p ${RECORDING_DIR})
exten => 1002,n,Set(RECORDING_FILE=${STRFTIME(${EPOCH},,%Y%m%d_%H%M%S)}_${CALLER_NUM}_${EXTEN})
exten => 1002,n,MixMonitor(${RECORDING_DIR}/${RECORDING_FILE}.wav)
exten => 1002,n,NoOp(Recording started: ${RECORDING_FILE}.wav)
exten => 1002,n,Goto(internal,thanvish-menu,1,1)

; Thanvish Music AI - Main Menu
exten => thanvish-menu,1,NoOp(Thanvish Music AI - Main Menu)
exten => thanvish-menu,n,SayPhonetic(H I)
exten => thanvish-menu,n,SayPhonetic(t h i s)
exten => thanvish-menu,n,SayPhonetic(i s)
exten => thanvish-menu,n,SayPhonetic(T H A N V I S H)
exten => thanvish-menu,n,SayPhonetic(M U S I C)
exten => thanvish-menu,n,SayPhonetic(A I)
exten => thanvish-menu,n,Wait(1)
exten => thanvish-menu,n,SayPhonetic(Press)
exten => thanvish-menu,n,SayNumber(1)
exten => thanvish-menu,n,SayPhonetic(f o r)
exten => thanvish-menu,n,SayPhonetic(M U S I C)
exten => thanvish-menu,n,SayPhonetic(R A G A S)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayPhonetic(Press)
exten => thanvish-menu,n,SayNumber(2)
exten => thanvish-menu,n,SayPhonetic(f o r)
exten => thanvish-menu,n,SayPhonetic(T H A L A)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayPhonetic(Press)
exten => thanvish-menu,n,SayNumber(3)
exten => thanvish-menu,n,SayPhonetic(f o r)
exten => thanvish-menu,n,SayPhonetic(D R U M S)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,SayPhonetic(Press)
exten => thanvish-menu,n,SayNumber(4)
exten => thanvish-menu,n,SayPhonetic(f o r)
exten => thanvish-menu,n,SayPhonetic(h e l p)
exten => thanvish-menu,n,WaitExten(15)
exten => thanvish-menu,n,NoOp(Timeout - repeating menu once)
exten => thanvish-menu,n,Goto(internal,thanvish-menu-repeat,1,1)

; Repeat Menu (after timeout)
exten => thanvish-menu-repeat,1,NoOp(Repeating menu after timeout)
exten => thanvish-menu-repeat,n,SayPhonetic(Press)
exten => thanvish-menu-repeat,n,SayNumber(1)
exten => thanvish-menu-repeat,n,SayPhonetic(f o r)
exten => thanvish-menu-repeat,n,SayPhonetic(R A G A S)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayPhonetic(Press)
exten => thanvish-menu-repeat,n,SayNumber(2)
exten => thanvish-menu-repeat,n,SayPhonetic(f o r)
exten => thanvish-menu-repeat,n,SayPhonetic(T H A L A)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayPhonetic(Press)
exten => thanvish-menu-repeat,n,SayNumber(3)
exten => thanvish-menu-repeat,n,SayPhonetic(f o r)
exten => thanvish-menu-repeat,n,SayPhonetic(D R U M S)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,SayPhonetic(Press)
exten => thanvish-menu-repeat,n,SayNumber(4)
exten => thanvish-menu-repeat,n,SayPhonetic(f o r)
exten => thanvish-menu-repeat,n,SayPhonetic(h e l p)
exten => thanvish-menu-repeat,n,WaitExten(15)
exten => thanvish-menu-repeat,n,NoOp(Second timeout - ending call)
exten => thanvish-menu-repeat,n,Goto(internal,thanvish-hangup,1,1)

; Option 1 - Music Ragas
exten => 1,1,NoOp(Option 1 selected - Music Ragas)
exten => 1,n,SayPhonetic(Y o u)
exten => 1,n,SayPhonetic(s e l e c t e d)
exten => 1,n,SayPhonetic(M U S I C)
exten => 1,n,SayPhonetic(R A G A S)
exten => 1,n,Wait(1)
exten => 1,n,SayPhonetic(I n f o r m a t i o n)
exten => 1,n,SayPhonetic(w i l l)
exten => 1,n,SayPhonetic(b e)
exten => 1,n,SayPhonetic(a v a i l a b l e)
exten => 1,n,SayPhonetic(s o o n)
exten => 1,n,Wait(1)
exten => 1,n,Goto(internal,thanvish-menu,1,1)

; Option 2 - Thala (Rhythms)
exten => 2,1,NoOp(Option 2 selected - Thala Rhythms)
exten => 2,n,SayPhonetic(Y o u)
exten => 2,n,SayPhonetic(s e l e c t e d)
exten => 2,n,SayPhonetic(T H A L A)
exten => 2,n,SayPhonetic(R H Y T H M S)
exten => 2,n,Wait(1)
exten => 2,n,SayPhonetic(I n f o r m a t i o n)
exten => 2,n,SayPhonetic(w i l l)
exten => 2,n,SayPhonetic(b e)
exten => 2,n,SayPhonetic(a v a i l a b l e)
exten => 2,n,SayPhonetic(s o o n)
exten => 2,n,Wait(1)
exten => 2,n,Goto(internal,thanvish-menu,1,1)

; Option 3 - Drums
exten => 3,1,NoOp(Option 3 selected - Drums)
exten => 3,n,SayPhonetic(Y o u)
exten => 3,n,SayPhonetic(s e l e c t e d)
exten => 3,n,SayPhonetic(D R U M S)
exten => 3,n,Wait(1)
exten => 3,n,SayPhonetic(I n f o r m a t i o n)
exten => 3,n,SayPhonetic(w i l l)
exten => 3,n,SayPhonetic(b e)
exten => 3,n,SayPhonetic(a v a i l a b l e)
exten => 3,n,SayPhonetic(s o o n)
exten => 3,n,Wait(1)
exten => 3,n,Goto(internal,thanvish-menu,1,1)

; Option 4 - General Music Help
exten => 4,1,NoOp(Option 4 selected - General Music Help)
exten => 4,n,SayPhonetic(Y o u)
exten => 4,n,SayPhonetic(s e l e c t e d)
exten => 4,n,SayPhonetic(g e n e r a l)
exten => 4,n,SayPhonetic(m u s i c)
exten => 4,n,SayPhonetic(h e l p)
exten => 4,n,Wait(1)
exten => 4,n,SayPhonetic(I n f o r m a t i o n)
exten => 4,n,SayPhonetic(w i l l)
exten => 4,n,SayPhonetic(b e)
exten => 4,n,SayPhonetic(a v a i l a b l e)
exten => 4,n,SayPhonetic(s o o n)
exten => 4,n,Wait(1)
exten => 4,n,Goto(internal,thanvish-menu,1,1)

; Invalid Option Handler
exten => i,1,NoOp(Invalid option selected)
exten => i,n,SayPhonetic(I n v a l i d)
exten => i,n,SayPhonetic(o p t i o n)
exten => i,n,SayPhonetic(P l e a s e)
exten => i,n,SayPhonetic(t r y)
exten => i,n,SayPhonetic(a g a i n)
exten => i,n,Wait(1)
exten => i,n,Goto(internal,thanvish-menu,1,1)

; Hangup Handler - Log call to database
exten => thanvish-hangup,1,NoOp(Call ending - logging to database)
exten => thanvish-hangup,n,Set(CALL_END=${EPOCH})
exten => thanvish-hangup,n,Set(CALL_DURATION=$[${CALL_END} - ${CALL_START}])
exten => thanvish-hangup,n,Set(TALK_TIME=$[${CALL_END} - ${ANSWER_TIME}])
exten => thanvish-hangup,n,System(/usr/local/bin/log-call.sh "${CALLER_NUM}" "${CALLED_NUM}" "${CALL_START}" "${ANSWER_TIME}" "${CALL_END}" "${CALL_DURATION}" "${TALK_TIME}" "${RECORDING_DIR}/${RECORDING_FILE}.wav" "thanvish_music_ai_ivr")
exten => thanvish-hangup,n,Hangup()

"""

# Split into lines
new_lines = new_ivr.split('\n')
# Add newline to each line
new_lines = [l + '\n' for l in new_lines if l.strip()]

# Replace the section
new_file = lines[:start_idx] + new_lines + lines[end_idx:]

# Write back
with open('/etc/asterisk/extensions.conf', 'w') as f:
    f.writelines(new_file)

print(f"✅ Replaced extension 1002 section (lines {start_idx+1} to {end_idx})")
print(f"✅ New section has {len(new_lines)} lines")
PYEOF

# Reload dialplan
asterisk -rx "dialplan reload"

echo ""
echo "=========================================="
echo "✅ Extension 1002 updated successfully!"
echo "=========================================="
echo ""
echo "Features:"
echo "  - Auto-answer calls"
echo "  - Greeting: 'Hi, this is Thanvish Music AI'"
echo "  - Menu options: 1=Music Ragas, 2=Thala Rhythms, 3=Drums, 4=General Help"
echo "  - Menu repeats once on timeout"
echo "  - Call recording starts immediately"
echo "  - All calls logged to database"
echo ""
echo "Test by calling extension 1002"

