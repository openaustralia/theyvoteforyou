<?php

# $Id: forummagic.inc,v 1.1 2005/10/11 14:57:54 frabcus Exp $
# Post things to the forum automatically (like log of changes to policies)

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

function post_to_forum($db, $forum_name, $topic_title) {
    // Find forum
    list($forum_id) = $db->query_one_row("select forum_id from phpbb_forums where forum_name = '$forum_name'");
    
    // See if topic exits, if not make it
    list($topic_id) = $db->query_onez_row("select topic_id from phpbb_topics where topic_title = '$topic_title' and forum_id = $forum_id");
    if (!$topic) {
        fatal_error("TODO");
    }

    // Make post
    print "<p>found $topic_id";
    
}

?>
