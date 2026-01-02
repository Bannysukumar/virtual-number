#!/bin/bash
# Trigger SIP callback using Asterisk AMI
# Usage: trigger-callback.sh <phone_number> [callback_id]

PHONE_NUMBER="$1"
CALLBACK_ID="${2:-}"
EXTENSION="1002"  # IVR extension
CONTEXT="outbound-callback"

if [ -z "$PHONE_NUMBER" ]; then
    echo "Error: Phone number required"
    exit 1
fi

# Normalize phone number (remove + for Asterisk dialing)
NORMALIZED_NUMBER=$(echo "$PHONE_NUMBER" | sed 's/^+//')

echo "Triggering callback to: $NORMALIZED_NUMBER"

# Method 1: Use Asterisk CLI originate command
# The dialplan has two options:
# 1. Extension 's' expects CALLER_NUM variable
# 2. Extension _X. uses the number directly as extension

# Use the phone number as extension (matches _X. pattern in dialplan)
asterisk -rx "channel originate Local/${NORMALIZED_NUMBER}@${CONTEXT} application Wait 1" > /dev/null 2>&1

# Alternative: Use extension 's' with variables (if above doesn't work)
# Note: Asterisk CLI doesn't support setting variables directly in originate
# We need to use AMI or set variables in the dialplan

# Alternative: Use AMI (Asterisk Manager Interface) if configured
# This requires AMI authentication - uncomment if AMI is set up
# echo "Action: Originate
# Channel: Local/${EXTENSION}@${CONTEXT}
# Context: ${CONTEXT}
# Exten: s
# Priority: 1
# Variable: CALLER_NUM=${NORMALIZED_NUMBER}
# Variable: CALLBACK_ID=${CALLBACK_ID}
# CallerID: ${NORMALIZED_NUMBER}
# " | nc localhost 5038

# Alternative: Use AMI (Asterisk Manager Interface) if configured
# This requires AMI authentication - uncomment if AMI is set up
# echo "Action: Originate
# Channel: Local/${EXTENSION}@${CONTEXT}
# Context: ${CONTEXT}
# Exten: s
# Priority: 1
# Variable: CALLER_NUM=${NORMALIZED_NUMBER}
# Variable: CALLBACK_ID=${CALLBACK_ID}
# CallerID: ${NORMALIZED_NUMBER}
# " | nc localhost 5038

# Alternative Method 2: Use AMI directly (if AMI is configured)
# This requires ami_client or curl to AMI port
# For now, using CLI method

# Log the callback attempt
echo "$(date '+%Y-%m-%d %H:%M:%S') - Callback triggered to $PHONE_NUMBER (ID: $CALLBACK_ID)" >> /var/log/asterisk/callback.log

exit 0
