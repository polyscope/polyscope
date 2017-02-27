<?php
/*
	Desc: Retrieves all functions from a given file
	Author:	Tony Legrone (http://stackoverflow.com/users/2911704/tony-legrone)
			Andrew Moore (http://stackoverflow.com/users/26210/andrew-moore)
	Date: - 
	Last Author: Sebastian Schmittner
	Last Date: 2015.07.12
	Version: 0.0.0
	
	Comment: This is an adapted version, original from http://stackoverflow.com/questions/2197851/function-list-of-php-file
*/

function getFunctionsOfFile($file) {
    $source = file_get_contents($file);
    $tokens = token_get_all($source);

    $functions = array();
    $nextStringIsFunc = false;
    $inClass = false;
    $bracesCount = 0;

    foreach($tokens as $token) {
        switch($token[0]) {
            case T_CLASS:
                $inClass = true;
                break;
            case T_FUNCTION:
                if(!$inClass) $nextStringIsFunc = true;
                break;

            case T_STRING:
                if($nextStringIsFunc) {
                    $nextStringIsFunc = false;
                    $functions[] = $token[1];
                }
                break;

            // Anonymous functions
            case '(':
            case ';':
                $nextStringIsFunc = false;
                break;

            // Exclude Classes
            case '{':
                if($inClass) $bracesCount++;
                break;

            case '}':
                if($inClass) {
                    $bracesCount--;
                    if($bracesCount === 0) $inClass = false;
                }
                break;
        }
    }

    return $functions;
}

?>
