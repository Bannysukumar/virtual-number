#!/bin/bash
# Check callback status and verify Asterisk integration

echo "=========================================="
echo "🔍 Checking Callback Status"
echo "=========================================="

echo ""
echo "1. Recent callbacks in database..."
mysql -u voip_user -p4XpeVl8flQpMZ0NAfkfDzTUyu virtual_phone_system -e "
SELECT 
    callback_id,
    caller_number,
    callback_status,
    callback_time,
    answer_time,
    duration,
    error_message,
    retry_count,
    created_at
FROM missed_call_callbacks 
ORDER BY created_at DESC 
LIMIT 5;
" 2>/dev/null

echo ""
echo "2. Checking if callback script exists and is executable..."
ls -la /usr/local/bin/trigger-callback.sh

echo ""
echo "3. Testing callback script manually..."
/usr/local/bin/trigger-callback.sh +919812345678 test123 2>&1 | head -10

echo ""
echo "4. Checking Asterisk status..."
asterisk -rx "core show version" 2>/dev/null | head -1 || echo "⚠️  Asterisk may not be running"

echo ""
echo "5. Checking Asterisk dialplan for callback context..."
asterisk -rx "dialplan show outbound-callback" 2>/dev/null | head -10 || echo "⚠️  Callback context not found"

echo ""
echo "6. Checking recent Asterisk logs..."
tail -20 /var/log/asterisk/full 2>/dev/null | grep -i "callback\|originate\|3003" || echo "No recent callback logs"

echo ""
echo "7. Checking PM2 API logs for callback attempts..."
pm2 logs missed-call-api --lines 30 --nostream | grep -i "callback\|trigger\|asterisk" || echo "No callback logs in API"

echo ""
echo "=========================================="
echo "✅ Status Check Complete"
echo "=========================================="
echo ""
echo "If callback_status is 'initiated' but no call was made:"
echo "  1. Check Asterisk is running: systemctl status asterisk"
echo "  2. Check callback script: /usr/local/bin/trigger-callback.sh"
echo "  3. Verify SIP trunk is configured for outbound calls"
echo "  4. Check Asterisk logs: tail -f /var/log/asterisk/full"

