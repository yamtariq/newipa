<?php
require_once '../db_connect.php';
session_start();

if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['id'])) {
    $loanId = $_GET['id'];
    
    $stmt = $conn->prepare("
        SELECT l.*, u.first_name_en as name, u.email, u.phone, u.sector as employment_status, u.employer, u.salary_customer as salary
        FROM loan_application_details l
        LEFT JOIN Customers u ON l.national_id = u.national_id
        WHERE l.loan_id = ?
    ");
    $stmt->bind_param("i", $loanId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode(['success' => true, 'details' => $row]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Loan application not found']);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed or missing ID']);
}
