<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Organizations</title>
</head>
<body>
<?php

  header('Content-Type: text/html; charset=utf-8');
include 'db.php';

$sql = "SELECT id, org_name, org_status FROM org";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo "<table><tr><th>#</th><th>Organization</th><th>State</th></tr>";
    // output data of each row
    while($row = $result->fetch_assoc()) {
       if ( $row["org_status"] == 1 ) {
          $org_status="Active";
       }else{
      $org_status="Inactive";
}
        echo "<tr><td>" . $row["id"]. "</td><td>" . $row["org_name"]. " " . $org_status. "</td></tr>";
    }
    echo "</table>";
} else {
    echo "0 results";
}

$conn->close();
?> 

</body>
</html>
