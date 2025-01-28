<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

// Change content type to accept form data
header('Content-Type: application/json; charset=utf-8');
header('Accept: application/x-www-form-urlencoded');

require 'db_connect.php';
require 'audit_log.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    // Check for API key in headers
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

    // Get and validate required fields
    $national_id = isset($_POST['national_id']) ? $con->real_escape_string($_POST['national_id']) : null;
    $new_password = isset($_POST['new_password']) ? $_POST['new_password'] : null;
    $type = isset($_POST['type']) ? $con->real_escape_string($_POST['type']) : 'reset_password';

    if (!$national_id) {
        throw new Exception('Missing required field: national_id');
    }

    // Start transaction
    $con->begin_transaction();

    try {
        // Validate password requirements only if password is provided
        if ($new_password) {
            if (strlen($new_password) < 8 || 
                !preg_match('/[A-Z]/', $new_password) || 
                !preg_match('/[a-z]/', $new_password) || 
                !preg_match('/[0-9]/', $new_password)) {
                throw new Exception('Password must be at least 8 characters and include uppercase, lowercase, and numbers');
            }
        }

        // Check if user exists
        $query = "SELECT id, password FROM Customers WHERE national_id = ?";
        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $national_id);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            throw new Exception('Customer not found');
        }

        $customer = $result->fetch_assoc();

        // Only proceed with password update if new password is provided
        if ($new_password) {
            // Check if new password is same as old password
            if ($customer['password'] && password_verify($new_password, $customer['password'])) {
                throw new Exception('New password must be different from current password');
            }

            // Hash the new password
            $hashedPassword = password_hash($new_password, PASSWORD_BCRYPT);

            // Update the password
            $query = "UPDATE Customers SET password = ? WHERE national_id = ?";
            $stmt = $con->prepare($query);
            $stmt->bind_param("ss", $hashedPassword, $national_id);
            
            if (!$stmt->execute()) {
                throw new Exception('Failed to update password');
            }

            // Log the password change
            $log_query = "INSERT INTO password_change_logs (
                national_id, 
                type, 
                status, 
                ip_address, 
                user_agent
            ) VALUES (?, ?, 'success', ?, ?)";
            $stmt = $con->prepare($log_query);
            $stmt->bind_param("ssss", $national_id, $type, $_SERVER['REMOTE_ADDR'], $_SERVER['HTTP_USER_AGENT']);
            $stmt->execute();
        }

        // Commit transaction
        $con->commit();

        echo json_encode([
            'status' => 'success',
            'message' => 'Password changed successfully',
            'message_ar' => 'تم تغيير كلمة المرور بنجاح'
        ]);

    } catch (Exception $e) {
        $con->rollback();
        throw $e;
    }

} catch (Exception $e) {
    $error_code = '';
    $error_message = $e->getMessage();
    $error_message_ar = '';
    
    switch ($error_message) {
        case 'Customer not found':
            $error_code = 'USER_NOT_FOUND';
            $error_message_ar = 'المستخدم غير موجود';
            break;
        case 'New password must be different from current password':
            $error_code = 'SAME_AS_OLD_PASSWORD';
            $error_message_ar = 'كلمة المرور الجديدة يجب أن تكون مختلفة عن كلمة المرور الحالية';
            break;
        case 'Password must be at least 8 characters and include uppercase, lowercase, and numbers':
            $error_code = 'INVALID_PASSWORD_FORMAT';
            $error_message_ar = 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل، وتتضمن أحرف كبيرة وصغيرة وأرقام';
            break;
        case 'Missing required fields':
            $error_code = 'MISSING_FIELDS';
            $error_message_ar = 'بعض الحقول المطلوبة غير موجودة';
            break;
        default:
            $error_code = 'UNKNOWN_ERROR';
            $error_message_ar = 'حدث خطأ غير متوقع';
    }

    if (isset($customer['id'])) {
        log_audit($con, $customer['id'], 'Password Change Failed', $error_message);
    }

    echo json_encode([
        'status' => 'error',
        'code' => $error_code,
        'message' => $error_message,
        'message_ar' => $error_message_ar
    ]);
}

$con->close();
?> 