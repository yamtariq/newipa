<?php
header('Content-Type: application/json');
require 'db_connect.php';
require 'audit_log.php'; // Include the audit log functionality

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Fetch headers and validate API key
        $headers = getallheaders();
        if (!isset($headers['api-key'])) {
            log_audit($con, null, 'Get Government Data Failed', 'API key is missing');
            echo json_encode(['status' => 'error', 'message' => 'API key is missing']);
            exit();
        }

        $api_key = $con->real_escape_string($headers['api-key']);
        $query = "SELECT * FROM API_Keys WHERE api_Key = ? AND (expires_at IS NULL OR expires_at > NOW())";
        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $api_key);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            log_audit($con, null, 'Get Government Data Failed', 'Invalid or expired API key');
            echo json_encode(['status' => 'error', 'message' => 'Invalid or expired API key']);
            exit();
        }

        // Check if national_id is provided
        if (!isset($_GET['national_id'])) {
            log_audit($con, null, 'Get Government Data Failed', 'National ID parameter is required');
            echo json_encode(['status' => 'error', 'message' => 'National ID parameter is required']);
            exit();
        }

        $national_id = $con->real_escape_string($_GET['national_id']);

        // Query the GovernmentServices table with all fields
        $query = "SELECT 
            national_id,
            full_name,
            arabic_name,
            dob,
            salary,
            employment_status,
            employer_name,
            employment_date,
            national_address,
            updated_at
        FROM GovernmentServices 
        WHERE national_id = ?";

        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $national_id);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $gov_data = $result->fetch_assoc();
            
            // Format the response
            $response = [
                'status' => 'success',
                'data' => $gov_data
            ];
            
            log_audit($con, $national_id, 'Get Government Data Success', 'Record retrieved successfully');
            echo json_encode($response);
        } else {
            log_audit($con, $national_id, 'Get Government Data Failed', 'Record not found');
            echo json_encode([
                'status' => 'error',
                'message' => 'Record not found for the provided national ID',
                'national_id' => $national_id
            ]);
        }
    } else {
        // Handle invalid request method
        log_audit($con, null, 'Get Government Data Failed', 'Invalid request method');
        echo json_encode(['status' => 'error', 'message' => 'Invalid request method']);
    }
} catch (Exception $e) {
    // Catch any unexpected exceptions
    log_audit($con, null, 'Get Government Data Failed', 'An unexpected error occurred');
    echo json_encode(['status' => 'error', 'message' => 'An unexpected error occurred', 'error' => $e->getMessage()]);
} finally {
    // Ensure the database connection is closed
    if (isset($con) && $con) {
        $con->close();
    }
}
?>
