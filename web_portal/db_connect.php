<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$SETTINGS["hostname"] = 'localhost';
$SETTINGS["mysql_user"] = 'icredept_tariq';
$SETTINGS["mysql_pass"] = 'tariq';
$SETTINGS["mysql_database"] = 'icredept_nayifat_app';

$conn = new mysqli($SETTINGS["hostname"], $SETTINGS["mysql_user"], $SETTINGS["mysql_pass"], $SETTINGS["mysql_database"]);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Set charset to handle Arabic text properly
if (!$conn->set_charset("utf8mb4")) {
    die("Error loading character set utf8mb4: " . $conn->error);
}

date_default_timezone_set('Asia/Riyadh');
?>