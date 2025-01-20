<?php
require 'db_connect.php';

// Set response headers
header('Content-Type: application/json');

// Helper function to send JSON response
function sendResponse($success, $data = null, $message = null) {
    $response = ['success' => $success];
    if ($data !== null) $response['data'] = $data;
    if ($message !== null) $response['message'] = $message;
    echo json_encode($response);
    exit;
}

// Helper function to fetch last update timestamps for all content
function fetchLastUpdates($con) {
    $updates = [];
    
    // Define the content types we want to track
    $contentTypes = [
        ['page' => 'home', 'key_name' => 'slideshow_content'],
        ['page' => 'home', 'key_name' => 'slideshow_content_ar'],
        ['page' => 'home', 'key_name' => 'contact_details'],
        ['page' => 'home', 'key_name' => 'contact_details_ar'],
        ['page' => 'loans', 'key_name' => 'loan_ad'],
        ['page' => 'cards', 'key_name' => 'card_ad']
    ];
    
    foreach ($contentTypes as $type) {
        $stmt = $con->prepare("SELECT last_updated FROM master_config WHERE page = ? AND key_name = ?");
        if (!$stmt) continue;
        
        $stmt->bind_param("ss", $type['page'], $type['key_name']);
        if (!$stmt->execute()) continue;
        
        $result = $stmt->get_result();
        if ($row = $result->fetch_assoc()) {
            $updates[$type['key_name']] = $row['last_updated'];
        }
    }
    
    return $updates;
}

// Helper function to fetch all content data
function fetchAllContent($con) {
    $content = [];
    
    // Define the content types we want to fetch
    $contentTypes = [
        ['page' => 'home', 'key_name' => 'slideshow_content'],
        ['page' => 'home', 'key_name' => 'slideshow_content_ar'],
        ['page' => 'home', 'key_name' => 'contact_details'],
        ['page' => 'home', 'key_name' => 'contact_details_ar'],
        ['page' => 'loans', 'key_name' => 'loan_ad'],
        ['page' => 'cards', 'key_name' => 'card_ad']
    ];
    
    foreach ($contentTypes as $type) {
        $stmt = $con->prepare("SELECT value, last_updated FROM master_config WHERE page = ? AND key_name = ?");
        if (!$stmt) continue;
        
        $stmt->bind_param("ss", $type['page'], $type['key_name']);
        if (!$stmt->execute()) continue;
        
        $result = $stmt->get_result();
        if ($row = $result->fetch_assoc()) {
            $content[$type['key_name']] = [
                'page' => $type['page'],
                'key_name' => $type['key_name'],
                'data' => json_decode($row['value'], true),
                'last_updated' => $row['last_updated']
            ];
        }
    }
    
    return $content;
}

try {
    // Check if action parameter is provided
    if (!isset($_GET['action'])) {
        sendResponse(false, null, 'Missing required parameter: action');
    }
    
    $action = $_GET['action'];
    
    switch ($action) {
        case 'checkupdate':
            // Return last update timestamps for all content
            $updates = fetchLastUpdates($con);
            if (empty($updates)) {
                sendResponse(false, null, 'No content found');
            }
            sendResponse(true, $updates);
            break;
            
        case 'fetchdata':
            // Return all content data
            $content = fetchAllContent($con);
            if (empty($content)) {
                sendResponse(false, null, 'No content found');
            }
            sendResponse(true, $content);
            break;
            
        default:
            sendResponse(false, null, 'Invalid action');
    }

} catch (Exception $e) {
    sendResponse(false, null, 'Server error: ' . $e->getMessage());
} finally {
    if (isset($con)) {
        $con->close();
    }
}
?>
