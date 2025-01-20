require_once '../db_connect.php';
<?php
session_start();

if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}

// Check if user has the correct role
if (!isset($_SESSION['role']) || ($_SESSION['role'] !== 'sales' && $_SESSION['role'] !== 'credit' && $_SESSION['role'] !== 'admin')) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Unauthorized role']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['id'])) {
    $cardId = $_GET['id'];
    
    $stmt = $conn->prepare("
        SELECT c.*, u.name, u.email, u.phone
        FROM card_application_details c
        LEFT JOIN Users u ON c.national_id = u.national_id
        WHERE c.card_id = ?
    ");
    $stmt->bind_param("i", $cardId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode(['success' => true, 'details' => $row]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Card application not found']);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed or missing ID']);
}
