<?php include "cache-begin.inc"; ?>
<?php 
    # $Id: boths.php,v 1.6 2003/10/27 09:36:41 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    $title = "Voted both aye and no"; 
    include "header.inc";
    include "db.inc";
    include "render.inc";
    include "parliaments.inc";
    $db = new DB(); 

    $sort = db_scrub($_GET["sort"]);
    if ($sort == "")
    {
        $sort = "date";
    }
    if ($sort == "date")
    {
        $order = "order by division_date desc, division_number desc, last_name, first_name, constituency";
    }
    elseif ($sort == "lastname")
    {
        $order = "order by last_name, first_name, constituency, division_date desc, division_number desc";
    }

    $db->query("select first_name, last_name, constituency, party, 
        entered_house, left_house, 
        division_number, division_date, division_name from pw_mp,
        pw_division, pw_vote where pw_mp.mp_id = pw_vote.mp_id and
        pw_division.division_id = pw_vote.division_id and vote =
        'both' $order");
    $count = $db->rows();

?>
<p>Amazingly, on <? print $count; ?> occasions in these parliaments,
an MP has voted twice in the same division.  It's a little known fact that this is perfectly
allowable, provided one vote is aye and the other is no.  For details see under the
heading "abstention" in the <a href="http://www.parliament.uk/documents/upload/p09.pdf">division factsheet</a> from the House of Commons Information Office.  

<p>An MP may have done this to cancel the effect of a mistaken vote in
the wrong lobby.   However, it would seem reasonable to encourage the
practice as a signal of active abstention from the vote.  You can see in
the table below one clear case of this happening, where many Conservative
members abstain on a fishing issue.

<p>This table lists all instances of double voting.  You can select the column
headings to sort it by MP name or by division date.

<?php
    $url = "boths.php?";

    $prettyrow = 0;
    $lastparl = "";
    while ($row = $db->fetch_row())
    {
        $thisparl = date_to_parliament($row[7]);
        if ($lastparl == "" or ($thisparl != $lastparl and $sort == "date"))
        {
            if ($lastparl != "")
                print "</table>\n";
            if ($sort == "date")
                print "<h2>" . parliament_name($thisparl) . " Parliament</h2>\n";

            print "<table class=\"mix\"><tr class=\"headings\">\n";
            print "<tr class=\"headings\"><td>No.</td>";
            head_cell($url, $sort, "Date", "date", "Sort by division date");
            print "<td>Division</td>";
            head_cell($url, $sort, "MP", "lastname", "Sort by surname");
            print "<td>Constituency</td><td>Party</td>";
            print "</tr>";
        }
        $lastparl = $thisparl;

        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$row[6]</td><td>$row[7]</td><td><a href=\"division.php?date=" . urlencode($row[7]) .
        "&number=" . urlencode($row[6]) . "\">$row[8]</a></td>";
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
<?php include "cache-end.inc"; ?>
