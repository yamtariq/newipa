<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

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

// Simple query first to check if table exists and has correct structure
$query = "SELECT * FROM card_application_details $status_conditions ORDER BY status_date DESC";
$result = $conn->query($query);

if ($result === false) {
    die("Error executing query: " . $conn->error);
}
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

        .table-container {
            margin: 20px;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }

        th {
            background-color: #f8f9fa;
            color: #1e293b;
            font-weight: 600;
            text-align: left;
            padding: 12px 20px;
            border-bottom: 1px solid #e2e8f0;
        }

        td {
            padding: 12px 20px;
            border-bottom: 1px solid #e2e8f0;
            color: #475569;
        }

        tr:hover {
            background-color: var(--hover-bg);
        }

        .status-badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 500;
            text-transform: uppercase;
        }

        .pending {
            background-color: #fff7e6;
            color: #d97706;
        }

        .approved {
            background-color: #ecfdf5;
            color: #059669;
        }

        .declined {
            background-color: #fef2f2;
            color: #dc2626;
        }

        .rejected {
            background-color: #fef2f2;
            color: #dc2626;
        }

        .view-btn {
            background-color: var(--primary-color);
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .view-btn:hover {
            background-color: var(--secondary-color);
        }

        .view-btn i {
            font-size: 12px;
        }

        .no-data {
            text-align: center;
            color: #94a3b8;
            padding: 40px 0;
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

        .tab-container {
            margin-top: 20px;
        }

        .tab-header {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 10px;
        }

        .tab-button {
            background: none;
            border: none;
            padding: 8px 16px;
            cursor: pointer;
            font-size: 14px;
            color: #64748b;
            border-radius: 4px;
            transition: all 0.2s;
        }

        .tab-button:hover {
            background-color: var(--hover-bg);
            color: var(--primary-color);
        }

        .tab-button.active {
            background-color: var(--primary-color);
            color: white;
        }

        .tab-content {
            padding: 20px 0;
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
            border: 1px solid #e2e8f0;
            padding: 10px;
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

        .form-group textarea {
            min-height: 100px;
            resize: vertical;
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

        .btn-warning {
            background-color: #fbbf24;
            color: #92400e;
        }

        .btn-warning:hover {
            background-color: #f59e0b;
        }

        .btn-info {
            background-color: #0ea5e9;
            color: white;
        }

        .btn-info:hover {
            background-color: #0284c7;
        }

        .button-group {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }

        .status-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-badge.pending {
            background-color: #fef3c7;
            color: #92400e;
        }

        .status-badge.accepted {
            background-color: #dcfce7;
            color: #166534;
        }

        .status-badge.rejected {
            background-color: #fee2e2;
            color: #991b1b;
        }

        .status-badge.missing {
            background-color: #fef9c3;
            color: #854d0e;
        }

        .status-badge.followup {
            background-color: #dbeafe;
            color: #1e40af;
        }

        .status-badge.fulfilled {
            background-color: #f3e8ff;
            color: #6b21a8;
        }

        .document-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px;
            border: 1px solid #e2e8f0;
            border-radius: 4px;
            margin-bottom: 10px;
        }

        .status-history-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }

        .status-history-table th,
        .status-history-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }

        .status-history-table th {
            background-color: #f8fafc;
            color: #64748b;
            font-weight: 600;
        }

        .status-history-table tr:hover {
            background-color: #f8fafc;
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
            <button id="toggleSidebar" class="toggle-button">
                <i class="fas fa-bars"></i>
            </button>
        </div>
        
        <div class="content-wrapper">
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Card ID</th>
                            <th>National ID</th>
                            <th>Status</th>
                            <th>Application Date</th>
                            <th style="width: 100px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                        if ($result && $result->num_rows > 0) {
                            while ($row = $result->fetch_assoc()) {
                                $statusClass = strtolower($row['status']);
                                echo "<tr>";
                                echo "<td>{$row['card_id']}</td>";
                                echo "<td>{$row['national_id']}</td>";
                                echo "<td><span class='status-badge {$statusClass}'>{$row['status']}</span></td>";
                                echo "<td>" . date('Y-m-d H:i', strtotime($row['status_date'])) . "</td>";
                                echo "<td>";
                                echo "<button class='view-btn' onclick='showApplicationDetails({$row['card_id']})'>";
                                echo "<i class='fas fa-eye'></i> View";
                                echo "</button>";
                                echo "</td>";
                                echo "</tr>";
                            }
                        } else {
                            echo "<tr><td colspan='5' class='no-data'>No applications found</td></tr>";
                        }
                        ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <div id="applicationModal" class="modal">
        <div class="modal-content">
            <span class="close">&times;</span>
            <div class="modal-header">
                <h2>Card Application Details</h2>
                <div id="statusBadge" class="status-badge"></div>
            </div>
            <div class="modal-body">
                <div class="tab-container">
                    <div class="tab-header">
                        <button class="tab-button active" onclick="openTab(event, 'card-info')">Card Info</button>
                        <button class="tab-button" onclick="openTab(event, 'personal-info')">Personal Info</button>
                        <button class="tab-button" onclick="openTab(event, 'employment-info')">Employment Info</button>
                    </div>

                    <div id="card-info" class="tab-content">
                        <div class="form-group">
                            <label>Card ID</label>
                            <input type="text" id="card_id" readonly>
                        </div>
                        <div class="form-group">
                            <label>Card Type</label>
                            <input type="text" id="card_type" readonly>
                        </div>
                        <div class="form-group">
                            <label>Credit Limit</label>
                            <input type="text" id="credit_limit" readonly>
                        </div>
                        <div class="form-group">
                            <label>Application Date</label>
                            <input type="text" id="application_date" readonly>
                        </div>
                        <div class="form-group">
                            <label>Status</label>
                            <input type="text" id="status" readonly>
                        </div>
                        <div class="form-group">
                            <label>Last Updated</label>
                            <input type="text" id="last_updated" readonly>
                        </div>
                        <div class="form-group">
                            <label>Remarks</label>
                            <textarea id="remarks"></textarea>
                        </div>
                    </div>

                    <div id="personal-info" class="tab-content" style="display: none;">
                        <div class="form-group">
                            <label>Full Name</label>
                            <input type="text" id="name" readonly>
                        </div>
                        <div class="form-group">
                            <label>National ID</label>
                            <input type="text" id="national_id" readonly>
                        </div>
                        <div class="form-group">
                            <label>Date of Birth</label>
                            <input type="text" id="dob" readonly>
                        </div>
                        <div class="form-group">
                            <label>Nationality</label>
                            <input type="text" id="nationality" readonly>
                        </div>
                        <div class="form-group">
                            <label>Mobile Number</label>
                            <input type="text" id="phone" readonly>
                        </div>
                        <div class="form-group">
                            <label>Email</label>
                            <input type="text" id="email" readonly>
                        </div>
                        <div class="form-group">
                            <label>City</label>
                            <input type="text" id="city" readonly>
                        </div>
                        <div class="form-group">
                            <label>Address</label>
                            <textarea id="address" readonly></textarea>
                        </div>
                    </div>

                    <div id="employment-info" class="tab-content" style="display: none;">
                        <div class="form-group">
                            <label>Employment Status</label>
                            <input type="text" id="employment_status" readonly>
                        </div>
                        <div class="form-group">
                            <label>Employer</label>
                            <input type="text" id="employer" readonly>
                        </div>
                        <div class="form-group">
                            <label>Monthly Salary</label>
                            <input type="text" id="salary" readonly>
                        </div>
                    </div>
                </div>

                <!-- Action Buttons -->
                <?php if ($_SESSION['role'] === 'credit'): ?>
                <div class="action-buttons">
                    <button onclick="updateCardStatus('approved')" class="btn btn-success">Approve</button>
                    <button onclick="updateCardStatus('rejected')" class="btn btn-danger">Reject</button>
                    <button onclick="updateCardStatus('missing')" class="btn btn-warning">Missing Info</button>
                    <button onclick="updateCardStatus('followup')" class="btn btn-info">Follow Up</button>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>

    <script>
        function openTab(evt, tabName) {
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tab-content");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
            }
            tablinks = document.getElementsByClassName("tab-button");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }
            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";
        }

        async function showApplicationDetails(cardId) {
            try {
                const response = await fetch(`../api/get-card-details.php?id=${cardId}`);
                const data = await response.json();
                
                if (!response.ok) {
                    throw new Error(data.message || 'Error fetching application details');
                }
                
                if (!data.success) {
                    throw new Error(data.message || 'Error fetching application details');
                }

                const app = data.details;
                
                // Update card info
                document.getElementById('card_id').value = app.card_id;
                document.getElementById('card_type').value = app.card_type;
                document.getElementById('credit_limit').value = app.credit_limit;
                document.getElementById('application_date').value = app.application_date;
                document.getElementById('status').value = app.status;
                document.getElementById('last_updated').value = app.last_updated;
                document.getElementById('remarks').value = app.remarks || '';
                
                // Update personal info
                document.getElementById('name').value = app.name;
                document.getElementById('national_id').value = app.national_id;
                document.getElementById('dob').value = app.dob;
                document.getElementById('nationality').value = app.nationality;
                document.getElementById('phone').value = app.phone;
                document.getElementById('email').value = app.email;
                document.getElementById('city').value = app.city;
                document.getElementById('address').value = app.address;
                
                // Update employment info
                document.getElementById('employment_status').value = app.employment_status;
                document.getElementById('employer').value = app.employer;
                document.getElementById('salary').value = app.salary;
                
                // Update status badge
                const statusBadge = document.getElementById('statusBadge');
                statusBadge.textContent = app.status.toUpperCase();
                statusBadge.className = 'status-badge ' + app.status.toLowerCase();

                // Show modal and first tab
                document.getElementById('applicationModal').style.display = 'block';
                openTab({ currentTarget: document.querySelector('.tab-button') }, 'card-info');
            } catch (error) {
                console.error('Error:', error);
                alert(error.message);
            }
        }

        // Close modal when clicking the close button or outside the modal
        document.querySelector('.close').onclick = function() {
            document.getElementById('applicationModal').style.display = 'none';
        }

        window.onclick = function(event) {
            const modal = document.getElementById('applicationModal');
            if (event.target == modal) {
                modal.style.display = 'none';
            }
        }

        async function updateCardStatus(newStatus) {
            const cardId = document.getElementById('card_id').value;
            const remarks = document.getElementById('remarks').value;
            
            try {
                const response = await fetch('../api/update-card-status.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        card_id: cardId,
                        status: newStatus,
                        remarks: remarks
                    })
                });
                
                const data = await response.json();
                
                if (!response.ok) {
                    throw new Error(data.message || 'Error updating status');
                }
                
                if (data.success) {
                    alert('Status updated successfully');
                    location.reload();
                } else {
                    throw new Error(data.message || 'Error updating status');
                }
            } catch (error) {
                console.error('Error:', error);
                alert(error.message);
            }
        }
    </script>
    <script src="../assets/js/main.js?v=<?php echo time(); ?>"></script>
</body>
</html>
