<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit();
}

require_once 'db_connect.php';

// Get counts from database
$loanCount = 0;
$cardCount = 0;
$userCount = 0;

// Get loan applications count
$query = "SELECT COUNT(*) as count FROM loan_application_details";
$result = $conn->query($query);
if ($result) {
    $loanCount = $result->fetch_assoc()['count'];
}

// Get card applications count
$query = "SELECT COUNT(*) as count FROM card_application_details";
$result = $conn->query($query);
if ($result) {
    $cardCount = $result->fetch_assoc()['count'];
}

// Get users count
$query = "SELECT COUNT(*) as count FROM portal_employees";
$result = $conn->query($query);
if ($result) {
    $userCount = $result->fetch_assoc()['count'];
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Nayifat Admin Dashboard</title>
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
            background-color: #f8fafc;
            color: var(--text-color);
            position: relative;
        }

        .sidebar {
            width: var(--sidebar-width);
            background: #fff;
            color: var(--text-color);
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
            background: var(--secondary-color);
            transform: scale(1.05);
        }

        .main-content {
            flex: 1;
            padding: 2rem;
            margin-left: var(--sidebar-width);
            transition: margin-left 0.3s ease;
            background-color: #f8fafc;
            min-height: 100vh;
            width: calc(100% - var(--sidebar-width));
            position: relative;
            z-index: 1;
        }

        .sidebar.collapsed + .main-content {
            margin-left: var(--sidebar-width-collapsed);
            width: calc(100% - var(--sidebar-width-collapsed));
        }

        .stats-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
            position: relative;
            z-index: 1;
        }

        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 1rem;
            box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
            border: 1px solid #e2e8f0;
        }

        .stat-card:hover {
            transform: translateY(-2px);
            border-color: var(--accent-color);
            box-shadow: 0 4px 6px -1px rgba(10, 113, 163, 0.1);
        }

        .stat-card h3 {
            color: #64748b;
            font-size: 0.875rem;
            font-weight: 500;
            margin-bottom: 0.5rem;
        }

        .stat-card .number {
            color: var(--primary-color);
            font-size: 1.75rem;
            font-weight: 700;
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

            .stats-container {
                grid-template-columns: 1fr;
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
            <a href="index.php" class="nav-link active">
                <i class="fas fa-home"></i>
                <span>Dashboard</span>
            </a>
            <a href="pages/loan-applications.php" class="nav-link">
                <i class="fas fa-file-alt"></i>
                <span>Loan Applications</span>
            </a>
            <a href="pages/card-applications.php" class="nav-link">
                <i class="fas fa-credit-card"></i>
                <span>Card Applications</span>
            </a>
            <a href="pages/users.php" class="nav-link">
                <i class="fas fa-users"></i>
                <span>Users</span>
            </a>
            <a href="pages/master-config.php" class="nav-link">
                <i class="fas fa-cogs"></i>
                <span>Master Config</span>
            </a>
            <a href="pages/push-notification.php" class="nav-link">
                <i class="fas fa-bell"></i>
                <span>Push Notifications</span>
            </a>
            <a href="logout.php" class="nav-link">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
        </nav>
    </div>

    <button class="toggle-sidebar" id="toggleSidebar">
        <i class="fas fa-bars"></i>
    </button>

    <div class="main-content">
        <?php if (isset($_SESSION['login_message'])): ?>
            <div class="welcome-message" style="
                background: #e6f3f8;
                padding: 1rem;
                border-radius: 0.5rem;
                margin-bottom: 2rem;
                border: 1px solid #b3e5fc;
                color: #0A71A3;
                display: flex;
                align-items: center;
                gap: 0.75rem;
            ">
                <i class="fas fa-check-circle"></i>
                <span><?php echo $_SESSION['login_message']; ?></span>
            </div>
            <?php unset($_SESSION['login_message']); ?>
        <?php endif; ?>
        
        <div class="stats-container">
            <div class="stat-card">
                <h3>Total Loan Applications</h3>
                <div class="number"><?php echo $loanCount; ?></div>
            </div>
            <div class="stat-card">
                <h3>Total Card Applications</h3>
                <div class="number"><?php echo $cardCount; ?></div>
            </div>
            <div class="stat-card">
                <h3>Total Users</h3>
                <div class="number"><?php echo $userCount; ?></div>
            </div>
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
    </script>
</body>
</html>
