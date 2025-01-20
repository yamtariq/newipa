<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Start session if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Include required files
require_once '../config/config.php';
require_once '../includes/auth.php';
require_once '../db_connect.php';

// Check if user is logged in
if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit();
}

// Check if user has required permissions
if (!checkPermission('sales_admin') && !checkPermission('super_admin')) {
    header('Location: index.php');
    exit();
}

// Debug: Print request information
error_log("Request parameters: " . print_r($_GET, true));

// Validate input parameters
if (!isset($_GET['type']) || !isset($_GET['id'])) {
    die('Invalid request: Missing parameters');
}

$type = $_GET['type'];
$id = $_GET['id'];

// Debug: Print input values
error_log("Type: $type, ID: $id");

// Validate type parameter
if (!in_array($type, ['card', 'loan'])) {
    die('Invalid application type');
}

try {
    // Debug: Print connection status
    error_log("Database connection status: " . ($con ? "Connected" : "Not connected"));
    
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
        
        // Debug: Print the query
        error_log("Query for card: " . str_replace('?', $id, $query));
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
            WHERE la.application_id = ?
        ";
    }
    
    // Prepare and execute the query using mysqli
    $stmt = $con->prepare($query);
    if (!$stmt) {
        throw new Exception("Failed to prepare statement: " . $con->error);
    }
    
    $stmt->bind_param('s', $id);
    if (!$stmt->execute()) {
        throw new Exception("Failed to execute query: " . $stmt->error);
    }
    
    $result = $stmt->get_result();
    $application = $result->fetch_assoc();
    
    // Debug: Print application data
    error_log("Application data: " . print_r($application, true));
    
    if (!$application) {
        die('Application not found');
    }
    
} catch(Exception $e) {
    error_log("Error: " . $e->getMessage());
    die("An error occurred. Please try again later.");
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Application Details</title>
    <link href="../assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <style>
        .application-details {
            max-width: 1200px;
            margin: 20px auto;
            padding: 20px;
        }
        .detail-section {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .detail-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        .detail-item {
            margin-bottom: 10px;
        }
        .detail-item strong {
            color: #555;
            margin-right: 10px;
        }
        .actions-section {
            margin-top: 30px;
        }
        .action-form {
            display: flex;
            gap: 10px;
            align-items: center;
        }
        .status-badge {
            padding: 5px 10px;
            border-radius: 4px;
            font-weight: 500;
        }
        .status-pending { background: #ffd700; }
        .status-approved { background: #90ee90; }
        .status-rejected { background: #ffcccb; }
    </style>
</head>
<body>
    <?php include '../includes/header.php'; ?>
    
    <div class="application-details">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h1>Application Details</h1>
            <a href="<?php echo $type === 'card' ? 'card-applications.php' : 'loan-applications.php'; ?>" 
               class="btn btn-secondary">
                Back to List
            </a>
        </div>
        
        <!-- Application Information -->
        <div class="detail-section">
            <h3>Application Information</h3>
            <div class="detail-grid">
                <?php if ($type === 'card'): ?>
                    <div class="detail-item"><strong>Card ID:</strong> <?php echo htmlspecialchars($application['card_id']); ?></div>
                <?php else: ?>
                    <div class="detail-item"><strong>Application ID:</strong> <?php echo htmlspecialchars($application['application_id']); ?></div>
                <?php endif; ?>
                <div class="detail-item">
                    <strong>Status:</strong> 
                    <span class="status-badge status-<?php echo $application['status']; ?>">
                        <?php echo ucfirst(htmlspecialchars($application['status'])); ?>
                    </span>
                </div>
                <div class="detail-item"><strong>Created At:</strong> <?php echo htmlspecialchars($application['created_at']); ?></div>
                <div class="detail-item"><strong>National ID:</strong> <?php echo htmlspecialchars($application['national_id']); ?></div>
            </div>
        </div>
        
        <!-- Personal Information -->
        <?php if ($application['name']): ?>
        <div class="detail-section">
            <h3>Personal Information</h3>
            <div class="detail-grid">
                <div class="detail-item"><strong>Name:</strong> <?php echo htmlspecialchars($application['name']); ?></div>
                <div class="detail-item"><strong>Arabic Name:</strong> <?php echo htmlspecialchars($application['arabic_name']); ?></div>
                <div class="detail-item"><strong>Email:</strong> <?php echo htmlspecialchars($application['email']); ?></div>
                <div class="detail-item"><strong>Phone:</strong> <?php echo htmlspecialchars($application['phone']); ?></div>
                <div class="detail-item"><strong>Date of Birth:</strong> <?php echo htmlspecialchars($application['dob']); ?></div>
                <div class="detail-item"><strong>Language:</strong> <?php echo htmlspecialchars($application['language']); ?></div>
                <div class="detail-item"><strong>National Address:</strong> <?php echo htmlspecialchars($application['national_address']); ?></div>
            </div>
        </div>
        
        <!-- Employment Information -->
        <div class="detail-section">
            <h3>Employment Information</h3>
            <div class="detail-grid">
                <div class="detail-item"><strong>Employment Status:</strong> <?php echo htmlspecialchars($application['employment_status']); ?></div>
                <div class="detail-item"><strong>Employer:</strong> <?php echo htmlspecialchars($application['employer_name']); ?></div>
                <div class="detail-item"><strong>Employment Date:</strong> <?php echo htmlspecialchars($application['employment_date']); ?></div>
                <div class="detail-item"><strong>Salary:</strong> <?php echo htmlspecialchars($application['salary']); ?></div>
                <div class="detail-item"><strong>Dependents:</strong> <?php echo htmlspecialchars($application['dependents']); ?></div>
            </div>
        </div>
        <?php endif; ?>
        
        <!-- Product Specific Information -->
        <div class="detail-section">
            <?php if ($type === 'card'): ?>
                <h3>Card Details</h3>
                <div class="detail-grid">
                    <div class="detail-item"><strong>Card Type:</strong> <?php echo htmlspecialchars($application['card_type']); ?></div>
                    <div class="detail-item"><strong>Card Limit:</strong> <?php echo htmlspecialchars($application['card_limit']); ?></div>
                </div>
            <?php else: ?>
                <h3>Loan Details</h3>
                <div class="detail-grid">
                    <div class="detail-item"><strong>Loan Amount:</strong> <?php echo htmlspecialchars($application['loan_amount']); ?></div>
                    <div class="detail-item"><strong>Loan Term:</strong> <?php echo htmlspecialchars($application['loan_term']); ?> months</div>
                    <div class="detail-item"><strong>Purpose:</strong> <?php echo htmlspecialchars($application['purpose']); ?></div>
                </div>
            <?php endif; ?>
        </div>
        
        <!-- Actions Section -->
        <?php if (checkPermission('credit_admin')): ?>
        <div class="detail-section">
            <h3>Actions</h3>
            <form method="POST" action="update_application_status.php" class="action-form">
                <?php if ($type === 'card'): ?>
                    <input type="hidden" name="application_id" value="<?php echo htmlspecialchars($application['card_id']); ?>">
                <?php else: ?>
                    <input type="hidden" name="application_id" value="<?php echo htmlspecialchars($application['application_id']); ?>">
                <?php endif; ?>
                <input type="hidden" name="application_type" value="<?php echo htmlspecialchars($type); ?>">
                <select name="status" class="form-control" style="width: auto;">
                    <option value="pending" <?php echo $application['status'] == 'pending' ? 'selected' : ''; ?>>Pending</option>
                    <option value="approved" <?php echo $application['status'] == 'approved' ? 'selected' : ''; ?>>Approved</option>
                    <option value="rejected" <?php echo $application['status'] == 'rejected' ? 'selected' : ''; ?>>Rejected</option>
                </select>
                <button type="submit" class="btn btn-primary">Update Status</button>
            </form>
        </div>
        <?php endif; ?>
    </div>

    <script src="../assets/js/bootstrap.bundle.min.js"></script>
</body>
</html>
