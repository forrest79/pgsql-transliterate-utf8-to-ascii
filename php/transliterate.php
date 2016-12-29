<?php

$unidecodeDir = __DIR__ . DIRECTORY_SEPARATOR . 'Unidecode';
$unidecodePHPDir = __DIR__ . DIRECTORY_SEPARATOR . 'UnidecodePHP';
$outputDir = __DIR__ . DIRECTORY_SEPARATOR . 'output';

if (!file_exists($unidecodeDir)) {
	echo 'Text::Unidecode files are expecting in ' . $unidecodeDir . 'directory...';
	exit(1);
}

if (!file_exists($unidecodePHPDir)) {
	mkdir($unidecodePHPDir, 0777, TRUE);
}

if (!file_exists($outputDir)) {
	mkdir($outputDir, 0777, TRUE);
}

$transliterate = [];

foreach (glob($unidecodeDir . DIRECTORY_SEPARATOR . '*.pm') as $filename) {
	$phpFilename = $unidecodePHPDir . DIRECTORY_SEPARATOR . basename($filename) . '.php';

	if (!file_exists($phpFilename)) {
		$data = file_get_contents($filename);

		$data = preg_replace_callback('/qq\{(.*)\},/U', function($matches) {
			$item = $matches[1];
			switch ($item) {
				case '\@' :
				case '\{' :
				case '\}' :
					$item = ltrim($item, '\\');
					break;
			}
			return '"' . ((strpos($item, '"') === FALSE) ? $item : addslashes($item)) . '",';
		}, $data);
		$data = preg_replace_callback('/q\{(.*)\},/U', function($matches) {
			$item = $matches[1];
			return "'" . ((strpos($item, "'") === FALSE) ? $item : addslashes($item)) . "',";
		}, $data);
		$data = str_replace('Text::Unidecode::make_placeholder_map()', '[]', $data);
		$data = substr(trim(str_replace('$Text::Unidecode::Char', '$transliterate', $data)), 0, -2);

		file_put_contents($phpFilename, "<?php\n" . $data);
	}

	require($phpFilename);
}

foreach ($transliterate as $x => $items) {
	foreach ($items as $y => $item) {
		$utf8Char = ($x * 256) + $y;

		// keep first 127 characters as is, ignore last 2 characters
		if (($utf8Char < 127) || ($utf8Char >= 65534)) {
			continue;
		}

		// create UTF-8 char by int value
		$text = mb_convert_encoding('&#' . intval($utf8Char) . ';', 'UTF-8', 'HTML-ENTITIES');

		// (instead of [?] we want '') || (we don't want to tolerate Win-1252 input, see x00.pm)
		if (($item == '[?]') || (($utf8Char >= 127) && ($utf8Char <= 159))) {
			$item = '';
		}

		file_put_contents($outputDir . DIRECTORY_SEPARATOR . 'transliterate.log', '(' . $utf8Char . ') ' . $text . ' -> ' . $item . "\n", FILE_APPEND);

		$exists[$text] = $utf8Char;
		
		$pgesc = function($text) {
			$text = str_replace('\'', '\'\'', $text);
			$text = str_replace('\\', '\\\\', $text);
			return $text;
		};
		file_put_contents($outputDir . DIRECTORY_SEPARATOR . 'transliterate.sql', 'INSERT INTO system.transliterate_to_ascii_rules(original, transliterate) VALUES(\'' . $pgesc($text) . '\', \'' . $pgesc($item) . '\');' . "\n", FILE_APPEND);
	}
}
