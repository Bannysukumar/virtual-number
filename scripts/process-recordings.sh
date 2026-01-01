#!/bin/bash

# Script to process new recordings and queue them for transcription
# Run this via cron every 1-5 minutes

# Database credentials
DB_USER="voip_user"
DB_PASS="your_password"
DB_NAME="virtual_phone_system"

# Recording directories
RECORDING_DIR="/var/recordings"
QUESTIONS_DIR="/var/recordings/questions"
CALLS_DIR="/var/recordings/calls"

# Process new recordings
process_recordings() {
    local DIR=$1
    local TYPE=$2
    
    # Find new WAV files (modified in last 10 minutes)
    find "$DIR" -name "*.wav" -type f -mmin -10 | while read -r file; do
        # Extract call info from filename or database
        FILENAME=$(basename "$file")
        
        # Check if already processed
        EXISTS=$(mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "
            SELECT COUNT(*) FROM recordings WHERE file_path = '$file';
        ")
        
        if [ "$EXISTS" -eq 0 ]; then
            # Get file info
            FILE_SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            DURATION=$(soxi -D "$file" 2>/dev/null || echo "0")
            
            # Try to find matching call_id from filename pattern
            # Pattern: YYYYMMDD_HHMMSS_callerid or similar
            CALL_ID=$(mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "
                SELECT call_id FROM calls 
                WHERE recording_path LIKE '%$FILENAME%' 
                ORDER BY call_id DESC LIMIT 1;
            ")
            
            if [ -z "$CALL_ID" ] || [ "$CALL_ID" = "NULL" ]; then
                # Create a call record if not found
                CALL_ID=$(mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "
                    INSERT INTO calls (
                        caller_id_number,
                        called_number,
                        direction,
                        call_status,
                        start_time,
                        recording_path
                    ) VALUES (
                        'unknown',
                        'unknown',
                        'incoming',
                        'answered',
                        NOW(),
                        '$file'
                    );
                    SELECT LAST_INSERT_ID();
                ")
            fi
            
            # Extract question number if it's a question recording
            QUESTION_NUM=$(echo "$FILENAME" | grep -oP 'q\d+' | grep -oP '\d+' || echo "NULL")
            
            # Insert recording record
            RECORDING_ID=$(mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "
                INSERT INTO recordings (
                    call_id,
                    recording_type,
                    question_number,
                    file_path,
                    file_size,
                    duration,
                    format
                ) VALUES (
                    $CALL_ID,
                    '$TYPE',
                    ${QUESTION_NUM:-NULL},
                    '$file',
                    $FILE_SIZE,
                    $DURATION,
                    'wav'
                );
                SELECT LAST_INSERT_ID();
            ")
            
            # Create transcription record
            mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
                INSERT INTO transcriptions (
                    recording_id,
                    call_id,
                    status
                ) VALUES (
                    $RECORDING_ID,
                    $CALL_ID,
                    'pending'
                );
EOF
            
            echo "Queued recording: $file (ID: $RECORDING_ID)"
        fi
    done
}

# Process pending transcriptions
process_transcriptions() {
    # Get next pending transcription
    RESULT=$(mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "
        SELECT t.transcription_id, t.recording_id, t.call_id, r.file_path
        FROM transcriptions t
        JOIN recordings r ON t.recording_id = r.recording_id
        WHERE t.status = 'pending'
        ORDER BY t.created_at ASC
        LIMIT 1;
    ")
    
    if [ -n "$RESULT" ]; then
        TRANSCRIPTION_ID=$(echo "$RESULT" | cut -f1)
        RECORDING_ID=$(echo "$RESULT" | cut -f2)
        CALL_ID=$(echo "$RESULT" | cut -f3)
        FILE_PATH=$(echo "$RESULT" | cut -f4)
        
        # Run transcription script
        /usr/local/bin/transcribe-recording.sh "$FILE_PATH" "$RECORDING_ID" "$CALL_ID"
    fi
}

# Main execution
echo "$(date): Processing recordings..."

# Process different recording types
process_recordings "$CALLS_DIR" "full_call"
process_recordings "$QUESTIONS_DIR" "question_response"

# Process one pending transcription (to avoid overload)
process_transcriptions

echo "$(date): Processing complete"

