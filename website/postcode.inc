<?php

/////////////////////////////////////////////////////////////////////////////
// This is now a copy from the theyworkforyou.com code, these functions
// are in utility.php there, so we add them at the start.

function validate_postcode ($postcode) {
    // See http://www.govtalk.gov.uk/gdsc/html/noframes/PostCode-2-1-Release.htm
    $postcode = trim($postcode);

    $in  = 'ABDEFGHJLNPQRSTUWXYZ';
    $fst = 'ABCDEFGHIJKLMNOPRSTUWYZ';
    $sec = 'ABCDEFGHJKLMNOPQRSTUVWXY';
    $thd = 'ABCDEFGHJKSTUW';
    $fth = 'ABEHMNPRVWXY';
    $num = '0123456789';
    $nom = '0123456789';
    $gap = '\s\.';

    if (    preg_match("/^[$fst][$num][$gap]*[$nom][$in][$in]$/i", $postcode) ||
            preg_match("/^[$fst][$num][$num][$gap]*[$nom][$in][$in]$/i", $postcode) ||
            preg_match("/^[$fst][$sec][$num][$gap]*[$nom][$in][$in]$/i", $postcode) ||
            preg_match("/^[$fst][$sec][$num][$num][$gap]*[$nom][$in][$in]$/i", $postcode) ||
            preg_match("/^[$fst][$num][$thd][$gap]*[$nom][$in][$in]$/i", $postcode) ||
            preg_match("/^[$fst][$sec][$num][$fth][$gap]*[$nom][$in][$in]$/i", $postcode)
        ) {
        return true;
    } else {
        return false;
    }
}

//////////////////////////////////////////////////////////////////////////////

// Whether the form of the postcode is one or not
function is_postcode($postcode)
{
	$postcode = trim($postcode);
    //return preg_match("/^[A-Z]{1,2}\d[A-Z\d]? ?\d[ABD-HJLNP-UW-Z]{2}$/i", $postcode);
	return validate_postcode($postcode);	// in utility.php
}

function startElement($parser, $name, $attrs) 
{
    global $tags, $constituency;
    array_push($tags, $name);
    if ($tags[count($tags) - 1] == "CONSTITUENCY_NAME" && $tags[count($tags) - 2] == "FAXYOURMP")
        $constituency = "";
}
 
function endElement($parser, $name) 
{
    global $tags;
    array_pop($tags);
}

function characterData($parser, $content) 
{
    global $tags, $constituency;
    if ($tags[count($tags) - 1] == "CONSTITUENCY_NAME" && $tags[count($tags) - 2] == "FAXYOURMP")
        $constituency .= $content;
}

function postcode_to_constituency($postcode) {
    $postcode = trim($postcode);

    global $last_postcode;
    global $last_postcode_value;

    if ($last_postcode == $postcode) {
        #debug ("TIME", "Postcode $postcode looked up last time, is $last_postcode_value .");
        return $last_postcode_value;
    }

    $start = getmicrotime();
    $ret = postcode_to_constituency_internal($postcode);
    $duration = getmicrotime() - $start;
    
    #debug ("TIME", "Postcode $postcode lookup took $duration seconds, returned $ret.");
    $last_postcode = $postcode;
    $last_postcode_value = $ret;
    return $ret;
}

function postcode_to_constituency_internal($postcode)
{
    $postcode = trim($postcode);

    # Try and match with regexp to exclude non postcodes quickly
    if (!is_postcode($postcode))
        return '';

    # Otherwise hit the server (URL is private)
    # We use fsockopen rather than just fopen or file_get_contents so we can do timeouts
    $filename = POSTCODE_SEARCH_PATH .  urlencode($postcode);
	$file = ""; // just to be safe. Dunno, if this is really needed
    $timeout = 5;
    $fp = @fsockopen(POSTCODE_SEARCH_DOMAIN, POSTCODE_SEARCH_PORT, $errno, $errstr, $timeout);
    if ($fp) {
        stream_set_timeout($fp, $timeout);
        $sockstart = getmicrotime(); # feof doesn't time out, so we have to measure ourselves also
        $out = "GET $filename HTTP/1.0\r\n";
        $out .= "Host: " . POSTCODE_SEARCH_DOMAIN. "\r\n";
        $out .= "Connection: Close\r\n\r\n";

        fwrite($fp, $out);
        $inbody = false;
        while (!feof($fp) and (getmicrotime() < $sockstart + $timeout)) {
            $line = fgets($fp, 1024);
            if ($line == "\r\n")
                $inbody = true;
            if ($inbody)
                $file .= $line;
        }
        if (getmicrotime() >= $sockstart + $timeout) {
            trigger_error("Postcode database is not working.  Connection timed out.", E_USER_WARNING);
            return '';
        }
        fclose($fp);
	} else {
        trigger_error("Postcode database is not working.  $errstr.", E_USER_WARNING);
        return '';
    }
	
	// Back to the original code.
    $file = str_replace("&", "&amp;", $file);
    $file = str_replace("&amp;amp;", "&amp;", $file);

    global $tags, $constituency;
    $tags = array();
    $constituency = null;

    $xml_parser = xml_parser_create();
    xml_set_element_handler($xml_parser, "startElement", "endElement");
    xml_set_character_data_handler($xml_parser, "characterData");
     
    if (!xml_parse($xml_parser, $file, true))
    {
        trigger_error("Postcode database is not working. Invalid XML.", E_USER_WARNING);
        return '';
#        die(sprintf("XML error: %s at line %d",
#            xml_error_string(xml_get_error_code($xml_parser)),
#            xml_get_current_line_number($xml_parser)));
    }
    xml_parser_free($xml_parser);
    $constituency = str_replace("  ", " ", $constituency);

    # Convert to canonical name
    global $consmatch, $consnames;
#    print "<pre>$file</pre><br>$constituency<br>";
#    print $consnames[$consmatch[strtolower($constituency)]];
    if (array_key_exists(strtolower($constituency), $consmatch))
        return $consnames[$consmatch[strtolower($constituency)]];
    else
        return '';
}

?>
