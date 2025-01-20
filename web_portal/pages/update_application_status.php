<?php
require_once '../includes/auth.php';
require_once '../includes/db.php';

if (!checkPermission('credit_admin')) {
    die(json_encode(['success' => false, 'error' => 'Permission denied']));
}

if (!isset($_POST['application_id']) || !isset($_POST['status']) || !isset($_POST['application_type'])) {
    die(json_encode(['success' => false, 'error' => 'Missing required fields']));
}

try {
    if ($_POST['application_type'] === 'card') {
        $stmt = $conn->prepare("
            UPDATE card_application_details 
            SET status = :status, 
                status_date = NOW() 
            WHERE card_id = :application_id
        ");
    } else {
        $stmt = $conn->prepare("
            UPDATE loan_applications 
            SET status = :status, 
                status_date = NOW() 
            WHERE application_id = :application_id
        ");
    }
    
    $stmt->execute([
        'status' => $_POST['status'],
        'application_id' => $_POST['application_id']
    ]);
    
    echo json_encode(['success' => true]);
} catch(PDOException $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
