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

// Fetch card applications
$query = "SELECT * FROM card_application_details ORDER BY status_date DESC";
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

        .admin-text {
            font-size: 14px;
            color: #64748b;
            display: block;
            margin-top: 2px;
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

        .nav-link:hover, .nav-link.active {
            color: #0A71A3;
            background: #e6f3f8;
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

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        body {
            display: flex;
            min-height: 100vh;
            background-color: #f8f9fa;
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
            color: #0A71A3;
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

        .action-btn {
            padding: 6px 12px;
            border-radius: 6px;
            border: none;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s ease;
            background: #1a4f7a;
            color: white;
            margin-right: 5px;
        }

        .action-btn:hover {
            background: #2980b9;
            transform: translateY(-2px);
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
            color: #1a4f7a;
        }

        .tab-item.active {
            color: #1a4f7a;
            border-bottom-color: #1a4f7a;
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
            color: #1a4f7a;
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
            border-color: #1a4f7a;
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
            background: #1a4f7a;
            border-radius: 4px;
        }

        .modal-content::-webkit-scrollbar-thumb:hover {
            background: #2980b9;
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
        }

        .close:hover {
            color: #1a4f7a;
            background: #e9ecef;
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
            <a href="loan-applications.php" class="nav-link">
                <i class="fas fa-file-alt"></i>
                <span>Loan Applications</span>
            </a>
            <a href="card-applications.php" class="nav-link active">
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
            <h1 class="page-title">Card Applications</h1>
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
                        <th>Card ID</th>
                        <th>Application No</th>
                        <th>National ID</th>
                        <th>Card Type</th>
                        <th>Monthly Income</th>
                        <th>Status</th>
                        <th>Date</th>
                        <th>Actions</th>
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
                                <?php if ($row['status'] === 'pending'): ?>
                                <button class="action-btn" onclick="handleStatusUpdate(<?php echo $row['card_id']; ?>, 'approved', 'card')">
                                    <i class="fas fa-check"></i> Approve
                                </button>
                                <button class="action-btn" onclick="handleStatusUpdate(<?php echo $row['card_id']; ?>, 'rejected', 'card')">
                                    <i class="fas fa-times"></i> Reject
                                </button>
                                <?php endif; ?>
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
            <span class="close" onclick="closeModal()">&times;</span>
            <h2 class="page-title">Application Details</h2>
            <div id="applicationDetails">
                <div class="form-group">
                    <label>Card ID</label>
                    <input type="text" id="card_id" readonly>
                </div>
                <div class="form-group">
                    <label>Application Number</label>
                    <input type="text" id="application_no" readonly>
                </div>
                <div class="form-group">
                    <label>National ID</label>
                    <input type="text" id="national_id" readonly>
                </div>
                <div class="form-group">
                    <label>Customer Decision</label>
                    <input type="text" id="customerDecision" readonly>
                </div>
                <div class="form-group">
                    <label>Card Type</label>
                    <input type="text" id="card_type" readonly>
                </div>
                <div class="form-group">
                    <label>Card Limit</label>
                    <input type="text" id="card_limit" readonly>
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
                    <label>Previous Notes</label>
                    <textarea id="remarks" readonly rows="3"></textarea>
                </div>
                <div class="form-group">
                    <label>Note User</label>
                    <input type="text" id="noteUser" readonly>
                </div>
                <div class="form-group">
                    <label>Previous Note</label>
                    <textarea id="previous_note" readonly rows="3"></textarea>
                </div>
            </div>
            
            <?php if ($_SESSION['department'] === 'sales'): ?>
                <div class="form-group" id="salesDecisionGroup">
                    <label for="salesDecision">Decision:</label>
                    <select id="salesDecision" name="salesDecision">
                        <option value="">Select Decision</option>
                        <option value="rejected">Rejected</option>
                        <option value="fulfilled">Fulfilled</option>
                        <option value="underprocess">Under Process</option>
                    </select>
                </div>
            <?php endif; ?>
            
            <?php if ($_SESSION['department'] === 'credit'): ?>
                <div class="form-group">
                    <label for="creditDecision">Decision:</label>
                    <select id="creditDecision" name="creditDecision">
                        <option value="">Select Decision</option>
                        <option value="approved">Approved</option>
                        <option value="missing">Missing</option>
                        <option value="rejected">Rejected</option>
                    </select>
                </div>
            <?php endif; ?>
            
            <div class="form-group">
                <label for="note">New Note:</label>
                <textarea id="note" name="note" rows="4"></textarea>
            </div>
            
            <button onclick="submitDecision()" class="btn btn-primary">Submit Decision</button>
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
                            'card_id': details.card_id,
                            'application_no': details.application_no,
                            'national_id': details.national_id,
                            'customerDecision': details.customerDecision,
                            'card_type': details.card_type,
                            'card_limit': details.card_limit,
                            'status': details.status,
                            'status_date': details.status_date,
                            'remarks': details.remarks || '',
                            'noteUser': details.noteUser || '',
                            'previous_note': details.note || ''
                        };

                        // Set application ID for the form
                        const detailsContainer = document.getElementById('applicationDetails');
                        if (detailsContainer) {
                            detailsContainer.setAttribute('data-application-id', details.card_id);
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
                        
                        const salesDecisionGroup = document.getElementById('salesDecisionGroup');
                        if (salesDecisionGroup) {
                            // Only show sales decision if status is pending or missing
                            salesDecisionGroup.style.display = 
                                (details.status === 'pending' || details.status === 'missing') ? 'block' : 'none';
                        }
                        
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

        function submitDecision() {
            const detailsContainer = document.getElementById('applicationDetails');
            const applicationId = detailsContainer ? detailsContainer.getAttribute('data-application-id') : null;
            const noteElement = document.getElementById('note');
            const note = noteElement ? noteElement.value : '';
            let decision = '';
            
            const salesDecision = document.getElementById('salesDecision');
            const creditDecision = document.getElementById('creditDecision');
            
            if (salesDecision && salesDecision.value) {
                decision = salesDecision.value;
            } else if (creditDecision && creditDecision.value) {
                decision = creditDecision.value;
            }
            
            if (!applicationId) {
                alert('Error: Could not find application ID');
                return;
            }
            
            if (!decision) {
                alert('Please select a decision');
                return;
            }
            
            if (!note.trim()) {
                alert('Please enter a note');
                return;
            }
            
            fetch('../api/update-card-decision.php', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    applicationId: applicationId,
                    decision: decision,
                    note: note
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Decision submitted successfully');
                    closeModal();
                    location.reload();
                } else {
                    alert('Error submitting decision: ' + (data.message || 'Unknown error'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error submitting decision: ' + error.message);
            });
        }

        function closeModal() {
            const modal = document.getElementById('applicationModal');
            if (modal) {
                modal.style.display = 'none';
            }
        }

        function handleStatusUpdate(cardId, status, type) {
            fetch(`../api/update-status.php?id=${cardId}&status=${status}&type=${type}`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        window.location.reload();
                    } else {
                        alert('Error updating status');
                    }
                })
                .catch(error => console.error('Error:', error));
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
