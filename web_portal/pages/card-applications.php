<?php
session_start();
require_once '../db_connect.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../login.php");
    exit();
}

// Check if user has the correct role
if (!isset($_SESSION['role']) || ($_SESSION['role'] !== 'sales' && $_SESSION['role'] !== 'credit' && $_SESSION['role'] !== 'admin')) {
    header("Location: ../unauthorized.php");
    exit();
}

// Set department based on role for consistency
$_SESSION['department'] = $_SESSION['role'];

// Fetch card applications based on user role
$user_role = $_SESSION['role'];
$status_conditions = '';

if ($user_role === 'sales') {
    $status_conditions = "WHERE status IN ('pending', 'rejected', 'declined', 'missing', 'followup', 'fulfilled', 'accepted')";
} elseif ($user_role === 'credit') {
    $status_conditions = "WHERE status IN ('pending', 'fulfilled')";
}

// Fetch card applications
$query = "SELECT * FROM card_application_details $status_conditions ORDER BY status_date DESC";
$result = $conn->query($query);
?>

<!DOCTYPE html>
<html>
<head>
    <title>Nayifat - Card Applications</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        :root {
            --primary-color: #0A71A3;
            --secondary-color: #0986c3;
            --accent-color: #40a7d9;
            --hover-bg: #e6f3f8;
            --text-color: #1e293b;
            --sidebar-width: 280px;
            --sidebar-width-collapsed: 80px;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Inter', 'Segoe UI', sans-serif;
        }

        body {
            display: flex;
            min-height: 100vh;
            background-color: #f8f9fa;
        }

        .sidebar {
            width: var(--sidebar-width);
            background: white;
            color: #64748b;
            padding: 1.5rem 1rem;
            transition: all 0.3s ease;
            height: 100vh;
            position: fixed;
            left: 0;
            top: 0;
            z-index: 1000;
            box-shadow: 4px 0 10px rgba(0, 0, 0, 0.05);
            overflow-y: auto;
        }

        .sidebar.collapsed {
            width: var(--sidebar-width-collapsed);
        }

        .logo-container {
            text-align: center;
            padding: 1rem 0;
            margin-bottom: 2rem;
            border-bottom: 1px solid #e2e8f0;
            white-space: nowrap;
            overflow: hidden;
        }

        .logo-container h2 {
            color: var(--primary-color);
            font-size: 1.5rem;
            font-weight: 700;
            transition: all 0.3s ease;
            margin-bottom: 0.5rem;
        }

        .logo-container h2 .full-name {
            transition: opacity 0.3s ease;
        }

        .sidebar.collapsed .logo-container h2 .full-name {
            display: none;
        }

        .logo-container h2 .letter {
            display: inline-block;
        }

        .sidebar.collapsed .logo-container {
            padding: 1rem 0;
        }

        .sidebar.collapsed .logo-container h2 {
            opacity: 1;
            width: auto;
            margin: 0;
            font-size: 1.75rem;
        }

        .user-info {
            font-size: 0.875rem;
            color: #64748b;
            transition: opacity 0.3s ease;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .user-name {
            font-weight: 600;
            color: var(--text-color);
            margin-bottom: 0.25rem;
        }

        .user-role {
            font-size: 0.75rem;
            color: #64748b;
        }

        .sidebar.collapsed .user-info {
            opacity: 0;
            height: 0;
            margin: 0;
        }

        .nav-link {
            display: flex;
            align-items: center;
            color: #64748b;
            text-decoration: none;
            padding: 0.875rem 1rem;
            margin-bottom: 0.5rem;
            border-radius: 0.5rem;
            transition: all 0.2s ease;
            white-space: nowrap;
            overflow: hidden;
        }

        .nav-link i {
            min-width: 1.5rem;
            margin-right: 1rem;
            font-size: 1.25rem;
            text-align: center;
            transition: margin 0.3s ease;
        }

        .nav-link span {
            opacity: 1;
            transition: opacity 0.3s ease;
        }

        .sidebar.collapsed .nav-link span {
            opacity: 0;
            width: 0;
            display: none;
        }

        .nav-link:hover,
        .nav-link.active {
            color: var(--primary-color);
            background: var(--hover-bg);
        }

        .toggle-sidebar {
            position: fixed;
            bottom: 2rem;
            left: 1.25rem;
            background: var(--primary-color);
            color: white;
            width: 2.5rem;
            height: 2.5rem;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            border: none;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            transition: all 0.2s ease;
            z-index: 1001;
        }

        .toggle-sidebar:hover {
            background: var(--secondary-color);
            transform: scale(1.05);
        }

        .main-content {
            margin-left: var(--sidebar-width);
            padding: 2rem;
            width: calc(100% - var(--sidebar-width));
            transition: all 0.3s ease;
        }

        .sidebar.collapsed ~ .main-content {
            margin-left: var(--sidebar-width-collapsed);
            width: calc(100% - var(--sidebar-width-collapsed));
        }

        .top-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px 30px;
            background: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            border-radius: 12px;
            margin-bottom: 30px;
        }

        .page-title {
            font-size: 1.5rem;
            color: var(--text-color);
            margin: 0;
            font-weight: 600;
        }

        .applications-table {
            width: 100%;
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            border-collapse: collapse;
            margin-top: 20px;
            overflow: hidden;
        }

        .applications-table th,
        .applications-table td {
            padding: 15px 20px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }

        .applications-table th {
            background-color: #f8fafc;
            font-weight: 600;
            color: var(--text-color);
            font-size: 0.875rem;
        }

        .applications-table tr:hover {
            background-color: #f8fafc;
        }

        .status-badge {
            padding: 6px 12px;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 500;
            text-transform: capitalize;
        }

        .status-pending {
            background-color: #fff7ed;
            color: #c2410c;
        }

        .status-approved {
            background-color: #f0fdf4;
            color: #15803d;
        }

        .status-rejected {
            background-color: #fef2f2;
            color: #b91c1c;
        }

        .status-fulfilled {
            background-color: #ecfdf5;
            color: #047857;
        }

        .status-missing {
            background-color: #fff7ed;
            color: #c2410c;
        }

        .status-followup {
            background-color: #eff6ff;
            color: #1d4ed8;
        }

        .modal {
            display: none;
            position: fixed;
            z-index: 1050;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            overflow: auto;
        }

        .modal-content {
            background-color: #fefefe;
            margin: 5% auto;
            padding: 30px;
            border: none;
            border-radius: 12px;
            width: 80%;
            max-width: 800px;
            max-height: 80vh;
            overflow-y: auto;
            position: relative;
            animation: modalSlideIn 0.3s ease-out;
        }

        @keyframes modalSlideIn {
            from {
                transform: translateY(-10%);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        .close {
            position: absolute;
            right: 20px;
            top: 20px;
            font-size: 28px;
            font-weight: bold;
            color: #64748b;
            cursor: pointer;
            transition: color 0.2s ease;
        }

        .close:hover {
            color: var(--text-color);
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: var(--text-color);
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            font-size: 0.875rem;
            transition: border-color 0.2s ease;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: var(--primary-color);
        }

        .form-group input[readonly],
        .form-group select[readonly],
        .form-group textarea[readonly] {
            background-color: #f8fafc;
            cursor: not-allowed;
        }

        .form-group select:not([readonly]) {
            background-color: white;
            cursor: pointer;
        }

        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 8px 16px;
            border-radius: 6px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            border: none;
            font-size: 0.875rem;
        }

        .btn-primary {
            background-color: var(--primary-color);
            color: white;
        }

        .btn-primary:hover {
            background-color: var(--secondary-color);
        }

        .btn-secondary {
            background-color: #e2e8f0;
            color: var(--text-color);
        }

        .btn-secondary:hover {
            background-color: #cbd5e1;
        }

        .btn-danger {
            background-color: #ef4444;
            color: white;
        }

        .btn-danger:hover {
            background-color: #dc2626;
        }

        .btn-group {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }

        .modal-content::-webkit-scrollbar {
            width: 8px;
        }

        .modal-content::-webkit-scrollbar-thumb {
            background: #cbd5e1;
            border-radius: 4px;
        }

        .modal-content::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="sidebar" id="sidebar">
        <div class="logo-container">
            <h2><span class="letter">N</span><span class="full-name">ayifat</span></h2>
            <div class="user-info">
                <div class="user-name"><?php echo $_SESSION['name']; ?></div>
                <div class="user-role"><?php echo ucfirst($_SESSION['role']); ?></div>
            </div>
        </div>
        <nav>
            <a href="dashboard.php" class="nav-link">
                <i class="fas fa-home"></i>
                <span>Dashboard</span>
            </a>
            <a href="loan-applications.php" class="nav-link">
                <i class="fas fa-file-alt"></i>
                <span>Loan Applications</span>
            </a>
            <a href="card-applications.php" class="nav-link active">
                <i class="fas fa-credit-card"></i>
                <span>Card Applications</span>
            </a>
            <a href="master-config.php" class="nav-link">
                <i class="fas fa-cogs"></i>
                <span>Master Config</span>
            </a>
            <a href="push-notification.php" class="nav-link">
                <i class="fas fa-bell"></i>
                <span>Push Notification</span>
            </a>
            <a href="../logout.php" class="nav-link">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
        </nav>
    </div>

    <button class="toggle-sidebar" id="toggleSidebar">
        <i class="fas fa-bars"></i>
    </button>

    <div class="main-content">
        <div class="top-bar">
            <h1 class="page-title">Card Applications</h1>
        </div>

        <div class="applications-table">
            <table>
                <thead>
                    <tr>
                        <th>Card ID</th>
                        <th>Application No</th>
                        <th>National ID</th>
                        <th>Card Type</th>
                        <th>Monthly Income</th>
                        <th>Status</th>
                        <th>Date</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php while($row = $result->fetch_assoc()): ?>
                        <tr>
                            <td><?php echo $row['card_id']; ?></td>
                            <td><?php echo $row['application_no']; ?></td>
                            <td><?php echo $row['national_id']; ?></td>
                            <td><?php echo $row['card_type']; ?></td>
                            <td>SAR <?php echo number_format($row['monthly_income'], 2); ?></td>
                            <td>
                                <span class="status-badge status-<?php echo strtolower($row['status']); ?>">
                                    <?php echo ucfirst($row['status']); ?>
                                </span>
                            </td>
                            <td><?php echo date('Y-m-d H:i', strtotime($row['status_date'])); ?></td>
                            <td>
                                <button class="action-btn" onclick="showApplicationDetails(<?php echo $row['card_id']; ?>)">
                                    <i class="fas fa-eye"></i> View
                                </button>
                                <?php if ($_SESSION['role'] === 'credit' && $row['status'] === 'pending'): ?>
                                    <button class="action-btn" onclick="handleStatusUpdate(<?php echo $row['card_id']; ?>, 'approved', 'card')">
                                        <i class="fas fa-check"></i> Approve
                                    </button>
                                    <button class="action-btn" onclick="handleStatusUpdate(<?php echo $row['card_id']; ?>, 'rejected', 'card')">
                                        <i class="fas fa-times"></i> Reject
                                    </button>
                                <?php endif; ?>
                                <?php if ($_SESSION['role'] === 'sales' && $row['status'] === 'pending'): ?>
                                    <button class="action-btn" onclick="handleStatusUpdate(<?php echo $row['card_id']; ?>, 'fulfilled', 'card')">
                                        <i class="fas fa-check"></i> Mark Fulfilled
                                    </button>
                                    <button class="action-btn" onclick="handleStatusUpdate(<?php echo $row['card_id']; ?>, 'missing', 'card')">
                                        <i class="fas fa-exclamation-triangle"></i> Mark Missing
                                    </button>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endwhile; ?>
                </tbody>
            </table>
        </div>
    </div>

    <script>
        function showApplicationDetails(applicationId) {
            fetch(`../api/get-card-details.php?id=${applicationId}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const details = data.details;
                        const fields = {
                            'application_id': details.application_id,
                            'customer_name': details.customer_name,
                            'mobile': details.mobile,
                            'status': details.status,
                        };

                        // Set application ID for the form
                        const detailsContainer = document.getElementById('applicationDetails');
                        if (detailsContainer) {
                            detailsContainer.setAttribute('data-application-id', details.application_id);
                        }

                        // Safely set field values
                        Object.keys(fields).forEach(fieldId => {
                            const element = document.getElementById(fieldId);
                            if (element) {
                                element.value = fields[fieldId];
                            } else {
                                console.warn(`Element with id '${fieldId}' not found`);
                            }
                        });

                        const modal = document.getElementById('applicationModal');
                        if (modal) {
                            modal.style.display = 'block';
                        }
                    } else {
                        alert('Error loading application details: ' + (data.message || 'Unknown error'));
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error loading application details: ' + error.message);
                });
        }

        function updateStatus(status) {
            const applicationId = document.getElementById('applicationDetails').getAttribute('data-application-id');
            const note = document.getElementById('note').value;

            fetch('../api/update-card-status.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    applicationId: applicationId,
                    status: status,
                    note: note
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Status updated successfully');
                    closeModal();
                    location.reload();
                } else {
                    alert('Error updating status: ' + (data.message || 'Unknown error'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error updating status: ' + error.message);
            });
        }

        function closeModal() {
            const modal = document.getElementById('applicationModal');
            if (modal) {
                modal.style.display = 'none';
            }
        }
    </script>
    <script>
        const sidebar = document.getElementById('sidebar');
        const toggleButton = document.getElementById('toggleSidebar');

        toggleButton.addEventListener('click', () => {
            sidebar.classList.toggle('collapsed');
        });

        // Handle responsive behavior
        if (window.innerWidth <= 768) {
            sidebar.classList.add('collapsed');
        }

        window.addEventListener('resize', () => {
            if (window.innerWidth <= 768) {
                sidebar.classList.add('collapsed');
            }
        });
    </script>
    <script src="../assets/js/main.js?v=<?php echo time(); ?>"></script>
</body>
</html>
