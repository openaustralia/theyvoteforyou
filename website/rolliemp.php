<?php 
    # $Id: rolliemp.php,v 1.1 2004/02/08 04:01:43 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
    include "constituencies.inc";
	include "xquery.inc";
	include "protodecode.inc";
    include "account/user.inc";
    $db = new DB(); 

    $id = db_scrub($_GET["id"]);

	$query = "select name, description, pw_dyn_user.user_id, user_name, real_name, email
        from pw_dyn_rolliemp, pw_dyn_user
        where pw_dyn_rolliemp.user_id = pw_dyn_user.user_id and rollie_Id = '$id'";
    $row = $db->query_one_row($query);
    $name = $row[0];
    $description = $row[1];
    $user_id = $row[2];
    $user_name = $row[3];
    $real_name = $row[4];
    $email = $row[5];

    $title = "Hand Rolled MP - '" . html_scrub($name) . "' - by " . html_scrub($real_name);
    include "header.inc";

    print "<p><b>Description:</b> " . html_scrub($description). "</p>";
    print "<p><b>Created by:</b> " . html_scrub($real_name) . " &lt;" . html_scrub($email) . "&gt;</p>";

    print "<h2><a name=\"divisions\">Divisions Attended</a></h2>
    <p>Divisions in which this virtual MP voted."; 

    print "<table>\n";
    # Table of votes in each division
    $query = "select pw_division.division_id, pw_division.division_number, pw_division.division_date,
        division_name, source_url, vote from pw_division,
        pw_dyn_rollievote where pw_dyn_rollievote.rolliemp_id = '$id' and
        pw_division.division_date = pw_dyn_rollievote.division_date and 
        pw_division.division_number = pw_dyn_rollievote.division_number ";

    $query .= "order by division_date desc, division_number desc";
    $db->query($query);

    print "<tr class=\"headings\">
    <td>No.</td><td>Date</td><td>Subject</td>
    <td>Vote</td>
    <td>Debate</td></tr>";
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$row[1]</td> <td>$row[2]</td> <td><a
            href=\"division.php?date=" . urlencode($row[2]) . "&number="
            . urlencode($row[1]) . "\">$row[3]</a></td>
            <td>$row[5]</td>
            <td><a href=\"$row[4]\">Hansard</a></td>"; 
        print "</tr>\n";
     }
    if ($db->rows() == 0)
    {
        $prettyrow = pretty_row_start($prettyrow, "");
        print "<td colspan=7>this virtual MP has not yet voted in any divisions</td></tr>\n";
    }
    print "</table>\n";
    if ($db->rows() == 0)
    {
        if (user_isloggedin())
        {
            print "To select votes for your virtual MP, <a href=\"search.php\">search</a> or
                    <a href=\"divisions.php\">browse</a> for divisions.  On the page for
                    each division you can choose how your made-up MP would have voted.  Only vote
                    on divisions which your MP cares about.";

        }
    }
?>
	

<?php include "footer.inc" ?>
