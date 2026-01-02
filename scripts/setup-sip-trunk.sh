#!/bin/bash
# Setup SIP trunk for outbound calls or configure callback to route to IVR

echo "=========================================="
echo "🔧 Setting Up SIP Trunk for Callbacks"
echo "=========================================="

echo ""
echo "Option 1: Configure callback to route to IVR (for testing)"
echo "Option 2: Create SIP trunk configuration template"
echo ""
read -p "Choose option (1 or 2): " OPTION

if [ "$OPTION" = "1" ]; then
    echo ""
    echo "Modifying dialplan to route callbacks to IVR instead of dialing out..."
    
    # Backup dialplan
    cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Modify the Dial command to route to IVR instead
    sed -i 's|Dial(SIP/${CALLER_NUM}@trunk,30,Tt)|Goto(internal,1002,1)|g' /etc/asterisk/extensions.conf
    
    asterisk -rx "dialplan reload"
    echo "✅ Dialplan updated - callbacks will route to IVR (extension 1002)"
    echo ""
    echo "Test with: /usr/local/bin/trigger-callback.sh +919812345678"
    
elif [ "$OPTION" = "2" ]; then
    echo ""
    echo "Creating SIP trunk configuration template..."
    
    # Check if trunk already exists
    if grep -q "^\[trunk\]" /etc/asterisk/sip.conf; then
        echo "⚠️  Trunk already exists in sip.conf"
        grep -A 15 "^\[trunk\]" /etc/asterisk/sip.conf
    else
        echo ""
        echo "Add this to /etc/asterisk/sip.conf:"
        echo ""
        cat << 'TRUNK_CONFIG'
[trunk]
type=peer
host=your-sip-provider.com
username=your_username
secret=your_password
fromuser=your_username
fromdomain=your-sip-provider.com
canreinvite=no
context=outbound-callback
qualify=yes
nat=force_rport,comedia
disallow=all
allow=ulaw
allow=alaw
allow=gsm
TRUNK_CONFIG
        
        echo ""
        read -p "Do you want to add this template to sip.conf? (y/n) " ADD_TRUNK
        if [ "$ADD_TRUNK" = "y" ]; then
            echo "" >> /etc/asterisk/sip.conf
            echo "; SIP Trunk for outbound callbacks" >> /etc/asterisk/sip.conf
            echo "[trunk]" >> /etc/asterisk/sip.conf
            echo "type=peer" >> /etc/asterisk/sip.conf
            echo "host=your-sip-provider.com" >> /etc/asterisk/sip.conf
            echo "username=your_username" >> /etc/asterisk/sip.conf
            echo "secret=your_password" >> /etc/asterisk/sip.conf
            echo "; Update the above with your SIP provider details" >> /etc/asterisk/sip.conf
            echo "✅ Template added to sip.conf"
            echo "⚠️  IMPORTANT: Update host, username, and secret with your SIP provider details"
            echo "Then reload: asterisk -rx 'sip reload'"
        fi
    fi
else
    echo "Invalid option"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Setup Complete"
echo "=========================================="

