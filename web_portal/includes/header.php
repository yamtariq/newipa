<header class="header">
    <div class="header-content">
        <button class="menu-toggle">☰</button>
        <span class="user-info">
            Welcome, <?php echo htmlspecialchars($_SESSION['name'] ?? 'User'); ?>
        </span>
        <a href="logout.php" class="btn btn-sm btn-danger">Logout</a>
    </div>
</header>

<nav class="sidebar">
    <ul class="sidebar-menu">
        <li><a href="index.php?page=dashboard">Dashboard</a></li>
        <?php if (checkPermission('super_admin')): ?>
            <li><a href="index.php?page=customers">Manage Customers</a></li>
        <?php endif; ?>
        <?php if (checkPermission('sales_admin') || checkPermission('super_admin')): ?>
            <li><a href="index.php?page=card-applications">Card Applications</a></li>
            <li><a href="index.php?page=loan-applications">Loan Applications</a></li>
        <?php endif; ?>
        <?php if (checkPermission('credit_admin') || checkPermission('super_admin')): ?>
            <li><a href="index.php?page=applications-review">Review Applications</a></li>
        <?php endif; ?>
        <?php if (checkPermission('config_admin') || checkPermission('super_admin')): ?>
            <li><a href="index.php?page=config">System Configuration</a></li>
        <?php endif; ?>
    </ul>
</nav>
