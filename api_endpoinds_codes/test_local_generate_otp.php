<?php
header("Content-Type: application/json");

// Include database connection file
require_once("../db_connect.php");

// Read JSON request body
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['nationalId']) || !isset($data['mobileNo']) || !isset($data['purpose']) || !isset($data['userId'])) {
    echo json_encode(["success" => false, "message" => "Missing required parameters"]);
    exit;
}

// Extract data
$nationalId = $data['nationalId'];
$mobileNo = $data['mobileNo'];
$purpose = $data['purpose'];
$userId = $data['userId'];
$otp = rand(100000, 999999); // Generate a 6-digit OTP
$expiryTime = date("Y-m-d H:i:s", strtotime("+5 minutes")); // OTP valid for 5 minutes

// Insert OTP record into the database
$stmt = $con->prepare("INSERT INTO otp_requests (national_id, mobile_no, otp, purpose, user_id, expiry_datetime, verified_flag) 
                        VALUES (?, ?, ?, ?, ?, ?, 0)");
$stmt->bind_param("sssiss", $nationalId, $mobileNo, $otp, $purpose, $userId, $expiryTime);

if ($stmt->execute()) {
    // Success response with OTP (In real-world, send via SMS, do not expose OTP in response)
    echo json_encode([
        "success" => true,
        "errors" => [],
        "result" => [
            "nationalId" => $nationalId,
            "otp" => $otp,
            "expiryDate" => $expiryTime,
            "successMsg" => "Success",
            "errCode" => 0,
            "errMsg" => null
        ],
        "type" => "N",
        "message" => null,
        "code" => null
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Failed to generate OTP"]);
}

$stmt->close();
$con->close();
?>
