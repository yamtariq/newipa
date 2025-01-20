<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

session_start();
require_once '../db_connect.php';

header('Content-Type: application/json');

// Debug log
error_log("Received request: " . file_get_contents('php://input'));

try {
    // Check if user is logged in
    if (!isset($_SESSION['user_id'])) {
        throw new Exception('Unauthorized access');
    }

    // Get JSON data from request
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    if (!$data) {
        throw new Exception('Invalid JSON input: ' . json_last_error_msg());
    }

    if (!isset($data['page']) || !isset($data['key_name']) || !isset($data['value'])) {
        throw new Exception('Missing required parameters');
    }

    // Sanitize inputs
    $page = $conn->real_escape_string($data['page']);
    $key_name = $conn->real_escape_string($data['key_name']);
    
    // Convert the value array to JSON string
    $value = json_encode($data['value'], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    
    if ($value === false) {
        throw new Exception('JSON encoding failed: ' . json_last_error_msg());
    }

    error_log("Prepared JSON value: " . $value);

    // Update the master_config table
    $sql = "UPDATE master_config SET value = ? WHERE page = ? AND key_name = ?";
    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        throw new Exception('Failed to prepare statement: ' . $conn->error);
    }

    $stmt->bind_param("sss", $value, $page, $key_name);

    if (!$stmt->execute()) {
        throw new Exception('Failed to execute statement: ' . $stmt->error);
    }

    if ($stmt->affected_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Configuration updated successfully'
        ]);
    } else {
        // If no rows were updated, try to insert
        $insertSql = "INSERT INTO master_config (page, key_name, value) VALUES (?, ?, ?)";
        $insertStmt = $conn->prepare($insertSql);
        
        if (!$insertStmt) {
            throw new Exception('Failed to prepare insert statement: ' . $conn->error);
        }

        $insertStmt->bind_param("sss", $page, $key_name, $value);
        
        if (!$insertStmt->execute()) {
            throw new Exception('Failed to execute insert statement: ' . $insertStmt->error);
        }

        echo json_encode([
            'success' => true,
            'message' => 'Configuration created successfully'
        ]);
        
        $insertStmt->close();
    }

    $stmt->close();

} catch (Exception $e) {
    error_log("Error in update_master_config.php: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?>
