<?php
function log_audit($con, $user_id, $action_description, $details = null) {
    $ip_address = $_SERVER['REMOTE_ADDR'];
    $query = "INSERT INTO AuditTrail (user_id, action_description, ip_address, created_at, details) VALUES (?, ?, ?, NOW(), ?)";
    $stmt = $con->prepare($query);
    $stmt->bind_param("isss", $user_id, $action_description, $ip_address, $details);
    $stmt->execute();
    $stmt->close();
}
?>
