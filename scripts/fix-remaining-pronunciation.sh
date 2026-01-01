#!/bin/bash

# Fix remaining letter-by-letter SayPhonetic issues
# Option 4 and Invalid option handler

set -e

echo "Fixing remaining pronunciation issues..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.remaining.$(date +%Y%m%d_%H%M%S)

# Fix Option 4 - General Music Help
sed -i 's/SayPhonetic(g e n e r a l)/SayPhonetic(general)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(m u s i c)/SayPhonetic(music)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(h e l p)/SayPhonetic(help)/g' /etc/asterisk/extensions.conf

# Fix Invalid option handler
sed -i 's/SayPhonetic(I n v a l i d)/SayPhonetic(invalid)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(o p t i o n)/SayPhonetic(option)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(P l e a s e)/SayPhonetic(please)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(t r y)/SayPhonetic(try)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(a g a i n)/SayPhonetic(again)/g' /etc/asterisk/extensions.conf

# Also fix any remaining letter-by-letter patterns (space-separated letters)
# This catches any we might have missed
sed -i 's/SayPhonetic(\([a-z]\) \([a-z]\) \([a-z]\) \([a-z]\) \([a-z]\) \([a-z]\))/SayPhonetic(\1\2\3\4\5\6)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(\([a-z]\) \([a-z]\) \([a-z]\) \([a-z]\) \([a-z]\))/SayPhonetic(\1\2\3\4\5)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(\([a-z]\) \([a-z]\) \([a-z]\) \([a-z]\))/SayPhonetic(\1\2\3\4)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(\([a-z]\) \([a-z]\) \([a-z]\))/SayPhonetic(\1\2\3)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(\([a-z]\) \([a-z]\))/SayPhonetic(\1\2)/g' /etc/asterisk/extensions.conf

# Reload dialplan
asterisk -rx "dialplan reload"

echo ""
echo "✅ Fixed remaining pronunciation issues!"
echo "  - Option 4: 'general music help' now pronounced naturally"
echo "  - Invalid option: 'invalid option please try again' now pronounced naturally"
echo ""
echo "All SayPhonetic commands now use whole words instead of letter-by-letter spelling."
echo ""
echo "Test by calling extension 1002"

