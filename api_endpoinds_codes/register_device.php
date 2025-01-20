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

        // Validate API key (reusing existing code)
        $api_key = $con->real_escape_string($headers['api-key']);
        $query = "SELECT * FROM API_Keys WHERE api_key = ? AND (expires_at IS NULL OR expires_at > NOW())";
        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $api_key);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            throw new Exception('Invalid or expired API key');
        }

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            throw new Exception('Invalid JSON input');
        }

        // Validate required fields
        $requiredFields = ['national_id', 'deviceId', 'platform', 'model', 'manufacturer'];
        foreach ($requiredFields as $field) {
            if (empty($data[$field])) {
                throw new Exception("Missing field: $field");
            }
        }

        // Check if register_device_only is set
        $register_device_only = isset($data['register_device_only']) && $data['register_device_only'] === true;

        // Check if user exists only if register_device_only is false
        if (!$register_device_only) {
            $stmt = $con->prepare("SELECT national_id FROM Users WHERE national_id = ?");
            $stmt->bind_param("s", $data['national_id']);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                throw new Exception('User not found');
            }
        }

        // First, disable any existing device record
        $stmt = $con->prepare("UPDATE user_devices SET status = 'disabled' WHERE national_id = ? AND deviceId = ?");
        $stmt->bind_param("ss", $data['national_id'], $data['deviceId']);
        $stmt->execute();

        // Register new device
        $stmt = $con->prepare("INSERT INTO user_devices (national_id, deviceId, platform, model, manufacturer, biometric_enabled, created_at) VALUES (?, ?, ?, ?, ?, 1, NOW())");
        $stmt->bind_param("sssss", 
            $data['national_id'],
            $data['deviceId'],
            $data['platform'],
            $data['model'],
            $data['manufacturer']
        );

        if (!$stmt->execute()) {
            throw new Exception('Database error: ' . $stmt->error);
        }

        // Log the device registration
        $ip = $_SERVER['REMOTE_ADDR'];
        $user_agent = $_SERVER['HTTP_USER_AGENT'];
        
        $stmt = $con->prepare("INSERT INTO auth_logs (national_id, deviceId, auth_type, status, ip_address, user_agent) VALUES (?, ?, 'biometric', 'success', ?, ?)");
        $stmt->bind_param("ssss", 
            $data['national_id'],
            $data['deviceId'],
            $ip,
            $user_agent
        );
        $stmt->execute();

        echo json_encode([
            'status' => 'success', 
            'message' => 'Device registered successfully',
            'device_id' => $con->insert_id
        ]);
    } else {
        throw new Exception('Invalid request method');
    }
} catch (Exception $e) {
    // Log failed attempt
    if (isset($data['national_id']) && isset($data['deviceId'])) {
        $stmt = $con->prepare("INSERT INTO auth_logs (national_id, deviceId, auth_type, status, ip_address, user_agent, failure_reason) VALUES (?, ?, 'biometric', 'failed', ?, ?, ?)");
        $stmt->bind_param("sssss", 
            $data['national_id'],
            $data['deviceId'],
            $_SERVER['REMOTE_ADDR'],
            $_SERVER['HTTP_USER_AGENT'],
            $e->getMessage()
        );
        $stmt->execute();
    }

    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    exit();
}

$con->close();
?>