<?php
require_once 'db_connect.php';

function authenticate($email, $password) {
    global $conn;
    
    try {
        // MySQLi prepared statement
        $stmt = $conn->prepare("
            SELECT employee_id, name, email, password, role
            FROM portal_employees
            WHERE email = ?
              AND status = 'active'
            LIMIT 1
        ");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
            $user = $result->fetch_assoc();
            
            // Plain text password check
            if ($password === $user['password']) {
                
                // Update last login timestamp
                $update = $conn->prepare("
                    UPDATE portal_employees
                    SET last_login = NOW()
                    WHERE employee_id = ?
                ");
                $update->bind_param("i", $user['employee_id']);
                $update->execute();
                
                // Optional: log the login event
                logActivity($user['employee_id'], 'login', 'User logged in');
                
                return $user;
            }
        }
        return false;
    } catch (mysqli_sql_exception $e) {
        error_log("Database Error: " . $e->getMessage());
        return false;
    }
}

function logout() {
    if (isset($_SESSION['user_id'])) {
        $userId = $_SESSION['user_id'];
        $logType = ($_SESSION['role'] === 'admin') ? 'admin' : 'user';
        logActivity($userId, 'logout', "$logType logged out");
    }
    
    session_destroy();
    header('Location: login.php');
    exit();
}

function logActivity($userId, $action, $details = '') {
    global $conn;
    try {
        $stmt = $conn->prepare("
            INSERT INTO portal_activity_log (employee_id, action, details, ip_address)
            VALUES (?, ?, ?, ?)
        ");
        $ip = $_SERVER['REMOTE_ADDR'] ?? 'Unknown IP';
        $stmt->bind_param("isss", $userId, $action, $details, $ip);
        $stmt->execute();
    } catch (mysqli_sql_exception $e) {
        error_log("Activity Log Error: " . $e->getMessage());
    }
}
?>
