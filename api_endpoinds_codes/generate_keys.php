<?php
require 'db_connect.php';

function generateApiKey() {
    return bin2hex(random_bytes(16));
}

for ($i = 0; $i < 5; $i++) {
    $api_key = generateApiKey();
    $stmt = $con->prepare("INSERT INTO API_Keys (api_Key) VALUES (?)");
    $stmt->bind_param("s", $api_key);
    $stmt->execute();
}

echo "5 API keys have been generated and added to the database.";
$con->close();
?>
