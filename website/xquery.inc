<?php

function ApplyXSLT($xmldata, $xsltfile)
{
    $xsltproc = xslt_create();

	# XSLT defaults to making UTF-8, unless you set otherwise
	xslt_set_encoding($xsltproc, 'ISO-8859-1');
	
	$html = xslt_process($xsltproc, 'arg:/_xml', 'xslt/' . $xsltfile, NULL, 
		array('/_xml' => $xmldata));
    if (empty($html)) { die('XSLT processing error: '. xslt_error($xsltproc)); }
    xslt_free($xsltproc);
	$html = str_replace('<?xml version="1.0" encoding="ISO-8859-1"?>', '', $html);
    return $html;
}

?>
