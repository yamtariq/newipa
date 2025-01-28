<?php
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 0); // Don't output errors to response

session_start();

// Check if the db_connect.php file exists
$dbPath = __DIR__ . '/../db_connect.php';
if (!file_exists($dbPath)) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database configuration file not found']);
    exit();
}

try {
    require_once $dbPath;
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error loading database configuration']);
    exit();
}

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

if ($_SERVER['REQUEST_METHOD'] !== 'GET' || !isset($_GET['id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing card ID']);
    exit();
}

try {
    $cardId = (int)$_GET['id'];
    
    // Get card application details
    $stmt = $conn->prepare("
        SELECT c.*, 
               u.first_name_en as name, 
               u.email, 
               u.phone, 
               u.sector as employment_status, 
               u.employer, 
               u.salary_customer as salary
        FROM card_application_details c
        LEFT JOIN Customers u ON c.national_id = u.national_id
        WHERE c.card_id = ?
    ");
    
    if (!$stmt) {
        throw new Exception('Database error: ' . $conn->error);
    }
    
    $stmt->bind_param("i", $cardId);
    
    if (!$stmt->execute()) {
        throw new Exception('Query error: ' . $stmt->error);
    }
    
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        $response = [
            'success' => true,
            'details' => [
                'card_id' => $row['card_id'],
                'national_id' => $row['national_id'],
                'name' => $row['name'],
                'email' => $row['email'],
                'phone' => $row['phone'],
                'status' => $row['status'],
                'remarks' => $row['remarks'] ?? '',
                'employment_status' => $row['employment_status'],
                'employer' => $row['employer'],
                'salary' => $row['salary'],
                'card_type' => $row['card_type'] ?? 'Standard',
                'credit_limit' => $row['credit_limit'] ?? 0,
                'application_date' => $row['status_date'],
                'last_updated' => $row['status_date']
            ]
        ];

        echo json_encode($response);
    } else {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Card application not found']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
