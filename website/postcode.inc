<?php

include "/home/francis/.pwdb.inc";
include "constituencies.inc";

function is_postcode($postcode)
{
    return preg_match("/^[A-Z]{1,2}\d[A-Z\d]? ?\d[ABD-HJLNP-UW-Z]{2}$/i", $postcode);
}

function startElement($parser, $name, $attrs) 
{
    global $tags, $constituency;
    array_push($tags, $name);
    if ($tags[count($tags) - 1] == "NAME" && $tags[count($tags) - 2] == "CONSTITUENCY")
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
    if ($tags[count($tags) - 1] == "NAME" && $tags[count($tags) - 2] == "CONSTITUENCY")
        $constituency .= $content;
}

function postcode_to_constituency($postcode)
{
    # Try and match with regexp to exclude non postcodes quickly
    if (!is_postcode($postcode))
        return undef;

    # Otherwise hit the server (URL is private)
    global $postcode_search_url;
    $filename = $postcode_search_url .  urlencode($postcode) . "&customer=news_constituency";
    $file = file_get_contents($filename);

    global $tags, $constituency;
    $tags = array();
    $constituency = undef;

    $xml_parser = xml_parser_create();
    xml_set_element_handler($xml_parser, "startElement", "endElement");
    xml_set_character_data_handler($xml_parser, "characterData");
     
    if (!xml_parse($xml_parser, $file, true))
    {
        die(sprintf("XML error: %s at line %d",
            xml_error_string(xml_get_error_code($xml_parser)),
            xml_get_current_line_number($xml_parser)));
    }
    xml_parser_free($xml_parser);
    $constituency = str_replace("  ", " ", $constituency);

    # Convert to canonical name
    global $consmatch;
#    print "<pre>$file</pre><br>$constituency<br>";
    return $consmatch[$constituency];
}

?>
