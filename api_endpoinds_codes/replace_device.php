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
        // Validate API key
        $headers = getallheaders();
        if (!isset($headers['api-key'])) {
            throw new Exception('API key is missing');
        }

        $api_key = $con->real_escape_string($headers['api-key']);
        $query = "SELECT * FROM API_Keys WHERE api_Key = ? AND (expires_at IS NULL OR expires_at > NOW())";
        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $api_key);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            throw new Exception('Invalid or expired API key');
        }

        // Parse input data
        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data) {
            throw new Exception('Invalid JSON input');
        }

        // Validate required fields
        if (empty($data['national_id'])) {
            throw new Exception('National ID is required');
        }
        if (empty($data['device_info'])) {
            throw new Exception('Device info is required');
        }

        $national_id = $con->real_escape_string($data['national_id']);
        $device_info = $data['device_info'];

        // Start transaction
        $con->begin_transaction();

        try {
            // 1. Deactivate old device
            $stmt = $con->prepare("
                UPDATE user_devices 
                SET status = 'disabled', 
                    last_used_at = NOW() 
                WHERE national_id = ? 
                AND status = 'active'
            ");
            $stmt->bind_param("s", $national_id);
            $stmt->execute();

            // 2. Register new device
            $stmt = $con->prepare("
                INSERT INTO user_devices (
                    national_id,
                    deviceId,
                    platform,
                    model,
                    manufacturer,
                    biometric_enabled,
                    status
                ) VALUES (?, ?, ?, ?, ?, 0, 'active')
            ");
            $stmt->bind_param(
                "sssss",
                $national_id,
                $device_info['deviceId'],
                $device_info['platform'],
                $device_info['model'],
                $device_info['manufacturer']
            );
            $stmt->execute();

            // 3. Revoke all existing sessions
            $stmt = $con->prepare("
                UPDATE user_sessions 
                SET status = 'revoked' 
                WHERE national_id = ?
            ");
            $stmt->bind_param("s", $national_id);
            $stmt->execute();

            // 4. Log the device change
            $stmt = $con->prepare("
                INSERT INTO auth_logs (
                    national_id,
                    deviceId,
                    auth_type,
                    status,
                    ip_address,
                    user_agent
                ) VALUES (?, ?, 'device_replacement', 'success', ?, ?)
            ");
            $stmt->bind_param(
                "ssss",
                $national_id,
                $device_info['deviceId'],
                $_SERVER['REMOTE_ADDR'],
                $_SERVER['HTTP_USER_AGENT']
            );
            $stmt->execute();

            // Commit transaction
            $con->commit();

            // Return success response
            echo json_encode([
                'status' => 'success',
                'message' => 'Device replaced successfully'
            ]);

        } catch (Exception $e) {
            // Rollback transaction on error
            $con->rollback();
            throw $e;
        }
    } else {
        throw new Exception('Invalid request method');
    }
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
    exit();
}

$con->close();
?>