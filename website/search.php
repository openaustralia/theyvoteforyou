<?php $title = "Search"; include "header.inc" 
# $Id: search.php,v 1.3 2003/10/02 09:42:03 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<?php
    include "db.inc";
    include "render.inc";
    include "parliaments.inc";
    $db = new DB(); 
    $origquery = mysql_escape_string($_GET["query"]);
    $query = strtoupper($query);

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

    $row = $db->query_one_row("select first_name, last_name from pw_mp
        order by rand() desc limit 1");
    $random_mp = $row[0] . " " . $row[1];

    $row = $db->query_one_row("select constituency from pw_mp
        order by rand() desc limit 1");
    $random_constituency = random_big_word($row[0]);
    if ($random_constituency == "")
        $random_constituency = "Liverpool";

    $row = $db->query_one_row("select division_name from pw_division
        order by rand() desc limit 1");
    $random_topic = random_big_word($row[0]);
    if ($random_topic == "")
        $random_topic = "Trade";
?>

<p class="search">Enter your MP, constituency or debate topic:</p>
<form class="search" action="search.php" name=pw>
<input maxLength=256 size=25 name=query value=""> <input type="submit" value="Search" name="button">
</form>
<p class="search"><i>Example: "<?=$random_mp?>", "<?=$random_constituency?>" or "<?=$random_topic?>"</i>

<?php include "footer.inc" ?>
