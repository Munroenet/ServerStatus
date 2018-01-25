<?php 
$title = 'Outages';
$name = htmlspecialchars($_GET['name']);
$host = htmlspecialchars($_GET['host']);
header( "refresh:600;url=./outages.php" );
if(file_exists('./includes/config.php')) {
	include('./includes/config.php');
}
else {
	exit("You need to create includes/config.php");
}	
if(file_exists("./cache/outages.db")){
	$outages = json_decode(file_get_contents("./cache/outages.db"), true);
}
else{
	$outages = array();
	$outages[] = array('down' => 0, 'upagain' => 1, 'name' => 'Server Name', 'host' => 'Server Host', 'type' => 'Server Type', 'uptime' => '1 Day');
}
$sTable ='
			<thead>
			<tr>
				<th id="status"></th>
				<th id="name">Name</th>
				<th id="host">Host</th>
				<th id="type">Type</th>
				<th id="location">Down</th>
				<th id="uptime">Up</th>
				<th id="load">Total</th>
			</tr>
			</thead>
			<tbody>';
			
if ($name == null && $host == null) {
	foreach($outages as $outage) {
		$sTable .='<tr><td></td><td><a href="outages.php?name=' . urlencode($outage['name']) . '">'. $outage['name'] . '</a></td><td><a href="outages.php?host=' . urlencode($outage['host']) . '">'. $outage['host'] . '</a></td><td>' . $outage['type'] . '</td><td>' . date("H:i | d M Y", $outage['down']) . '</td><td>' . date("H:i | d M Y", $outage['upagain']) . '</td><td>' . number_format((($outage['upagain'] - $outage['down']) / 60), 0, '.', '') . ' Min</td></tr>';
	}
}
elseif($name != null && $host == null) {
	foreach($outages as $outage) {
		if ($name == $outage['name']) {
			$sTable .='<tr><td></td><td><a href="outages.php?name=' . urlencode($outage['name']) . '">'. $outage['name'] . '</a></td><td><a href="outages.php?host=' . urlencode($outage['name']) . '">'. $outage['host'] . '</a></td><td>' . $outage['type'] . '</td><td>' . date("H:i | d M Y", $outage['down']) . '</td><td>' . date("H:i | d M Y", $outage['upagain']) . '</td><td>' . number_format((($outage['upagain'] - $outage['down']) / 60), 0, '.', '') . ' Min</td></tr>';
		}
	}
}
elseif($name == null && $host != null) {
	foreach($outages as $outage) {
		if ($host == $outage['host']) {
			$sTable .='<tr><td></td><td><a href="outages.php?name=' . urlencode($outage['name']) . '">'. $outage['name'] . '</a></td><td><a href="outages.php?host=' . urlencode($outage['name']) . '">'. $outage['host'] . '</a></td><td>' . $outage['type'] . '</td><td>' . date("H:i | d M Y", $outage['down']) . '</td><td>' . date("H:i | d M Y", $outage['upagain']) . '</td><td>' . number_format((($outage['upagain'] - $outage['down']) / 60), 0, '.', '') . ' Min</td></tr>';
		}
	}
}
elseif($name != null && $host != null) {
	foreach($outages as $outage) {
		if ($host == $outage['host'] && $host == $outage['host']) {
			$sTable .='<tr><td></td><td><a href="outages.php?name=' . urlencode($outage['name']) . '">'. $outage['name'] . '</a></td><td><a href="outages.php?host=' . urlencode($outage['name']) . '">'. $outage['host'] . '</a></td><td>' . $outage['type'] . '</td><td>' . date("H:i | d M Y", $outage['down']) . '</td><td>' . date("H:i | d M Y", $outage['upagain']) . '</td><td>' . number_format((($outage['upagain'] - $outage['down']) / 60), 0, '.', '') . ' Min</td></tr>';
		}
	}
}

$sJavascript = '';
$sTable .= '</tbody>';
include($index);




?>
