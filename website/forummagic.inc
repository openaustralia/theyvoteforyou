<?php

# $Id: forummagic.inc,v 1.4 2005/10/12 22:48:44 theyworkforyou Exp $
# Post things to the forum automatically (like log of changes to policies)

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# forummagic_post DB FORUM_NAME TOPIC_MATCH TOPIC_TITLE CONTENT
# Posts a new message to the forum, using the user id of the logged in user.
# Requires the name of PHPBB forum, a topic title for a topic in that forum,
# and the content of the post. If the topic already exists, a new one will be
# made.  It is an error for the forum not to exist. TOPIC_MATCH is the first
# part of the topic name to use for searching, posting uses TOPIC_TITLE.
function forummagic_post($db, $forum_name, $topic_match, $topic_title, $content) {
    global $domain_name;
    list($forum_id, $topic_id) = forummagic_findtopic($db, $forum_name, $topic_match);
    forummagic_make_sure_phpbb_account($db);

    // Post our message
    $post_filename = "/forum/posting.php";
    if (!$topic_id) {
        // Make topic
        $post_data = "f=$forum_id&mode=newtopic&notify=on&topictype=0&subject=".urlencode($topic_title).
                     "&message=".urlencode($content)."&post=Submit"; 
        list($response, $head) = forummagic_do_post($domain_name, $post_filename, $post_data);
    } else {
        $post_data = "t=$topic_id&mode=reply&notify=on&subject=".urlencode($topic_title).
                     "&message=".urlencode($content)."&post=Submit"; 
        list($response, $head) = forummagic_do_post($domain_name, $post_filename, $post_data);
    }

    // Check all's well
    if (!stristr($response, "Your message has been entered successfully.")) {
        fatal_error("Failed to post change to forum.");
    }
}

# forummagic_getlink DB FORUM_NAME TOPIC_MATCH
# Returns URL of topic.
function forummagic_getlink($db, $forum_name, $topic_match) {
    list($forum_id, $topic_id) = forummagic_findtopic($db, $forum_name, $topic_match);
    if (!$topic_id)
        return null;
    return "/forum/viewtopic.php?t=$topic_id";
}

function forummagic_findtopic($db, $forum_name, $topic_match) {
    // Find forum and topic
    list($forum_id) = $db->query_one_row("select forum_id from phpbb_forums where forum_name = '$forum_name'");
    list($topic_id) = $db->query_onez_row("select topic_id from phpbb_topics where topic_title like '".mysql_escape_string($topic_match)."%' and forum_id = $forum_id order by topic_id desc limit 1");
    return array($forum_id, $topic_id);
}

// Makes sure the phpbb user account has been made
function forummagic_make_sure_phpbb_account($db){
    global $domain_name;
    if (!user_isloggedin())  
        fatal_error("forummagic_make_sure_phpbb_account: Must be logged in");

    // Make sure PHPBB user account has been made
    $user_name = user_getname();
    list($got_users) = $db->query_one_row("select count(*) from phpbb_users where username = '$user_name'");
    if ($got_users != 0 && $got_users != 1)
        fatal_error("forummagic_make_sure_phpbb_account: Unexpected strange value for got_users");
    if (!$got_users) {
        # Provoke creation of PHPBB account (not sure why have to do this twice - to do
        # with redirects and phpbb and our hacks to its user accounts)
        list ($response, $head) = forummagic_do_post($domain_name, "/forum/", "");
        list ($response, $head) = forummagic_do_post($domain_name, "/forum/", "");
        list($got_users) = $db->query_one_row("select count(*) from phpbb_users where username = '$user_name'");
        if ($got_users != 0 && $got_users != 1)
            fatal_error("forummagic_make_sure_phpbb_account: Unexpected strange value for got_users");
        if ($got_users == 0) 
            fatal_error("forummagic_make_sure_phpbb_account: Failed to generated phpbb account '$user_name'");
    }
}

// Perform a post request into the forum
// Returns array(body, headers)
function forummagic_do_post($post_domain, $post_filename, $post_data) {
    $timeout = 5; 

    $head = '';
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
        else 
            $head .= $line;
    }
    if (getmicrotime() >= $sockstart + $timeout) {
        fatal_error('HTTP timed out while doing internal forum post');
    }
    fclose($fp);

    return array($response, $head);
}

?>
