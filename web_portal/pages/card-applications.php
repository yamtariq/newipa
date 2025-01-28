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
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.4);
            overflow-y: auto;
        }

        .modal-content {
            background-color: #fefefe;
            margin: 50px auto;
            padding: 20px;
            border-radius: 8px;
            width: 80%;
            max-width: 900px;
            position: relative;
            max-height: 90vh;
            overflow-y: auto;
        }

        .close {
            position: absolute;
            right: 20px;
            top: 20px;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }

        .close:hover {
            color: var(--primary-color);
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
            color: #64748b;
            font-size: 14px;
        }

        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #e2e8f0;
            border-radius: 4px;
            font-size: 14px;
        }

        .form-group textarea {
            min-height: 100px;
            resize: vertical;
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
            background-color: #cbd5e1;
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

    <div id="applicationModal" class="modal">
        <div class="modal-content">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-right: 50px;">
                <div style="display: flex; align-items: center; gap: 20px;">
                    <h2 id="modalTitle" class="page-title">Application Details</h2>
                    <div class="status-badge" id="statusBadge"></div>
                </div>
                <span class="close">&times;</span>
            </div>

            <div class="tab-container">
                <div class="tab-header">
                    <button class="tab-button active" onclick="openTab(event, 'card-info')">Card Info</button>
                    <button class="tab-button" onclick="openTab(event, 'personal-info')">Personal Info</button>
                    <button class="tab-button" onclick="openTab(event, 'documents')">Documents</button>
                    <button class="tab-button" onclick="openTab(event, 'status-history')">Status History</button>
                </div>

                <div id="card-info" class="tab-content">
                    <div class="form-group">
                        <label>Card Application ID</label>
                        <input type="text" id="card_id" readonly>
                    </div>
                    <div class="form-group">
                        <label>Card Type</label>
                        <input type="text" id="card_type" readonly>
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
                        <label>Remarks</label>
                        <textarea id="remarks"></textarea>
                    </div>
                    <div class="button-group">
                        <button class="btn btn-primary" onclick="updateCardStatus('accepted')">Accept</button>
                        <button class="btn btn-secondary" onclick="updateCardStatus('rejected')">Reject</button>
                        <button class="btn btn-warning" onclick="updateCardStatus('missing')">Missing Info</button>
                        <button class="btn btn-info" onclick="updateCardStatus('followup')">Follow Up</button>
                    </div>
                </div>

                <div id="personal-info" class="tab-content" style="display: none;">
                    <div class="form-group">
                        <label>Full Name</label>
                        <input type="text" id="full_name" readonly>
                    </div>
                    <div class="form-group">
                        <label>National ID</label>
                        <input type="text" id="national_id" readonly>
                    </div>
                    <div class="form-group">
                        <label>Mobile Number</label>
                        <input type="text" id="mobile_number" readonly>
                    </div>
                    <div class="form-group">
                        <label>Email</label>
                        <input type="text" id="email" readonly>
                    </div>
                </div>

                <div id="documents" class="tab-content" style="display: none;">
                    <div id="documents-container"></div>
                </div>

                <div id="status-history" class="tab-content" style="display: none;">
                    <div id="status-history-container"></div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Sidebar toggle functionality
        const sidebar = document.getElementById('sidebar');
        const toggleButton = document.getElementById('toggleSidebar');
        const mainContent = document.querySelector('.main-content');

        function toggleSidebar() {
            sidebar.classList.toggle('collapsed');
            mainContent.classList.toggle('expanded');
        }

        // Modal functionality
        const modal = document.getElementById('applicationModal');
        const span = document.getElementsByClassName('close')[0];

        span.onclick = function() {
            modal.style.display = "none";
        }

        window.onclick = function(event) {
            if (event.target == modal) {
                modal.style.display = "none";
            }
        }

        function openTab(evt, tabName) {
            var i, tabContent, tabButtons;
            tabContent = document.getElementsByClassName("tab-content");
            for (i = 0; i < tabContent.length; i++) {
                tabContent[i].style.display = "none";
            }
            tabButtons = document.getElementsByClassName("tab-button");
            for (i = 0; i < tabButtons.length; i++) {
                tabButtons[i].className = tabButtons[i].className.replace(" active", "");
            }
            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";
        }

        function showApplicationDetails(applicationId) {
            fetch(`../api/get-card-details.php?id=${applicationId}`)
                .then(response => response.json())
                .then(data => {
                    // Card Info
                    document.getElementById('card_id').value = data.card_id;
                    document.getElementById('card_type').value = data.card_type;
                    document.getElementById('application_date').value = data.application_date;
                    document.getElementById('status').value = data.status;
                    document.getElementById('remarks').value = data.remarks || '';

                    // Personal Info
                    document.getElementById('full_name').value = data.full_name;
                    document.getElementById('national_id').value = data.national_id;
                    document.getElementById('mobile_number').value = data.mobile_number;
                    document.getElementById('email').value = data.email;

                    // Update status badge
                    const statusBadge = document.getElementById('statusBadge');
                    statusBadge.textContent = data.status.toUpperCase();
                    statusBadge.className = 'status-badge ' + data.status;

                    // Documents
                    const documentsContainer = document.getElementById('documents-container');
                    documentsContainer.innerHTML = '';
                    if (data.documents && data.documents.length > 0) {
                        data.documents.forEach(doc => {
                            const docElement = document.createElement('div');
                            docElement.className = 'document-item';
                            docElement.innerHTML = `
                                <span>${doc.name}</span>
                                <a href="${doc.url}" target="_blank" class="btn btn-primary">View</a>
                            `;
                            documentsContainer.appendChild(docElement);
                        });
                    } else {
                        documentsContainer.innerHTML = '<p>No documents available</p>';
                    }

                    // Status History
                    const historyContainer = document.getElementById('status-history-container');
                    historyContainer.innerHTML = '';
                    if (data.status_history && data.status_history.length > 0) {
                        const historyTable = document.createElement('table');
                        historyTable.className = 'status-history-table';
                        historyTable.innerHTML = `
                            <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Status</th>
                                    <th>Remarks</th>
                                    <th>Updated By</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${data.status_history.map(history => `
                                    <tr>
                                        <td>${history.date}</td>
                                        <td><span class="status-badge ${history.status}">${history.status.toUpperCase()}</span></td>
                                        <td>${history.remarks || ''}</td>
                                        <td>${history.updated_by}</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        `;
                        historyContainer.appendChild(historyTable);
                    } else {
                        historyContainer.innerHTML = '<p>No status history available</p>';
                    }

                    modal.style.display = "block";
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error fetching application details');
                });
        }

        function updateCardStatus(status) {
            const cardId = document.getElementById('card_id').value;
            const remarks = document.getElementById('remarks').value;
            
            fetch('../api/update-card-status.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    card_id: cardId,
                    status: status,
                    remarks: remarks
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Status updated successfully');
                    location.reload();
                } else {
                    alert('Error updating status: ' + data.message);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error updating status');
            });
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
