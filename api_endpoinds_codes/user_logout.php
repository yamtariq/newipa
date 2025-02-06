<?php
header('Content-Type: application/json');
require 'db_connect.php';
require 'audit_log.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Check for the API key and session token in the request header
    $headers = getallheaders();
    if (!isset($headers['api-key']) || !isset($headers['session-token'])) {
        log_audit($con, null, 'User Logout Failed', 'API key or session token is missing');
        echo json_encode(['status' => 'error', 'message' => 'API key or session token is missing']);
        exit();
    }

    $api_key = $con->real_escape_string($headers['api-key']);
    $session_token = $con->real_escape_string($headers['session-token']);

    // Validate the API key
    $current_time = date('Y-m-d H:i:s');
    
    $query = "SELECT * FROM API_Keys WHERE api_Key = ? AND (expires_at IS NULL OR expires_at > ?)";
    $stmt = $con->prepare($query);
    $stmt->bind_param("ss", $api_key, $current_time);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        log_audit($con, null, 'User Logout Failed', 'Invalid or expired API key');
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired API key']);
        exit();
    }

    // Validate the session token and check expiration
    $query = "SELECT * FROM Sessions WHERE session_token = ? AND expires_at > ?";
    $stmt = $con->prepare($query);
    $stmt->bind_param("ss", $session_token, $current_time);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        log_audit($con, null, 'User Logout Failed', 'Invalid or expired session token');
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired session token']);
        exit();
    }

    // Invalidate the session token
    $query = "DELETE FROM Sessions WHERE session_token = ?";
    $stmt = $con->prepare($query);
    $stmt->bind_param("s", $session_token);

    if ($stmt->execute()) {
        log_audit($con, null, 'User Logout Successful', 'Session successfully terminated');
        echo json_encode(['status' => 'success', 'message' => 'Logout successful']);
    } else {
        log_audit($con, null, 'User Logout Failed', 'Failed to terminate session');
        echo json_encode(['status' => 'error', 'message' => 'Failed to logout']);
    }

    $stmt->close();
} else {
    log_audit($con, null, 'User Logout Failed', 'Invalid request method');
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
}

$con->close();
?>
