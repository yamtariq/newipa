<?php
header("Content-Type: application/json");

// Include database connection file
require_once("../db_connect.php");

// Read JSON request body
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['nationalId']) || !isset($data['otp']) || !isset($data['userId'])) {
    echo json_encode(["success" => false, "message" => "Missing required parameters"]);
    exit;
}

// Extract data
$nationalId = $data['nationalId'];
$otp = $data['otp'];
$userId = $data['userId'];

// Check if OTP exists and is valid
$stmt = $con->prepare("SELECT otp, expiry_datetime FROM otp_requests WHERE national_id = ? AND verified_flag = 0 ORDER BY created_at DESC LIMIT 1");
$stmt->bind_param("s", $nationalId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows == 0) {
    echo json_encode(["success" => false, "message" => "Invalid or expired OTP"]);
    exit;
}

$row = $result->fetch_assoc();
$storedOtp = $row['otp'];
$expiryTime = strtotime($row['expiry_datetime']);
$currentTime = time();

// Check OTP validity
if ($otp != $storedOtp) {
    echo json_encode(["success" => false, "message" => "Incorrect OTP"]);
    exit;
}

if ($currentTime > $expiryTime) {
    echo json_encode(["success" => false, "message" => "OTP expired"]);
    exit;
}

// Mark OTP as verified
$updateStmt = $con->prepare("UPDATE otp_requests SET verified_flag = 1 WHERE national_id = ? AND otp = ?");
$updateStmt->bind_param("ss", $nationalId, $otp);
$updateStmt->execute();

// Success response
echo json_encode([
    "success" => true,
    "errors" => [],
    "result" => [
        "nationalId" => $nationalId,
        "otp" => $otp,
        "verifiedFlag" => true,
        "successMsg" => "Verified successfully.",
        "errCode" => 0,
        "errMsg" => null
    ],
    "type" => "N",
    "message" => null,
    "code" => null
]);

$stmt->close();
$updateStmt->close();
$con->close();
?>
