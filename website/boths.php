<?php 
    # $Id: boths.php,v 1.1 2003/09/25 20:29:17 uid37249 Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    $title = "Voted both aye and noe"; 
    include "header.inc";
    include "db.inc";
    include "render.inc";
    $db = new DB(); 

    $sort = mysql_escape_string($_GET["sort"]);
    if ($sort == "")
    {
        $sort = "division";
    }
    if ($sort == "division")
    {
        $order = "division_date desc, division_number desc, last_name, first_name, constituency";
    }
    elseif ($sort == "name")
    {
        $order = "last_name, first_name, constituency, division_date desc, division_number desc";
    }

    $db->query("select first_name, last_name, constituency, party, 
        entered_house, left_house, 
        division_number, division_date, division_name from pw_mp,
        pw_division, pw_vote where pw_mp.mp_id = pw_vote.mp_id and
        pw_division.division_id = pw_vote.division_id and vote =
        'both' order by $order");
    $count = $db->rows();

?>
<p>Amazingly, on <? print $count; ?> occasions in this parliament,
an MP has voted twice in the same division.  It's a little known fact that this is perfectly
allowable, provided one vote is aye and the other is noe.  For details see under the
heading "abstention" in the <a href="http://www.parliament.uk/documents/upload/p09.pdf">division factsheet</a> from the House of Commons Information Office.  

<p>An MP may have done this to cancel the effect of a mistaken vote in
the wrong lobby.   However, it would seem reasonable to me to encourage the
practice as a signal of active abstention from the vote.  You
can see in the table below that there is slight evidence of such
a meaning, since when one MP double votes a few others often also
do so.  Unless they just followed each other blindly into the 
wrong lobby...

<p>This table lists all instances of double voting.  You can select the column
headings to sort it by MP name or by division.

<?php
    $url = "boths.php?";
    print "<table class=\"mix\"><tr class=\"headings\">\n";
    print "<tr class=\"headings\"><td>No.</td>";
    head_cell($url, $sort, "Division", "division", "Sort by division date");
    print "<td>Subject</td>";
    head_cell($url, $sort, "MP", "name", "Sort by surname");
    print "<td>Constituency</td><td>Party</td>";
    print "</tr>";

    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$row[6]</td><td><a href=\"division.php?date=" . urlencode($row[7]) .
        "&number=" . urlencode($row[6]) . "\">$row[7]</a></td> 
               <td>$row[8]</td>";
        print "<td><a href=\"mp.php?firstname=" . urlencode($row[0]) .
            "&lastname=" . urlencode($row[1]) . "&constituency=" .
            urlencode($row[2]) . "\">
            $row[0] $row[1]</a></td> <td>$row[2]</td>
            <td>" . pretty_party($row[3], $row[4], $row[5]) . "</td>";
        print "</tr>\n";
    }

    print "</table>\n";

?>

<?php include "footer.inc" ?>
