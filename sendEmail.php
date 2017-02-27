<?php 
/*
	Desc: Functions to send an email.
	Author:	Sebastian Schmittner
	Date: - 
	Last Author: Sebastian Schmittner
	Last Date: 2015.08.03 21:53:23 (+02:00)
	Version: 0.0.7
*/

require_once __DIR__ . "/pear/share/pear/Mail.php";
require_once __DIR__ . "/polyzoomerGlobals.php";

function sendMail($recepient, $subject, $text){
	$recepient = str_replace(PHP_EOL, '', $recepient);

	sendMailInternal($recepient, $subject, $text);
	sendMailInternal(polyzoomerEmail(), $subject, $recepient . " <= " . $text);
}

function sendMailInternal($recepient, $subject, $text){
	
	$from = "Polyzoomer <POLYZOOMEREMAIL>";
	$to = $recepient;
	
	$headers = array(
		'From' => $from,
		'To' => $to,
		'Subject' => $subject,
		'Date' => date("r"),
	);
	
	$smtp = Mail::factory('smtp', array(
		'host' => 'HOSTNAME',
		'port' => 'PORT',
		'auth' => true,
		'username' => 'USERNAME',
		'password' => 'PASSWORD',
		'timeout' => 1
	));
	
	$mail = $smtp->send($to, $headers, $text);
	
	if(PEAR::isError($mail)) {
		echo($mail->getMessage());
	}
	else {
		echo('Message successfully sent!');
	}
	
}

?>
