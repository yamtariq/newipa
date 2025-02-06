<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header('Content-Type: application/json');

require 'db_connect.php';
require 'audit_log.php';

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $headers = getallheaders();
        if (!isset($headers['api-key'])) {
            throw new Exception('API key is missing');
        }

        // Validate API key
        $api_key = $con->real_escape_string($headers['api-key']);
        $query = "SELECT * FROM API_Keys WHERE api_Key = ? AND (expires_at IS NULL OR expires_at > NOW())";
        $stmt = $con->prepare($query);
        $stmt->bind_param("s", $api_key);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            throw new Exception('Invalid or expired API key');
        }

        $data = json_decode(file_get_contents('php://input'), true);
        if (!$data || empty($data['national_id'])) {
            throw new Exception('Invalid input or missing national_id');
        }

        // Get user's notifications
        $stmt = $con->prepare("SELECT notifications FROM user_notifications WHERE national_id = ?");
        $stmt->bind_param("s", $data['national_id']);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            echo json_encode([
                'status' => 'success',
                'notifications' => []
            ]);
            exit();
        }

        $row = $result->fetch_assoc();
        $notificationsJson = $row['notifications'] ?? null;
        $notifications = [];
        
        if (!empty($notificationsJson)) {
            $notifications = json_decode($notificationsJson, true) ?? [];
        }
        
        // Filter unread notifications and fetch their details
        $unreadNotifications = [];
        $currentTime = date('Y-m-d H:i:s');
        
        foreach ($notifications as $notification) {
            // Skip if notification is read or expired
            if ($notification['status'] !== 'unread' || 
                ($notification['expires_at'] && $notification['expires_at'] < $currentTime)) {
                continue;
            }

            // Get template details
            $stmt = $con->prepare("
                SELECT * FROM notification_templates 
                WHERE id = ? 
                AND (expiry_at IS NULL OR expiry_at > ?)
            ");
            $stmt->bind_param("is", $notification['template_id'], $currentTime);
            $stmt->execute();
            $templateResult = $stmt->get_result();
            
            if ($templateResult->num_rows > 0) {
                $template = $templateResult->fetch_assoc();
                $additionalDataJson = $template['additional_data'] ?? null;
                $additionalData = null;
                
                if (!empty($additionalDataJson)) {
                    $additionalData = json_decode($additionalDataJson, true);
                }
                
                $unreadNotifications[] = [
                    'id' => $notification['template_id'],
                    'title' => $template['title'],
                    'body' => $template['body'],
                    'title_en' => $template['title_en'],
                    'body_en' => $template['body_en'],
                    'title_ar' => $template['title_ar'],
                    'body_ar' => $template['body_ar'],
                    'route' => $template['route'],
                    'additional_data' => $additionalData,
                    'created_at' => $notification['created_at'],
                    'expires_at' => $notification['expires_at'],
                    'status' => $notification['status']
                ];
            }
        }

        // Check for expired notifications and log them
        $expiredNotifications = array_filter($notifications, function($n) use ($currentTime) {
            return isset($n['expires_at']) && $n['expires_at'] < $currentTime && isset($n['template_id']);
        });

        if (!empty($expiredNotifications)) {
            $expiredIds = array_map(function($n) {
                return $n['template_id'] ?? null;
            }, $expiredNotifications);
            
            // Filter out any null values
            $expiredIds = array_filter($expiredIds);
            
            if (!empty($expiredIds)) {
                log_audit($con, $data['national_id'], 'notification_expired', json_encode([
                    'notification_ids' => $expiredIds,
                    'timestamp' => $currentTime
                ]));
            }
        }

        // Log notifications being delivered to user
        $notificationIds = array_map(function($n) {
            return $n['id'] ?? null;
        }, $unreadNotifications);

        // Filter out any null values
        $notificationIds = array_filter($notificationIds);

        if (!empty($notificationIds)) {
            log_audit($con, $data['national_id'], 'notification_delivered', json_encode([
                'notification_count' => count($unreadNotifications),
                'notification_ids' => $notificationIds,
                'timestamp' => date('Y-m-d H:i:s')
            ]));
        }

        // Mark notifications as read if requested
        if (!empty($data['mark_as_read']) && !empty($unreadNotifications)) {
            foreach ($notifications as &$notification) {
                if (isset($notification['status']) && $notification['status'] === 'unread') {
                    $notification['status'] = 'read';
                    $notification['read_at'] = date('Y-m-d H:i:s');
                }
            }
            
            // Update notifications in database
            $stmt = $con->prepare("UPDATE user_notifications SET notifications = ? WHERE national_id = ?");
            $notificationsJson = json_encode($notifications);
            $stmt->bind_param("ss", $notificationsJson, $data['national_id']);
            
            if ($stmt->execute()) {
                // Log notifications being marked as read
                $readNotificationIds = array_map(function($n) {
                    return $n['template_id'] ?? null;
                }, array_filter($unreadNotifications, function($n) {
                    return isset($n['status']) && $n['status'] === 'unread';
                }));
                
                // Filter out any null values
                $readNotificationIds = array_filter($readNotificationIds);
                
                if (!empty($readNotificationIds)) {
                    log_audit($con, $data['national_id'], 'notification_read', json_encode([
                        'notification_ids' => $readNotificationIds,
                        'timestamp' => date('Y-m-d H:i:s')
                    ]));
                }
            }
        }

        echo json_encode([
            'status' => 'success',
            'notifications' => $unreadNotifications
        ]);
    } else {
        throw new Exception('Invalid request method');
    }
} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    exit();
}

$con->close();
?> 