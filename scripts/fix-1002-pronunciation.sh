#!/bin/bash

# Fix pronunciation issues in extension 1002
# Replace SayPhonetic letter-by-letter with SayAlpha and better phrasing

set -e

echo "Fixing pronunciation in extension 1002..."

# Backup
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.pronunciation.$(date +%Y%m%d_%H%M%S)

# Fix the greeting - use SayAlpha for spelling and simpler phrases
sed -i '/thanvish-menu,1,/,/thanvish-menu,n,Wait(1)/ {
    s/SayPhonetic(H I)/SayAlpha(H I)/g
    s/SayPhonetic(t h i s)/SayPhonetic(this)/g
    s/SayPhonetic(i s)/SayPhonetic(is)/g
    s/SayPhonetic(T H A N V I S H)/SayAlpha(T H A N V I S H)/g
    s/SayPhonetic(M U S I C)/SayAlpha(M U S I C)/g
    s/SayPhonetic(A I)/SayAlpha(A I)/g
}' /etc/asterisk/extensions.conf

# Fix menu options - simplify phrases
sed -i 's/SayPhonetic(Press)/SayPhonetic(press)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(f o r)/SayPhonetic(for)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(M U S I C)/SayAlpha(M U S I C)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(R A G A S)/SayAlpha(R A G A S)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(T H A L A)/SayAlpha(T H A L A)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(R H Y T H M S)/SayAlpha(R H Y T H M S)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(D R U M S)/SayAlpha(D R U M S)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(g e n e r a l)/SayPhonetic(general)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(m u s i c)/SayAlpha(M U S I C)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(h e l p)/SayPhonetic(help)/g' /etc/asterisk/extensions.conf

# Fix option responses
sed -i 's/SayPhonetic(Y o u)/SayPhonetic(you)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(s e l e c t e d)/SayPhonetic(selected)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(I n f o r m a t i o n)/SayPhonetic(information)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(w i l l)/SayPhonetic(will)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(b e)/SayPhonetic(be)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(a v a i l a b l e)/SayPhonetic(available)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(s o o n)/SayPhonetic(soon)/g' /etc/asterisk/extensions.conf

# Fix invalid option handler
sed -i 's/SayPhonetic(I n v a l i d)/SayPhonetic(invalid)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(o p t i o n)/SayPhonetic(option)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(P l e a s e)/SayPhonetic(please)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(t r y)/SayPhonetic(try)/g' /etc/asterisk/extensions.conf
sed -i 's/SayPhonetic(a g a i n)/SayPhonetic(again)/g' /etc/asterisk/extensions.conf

# Reload
asterisk -rx "dialplan reload"

echo "✅ Pronunciation fixes applied!"
echo "Test by calling extension 1002"

