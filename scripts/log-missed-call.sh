#!/bin/bash

# Script to log missed calls for callback functionality
# Called from Asterisk dialplan

CALLER_ID=$1
EXTENSION=$2
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Database credentials (adjust as needed)
DB_USER="voip_user"
DB_PASS="your_password"
DB_NAME="virtual_phone_system"

# Log missed call
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO calls (
    caller_id_number,
    called_number,
    direction,
    call_status,
    start_time,
    end_time,
    flow_type
) VALUES (
    '$CALLER_ID',
    '$EXTENSION',
    'incoming',
    'missed',
    '$TIMESTAMP',
    '$TIMESTAMP',
    'missed_call_callback'
);

UPDATE callers 
SET 
    last_call_date = '$TIMESTAMP',
    total_calls = total_calls + 1
WHERE phone_number = '$CALLER_ID';

INSERT INTO callers (phone_number, first_call_date, last_call_date, total_calls)
SELECT '$CALLER_ID', '$TIMESTAMP', '$TIMESTAMP', 1
WHERE NOT EXISTS (SELECT 1 FROM callers WHERE phone_number = '$CALLER_ID');
EOF

# Optional: Trigger callback script (uncomment if needed)
# /usr/local/bin/trigger-callback.sh "$CALLER_ID" "$EXTENSION"

exit 0

