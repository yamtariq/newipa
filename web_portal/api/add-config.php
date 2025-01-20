<?php
require_once '../db_connect.php';
session_start();

if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $page = $_POST['page'];
    $key_name = $_POST['key_name'];
    $value = $_POST['value'];

    $stmt = $conn->prepare("INSERT INTO master_config (page, key_name, value) VALUES (?, ?, ?)");
    $stmt->bind_param("sss", $page, $key_name, $value);

    if ($stmt->execute()) {
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'message' => $conn->error]);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
