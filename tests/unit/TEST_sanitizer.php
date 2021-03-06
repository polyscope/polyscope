<?php
/*
	Desc: Test isSane function.
	Author:	Sebastian Schmittner
	Date: 2015.05.02
	Last Author: Sebastian Schmittner
	Last Date: 2015.05.02 18:28:02 (+02:00)
	Version: 0.0.1
*/

require_once 'sanitizer.php';

class sanitizerTest extends PHPUnit_Framework_TestCase
{
	/**
	 *  @dataProvider stringsToTestForSanity
	 */
	public function testIsSane( $stringToTest, $expected ) {
		
		$this->assertEquals($expected, isSane( $stringToTest ) );
	
	}
	
	public function stringsToTestForSanity() {
		
		return array(
			array('test@icr.ac.uk', true),
			array('That is a test string.', true),
			array('1 + 0 - 99', true),
			array('1,99', true),
			array('Test punctuation, Stop.', true),
			array('A_B_C_D_E', true),
			
			array('!', false),
			array('""', false),
			array('  $%&', false),
			array('{}', false),
			array('[]', false),
			array('()', false),
			array('/', false),
			array('#', false),
			array('?', false),
			array('*', false),

			array('This cannot be a sane string! Because the special characters * are screwing the sanity! Right?', false)
		);
	}
}
 
?>

