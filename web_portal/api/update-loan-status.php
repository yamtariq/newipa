<?php
require_once '../db_connect.php';
session_start();

if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $loanId = $data['loan_id'];  // Changed from $data['id']
    $status = $data['status'];
    $remarks = $data['remarks']; // If you also want to store remarks

    $stmt = $conn->prepare("
        UPDATE loan_application_details
        SET status = ?, 
            remarks = ?, 
            status_date = NOW()
        WHERE loan_id = ?
    ");
    $stmt->bind_param("ssi", $status, $remarks, $loanId);

    if ($stmt->execute()) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'message' => $conn->error]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
