<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header('Content-Type: application/json');

require 'db_connect.php'; // Ensure this file is included for database connection
require 'audit_log.php';  // Include if you need to log actions

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
        FROM loan_application_details 
        WHERE national_id = ? 
        AND status NOT IN ('Rejected', 'Declined')
        AND status_date >= DATE_SUB(NOW(), INTERVAL 5 DAY)
        ORDER BY loan_id DESC 
        LIMIT 1");

    $check_stmt->bind_param("s", $national_id);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();

    if ($check_result->num_rows > 0) {
        $row = $check_result->fetch_assoc();
        echo json_encode([
            'status' => 'error',
            'code' => 'ACTIVE_APPLICATION_EXISTS',
            'message' => 'You have an active loan application. Please check your application status.',
            'message_ar' => 'لديك طلب تمويل نشط. يرجى التحقق من حالة طلبك.',
            'application_no' => $row['application_no'],
            'current_status' => $row['status']
        ]);
        exit();
    }

    // Proceed with loan decision if no active applications
    // Validate required fields
    $required_fields = ['salary', 'liabilities', 'expenses', 'requested_tenure'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || $data[$field] === '') {
            throw new Exception("Missing required field: $field");
        }
    }

    $salary           = (float)$data['salary'];
    $liabilities      = (float)$data['liabilities'];
    $expenses         = (float)$data['expenses'];  // Not used in the new formula, but we keep it if needed
    $requested_tenure = (int)$data['requested_tenure']; // Not used; we force 60 months below

    // Basic validations
    $errors = [];
    if ($salary < 4000) {
        $errors[] = "Minimum salary must be 4000.";
    }
    // You can remove or change the next check if you no longer want to validate requested_tenure range
    // Because you're specifically using 60 months below, you might just remove this block:
    // if ($requested_tenure < 12 || $requested_tenure > 60) {
    //     $errors[] = "Tenure must be between 12 and 60 months.";
    // }

    if (!empty($errors)) {
        echo json_encode([
            'status'  => 'error',
            'code'    => 'VALIDATION_ERROR',
            'message' => 'Invalid input data',
            'errors'  => $errors
        ]);
        exit();
    }

    // ------------------------------------------------------------------
    // NEW CALCULATION LOGIC per your specifications
    // ------------------------------------------------------------------
    // 1. dbr_emi = salary * 0.15
    $dbr_emi = $salary * 0.15;

    // 2. max_emi = salary - liabilities
    $max_emi = $salary - $liabilities;

    // 3. final EMI = which is lower between dbr_emi and max_emi
    $allowed_emi = min($dbr_emi, $max_emi);

    // Force a 60-month tenure (5 years) for the new calculations
    $tenure_months = 60;
    $tenure_years  = $tenure_months / 12;

    // Define a flat annual interest rate (adjust as needed)
    $flat_rate = 0.16; // 16%

    // 4. total loan with interest = emi * 60
    $initial_total_repayment = $allowed_emi * $tenure_months;

    // 5. Backward calculation of principal:
    //    totalRepayment = principal * (1 + rate * 5)
    //    => principal   = totalRepayment / (1 + rate * 5)
    $raw_principal = $initial_total_repayment / (1 + ($flat_rate * $tenure_years));

    // 6. Clamp principal between 10,000 and 300,000
    $min_principal = 10000;
    $max_principal = 300000;

    if ($raw_principal < $min_principal) {
        $final_principal = $min_principal;
    } elseif ($raw_principal > $max_principal) {
        $final_principal = $max_principal;
    } else {
        $final_principal = $raw_principal;
    }

    // 7. Recalculate final numbers based on clamped principal
    $total_repayment = $final_principal * (1 + ($flat_rate * $tenure_years));
    $actual_emi      = $total_repayment / $tenure_months;
    $total_interest  = $total_repayment - $final_principal;

    // ------------------------------------------------------------------
    // Prepare debug info for transparency
    // ------------------------------------------------------------------
    $debug_info = [
        'salary'                => $salary,
        'liabilities'           => $liabilities,
        'expenses'              => $expenses, // not used in final EMI, but kept for reference
        'flat_rate'             => $flat_rate,
        'dbr_emi'               => $dbr_emi,
        'max_emi'               => $max_emi,
        'allowed_emi'           => $allowed_emi,
        'initial_total_repayment' => $initial_total_repayment,
        'raw_principal_calc'    => $raw_principal,
        'clamped_principal'     => $final_principal,
        'tenure_months'         => $tenure_months,
        'tenure_years'          => $tenure_years,
        'total_interest'        => $total_interest,
        'recalculated_emi'      => $actual_emi
    ];

    // Generate a unique 7-digit application number
    $application_number = str_pad(mt_rand(1000000, 9999999), 7, '0', STR_PAD_LEFT);

    // Final response
    echo json_encode([
        'status'          => 'success',
        'decision'        => 'approved',
        'finance_amount'  => floor($final_principal), // or round as needed
        'tenure'          => $tenure_months,          // forced to 60
        'emi'             => round($actual_emi, 2),
        'flat_rate'       => $flat_rate,
        'total_repayment' => round($total_repayment, 2),
        'interest'        => round($total_interest, 2),
        'application_number' => $application_number,  // Add the application number to response
        'debug'           => $debug_info
    ]);

} catch (Exception $e) {
    echo json_encode([
        'status'  => 'error',
        'code'    => 'SYSTEM_ERROR',
        'message' => $e->getMessage()
    ]);
    exit();
}

$con->close();
?>
