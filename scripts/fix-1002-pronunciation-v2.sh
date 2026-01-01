#!/bin/bash

# Fix pronunciation - use SayAlpha for spelling, SayPhonetic for words
# SayPhonetic with spaces spells letter-by-letter (wrong)
# SayAlpha spells letters (correct for acronyms)
# SayPhonetic without spaces pronounces words (correct)

set -e

echo "Fixing pronunciation in extension 1002..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.pronunciation.$(date +%Y%m%d_%H%M%S)

# Replace the entire greeting section with better pronunciation
python3 << 'PYEOF'
import re

with open('/etc/asterisk/extensions.conf', 'r') as f:
    content = f.read()

# Fix greeting - use SayAlpha for spelling acronyms, SayPhonetic for words
replacements = [
    # Greeting fixes
    (r'SayPhonetic\(H I\)', 'SayAlpha(H I)'),
    (r'SayPhonetic\(t h i s\)', 'SayPhonetic(this)'),
    (r'SayPhonetic\(i s\)', 'SayPhonetic(is)'),
    (r'SayPhonetic\(T H A N V I S H\)', 'SayAlpha(T H A N V I S H)'),
    (r'SayPhonetic\(M U S I C\)', 'SayAlpha(M U S I C)'),
    (r'SayPhonetic\(A I\)', 'SayAlpha(A I)'),
    
    # Menu option fixes
    (r'SayPhonetic\(Press\)', 'SayPhonetic(press)'),
    (r'SayPhonetic\(f o r\)', 'SayPhonetic(for)'),
    (r'SayPhonetic\(M U S I C\)', 'SayAlpha(M U S I C)'),
    (r'SayPhonetic\(R A G A S\)', 'SayAlpha(R A G A S)'),
    (r'SayPhonetic\(T H A L A\)', 'SayAlpha(T H A L A)'),
    (r'SayPhonetic\(R H Y T H M S\)', 'SayAlpha(R H Y T H M S)'),
    (r'SayPhonetic\(D R U M S\)', 'SayAlpha(D R U M S)'),
    (r'SayPhonetic\(g e n e r a l\)', 'SayPhonetic(general)'),
    (r'SayPhonetic\(m u s i c\)', 'SayAlpha(M U S I C)'),
    (r'SayPhonetic\(h e l p\)', 'SayPhonetic(help)'),
    
    # Option response fixes
    (r'SayPhonetic\(Y o u\)', 'SayPhonetic(you)'),
    (r'SayPhonetic\(s e l e c t e d\)', 'SayPhonetic(selected)'),
    (r'SayPhonetic\(I n f o r m a t i o n\)', 'SayPhonetic(information)'),
    (r'SayPhonetic\(w i l l\)', 'SayPhonetic(will)'),
    (r'SayPhonetic\(b e\)', 'SayPhonetic(be)'),
    (r'SayPhonetic\(a v a i l a b l e\)', 'SayPhonetic(available)'),
    (r'SayPhonetic\(s o o n\)', 'SayPhonetic(soon)'),
    
    # Invalid option fixes
    (r'SayPhonetic\(I n v a l i d\)', 'SayPhonetic(invalid)'),
    (r'SayPhonetic\(o p t i o n\)', 'SayPhonetic(option)'),
    (r'SayPhonetic\(P l e a s e\)', 'SayPhonetic(please)'),
    (r'SayPhonetic\(t r y\)', 'SayPhonetic(try)'),
    (r'SayPhonetic\(a g a i n\)', 'SayPhonetic(again)'),
]

for pattern, replacement in replacements:
    content = re.sub(pattern, replacement, content)

with open('/etc/asterisk/extensions.conf', 'w') as f:
    f.write(content)

print("✅ Pronunciation fixes applied")
PYEOF

# Reload dialplan
asterisk -rx "dialplan reload"

echo ""
echo "✅ Fixed! Test by calling extension 1002"
echo ""
echo "Changes:"
echo "  - SayAlpha for acronyms (THANVISH, MUSIC, AI, RAGAS, etc.)"
echo "  - SayPhonetic for whole words (this, is, press, for, etc.)"
echo ""

