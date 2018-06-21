<?php


header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header("Expires: Sat, 26 Jul 1997 05:00:00 GMT");

?>



<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta http-equiv="cache-control" content="max-age=0" />
<meta http-equiv="cache-control" content="no-cache" />
<meta http-equiv="expires" content="0" />
<meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />
<meta http-equiv="pragma" content="no-cache" />
<title>GOVProxy Project</title>
<script src="js/jquery-3.1.1.js"></script>
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
  <link rel="stylesheet" href="css/normalize.min.css">
  <link rel="stylesheet" href="css/style.css">
  <link rel="stylesheet" href="css/font-awesome-4.7.0/css/font-awesome.min.css">

<style>
#myProgress {
  width: 50%;
  background-color: #ddd;
  border-radius: 2px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.25) inset;

}

#myBar {
  width: 160%;
  height: 30px;
  background-color: #4CAF50;
  text-align: center;
  line-height: 30px;
  color: white;
}

#myProgressRAM {
  width: 120px;
  background-color: #ddd;
  border-radius: 2px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.25) inset;

}

#myBarRAM {
  width: 30%;
  height: 30px;
  background-color: #20b1eb;
  text-align: center;
  line-height: 30px;
  color: white;
}


#myProgressCPU {
  width: 120px;
  background-color: #ddd;
  border-radius: 2px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.25) inset;

}

#myBarCPU {
  width: 30%;
  height: 30px;
  background-color: #e07425;
  text-align: center;
  line-height: 30px;
  color: white;
}




</style>

</head>
<body>


<div class="table-users">
   <div class="header">Load Distribution:</div>

<div id="show"></div>



<script type="text/javascript">
    $(document).ready(function(){
      refreshTable();
    });

    function refreshTable(){
        $('#show').load('data.php', function(){
           setTimeout(refreshTable, 2000);
        });
    }
</script>

