<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header('Content-Type: application/json');

require 'db_connect.php';

define('TOKEN_EXPIRY', 3600); // 1 hour

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    // Parse input data
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data || !isset($data['refresh_token'])) {
        throw new Exception('Invalid request data');
    }

    $refreshToken = $data['refresh_token'];

    // Verify refresh token in database
    $stmt = $con->prepare("
        SELECT user_id, national_id 
        FROM user_tokens 
        WHERE refresh_token = ? AND refresh_expires_at > NOW()
    ");
    $stmt->bind_param("s", $refreshToken);
    $stmt->execute();
    $result = $stmt->get_result();

    if (!$result->num_rows) {
        throw new Exception('Invalid or expired refresh token');
    }

    $user = $result->fetch_assoc();

    // Generate new access token
    $accessToken = bin2hex(random_bytes(32));
    $accessExpiry = time() + TOKEN_EXPIRY;

    // Update access token in database
    $stmt = $con->prepare("
        UPDATE user_tokens 
        SET access_token = ?, 
            access_expires_at = FROM_UNIXTIME(?) 
        WHERE user_id = ?
    ");
    $stmt->bind_param("sis", $accessToken, $accessExpiry, $user['user_id']);
    $stmt->execute();

    echo json_encode([
        'success' => true,
        'access_token' => $accessToken,
        'expires_in' => TOKEN_EXPIRY,
        'token_type' => 'Bearer'
    ]);

} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'error' => 'invalid_token',
        'message' => $e->getMessage()
    ]);
}
