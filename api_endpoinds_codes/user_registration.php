<?php
// Error reporting should be first
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

        $api_key = $con->real_escape_string($headers['api-key']);
        $query = "SELECT * FROM API_Keys WHERE api_Key = ? AND (expires_at IS NULL OR expires_at > NOW())";
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
            $query = "SELECT national_id FROM Customers WHERE national_id = ?";
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
        $query = "SELECT national_id FROM Customers WHERE national_id = ?";
        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $data['national_id']);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            throw new Exception('This ID already registered');
        }

        // Only national_id is required
        if (empty($data['national_id'])) {
            throw new Exception("Missing required field: national_id");
        }

        // Start transaction
        $con->begin_transaction();

        try {
            // Prepare variables for binding with all fields optional
            $national_id = $data['national_id'];
            $first_name_en = isset($data['first_name_en']) ? $data['first_name_en'] : null;
            $second_name_en = isset($data['second_name_en']) ? $data['second_name_en'] : null;
            $third_name_en = isset($data['third_name_en']) ? $data['third_name_en'] : null;
            $family_name_en = isset($data['family_name_en']) ? $data['family_name_en'] : null;
            $first_name_ar = isset($data['first_name_ar']) ? $data['first_name_ar'] : null;
            $second_name_ar = isset($data['second_name_ar']) ? $data['second_name_ar'] : null;
            $third_name_ar = isset($data['third_name_ar']) ? $data['third_name_ar'] : null;
            $family_name_ar = isset($data['family_name_ar']) ? $data['family_name_ar'] : null;
            $email = isset($data['email']) ? $data['email'] : null;
            $hashedPassword = isset($data['password']) ? password_hash($data['password'], PASSWORD_BCRYPT) : null;
            $phone = isset($data['phone']) ? $data['phone'] : null;
            $date_of_birth = isset($data['date_of_birth']) ? $data['date_of_birth'] : null;
            $id_expiry_date = isset($data['id_expiry_date']) ? $data['id_expiry_date'] : null;
            $building_no = isset($data['building_no']) ? $data['building_no'] : null;
            $street = isset($data['street']) ? $data['street'] : null;
            $district = isset($data['district']) ? $data['district'] : null;
            $city = isset($data['city']) ? $data['city'] : null;
            $zipcode = isset($data['zipcode']) ? $data['zipcode'] : null;
            $add_no = isset($data['add_no']) ? $data['add_no'] : null;
            $iban = isset($data['iban']) ? $data['iban'] : null;
            $dependents = isset($data['dependents']) ? $data['dependents'] : null;
            $salary_dakhli = isset($data['salary_dakhli']) ? $data['salary_dakhli'] : null;
            $salary_customer = isset($data['salary_customer']) ? $data['salary_customer'] : null;
            $los = isset($data['los']) ? $data['los'] : null;
            $sector = isset($data['sector']) ? $data['sector'] : null;
            $employer = isset($data['employer']) ? $data['employer'] : null;
            $consent = isset($data['consent']) ? $data['consent'] : false;
            $consent_date = isset($data['consent_date']) ? $data['consent_date'] : null;
            $nafath_status = isset($data['nafath_status']) ? $data['nafath_status'] : null;
            $nafath_timestamp = isset($data['nafath_timestamp']) ? $data['nafath_timestamp'] : null;

            // Prepare and insert customer with all fields
            $stmt = $con->prepare("INSERT INTO Customers (
                national_id, 
                first_name_en, second_name_en, third_name_en, family_name_en,
                first_name_ar, second_name_ar, third_name_ar, family_name_ar,
                date_of_birth, id_expiry_date, email, phone,
                building_no, street, district, city, zipcode, add_no,
                iban, dependents, salary_dakhli, salary_customer,
                los, sector, employer, password,
                registration_date, consent, consent_date,
                nafath_status, nafath_timestamp
            ) VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                CURRENT_TIMESTAMP, ?, ?, ?, ?
            )");
            
            $stmt->bind_param("ssssssssssssssssssssisssissbsss", 
                $national_id,
                $first_name_en, $second_name_en, $third_name_en, $family_name_en,
                $first_name_ar, $second_name_ar, $third_name_ar, $family_name_ar,
                $date_of_birth, $id_expiry_date, $email, $phone,
                $building_no, $street, $district, $city, $zipcode, $add_no,
                $iban, $dependents, $salary_dakhli, $salary_customer,
                $los, $sector, $employer, $hashedPassword,
                $consent, $consent_date, $nafath_status, $nafath_timestamp
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
                    $disable_stmt = $con->prepare("UPDATE customer_devices SET status = 'disabled' WHERE national_id = ? AND deviceId = ?");
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
                $stmt = $con->prepare("INSERT INTO customer_devices (
                    national_id, 
                    deviceId, 
                    platform, 
                    model, 
                    manufacturer, 
                    biometric_enabled, 
                    status,
                    created_at
                ) VALUES (?, ?, ?, ?, ?, ?, 'active', NOW())");
                
                if (!$stmt) {
                    throw new Exception('Failed to prepare device registration statement: ' . $con->error);
                }
                
                $biometricEnabled = 1;
                if (!bindParameters($stmt, "sssssi", 
                    $data['national_id'],
                    $deviceInfo['deviceId'],
                    $deviceInfo['platform'],
                    $deviceInfo['model'],
                    $deviceInfo['manufacturer'],
                    $biometricEnabled
                )) {
                    throw new Exception('Failed to bind parameters: ' . $stmt->error);
                }
                
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
                ) VALUES (?, ?, 'device_registration', 'success', ?, ?)");
                
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
                'first_name_en' => $first_name_en,
                'family_name_en' => $family_name_en,
                'first_name_ar' => $first_name_ar,
                'family_name_ar' => $family_name_ar,
                'date_of_birth' => $date_of_birth,
                'id_expiry_date' => $id_expiry_date,
                'building_no' => $building_no,
                'street' => $street,
                'district' => $district,
                'city' => $city,
                'zipcode' => $zipcode,
                'add_no' => $add_no,
                'iban' => $iban,
                'dependents' => $dependents,
                'salary_dakhli' => $salary_dakhli,
                'salary_customer' => $salary_customer,
                'los' => $los,
                'sector' => $sector,
                'employer' => $employer,
                'consent' => $consent,
                'consent_date' => $consent_date,
                'nafath_status' => $nafath_status,
                'nafath_timestamp' => $nafath_timestamp,
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