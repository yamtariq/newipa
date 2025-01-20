<?php
header('Content-Type: application/json');
require 'db_connect.php';
require 'audit_log.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Check for the API key in the request header
    $headers = getallheaders();
    if (!isset($headers['api-key'])) {
        echo json_encode(['status' => 'error', 'message' => 'API key is missing']);
        exit();
    }
    
    $currentdate = date('Y-m-d H:i:s');
    
    $api_key = $con->real_escape_string($headers['api-key']);

    // Validate the API key
    $query = "SELECT * FROM API_Keys WHERE api_key = ? AND (expires_at IS NULL OR expires_at > ?)";
    $stmt = $con->prepare($query);
    $stmt->bind_param("ss", $api_key, $currentdate);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired API key']);
        exit();
    }

    // Retrieve data from POST request
    $national_id = isset($_POST['national_id']) ? $con->real_escape_string($_POST['national_id']) : null;
    $password = isset($_POST['password']) ? $_POST['password'] : null;

    // Validate required fields
    if (!$national_id || !$password) {
        log_audit($con, null, 'User Login Failed', "national_id and password are required");
        echo json_encode(['status' => 'error', 'message' => 'Both national_id and password are required']);
        exit();
    }

    // Check if the user exists
    $query = "SELECT * FROM Users WHERE national_id = ?";
    $stmt = $con->prepare($query);
    $stmt->bind_param("s", $national_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        log_audit($con, $national_id, 'User Login Failed', "Invalid national_id: $national_id");
        echo json_encode(['status' => 'error', 'message' => 'Invalid national_id or password']);
        exit();
    }

    // Fetch user data
    $user = $result->fetch_assoc();
    
    // Verify the password
    if (!password_verify($password, $user['password'])) {
        log_audit($con, $user['user_id'], 'User Login Failed', "Invalid password for national_id: $national_id");
        echo json_encode(['status' => 'error', 'message' => 'Invalid national_id or password']);
        exit();
    }

    // Generate a session token and set expiration
    $session_token = bin2hex(random_bytes(16));
    $user_id = $user['user_id'];
    $name = $user['name'];
    $arabic_name = $user['arabic_name'];
    
    $expires_at = date('Y-m-d H:i:s', strtotime('+24 hours'));

    // Store the session token with expiration
    $insertSessionQuery = "INSERT INTO Sessions (user_id, session_token, created_at, expires_at) VALUES (?, ?, ?, ?)";
    $stmt = $con->prepare($insertSessionQuery);
    $stmt->bind_param("isss", $user_id, $session_token, $currentdate, $expires_at);

    if ($stmt->execute()) {
        log_audit($con, $user_id, 'User Login Successful', "Session token: $session_token");
        echo json_encode(['status' => 'success', 'message' => 'Login successful', 'session_token' => $session_token, 'expires_at' => $expires_at, 'name' => $name, 'arabic_name' => $arabic_name]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to create session']);
    }

    $stmt->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
}

$con->close();
?>
