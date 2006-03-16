<?php require_once "common.inc";
# $Id: search.php,v 1.45 2006/03/16 01:24:50 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $prettyquery = html_scrub(trim($_GET["query"]));
    $query = strtolower(db_scrub(trim($_GET["query"])));
    if ($prettyquery == "word/postcode") {
        $prettyquery = "";
        $query = "";
    }
    $title = "Search for '$prettyquery'"; 
    if ($prettyquery == "") {
        $onload = "givefocus('query')";
        $title = "Search";
    }
    require_once "parliaments.inc";
    require_once "constituencies.inc";
    require_once "links.inc";
    require_once "postcode.inc";
    require_once "wiki.inc";
    require_once "tablemake.inc";
    require_once "tablepeop.inc";

    $db = new DB(); 

    $postcode = is_postcode($query);
    $header = false;

    if ($postcode)
    {
        $score_clause = "(1=0)";
        $pccons = postcode_to_constituency($db, $query);
        if (isset($pccons))
        {
            # Overwrite over matches if we have postcode
            $score_clause = "(constituency = '" . db_scrub($pccons) . "')";
            header("Location: mp.php?constituency=" . urlencode($pccons));
            exit;
        }
    }


    if ($query <> "")
    {
        $found = false;

        if (!$postcode)
        {
            $header = true;
            pw_header();

            # Perform query on divisions
            # TODO: only show this if something was found
            print "<p>Found these " /*. $db->rows()*/ . " divisions matching '$prettyquery':";
            print "<table class=\"votes\">\n";
            $divtabattr = array(
                    "showwhich"		=> 'search',
                    "search"        => $query,
                    "headings"		=> 'columns',
                    "sortby"		=> 'date',
                    "display_house" => 'both');
            division_table($db, $divtabattr);
            # TODO: set $found correctly
            $found = true;
            print "</table>\n";

            # Perform query on MPs
            # TODO: only show this if something was found
            print "<p>Found these MPs and Lords whose names sound like ";
            print "<table class=\"mps\">\n";
            $mptabattr = array("listtype" 	=> "search",
                               "search" => $query,
                               "showwhich" 	=> "all",
                               "sortby"		=> "score",
                               "house"      => "both", 
                               "headings"	=> "yes");
            mp_table($db, $mptabattr);
            # TODO: set $found correctly
            $found = true;
            print "</table>\n";
        }

        # Nothing?
        if (!$found)
        {
?>
<p>Nothing found matching <? if ($postcode) print "postcode "; ?> '<?=$prettyquery?>'.
<?
        }

?>
<p>Also try browsing the list of <a href="mps.php">all MPs</a>,
<a href="mps.php?house=lords">all Lords</a>
or <a href="divisions.php">all divisions</a>.
<?php

    }
    else
    {
        pw_header();
    }

    $random_mp = searchtip_random_mp($db);
    $random_constituency = searchtip_random_constituency($db);
    $random_topic = searchtip_random_topic($db);
?>

<p class="search">Enter your postcode, MP name, constituency or debate topic:</p>
<form class="search" action="search.php" name=pw>
<input maxLength=256 size=25 name=query id=query value=""> <input type="submit" value="Search" name="button">
</form>

<p class="search"><i>Example: "OX1 3DR", "<?=$random_mp?>"<?=$random_constituency?> or "<?=$random_topic?>"</i>

<p class="search"><span class="ptitle">MPs:</span> You can enter a postcode
to get a list of all MPs for that constituency, or else enter their name or
part of their name.  If you don't know exactly how to spell the name,
write it as best you can like it sounds.

<p class="search"><span class="ptitle">Divisions:</span> 
To find divisions you are interested in, enter the
name of a subject, such as "Pensions" or "Hunting".  The Public Whip
will search the titles of the divisions and the text of the motion being
debated.  If you enter multiple words, it will only find entries where they 
appear next to each other as you enter them.  You can enter part of a word.

<?php pw_footer() ?>

