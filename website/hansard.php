<?php 
    # $Id: hansard.php,v 1.3 2003/10/13 17:45:59 frabcus Exp $
    # Test page, just for use on local machine.  The pw_debate_content
    # database is too big for us to put on mythic-beasts at the moment.

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.
    
    include "db.inc";
    $db = new DB(); 
    $date = db_scrub($_GET["date"]);

    $title .= "Hansard Content " . html_scrub($date);
    include "header.inc";

    $row = $db->query_one_row("select content, download_date,
        first_page_url from pw_debate_content, pw_hansard_day
        where pw_hansard_day.day_date = pw_debate_content.day_date and
        pw_debate_content.day_date = '$date'"); 

    $content = $row[0];
    $downloaddate = $row[1];
    $url = $row[2];

    print "<p>Content was downloaded from Hansard starting with page:<br>
    <a href=\"$url\">$url</a><br>Date and time of download $downloaddate";
    print "<hr>";
    print $content;
    print "<hr>";

?>

<?php include "footer.inc" ?>


