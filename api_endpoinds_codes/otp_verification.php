<?php
// otp_verification.php
header('Content-Type: application/json');
require 'db_connect.php';
require 'audit_log.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Enable debugging for development
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);

    // Check for the API key in the request header
    $headers = getallheaders();
    if (!isset($headers['api-key'])) {
        log_audit($con, null, 'OTP Verification Failed', 'API key is missing');
        echo json_encode(['status' => 'error', 'message' => 'API key is missing']);
        exit();
    }

    $api_key = $con->real_escape_string($headers['api-key']);

    // Validate the API key
    $current_time = date('Y-m-d H:i:s');
    $query = "SELECT * FROM API_Keys WHERE api_Key = ? AND (expires_at IS NULL OR expires_at > ?)";
    $stmt = $con->prepare($query);
    if (!$stmt) {
        echo json_encode(['status' => 'error', 'message' => 'SQL error in API key validation', 'debug' => $con->error]);
        exit();
    }
    $stmt->bind_param("ss", $api_key, $current_time);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        log_audit($con, null, 'OTP Verification Failed', 'Invalid or expired API key');
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired API key']);
        exit();
    }

    // Retrieve data from POST request
    $national_id = isset($_POST['national_id']) ? $con->real_escape_string($_POST['national_id']) : null;
    $otp_code = isset($_POST['otp_code']) ? $con->real_escape_string($_POST['otp_code']) : null;

    if (!$national_id || !$otp_code) {
        log_audit($con, null, 'OTP Verification Failed', 'national_id or OTP code is missing');
        echo json_encode(['status' => 'error', 'message' => 'national_id and OTP code are required']);
        exit();
    }

    // Hash the OTP code before verification
    $hashed_otp = hash('sha256', $otp_code);

    // Verify the OTP
    $query = "SELECT otp_id, expires_at FROM OTP_Codes 
              WHERE national_id = ? AND otp_code = ? AND is_used = 0 AND expires_at > ?";
    $stmt = $con->prepare($query);
    if (!$stmt) {
        echo json_encode(['status' => 'error', 'message' => 'SQL error in OTP verification', 'debug' => $con->error]);
        exit();
    }
    $stmt->bind_param("sss", $national_id, $hashed_otp, $current_time);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        log_audit($con, $national_id, 'OTP Verification Failed', 'Invalid or expired OTP for national_id: ' . $national_id);

        // Include debug information for development purposes
        echo json_encode([
            'status' => 'error',
            'message' => 'Invalid or expired OTP',
            'debug' => [
                'national_id' => $national_id,
                'otp_code' => $otp_code
            ]
        ]);
        exit();
    }

    $row = $result->fetch_assoc();
    $otp_id = $row['otp_id'];
    $expires_at = $row['expires_at'];

    // Check if the OTP has expired
    if ($expires_at !== null && strtotime($expires_at) < time()) {
        log_audit($con, null, 'OTP Verification Failed', 'OTP expired for national_id: ' . $national_id);
        echo json_encode(['status' => 'error', 'message' => 'OTP has expired']);
        exit();
    }

    // Mark the OTP as used
    $update_query = "UPDATE OTP_Codes SET is_used = TRUE WHERE otp_id = ?";
    $update_stmt = $con->prepare($update_query);
    if (!$update_stmt) {
        echo json_encode(['status' => 'error', 'message' => 'SQL error in marking OTP as used', 'debug' => $con->error]);
        exit();
    }
    $update_stmt->bind_param("i", $otp_id);
    if ($update_stmt->execute()) {
        log_audit($con, null, 'OTP Verification Successful', 'OTP verified successfully for national_id: ' . $national_id);
        echo json_encode(['status' => 'success', 'message' => 'OTP verified successfully']);
    } else {
        log_audit($con, null, 'OTP Verification Failed', 'Failed to mark OTP as used for national_id: ' . $national_id);
        echo json_encode(['status' => 'error', 'message' => 'Failed to mark OTP as used']);
    }

} else {
    log_audit($con, null, 'OTP Verification Failed', 'Invalid request method');
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
}

$con->close();
?>
