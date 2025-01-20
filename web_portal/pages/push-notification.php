<?php
session_start();
require_once '../db_connect.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../login.php");
    exit();
}

// Function to get all columns from a table
function getTableColumns($conn, $table) {
    $columns = [];
    $result = $conn->query("SHOW COLUMNS FROM $table");
    while($row = $result->fetch_assoc()) {
        $columns[] = $row['Field'];
    }
    return $columns;
}

// Get columns for each table
$tables = [
    'Users' => getTableColumns($conn, 'Users'),
    'card_application_details' => getTableColumns($conn, 'card_application_details'),
    'loan_application_details' => getTableColumns($conn, 'loan_application_details')
];

// Convert tables data to JSON for JavaScript use
$tablesJson = json_encode($tables);

// Define available operators
$operators = [
    '=' => 'Equals',
    '!=' => 'Not Equals',
    '>' => 'Greater Than',
    '<' => 'Less Than',
    '>=' => 'Greater Than or Equal',
    '<=' => 'Less Than or Equal',
    'LIKE' => 'Contains',
    'IN' => 'In List',
    'BETWEEN' => 'Between'
];
$operatorsJson = json_encode($operators);

// Get notification templates
$notification_templates_query = "SELECT * FROM notification_templates order by id DESC";
$notification_templates_result = $conn->query($notification_templates_query);
$notification_templates = [];
while($row = $notification_templates_result->fetch_assoc()) {
    $notification_templates[] = $row;
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Nayifat - Push Notifications</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        :root {
            --sidebar-width: 280px;
            --sidebar-width-collapsed: 80px;
        }

        .sidebar {
            width: var(--sidebar-width);
            background: white;
            color: #1e293b;
            padding: 1.5rem 1rem;
            flex-shrink: 0;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
            transition: all 0.3s ease;
            position: fixed;
            height: 100vh;
            overflow-x: hidden;
            z-index: 1000;
            left: 0;
            top: 0;
        }

        .sidebar.collapsed {
            width: var(--sidebar-width-collapsed);
            padding: 1.5rem 0.75rem;
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
            color: #0A71A3;
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
            color: #1e293b;
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

        .sidebar.collapsed .nav-link i {
            margin-right: 0;
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
            background: #0A71A3;
            color: white;
            border: none;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
            z-index: 1001;
        }

        .sidebar.collapsed ~ .toggle-sidebar {
            left: 1.25rem;
        }

        .toggle-sidebar:hover {
            background: #0986c3;
            transform: scale(1.05);
        }

        .main-content {
            flex: 1;
            padding: 2rem;
            margin-left: var(--sidebar-width);
            transition: all 0.3s ease;
            min-height: 100vh;
            width: calc(100% - var(--sidebar-width));
            position: relative;
        }

        .sidebar.collapsed ~ .main-content {
            margin-left: var(--sidebar-width-collapsed);
            width: calc(100% - var(--sidebar-width-collapsed));
        }

        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
            }

            .sidebar.show {
                transform: translateX(0);
            }

            .main-content {
                margin-left: 0 !important;
                width: 100% !important;
            }

            .modal-content {
                width: 95%;
                margin: 2% auto;
            }
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
            margin: 0;
            padding: 0;
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
            color: #0A71A3;
            font-size: 24px;
            font-weight: 600;
        }

        .user-actions {
            display: flex;
            gap: 1rem;
            align-items: center;
        }

        .btn-primary {
            background: white;
            color: #0A71A3;
            border: 2px solid #0A71A3;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
        }

        .btn-primary:hover {
            background: #e6f3f8;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }

        .btn-primary i {
            font-size: 16px;
            color: #0A71A3;
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

        .notifications-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-top: 20px;
        }

        .notifications-table th {
            background: #0A71A3;
            color: white;
            font-weight: 600;
            padding: 15px;
            text-align: left;
        }

        .notifications-table td {
            padding: 15px;
            border-bottom: 1px solid #e9ecef;
        }

        .notifications-table tr:hover {
            background: #e6f3f8;
        }

        .notifications-table tr:last-child td {
            border-bottom: none;
        }

        .status-badge {
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-align: center;
            display: inline-block;
            min-width: 100px;
        }

        .status-unread {
            background: #e3f2fd;
            color: #0A71A3;
        }

        .status-read {
            background: #e8f5e9;
            color: #388e3c;
        }

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
            background: #0A71A3;
            border-radius: 4px;
        }

        .modal-content::-webkit-scrollbar-thumb:hover {
            background: #0986c3;
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
        }

        .close:hover {
            color: #0A71A3;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #0A71A3;
            font-weight: 600;
        }

        .form-group input,
        .form-group textarea,
        .form-group select {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s ease;
        }

        .form-group input:focus,
        .form-group textarea:focus,
        .form-group select:focus {
            border-color: #0A71A3;
            outline: none;
        }

        .form-group textarea {
            min-height: 100px;
            resize: vertical;
        }

        .language-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
        }

        .language-tab {
            padding: 8px 16px;
            border: 2px solid #0A71A3;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s ease;
        }

        .language-tab.active {
            background: #0A71A3;
            color: white;
        }

        .language-content {
            display: none;
        }

        .language-content.active {
            display: block;
        }

        .btn-submit {
            background: #0A71A3;
            color: white;
            border: none;
            padding: 12px 25px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 600;
            width: 100%;
            transition: background-color 0.3s ease;
        }

        .btn-submit:hover {
            background: #0986c3;
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        @keyframes slideIn {
            from { transform: translate(-50%, -60%); opacity: 0; }
            to { transform: translate(-50%, -50%); opacity: 1; }
        }

        .filter-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }

        .filter-section h3 {
            color: #0A71A3;
            margin-bottom: 15px;
            font-size: 18px;
        }

        .range-inputs {
            display: flex;
            gap: 10px;
            align-items: center;
        }

        .range-inputs input {
            flex: 1;
        }

        .range-inputs span {
            color: #666;
            font-weight: 600;
        }

        select[multiple] {
            height: auto;
            min-height: 100px;
        }

        .target-input {
            margin-bottom: 25px;
        }

        .filter-builder {
            margin: 20px 0;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 8px;
        }

        .filter-row {
            display: flex;
            gap: 10px;
            margin-bottom: 10px;
            align-items: center;
        }

        .filter-list {
            margin-top: 15px;
        }

        .filter-item {
            background: #f5f5f5;
            padding: 10px;
            margin: 5px 0;
            border-radius: 4px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .filter-item .remove-filter {
            color: #dc3545;
            cursor: pointer;
        }

        .filter-operation {
            margin: 10px 0;
            padding: 10px;
            background: #e9ecef;
            border-radius: 4px;
            display: none;
        }

        .data-table {
            width: 100%;
            min-width: 800px;
            border-collapse: separate;
            border-spacing: 0;
            background: white;
            margin: 0;
        }

        .table-container {
            margin: 20px;
            padding: 20px;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
            display: flex;
            flex-direction: column;
        }

        .scroll-container {
            overflow-x: auto;
            max-width: 100%;
            margin-bottom: 10px;
            scrollbar-width: thin;
            scrollbar-color: #0986c3 #f0f0f0;
            order: -1;
        }

        .table-wrapper {
            overflow-x: hidden;
            overflow-y: auto;
            max-height: 500px;
            -webkit-overflow-scrolling: touch;
        }

        .scroll-container::-webkit-scrollbar {
            height: 8px;
            width: 8px;
        }

        .scroll-container::-webkit-scrollbar-track {
            background: #f0f0f0;
            border-radius: 4px;
        }

        .scroll-container::-webkit-scrollbar-thumb {
            background: #0986c3;
            border-radius: 4px;
        }

        .scroll-container::-webkit-scrollbar-thumb:hover {
            background: #0A71A3;
        }

        .data-table thead th {
            position: sticky;
            top: 0;
            background: #f8f9fa;
            z-index: 1;
            font-weight: 600;
            color: #2c3e50;
            border-bottom: 2px solid #ddd;
        }

        .data-table th,
        .data-table td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
            white-space: nowrap;
            max-width: 200px;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .data-table td:hover {
            white-space: normal;
            word-break: break-word;
        }

        .data-table tbody tr:hover {
            background-color: #e6f3f8;
        }

        .btn-secondary {
            background-color: #6c757d;
            color: white;
            border: none;
            padding: 8px 15px;
            border-radius: 4px;
            cursor: pointer;
            transition: background-color 0.3s;
        }

        .btn-secondary:hover {
            background-color: #5a6268;
        }

        .header-buttons {
            display: flex;
            gap: 10px;
            align-items: center;
        }

        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
            }

            .sidebar.show {
                transform: translateX(0);
            }

            .main-content {
                margin-left: 0;
                width: 100%;
            }

            .modal-content {
                width: 95%;
                margin: 2% auto;
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
            <a href="loan-applications.php" class="nav-link">
                <i class="fas fa-file-alt"></i>
                <span>Loan Applications</span>
            </a>
            <a href="card-applications.php" class="nav-link ">
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
            <a href="push-notification.php" class="nav-link active">
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
            <h1 class="page-title">Push Notifications</h1>
            <div class="user-actions">
                <button class="btn-primary" onclick="openModal()">
                    <i class="fas fa-plus"></i> Send New Notification
                </button>
                <a href="../logout.php" class="btn-danger">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </a>
            </div>
        </div>

        <!-- Notification Templates Table -->
        <div class="table-container">
            <div class="scroll-container">
                <div style="width: 1px; height: 1px;"></div>
            </div>
            <div class="table-wrapper">
                <table class="data-table">
                    <thead>
                        <tr>
                            <?php
                            // Display table headers based on first row
                            if (!empty($notification_templates)) {
                                foreach (array_keys($notification_templates[0]) as $column) {
                                    echo "<th>" . htmlspecialchars(ucwords(str_replace('_', ' ', $column))) . "</th>";
                                }
                                echo "<th>Actions</th>";
                            }
                            ?>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($notification_templates as $template): ?>
                            <tr>
                                <?php 
                                foreach ($template as $value) {
                                    echo "<td>" . htmlspecialchars($value) . "</td>";
                                }
                                ?>
                                <td>
                                    <button class="btn-secondary" onclick="useTemplate(<?php echo htmlspecialchars(json_encode($template)); ?>)">
                                        Use Template
                                    </button>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>


        <!-- Modal for sending new notification -->
        <div id="notificationModal" class="modal">
            <div class="modal-content">
                <span class="close" onclick="closeModal()">&times;</span>
                <h2 class="page-title">Send New Notification</h2>
                
                <form id="notificationForm" onsubmit="sendNotification(event)">
                    <div class="form-group">
                        <label>Target Method *</label>
                        <select id="targetType" onchange="toggleTargetInputs()">
                            <option value="filtered">Filtered Users</option>
                            <option value="single">Single User</option>
                            <option value="multiple">Multiple Users</option>
                        </select>
                    </div>

                    <!-- Single User Input -->
                    <div id="singleUserInput" class="form-group target-input" style="display: none;">
                        <div class="form-group">
                            <label>National ID *</label>
                            <input type="text" id="nationalId" placeholder="Enter National ID">
                        </div>
                    </div>

                    <!-- Multiple Users Input -->
                    <div id="multipleUserInput" class="form-group target-input" style="display: none;">
                        <div class="form-group">
                            <label>National IDs *</label>
                            <textarea id="nationalIds" placeholder="Enter National IDs (one per line)"></textarea>
                        </div>
                    </div>

                    <!-- Filtered Users Input -->
                    <div id="filteredUserInput" class="target-input" style="display: block;">
                        <div class="filter-section">
                            <h3>Build Filter</h3>
                            
                            <div class="filter-builder">
                                <div class="filter-row">
                                    <div class="form-group">
                                        <label>Table</label>
                                        <select id="filterTable" onchange="updateColumns()">
                                            <option value="">Select Table</option>
                                        </select>
                                    </div>
                                    
                                    <div class="form-group">
                                        <label>Column</label>
                                        <select id="filterColumn" disabled>
                                            <option value="">Select Column</option>
                                        </select>
                                    </div>
                                    
                                    <div class="form-group">
                                        <label>Operator</label>
                                        <select id="filterOperator" disabled>
                                            <option value="">Select Operator</option>
                                        </select>
                                    </div>
                                    
                                    <div class="form-group">
                                        <label>Value</label>
                                        <div id="filterValueContainer">
                                            <input type="text" id="filterValue" placeholder="Enter value" disabled>
                                        </div>
                                    </div>
                                    
                                    <button type="button" class="btn-primary" onclick="addFilter()" id="addFilterBtn" disabled>
                                        Add Filter
                                    </button>
                                </div>
                            </div>
                            
                            <div class="filter-operation" id="filterOperation">
                                <label>Filter Operation:</label>
                                <select id="filterOperationType">
                                    <option value="AND">Match All Filters (AND)</option>
                                    <option value="OR">Match Any Filter (OR)</option>
                                </select>
                            </div>
                            
                            <div class="filter-list" id="filterList">
                                <!-- Active filters will be displayed here -->
                            </div>
                        </div>
                    </div>

                    <div class="language-tabs">
                        <div class="language-tab" onclick="switchLanguageMode('single')">Single Language</div>
                        <div class="language-tab active" onclick="switchLanguageMode('multi')">Multi Language</div>
                    </div>

                    <div id="singleLanguageContent" style="display: none;">
                        <div class="form-group">
                            <label>Title *</label>
                            <input type="text" id="title" placeholder="Notification Title">
                        </div>
                        <div class="form-group">
                            <label>Message *</label>
                            <textarea id="body" placeholder="Notification Message"></textarea>
                        </div>
                    </div>

                    <div id="multiLanguageContent" style="display: block;">
                        <div class="form-group">
                            <label>English Title *</label>
                            <input type="text" id="titleEn" placeholder="English Title">
                        </div>
                        <div class="form-group">
                            <label>English Message *</label>
                            <textarea id="bodyEn" placeholder="English Message"></textarea>
                        </div>
                        <div class="form-group">
                            <label>Arabic Title *</label>
                            <input type="text" id="titleAr" placeholder="Arabic Title">
                        </div>
                        <div class="form-group">
                            <label>Arabic Message *</label>
                            <textarea id="bodyAr" placeholder="Arabic Message"></textarea>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>App Route (Optional)</label>
                        <input type="text" id="route" placeholder="e.g., /loans/details">
                    </div>

                    <div class="form-group">
                        <label>Additional Data (Optional JSON)</label>
                        <textarea id="additionalData" placeholder="{ &quot;key&quot;: &quot;value&quot; }"></textarea>
                    </div>

                    <div class="form-group">
                        <label>Expiry Date (Optional)</label>
                        <input type="datetime-local" id="expiryDate">
                    </div>

                    <button type="submit" class="btn-primary">Send Notification</button>
                </form>
            </div>
        </div>
    </div>

    <script>
        // Modal functions
        function openModal() {
            document.getElementById('notificationModal').style.display = 'block';
            // Set default target type to filtered
            document.getElementById('targetType').value = 'filtered';
            toggleTargetInputs();
            // Set default language mode to multi
            switchLanguageMode('multi');
        }

        function closeModal() {
            document.getElementById('notificationModal').style.display = 'none';
            // Reset form when closing
            document.getElementById('notificationForm').reset();
            activeFilters = [];
            updateFilterList();
            resetFilterForm();
        }

        function toggleTargetInputs() {
            // Hide all target inputs first
            document.querySelectorAll('.target-input').forEach(input => {
                input.style.display = 'none';
            });
            
            // Show the selected target input
            const targetType = document.getElementById('targetType').value;
            if (targetType === 'single') {
                document.getElementById('singleUserInput').style.display = 'block';
            } else if (targetType === 'multiple') {
                document.getElementById('multipleUserInput').style.display = 'block';
            } else if (targetType === 'filtered') {
                document.getElementById('filteredUserInput').style.display = 'block';
            }
        }

        function switchLanguageMode(mode) {
            // Update tabs
            document.querySelectorAll('.language-tab').forEach(tab => {
                tab.classList.remove('active');
            });
            event.target.classList.add('active');

            // Update content visibility
            if (mode === 'single') {
                document.getElementById('singleLanguageContent').style.display = 'block';
                document.getElementById('multiLanguageContent').style.display = 'none';
            } else {
                document.getElementById('singleLanguageContent').style.display = 'none';
                document.getElementById('multiLanguageContent').style.display = 'block';
            }
        }
        
        // Sync scroll positions and handle scrolling
        document.addEventListener('DOMContentLoaded', function() {
            const scrollContainer = document.querySelector('.scroll-container');
            const tableWrapper = document.querySelector('.table-wrapper');
            
            // Add a dummy element to force scrollbar to appear
            const scrollContent = document.createElement('div');
            scrollContent.style.width = tableWrapper.scrollWidth + 'px';
            scrollContent.style.height = '1px';
            scrollContainer.appendChild(scrollContent);

            // Sync horizontal scroll
            scrollContainer.addEventListener('scroll', function() {
                tableWrapper.scrollLeft = this.scrollLeft;
            });

            tableWrapper.addEventListener('scroll', function() {
                scrollContainer.scrollLeft = this.scrollLeft;
            });

            // Handle mouse wheel scrolling for both directions
            tableWrapper.addEventListener('wheel', function(e) {
                if (e.shiftKey) {
                    // Horizontal scroll with Shift key
                    e.preventDefault();
                    const scrollSpeed = 60;
                    this.scrollLeft += e.deltaY;
                    scrollContainer.scrollLeft = this.scrollLeft;
                } else {
                    // Vertical scroll (natural behavior)
                    const maxScroll = this.scrollHeight - this.clientHeight;
                    const newScroll = this.scrollTop + e.deltaY;
                    
                    // Only prevent default if we're at the bounds
                    if ((newScroll < 0 || newScroll > maxScroll) && !e.shiftKey) {
                        e.preventDefault();
                    }
                }
            });

            // Touch handling variables
            let isDown = false;
            let startX;
            let startY;
            let scrollLeft;
            let scrollTop;
            let initialScrollLeft;
            let initialScrollTop;
            let isScrollingHorizontally = null;

            // Touch event handlers for the table
            tableWrapper.addEventListener('touchstart', function(e) {
                isDown = true;
                startX = e.touches[0].pageX - this.offsetLeft;
                startY = e.touches[0].pageY - this.offsetTop;
                scrollLeft = this.scrollLeft;
                scrollTop = this.scrollTop;
                initialScrollLeft = this.scrollLeft;
                initialScrollTop = this.scrollTop;
                isScrollingHorizontally = null;
            });

            tableWrapper.addEventListener('touchmove', function(e) {
                if (!isDown) return;

                const x = e.touches[0].pageX - this.offsetLeft;
                const y = e.touches[0].pageY - this.offsetTop;
                const walkX = (x - startX) * 1.5;
                const walkY = (y - startY) * 1.5;

                // Determine scroll direction if not yet determined
                if (isScrollingHorizontally === null) {
                    isScrollingHorizontally = Math.abs(walkX) > Math.abs(walkY);
                }

                if (isScrollingHorizontally) {
                    e.preventDefault();
                    this.scrollLeft = scrollLeft - walkX;
                    scrollContainer.scrollLeft = this.scrollLeft;
                } else {
                    this.scrollTop = scrollTop - walkY;
                }
            });

            tableWrapper.addEventListener('touchend', function() {
                isDown = false;
                isScrollingHorizontally = null;
            });

            // Touch event handlers for the top scrollbar
            scrollContainer.addEventListener('touchstart', function(e) {
                isDown = true;
                startX = e.touches[0].pageX - this.offsetLeft;
                scrollLeft = this.scrollLeft;
            });

            scrollContainer.addEventListener('touchmove', function(e) {
                if (!isDown) return;
                e.preventDefault();
                const x = e.touches[0].pageX - this.offsetLeft;
                const walk = (x - startX) * 1.5;
                this.scrollLeft = scrollLeft - walk;
                tableWrapper.scrollLeft = this.scrollLeft;
            });

            scrollContainer.addEventListener('touchend', function() {
                isDown = false;
            });
        });
        
        // Tables and operators data from PHP
        const tables = <?php echo $tablesJson; ?>;
        const operators = <?php echo $operatorsJson; ?>;
        
        // Initialize table select
        function initializeFilters() {
            const tableSelect = document.getElementById('filterTable');
            Object.keys(tables).forEach(table => {
                const option = document.createElement('option');
                option.value = table;
                option.textContent = table;
                tableSelect.appendChild(option);
            });
            
            // Initialize operator select
            const operatorSelect = document.getElementById('filterOperator');
            Object.entries(operators).forEach(([value, label]) => {
                const option = document.createElement('option');
                option.value = value;
                option.textContent = label;
                operatorSelect.appendChild(option);
            });
        }
        
        // Update columns when table is selected
        function updateColumns() {
            const tableSelect = document.getElementById('filterTable');
            const columnSelect = document.getElementById('filterColumn');
            const operatorSelect = document.getElementById('filterOperator');
            const valueInput = document.getElementById('filterValue');
            const addFilterBtn = document.getElementById('addFilterBtn');
            
            columnSelect.innerHTML = '<option value="">Select Column</option>';
            columnSelect.disabled = !tableSelect.value;
            operatorSelect.disabled = true;
            valueInput.disabled = true;
            addFilterBtn.disabled = true;
            
            if (tableSelect.value) {
                tables[tableSelect.value].forEach(column => {
                    const option = document.createElement('option');
                    option.value = column;
                    option.textContent = column;
                    columnSelect.appendChild(option);
                });
            }
        }
        
        // Enable operator select when column is selected
        document.getElementById('filterColumn').addEventListener('change', function() {
            const operatorSelect = document.getElementById('filterOperator');
            operatorSelect.disabled = !this.value;
            document.getElementById('filterValue').disabled = true;
            document.getElementById('addFilterBtn').disabled = true;
        });
        
        // Update value input based on operator
        document.getElementById('filterOperator').addEventListener('change', function() {
            const valueContainer = document.getElementById('filterValueContainer');
            const addFilterBtn = document.getElementById('addFilterBtn');
            
            if (!this.value) {
                valueContainer.innerHTML = '<input type="text" id="filterValue" placeholder="Enter value" disabled>';
                addFilterBtn.disabled = true;
                return;
            }
            
            let valueInput = '';
            switch(this.value) {
                case 'IN':
                    valueInput = '<textarea id="filterValue" placeholder="Enter values (one per line)"></textarea>';
                    break;
                case 'BETWEEN':
                    valueInput = `
                        <div class="range-inputs">
                            <input type="text" id="filterValueMin" placeholder="Min value">
                            <input type="text" id="filterValueMax" placeholder="Max value">
                        </div>`;
                    break;
                default:
                    valueInput = '<input type="text" id="filterValue" placeholder="Enter value">';
            }
            
            valueContainer.innerHTML = valueInput;
            document.querySelectorAll('#filterValueContainer input, #filterValueContainer textarea')
                .forEach(el => el.disabled = false);
            addFilterBtn.disabled = false;
        });
        
        // Store active filters
        let activeFilters = [];
        
        // Add filter to the list
        function addFilter() {
            const table = document.getElementById('filterTable').value;
            const column = document.getElementById('filterColumn').value;
            const operator = document.getElementById('filterOperator').value;
            let value;
            
            switch(operator) {
                case 'IN':
                    value = document.getElementById('filterValue').value
                        .split('\n')
                        .map(v => v.trim())
                        .filter(v => v);
                    break;
                case 'BETWEEN':
                    const min = document.getElementById('filterValueMin').value.trim();
                    const max = document.getElementById('filterValueMax').value.trim();
                    value = [min, max];
                    break;
                default:
                    value = document.getElementById('filterValue').value.trim();
            }
            
            if (!value || (Array.isArray(value) && value.length === 0)) {
                alert('Please enter a value');
                return;
            }
            
            const filter = {
                table,
                column,
                operator,
                value
            };
            
            activeFilters.push(filter);
            updateFilterList();
            resetFilterForm();
            
            // Show filter operation if more than one filter
            document.getElementById('filterOperation').style.display = 
                activeFilters.length > 1 ? 'block' : 'none';
        }
        
        // Update the visual filter list
        function updateFilterList() {
            const filterList = document.getElementById('filterList');
            filterList.innerHTML = '';
            
            activeFilters.forEach((filter, index) => {
                const filterItem = document.createElement('div');
                filterItem.className = 'filter-item';
                
                let valueDisplay = Array.isArray(filter.value) 
                    ? filter.value.join(', ') 
                    : filter.value;
                
                filterItem.innerHTML = `
                    <span>${filter.table}.${filter.column} ${filter.operator} ${valueDisplay}</span>
                    <i class="fas fa-times remove-filter" onclick="removeFilter(${index})"></i>
                `;
                
                filterList.appendChild(filterItem);
            });
        }
        
        // Remove filter from the list
        function removeFilter(index) {
            activeFilters.splice(index, 1);
            updateFilterList();
            
            // Hide filter operation if less than two filters
            document.getElementById('filterOperation').style.display = 
                activeFilters.length > 1 ? 'block' : 'none';
        }
        
        // Reset filter form
        function resetFilterForm() {
            document.getElementById('filterTable').value = '';
            document.getElementById('filterColumn').innerHTML = '<option value="">Select Column</option>';
            document.getElementById('filterColumn').disabled = true;
            document.getElementById('filterOperator').value = '';
            document.getElementById('filterOperator').disabled = true;
            document.getElementById('filterValueContainer').innerHTML = 
                '<input type="text" id="filterValue" placeholder="Enter value" disabled>';
            document.getElementById('addFilterBtn').disabled = true;
        }
        
        // Initialize filters on page load
        document.addEventListener('DOMContentLoaded', initializeFilters);
        
        // Override the existing sendNotification function to handle the new filter format
        async function sendNotification(event) {
            event.preventDefault();
            
            const targetType = document.getElementById('targetType').value;
            const languageMode = document.querySelector('.language-tab.active').textContent.toLowerCase().includes('single') ? 'single' : 'multi';
            
            // Prepare the request data
            const data = {};
            
            // Handle target users
            switch(targetType) {
                case 'single':
                    const nationalId = document.getElementById('nationalId').value.trim();
                    if (!nationalId) {
                        alert('Please enter a National ID');
                        return;
                    }
                    data.national_id = nationalId;
                    break;
                    
                case 'multiple':
                    const nationalIds = document.getElementById('nationalIds').value
                        .split('\n')
                        .map(id => id.trim())
                        .filter(id => id);
                    if (nationalIds.length === 0) {
                        alert('Please enter at least one National ID');
                        return;
                    }
                    data.national_ids = nationalIds;
                    break;
                    
                case 'filtered':
                    if (activeFilters.length === 0) {
                        alert('Please add at least one filter');
                        return;
                    }
                    
                    const filters = {};
                    activeFilters.forEach(filter => {
                        const key = `${filter.table}.${filter.column}`;
                        filters[key] = {
                            operator: filter.operator,
                            value: filter.value
                        };
                    });
                    
                    data.filters = filters;
                    
                    if (activeFilters.length > 1) {
                        data.filter_operation = document.getElementById('filterOperationType').value;
                    }
                    break;
            }
            
            // Handle notification content
            if (languageMode === 'single') {
                const title = document.getElementById('title').value.trim();
                const body = document.getElementById('body').value.trim();
                
                if (!title || !body) {
                    alert('Please enter both title and message');
                    return;
                }
                
                data.title = title;
                data.body = body;
            } else {
                const titleEn = document.getElementById('titleEn').value.trim();
                const bodyEn = document.getElementById('bodyEn').value.trim();
                const titleAr = document.getElementById('titleAr').value.trim();
                const bodyAr = document.getElementById('bodyAr').value.trim();
                
                if (!titleEn || !bodyEn || !titleAr || !bodyAr) {
                    alert('Please enter all multi-language fields');
                    return;
                }
                
                data.title_en = titleEn;
                data.body_en = bodyEn;
                data.title_ar = titleAr;
                data.body_ar = bodyAr;
            }
            
            // Optional fields
            const route = document.getElementById('route').value.trim();
            if (route) {
                data.route = route;
            }
            
            const additionalData = document.getElementById('additionalData').value.trim();
            if (additionalData) {
                try {
                    data.additionalData = JSON.parse(additionalData);
                } catch (e) {
                    alert('Invalid JSON in Additional Data field');
                    return;
                }
            }
            
            const expiryDate = document.getElementById('expiryDate').value;
            if (expiryDate) {
                data.expiry_at = expiryDate;
            }
            
            // Format the request data
            const formattedData = JSON.stringify(data, null, 2);
            
            // Show the request data in an alert
            alert('Request Data:\n' + formattedData);
            
            // Copy to clipboard
            try {
                await navigator.clipboard.writeText(formattedData);
                console.log('Request data copied to clipboard');
            } catch (err) {
                console.error('Failed to copy to clipboard:', err);
                
                // Fallback method for clipboard copy
                const textarea = document.createElement('textarea');
                textarea.value = formattedData;
                document.body.appendChild(textarea);
                textarea.select();
                try {
                    document.execCommand('copy');
                    console.log('Request data copied to clipboard (fallback)');
                } catch (err) {
                    console.error('Failed to copy to clipboard (fallback):', err);
                }
                document.body.removeChild(textarea);
            }
            
            try {
                const response = await fetch('https://icreditdept.com/api/send_notification.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'api-key': '7ca7427b418bdbd0b3b23d7debf69bf7'
                    },
                    body: JSON.stringify(data)
                });
                
                const result = await response.json();
                
                if (result.status === 'success') {
                    alert('Notification sent successfully!');
                    closeModal();
                    window.location.reload();
                } else {
                    alert('Error: ' + result.message);
                }
            } catch (error) {
                alert('Error sending notification: ' + error.message);
            }
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('notificationModal');
            if (event.target === modal) {
                modal.style.display = 'none';
            }
        }

        function useTemplate(template) {
            // Open modal
            openModal();
            
            // Fill in the form with template data
            if (template.title) {
                document.getElementById('title').value = template.title;
            }
            if (template.body) {
                document.getElementById('body').value = template.body;
            }
            // Add more fields as needed based on your template structure
        }

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
</body>
</html>
