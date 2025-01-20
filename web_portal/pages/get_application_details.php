<?php
// Include config first to ensure session is started
require_once '../config/config.php';

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Debug logging function
function debug_log($message, $data = null) {
    $log = date('Y-m-d H:i:s') . " - " . $message;
    if ($data !== null) {
        $log .= ": " . print_r($data, true);
    }
    error_log($log);
}

// Function to send JSON error response
function send_error($message, $code = 400) {
    http_response_code($code);
    header('Content-Type: application/json');
    echo json_encode(['error' => $message, 'code' => $code]);
    exit;
}

// Include other required files
require_once '../includes/auth.php';
require_once '../db_connect.php';

// Log all incoming request data
debug_log("Request details", [
    'method' => $_SERVER['REQUEST_METHOD'],
    'session_id' => session_id(),
    'session_data' => $_SESSION,
    'cookies' => $_COOKIE,
    'headers' => getallheaders(),
    'get' => $_GET
]);

// Check session status
if (session_status() !== PHP_SESSION_ACTIVE) {
    debug_log("Session not active", ['session_status' => session_status()]);
    send_error('Session not active', 401);
}

// Check if user is logged in
if (!isset($_SESSION['employee_id'])) {
    debug_log("No employee_id in session", $_SESSION);
    send_error('Session expired', 401);
}

// Check if session is valid
$sessionTimeout = 86400; // 24 hours in seconds
if (!isset($_SESSION['last_activity']) || (time() - $_SESSION['last_activity'] > $sessionTimeout)) {
    debug_log("Session timeout", [
        'last_activity' => isset($_SESSION['last_activity']) ? $_SESSION['last_activity'] : 'not set',
        'current_time' => time(),
        'timeout' => $sessionTimeout
    ]);
    session_unset();
    session_destroy();
    send_error('Session timeout', 401);
}

// Update last activity time
$_SESSION['last_activity'] = time();

// Set response headers
header('Content-Type: text/html; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');

// Check if this is an AJAX request
if (!isset($_SERVER['HTTP_X_REQUESTED_WITH']) || strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) != 'xmlhttprequest') {
    debug_log("Direct access attempt blocked");
    send_error('Direct access not allowed', 403);
}

// Check if user has required permissions
if (!checkPermission('sales_admin') && !checkPermission('super_admin')) {
    debug_log("Permission denied for user", $_SESSION['employee_id']);
    send_error('Permission denied', 403);
}

// Validate input parameters
if (!isset($_GET['type']) || !isset($_GET['id'])) {
    debug_log("Missing parameters", $_GET);
    send_error('Missing required parameters');
}

$type = $_GET['type'];
$id = $_GET['id'];

// Validate application type
if (!in_array($type, ['card', 'loan'])) {
    debug_log("Invalid application type", $type);
    send_error('Invalid application type');
}

try {
    // Prepare the query based on application type
    if ($type === 'card') {
        $query = "
            SELECT 
                ca.*,
                u.name,
                u.arabic_name,
                u.email,
                u.phone,
                u.dob,
                u.doe,
                u.language,
                u.dependents,
                u.salary,
                u.employment_status,
                u.employer_name,
                u.employment_date,
                u.national_address
            FROM card_application_details ca
            LEFT JOIN Users u ON ca.national_id = u.national_id
            WHERE ca.card_id = ?
        ";
        
        // Debug: Print the exact query with the ID
        debug_log("Query: " . str_replace('?', $id, $query));
    } else {
        $query = "
            SELECT 
                la.*,
                u.name,
                u.arabic_name,
                u.email,
                u.phone,
                u.dob,
                u.doe,
                u.language,
                u.dependents,
                u.salary,
                u.employment_status,
                u.employer_name,
                u.employment_date,
                u.national_address
            FROM loan_applications la
            LEFT JOIN Users u ON la.national_id = u.national_id
            WHERE la.loan_id = ?
        ";
        
        // Debug: Print the exact query with the ID
        debug_log("Query: " . str_replace('?', $id, $query));
    }
    
    // Prepare and execute the query using mysqli
    $stmt = $con->prepare($query);
    if (!$stmt) {
        debug_log("Failed to prepare statement", $con->error);
        throw new Exception("Failed to prepare statement: " . $con->error);
    }
    
    $stmt->bind_param('s', $id);
    if (!$stmt->execute()) {
        debug_log("Failed to execute query", $stmt->error);
        throw new Exception("Failed to execute query: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    $application = $result->fetch_assoc();
    debug_log("Query result", $application ? "Found" : "Not found");
    
    if (!$application) {
        debug_log("Application not found", ["type" => $type, "id" => $id]);
        send_error('Application not found', 404);
    }
    
    // Output the application details
    echo '<div class="application-details">';
    
    // Application Information
    echo '<div class="detail-section">';
    echo '<h3>Application Information</h3>';
    echo '<div class="detail-grid">';
    if ($type === 'card') {
        echo '<div class="detail-item"><strong>Card ID:</strong> ' . htmlspecialchars($application['card_id']) . '</div>';
    } else {
        echo '<div class="detail-item"><strong>Loan ID:</strong> ' . htmlspecialchars($application['loan_id']) . '</div>';
    }
    echo '<div class="detail-item"><strong>Status:</strong> ' . htmlspecialchars($application['status']) . '</div>';
    echo '<div class="detail-item"><strong>Created At:</strong> ' . htmlspecialchars($application['created_at']) . '</div>';
    echo '<div class="detail-item"><strong>National ID:</strong> ' . htmlspecialchars($application['national_id']) . '</div>';
    echo '</div></div>';
    
    // Personal Information
    if ($application['name']) { // Only show if user data exists
        echo '<div class="detail-section">';
        echo '<h3>Personal Information</h3>';
        echo '<div class="detail-grid">';
        echo '<div class="detail-item"><strong>Name:</strong> ' . htmlspecialchars($application['name']) . '</div>';
        echo '<div class="detail-item"><strong>Arabic Name:</strong> ' . htmlspecialchars($application['arabic_name']) . '</div>';
        echo '<div class="detail-item"><strong>Email:</strong> ' . htmlspecialchars($application['email']) . '</div>';
        echo '<div class="detail-item"><strong>Phone:</strong> ' . htmlspecialchars($application['phone']) . '</div>';
        echo '<div class="detail-item"><strong>Date of Birth:</strong> ' . htmlspecialchars($application['dob']) . '</div>';
        echo '<div class="detail-item"><strong>Language:</strong> ' . htmlspecialchars($application['language']) . '</div>';
        echo '<div class="detail-item"><strong>National Address:</strong> ' . htmlspecialchars($application['national_address']) . '</div>';
        echo '</div></div>';
        
        // Employment Information
        echo '<div class="detail-section">';
        echo '<h3>Employment Information</h3>';
        echo '<div class="detail-grid">';
        echo '<div class="detail-item"><strong>Employment Status:</strong> ' . htmlspecialchars($application['employment_status']) . '</div>';
        echo '<div class="detail-item"><strong>Employer:</strong> ' . htmlspecialchars($application['employer_name']) . '</div>';
        echo '<div class="detail-item"><strong>Employment Date:</strong> ' . htmlspecialchars($application['employment_date']) . '</div>';
        echo '<div class="detail-item"><strong>Salary:</strong> ' . htmlspecialchars($application['salary']) . '</div>';
        echo '<div class="detail-item"><strong>Dependents:</strong> ' . htmlspecialchars($application['dependents']) . '</div>';
        echo '</div></div>';
    }
    
    // Product Specific Information
    if ($type === 'card') {
        echo '<div class="detail-section">';
        echo '<h3>Card Details</h3>';
        echo '<div class="detail-grid">';
        echo '<div class="detail-item"><strong>Card Type:</strong> ' . htmlspecialchars($application['card_type']) . '</div>';
        echo '<div class="detail-item"><strong>Card Limit:</strong> ' . htmlspecialchars($application['card_limit']) . '</div>';
        echo '</div></div>';
    } else {
        echo '<div class="detail-section">';
        echo '<h3>Loan Details</h3>';
        echo '<div class="detail-grid">';
        echo '<div class="detail-item"><strong>Loan Amount:</strong> ' . htmlspecialchars($application['loan_amount']) . '</div>';
        echo '<div class="detail-item"><strong>Loan Term:</strong> ' . htmlspecialchars($application['loan_term']) . ' months</div>';
        echo '<div class="detail-item"><strong>Purpose:</strong> ' . htmlspecialchars($application['purpose']) . '</div>';
        echo '</div></div>';
    }
    
    // Actions Section
    if (checkPermission('credit_admin')) {
        echo '<div class="actions-section">';
        echo '<h3>Actions</h3>';
        echo '<form method="POST" class="action-form" onsubmit="return updateApplicationStatus(this);">';
        if ($type === 'card') {
            echo '<input type="hidden" name="application_id" value="' . htmlspecialchars($application['card_id']) . '">';
        } else {
            echo '<input type="hidden" name="application_id" value="' . htmlspecialchars($application['loan_id']) . '">';
        }
        echo '<input type="hidden" name="application_type" value="' . htmlspecialchars($type) . '">';
        echo '<select name="status" class="form-control">';
        echo '<option value="pending" ' . ($application['status'] == 'pending' ? 'selected' : '') . '>Pending</option>';
        echo '<option value="approved" ' . ($application['status'] == 'approved' ? 'selected' : '') . '>Approved</option>';
        echo '<option value="rejected" ' . ($application['status'] == 'rejected' ? 'selected' : '') . '>Rejected</option>';
        echo '</select>';
        echo '<button type="submit" class="btn btn-primary">Update Status</button>';
        echo '</form>';
        echo '</div>';
    }
    
    echo '</div>';
    
    // Close the statement
    $stmt->close();
    
} catch(Exception $e) {
    debug_log("Error: " . $e->getMessage());
    send_error('An error occurred while processing your request', 500);
}
