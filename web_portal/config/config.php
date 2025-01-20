<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_USER', 'icredept_tariq');
define('DB_PASS', 'tariq');
define('DB_NAME', 'icredept_nayifat_app');

// Session configuration
ini_set('session.cookie_lifetime', 86400); // 24 hours
ini_set('session.gc_maxlifetime', 86400);  // 24 hours
ini_set('session.cookie_domain', '.icreditdept.com');
ini_set('session.cookie_path', '/');
ini_set('session.cookie_secure', true);
ini_set('session.cookie_httponly', true);
ini_set('session.use_strict_mode', true);
ini_set('session.use_only_cookies', true);
ini_set('session.cache_limiter', 'nocache');
ini_set('session.cache_expire', 180);

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Establish database connection
try {
    $conn = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME,
        DB_USER,
        DB_PASS,
        array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8'")
    );
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    error_log("Connection Error: " . $e->getMessage());
    exit();
}

// Define user roles
define('ROLE_SUPER_ADMIN', 'super_admin');
define('ROLE_SALES_ADMIN', 'sales_admin');
define('ROLE_CREDIT_ADMIN', 'credit_admin');
define('ROLE_CONFIG_ADMIN', 'config_admin');

// Application settings
define('APP_NAME', 'Nayifat Admin Portal');
define('APP_URL', 'https://icreditdept.com/api/portal/');

// Set timezone
date_default_timezone_set('Asia/Riyadh');
?>
