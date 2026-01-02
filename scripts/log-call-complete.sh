#!/bin/bash
# Log call completion with all details
# Usage: log-call-complete.sh caller_num called_num start_time answer_time end_time duration talk_time recording_path ivr_option

CALLER_NUM="${1:-unknown}"
CALLED_NUM="${2:-unknown}"
START_TIME="${3}"
ANSWER_TIME="${4}"
END_TIME="${5}"
DURATION="${6:-0}"
TALK_TIME="${7:-0}"
RECORDING_PATH="${8}"
IVR_OPTION="${9}"

DB_USER="voip_user"
DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"
DB_NAME="virtual_phone_system"

mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE calls 
SET 
    end_time = FROM_UNIXTIME($END_TIME),
    duration = $DURATION,
    talk_time = $TALK_TIME,
    recording_path = '$RECORDING_PATH',
    ivr_option_selected = '$IVR_OPTION',
    call_status = 'answered'
WHERE 
    caller_id_number = '$CALLER_NUM'
    AND called_number = '$CALLED_NUM'
    AND start_time = FROM_UNIXTIME($START_TIME)
ORDER BY call_id DESC
LIMIT 1;

UPDATE callers 
SET 
    last_call_date = FROM_UNIXTIME($END_TIME),
    total_calls = total_calls + 1
WHERE phone_number = '$CALLER_NUM';

INSERT INTO callers (phone_number, first_call_date, last_call_date, total_calls)
SELECT '$CALLER_NUM', FROM_UNIXTIME($START_TIME), FROM_UNIXTIME($END_TIME), 1
WHERE NOT EXISTS (SELECT 1 FROM callers WHERE phone_number = '$CALLER_NUM');
EOF

exit 0

