#!/bin/bash

# Script to transcribe audio recordings using Whisper.cpp
# This script processes recordings in the queue

RECORDING_FILE=$1
RECORDING_ID=$2
CALL_ID=$3

# Configuration
WHISPER_MODEL="base"  # Options: tiny, base, small, medium, large
WHISPER_BIN="/usr/local/bin/whisper"
RECORDING_DIR="/var/recordings"
OUTPUT_DIR="/var/recordings/transcriptions"

# Database credentials
DB_USER="voip_user"
DB_PASS="your_password"
DB_NAME="virtual_phone_system"

# Check if file exists
if [ ! -f "$RECORDING_FILE" ]; then
    echo "Error: Recording file not found: $RECORDING_FILE"
    exit 1
fi

# Update status to processing
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE transcriptions 
SET status = 'processing', created_at = NOW()
WHERE recording_id = $RECORDING_ID;
EOF

# Start time for processing time calculation
START_TIME=$(date +%s)

# Convert audio to required format if needed (16kHz, mono, WAV)
TEMP_FILE="/tmp/recording_${RECORDING_ID}.wav"
sox "$RECORDING_FILE" -r 16000 -c 1 "$TEMP_FILE"

# Run Whisper transcription
if [ -f "$WHISPER_BIN" ]; then
    TRANSCRIPTION=$("$WHISPER_BIN" -m "/usr/local/share/whisper/models/ggml-${WHISPER_MODEL}.bin" -f "$TEMP_FILE" 2>/dev/null | tail -n 1)
else
    # Fallback: Use whisper.cpp via Python if available
    TRANSCRIPTION=$(python3 -c "
import whisper
model = whisper.load_model('${WHISPER_MODEL}')
result = model.transcribe('${TEMP_FILE}')
print(result['text'])
" 2>/dev/null)
fi

# Calculate processing time
END_TIME=$(date +%s)
PROCESSING_TIME=$((END_TIME - START_TIME))

# Detect language (simple detection - can be improved)
LANGUAGE="en"
if echo "$TRANSCRIPTION" | grep -q -i "है\|कर\|से\|में"; then
    LANGUAGE="hi"
fi

# Save transcription to database
mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE transcriptions 
SET 
    transcribed_text = '$(echo "$TRANSCRIPTION" | sed "s/'/''/g")',
    language = '$LANGUAGE',
    processing_time = $PROCESSING_TIME,
    status = 'completed',
    completed_at = NOW()
WHERE recording_id = $RECORDING_ID;
EOF

# Save transcription to file
mkdir -p "$OUTPUT_DIR"
echo "$TRANSCRIPTION" > "$OUTPUT_DIR/transcription_${RECORDING_ID}.txt"

# Cleanup temp file
rm -f "$TEMP_FILE"

echo "Transcription completed for recording $RECORDING_ID"
exit 0

