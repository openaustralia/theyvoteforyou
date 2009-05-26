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

# This function returns a map of constituency type to
# name of constituency.  For example, a Cambridge postcode
# might return:
#   array( "WMC" => "South Cambridgeshire" )
# ... whereas a postcode in Edinburgh might return:
#   array( "WMC" => "Edinburgh East",
#          "SPC" => "Edinburgh Central",
#          "SPE" => "Lothians" )
# If there's any error, then we return something like:
#   array( "ERROR" => "That isn't a postcode" )
function postcode_to_constituencies($db, $postcode) {
	$postcode = trim($postcode);
    if (!is_postcode($postcode))
        return array('ERROR' => "The postcode was malformed.");
    $useful_keys = array("WMC" => TRUE,
                         "SPC" => TRUE,
                         "SPE" => TRUE);

    $response = get_text_from_http( POSTCODE_SEARCH_REPRESENTATIVES_DOMAIN,
                                    POSTCODE_SEARCH_REPRESENTATIVES_PORT,
                                    POSTCODE_SEARCH_REPRESENTATIVES_PATH."?pc=".urlencode($postcode) );

    # Parsing this XML response with regular expressions is pretty
    # horrible - I'm not sure why it's done like this below, but I'll
    # assume there's a good reason for it...

    if (!$response)
        return array('ERROR' => "There was an error looking up that postcode.");
    # Now check whether the response was an error:
    preg_match("/error>([^<]*)/ims", $response, $result);
    if( $result ) {
        $error_text = $result[1];
        return array ("ERROR" => "The postcode server returned an error.");
    }
    # Otherwise it was probably a real response:
    $re = "/name type=\"([^\"]*)\">([^<]*)/ims";
    $n = preg_match_all( $re, $response, $results, PREG_SET_ORDER );
    if (!$n) {
        return array ("ERROR" => "There were no matches for the postcode.");
    }
    $final_result = array();
    foreach ($results as $match) {
        $key = $match[1];
        $value = $match[2];
        if ($useful_keys[$key]) {
           $house = 'commons';
           if ($key == "SPE" or $key == "SPC") {
               $house = 'scotland';
           }
           $constituency = normalise_constituency_name($db, strtolower($value), $house);
           if (!$constituency)
               $constituency = "[Unknown $house constituency: '$value']";
           $final_result[$key] = $constituency;
        }
    }
    if (!$final_result)
        return array ("ERROR" => "There was an unexpected response when looking up the postcode.");
    return $final_result;
}

function get_text_from_http( $domain, $port, $path ) {
	$file = ""; // just to be safe. Dunno, if this is really needed
    $timeout = 5;
    $fp = @fsockopen($domain, $port, $errno, $errstr, $timeout);
    if ($fp) {
        stream_set_timeout($fp, $timeout);
        $sockstart = getmicrotime(); # feof doesn't time out, so we have to measure ourselves also
        $out = "GET $path HTTP/1.0\r\n";
        $out .= "Host: " . $domain. "\r\n";
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
    return $file;
}

function postcode_to_constituency($db, $postcode, $pc_parl = "2005") {
    $postcode = trim($postcode);

    global $last_postcode;
    global $last_postcode_value;

    if ($last_postcode == $postcode) {
        #debug ("TIME", "Postcode $postcode looked up last time, is $last_postcode_value .");
        return $last_postcode_value;
    }

    $start = getmicrotime();
    $ret = postcode_to_constituency_internal($db, $postcode, $pc_parl);
    $duration = getmicrotime() - $start;
    
    #debug ("TIME", "Postcode $postcode lookup took $duration seconds, returned $ret.");
    $last_postcode = $postcode;
    $last_postcode_value = $ret;
    return $ret;
}

function postcode_to_constituency_internal($db, $postcode, $pc_parl)
{
    if (!POSTCODE_SEARCH_DOMAIN) {
        return "Liverpool Riverside";
    }

    $postcode = trim($postcode);
    
    # Try and match with regexp to exclude non postcodes quickly
    if (!is_postcode($postcode))
        return '';

    # Otherwise hit the server (URL is private)
    # We use fsockopen rather than just fopen or file_get_contents so we can do timeouts
    if ($pc_parl == "2005" || !$pc_parl) {
        $filename = POSTCODE_SEARCH_PATH .  urlencode($postcode);
        $domain = POSTCODE_SEARCH_DOMAIN;
    } elseif ($pc_parl == "2001") {
        $filename = POSTCODE_SEARCH_PATH_2001_PARLIAMENT .  urlencode($postcode);
        $domain = POSTCODE_SEARCH_DOMAIN_2001_PARLIAMENT;
    } elseif ($pc_parl) {
        trigger_error("Unknown postcode parliament $pc_parl", E_USER_ERROR);
    } else {
        trigger_error("Internal postcode_to_constituency_internal error", E_USER_ERROR);
    }
    $file = get_text_from_http( $domain, POSTCODE_SEARCH_PORT, $filename );
    if (!$file)
        return '';

	// Back to the original code.
    $file = str_replace("&", "&amp;", $file);
    $file = str_replace("&amp;amp;", "&amp;", $file);

    global $tags, $constituency;
    $tags = array();
    $constituency = null;

    # we now don't decode using xml parser (which was stupid).  Although php regexp support isn't that great to use.
    if (false)
    {
        $xml_parser = xml_parser_create();
        xml_set_element_handler($xml_parser, "startElement", "endElement");
        xml_set_character_data_handler($xml_parser, "characterData");
         
        if (!xml_parse($xml_parser, $file, true))
        {
            trigger_error("Postcode database is not working. Invalid XML.", E_USER_WARNING);
            return '';
    #        trigger_error(sprintf("XML error: %s at line %d",
    #            xml_error_string(xml_get_error_code($xml_parser)),
    #            xml_get_current_line_number($xml_parser)), E_USER_ERROR);
        }
        xml_parser_free($xml_parser);
    }
    else
    {
        $res = array();
        preg_match("/name\>([^<]*)/i", $file, $res);
    #    print "iii" . preg_match("/name\>([^<]*)/i", $file, $res);
    #    preg_match("/ell/", "Hello World!", $res);
    #    print_r($res);
        if (!$res)
        {
            trigger_error("Postcode not recognized."); 
            return '';
        }
        $constituency = $res[1]; 
    #print_r($res); 
    #print "<h1>$file</h1>";
    }
    $constituency = str_replace("  ", " ", $constituency);

    # Convert to canonical name
#    print "<pre>$file</pre><br>$constituency<br>";
#    print $consnames[$consmatch[strtolower($constituency)]];
    $normalised = normalise_constituency_name($db, strtolower($constituency), 'commons', $pc_parl);
    if ($normalised)
        return $normalised;
    else
        return '';
}

?>
