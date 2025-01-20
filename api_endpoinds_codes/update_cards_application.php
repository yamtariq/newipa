<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header('Content-Type: application/json');

require 'db_connect.php';
require 'audit_log.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    // Check for API key in the request headers
    $headers = getallheaders();
    if (!isset($headers['api-key'])) {
        throw new Exception('API key is missing');
    }

    // Validate the API key
    $api_key = $con->real_escape_string($headers['api-key']);
    $query = "SELECT * FROM API_Keys WHERE api_key = ? AND (expires_at IS NULL OR expires_at > NOW())";
    $stmt = $con->prepare($query);
    $stmt->bind_param("s", $api_key);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        throw new Exception('Invalid or expired API key');
    }

    // Parse input data
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data) {
        throw new Exception('Invalid JSON input');
    }

    // Validate required fields
    $required_fields = ['national_id', 'card_type', 'card_limit', 'status', 'customerDecision', 'noteUser', 'application_number'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            throw new Exception("Missing required field: $field");
        }
    }

    // Start transaction
    $con->begin_transaction();

    try {
        // Get current timestamp for status_date
        $status_date = date('Y-m-d H:i:s');

        // Convert application_number to integer to match database type
        $application_no = intval($data['application_number']);

        // First check if the card application exists
        $check_stmt = $con->prepare("SELECT card_id FROM card_application_details WHERE national_id = ? AND application_no = ?");
        $check_stmt->bind_param("si", $data['national_id'], $application_no);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();

        if ($check_result->num_rows === 0) {
            // If no existing record, insert a new one
            $stmt = $con->prepare("INSERT INTO card_application_details (
                national_id,
                application_no,
                card_type,
                card_limit,
                status,
                status_date,
                customerDecision,
                remarks,
                noteUser,
                note
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

            $remarks = $data['remarks'] ?? 'Card application submitted';
            $note = $data['note'] ?? null;

            $stmt->bind_param(
                "sisdssssss",
                $data['national_id'],
                $application_no,
                $data['card_type'],
                $data['card_limit'],
                $data['status'],
                $status_date,
                $data['customerDecision'],
                $remarks,
                $data['noteUser'],
                $note
            );
        } else {
            // If record exists, update it
            $stmt = $con->prepare("UPDATE card_application_details SET 
                card_limit = ?,
                status = ?,
                status_date = ?,
                customerDecision = ?,
                remarks = ?,
                noteUser = ?,
                note = ?
                WHERE application_no = ? AND national_id = ?");

            $remarks = $data['remarks'] ?? 'Card application submitted';
            $note = $data['note'] ?? null;

            $stmt->bind_param(
                "dsssssssi",
                $data['card_limit'],
                $data['status'],
                $status_date,
                $data['customerDecision'],
                $remarks,
                $data['noteUser'],
                $note,
                $application_no,
                $data['national_id']
            );
        }

        // Execute the statement
        if (!$stmt->execute()) {
            throw new Exception("Failed to save card application: " . $stmt->error);
        }

        // Log the successful application update
        log_audit($con, null, 'Card Application Updated', "Card application updated for National ID: " . $data['national_id'] . ", Application #: " . $data['application_number']);

        // Commit transaction
        $con->commit();

        // Return success response with application details
        echo json_encode([
            'status' => 'success',
            'message' => 'Card application saved successfully',
            'card_details' => [
                'application_no' => $data['application_number'],
                'national_id' => $data['national_id'],
                'card_type' => $data['card_type'],
                'card_limit' => $data['card_limit'],
                'status' => $data['status'],
                'status_date' => $status_date,
                'customerDecision' => $data['customerDecision'],
                'noteUser' => $data['noteUser']
            ]
        ]);

    } catch (Exception $e) {
        // Rollback transaction on error
        $con->rollback();
        throw $e;
    }

} catch (Exception $e) {
    // Log the error
    log_audit($con, null, 'Card Application Error', $e->getMessage());
    
    echo json_encode([
        'status' => 'error',
        'code' => 'SYSTEM_ERROR',
        'message' => $e->getMessage()
    ]);
    exit();
}

$con->close();
?>
