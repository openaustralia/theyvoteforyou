<?php

include "constituencies.inc";

function is_postcode($postcode)
{
    return preg_match("/^[A-Z]{1,2}\d[A-Z\d]? ?\d[ABD-HJLNP-UW-Z]{2}$/i", $postcode);
}

function startElement($parser, $name, $attrs) 
{
    global $postcode_tags, $postcode_constituency;
    array_push($postcode_tags, $name);
    if ($postcode_tags[count($postcode_tags) - 1] == "CONSTITUENCY_NAME" && $postcode_tags[count($postcode_tags) - 2] == "FAXYOURMP")
        $postcode_constituency = "";
}
 
function endElement($parser, $name) 
{
    global $postcode_tags;
    array_pop($postcode_tags);
}

function characterData($parser, $content) 
{
    global $postcode_tags, $postcode_constituency;
    if ($postcode_tags[count($postcode_tags) - 1] == "CONSTITUENCY_NAME" && $postcode_tags[count($postcode_tags) - 2] == "FAXYOURMP")
        $postcode_constituency .= $content;
}

function postcode_to_constituency($postcode)
{
    # Try and match with regexp to exclude non postcodes quickly
    if (!is_postcode($postcode))
        return false;

    # Otherwise hit the server (URL is private)
    global $postcode_search_url;
    $filename = $postcode_search_url .  urlencode($postcode);
    $file = file_get_contents($filename);
    $file = str_replace("&", "&amp;", $file);
    $file = str_replace("&amp;amp;", "&amp;", $file);

    global $postcode_tags, $postcode_constituency;
    $postcode_tags = array();
    $postcode_constituency = null;

    $xml_parser = xml_parser_create();
    xml_set_element_handler($xml_parser, "startElement", "endElement");
    xml_set_character_data_handler($xml_parser, "characterData");
     
    if (!xml_parse($xml_parser, $file, true))
    {
        return false;
#        die(sprintf("XML error: %s at line %d",
#            xml_error_string(xml_get_error_code($xml_parser)),
#            xml_get_current_line_number($xml_parser)));
    }
    xml_parser_free($xml_parser);
    $postcode_constituency = str_replace("  ", " ", $postcode_constituency);

    # Convert to canonical name
    global $consmatch, $consnames;
#    print "<pre>$file</pre><br>$postcode_constituency<br>";
    return $consnames[$consmatch[strtolower($postcode_constituency)]];
}

?>
