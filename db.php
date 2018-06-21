<?php


$servername = "localhost";
$username = "user";
$password = "pass";
$dbname = "govproxy";


// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
mysqli_set_charset($conn,"utf8");
// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} 

?>
