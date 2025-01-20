<?php
// Set the default timezone to UTC
date_default_timezone_set('UTC');

// Prevent caching of the response
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

// Set the content type to JSON
header('Content-Type: application/json');

// Include necessary files
require 'db_connect.php';
require 'audit_log.php';

// Function to generate a secure OTP
function generate_otp($length = 6) {
    $min = pow(10, $length - 1);
    $max = pow(10, $length) - 1;
    return random_int($min, $max);
}

// Handle only POST requests
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Retrieve all request headers
    $headers = getallheaders();

    // Check for the presence of the 'api-key' header
    if (!isset($headers['api-key'])) {
        log_audit($con, null, 'OTP Generation Failed', 'API key is missing');
        echo json_encode(['status' => 'error', 'message' => 'API key is missing']);
        exit();
    }

    // Sanitize the API key
    $api_key = $con->real_escape_string($headers['api-key']);

    // Validate the API key against the database
    $query = "SELECT * FROM API_Keys WHERE api_key = ? AND (expires_at IS NULL OR expires_at > ?)";
    $stmt = $con->prepare($query);
    $current_time = date('Y-m-d H:i:s'); // PHP's current time in UTC
    $stmt->bind_param("ss", $api_key, $current_time);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        log_audit($con, null, 'OTP Generation Failed', 'Invalid or expired API key');
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired API key']);
        exit();
    }

    // Retrieve and sanitize the 'national_id' from POST data
    $national_id = isset($_POST['national_id']) ? $con->real_escape_string($_POST['national_id']) : null;

    if (!$national_id) {
        log_audit($con, null, 'OTP Generation Failed', 'national_id is missing');
        echo json_encode(['status' => 'error', 'message' => 'national_id is required']);
        exit();
    }

    // Rate Limiting: Check if an unexpired OTP exists for the national_id
    $query = "SELECT expires_at FROM OTP_Codes WHERE national_id = ? AND expires_at > ? ORDER BY expires_at DESC LIMIT 1";
    $stmt = $con->prepare($query);
    $stmt->bind_param("ss", $national_id, $current_time);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $db_expires_at = $row['expires_at'];

        log_audit($con, $national_id, 'OTP Generation Failed', 'Rate limit exceeded for national_id: ' . $national_id);
        echo json_encode([
            'status' => 'error',
            'message' => 'OTP request rate limit exceeded. Please wait before requesting again.',
            
        ]);
        exit();
    }

    // Generate a secure 6-digit OTP
    $otp_code = generate_otp(6);

    // Hash the OTP for secure storage
    $hashed_otp = hash('sha256', $otp_code);

    // Set the OTP expiration time to 5 minutes from now
    $expires_at = date('Y-m-d H:i:s', strtotime('+5 minutes'));

    // Insert the OTP into the database
    $stmt = $con->prepare("INSERT INTO OTP_Codes (otp_code, expires_at, is_used, national_id) VALUES (?, ?, 0, ?)");
    $stmt->bind_param("sss", $hashed_otp, $expires_at, $national_id);

    if ($stmt->execute()) {
        // Log the successful OTP generation
        log_audit($con, $national_id, 'OTP Generation Successful', 'OTP generated and sent to user phone');

        // Respond with the OTP (In production, **do not** send the OTP in the response)
        echo json_encode([
            'status' => 'success',
            'message' => 'OTP generated successfully and sent to the user phone',
            'otp_code' => $otp_code, // **Remove in Production**
            
        ]);
    } else {
        // Log the failure to generate OTP
        log_audit($con, $national_id, 'OTP Generation Failed', 'Failed to generate OTP');
        echo json_encode(['status' => 'error', 'message' => 'Failed to generate OTP']);
    }

    // Close the statement
    $stmt->close();
} else {
    // Log invalid request methods
    log_audit($con, null, 'OTP Generation Failed', 'Invalid request method');
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
}

// Close the database connection
$con->close();
?>
