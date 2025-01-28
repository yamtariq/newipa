<div class="sidebar">
    <h3>Welcome, <?php echo $_SESSION['name']; ?></h3>
    <nav>
        <a href="../pages/customers.php" class="nav-link">Manage Customers</a>
        <a href="../pages/card-applications.php" class="nav-link">Card Applications</a>
        <a href="../pages/loan-applications.php" class="nav-link">Loan Applications</a>
        <a href="../pages/push-notification.php" class="nav-link">Push Notification</a>
        <a href="../pages/config.php" class="nav-link">System Config</a>
        <a href="../logout.php" class="nav-link">Logout</a>
    </nav>
</div>

<style>
.sidebar {
    width: 250px;
    background-color: #2c3e50;
    color: white;
    padding: 20px;
    flex-shrink: 0;
    height: 100vh;
    position: fixed;
}

.sidebar h3 {
    margin-bottom: 20px;
    color: #ecf0f1;
}

.nav-link {
    display: block;
    color: #ecf0f1;
    text-decoration: none;
    padding: 10px 0;
    margin-bottom: 5px;
}

.nav-link:hover {
    color: #3498db;
}

.main-content {
    margin-left: 250px;
    padding: 20px;
    background-color: #f5f6fa;
    min-height: 100vh;
}
</style>
