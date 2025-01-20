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
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Invalid request method');
    }

    $headers = getallheaders();
    if (!isset($headers['api-key'])) {
        throw new Exception('API key is missing');
    }

    // Validate API key
    $api_key = $con->real_escape_string($headers['api-key']);
    $query = "SELECT * FROM API_Keys WHERE api_key = ? AND (expires_at IS NULL OR expires_at > NOW())";
    $stmt = $con->prepare($query);
    $stmt->bind_param("s", $api_key);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        throw new Exception('Invalid or expired API key');
    }

    // Parse input data
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$data) {
        throw new Exception('Invalid JSON input');
    }

    // Check if it's a multi-language notification
    $isMultiLanguage = isset($data['title_en']) && isset($data['body_en']) && isset($data['title_ar']) && isset($data['body_ar']);

    if (!$isMultiLanguage && (!isset($data['title']) || !isset($data['body']))) {
        throw new Exception("Either provide single language notification (title + body) or multi-language notification (title_en + body_en + title_ar + body_ar)");
    }

    // Initialize target users array
    $targetUsers = [];

    // Case 1: Single user
    if (!empty($data['national_id'])) {
        $stmt = $con->prepare("SELECT national_id FROM Users WHERE national_id = ?");
        $stmt->bind_param("s", $data['national_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        while ($row = $result->fetch_assoc()) {
            $targetUsers[] = $row['national_id'];
        }
    }

    // Case 2: Multiple specific users
    else if (!empty($data['national_ids']) && is_array($data['national_ids'])) {
        $ids = array_map([$con, 'real_escape_string'], $data['national_ids']);
        $idList = "'" . implode("','", $ids) . "'";
        $result = $con->query("SELECT national_id FROM Users WHERE national_id IN ($idList)");
        while ($row = $result->fetch_assoc()) {
            $targetUsers[] = $row['national_id'];
        }
    }

    // Case 3: Filtered users
    else if (!empty($data['filters']) && is_array($data['filters'])) {
        $conditions = [];
        $params = [];
        $types = "";
        
        // Check if this is an OR operation
        $isOrOperation = isset($data['filter_operation']) && strtoupper($data['filter_operation']) === 'OR';
        $filterGroups = [];

        foreach ($data['filters'] as $key => $value) {
            $currentConditions = [];
            switch ($key) {
                case 'salary_range':
                    if (isset($value['min'])) {
                        $currentConditions[] = "salary >= ?";
                        $params[] = $value['min'];
                        $types .= "i";
                    }
                    if (isset($value['max'])) {
                        $currentConditions[] = "salary <= ?";
                        $params[] = $value['max'];
                        $types .= "i";
                    }
                    if (!empty($currentConditions)) {
                        $filterGroups[] = "(" . implode(" AND ", $currentConditions) . ")";
                    }
                    break;

                case 'employment_status':
                    $currentConditions[] = "employment_status = ?";
                    $params[] = $value;
                    $types .= "s";
                    $filterGroups[] = implode(" AND ", $currentConditions);
                    break;

                case 'employer_name':
                    $currentConditions[] = "employer_name = ?";
                    $params[] = $value;
                    $types .= "s";
                    $filterGroups[] = implode(" AND ", $currentConditions);
                    break;

                case 'language':
                    $currentConditions[] = "language = ?";
                    $params[] = $value;
                    $types .= "s";
                    $filterGroups[] = implode(" AND ", $currentConditions);
                    break;

                case 'loan_status':
                    $currentConditions[] = "EXISTS (SELECT 1 FROM loan_application_details WHERE loan_application_details.national_id = Users.national_id AND loan_application_details.status = ?)";
                    $params[] = $value;
                    $types .= "s";
                    $filterGroups[] = implode(" AND ", $currentConditions);
                    break;

                case 'card_status':
                    $currentConditions[] = "EXISTS (SELECT 1 FROM card_application_details WHERE card_application_details.national_id = Users.national_id AND card_application_details.status = ?)";
                    $params[] = $value;
                    $types .= "s";
                    $filterGroups[] = implode(" AND ", $currentConditions);
                    break;

                default:
                    // Dynamic filter handling for all three tables
                    $tableColumn = explode('.', $key);
                    if (count($tableColumn) === 2) {
                        $table = $tableColumn[0];
                        $column = $tableColumn[1];
                        
                        // Validate table name to prevent SQL injection
                        $allowedTables = [
                            'Users', 
                            'loan_application_details',
                            'card_application_details'
                        ];
                        if (!in_array($table, $allowedTables)) {
                            continue;
                        }

                        // Add debug logging
                        error_log("Processing filter for table: $table, column: $column");
                        error_log("Filter value: " . json_encode($value));

                        if (is_array($value) && isset($value[0])) {
                            // Multiple conditions for same column (already OR'ed)
                            $columnConditions = [];
                            foreach ($value as $condition) {
                                if (!isset($condition['operator']) || !isset($condition['value'])) {
                                    continue;
                                }

                                $operator = $condition['operator'];
                                $filterValue = $condition['value'];

                                // Validate operator to prevent SQL injection
                                $allowedOperators = ['=', '!=', '>', '<', '>=', '<=', 'LIKE', 'IN', 'BETWEEN'];
                                if (!in_array($operator, $allowedOperators)) {
                                    continue;
                                }

                                if ($operator === 'BETWEEN' && is_array($filterValue) && count($filterValue) === 2) {
                                    if ($table === 'Users') {
                                        $columnConditions[] = "($column >= ? AND $column <= ?)";
                                    } else {
                                        $columnConditions[] = "EXISTS (SELECT 1 FROM $table WHERE $table.national_id = Users.national_id AND $table.$column >= ? AND $table.$column <= ?)";
                                    }
                                    $params[] = $filterValue[0];
                                    $params[] = $filterValue[1];
                                    $types .= "ss";
                                } else if ($operator === 'IN' && is_array($filterValue)) {
                                    $placeholders = str_repeat('?,', count($filterValue) - 1) . '?';
                                    if ($table === 'Users') {
                                        $columnConditions[] = "$column IN ($placeholders)";
                                    } else {
                                        $columnConditions[] = "EXISTS (SELECT 1 FROM $table WHERE $table.national_id = Users.national_id AND $table.$column IN ($placeholders))";
                                    }
                                    foreach ($filterValue as $val) {
                                        $params[] = $val;
                                        $types .= 's';
                                    }
                                } else {
                                    if ($table === 'Users') {
                                        $columnConditions[] = "$column $operator ?";
                                    } else {
                                        $columnConditions[] = "EXISTS (SELECT 1 FROM $table WHERE $table.national_id = Users.national_id AND $table.$column $operator ?)";
                                    }
                                    $params[] = $filterValue;
                                    $types .= 's';
                                }
                            }
                            
                            if (!empty($columnConditions)) {
                                $filterGroups[] = "(" . implode(" OR ", $columnConditions) . ")";
                            }
                        } else if (is_array($value) && isset($value['operator'])) {
                            // Single condition
                            $operator = $value['operator'];
                            $filterValue = $value['value'];
                            
                            $allowedOperators = ['=', '!=', '>', '<', '>=', '<=', 'LIKE', 'IN', 'BETWEEN'];
                            if (!in_array($operator, $allowedOperators)) {
                                continue;
                            }
                            
                            if ($operator === 'BETWEEN' && is_array($filterValue) && count($filterValue) === 2) {
                                if ($table === 'Users') {
                                    $currentConditions[] = "($column >= ? AND $column <= ?)";
                                } else {
                                    $currentConditions[] = "EXISTS (SELECT 1 FROM $table WHERE $table.national_id = Users.national_id AND $table.$column >= ? AND $table.$column <= ?)";
                                }
                                $params[] = $filterValue[0];
                                $params[] = $filterValue[1];
                                $types .= "ss";
                            } else if ($operator === 'IN' && is_array($filterValue)) {
                                $placeholders = str_repeat('?,', count($filterValue) - 1) . '?';
                                if ($table === 'Users') {
                                    $currentConditions[] = "$column IN ($placeholders)";
                                } else {
                                    $currentConditions[] = "EXISTS (SELECT 1 FROM $table WHERE $table.national_id = Users.national_id AND $table.$column IN ($placeholders))";
                                }
                                foreach ($filterValue as $val) {
                                    $params[] = $val;
                                    $types .= 's';
                                }
                            } else {
                                if ($table === 'Users') {
                                    $currentConditions[] = "$column $operator ?";
                                } else {
                                    $currentConditions[] = "EXISTS (SELECT 1 FROM $table WHERE $table.national_id = Users.national_id AND $table.$column $operator ?)";
                                }
                                $params[] = $filterValue;
                                $types .= 's';
                            }
                            if (!empty($currentConditions)) {
                                $filterGroups[] = implode(" AND ", $currentConditions);
                            }
                        }
                    }
                    break;
            }
        }

        if (!empty($filterGroups)) {
            // Combine all filter groups with AND or OR
            $conditions[] = "(" . implode($isOrOperation ? " OR " : " AND ", $filterGroups) . ")";
        }

        if (!empty($conditions)) {
            $query = "SELECT national_id FROM Users WHERE " . implode(" AND ", $conditions);
            // Debug logging
            error_log("Generated SQL Query: " . $query);
            error_log("Parameters: " . json_encode($params));
            error_log("Types string: " . $types);
            
            $stmt = $con->prepare($query);
            if (!empty($params)) {
                $stmt->bind_param($types, ...$params);
            }
            $stmt->execute();
            $result = $stmt->get_result();
            
            // Debug logging
            error_log("Number of rows found: " . $result->num_rows);
            
            while ($row = $result->fetch_assoc()) {
                $targetUsers[] = $row['national_id'];
            }
        } else {
            error_log("No conditions were generated from the filters");
        }
    }

    if (empty($targetUsers)) {
        throw new Exception('No target users found for the given criteria');
    }

    // First, save the notification template
    $stmt = $con->prepare("INSERT INTO notification_templates (
        title, body, title_en, body_en, title_ar, body_ar, 
        route, additional_data, target_criteria, created_at, expiry_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

    $title = $isMultiLanguage ? null : $data['title'];
    $body = $isMultiLanguage ? null : $data['body'];
    $titleEn = $isMultiLanguage ? $data['title_en'] : null;
    $bodyEn = $isMultiLanguage ? $data['body_en'] : null;
    $titleAr = $isMultiLanguage ? $data['title_ar'] : null;
    $bodyAr = $isMultiLanguage ? $data['body_ar'] : null;
    $route = $data['route'] ?? null;
    $additionalData = isset($data['additionalData']) ? json_encode($data['additionalData']) : null;
    $targetCriteria = json_encode($data['filters'] ?? null);
    
    // Set current time and expiry date
    $createdAt = date('Y-m-d H:i:s');
    $expiryAt = isset($data['expiry_at']) ? $data['expiry_at'] : date('Y-m-d H:i:s', strtotime('+30 days'));

    $stmt->bind_param("sssssssssss", 
        $title, $body, $titleEn, $bodyEn, $titleAr, $bodyAr, 
        $route, $additionalData, $targetCriteria, $createdAt, $expiryAt
    );

    if (!$stmt->execute()) {
        throw new Exception('Failed to save notification template: ' . $stmt->error);
    }

    $templateId = $stmt->insert_id;
    error_log("Created notification template with ID: " . $templateId);

    // Log the notification template creation
    log_audit($con, null, 'notification_sent', json_encode([
        'template_id' => $templateId,
        'recipient_count' => count($targetUsers),
        'target_criteria' => $data['filters'] ?? null,
        'timestamp' => $createdAt
    ]));

    // Prepare notification reference data
    $notificationRef = [
        'template_id' => $templateId,
        'status' => 'unread',
        'created_at' => date('Y-m-d H:i:s'),
        'read_at' => null,
        'expires_at' => $expiryAt
    ];

    // Insert or update notifications for each target user
    $successCount = 0;
    foreach ($targetUsers as $user) {
        error_log("Processing notifications for user: " . $user);
        
        // Check if user already has notifications
        $stmt = $con->prepare("SELECT notifications FROM user_notifications WHERE national_id = ?");
        $stmt->bind_param("s", $user);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            error_log("Existing notifications found for user: " . $user);
            // Update existing notifications
            $row = $result->fetch_assoc();
            $existingNotifications = json_decode($row['notifications'], true) ?? [];
            error_log("Current notifications count: " . count($existingNotifications));
            
            array_unshift($existingNotifications, $notificationRef); // Add new notification at the beginning
            error_log("Added new notification. New count: " . count($existingNotifications));
            
            // Keep only the last 50 notifications
            if (count($existingNotifications) > 50) {
                $existingNotifications = array_slice($existingNotifications, 0, 50);
                error_log("Trimmed to 50 notifications");
            }
            
            $stmt = $con->prepare("UPDATE user_notifications SET notifications = ? WHERE national_id = ?");
            $notificationsJson = json_encode($existingNotifications);
            error_log("Updating notifications for user: " . $user);
            error_log("New JSON data: " . $notificationsJson);
            
            $stmt->bind_param("ss", $notificationsJson, $user);
        } else {
            error_log("No existing notifications for user: " . $user);
            // Create new notifications entry
            $stmt = $con->prepare("INSERT INTO user_notifications (national_id, notifications) VALUES (?, ?)");
            $notificationsJson = json_encode([$notificationRef]);
            error_log("Creating new notification entry with JSON: " . $notificationsJson);
            
            $stmt->bind_param("ss", $user, $notificationsJson);
        }
        
        // Execute and check for errors
        if (!$stmt->execute()) {
            error_log("Database error for user " . $user . ": " . $stmt->error);
            continue;
        }
        
        if ($stmt->affected_rows > 0) {
            error_log("Successfully saved notification for user: " . $user);
            $successCount++;
        } else {
            error_log("No rows affected for user: " . $user . ". Error: " . $stmt->error);
        }
    }

    // Double check the results
    error_log("Final success count: " . $successCount);
    error_log("Total target users: " . count($targetUsers));

    // After successful notification sending
    if ($successCount > 0) {
        log_audit($con, null, 'notification_delivered', json_encode([
            'template_id' => $templateId,
            'successful_sends' => $successCount,
            'total_recipients' => count($targetUsers),
            'timestamp' => date('Y-m-d H:i:s')
        ]));
    }

    echo json_encode([
        'status' => 'success',
        'message' => "Successfully sent notifications to $successCount users",
        'total_recipients' => count($targetUsers),
        'successful_sends' => $successCount
    ]);

} catch (Exception $e) {
    error_log("Error in send_notification.php: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$con->close();
?> 