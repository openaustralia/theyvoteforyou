<?php

$xmldatapath = "/home/francis/pwdata/pwscrapedxml/";

function sgrep_query($xmlfolder, $query)
{
	global $xmldatapath;
	$path = $xmldatapath . $xmlfolder;
	$command = "sgrep -x $path/ixsgrep -g xml";

	$sgrepout = array();
	exec("$command '$query' 2>&1", $sgrepout);

	$result = join("\n", $sgrepout);
	$result = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n" . "<publicwhip>\n" . $result . "</publicwhip>\n";

#	print "<pre>$result</pre>";

	return $result;
}

function print_transform($xsltfile, $xmlfile)
{
    $xsltproc = xslt_create();
    xslt_set_encoding($xsltproc, 'ISO-8859-1');
	$html = xslt_process($xsltproc, 'arg:/_xml', $xsltfile, NULL, array('/_xml' => $xmlfile));
    if (empty($html)) { die('XSLT processing error: '. xslt_error($xsltproc)); }
    xslt_free($xsltproc);
    print $html;
}

?>
