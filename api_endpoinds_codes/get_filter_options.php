<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header('Content-Type: application/json');

require 'db_connect.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
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

    $filterOptions = [];

    // Get columns from Customers table
    $result = $con->query("SHOW COLUMNS FROM Customers");
    $filterOptions['Customers'] = [];
    while ($row = $result->fetch_assoc()) {
        $filterOptions['Customers'][] = [
            'column' => $row['Field'],
            'type' => $row['Type'],
            'operators' => getOperatorsForType($row['Type'])
        ];
    }

    // Get columns from loan_application_detail table
    $result = $con->query("SHOW COLUMNS FROM loan_application_detail");
    $filterOptions['loan_application_detail'] = [];
    while ($row = $result->fetch_assoc()) {
        $filterOptions['loan_application_detail'][] = [
            'column' => $row['Field'],
            'type' => $row['Type'],
            'operators' => getOperatorsForType($row['Type'])
        ];
    }

    // Get columns from card_application_detail table
    $result = $con->query("SHOW COLUMNS FROM card_application_detail");
    $filterOptions['card_application_detail'] = [];
    while ($row = $result->fetch_assoc()) {
        $filterOptions['card_application_detail'][] = [
            'column' => $row['Field'],
            'type' => $row['Type'],
            'operators' => getOperatorsForType($row['Type'])
        ];
    }

    // Get distinct values for enum and status fields
    foreach ($filterOptions as $table => &$columns) {
        foreach ($columns as &$column) {
            if (strpos($column['type'], 'enum') === 0 || $column['column'] === 'status') {
                $query = "SELECT DISTINCT {$column['column']} FROM {$table} WHERE {$column['column']} IS NOT NULL";
                $result = $con->query($query);
                $values = [];
                while ($row = $result->fetch_assoc()) {
                    $values[] = $row[$column['column']];
                }
                $column['possible_values'] = $values;
            }
        }
    }

    echo json_encode([
        'status' => 'success',
        'filter_options' => $filterOptions
    ]);

} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$con->close();

function getOperatorsForType($type) {
    // Basic operators for all types
    $operators = ['=', '!='];
    
    // Add numeric operators for int, decimal, float types
    if (strpos($type, 'int') === 0 || 
        strpos($type, 'decimal') === 0 || 
        strpos($type, 'float') === 0 || 
        strpos($type, 'double') === 0) {
        $operators = array_merge($operators, ['>', '<', '>=', '<=', 'BETWEEN']);
    }
    
    // Add LIKE operator for string types
    if (strpos($type, 'varchar') === 0 || 
        strpos($type, 'text') === 0 || 
        strpos($type, 'char') === 0) {
        $operators[] = 'LIKE';
    }
    
    // Add IN operator for all types except text/blob
    if (strpos($type, 'text') !== 0 && 
        strpos($type, 'blob') !== 0 && 
        strpos($type, 'longtext') !== 0) {
        $operators[] = 'IN';
    }
    
    return $operators;
}
?> 