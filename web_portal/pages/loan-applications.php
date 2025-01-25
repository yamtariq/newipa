<?php
session_start();
require_once '../db_connect.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../login.php");
    exit();
}

// Fetch loan applications based on user role
$user_role = $_SESSION['role'];
$status_conditions = '';

if ($user_role === 'sales') {
    $status_conditions = "WHERE status IN ('pending', 'rejected', 'declined', 'missing', 'followup', 'fulfilled', 'accepted')";
} elseif ($user_role === 'credit') {
    $status_conditions = "WHERE status IN ('pending', 'fulfilled')";
}

$query = "SELECT * FROM loan_application_details $status_conditions ORDER BY status_date DESC";
$result = $conn->query($query);
?>

<!DOCTYPE html>
<html>
<head>
    <title>Nayifat - Loan Applications</title>
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

        .sidebar.collapsed ~ .toggle-sidebar {
            left: 1.25rem;
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

        .page-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding: 20px;
        }

        .page-title {
            color: var(--primary-color);
            font-size: 24px;
            font-weight: 600;
        }

        .applications-table {
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            overflow: hidden;
            width: 100%;
        }

        .applications-table table {
            width: 100%;
            border-collapse: collapse;
        }

        .applications-table th {
            background: #f8f9fa;
            color: #1a4f7a;
            font-weight: 600;
            padding: 15px;
            text-align: left;
            border-bottom: 2px solid #e9ecef;
        }

        .applications-table td {
            padding: 15px;
            border-bottom: 1px solid #e9ecef;
            color: #444;
        }

        .applications-table tr:hover {
            background: #f8f9fa;
        }

        .status-badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 500;
        }

        .status-pending {
            background: #fff3cd;
            color: #856404;
        }

        .status-approved {
            background: #d4edda;
            color: #155724;
        }

        .status-rejected {
            background: #f8d7da;
            color: #721c24;
        }

        .status-fulfilled,
        .status-accepted {
            background: #d4edda;
            color: #155724;
        }

        .status-declined {
            background: #f8d7da;
            color: #721c24;
        }

        .status-missing,
        .status-followup {
            background: #fff3cd;
            color: #856404;
        }

        .action-btn {
            padding: 6px 12px;
            border-radius: 6px;
            border: none;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s ease;
            background: var(--primary-color);
            color: white;
        }

        .action-btn:hover {
            background: var(--secondary-color);
            transform: translateY(-2px);
        }

        .btn-danger {
            background: white;
            color: #dc3545;
            border: 2px solid #dc3545;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
            text-decoration: none;
        }

        .btn-danger:hover {
            background: #fde8ea;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }

        .btn-danger i {
            font-size: 16px;
            color: #dc3545;
        }

        .logout-btn {
            background: white;
            color: #dc3545;
            border: 2px solid #dc3545;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
            text-decoration: none;
        }

        .logout-btn:hover {
            background: #fde8ea;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }

        .logout-btn i {
            font-size: 16px;
            color: #dc3545;
        }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s ease-out;
        }

        .modal-content {
            background-color: #fefefe;
            padding: 25px;
            border-radius: 12px;
            width: 90%;
            max-width: 800px;
            position: fixed;
            left: 50%;
            top: 50%;
            transform: translate(-50%, -50%);
            max-height: 90vh;
            overflow-y: auto;
            animation: slideIn 0.3s ease-out;
        }

        .modal-content::-webkit-scrollbar {
            width: 8px;
        }

        .modal-content::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 4px;
        }

        .modal-content::-webkit-scrollbar-thumb {
            background: var(--primary-color);
            border-radius: 4px;
        }

        .modal-content::-webkit-scrollbar-thumb:hover {
            background: var(--secondary-color);
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        @keyframes slideIn {
            from { transform: translate(-50%, -60%); opacity: 0; }
            to { transform: translate(-50%, -50%); opacity: 1; }
        }

        .close {
            position: absolute;
            right: 25px;
            top: 15px;
            font-size: 28px;
            font-weight: bold;
            color: #666;
            cursor: pointer;
            transition: color 0.3s ease;
            text-decoration: none;
            z-index: 100;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            background: #f8f9fa;
            margin-left: 20px;
        }

        .close:hover {
            color: var(--primary-color);
            background: #e9ecef;
        }

        /* Tab Styles */
        .tabs {
            display: flex;
            margin: 0 0 30px;
            padding: 0;
            list-style: none;
            border-bottom: 2px solid #e9ecef;
            gap: 10px;
        }

        .tab-item {
            padding: 15px 25px;
            cursor: pointer;
            color: #666;
            font-weight: 600;
            border-bottom: 2px solid transparent;
            margin-bottom: -2px;
            transition: all 0.3s ease;
            font-size: 15px;
            white-space: nowrap;
        }

        .tab-item:hover {
            color: var(--primary-color);
        }

        .tab-item.active {
            color: var(--primary-color);
            border-bottom-color: var(--primary-color);
        }

        .tab-content {
            display: none;
            animation: fadeIn 0.3s ease-out;
        }

        .tab-content.active {
            display: block;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: var(--primary-color);
            font-weight: 600;
            font-size: 14px;
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 10px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            color: #444;
            background-color: #f8f9fa;
            transition: all 0.3s ease;
        }

        .form-group input[readonly],
        .form-group select[readonly],
        .form-group textarea[readonly] {
            background-color: #f8f9fa;
            cursor: not-allowed;
            color: #666;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            border-color: var(--primary-color);
            outline: none;
            box-shadow: 0 0 0 3px rgba(26, 79, 122, 0.1);
        }

        .form-group textarea {
            min-height: 100px;
            resize: vertical;
        }

        .form-group select {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='%23666' viewBox='0 0 16 16'%3E%3Cpath d='M8 11.5l-5-5h10l-5 5z'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 15px center;
            padding-right: 40px;
        }

        .form-group select:not([readonly]) {
            background-color: white;
            cursor: pointer;
        }

        @media (max-width: 768px) {
            .sidebar {
                width: 80px;
                padding: 15px;
            }

            .logo-container h2,
            .nav-link span {
                display: none;
            }

            .nav-link i {
                margin-right: 0;
                font-size: 20px;
            }

            .main-content {
                padding: 15px;
            }

            .applications-table {
                overflow-x: auto;
            }
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
            <a href="../index.php" class="nav-link">
                <i class="fas fa-home"></i>
                <span>Dashboard</span>
            </a>
            <a href="loan-applications.php" class="nav-link active">
                <i class="fas fa-file-alt"></i>
                <span>Loan Applications</span>
            </a>
            <a href="card-applications.php" class="nav-link">
                <i class="fas fa-credit-card"></i>
                <span>Card Applications</span>
            </a>
            <a href="users.php" class="nav-link">
                <i class="fas fa-users"></i>
                <span>Users</span>
            </a>
            <a href="master-config.php" class="nav-link">
                <i class="fas fa-cogs"></i>
                <span>Master Config</span>
            </a>
            <a href="push-notification.php" class="nav-link">
                <i class="fas fa-bell"></i>
                <span>Push Notifications</span>
            </a>
        </nav>
    </div>
    <button class="toggle-sidebar" id="toggleSidebar">
        <i class="fas fa-bars"></i>
    </button>

    <div class="main-content">
        <div class="top-bar">
            <h1 class="page-title">Loan Applications</h1>
            <div class="user-actions">
                <a href="../logout.php" class="logout-btn">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </a>
            </div>
        </div>

        <div class="applications-table">
            <table>
                <thead>
                    <tr>
                        <th>Loan ID</th>
                        <th>Application No</th>
                        <th>National ID</th>
                        <th>Amount</th>
                        <th>Purpose</th>
                        <th>Tenure</th>
                        <th>Interest Rate</th>
                        <th>Status</th>
                        <th>Status Date</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php while($row = $result->fetch_assoc()): ?>
                        <tr data-loan-id="<?php echo $row['loan_id']; ?>">
                            <td><?php echo $row['loan_id']; ?></td>
                            <td><?php echo $row['application_no']; ?></td>
                            <td><?php echo $row['national_id']; ?></td>
                            <td>SAR <?php echo number_format($row['loan_amount'], 2); ?></td>
                            <td><?php echo $row['loan_purpose']; ?></td>
                            <td><?php echo $row['loan_tenure']; ?></td>
                            <td><?php echo $row['interest_rate']; ?>%</td>
                            <td>
                                <span class="status-badge status-<?php echo strtolower($row['status']); ?>">
                                    <?php echo ucfirst($row['status']); ?>
                                </span>
                            </td>
                            <td><?php echo date('Y-m-d H:i', strtotime($row['status_date'])); ?></td>
                            <td>
                                <button class="action-btn" onclick="viewLoanDetails(<?php echo $row['loan_id']; ?>)">
                                    <i class="fas fa-eye"></i> View
                                </button>
                            </td>
                        </tr>
                    <?php endwhile; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Application Details Modal -->
    <div id="applicationModal" class="modal">
        <div class="modal-content">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-right: 50px;">
                <div style="display: flex; align-items: center; gap: 20px;">
                    <h2 id="modalTitle" class="page-title">Application Details</h2>
                    <div class="status-buttons" style="display: flex; gap: 10px;">
                        <?php if ($_SESSION['role'] === 'credit'): ?>
                            <button class="action-btn" onclick="updateLoanStatus('approved')">Approved</button>
                            <button class="action-btn" onclick="updateLoanStatus('missing')">Missing</button>
                            <button class="action-btn" onclick="updateLoanStatus('rejected')">Rejected</button>
                        <?php elseif ($_SESSION['role'] === 'sales'): ?>
                            <button class="action-btn" onclick="updateLoanStatus('accepted')">Accepted</button>
                            <button class="action-btn" onclick="updateLoanStatus('fulfilled')">Fulfilled</button>
                            <button class="action-btn" onclick="updateLoanStatus('followup')">Follow Up</button>
                            <button class="action-btn" onclick="updateLoanStatus('declined')">Declined</button>
                        <?php endif; ?>
                    </div>
                </div>
                <div style="font-size: 14px; color: #666; text-align: right;">
                    <strong><?php echo $_SESSION['name']; ?></strong> (<?php echo ucfirst($_SESSION['role']); ?>)
                </div>
            </div>
            <span class="close" onclick="closeModal()">&times;</span>

            <ul class="tabs">
                <li class="tab-item active" onclick="switchTab('applicant-info', this)">Applicant Information</li>
                <li class="tab-item" onclick="switchTab('employment-info', this)">Employment Information</li>
                <li class="tab-item" onclick="switchTab('loan-info', this)">Loan Information</li>
            </ul>

            <div id="applicant-info" class="tab-content active">
                <div class="form-group">
                    <label>Full Name</label>
                    <input type="text" id="name" readonly placeholder="Applicant's full name">
                </div>
                <div class="form-group">
                    <label>National ID</label>
                    <input type="text" id="national_id" readonly placeholder="National ID number">
                </div>
                <div class="form-group">
                    <label>Date of Birth</label>
                    <input type="text" id="dob" readonly placeholder="Date of birth">
                </div>
                <div class="form-group">
                    <label>Phone Number</label>
                    <input type="text" id="phone" readonly placeholder="Phone number">
                </div>
                <div class="form-group">
                    <label>Email Address</label> 
                    <input type="email" id="email" readonly placeholder="Email address"> 
                </div> 
            </div>
            <div id="employment-info" class="tab-content">
            <div class="form-group">
                <label>Employer</label>
                <input type="text" id="employer" readonly placeholder="Employer name">
            </div>
            <div class="form-group">
                <label>Job Title</label>
                <input type="text" id="job_title" readonly placeholder="Job title">
            </div>
            <div class="form-group">
                <label>Monthly Salary</label>
                <input type="text" id="salary" readonly placeholder="Monthly salary">
            </div>
            <div class="form-group">
                <label>Employment Duration</label>
                <input type="text" id="employment_duration" readonly placeholder="Duration of employment">
            </div>
        </div>

        <div id="loan-info" class="tab-content">
            <div class="form-group">
                <label>Loan ID</label>
                <input type="text" id="loan_id" readonly>
            </div>
            <div class="form-group">
                <label>National ID</label>
                <input type="text" id="loan_national_id" readonly>
            </div>
            <div class="form-group">
                <label>Loan Amount</label>
                <input type="text" id="loan_amount" readonly>
            </div>
            <div class="form-group">
                <label>Loan Purpose</label>
                <input type="text" id="loan_purpose" readonly>
            </div>
            <div class="form-group">
                <label>Loan Tenure (Months)</label>
                <input type="text" id="loan_tenure" readonly>
            </div>
            <div class="form-group">
                <label>Interest Rate (%)</label>
                <input type="text" id="interest_rate" readonly>
            </div>
            <div class="form-group">
                <label>Status</label>
                <input type="text" id="status" readonly>
            </div>
            <div class="form-group">
                <label>Status Date</label>
                <input type="text" id="status_date" readonly>
            </div>
            <div class="form-group">
                <label>Remarks</label>
                <textarea id="remarks" rows="3"></textarea>
            </div>
        </div>
    </div>
</div>

<script>
    // Sidebar toggle functionality
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

    function switchTab(tabId, element) {
        document.querySelectorAll('.tab-item').forEach(tab => tab.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
        
        element.classList.add('active');
        document.getElementById(tabId).classList.add('active');
    }

    function closeModal() {
        document.getElementById('applicationModal').style.display = 'none';
    }

    // Close modal when clicking outside
    window.onclick = function(event) {
        const modal = document.getElementById('applicationModal');
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    }

    function viewLoanDetails(loanId) {
        fetch(`../api/get-loan-details.php?id=${loanId}`)
            .then(response => response.json())
            .then(data => {
                if (data.success && data.details) {
                    const details = data.details;
                    
                    document.getElementById('name').value = details.name || '';
                    document.getElementById('national_id').value = details.national_id || '';
                    document.getElementById('dob').value = details.dob || '';
                    document.getElementById('phone').value = details.phone || '';
                    document.getElementById('email').value = details.email || '';

                    document.getElementById('employer').value = details.employer || '';
                    document.getElementById('job_title').value = details.job_title || '';
                    document.getElementById('salary').value = details.salary 
                        ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'SAR' }).format(details.salary) 
                        : '';
                    document.getElementById('employment_duration').value = details.employment_duration || '';

                    document.getElementById('loan_id').value = details.loan_id || '';
                    document.getElementById('loan_national_id').value = details.national_id || '';
                    document.getElementById('loan_amount').value = details.loan_amount 
                        ? new Intl.NumberFormat('en-US', { style: 'currency', currency: 'SAR' }).format(details.loan_amount) 
                        : '';
                    document.getElementById('loan_purpose').value = details.loan_purpose || '';
                    document.getElementById('loan_tenure').value = details.loan_tenure || '';
                    document.getElementById('interest_rate').value = details.interest_rate 
                        ? details.interest_rate + '%' 
                        : '';
                    document.getElementById('status').value = details.status || 'pending';
                    document.getElementById('status_date').value = details.status_date 
                        ? new Date(details.status_date).toLocaleString() 
                        : '';
                    document.getElementById('remarks').value = details.remarks || '';

                    document.querySelectorAll('.tab-item').forEach(tab => tab.classList.remove('active'));
                    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
                    document.querySelector('.tab-item').classList.add('active');
                    document.getElementById('applicant-info').classList.add('active');

                    document.getElementById('applicationModal').style.display = 'block';
                }
            })
            .catch(error => console.error('Error:', error));
    }

    function updateLoanStatus(status) {
        const loanId = document.getElementById('loan_id').value;
        const remarks = document.getElementById('remarks').value;
        
        fetch('../api/update-loan-status.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                loan_id: loanId,
                status: status,
                remarks: remarks
            })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                const statusCell = document.querySelector(`tr[data-loan-id="${loanId}"] .status-badge`);
                if (statusCell) {
                    statusCell.textContent = status.charAt(0).toUpperCase() + status.slice(1);
                    statusCell.className = `status-badge status-${status.toLowerCase()}`;
                }
                
                document.getElementById('status').value = status.charAt(0).toUpperCase() + status.slice(1);
                document.getElementById('status_date').value = new Date().toLocaleString();
                
                alert('Status updated successfully');
            } else {
                alert('Failed to update status: ' + (data.message || 'Unknown error'));
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Failed to update status. Please try again.');
        });
    }
</script>
<script src="../assets/js/main.js?v=<?php echo time(); ?>"></script>
</body> 
</html> 
