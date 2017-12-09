<?php
// main page
$title = 'Live';
if (file_exists('./includes/config.php')) {
	include('./includes/config.php');
}
else {
	exit("You need to create includes/config.php");
}
global $sJavascript, $sTable;

	$sJavascript .= '<script type="text/javascript">
		function uptime() {
			$(function() {';
$id = 0;
$sTable ='
			<thead>
			<tr>
				<th id="status" style="text-align: center;">Status</th>
				<th id="name">Name</th>
				<th id="host">Host</th>
				<th id="type">Type</th>
				<th id="location">Location</th>
				<th id="uptime">Uptime</th>
				<th id="load">Load</th>
				<th id="ram">RAM</th>
				<th id="hdd">HDD</th>
			</tr>
			</thead>
			<tbody>';
foreach($servers as $result) {
	if(isset($result['break'])) {
		$sTable .= '<tr><td id="null" colspan="9" style="text-align:center;font-size:150%;">' . $result['name'] . '</td></tr>';
	}
	else {
		$sJavascript .= '$.getJSON("pull/index.php?url='.$id.'",function(result){
		$("#online'.$id.'").html(result.online);
		$("#uptime'.$id.'").html(result.uptime);
		$("#load'.$id.'").html(result.load);
		$("#memory'.$id.'").html(result.memory);
		$("#hdd'.$id.'").html(result.hdd);
		});';
		$sTable .= '
			<tr>
				<td id="online'.$id.'">
					<div class="progress">
						<div class="bar bar-danger" style="width: 100%;"><small>Down</small></div>
					</div>
				</td>
				<td><a href="outages.php?name='.$result["name"].'">'.$result["name"].'</a></td>
				<td><a href="outages.php?host='.$result["host"].'">'.$result["host"].'</a></td>
				<td>'.$result["type"].'</td>
				<td>'.$result["location"].'</td>
				<td id="uptime'.$id.'">n/a</td>
				<td id="load'.$id.'">n/a</td>
				<td id="memory'.$id.'">
					<div class="progress progress-striped active">
						<div class="bar bar-danger" style="width: 100%;"><small>n/a</small></div>
					</div>
				</td>
				<td id="hdd'.$id.'">
					<div class="progress progress-striped active">
						<div class="bar bar-danger" style="width: 100%;"><small>n/a</small></div>
					</div>
				</td>
			</tr>
		';
	}
	$id++;
}
$sTable .= '</tbody>';
	$sJavascript .= '});
	}
	uptime();
	setInterval(uptime, '.$refresh.');
	</script>';

include($index);

?>