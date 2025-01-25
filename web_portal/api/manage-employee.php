<?php
require_once '../db_connect.php';
session_start();

if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Debug log
    error_log("POST data received: " . print_r($_POST, true));
    
    $name = $_POST['name'];
    $email = $_POST['email'];
    $status = isset($_POST['status']) ? $_POST['status'] : 'active';
    $role = isset($_POST['role']) ? $_POST['role'] : null;
    
    if (!$role) {
        echo json_encode(['success' => false, 'message' => 'Role is required']);
        exit();
    }
    
    $acting_employee_id = $_SESSION['user_id']; // Get the ID of the user performing the action
    
    // Check if we're updating an existing record
    if (isset($_POST['employee_id']) && !empty($_POST['employee_id'])) {
        $employee_id = $_POST['employee_id'];
        
        // Build the update query dynamically based on whether password is being updated
        if (isset($_POST['password']) && !empty($_POST['password'])) {
            $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
            $stmt = $conn->prepare("UPDATE portal_employees SET name=?, email=?, password=?, role=?, status=? WHERE employee_id=?");
            $stmt->bind_param("sssssi", $name, $email, $password, $role, $status, $employee_id);
            $password_updated = true;
        } else {
            $stmt = $conn->prepare("UPDATE portal_employees SET name=?, email=?, role=?, status=? WHERE employee_id=?");
            $stmt->bind_param("ssssi", $name, $email, $role, $status, $employee_id);
            $password_updated = false;
        }

        if ($stmt->execute()) {
            // Log the update action
            $action = "UPDATE_EMPLOYEE";
            $details = json_encode([
                'target_employee_id' => $employee_id,
                'changes' => [
                    'name' => $name,
                    'email' => $email,
                    'role' => $role,
                    'status' => $status,
                    'password_updated' => $password_updated
                ]
            ]);
            
            $log_stmt = $conn->prepare("INSERT INTO portal_activity_log (employee_id, action, details, ip_address) VALUES (?, ?, ?, ?)");
            $ip_address = $_SERVER['REMOTE_ADDR'];
            $log_stmt->bind_param("isss", $acting_employee_id, $action, $details, $ip_address);
            $log_stmt->execute();
            
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'message' => $conn->error]);
        }
    } 
    // Adding a new record
    else {
        if (!isset($_POST['password']) || empty($_POST['password'])) {
            echo json_encode(['success' => false, 'message' => 'Password is required for new employees']);
            exit();
        }
        
        $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
        $stmt = $conn->prepare("INSERT INTO portal_employees (name, email, password, role, status, created_at) VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)");
        $stmt->bind_param("sssss", $name, $email, $password, $role, $status);

        if ($stmt->execute()) {
            $new_employee_id = $conn->insert_id;
            
            // Log the create action
            $action = "CREATE_EMPLOYEE";
            $details = json_encode([
                'target_employee_id' => $new_employee_id,
                'employee_data' => [
                    'name' => $name,
                    'email' => $email,
                    'role' => $role,
                    'status' => $status
                ]
            ]);
            
            $log_stmt = $conn->prepare("INSERT INTO portal_activity_log (employee_id, action, details, ip_address) VALUES (?, ?, ?, ?)");
            $ip_address = $_SERVER['REMOTE_ADDR'];
            $log_stmt->bind_param("isss", $acting_employee_id, $action, $details, $ip_address);
            $log_stmt->execute();
            
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'message' => $conn->error]);
        }
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
