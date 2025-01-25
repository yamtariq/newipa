<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header('Content-Type: application/json');

require 'db_connect.php';
require 'audit_log.php';

function log_auth_attempt($con, $national_id, $deviceId, $status, $failure_reason = null) {
    $stmt = $con->prepare("
        INSERT INTO auth_logs (
            national_id, deviceId, auth_type, status, 
            ip_address, user_agent, failure_reason
        ) VALUES (?, ?, 'password', ?, ?, ?, ?)
    ");
    $ip = $_SERVER['REMOTE_ADDR'];
    $user_agent = $_SERVER['HTTP_USER_AGENT'];
    $stmt->bind_param("ssssss", $national_id, $deviceId, $status, $ip, $user_agent, $failure_reason);
    $stmt->execute();
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    // Parse input data
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data) {
        throw new Exception('Invalid JSON input');
    }

    // Validate required fields
    if (empty($data['national_id']) || empty($data['deviceId'])) {
        throw new Exception('Missing required fields');
    }

    $national_id = $con->real_escape_string($data['national_id']);
    $deviceId = $con->real_escape_string($data['deviceId']);
    $isPasswordAuth = isset($data['password']);
    $password = $isPasswordAuth ? $data['password'] : null;

    // 1. Check if user exists
    $stmt = $con->prepare("
        SELECT * FROM Users WHERE national_id = ?
    ");
    $stmt->bind_param("s", $national_id);
    $stmt->execute();
    $user_result = $stmt->get_result();

    if ($user_result->num_rows === 0) {
        log_auth_attempt($con, $national_id, $deviceId, 'failed', 'User not found');
        echo json_encode([
            'status' => 'error',
            'code' => 'USER_NOT_FOUND',
            'message' => 'Invalid credentials'
        ]);
        exit();
    }

    $user = $user_result->fetch_assoc();

    // 2. If password authentication, verify password
    if ($isPasswordAuth) {
        if (!password_verify($password, $user['password'])) {
            log_auth_attempt($con, $national_id, $deviceId, 'failed', 'Invalid password');
            echo json_encode([
                'status' => 'error',
                'code' => 'INVALID_PASSWORD',
                'message' => 'Invalid credentials'
            ]);
            exit();
        }
    }

    // If we reach here, authentication is successful
    // Expire existing sessions
    $stmt = $con->prepare("
        UPDATE user_sessions 
        SET status = 'expired', expires_at = NOW() 
        WHERE national_id = ? AND deviceId = ? AND status = 'active'
    ");
    $stmt->bind_param("ss", $national_id, $deviceId);
    $stmt->execute();

    // Create new session
    $token = bin2hex(random_bytes(32));
    $stmt = $con->prepare("
        INSERT INTO user_sessions (
            national_id, deviceId, session_token, 
            created_at, expires_at, status
        ) VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 'active')
    ");
    $stmt->bind_param("sss", $national_id, $deviceId, $token);
    $stmt->execute();

    // Update last used timestamp for device
    $stmt = $con->prepare("
        UPDATE user_devices 
        SET last_used_at = NOW()
        WHERE national_id = ? AND deviceId = ?
    ");
    $stmt->bind_param("ss", $national_id, $deviceId);
    $stmt->execute();

    // Log successful login
    log_auth_attempt($con, $national_id, $deviceId, 'success');

    // Return token and user data
    echo json_encode([
        'status' => 'success',
        'token' => $token,
        'user' => $user
    ]);

} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'code' => 'SYSTEM_ERROR',
        'message' => 'An unexpected error occurred'
    ]);
    exit();
}

$con->close();
?>