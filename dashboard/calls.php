<?php
/**
 * Call Logs Page
 */

require_once '../config/database.php';

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

// Pagination
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$per_page = 50;
$offset = ($page - 1) * $per_page;

// Filters
$filter_caller = $_GET['caller'] ?? '';
$filter_status = $_GET['status'] ?? '';
$filter_date_from = $_GET['date_from'] ?? '';
$filter_date_to = $_GET['date_to'] ?? '';

// Build query
$where = [];
$params = [];

if ($filter_caller) {
    $where[] = "caller_id_number LIKE :caller";
    $params[':caller'] = "%$filter_caller%";
}

if ($filter_status) {
    $where[] = "call_status = :status";
    $params[':status'] = $filter_status;
}

if ($filter_date_from) {
    $where[] = "start_time >= :date_from";
    $params[':date_from'] = $filter_date_from;
}

if ($filter_date_to) {
    $where[] = "start_time <= :date_to";
    $params[':date_to'] = $filter_date_to . ' 23:59:59';
}

$where_sql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

// Get total count
$total = $pdo->prepare("SELECT COUNT(*) FROM calls $where_sql");
$total->execute($params);
$total_calls = $total->fetchColumn();
$total_pages = ceil($total_calls / $per_page);

// Get calls
$stmt = $pdo->prepare("
    SELECT 
        call_id,
        caller_id_number,
        caller_id_name,
        called_number,
        direction,
        call_status,
        start_time,
        answer_time,
        end_time,
        duration,
        talk_time,
        recording_path
    FROM calls
    $where_sql
    ORDER BY start_time DESC
    LIMIT :limit OFFSET :offset
");

foreach ($params as $key => $value) {
    $stmt->bindValue($key, $value);
}
$stmt->bindValue(':limit', $per_page, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$stmt->execute();
$calls = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Call Logs - Virtual Phone System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <?php include 'header.php'; ?>
    
    <div class="container">
        <div class="section">
            <h2>Call Logs</h2>
            
            <form method="GET" class="filters">
                <input type="text" name="caller" placeholder="Caller ID" value="<?php echo htmlspecialchars($filter_caller); ?>">
                <select name="status">
                    <option value="">All Status</option>
                    <option value="answered" <?php echo $filter_status === 'answered' ? 'selected' : ''; ?>>Answered</option>
                    <option value="missed" <?php echo $filter_status === 'missed' ? 'selected' : ''; ?>>Missed</option>
                    <option value="failed" <?php echo $filter_status === 'failed' ? 'selected' : ''; ?>>Failed</option>
                </select>
                <input type="date" name="date_from" value="<?php echo htmlspecialchars($filter_date_from); ?>">
                <input type="date" name="date_to" value="<?php echo htmlspecialchars($filter_date_to); ?>">
                <button type="submit">Filter</button>
                <a href="calls.php">Clear</a>
            </form>
            
            <div class="pagination-info">
                Showing <?php echo $offset + 1; ?>-<?php echo min($offset + $per_page, $total_calls); ?> of <?php echo number_format($total_calls); ?> calls
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Time</th>
                        <th>Caller</th>
                        <th>Called</th>
                        <th>Status</th>
                        <th>Duration</th>
                        <th>Recording</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($calls as $call): ?>
                    <tr>
                        <td><?php echo $call['call_id']; ?></td>
                        <td><?php echo date('Y-m-d H:i:s', strtotime($call['start_time'])); ?></td>
                        <td><?php echo htmlspecialchars($call['caller_id_number']); ?></td>
                        <td><?php echo htmlspecialchars($call['called_number']); ?></td>
                        <td>
                            <span class="status-badge status-<?php echo $call['call_status']; ?>">
                                <?php echo ucfirst($call['call_status']); ?>
                            </span>
                        </td>
                        <td><?php echo gmdate('H:i:s', $call['duration']); ?></td>
                        <td>
                            <?php if ($call['recording_path']): ?>
                                <a href="recording.php?id=<?php echo $call['call_id']; ?>">Play</a>
                            <?php else: ?>
                                -
                            <?php endif; ?>
                        </td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
            
            <?php if ($total_pages > 1): ?>
            <div class="pagination">
                <?php if ($page > 1): ?>
                    <a href="?page=<?php echo $page - 1; ?>&<?php echo http_build_query($_GET); ?>">Previous</a>
                <?php endif; ?>
                
                <?php for ($i = max(1, $page - 2); $i <= min($total_pages, $page + 2); $i++): ?>
                    <a href="?page=<?php echo $i; ?>&<?php echo http_build_query(array_merge($_GET, ['page' => $i])); ?>"
                       class="<?php echo $i === $page ? 'active' : ''; ?>">
                        <?php echo $i; ?>
                    </a>
                <?php endfor; ?>
                
                <?php if ($page < $total_pages): ?>
                    <a href="?page=<?php echo $page + 1; ?>&<?php echo http_build_query($_GET); ?>">Next</a>
                <?php endif; ?>
            </div>
            <?php endif; ?>
        </div>
    </div>
</body>
</html>

