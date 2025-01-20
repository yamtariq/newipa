<?php
session_start();
require_once '../db_connect.php';

header('Content-Type: application/json');

if (!isset($_SESSION['user_id'])) {
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}

// Check if user has the correct role
if (!isset($_SESSION['role']) || ($_SESSION['role'] !== 'sales' && $_SESSION['role'] !== 'credit' && $_SESSION['role'] !== 'admin')) {
    echo json_encode(['success' => false, 'message' => 'Unauthorized role']);
    exit();
}

// Validate decision based on role
$validDecisions = [
    'sales' => ['rejected', 'fulfilled', 'underprocess'],
    'credit' => ['approved', 'missing', 'rejected'],
    'admin' => ['rejected', 'fulfilled', 'underprocess', 'approved', 'missing']
];

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['applicationId']) || !isset($data['decision']) || !isset($data['note'])) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit();
}

$applicationId = $data['applicationId'];
$decision = $data['decision'];
$note = $data['note'];
$userId = $_SESSION['user_id'];

if (!in_array($decision, $validDecisions[$_SESSION['role']])) {
    echo json_encode(['success' => false, 'message' => 'Invalid decision for your role']);
    exit();
}

// For sales role, check if status is pending or missing
if ($_SESSION['role'] === 'sales') {
    $statusQuery = "SELECT status FROM card_application_details WHERE card_id = ?";
    $stmt = $conn->prepare($statusQuery);
    $stmt->bind_param('i', $applicationId);
    $stmt->execute();
    $result = $stmt->get_result();
    $currentStatus = $result->fetch_assoc()['status'];
    
    if ($currentStatus !== 'pending' && $currentStatus !== 'missing') {
        echo json_encode(['success' => false, 'message' => 'Sales can only make decisions on pending or missing applications']);
        exit();
    }
}

try {
    // Start transaction
    $conn->begin_transaction();

    // Update the card application status
    $updateQuery = "UPDATE card_application_details 
                   SET status = ?, 
                       noteUser = ?, 
                       note = ?,
                       status_date = CURRENT_TIMESTAMP 
                   WHERE card_id = ?";
    
    $stmt = $conn->prepare($updateQuery);
    $stmt->bind_param('sisi', $decision, $userId, $note, $applicationId);
    $stmt->execute();

    if ($stmt->affected_rows === 0) {
        throw new Exception('No application found with the given ID');
    }

    // Commit transaction
    $conn->commit();
    
    echo json_encode(['success' => true]);
} catch (Exception $e) {
    // Rollback transaction on error
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
