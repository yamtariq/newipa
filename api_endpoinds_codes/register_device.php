<?php
error_reporting(0); // Suppress all errors in production
ini_set('display_errors', 0);

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header('Content-Type: application/json');

require 'db_connect.php';
require 'audit_log.php';

// Function to safely bind parameters
function bindParameters($stmt, $types, ...$params) {
    $refs = array();
    $refs[0] = $types;
    for($i = 0; $i < count($params); $i++) {
        $refs[$i+1] = &$params[$i];
    }
    return call_user_func_array(array($stmt, 'bind_param'), $refs);
}

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

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            throw new Exception('Invalid JSON input');
        }

        // Only national_id is required
        if (empty($data['national_id'])) {
            throw new Exception("Missing required field: national_id");
        }

        // First, disable ALL existing devices for this user if deviceId is provided
        if (isset($data['deviceId'])) {
            $stmt = $con->prepare("UPDATE customer_devices SET status = 'disabled' WHERE national_id = ?");
            $stmt->bind_param("s", $data['national_id']);
            $stmt->execute();
        }

        // Verify customer exists
        $stmt = $con->prepare("SELECT id FROM Customers WHERE national_id = ?");
        $stmt->bind_param("s", $data['national_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            throw new Exception('Customer not found');
        }

        // Register new device only if device info is provided
        if (isset($data['deviceId'])) {
            $stmt = $con->prepare("INSERT INTO customer_devices (
                national_id, 
                deviceId, 
                platform, 
                model, 
                manufacturer, 
                biometric_enabled, 
                status,
                created_at
            ) VALUES (?, ?, ?, ?, ?, 1, 'active', NOW())");
            
            if (!$stmt) {
                throw new Exception('Failed to prepare device registration statement: ' . $con->error);
            }
            
            $platform = isset($data['platform']) ? $data['platform'] : null;
            $model = isset($data['model']) ? $data['model'] : null;
            $manufacturer = isset($data['manufacturer']) ? $data['manufacturer'] : null;
            
            if (!bindParameters($stmt, "sssss", 
                $data['national_id'],
                $data['deviceId'],
                $platform,
                $model,
                $manufacturer
            )) {
                throw new Exception('Failed to bind parameters: ' . $stmt->error);
            }

            if (!$stmt->execute()) {
                throw new Exception('Database error: ' . $stmt->error);
            }

            // Log the device registration
            $ip = $_SERVER['REMOTE_ADDR'];
            $user_agent = $_SERVER['HTTP_USER_AGENT'];
            
            $stmt = $con->prepare("INSERT INTO auth_logs (
                national_id, 
                deviceId, 
                auth_type,
                status, 
                ip_address, 
                user_agent
            ) VALUES (?, ?, 'device_registration', 'success', ?, ?)");
            
            $stmt->bind_param("ssss", 
                $data['national_id'],
                $data['deviceId'],
                $ip,
                $user_agent
            );
            $stmt->execute();
        }

        echo json_encode([
            'status' => 'success', 
            'message' => isset($data['deviceId']) ? 'Device registered successfully' : 'Customer verified successfully',
            'device_id' => isset($data['deviceId']) ? $con->insert_id : null
        ]);
    } else {
        throw new Exception('Invalid request method');
    }
} catch (Exception $e) {
    // Log failed attempt
    if (isset($data['national_id']) && isset($data['deviceId'])) {
        $stmt = $con->prepare("INSERT INTO auth_logs (national_id, deviceId, auth_type, status, ip_address, user_agent, failure_reason) VALUES (?, ?, 'device_registration', 'failed', ?, ?, ?)");
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