<?php 
# $Id: search.php,v 1.5 2003/10/03 17:56:36 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<?php
    $origquery = mysql_escape_string($_GET["query"]);
    $query = strtoupper($query);
    $title = "Search for '$origquery'"; 
    if ($origquery == "")
        $title = "Search";
    include "header.inc";

    include "db.inc";
    include "render.inc";
    include "parliaments.inc";
    $db = new DB(); 

    if ($query <> "")
    {
        $found = false;

        # Perform query on MPs
        $score_clause = "
            (upper(concat(first_name, ' ', last_name)) = '$query') * 10 + 
            (upper(constituency) = '$query') * 10 + 
            (soundex(concat(first_name, ' ', last_name)) = soundex('$query')) * 8 + 
            (soundex(constituency) = soundex('$query')) * 8 + 
            (soundex(last_name) = soundex('$query')) * 6 + 
            (upper(constituency) like '%$query%') * 4 + 
            (upper(last_name) like '%$query%') * 4 + 
            (soundex(first_name) = soundex('$query')) * 2 + 
            (upper(first_name) like '%$query%')";

        $db->query("$mps_query_start and ($score_clause > 0) 
                    order by constituency, entered_house desc, last_name, first_name");

        if ($db->rows() > 0)
        {
            $found = true;
            print "<p>Found these MPs matching '$origquery':";
            print "<table class=\"mps\"><tr
                class=\"headings\"><td>Date</td><td>Name</td><td>Constituency</td><td>Party</td><td>Rebellions</td><td>Attendance</td></tr>\n";
            $prettyrow = 0;
            while ($row = $db->fetch_row())
            {
                $prettyrow = pretty_row_start($prettyrow);
                $anchor = "\"mp.php?firstname=" . urlencode($row[0]) .
                    "&lastname=" . urlencode($row[1]) . "&constituency=" .
                    urlencode($row[3]) . "\"";

                if ($row[6] == "") { $row[6] = "n/a"; } else { $row[6] .= "%"; }

                print "<td>" . year_range($row[10], $row[11]) . "</td>";
                print "<td><a href=$anchor>$row[2] $row[0] $row[1]</a></td></td>
                    <td>$row[3]</td>
                    <td>" . pretty_party($row[4], $row[8], $row[9]) . "</td>
                    <td class=\"percent\">$row[6]</td>
                    <td class=\"percent\">$row[7]%</td>";
                print "</tr>\n";
            }
            print "</table>\n";
        } 

        # Perform query on divisions
        $db->query("$divisions_query_start and (upper(division_name) like '%$query%'
        or upper(motion) like '%$query%')
        order by division_date desc, division_number desc"); 

        if ($db->rows() > 0)
        {
            $found = true;
            print "<p>Found these divisions matching '$origquery':";
            print "<table class=\"votes\">\n";
            print "<tr
            class=\"headings\"><td>No.</td><td>Date</td><td>Subject</td><td>Rebellions</td><td>Turnout</td></tr>";
            render_divisions_table($db);
            print "</table>\n";
        }

        if (!$found)
        {
?>
<p>Nothing found matching '<?=$origquery?>'.
<p>Try browsing the list of <a href="mps.php">all MPs</a>
or <a href="divisions.hphp">all divisions</a>.
<?php
        }
    }

?>

<p class="search">Enter your MP, constituency or debate topic:</p>
<form class="search" action="search.php" name=pw>
<input maxLength=256 size=25 name=query value=""> <input type="submit" value="Search" name="button">
</form>
<?php search_example($db) ?>
<p class="search"><span class="ptitle">Search Tip 1:</span> You can <a
href="http://www.locata.co.uk/commons/">find your MP by postcode</a>
on an external site, then enter their name back here.  If you are having
trouble, try using just the first name or just the last name.  If you
don't know exactly how to spell the name, write it as best you
can like it sounds.

<p class="search"><span class="ptitle">Search Tip 2:</span> 
To find divisions you are interested in, enter the
name of a subject, such as "Pensions" or "Hunting".  The Public Whip
will search the titles of the divisions and the text of the motion being
debated.

<?php include "footer.inc" ?>
