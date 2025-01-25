<?php

$SETTINGS["hostname"] = 'localhost';
$SETTINGS["mysql_user"] = 'icredept_tariq';
$SETTINGS["mysql_pass"] = 'tariq';
$SETTINGS["mysql_database"] = 'icredept_nayifat_app';

$conn = new mysqli($SETTINGS["hostname"], $SETTINGS["mysql_user"], $SETTINGS["mysql_pass"], $SETTINGS["mysql_database"]);

date_default_timezone_set('Asia/Riyadh');

 
 
?>