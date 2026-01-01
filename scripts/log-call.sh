#!/bin/bash

# Log call to database
# Usage: log-call.sh caller_num called_num start_time answer_time end_time duration talk_time recording_path flow_type

CALLER_NUM="${1:-unknown}"
CALLED_NUM="${2:-unknown}"
START_TIME="${3}"
ANSWER_TIME="${4}"
END_TIME="${5}"
DURATION="${6:-0}"
TALK_TIME="${7:-0}"
RECORDING_PATH="${8}"
FLOW_TYPE="${9:-ivr}"

# Database credentials
DB_USER="voip_user"
DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"
DB_NAME="virtual_phone_system"

# Convert epoch to MySQL datetime
START_DT=$(date -d "@${START_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "${START_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$(date '+%Y-%m-%d %H:%M:%S')")
ANSWER_DT=$(date -d "@${ANSWER_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "${ANSWER_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$START_DT")
END_DT=$(date -d "@${END_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r "${END_TIME}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$(date '+%Y-%m-%d %H:%M:%S')")

# Determine call status
if [ "$TALK_TIME" -gt 0 ]; then
    CALL_STATUS="answered"
else
    CALL_STATUS="no-answer"
fi

# Insert call record
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO calls (
    caller_id_number,
    called_number,
    direction,
    call_status,
    start_time,
    answer_time,
    end_time,
    duration,
    talk_time,
    recording_path,
    flow_type
) VALUES (
    '$CALLER_NUM',
    '$CALLED_NUM',
    'incoming',
    '$CALL_STATUS',
    '$START_DT',
    '$ANSWER_DT',
    '$END_DT',
    $DURATION,
    $TALK_TIME,
    ${RECORDING_PATH:+'$RECORDING_PATH'},
    '$FLOW_TYPE'
);

UPDATE callers 
SET 
    last_call_date = '$END_DT',
    total_calls = total_calls + 1
WHERE phone_number = '$CALLER_NUM';

INSERT INTO callers (phone_number, first_call_date, last_call_date, total_calls)
SELECT '$CALLER_NUM', '$END_DT', '$END_DT', 1
WHERE NOT EXISTS (SELECT 1 FROM callers WHERE phone_number = '$CALLER_NUM');
EOF

exit 0

