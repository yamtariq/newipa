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
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    // Check for API key in the request headers
    $headers = getallheaders();
    if (!isset($headers['api-key'])) {
        throw new Exception('API key is missing');
    }

    // Validate the API key
    $api_key = $con->real_escape_string($headers['api-key']);
    $query = "SELECT * FROM API_Keys WHERE api_key = ? AND (expires_at IS NULL OR expires_at > NOW())";
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

    // Check for active applications first
    $national_id = $data['national_id'];
    $check_stmt = $con->prepare("SELECT application_no, status 
        FROM card_application_details 
        WHERE national_id = ? 
        AND status NOT IN ('Rejected', 'Declined')
        AND status_date >= DATE_SUB(NOW(), INTERVAL 5 DAY)
        ORDER BY card_id DESC 
        LIMIT 1");

    $check_stmt->bind_param("s", $national_id);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();

    if ($check_result->num_rows > 0) {
        $row = $check_result->fetch_assoc();
        echo json_encode([
            'status' => 'error',
            'code' => 'ACTIVE_APPLICATION_EXISTS',
            'message' => 'You have an active card application. Please check your application status.',
            'message_ar' => 'لديك طلب بطاقة نشط. يرجى التحقق من حالة طلبك.',
            'application_no' => $row['application_no'],
            'current_status' => $row['status']
        ]);
        exit();
    }

    // Validate required fields
    $required_fields = ['salary', 'liabilities', 'expenses'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            throw new Exception("Missing required field: $field");
        }
    }

    $salary = (float)$data['salary'];
    $liabilities = (float)$data['liabilities'];
    $expenses = (float)$data['expenses'];

    // Basic validations
    $errors = [];
    if ($salary < 4000) {
        $errors[] = "Minimum salary must be 4000.";
    }

    if (!empty($errors)) {
        echo json_encode([
            'status' => 'error',
            'code' => 'VALIDATION_ERROR',
            'message' => 'Invalid input data',
            'errors' => $errors
        ]);
        exit();
    }

    // Calculate credit limit based on salary and liabilities
    // 1. Calculate maximum credit limit (2x monthly salary)
    $max_credit_limit = $salary * 2;

    // 2. Calculate DBR-based limit (15% of salary for monthly payment)
    $monthly_dbr = $salary * 0.15;

    // 3. Calculate available monthly payment capacity
    $available_monthly = $salary - $liabilities - $expenses;

    // 4. Use the lower of DBR and available monthly as the payment capacity
    $payment_capacity = min($monthly_dbr, $available_monthly);

    // 5. Calculate final credit limit based on payment capacity
    // Assuming minimum payment is 5% of credit limit
    $credit_limit_from_capacity = $payment_capacity * 20; // (1/0.05)

    // 6. Take the lower of maximum credit limit and capacity-based limit
    $final_credit_limit = min($max_credit_limit, $credit_limit_from_capacity);

    // 7. Apply minimum and maximum bounds
    $min_credit_limit = 2000;  // Minimum credit limit
    $max_credit_limit = 50000; // Maximum credit limit

    if ($final_credit_limit < $min_credit_limit) {
        $final_credit_limit = $min_credit_limit;
    } elseif ($final_credit_limit > $max_credit_limit) {
        $final_credit_limit = $max_credit_limit;
    }

    // Round to nearest 100
    $final_credit_limit = floor($final_credit_limit / 100) * 100;

    // Generate a unique 7-digit application number
    $application_number = str_pad(mt_rand(1000000, 9999999), 7, '0', STR_PAD_LEFT);

    // Insert initial application record
    $insert_query = "INSERT INTO card_application_details (
        application_no,
        national_id,
        card_type,
        card_limit,
        status
    ) VALUES (?, ?, ?, ?, ?)";

    $insert_stmt = $con->prepare($insert_query);
    if (!$insert_stmt) {
        throw new Exception("Database error: " . $con->error);
    }

    $card_type = $final_credit_limit >= 17500 ? 'GOLD' : 'REWARD';
    $initial_status = 'pending';

    $insert_stmt->bind_param(
        "issds",
        $application_number,
        $national_id,
        $card_type,
        $final_credit_limit,
        $initial_status
    );

    if (!$insert_stmt->execute()) {
        throw new Exception("Failed to save initial card application: " . $insert_stmt->error);
    }

    // Prepare debug info
    $debug_info = [
        'salary' => $salary,
        'liabilities' => $liabilities,
        'expenses' => $expenses,
        'max_credit_limit' => $max_credit_limit,
        'monthly_dbr' => $monthly_dbr,
        'available_monthly' => $available_monthly,
        'payment_capacity' => $payment_capacity,
        'credit_limit_from_capacity' => $credit_limit_from_capacity,
        'final_credit_limit' => $final_credit_limit
    ];

    // Return approval decision with credit limit details
    $response = [
        'status' => 'success',
        'decision' => 'approved',
        'credit_limit' => $final_credit_limit,
        'min_credit_limit' => $min_credit_limit,
        'max_credit_limit' => $max_credit_limit,
        'application_number' => $application_number,
        'card_type' => $final_credit_limit >= 17500 ? 'GOLD' : 'REWARD', // Determine card type based on limit
        'debug' => $debug_info
    ];

    // Log the successful decision
    log_audit($con, null, 'Card Decision', "Card decision processed with credit limit: " . $final_credit_limit);

    echo json_encode($response);

} catch (Exception $e) {
    // Log the error
    log_audit($con, null, 'Card Decision Error', $e->getMessage());

    echo json_encode([
        'status' => 'error',
        'code' => 'SYSTEM_ERROR',
        'message' => $e->getMessage()
    ]);
    exit();
}

$con->close();
?> 