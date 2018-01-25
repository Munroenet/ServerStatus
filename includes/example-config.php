<?php

$servers = array();
// Example array below!
//$servers[] = array('url' => '', 'name' => '', 'location' => '', 'host' => '', 'type' => '');
//============================================================================================
// The order you put your arrays in will be how they show up on the server!
$servers[] = array(
	'break' => 1,
	'name' => ' Test Servers '
);

$servers[] = array(
	'url' => 'https://uptime.munroenet.com/uptime.php', 
	'name' => 'Example Host', 
	'location' => 'Dallas Texas', 
	'host' => 'Example Host', 
	'type' => 'Test File',
	'maxload' => 2.0
);






//============================================================================================
// Chose A template.
// Options ( dark | default | default2016 )
$template = "./templates/default/"; 
 
// Tells the web client how often to recheck in ms.
$refresh = 10005; 

 // This is how long before the cache expires in seconds.
$cache = 10;

// This defines how many seconds before we define a server down.
$failafter = 70;  



// If you query uptime.php than use free, if you query uptime_used than use used.
$rtype = 'free'; 


// Anything other then 1 will make it not send emails to you!
$mailme = 0; 


// Email Options via phpmail.
// where should we send down and up alerts?
$emailto = '@gmail.com'; 
// where will we send the emails from?
$emailfrom = 'serverstatus@'; 

//============================================================================================
// Settings below this shouldn't be changed!

$index = $template . "index.php";

// Turns off the stripe animation to improve performance.
$no_stripe = 1; 

?>