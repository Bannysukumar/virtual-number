#!/bin/bash

# Add greeting and better menu context to extension 1002
# Uses Playback() for greetings and SayNumber for menu options

set -e

echo "Adding greeting and menu context to extension 1002..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.greeting.$(date +%Y%m%d_%H%M%S)

python3 << 'PYEOF'
import re

with open('/etc/asterisk/extensions.conf', 'r') as f:
    content = f.read()

# Replace the thanvish-menu section with a better version
new_menu = """exten => thanvish-menu,1,NoOp(Thanvish Music AI - Main Menu)
exten => thanvish-menu,n,Playback(en_US_f_Allison/dir-welcome)
exten => thanvish-menu,n,Wait(0.5)
exten => thanvish-menu,n,SayAlpha(T H A N V I S H)
exten => thanvish-menu,n,SayAlpha(M U S I C)
exten => thanvish-menu,n,SayAlpha(A I)
exten => thanvish-menu,n,Wait(1)
exten => thanvish-menu,n,Playback(en/basic-pbx-ivr-main)
exten => thanvish-menu,n,Wait(0.5)
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

# Find and replace thanvish-menu
pattern = r'exten => thanvish-menu,1,NoOp\(Thanvish Music AI - Main Menu\).*?exten => thanvish-menu,n,Goto\(internal,thanvish-menu-repeat,1,1\)'
content = re.sub(pattern, new_menu.strip(), content, flags=re.DOTALL)

# Replace repeat menu
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

pattern_repeat = r'exten => thanvish-menu-repeat,1,NoOp\(Repeating menu after timeout\).*?exten => thanvish-menu-repeat,n,Goto\(internal,thanvish-hangup,1,1\)'
content = re.sub(pattern_repeat, new_repeat.strip(), content, flags=re.DOTALL)

# Fix option handlers to provide feedback
# Option 1
content = re.sub(
    r'exten => 1,1,NoOp\(Option 1 selected - Music Ragas\).*?exten => 1,n,Goto\(internal,thanvish-menu,1,1\)',
    """exten => 1,1,NoOp(Option 1 selected - Music Ragas)
exten => 1,n,Playback(en_US_f_Allison/dir-welcome)
exten => 1,n,Wait(1)
exten => 1,n,Goto(internal,thanvish-menu,1,1)""",
    content,
    flags=re.DOTALL
)

# Option 2
content = re.sub(
    r'exten => 2,1,NoOp\(Option 2 selected - Thala Rhythms\).*?exten => 2,n,Goto\(internal,thanvish-menu,1,1\)',
    """exten => 2,1,NoOp(Option 2 selected - Thala Rhythms)
exten => 2,n,Playback(en_US_f_Allison/dir-welcome)
exten => 2,n,Wait(1)
exten => 2,n,Goto(internal,thanvish-menu,1,1)""",
    content,
    flags=re.DOTALL
)

# Option 3
content = re.sub(
    r'exten => 3,1,NoOp\(Option 3 selected - Drums\).*?exten => 3,n,Goto\(internal,thanvish-menu,1,1\)',
    """exten => 3,1,NoOp(Option 3 selected - Drums)
exten => 3,n,Playback(en_US_f_Allison/dir-welcome)
exten => 3,n,Wait(1)
exten => 3,n,Goto(internal,thanvish-menu,1,1)""",
    content,
    flags=re.DOTALL
)

# Option 4
content = re.sub(
    r'exten => 4,1,NoOp\(Option 4 selected - General Music Help\).*?exten => 4,n,Goto\(internal,thanvish-menu,1,1\)',
    """exten => 4,1,NoOp(Option 4 selected - General Music Help)
exten => 4,n,Playback(en_US_f_Allison/dir-welcome)
exten => 4,n,Wait(1)
exten => 4,n,Goto(internal,thanvish-menu,1,1)""",
    content,
    flags=re.DOTALL
)

# Invalid option
content = re.sub(
    r'exten => i,1,NoOp\(Invalid option selected\).*?exten => i,n,Goto\(internal,thanvish-menu,1,1\)',
    """exten => i,1,NoOp(Invalid option selected)
exten => i,n,Playback(en/basic-pbx-ivr-invalid)
exten => i,n,Wait(1)
exten => i,n,Goto(internal,thanvish-menu,1,1)""",
    content,
    flags=re.DOTALL
)

# Remove duplicate Goto line if exists
content = re.sub(r'exten => thanvish-menu,n,Goto\(internal,thanvish-menu-repeat,1,1\)\n\s*exten => thanvish-menu,n,Goto\(internal,thanvish-menu-repeat,1,1\)', 
                 'exten => thanvish-menu,n,Goto(internal,thanvish-menu-repeat,1,1)', content)

with open('/etc/asterisk/extensions.conf', 'w') as f:
    f.write(content)

print("✅ Added greeting and improved menu")
PYEOF

# Reload
asterisk -rx "dialplan reload"

echo ""
echo "✅ Updated IVR with:"
echo "  - Greeting: Playback(welcome)"
echo "  - Acronyms: SayAlpha(THANVISH MUSIC AI)"
echo "  - Menu: Playback(main-menu) + SayNumber(1,2,3,4)"
echo "  - Option feedback: Playback(welcome) when selected"
echo ""
echo "⚠️  Note: For custom messages like 'Press 1 for Music Ragas',"
echo "   you need to record audio files. See instructions below."
echo ""
echo "Test by calling extension 1002"

