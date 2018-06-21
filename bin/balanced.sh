#!/bin/sh


# global stuff
IFS=$'\n'
source /etc/govproxy/govproxy.conf

echo start_while
while true;
 do
  sleep 3
echo inside_while


total_usr_tmp=$(mktemp)


lb_vip=$(mysql -u $db_user  $db_name --raw -N -s -e "select DISTINCT lb_vip from lb_conf where lb_status=\"enabled\";")
real_servers=$(mysql -u $db_user  $db_name --raw -N -s -e "SELECT node_ip FROM nodes WHERE status=\"active\";")
org_count=$(mysql -u $db_user  $db_name --raw -N -s -e "SELECT COUNT(id) from org where org_status=\"active\";")


ctotal_connections=""
for vip in $lb_vip; 
 do
  echo "VIP: $vip"
  for conn in $(ssh $vip /bin/total_connections );
     do ctotal_connections=$((ctotal_connections+ $conn))
  done
done
echo  "ctotal_connections: $ctotal_connections"


total_users=""
for server in $real_servers; 
  do
     echo "server: $server" 
     total_users_raw=$(ssh $server netstat -tn | grep 3128 | awk '{print $5}' | cut -d: -f1 | sort -u)
     echo "$total_users_raw" >>$total_usr_tmp
     total_users=$((total_users+ $(echo "$total_users_raw" |wc -l)))
     echo "Total User on ${server}: $total_users"

done
tmp_file=$(mktemp)

echo "total_users: $total_users"
echo "total_usr_tmp: $total_usr_tmp"



echo "real_servers: $real_servers"
echo "tmp_file: $tmp_file"
echo "total_users: $total_users"
echo "smart_users: $smart_users"
echo "smart_users_percentage: $smart_users_percentage"
echo "other_users: $other_users"
echo "other_users_percentage: $other_users_percentage"
echo "total_connections: $ctotal_connections"


function get_free_ram() {
ssh $1 free-ram
}

function get_cpu_load() {
ssh $1 cpu-load
}



function get_distrubution_per_node() {
percentage=$(calc -p "round($1*100/$ctotal_connections)")
echo "${percentage}%"
}


node_connections=""
node_total_connections=""
function get_conn_by_srv() {
for vip in $lb_vip;
 do
 node_connections=$(ssh $vip ipvsadm -Ln  | grep Route  | grep $1 | awk '{print $5}')
 node_total_connections=$((node_total_connections + $node_connections))
done


if [[ "$2" == "1" ]] && [ $node_total_connections -gt 1000 ]; then
    node_total_connections_formatted=$(calc -p "round($node_total_connections/1000)")
 echo ${node_total_connections_formatted}K
   else
 echo $node_total_connections
fi

}


function check_srv_state(){
curl -s --connect-timeout 1 $1:3128 >/dev/null
result=$?
if test "$result" = "0"; then

   echo "<img src=\"images/green.png\" title=\"server is healthy\" />"
else
   echo "<img src=\"images/red.png\" title=\"server is down\" />"
fi
} 



echo "
<?php


header(\"Cache-Control: no-store, no-cache, must-revalidate, max-age=0\");
header(\"Cache-Control: post-check=0, pre-check=0\", false);
header(\"Pragma: no-cache\");
header(\"Expires: Sat, 26 Jul 1997 05:00:00 GMT\");
?>

">$tmp_file

echo "generating pie chart"
gen_org_chart=$(sh $BIN_PATH/compare-belongs.sh $total_users $total_usr_tmp )
echo "

<table cellspacing=\"0\" style=\"padding:0;\">
<tr>
<td>
<i class=\"fa fa-building-o fa-3x\" aria-hidden=\"true\" style=\"vertical-align: inherit; margin-left: 50%;\"></i>
<strong  style=\"padding-left: 2%;\">ორგანიზაციების რაოდენობა:</strong>
</td>
<td width=\"25%\">
<h1>$org_count</h1>
</td>
</tr>
<td>
<i class=\"fa fa-user fa-3x\" aria-hidden=\"true\" style=\"vertical-align: inherit; margin-left: 50%;\"></i>
<strong  style=\"padding-left: 2%;\">მომხმარებლების რაოდენობა:</strong>
</td>
<td width=\"25%\">
<h1>$total_users</h1>
</td>
</tr>
<td>
<i class=\"fa fa-arrow-up fa-2x\" aria-hidden=\"true\" style=\"vertical-align: inherit; margin-left: 41%;\">
</i>
<i class=\"fa fa-arrow-up fa-2x\" aria-hidden=\"true\" style=\"vertical-align: inherit;\">
</i>
<strong  style=\"padding-left: 2%;\">მთლიანი კავშირების რაოდენობა:</strong>
</td>
<td width=\"25%\" ><h1>$ctotal_connections</h1>
</td>
</table>

  <div id=\"piechart\" style=\"width: 1200px; height: 600px;\"></div>
     <script type=\"text/javascript\">
      google.charts.load('current', {'packages':['corechart']});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable([
          ['Task', 'Hours per Day'],
          $gen_org_chart
        ]);
        var options = {
          title: 'მოხმარება ორგანიზაციის მიხედვით.'
        };
        var chart = new google.visualization.PieChart(document.getElementById('piechart'));
        chart.draw(data, options);
      }
    </script>
">>$tmp_file
echo "end of pie chart"

echo "
<table cellspacing="0">
<tr>
<th>სერვერი:</th>
<th>სტატუსი:</th>
<th>კავშირები:</th>
<th>კავშირების გადანაწილება:</th>
<th>RAM:</th>
<th>CPU დატვირთვა:</th>
<tr>
<div id=\"show\"></div>
</tr>
">>$tmp_file

echo "generating HTML table"
for server in $real_servers;
 do
echo "
<tr>
<td><strong>$server</strong></td>
<td>$(check_srv_state $server)</td>
<td><strong>$( get_conn_by_srv $server 1 )</strong></td>
<td><div id=\"myProgress\"><div id=\"myBar\" style=\"width:$(get_distrubution_per_node $(get_conn_by_srv $server))\" >$(get_distrubution_per_node $(get_conn_by_srv $server))</div></div></td>
<td><div id=\"myProgressRAM\"><div id=\"myBarRAM\" style=\"width:$(get_free_ram $server)\" >$(get_free_ram $server)</div></div></td>
<td><div id=\"myProgressCPU\"><div id=\"myBarCPU\" style=\"width:$(get_cpu_load $server)\" >$(get_cpu_load $server)</div></div></td>
</tr>
"
done>>$tmp_file
cat $tmp_file > /var/www/html/data.php

echo "removing data"
rm -rf $tmp_file
rm -rf $total_usr_tmp
done

