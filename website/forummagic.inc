<?php

# $Id: forummagic.inc,v 1.20 2009/11/30 19:26:30 publicwhip Exp $
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
	return;
    $topic_title = forummagic_sanitise_topic($topic_title);
    
    global $domain_name;
    list($forum_id, $topic_id) = forummagic_findtopic($db, $forum_name, $topic_match, $topic_title);

    $done = false;
    $c = 0;
    $cookie_jar = cookie_splitter($_SERVER['HTTP_COOKIE']);
    $all_full_responses = "";
    while (!$done) {
        // 3 times lucky :)
        // (actually, it takes that long for cookies/sessions to be made for
        // PHPBB login to be made from PublicWhip login for new users -- maybe
        // not now cookie stuff done right, dunno)
        $c++;
        if ($c > 3 ) {
            $mail_error = "";
            $mail_error .= "--- Begin dump of forummagic_post error ---\n";
            $mail_error .= "logged in as: " . user_getname() . "\n";
            $mail_error .= "forum_name: $forum_name\n";
            $mail_error .= "topic_match: $topic_match\n";
            $mail_error .= "topic_title: $topic_title\n";
            $mail_error .= "content: $content\n";
            $mail_error .= "user agent: " . $_SERVER['HTTP_USER_AGENT'] . "\n";
            $mail_error .= "ip address: " . $_SERVER['REMOTE_ADDR'] . "\n";
            $mail_error .= $all_full_responses;
            $mail_error .= "--- End dump of forummagic_post error ---";
            // Mail the diagnostics to us -- FAI 2006-10-21
            mail("team@publicwhip.org.uk", "Forum magic post failure diagnostics", $mail_error);
            print "<pre>" . $mail_error . "</pre>";
            trigger_error("Failed to post change to forum after several goes, mailed error to team@publicwhip.org.uk", E_USER_ERROR);
        }

        // Post our message
        $post_filename = "/forum/posting.php";

        $sid = $cookie_jar['phpbb2mysql_sid'];
        if (!$topic_id) {
            // Make topic
            $post_data = "f=$forum_id&mode=newtopic&notify=on&topictype=0&subject=".urlencode($topic_title).
                         "&message=".urlencode($content)."&post=Submit&sid=".urlencode($sid); 
        } else {
            $post_data = "t=$topic_id&mode=reply&notify=on&subject=".urlencode($topic_title).
                         "&message=".urlencode($content)."&post=Submit&sid=".urlencode($sid); 
        }
        $all_full_responses .= "\n\n=============================\ndomain_name:" . $domain_name . "\npost_filename:" . $post_filename . "\npost_data:" . $post_data . "\nmain cookies:" . $_SERVER["HTTP_COOKIE"];
        $all_full_responses .= "\nOur cookie jar:\n" . print_r($cookie_jar, true);
        list($response, $head) = forummagic_do_post($domain_name, $post_filename, $post_data, $cookie_jar);
        $all_full_responses .= "\n----------------------------\n" . $head . $response;

        // Find cookies, and send them in next time
        $matches = array();
        preg_match_all("/^Set-Cookie: ([^;]*);/m", $head, $matches);
        foreach ($matches[1] as $match) {
            $cookie_jar = array_merge($cookie_jar, cookie_splitter($match));
        }

        // See if it all worked
        if (stristr($response, "Your message has been entered successfully.")) {
            $done = true;
        }
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

// Internal function to find forum and topic id
function forummagic_findtopic($db, $forum_name, $topic_match, $topic_set = null) {
    // Find forum and topic
    list($forum_id) = $db->query_one_row("select forum_id from phpbb_forums where forum_name = '$forum_name'");
    list($topic_id, $current_title) = $db->query_onez_row("select topic_id, topic_title from phpbb_topics where topic_title like '".mysql_real_escape_string($topic_match)."%' and forum_id = $forum_id order by topic_id desc limit 1");
    if ($topic_id && $topic_set && ($topic_set != $current_title)) {
        $db->query("update phpbb_topics set topic_title = '" . mysql_real_escape_string($topic_set). "'".
            " where topic_id = " . $topic_id);
    }
    return array($forum_id, $topic_id);
}

// Internal function, splits a cookie into an array
function cookie_splitter($cookie_string) {
    $jar = array();
    $parts = preg_split("/;/", $cookie_string, -1, PREG_SPLIT_NO_EMPTY);
    foreach ($parts as $part) {
        $part = trim($part);
        list($key, $value) = preg_split("/=/", $part, -1, PREG_SPLIT_NO_EMPTY);
        $jar[$key] = $value;
    }
    return $jar;
}

// Internal function, perform a post request into the forum
// Returns array(body, headers)
function forummagic_do_post($post_domain, $post_filename, $post_data, $cookie_jar) {
    $timeout = 15; 

    $head = '';
    $response = '';
    $fp = @fsockopen($post_domain, 80, $errno, $errstr, $timeout);
    if (!$fp) 
        trigger_error('Failed to open internal HTTP socket for forum post', E_USER_ERROR);
    stream_set_timeout($fp, $timeout);
    $sockstart = getmicrotime(); # feof doesn't time out, so we have to measure ourselves also        
    $out = "POST $post_filename HTTP/1.0\r\n";
    $out .= "Host: " . $post_domain . "\r\n";
    $out .= "Content-Type: application/x-www-form-urlencoded\r\n";
    $out .= "User-Agent: forummagic.inc from Public Whip\r\n";
    $out .= "Content-Length: " . strlen($post_data) . "\r\n";
    $cookie_string = "";
    foreach ($cookie_jar as $key => $value) {
        $cookie_string .= "$key=$value; ";
    }
    $out .= "Cookie: $cookie_string\r\n";
    $out .= "\r\n";
    $out .= $post_data;
    #print "<b>forummagic_do_post sending</b><pre>$out</pre>";
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
        trigger_error('HTTP timed out while doing internal forum post', E_USER_ERROR);
    }
    fclose($fp);

    #print "<b>forummagic_do_post got</b><pre>$head</pre>";
    return array($response, $head);
}

# Remove HTML bits, for forum
function forummagic_sanitise_topic($topic) {
    $topic = str_replace("&#8212;", "-", $topic);
    return $topic;
}

?>
