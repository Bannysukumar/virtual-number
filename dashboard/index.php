<?php
/**
 * Virtual Phone System - Admin Dashboard
 * Main Dashboard Page
 */

require_once '../config/database.php';

// Database connection
$config = require '../config/database.php';
try {
    $pdo = new PDO(
        "mysql:host={$config['host']};port={$config['port']};dbname={$config['database']};charset={$config['charset']}",
        $config['username'],
        $config['password'],
        $config['options']
    );
} catch (PDOException $e) {
    die("Database connection failed: " . $e->getMessage());
}

// Get statistics
$stats = [];
$stats['total_calls_today'] = $pdo->query("SELECT COUNT(*) FROM calls WHERE DATE(start_time) = CURDATE()")->fetchColumn();
$stats['answered_calls_today'] = $pdo->query("SELECT COUNT(*) FROM calls WHERE DATE(start_time) = CURDATE() AND call_status = 'answered'")->fetchColumn();
$stats['total_recordings'] = $pdo->query("SELECT COUNT(*) FROM recordings")->fetchColumn();
$stats['pending_transcriptions'] = $pdo->query("SELECT COUNT(*) FROM transcriptions WHERE status = 'pending'")->fetchColumn();

// Get recent calls
$recent_calls = $pdo->query("
    SELECT 
        call_id,
        caller_id_number,
        caller_id_name,
        called_number,
        call_status,
        start_time,
        duration
    FROM calls
    ORDER BY start_time DESC
    LIMIT 20
")->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Virtual Phone System - Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f5;
            color: #333;
        }
        .header {
            background: #2c3e50;
            color: white;
            padding: 1rem 2rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header h1 { font-size: 1.5rem; }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 2rem;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            color: #7f8c8d;
            font-size: 0.9rem;
            text-transform: uppercase;
            margin-bottom: 0.5rem;
        }
        .stat-card .value {
            font-size: 2rem;
            font-weight: bold;
            color: #2c3e50;
        }
        .section {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
        }
        .section h2 {
            margin-bottom: 1rem;
            color: #2c3e50;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 0.75rem;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #2c3e50;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .status-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 12px;
            font-size: 0.85rem;
            font-weight: 500;
        }
        .status-answered { background: #d4edda; color: #155724; }
        .status-missed { background: #fff3cd; color: #856404; }
        .status-failed { background: #f8d7da; color: #721c24; }
        .nav {
            background: white;
            padding: 1rem 2rem;
            margin-bottom: 2rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .nav a {
            display: inline-block;
            margin-right: 1.5rem;
            color: #2c3e50;
            text-decoration: none;
            font-weight: 500;
        }
        .nav a:hover {
            color: #3498db;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📞 Virtual Phone System - Admin Dashboard</h1>
    </div>
    
    <div class="nav">
        <a href="index.php">Dashboard</a>
        <a href="calls.php">Call Logs</a>
        <a href="recordings.php">Recordings</a>
        <a href="transcriptions.php">Transcriptions</a>
        <a href="callers.php">Callers</a>
        <a href="settings.php">Settings</a>
    </div>
    
    <div class="container">
        <div class="stats-grid">
            <div class="stat-card">
                <h3>Total Calls Today</h3>
                <div class="value"><?php echo number_format($stats['total_calls_today']); ?></div>
            </div>
            <div class="stat-card">
                <h3>Answered Calls</h3>
                <div class="value"><?php echo number_format($stats['answered_calls_today']); ?></div>
            </div>
            <div class="stat-card">
                <h3>Total Recordings</h3>
                <div class="value"><?php echo number_format($stats['total_recordings']); ?></div>
            </div>
            <div class="stat-card">
                <h3>Pending Transcriptions</h3>
                <div class="value"><?php echo number_format($stats['pending_transcriptions']); ?></div>
            </div>
        </div>
        
        <div class="section">
            <h2>Recent Calls</h2>
            <table>
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>Caller</th>
                        <th>Called Number</th>
                        <th>Status</th>
                        <th>Duration</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($recent_calls as $call): ?>
                    <tr>
                        <td><?php echo date('Y-m-d H:i:s', strtotime($call['start_time'])); ?></td>
                        <td><?php echo htmlspecialchars($call['caller_id_number']); ?></td>
                        <td><?php echo htmlspecialchars($call['called_number']); ?></td>
                        <td>
                            <span class="status-badge status-<?php echo $call['call_status']; ?>">
                                <?php echo ucfirst($call['call_status']); ?>
                            </span>
                        </td>
                        <td><?php echo gmdate('H:i:s', $call['duration']); ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>

