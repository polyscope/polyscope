<?php
/*
	Desc: Creates a code dependency graph of the provided path
	Author:	Sebastian Schmittner
	Date: 2015.07.13
	Last Author: Sebastian Schmittner
	Last Date: 2015.07.13
	Version: 0.0.0
*/

$root = '/home/polyzoomer/Dropbox/Polyzoomer_Sebastian/yuanlab.org/ServerFrontEnd/';

require_once $root . 'tools.php';

function createCodeDependencyGraph( $path ) {

	$root = '/home/polyzoomer/Dropbox/Polyzoomer_Sebastian/yuanlab.org/ServerFrontEnd/';
	
	$allFiles = getAllFiles( $root );
	$phpFiles = getAllPhpFiles($allFiles);

	$phpFunctionsPerFile = gatherFunctionDefinitionsPerFile( $phpFiles );
	$phpIncludesPerFile = gatherIncludeDefinitionsPerFile( $phpFiles );
	
	print_r($phpIncludesPerFile);
}

function gatherIncludeDefinitionsPerFile( $phpFiles ) {
	return gatherItemDefintionsPerFile( $phpFiles, 'getDefinedIncludesInFile' );
}

function gatherFunctionDefinitionsPerFile( $phpFiles ) {
	return gatherItemDefintionsPerFile( $phpFiles, 'get_defined_functions_in_file' );
}

function gatherItemDefintionsPerFile( $files, $gathererFunction ) {
	$itemsPerFile = array();
	
	foreach( $files as $file ) {
		$items = $gathererFunction( $file );

		$itemsPerFile[$file] = $items;
	}
	
	return $itemsPerFile;
}

function getAllFiles( $path ) {
	return dirToArray( $path, DTA_ALL, DTA_MERGE );
}

function getAllPhpFiles( $files ) {
	return getAllItemsContaining( $files, '.php' );
}

function getAllItemsContaining( $items, $substring ) {
	return array_filter( $items, function($v) {
		return strpos( $v, '.php' ) !== false;
	} );
}

function contains( $item, $substring ) {
	return strpos($item, $substring) !== false;
}

function createIncludeDependencyGraph( $phpFiles ) {
}

function getDefinedIncludesInFile( $file ) {
    $source = file_get_contents($file);
    $tokens = token_get_all($source);

    $includes = array();
    $nextStringIsInc = false;
    $inClass = false;
    $bracesCount = 0;

    foreach($tokens as $token) {
        switch($token[0]) {
            case T_CLASS:
                $inClass = true;
                break;
            case T_INCLUDE:
			case T_INCLUDE_ONCE:
			case T_REQUIRE:
			case T_REQUIRE_ONCE:
                if(!$inClass) $nextStringIsInc = true;
                break;

            case T_CONSTANT_ENCAPSED_STRING:
                if($nextStringIsInc) {
                    $nextStringIsInc = false;
                    $includes[] = $token[1];
                }
                break;

            // Anonymous includes
            case '(':
            case ';':
                $nextStringIsInc = false;
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

    return $includes;
}

function get_defined_functions_in_file($file) {
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
