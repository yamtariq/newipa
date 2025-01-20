<?php
session_start();
require_once '../db_connect.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../login.php");
    exit();
}

$query = "SELECT * FROM portal_employees ORDER BY created_at DESC";
$result = $conn->query($query);
?>

<!DOCTYPE html>
<html>
<head>
    <title>Nayifat - Portal Employees</title>
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
            position: relative;
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
            margin-left: 0;
        }

        .nav-link:hover, .nav-link.active {
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

        .sidebar.collapsed + .main-content {
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

        .header-buttons {
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

        .page-title {
            color: var(--primary-color);
            font-size: 24px;
            font-weight: 600;
        }

        .employees-table {
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            overflow: hidden;
            width: 100%;
            margin-top: 20px;
        }

        .employees-table table {
            width: 100%;
            border-collapse: collapse;
        }

        .employees-table th {
            background: #f8f9fa;
            color: #1a4f7a;
            font-weight: 600;
            padding: 15px;
            text-align: left;
            border-bottom: 2px solid #e9ecef;
        }

        .employees-table td {
            padding: 15px;
            border-bottom: 1px solid #e9ecef;
            color: #444;
        }

        .employees-table tr:hover {
            background: #f8f9fa;
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
            display: inline-flex;
            align-items: center;
        }

        .action-btn.delete {
            background: #dc3545;
        }

        .action-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }

        .action-btn i {
            margin-right: 5px;
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

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        .modal-content {
            background-color: #fefefe;
            margin: 5% auto;
            padding: 25px;
            border-radius: 12px;
            width: 90%;
            max-width: 600px;
            position: relative;
            animation: slideIn 0.3s ease-out;
        }

        @keyframes slideIn {
            from { transform: translateY(-20px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
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
            color: #1a4f7a;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #1a4f7a;
            font-weight: 600;
        }

        .form-group input {
            width: 100%;
            padding: 10px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 15px;
            transition: all 0.3s ease;
        }

        .form-group input:focus {
            border-color: #1a4f7a;
            outline: none;
            box-shadow: 0 0 0 3px rgba(26, 79, 122, 0.1);
        }

        .success-message {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            animation: fadeIn 0.3s ease-out;
        }

        .error-message {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            animation: fadeIn 0.3s ease-out;
        }

        .message-icon {
            margin-right: 10px;
            font-size: 20px;
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

            .top-bar {
                padding: 15px;
                flex-direction: column;
                gap: 10px;
            }

            .employees-table {
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
            <a href="loan-applications.php" class="nav-link">
                <i class="fas fa-file-alt"></i>
                <span>Loan Applications</span>
            </a>
            <a href="card-applications.php" class="nav-link">
                <i class="fas fa-credit-card"></i>
                <span>Card Applications</span>
            </a>
            <a href="users.php" class="nav-link active">
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
            <h1 class="page-title">Portal Employees</h1>
            <div class="header-buttons">
                <button class="btn-primary" onclick="openModal()">
                    <i class="fas fa-plus"></i> Add New Employee
                </button>
                <a href="../logout.php" class="btn-danger">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </a>
            </div>
        </div>

        <?php if (isset($_SESSION['success'])): ?>
            <div class="success-message">
                <i class="fas fa-check-circle message-icon"></i>
                <?php 
                echo $_SESSION['success'];
                unset($_SESSION['success']);
                ?>
            </div>
        <?php endif; ?>

        <?php if (isset($_SESSION['error'])): ?>
            <div class="error-message">
                <i class="fas fa-exclamation-circle message-icon"></i>
                <?php 
                echo $_SESSION['error'];
                unset($_SESSION['error']);
                ?>
            </div>
        <?php endif; ?>

        <div class="employees-table">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Created At</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php while ($row = $result->fetch_assoc()): ?>
                    <tr>
                        <td><?php echo $row['id']; ?></td>
                        <td><?php echo $row['name']; ?></td>
                        <td><?php echo $row['email']; ?></td>
                        <td><?php echo ucfirst($row['role']); ?></td>
                        <td><?php echo date('Y-m-d H:i', strtotime($row['created_at'])); ?></td>
                        <td>
                            <button class="action-btn" onclick="openModal(<?php echo $row['id']; ?>)">
                                <i class="fas fa-edit"></i> Edit
                            </button>
                            <button class="action-btn delete" onclick="deleteEmployee(<?php echo $row['id']; ?>)">
                                <i class="fas fa-trash"></i> Delete
                            </button>
                        </td>
                    </tr>
                    <?php endwhile; ?>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Add/Edit Employee Modal -->
    <div id="employeeModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal()">&times;</span>
            <h2 id="modalTitle" class="page-title">Add New Employee</h2>
            <form id="employeeForm" method="POST" action="../api/manage-employee.php">
                <input type="hidden" id="employee_id" name="employee_id">
                <input type="hidden" id="action" name="action" value="add">
                
                <div class="form-group">
                    <label for="name">Name</label>
                    <input type="text" id="name" name="name" required>
                </div>

                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" required>
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password">
                    <small>(Leave empty if not changing)</small>
                </div>

                <div class="form-group">
                    <label for="role">Role</label>
                    <select id="role" name="role" required>
                        <option value="admin">Admin</option>
                        <option value="manager">Manager</option>
                        <option value="sales">Sales</option>
                        <option value="credit">Credit</option>
                    </select>
                </div>

                <button type="submit" class="action-btn">
                    <i class="fas fa-save"></i> Save Employee
                </button>
            </form>
        </div>
    </div>

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

        function openModal(employeeId = null) {
            const modal = document.getElementById('employeeModal');
            const modalTitle = document.getElementById('modalTitle');
            const form = document.getElementById('employeeForm');
            
            if (employeeId) {
                modalTitle.textContent = 'Edit Employee';
                // Populate form with employee data
                // Add your edit logic here
            } else {
                modalTitle.textContent = 'Add New Employee';
                form.reset();
            }
            
            modal.style.display = 'block';
        }

        function closeModal() {
            const modal = document.getElementById('employeeModal');
            modal.style.display = 'none';
        }

        window.onclick = function(event) {
            const modal = document.getElementById('employeeModal');
            if (event.target == modal) {
                modal.style.display = 'none';
            }
        }

        function deleteEmployee(id) {
            if (confirm('Are you sure you want to delete this employee?')) {
                fetch('../api/manage-employee.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: `action=delete&employee_id=${id}`
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        location.reload();
                    } else {
                        alert('Error deleting employee');
                    }
                })
                .catch(error => console.error('Error:', error));
            }
        }
    </script>
</body>
</html>
