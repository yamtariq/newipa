<?php
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header('Content-Type: application/json');

// Include database connection
require_once 'db_connect.php';
require_once 'audit_log.php';

// Check if API key is provided in the headers
try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    // Check for API key in the request headers
    $headers = getallheaders();
    if (!isset($headers['api-key'])) {
        throw new Exception('API key is missing');
    }

    $apiKey = $headers['api-key'];

    // Validate API key
    $apiKeyStmt = $con->prepare("SELECT * FROM API_Keys WHERE api_key = ? AND (expires_at IS NULL OR expires_at > NOW())");
    $apiKeyStmt->bind_param("s", $apiKey);
    $apiKeyStmt->execute();
    $apiKeyResult = $apiKeyStmt->get_result();

    if ($apiKeyResult->num_rows === 0) {
        throw new Exception('Invalid or expired API key');
    }

    // Get POST data
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($data['national_id'])) {
        throw new Exception('National ID is required');
    }

    $national_id = $con->real_escape_string($data['national_id']);
    
    // Get all loan applications ordered by latest first
    $query = "
        SELECT 
            loan_id,
            application_no,
            status,
            status_date,
            loan_amount,
            loan_purpose,
            loan_tenure,
            interest_rate,
            customerDecision
        FROM loan_application_details 
        WHERE national_id = ? 
        ORDER BY loan_id DESC
    ";
    
    $stmt = $con->prepare($query);
    $stmt->bind_param("s", $national_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $applications = [];
    while ($row = $result->fetch_assoc()) {
        $applications[] = [
            'loan_id' => $row['loan_id'],
            'application_no' => $row['application_no'],
            'status' => $row['status'],
            'status_date' => $row['status_date'],
            'loan_amount' => $row['loan_amount'],
            'loan_purpose' => $row['loan_purpose'],
            'loan_tenure' => $row['loan_tenure'],
            'interest_rate' => $row['interest_rate'],
            'customerDecision' => $row['customerDecision']
        ];
    }
    
    if (!empty($applications)) {
        echo json_encode([
            "success" => true,
            "data" => $applications
        ]);

        // Log the action
        logAction('LOAN_STATUS_CHECK', $national_id, 'Success - Found ' . count($applications) . ' applications');
    } else {
        echo json_encode([
            "success" => true,
            "data" => []
        ]);

        // Log the action
        logAction('LOAN_STATUS_CHECK', $national_id, 'No applications found');
    }
    
} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);

    // Log the error
    logAction('LOAN_STATUS_CHECK', $national_id ?? 'unknown', 'Error: ' . $e->getMessage());
}
