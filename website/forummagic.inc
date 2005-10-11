<?php

# $Id: forummagic.inc,v 1.2 2005/10/11 23:43:02 frabcus Exp $
# Post things to the forum automatically (like log of changes to policies)

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# forummagic_post DB FORUM_NAME TOPIC_TITLE CONTENT
# Posts a new message to the forum, using the user id of the logged in user.
# Requires the name of PHPBB forum, a topic title for a topic in that forum,
# and the content of the post. If the topic already exists, a new one will be
# made.  It is an error for the forum not to exist.
function forummagic_post($db, $forum_name, $topic_title, $content) {
    // Find forum
    list($forum_id) = $db->query_one_row("select forum_id from phpbb_forums where forum_name = '$forum_name'");
    
    // See if topic exits, if not make it
    list($topic_id) = $db->query_onez_row("select topic_id from phpbb_topics where topic_title = '".mysql_escape_string($topic_title)."' and forum_id = $forum_id");

    // Post our message
    $post_domain = "publicwhip.owl";
    $post_filename = "/forum/posting.php";
    if (!$topic_id) {
        // Make topic
        $post_data = "f=$forum_id&mode=newtopic&notify=on&topictype=0&subject=".urlencode($topic_title).
                     "&message=".urlencode($content)."&post=Submit"; 
        $response = forummagic_do_post($post_domain, $post_filename, $post_data);
        print $response;
    } else {
        $post_data = "t=$topic_id&mode=reply&notify=on&subject=".urlencode($topic_title).
                     "&message=".urlencode($content)."&post=Submit"; 
        $response = forummagic_do_post($post_domain, $post_filename, $post_data);
        print $response;
    }

    // Check all's well
    if (!stristr($response, "Your message has been entered successfully.")) {
        fatal_error("Failed to post change to forum.");
    }
}

// Perform a post request into the forum
function forummagic_do_post($post_domain, $post_filename, $post_data) {
    $timeout = 5; 

    $response = '';
    $fp = @fsockopen($post_domain, 80, $errno, $errstr, $timeout);
    if (!$fp) 
        fatal_error('Failed to open internal HTTP socket for forum post');
    stream_set_timeout($fp, $timeout);
    $sockstart = getmicrotime(); # feof doesn't time out, so we have to measure ourselves also        
    $out = "POST $post_filename HTTP/1.0\r\n";
    $out .= "Host: " . $post_domain . "\r\n";
    $out .= "Content-Type: application/x-www-form-urlencoded\r\n";
    $out .= "User-Agent: forummagic.inc from Public Whip\r\n";
    $out .= "Content-Length: " . strlen($post_data) . "\r\n";
    $out .= "Cookie: " . $_SERVER["HTTP_COOKIE"] . "\r\n";
#    $out .= "Connection: Close\r\n";
    $out .= "\r\n";
    $out .= $post_data;
    fwrite($fp, $out);
    $inbody = false;
    while (!feof($fp) and (getmicrotime() < $sockstart + $timeout)) {
        $line = fgets($fp, 1024);
        if ($line == "\r\n")
            $inbody = true;
        if ($inbody)
            $response .= $line;
    }
    if (getmicrotime() >= $sockstart + $timeout) {
        fatal_error('HTTP timed out while doing internal forum post');
    }
    fclose($fp);

    return $response;
}

?>
