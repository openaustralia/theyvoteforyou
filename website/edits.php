<?php require_once "common.inc";

    # $id: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    require_once "wiki.inc";
    require_once "pretty.inc";
    require_once "DifferenceEngine.inc";
    $db = new DB(); 

    $type = db_scrub($_GET["type"]);
    if (!$type)
        $type = "motion";
    if ($type) {
        if ($type == 'motion') {
            if ($_GET["date"]) 
                $params = array(db_scrub($_GET["date"]), db_scrub($_GET["number"]), db_scrub($_GET["house"]));
            else
                $params = null;
        } else {
            trigger_error("Unknown wiki type " . htmlspecialchars($type), E_USER_ERROR);
        }
    }

    if ($params) {
        $db->query("select * from pw_division where division_date = '$params[0]' 
            and division_number = '$params[1]' and house = '$params[2]'");
        $division_details = $db->fetch_row_assoc();
        $prettydate = date("j M Y", strtotime($params[0]));
        $title = "Division Description Changes - " . $division_details['division_name'] . " - $prettydate - Division No. $params[1]";
    } else {
        $title = "All Division Description Edits";
    }

    pw_header();
    
    if ($params)  {
        print "<p>All changes made to the description and title of this division.";
        $edit_link = "account/wiki.php?type=motion&date=".$params[0].
            "&number=".$params[1]."&house=".$params[2].
            "&rr=".urlencode($_SERVER["REQUEST_URI"]);
        $division_link = "division.php?date=".$params[0].
            "&number=".$params[1]."&house=".$params[2];
        print "<p><a href=\"$division_link\">View division</a> | <a href=\"$edit_link\">Edit description</a>";
    }
    else
        print "<p>Recent changes made to description and title of any division.";

    print "<table class=\"edits\">\n";
    print "<tr class=\"headings\">
        <td>Change</td>
        <td>Division Description Changes</td>
        </tr>";

    // Find initial values
    $query = "select division_date, division_number, house, 
                     motion, division_name from pw_division ";
    if ($params)
        $query .= "where " . get_wiki_where_fragment($type, $params);
    $db->query($query);
    $previous = array();
    while ($row = $db->fetch_row_assoc()) {
        $previous[$row['division_date']."-".$row['division_number']."-".$row['house']] = 
            add_motion_missing_wrappers($row['motion'], $row['division_name']);
    }

    // And loop through later ones
    $query = "select " . get_wiki_table($type) . ".*, user_name, pw_dyn_user.user_id as user_id, edit_date 
             from " . get_wiki_table($type) . ", pw_dyn_user
             where " . get_wiki_table($type) . ".user_id = pw_dyn_user.user_id ";
    if ($params)
        $query .= " and " . get_wiki_where_fragment($type, $params);
    $query .= "order by edit_date";
    $db->query($query);
    $rows = array();
    while ($row = $db->fetch_row_assoc()) {
//    print "<p><pre>";print_r($previous);print "</pre></p>";
        $row['previous'] = $previous[$row['division_date']."-".$row['division_number']."-".$row['house']];
        array_unshift($rows, $row); 
        $previous[$row['division_date']."-".$row['division_number']."-".$row['house']] = $row['text_body'];
    }
 //   print "<p><pre>";print_r($previous);print "</pre></p>";

    $prettyrow = 0;
    foreach ($rows as $row)
    {
        $prettyrow = pretty_row_start($prettyrow);
        print "<td valign=\"top\" width=\"16%\">";
        if ($type == 'motion') {
            print 
                "<a href=\"division.php?date=" . $row['division_date'] . "&number=" . $row['division_number'] . 
                "&house=" . $row['house'] . "\">" . 
                $row['house'] . " vote ".
                $row['division_date'] . "#" . $row['division_number'] . 
                "</a>";
        } else {
            print "wikiid".$row['wiki_id'];
        }
        print "<p>Edited by ".pretty_user_name($db, html_scrub(($row['user_name'])));
        print "<p>on " . $row['edit_date'] . "\n";
        print "</td>";
        $marked_text_diff = format_linediff(
            extract_motion_text_from_wiki_text($row['previous']),
            extract_motion_text_from_wiki_text($row['text_body']), true);
        $marked_title_diff = format_linediff(
            extract_title_from_wiki_text($row['previous']),
            extract_title_from_wiki_text($row['text_body']), false);
        print "<td>" . 
            "<b>" . $marked_title_diff. "</b><br>".  $marked_text_diff.
            "</td>";
        print "</td></tr>";
    }
    print "</table>\n";

?>

<?php pw_footer() ?>
