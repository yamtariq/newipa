<?php
// Get statistics for dashboard
$stats = [
    'pending_cards' => 0,
    'pending_loans' => 0,
    'approved_cards' => 0,
    'approved_loans' => 0
];

try {
    // Get card application stats
    $stmt = $conn->query("SELECT status, COUNT(*) as count FROM card_application_details GROUP BY status");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if ($row['status'] === 'pending') {
            $stats['pending_cards'] = $row['count'];
        } elseif ($row['status'] === 'approved') {
            $stats['approved_cards'] = $row['count'];
        }
    }
    
    // Get loan application stats
    $stmt = $conn->query("SELECT status, COUNT(*) as count FROM loan_application_details GROUP BY status");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if ($row['status'] === 'pending') {
            $stats['pending_loans'] = $row['count'];
        } elseif ($row['status'] === 'approved') {
            $stats['approved_loans'] = $row['count'];
        }
    }
} catch(PDOException $e) {
    error_log("Dashboard Error: " . $e->getMessage());
}
?>

<div class="dashboard dashboard-page">
    <h1>Dashboard</h1>
    
    <div class="stats-container">
        <div class="card">
            <h3>Card Applications</h3>
            <div class="stats-grid">
                <div class="stat-item">
                    <span class="stat-label">Pending</span>
                    <span class="stat-value"><?php echo $stats['pending_cards']; ?></span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Approved</span>
                    <span class="stat-value"><?php echo $stats['approved_cards']; ?></span>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h3>Loan Applications</h3>
            <div class="stats-grid">
                <div class="stat-item">
                    <span class="stat-label">Pending</span>
                    <span class="stat-value"><?php echo $stats['pending_loans']; ?></span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Approved</span>
                    <span class="stat-value"><?php echo $stats['approved_loans']; ?></span>
                </div>
            </div>
        </div>
    </div>
    
    <?php if (checkPermission('super_admin')): ?>
    <div class="card mt-20">
        <h3>Recent Activity</h3>
        <table class="table">
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Application Type</th>
                    <th>Status</th>
                    <th>National ID</th>
                </tr>
            </thead>
            <tbody>
                <?php
                try {
                    $query = "
                        (SELECT status_date as date, 'Card' as type, status, national_id 
                         FROM card_application_details 
                         ORDER BY status_date DESC LIMIT 5)
                        UNION ALL
                        (SELECT status_date as date, 'Loan' as type, status, national_id 
                         FROM loan_application_details 
                         ORDER BY status_date DESC LIMIT 5)
                        ORDER BY date DESC
                        LIMIT 10
                    ";
                    
                    $stmt = $conn->query($query);
                    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                        echo "<tr>";
                        echo "<td>" . date('Y-m-d H:i', strtotime($row['date'])) . "</td>";
                        echo "<td>" . htmlspecialchars($row['type']) . "</td>";
                        echo "<td>" . htmlspecialchars($row['status']) . "</td>";
                        echo "<td>" . htmlspecialchars($row['national_id']) . "</td>";
                        echo "</tr>";
                    }
                } catch(PDOException $e) {
                    error_log("Recent Activity Error: " . $e->getMessage());
                }
                ?>
            </tbody>
        </table>
    </div>
    <?php endif; ?>
</div>

<style>
.dashboard-page {
    padding: 20px;
    margin-top: 80px; /* Increased margin to prevent header overlap */
    padding-top: 0; /* Remove top padding since we're using margin */
}

.stats-container {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin-top: 20px;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 15px;
    margin-top: 15px;
}

.stat-item {
    text-align: center;
    padding: 15px;
    background-color: #f8f9fa;
    border-radius: 4px;
}

.stat-label {
    display: block;
    font-size: 14px;
    color: #666;
    margin-bottom: 5px;
}

.stat-value {
    display: block;
    font-size: 24px;
    font-weight: bold;
    color: #2c3e50;
}
</style>
