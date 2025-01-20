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
        
        // Check if this is just an ID check
        if (isset($data['check_only']) && $data['check_only'] === true) {
            $query = "SELECT national_id FROM Users WHERE national_id = ?";
            $stmt = $con->prepare($query);
            $stmt->bind_param("s", $data['national_id']);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows > 0) {
                echo json_encode([
                    'status' => 'error',
                    'message' => 'This ID already registered'
                ]);
                exit();
            } else {
                echo json_encode([
                    'status' => 'success',
                    'message' => 'ID available'
                ]);
                exit();
            }
        }

        // Regular registration flow
        $query = "SELECT national_id FROM Users WHERE national_id = ?";
        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $data['national_id']);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            throw new Exception('This ID already registered');
        }

        $requiredFields = ['national_id', 'name', 'arabic_name', 'email', 'password', 'phone'];
        foreach ($requiredFields as $field) {
            if (empty($data[$field])) {
                throw new Exception("Missing field: $field");
            }
        }

        // Start transaction
        $con->begin_transaction();

        try {
            // Prepare variables for binding
            $national_id = $data['national_id'];
            $full_name = isset($data['full_name']) ? $data['full_name'] : $data['name'];
            $arabic_name = $data['arabic_name'];
            $email = $data['email'];
            $hashedPassword = password_hash($data['password'], PASSWORD_BCRYPT);
            $phone = $data['phone'];
            $dob = isset($data['dob']) ? $data['dob'] : null;
            $salary = isset($data['salary']) ? $data['salary'] : null;
            $employment_status = isset($data['employment_status']) ? $data['employment_status'] : null;
            $employer_name = isset($data['employer_name']) ? $data['employer_name'] : null;
            $employment_date = isset($data['employment_date']) ? $data['employment_date'] : null;
            $national_address = isset($data['national_address']) ? $data['national_address'] : null;

            // Prepare and insert user with government data
            $stmt = $con->prepare("INSERT INTO Users (
                national_id, name, arabic_name, email, password, phone, 
                dob, salary, employment_status, employer_name, 
                employment_date, national_address, created_at
            ) VALUES (
                ?, ?, ?, ?, ?, ?, 
                ?, ?, ?, ?, 
                ?, ?, DATE_ADD(NOW(), INTERVAL 8 HOUR)
            )");
            
            $stmt->bind_param("ssssssssssss", 
                $national_id,
                $full_name,
                $arabic_name,
                $email,
                $hashedPassword,
                $phone,
                $dob,
                $salary,
                $employment_status,
                $employer_name,
                $employment_date,
                $national_address
            );
            
            if (!$stmt->execute()) {
                throw new Exception('Database error: ' . $stmt->error);
            }

            // Handle device registration if biometric is requested
            if (isset($data['device_info']) && is_array($data['device_info'])) {
                $deviceInfo = $data['device_info'];
                
                // Validate device info
                $requiredDeviceFields = ['deviceId', 'platform', 'model', 'manufacturer'];
                foreach ($requiredDeviceFields as $field) {
                    if (empty($deviceInfo[$field])) {
                        throw new Exception("Missing device info field: $field");
                    }
                }
                
                // Disable any existing devices for this user
                try {
                    $disable_stmt = $con->prepare("UPDATE user_devices SET status = 'disabled' WHERE national_id = ? AND deviceId = ?");
                    if (!$disable_stmt) {
                        error_log("Prepare failed: " . $con->error);
                        throw new Exception("Failed to prepare disable devices statement");
                    }
                    
                    $disable_stmt->bind_param("ss", $data['national_id'], $deviceInfo['deviceId']);
                    if (!$disable_stmt->execute()) {
                        error_log("Execute failed: " . $disable_stmt->error);
                        throw new Exception("Failed to disable existing devices");
                    }
                    
                    error_log("Successfully disabled existing devices. Affected rows: " . $disable_stmt->affected_rows);
                    $disable_stmt->close();
                } catch (Exception $e) {
                    error_log("Error disabling existing devices: " . $e->getMessage());
                }

                // Register device
                $stmt = $con->prepare("INSERT INTO user_devices (
                    national_id, 
                    deviceId, 
                    platform, 
                    model, 
                    manufacturer, 
                    biometric_enabled, 
                    status,
                    created_at
                ) VALUES (?, ?, ?, ?, ?, ?, 'active', NOW())");
                
                $biometricEnabled = 1;
                $stmt->bind_param("sssssi", 
                    $data['national_id'],
                    $deviceInfo['deviceId'],
                    $deviceInfo['platform'],
                    $deviceInfo['model'],
                    $deviceInfo['manufacturer'],
                    $biometricEnabled
                );
                
                if (!$stmt->execute()) {
                    throw new Exception('Failed to register device: ' . $stmt->error);
                }

                // Log the device registration
                $stmt = $con->prepare("INSERT INTO auth_logs (
                    national_id, 
                    deviceId, 
                    auth_type, 
                    status, 
                    ip_address, 
                    user_agent
                ) VALUES (?, ?, 'biometric', 'success', ?, ?)");
                
                $stmt->bind_param("ssss", 
                    $data['national_id'],
                    $deviceInfo['deviceId'],
                    $_SERVER['REMOTE_ADDR'],
                    $_SERVER['HTTP_USER_AGENT']
                );
                
                if (!$stmt->execute()) {
                    throw new Exception('Failed to log device registration: ' . $stmt->error);
                }
            }

            // Commit transaction
            $con->commit();

            // Prepare the government data for the response
            $gov_data = [
                'national_id' => $national_id,
                'full_name' => $full_name,
                'arabic_name' => $arabic_name,
                'dob' => $dob,
                'salary' => $salary,
                'employment_status' => $employment_status,
                'employer_name' => $employer_name,
                'employment_date' => $employment_date,
                'national_address' => $national_address,
                'updated_at' => date('Y-m-d H:i:s')
            ];

            $response = [
                'status' => 'success',
                'message' => 'User registered successfully',
                'government_data' => $gov_data
            ];

            if (isset($deviceInfo)) {
                $response['device_registered'] = true;
                $response['biometric_enabled'] = true;
            }

            echo json_encode($response);

        } catch (Exception $e) {
            // Rollback transaction on error
            $con->rollback();
            throw $e;
        }

    } else {
        throw new Exception('Invalid request method');
    }
} catch (Exception $e) {
    // Log registration failure
    if (isset($data['national_id']) && isset($data['device_info'])) {
        $stmt = $con->prepare("INSERT INTO auth_logs (
            national_id, 
            deviceId, 
            auth_type, 
            status, 
            ip_address, 
            user_agent, 
            failure_reason
        ) VALUES (?, ?, 'biometric', 'failed', ?, ?, ?)");
        
        $stmt->bind_param("sssss", 
            $data['national_id'],
            $data['device_info']['deviceId'],
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