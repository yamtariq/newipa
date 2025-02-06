<?php
header("Content-Type: application/json");

// Include Database Connection
require_once '../db_connect.php';

// Validate HTTP Method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "message" => "Method Not Allowed"]);
    exit;
}

// Read JSON Input
$data = json_decode(file_get_contents("php://input"), true);

// Validate Headers
$requiredHeaders = ["Authorization", "X-APP-ID", "X-API-KEY", "X-Organization-No"];
$headers = getallheaders();
foreach ($requiredHeaders as $header) {
    if (!isset($headers[$header])) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Missing required headers: $header"]);
        exit;
    }
}

// Validate Required Parameters
$requiredFields = ["nationalId", "applicationId", "acceptFlag", "nameOnCardCode"];
foreach ($requiredFields as $field) {
    if (!isset($data[$field]) || $data[$field] === '') {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Missing required parameter: $field"]);
        exit;
    }
}

// Extract Data
$nationalId = $data["nationalId"];
$applicationId = $data["applicationId"];
$acceptFlag = $data["acceptFlag"];
$nameOnCardCode = $data["nameOnCardCode"];
$updateFlag = true; // Assume update is successful
$successMsg = "SUCCESS";
$errCode = 0;
$errMsg = NULL;
$responseType = "N";

// Check if Customer Exists
$sql_check = "SELECT * FROM CustomerUpdateResponse WHERE nationalId = ? AND applicationId = ?";
$stmt_check = $con->prepare($sql_check);
$stmt_check->bind_param("ss", $nationalId, $applicationId);
$stmt_check->execute();
$result_check = $stmt_check->get_result();

if ($result_check->num_rows > 0) {
    // Update Existing Record
    $sql_update = "UPDATE CustomerUpdateResponse 
                   SET acceptFlag = ?, nameOnCardCode = ?, updateFlag = ?, 
                   successMsg = ?, errCode = ?, errMsg = ?, responseType = ?, updated_at = NOW() 
                   WHERE nationalId = ? AND applicationId = ?";
    $stmt = $con->prepare($sql_update);
    $stmt->bind_param("iisbissss", 
        $acceptFlag, $nameOnCardCode, $updateFlag, 
        $successMsg, $errCode, $errMsg, $responseType, 
        $nationalId, $applicationId
    );
} else {
    // Insert New Record
    $sql_insert = "INSERT INTO CustomerUpdateResponse 
                   (nationalId, applicationId, acceptFlag, nameOnCardCode, updateFlag, 
                   successMsg, errCode, errMsg, responseType) 
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    $stmt = $con->prepare($sql_insert);
    $stmt->bind_param("ssiiisbss", 
        $nationalId, $applicationId, $acceptFlag, $nameOnCardCode, $updateFlag, 
        $successMsg, $errCode, $errMsg, $responseType
    );
}

// Execute Query
if ($stmt->execute()) {
    echo json_encode([
        "success" => true,
        "errors" => [],
        "result" => [
            "nationalId" => $nationalId,
            "applicationId" => $applicationId,
            "updateFlag" => $updateFlag,
            "successMsg" => $successMsg,
            "errCode" => $errCode,
            "errMsg" => $errMsg
        ],
        "type" => $responseType
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Database Error",
        "errors" => [$stmt->error]
    ]);
}

$stmt->close();
$con->close();
?>
