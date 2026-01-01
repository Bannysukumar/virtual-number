#!/bin/bash

# Update dialplan for Human Voice IVR
# Natural, friendly female voice with specific greeting and menu

set -e

echo "Updating dialplan for Human Voice IVR..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.human-voice.$(date +%Y%m%d_%H%M%S)

python3 << 'PYEOF'
import re

with open('/etc/asterisk/extensions.conf', 'r') as f:
    content = f.read()

# New Human Voice IVR Menu
new_menu = """exten => thanvish-menu,1,NoOp(Thanvish Music AI - Human Voice IVR)
exten => thanvish-menu,n,Playback(en/custom/greeting)
exten => thanvish-menu,n,Wait(1)
exten => thanvish-menu,n,Playback(en/custom/menu-1)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,Playback(en/custom/menu-2)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,Playback(en/custom/menu-3)
exten => thanvish-menu,n,Wait(0.8)
exten => thanvish-menu,n,Playback(en/custom/menu-4)
exten => thanvish-menu,n,WaitExten(15)
exten => thanvish-menu,n,NoOp(Timeout - repeating menu once)
exten => thanvish-menu,n,Goto(internal,thanvish-menu-repeat,1,1)

"""

# Repeat Menu (after timeout)
new_repeat = """exten => thanvish-menu-repeat,1,NoOp(Repeating menu after timeout)
exten => thanvish-menu-repeat,n,Playback(en/custom/menu-1)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,Playback(en/custom/menu-2)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,Playback(en/custom/menu-3)
exten => thanvish-menu-repeat,n,Wait(0.8)
exten => thanvish-menu-repeat,n,Playback(en/custom/menu-4)
exten => thanvish-menu-repeat,n,WaitExten(15)
exten => thanvish-menu-repeat,n,NoOp(Second timeout - ending call)
exten => thanvish-menu-repeat,n,Goto(internal,thanvish-hangup,1,1)

"""

# Option handlers with natural responses
option_1 = """exten => 1,1,NoOp(Option 1 selected - Music Ragas)
exten => 1,n,Playback(en/custom/option-1)
exten => 1,n,Wait(2)
exten => 1,n,Goto(internal,thanvish-menu,1,1)

"""

option_2 = """exten => 2,1,NoOp(Option 2 selected - Thala Rhythms)
exten => 2,n,Playback(en/custom/option-2)
exten => 2,n,Wait(2)
exten => 2,n,Goto(internal,thanvish-menu,1,1)

"""

option_3 = """exten => 3,1,NoOp(Option 3 selected - Drums)
exten => 3,n,Playback(en/custom/option-3)
exten => 3,n,Wait(2)
exten => 3,n,Goto(internal,thanvish-menu,1,1)

"""

option_4 = """exten => 4,1,NoOp(Option 4 selected - General Music Help)
exten => 4,n,Playback(en/custom/option-4)
exten => 4,n,Wait(2)
exten => 4,n,Goto(internal,thanvish-menu,1,1)

"""

invalid_option = """exten => i,1,NoOp(Invalid option selected)
exten => i,n,Playback(en/custom/invalid)
exten => i,n,Wait(1)
exten => i,n,Goto(internal,thanvish-menu,1,1)

"""

# Find and replace thanvish-menu
pattern = r'exten => thanvish-menu,1,NoOp\(Thanvish Music AI.*?exten => thanvish-menu,n,Goto\(internal,thanvish-menu-repeat,1,1\)'
content = re.sub(pattern, new_menu.strip(), content, flags=re.DOTALL)

# Find and replace repeat menu
pattern_repeat = r'exten => thanvish-menu-repeat,1,NoOp\(.*?exten => thanvish-menu-repeat,n,Goto\(internal,thanvish-hangup,1,1\)'
content = re.sub(pattern_repeat, new_repeat.strip(), content, flags=re.DOTALL)

# Replace option handlers
content = re.sub(
    r'exten => 1,1,NoOp\(Option 1.*?exten => 1,n,Goto\(internal,thanvish-menu,1,1\)',
    option_1.strip(),
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'exten => 2,1,NoOp\(Option 2.*?exten => 2,n,Goto\(internal,thanvish-menu,1,1\)',
    option_2.strip(),
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'exten => 3,1,NoOp\(Option 3.*?exten => 3,n,Goto\(internal,thanvish-menu,1,1\)',
    option_3.strip(),
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'exten => 4,1,NoOp\(Option 4.*?exten => 4,n,Goto\(internal,thanvish-menu,1,1\)',
    option_4.strip(),
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'exten => i,1,NoOp\(Invalid option.*?exten => i,n,Goto\(internal,thanvish-menu,1,1\)',
    invalid_option.strip(),
    content,
    flags=re.DOTALL
)

with open('/etc/asterisk/extensions.conf', 'w') as f:
    f.write(content)

print("✅ Updated dialplan for Human Voice IVR")
PYEOF

# Reload dialplan
asterisk -rx "dialplan reload"

echo ""
echo "✅ Dialplan updated!"
echo ""
echo "The IVR now uses:"
echo "  - Natural greeting: 'Hi, this is Thanvish Music AI. How can I help you today?'"
echo "  - Natural menu flow with human-like voice"
echo "  - Option responses with confirmation"
echo ""
echo "Test by calling extension 1002"

