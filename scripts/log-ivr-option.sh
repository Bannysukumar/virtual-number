#!/bin/bash
# Log IVR option selection
# Usage: log-ivr-option.sh caller_num option_pressed timestamp

CALLER_NUM="${1}"
OPTION="${2}"
TIMESTAMP="${3:-$(date +%s)}"

DB_USER="voip_user"
DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"
DB_NAME="virtual_phone_system"

# Get the most recent call_id for this caller
CALL_ID=$(mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "
SELECT call_id FROM calls 
WHERE caller_id_number = '$CALLER_NUM' 
AND call_status = 'answered'
ORDER BY call_id DESC LIMIT 1;
")

if [ -n "$CALL_ID" ]; then
    mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO ivr_responses (call_id, menu_level, option_pressed, response_time)
VALUES ($CALL_ID, 1, '$OPTION', FROM_UNIXTIME($TIMESTAMP));

UPDATE calls 
SET ivr_option_selected = '$OPTION'
WHERE call_id = $CALL_ID;
EOF
fi

exit 0

