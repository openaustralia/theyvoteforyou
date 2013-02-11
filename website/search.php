<?php require_once "common.inc";
# $Id: search.php,v 1.48 2009/05/27 06:09:02 marklon Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $prettyquery = html_scrub(trim($_GET["query"]));
    $query = strtolower(trim($_GET["query"]));
    if ($prettyquery == "word/postcode") {
        $prettyquery = "";
        $query = "";
    }
    $title = 'Search for '.preg_replace('/[^A-Za-z0-9 \.\,]/','',$prettyquery);
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

    $postcode = is_postcode($query);
    $header = false;

    if ($postcode)
    {
        $escaped_postcode = htmlentities(strtoupper($query));
        $postcode_matches = postcode_to_constituencies($db,$query);
        if( (!$postcode_matches) or $postcode_matches['ERROR'] ) {
            $title = "Postcode Error";
            pw_header();
            print "<p>There was an error trying to look up the postcode";
            if ($postcode_matches)
                print ": ".htmlentities($postcode_matches['ERROR'])."</p>";
            pw_footer();
            exit;
        }
        $number_of_matches = count($postcode_matches);
        if ($number_of_matches == 1) {
            # If there's only one match for a postcode, that means
            # there's just a Westminster constituency, so redirect
            # straight to that page:
            header("Location: mp.php?constituency=".urlencode($postcode_matches["WMC"])."&house=commons");
            exit;
        } else {
            # There must be more than one match.  Produce a table with links
            # to all possible representatives:
            $title = "Representatives for postcode $escaped_postcode";
            pw_header();
            print "<table class=\"mps\">\n";
            $key_to_house = array( "WMC" => "commons",
                                   "SPC" => "scotland",
                                   "SPE" => "scotland" );
            $pretty_house = array( "commons" => "Commons",
                                   "scotland" => "Scotland");
            $odd = FALSE;
            # Make sure that the results are listed in the order "WMC", "SPC", "SPE":
            foreach( array("WMC", "SPC", "SPE") as $k ) {
                $constituency = $postcode_matches[$k];
                if (!$constituency)
                    continue;
                $house = $key_to_house[$k];
                if (!$house) {
                    print "<p>Error: An unknown key ".htmlentities($k)." was found.</p>";
                    pw_footer();
                    exit;
                }
                $scrubbed_constituency = db_scrub($constituency);
                # FIXME: should probably do this with mp_table instead:
                $rows=$pwpdo->fetch_all_rows('SELECT * FROM pw_mp WHERE
                            house = ? AND
                            constituency = ? AND
                            CURDATE() >= entered_house and CURDATE() <= left_house
                            ORDER BY house, last_name',array($house,$scrubbed_constituency));
                foreach ($rows as $row) {
                    $mp_url = "mp.php?".link_to_mp($row);
                    $constituency_url = "mp.php?mpc=".urlencode(str_replace(" ", "_", $row['constituency']))."&"."house=".urlencode($row['house']);
                    print "<tr class=\"".($odd?'odd':'even')."\">\n";
                    # Print out house, full name, constituency
                    print '<td class="'.$row['house'].'">';
                    print $pretty_house[$row['house']];
                    print '</td>'."\n";
                    print '<td><a href="'.$mp_url.'">'.$row['first_name'].' '.$row['last_name'].'</a></td>'."\n";
                    print "<td>".html_scrub($row['party'])."</td>";
                    print '<td><a href="'.$constituency_url.'">'.$constituency.'</a></td>'."\n";
                    print "</tr>\n";
                    $odd = ! $odd;
                }
            }
            print "</table>";
            pw_footer();
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
            print "<p>Found these MPs and Lords whose names sound like '$prettyquery':";
            print "<table class=\"mps\">\n";
            $mptabattr = array("listtype" 	=> "search",
                               "search" => $query,
                               "showwhich" 	=> "all",
                               "sortby"		=> "score",
                               "house"      => "both", 
                               "headings"	=> "yes");
            mp_table($mptabattr);
            # TODO: set $found correctly
            $found = true;
            print "</table>\n";
        }

        # Nothing?
        if (!$found)
        {
?>
<p>Nothing found matching <?php if ($postcode) print "postcode "; ?> '<?php echo $prettyquery; ?>'.
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
<input maxLength=256 size=25 name="query" id="query" value=""> <input type="submit" value="Search" name="button">
</form>

<p class="search"><i>Example: "OX1 3DR", "<?php echo $random_mp?>"<?php echo $random_constituency?> or "<?php echo $random_topic?>"</i>

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

