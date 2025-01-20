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
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $headers = getallheaders();
        if (!isset($headers['api-key'])) {
            throw new Exception('API key is missing');
        }

        // Validate API key
        $api_key = $con->real_escape_string($headers['api-key']);
        $query = "SELECT * FROM API_Keys WHERE api_key = ? AND (expires_at IS NULL OR expires_at > NOW())";
        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $api_key);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            throw new Exception('Invalid or expired API key');
        }

        // Get JSON input
        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            throw new Exception('Invalid JSON input');
        }

        // Validate required fields
        $requiredFields = ['national_id', 'application_no', 'customerDecision', 'loan_amount'];
        foreach ($requiredFields as $field) {
            if (!isset($data[$field])) {
                throw new Exception("Missing required field: $field");
            }
        }

        // Start transaction
        $con->begin_transaction();

        try {
            // Prepare variables for binding
            $national_id = $data['national_id'];
            $application_no = $data['application_no'];
            $customerDecision = $data['customerDecision'];
            $loan_amount = $data['loan_amount'];
            $loan_purpose = isset($data['loan_purpose']) ? $data['loan_purpose'] : null;
            $loan_tenure = isset($data['loan_tenure']) ? $data['loan_tenure'] : null;
            $interest_rate = isset($data['interest_rate']) ? $data['interest_rate'] : null;
            $status = isset($data['status']) ? $data['status'] : 'pending';
            $remarks = isset($data['remarks']) ? $data['remarks'] : null;
            $noteUser = isset($data['noteUser']) ? $data['noteUser'] : 'SYSTEM';
            $note = isset($data['note']) ? $data['note'] : null;

            // First check if the loan application exists
            $check_stmt = $con->prepare("SELECT loan_id FROM loan_application_details WHERE national_id = ? AND application_no = ?");
            $check_stmt->bind_param("ss", $national_id, $application_no);
            $check_stmt->execute();
            $check_result = $check_stmt->get_result();

            if ($check_result->num_rows === 0) {
                // If no existing record, insert a new one
                $stmt = $con->prepare("INSERT INTO loan_application_details (
                    national_id,
                    application_no,
                    customerDecision,
                    loan_amount,
                    loan_purpose,
                    loan_tenure,
                    interest_rate,
                    status,
                    status_date,
                    remarks,
                    noteUser,
                    note
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?, ?)");

                $stmt->bind_param(
                    "sssdsdsssss",
                    $national_id,
                    $application_no,
                    $customerDecision,
                    $loan_amount,
                    $loan_purpose,
                    $loan_tenure,
                    $interest_rate,
                    $status,
                    $remarks,
                    $noteUser,
                    $note
                );
            } else {
                // If record exists, update it
                $stmt = $con->prepare("UPDATE loan_application_details SET 
                    customerDecision = ?,
                    loan_amount = ?,
                    loan_purpose = ?,
                    loan_tenure = ?,
                    interest_rate = ?,
                    status = ?,
                    status_date = CURRENT_TIMESTAMP,
                    remarks = ?,
                    noteUser = ?,
                    note = ?
                    WHERE national_id = ? AND application_no = ?");

                $stmt->bind_param(
                    "sdssdssssss",
                    $customerDecision,
                    $loan_amount,
                    $loan_purpose,
                    $loan_tenure,
                    $interest_rate,
                    $status,
                    $remarks,
                    $noteUser,
                    $note,
                    $national_id,
                    $application_no
                );
            }

            if (!$stmt->execute()) {
                throw new Exception('Failed to process loan application: ' . $stmt->error);
            }

            // Commit transaction
            $con->commit();

            // Prepare response
            $response = [
                'status' => 'success',
                'message' => 'Loan application processed successfully',
                'loan_details' => [
                    'national_id' => $national_id,
                    'application_no' => $application_no,
                    'customerDecision' => $customerDecision,
                    'loan_amount' => $loan_amount,
                    'loan_purpose' => $loan_purpose,
                    'loan_tenure' => $loan_tenure,
                    'interest_rate' => $interest_rate,
                    'status' => $status,
                    'remarks' => $remarks,
                    'noteUser' => $noteUser,
                    'note' => $note,
                    'update_date' => date('Y-m-d H:i:s')
                ]
            ];

            echo json_encode($response);

        } catch (Exception $e) {
            // Rollback transaction on error
            $con->rollback();
            throw $e;
        }

    } else {
        throw new Exception('Invalid request method');
    }
} catch (Exception $e) {
    // Log error
    error_log("Loan application update error: " . $e->getMessage());

    // Prepare error response
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
    exit();
}

$con->close();