<?php
function authenticate($email, $password) {
    global $conn;
    
    try {
        $stmt = $conn->prepare("
            SELECT * FROM portal_employees 
            WHERE email = :email AND status = 'active' 
            LIMIT 1
        ");
        $stmt->bindParam(':email', $email);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            $employee = $stmt->fetch(PDO::FETCH_ASSOC);
            if (password_verify($password, $employee['password'])) {
                // Update last login
                $updateStmt = $conn->prepare("
                    UPDATE portal_employees 
                    SET last_login = NOW() 
                    WHERE employee_id = :employee_id
                ");
                $updateStmt->execute(['employee_id' => $employee['employee_id']]);
                
                // Set session variables
                $_SESSION['employee_id'] = $employee['employee_id'];
                $_SESSION['name'] = $employee['name'];
                $_SESSION['email'] = $employee['email'];
                
                // Log activity
                logActivity($employee['employee_id'], 'login', 'User logged in successfully');
                
                return true;
            }
        }
        return false;
    } catch(PDOException $e) {
        error_log("Authentication Error: " . $e->getMessage());
        return false;
    }
}

function checkPermission($requiredRole) {
    if (!isset($_SESSION['employee_id'])) {
        return false;
    }
    
    global $conn;
    try {
        $stmt = $conn->prepare("
            SELECT role FROM portal_roles 
            WHERE employee_id = :employee_id AND role = :role
        ");
        $stmt->execute([
            'employee_id' => $_SESSION['employee_id'],
            'role' => $requiredRole
        ]);
        
        return $stmt->rowCount() > 0;
    } catch(PDOException $e) {
        error_log("Permission Check Error: " . $e->getMessage());
        return false;
    }
}

function logout() {
    if (isset($_SESSION['employee_id'])) {
        logActivity($_SESSION['employee_id'], 'logout', 'User logged out');
    }
    
    session_destroy();
    header('Location: login.php');
    exit();
}

function logActivity($employeeId, $action, $details = '') {
    global $conn;
    try {
        $stmt = $conn->prepare("
            INSERT INTO portal_activity_log 
            (employee_id, action, details, ip_address) 
            VALUES (:employee_id, :action, :details, :ip_address)
        ");
        
        $stmt->execute([
            'employee_id' => $employeeId,
            'action' => $action,
            'details' => $details,
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null
        ]);
    } catch(PDOException $e) {
        error_log("Activity Log Error: " . $e->getMessage());
    }
}
?>
