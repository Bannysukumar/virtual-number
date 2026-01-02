#!/bin/bash
# Log call when answered (not on hangup)
# Usage: log-call-answered.sh caller_num called_num start_time answer_time

CALLER_NUM="${1:-unknown}"
CALLED_NUM="${2:-unknown}"
START_TIME="${3:-$(date +%s)}"
ANSWER_TIME="${4:-$(date +%s)}"

DB_USER="voip_user"
DB_PASS="4XpeVl8flQpMZ0NAfkfDzTUyu"
DB_NAME="virtual_phone_system"

# Insert call record immediately when answered
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
INSERT INTO calls (
    caller_id_number,
    called_number,
    direction,
    call_status,
    start_time,
    answer_time,
    early_media_sent
) VALUES (
    '$CALLER_NUM',
    '$CALLED_NUM',
    'incoming',
    'answered',
    FROM_UNIXTIME($START_TIME),
    FROM_UNIXTIME($ANSWER_TIME),
    1
) ON DUPLICATE KEY UPDATE
    answer_time = FROM_UNIXTIME($ANSWER_TIME),
    call_status = 'answered',
    early_media_sent = 1;
EOF

exit 0

