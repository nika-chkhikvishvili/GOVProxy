<!DOCTYPE html>
<html>
<head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Add Organiaztion</title>
        <link rel="stylesheet" href="https://necolas.github.io/normalize.css/7.0.0/normalize.css">
        <link href='https://fonts.googleapis.com/css?family=Nunito:400,300' rel='stylesheet' type='text/css'>
        <link rel="stylesheet" href="style/org-add.css">
    </head>

<body>
<?php

header('Content-Type: text/html; charset=utf-8');
include 'db.php';

?>
<div data-role="content">
 <form id="form" data-ajax="false">
     <div data-role="fieldcontain">

                <label for="org_name">Organiazation</label>
                <input name="org_name" id="org_name" type="text">
                <br/>
                <label for="gateway">Network:</label>
                <input name="gateway" id="gateway" type="text" required pattern="((^|\.)((25[0-5])|(2[0-4]\d)|(1\d\d)|([1-9]?\d))){4}$">
                /
                <input style="width:2%;" name="gateway" id="gateway" type="text" required pattern="[0-9]{1,3}">
                 <br />
                   <label for="vlan">vlan:</label>
                <input name="vlan" id="vlan" type="text" required pattern="[0-9]{1,4}">
                 <br />
                <label for="gateway">Gateway</label>
                <input name="gateway" id="gateway" type="text" required pattern="((^|\.)((25[0-5])|(2[0-4]\d)|(1\d\d)|([1-9]?\d))){4}$">                                      <br/>

                <label for="nat_range">NAT Range:</label>
                <input name="nat_range_start" id="nat_range_start" type="text" required pattern="((^|\.)((25[0-5])|(2[0-4]\d)|(1\d\d)|([1-9]?\d))){4}$">
                -
                <input style="width:2%;" name="nat_range_end" id="nat_range_end" type="text" required pattern="[0-9]{1,3}">




     </div>
     <div style="text-align:center;">                   
                <input type="submit" value="Enter" />
     </div> 
 </form>
</div>
