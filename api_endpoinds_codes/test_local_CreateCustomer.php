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

// Validate Required Parameter
if (!isset($data["nationalId"]) || empty($data["nationalId"])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Missing required parameter: nationalId"]);
    exit;
}

$nationalId = $data["nationalId"];

// Fetch Customer Data from Database
$sql = "SELECT * FROM CustomerCreationResponse WHERE nationalId = ?";
$stmt = $con->prepare($sql);
$stmt->bind_param("s", $nationalId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $customer = $result->fetch_assoc();
    
    // Success Response
    echo json_encode([
        "success" => true,
        "errors" => [],
        "result" => [
            "requestId" => $customer["requestId"],
            "nationalId" => $customer["nationalId"],
            "applicationFlag" => $customer["applicationFlag"],
            "applicationId" => $customer["applicationId"],
            "applicationStatus" => $customer["applicationStatus"],
            "customerId" => $customer["customerId"],
            "eligibleStatus" => $customer["eligibleStatus"],
            "eligibleAmount" => $customer["eligibleAmount"],
            "eligibleEmi" => $customer["eligibleEmi"],
            "productType" => $customer["productType"],
            "successMsg" => $customer["successMsg"],
            "errCode" => $customer["errCode"],
            "errMsg" => $customer["errMsg"]
        ],
        "type" => $customer["responseType"]
    ]);
} else {
    // Not Found Response
    http_response_code(404);
    echo json_encode(["success" => false, "message" => "Customer not found"]);
}

$stmt->close();
$con->close();
?>
