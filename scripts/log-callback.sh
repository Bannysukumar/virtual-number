#!/bin/bash
# Log callback completion
# Usage: log-callback.sh caller_num called_num start_time answer_time end_time duration talk_time recording_path call_status callback_id

CALLER_NUM="${1:-unknown}"
CALLED_NUM="${2:-unknown}"
START_TIME="${3}"
ANSWER_TIME="${4}"
END_TIME="${5}"
DURATION="${6:-0}"
TALK_TIME="${7:-0}"
RECORDING_PATH="${8}"
CALL_STATUS="${9:-failed}"
CALLBACK_ID="${10}"

DB_USER="voip_user"
DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"
DB_NAME="virtual_phone_system"

# Get call_id from calls table
CALL_ID=$(mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "
SELECT call_id FROM calls 
WHERE caller_id_number = '$CALLER_NUM' 
AND start_time = FROM_UNIXTIME($START_TIME)
ORDER BY call_id DESC LIMIT 1;
")

# Update callback status
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE missed_call_callbacks 
SET 
    callback_status = '$CALL_STATUS',
    call_id = ${CALL_ID:-NULL},
    answer_time = ${ANSWER_TIME:+FROM_UNIXTIME($ANSWER_TIME)},
    duration = $DURATION,
    updated_at = NOW()
WHERE callback_id = ${CALLBACK_ID:-NULL}
   OR (caller_number = '$CALLER_NUM' AND callback_status = 'initiated')
ORDER BY callback_id DESC
LIMIT 1;
EOF

exit 0

