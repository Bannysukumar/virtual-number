#!/usr/bin/env node
/**
 * Missed Call SMS Receiver API
 * Receives SMS from Android/GSM modem and triggers SIP callback
 */

const express = require('express');
const mysql = require('mysql2/promise');
const { spawn } = require('child_process');
const crypto = require('crypto');

const app = express();
app.use(express.json());

// Configuration
const CONFIG = {
    port: 3001,
    db: {
        host: 'localhost',
        user: 'voip_user',
        password: '4XpeVl8flQpMZ0NAfkfDzTUyu',
        database: 'virtual_phone_system'
    },
    asterisk: {
        amiHost: '127.0.0.1',
        amiPort: 5038,
        amiUser: 'admin',
        amiSecret: 'amp111' // Change this to your AMI password
    },
    debounceSeconds: 60, // Prevent duplicate callbacks within 60 seconds
    retryAttempts: 1,
    retryDelay: 5000 // 5 seconds
};

// Database connection pool
const pool = mysql.createPool({
    ...CONFIG.db,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

/**
 * Extract phone number from SMS message
 * Handles formats like:
 * - "Missed call from +919876543210"
 * - "Missed call from 9876543210"
 * - "+919876543210"
 */
function extractPhoneNumber(message) {
    // Regex to match Indian phone numbers
    const patterns = [
        /(\+91\d{10})/g,           // +91XXXXXXXXXX
        /(91\d{10})/g,             // 91XXXXXXXXXX
        /(0\d{10})/g,              // 0XXXXXXXXXX
        /(\d{10})/g                // XXXXXXXXXX (10 digits)
    ];

    for (const pattern of patterns) {
        const matches = message.match(pattern);
        if (matches && matches.length > 0) {
            let number = matches[0];
            
            // Normalize to E.164 format (+91XXXXXXXXXX)
            if (number.startsWith('+91')) {
                return number;
            } else if (number.startsWith('91') && number.length === 12) {
                return '+' + number;
            } else if (number.startsWith('0') && number.length === 11) {
                return '+91' + number.substring(1);
            } else if (number.length === 10) {
                return '+91' + number;
            }
        }
    }

    return null;
}

/**
 * Check if callback was made recently (debouncing)
 */
async function checkRecentCallback(phoneNumber) {
    const [rows] = await pool.execute(
        `SELECT callback_time FROM missed_call_callbacks 
         WHERE caller_number = ? 
         AND callback_time > DATE_SUB(NOW(), INTERVAL ? SECOND)
         ORDER BY callback_time DESC LIMIT 1`,
        [phoneNumber, CONFIG.debounceSeconds]
    );

    return rows.length > 0;
}

/**
 * Log missed call to database
 */
async function logMissedCall(phoneNumber, smsData) {
    try {
        await pool.execute(
            `INSERT INTO missed_call_callbacks 
             (caller_number, sms_message, sms_from, callback_status, callback_time, created_at)
             VALUES (?, ?, ?, 'pending', NOW(), NOW())`,
            [phoneNumber, smsData.message, smsData.from || 'unknown']
        );
        return true;
    } catch (error) {
        console.error('Error logging missed call:', error);
        return false;
    }
}

/**
 * Update callback status
 */
async function updateCallbackStatus(phoneNumber, status, callId = null) {
    try {
        await pool.execute(
            `UPDATE missed_call_callbacks 
             SET callback_status = ?, call_id = ?, updated_at = NOW()
             WHERE caller_number = ? 
             AND callback_status = 'pending'
             ORDER BY created_at DESC LIMIT 1`,
            [status, callId, phoneNumber]
        );
    } catch (error) {
        console.error('Error updating callback status:', error);
    }
}

/**
 * Trigger SIP callback using Asterisk AMI
 */
async function triggerSIPCallback(phoneNumber) {
    return new Promise((resolve, reject) => {
        // Use asterisk -rx command to originate call
        // Format: asterisk -rx "channel originate Local/EXTEN@context application appname appdata"
        
        const callbackScript = `/usr/local/bin/trigger-callback.sh`;
        const command = spawn('bash', [callbackScript, phoneNumber]);

        let stdout = '';
        let stderr = '';

        command.stdout.on('data', (data) => {
            stdout += data.toString();
        });

        command.stderr.on('data', (data) => {
            stderr += data.toString();
        });

        command.on('close', (code) => {
            if (code === 0) {
                console.log(`Callback triggered successfully for ${phoneNumber}`);
                resolve({ success: true, output: stdout });
            } else {
                console.error(`Callback failed for ${phoneNumber}:`, stderr);
                reject({ success: false, error: stderr, code });
            }
        });

        command.on('error', (error) => {
            console.error(`Error spawning callback command:`, error);
            reject({ success: false, error: error.message });
        });
    });
}

/**
 * Retry callback with delay
 */
async function retryCallback(phoneNumber, attempt = 1) {
    if (attempt > CONFIG.retryAttempts) {
        await updateCallbackStatus(phoneNumber, 'failed');
        return { success: false, error: 'Max retries exceeded' };
    }

    console.log(`Retrying callback for ${phoneNumber} (attempt ${attempt})`);
    await new Promise(resolve => setTimeout(resolve, CONFIG.retryDelay));

    try {
        const result = await triggerSIPCallback(phoneNumber);
        if (result.success) {
            await updateCallbackStatus(phoneNumber, 'initiated');
            return result;
        } else {
            return await retryCallback(phoneNumber, attempt + 1);
        }
    } catch (error) {
        return await retryCallback(phoneNumber, attempt + 1);
    }
}

/**
 * Main SMS receiver endpoint
 */
app.post('/sms-receiver', async (req, res) => {
    try {
        const { from, message, timestamp } = req.body;

        console.log('Received SMS:', { from, message, timestamp });

        // Validate request
        if (!message) {
            return res.status(400).json({ 
                success: false, 
                error: 'Message is required' 
            });
        }

        // Extract phone number
        const phoneNumber = extractPhoneNumber(message);

        if (!phoneNumber) {
            console.log('Could not extract phone number from message:', message);
            return res.status(400).json({ 
                success: false, 
                error: 'Could not extract phone number from SMS' 
            });
        }

        console.log(`Extracted phone number: ${phoneNumber}`);

        // Check debouncing
        const recentCallback = await checkRecentCallback(phoneNumber);
        if (recentCallback) {
            console.log(`Skipping duplicate callback for ${phoneNumber} (within ${CONFIG.debounceSeconds}s)`);
            return res.json({ 
                success: true, 
                message: 'Callback skipped (duplicate within debounce period)',
                phoneNumber 
            });
        }

        // Log missed call
        await logMissedCall(phoneNumber, { from, message, timestamp });

        // Trigger callback (with retry)
        try {
            const result = await triggerSIPCallback(phoneNumber);
            if (result.success) {
                await updateCallbackStatus(phoneNumber, 'initiated');
                return res.json({ 
                    success: true, 
                    message: 'Callback initiated',
                    phoneNumber 
                });
            } else {
                // Retry once
                const retryResult = await retryCallback(phoneNumber);
                if (retryResult.success) {
                    return res.json({ 
                        success: true, 
                        message: 'Callback initiated after retry',
                        phoneNumber 
                    });
                } else {
                    return res.status(500).json({ 
                        success: false, 
                        error: 'Failed to initiate callback after retries',
                        phoneNumber 
                    });
                }
            }
        } catch (error) {
            console.error('Error triggering callback:', error);
            await updateCallbackStatus(phoneNumber, 'failed');
            return res.status(500).json({ 
                success: false, 
                error: 'Failed to trigger callback',
                phoneNumber 
            });
        }

    } catch (error) {
        console.error('Error processing SMS:', error);
        return res.status(500).json({ 
            success: false, 
            error: 'Internal server error' 
        });
    }
});

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        service: 'missed-call-sms-api'
    });
});

/**
 * Get callback status
 */
app.get('/callback-status/:phoneNumber', async (req, res) => {
    try {
        const { phoneNumber } = req.params;
        const [rows] = await pool.execute(
            `SELECT * FROM missed_call_callbacks 
             WHERE caller_number = ? 
             ORDER BY created_at DESC LIMIT 1`,
            [phoneNumber]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'No callback found' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Error fetching callback status:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Start server
const PORT = CONFIG.port || 3001;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Missed Call SMS API listening on port ${PORT}`);
    console.log(`Endpoint: POST http://0.0.0.0:${PORT}/sms-receiver`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('Shutting down...');
    await pool.end();
    process.exit(0);
});

