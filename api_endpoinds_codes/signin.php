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
    if (empty($data['national_id'])) {
        throw new Exception('Missing required field: national_id');
    }

    $national_id = $con->real_escape_string($data['national_id']);
    $deviceId = isset($data['deviceId']) ? $con->real_escape_string($data['deviceId']) : null;
    $isPasswordAuth = isset($data['password']);
    $password = $isPasswordAuth ? $data['password'] : null;

    // 1. Check if user exists
    $stmt = $con->prepare("
        SELECT * FROM Customers WHERE national_id = ?
    ");
    $stmt->bind_param("s", $national_id);
    $stmt->execute();
    $user_result = $stmt->get_result();

    if ($user_result->num_rows === 0) {
        log_auth_attempt($con, $national_id, $deviceId, 'failed', 'Customer not found');
        echo json_encode([
            'status' => 'error',
            'code' => 'CUSTOMER_NOT_FOUND',
            'message' => 'Invalid credentials'
        ]);
        exit();
    }

    $customer = $user_result->fetch_assoc();

    // Determine authentication method after confirming customer exists
    if ($isPasswordAuth) {
        // Password authentication flow
        if ($customer['password'] !== null) {
            if (!password_verify($password, $customer['password'])) {
                log_auth_attempt($con, $national_id, $deviceId, 'failed', 'Invalid password');
                echo json_encode([
                    'status' => 'error',
                    'code' => 'INVALID_PASSWORD',
                    'message' => 'Invalid credentials'
                ]);
                exit();
            }
        }
    } else {
        // OTP authentication flow - only start after customer verification
        echo json_encode([
            'status' => 'success',
            'code' => 'CUSTOMER_VERIFIED',
            'message' => 'Customer verified, proceed with OTP',
            'require_otp' => true
        ]);
        exit();
    }

    // If we reach here, password authentication is successful
    // Generate token regardless of device
    $token = bin2hex(random_bytes(32));

    // Update last used timestamp for device if provided
    if ($deviceId) {
        $stmt = $con->prepare("
            UPDATE customer_devices 
            SET last_used_at = NOW()
            WHERE national_id = ? AND deviceId = ?
        ");
        $stmt->bind_param("ss", $national_id, $deviceId);
        $stmt->execute();
    }

    // Log successful login
    log_auth_attempt($con, $national_id, $deviceId, 'success');

    // Return token and user data
    echo json_encode([
        'status' => 'success',
        'token' => $token,
        'user' => $customer
    ]);

} catch (Exception $e) {
    error_log("Signin error: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'code' => 'SYSTEM_ERROR',
        'message' => $e->getMessage()
    ]);
    exit();
}

$con->close();
?>