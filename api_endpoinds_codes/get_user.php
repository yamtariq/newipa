<?php
header("Content-Type: application/json");

// Include database connection
require_once 'db_connect.php';

// Check if API key is provided in the headers
if (!isset($_SERVER['HTTP_X_API_KEY']) || empty($_SERVER['HTTP_X_API_KEY'])) {
    echo json_encode([
        "success" => false,
        "message" => "API key is missing"
    ]);
    exit;
}

$apiKey = $_SERVER['HTTP_X_API_KEY'];

try {
    // Validate API key
    $apiKeyStmt = $con->prepare("SELECT * FROM API_Keys WHERE api_Key = ? AND expires_at > NOW()");
    $apiKeyStmt->bind_param("s", $apiKey);
    $apiKeyStmt->execute();
    $apiKeyResult = $apiKeyStmt->get_result();

    if ($apiKeyResult->num_rows === 0) {
        echo json_encode([
            "success" => false,
            "message" => "Invalid or expired API key"
        ]);
        exit;
    }

    // Check if nationalId is provided
    if (!isset($_GET['nationalId']) || empty($_GET['nationalId'])) {
        echo json_encode([
            "success" => false,
            "message" => "nationalId parameter is required"
        ]);
        exit;
    }

    $nationalId = $_GET['nationalId'];

    // Prepare SQL query to fetch user details
    $stmt = $con->prepare("SELECT * FROM Customers WHERE national_id = ?");
    $stmt->bind_param("s", $nationalId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // Fetch user data
        $user = $result->fetch_assoc();
        echo json_encode([
            "success" => true,
            "data" => $user
        ]);
    } else {
        // User not found
        echo json_encode([
            "success" => false,
            "message" => "User not found"
        ]);
    }
} catch (Exception $e) {
    // Handle unexpected errors
    echo json_encode([
        "success" => false,
        "message" => "Error: " . $e->getMessage()
    ]);
}

// Close database connections
$stmt->close();
$apiKeyStmt->close();
$con->close();
?>
