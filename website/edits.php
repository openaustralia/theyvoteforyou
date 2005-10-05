<?php require_once "common.inc";

    # $id: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "wiki.inc";
    include "pretty.inc";
    include "DifferenceEngine.inc";
    $db = new DB(); 

    $type = db_scrub($_GET["type"]);
    if ($type) {
        if ($type == 'motion') {
            if ($_GET["date"]) 
                $params = array(db_scrub($_GET["date"]), db_scrub($_GET["number"]), db_scrub($_GET["house"]));
            else
                $params = null;
        } else {
            die("Unknown wiki type " . htmlspecialchars($type));
        }
    }

    $title = "Motion Text Edits for $key";
    include "header.inc";
?>
   <p>Recent changes to motion text.
<?php

    print "<table class=\"edits\">\n";
    print "<tr class=\"headings\">
        <td>Event</td>
        <td>Motion Text Before</td>
        <td>Motion Text After</td>
        </tr>";

    function format_linediff($prev, $next) {
        $df  = new WordLevelDiff(array($prev), array($next));
        $opening = $df->orig();
        $closing = $df->closing();
        print_r($closing);
        print_r($opening);
        # TODO: These joins are knackered - every other entry has a
        # weird bit of whitespace in it which breaks the display.  Odd!
        return array(join($closing, " "), join($opening, " "));
    }

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
        $row['previous'] = $previous[$row['division_date']."-".$row['division_number']."-".$row['house']];
        array_unshift($rows, $row); 
        $previous[$row['division_date']."-".$row['division_number']."-".$row['house']] = $row['text_body'];
    }

    $prettyrow = 0;
    foreach ($rows as $row)
    {
        $prettyrow = pretty_row_start($prettyrow);
        print "<td valign=\"top\" width=\"16%\">";
        if ($type == 'motion') {
            print "<a href=\"division.php?date=" . $row['division_date'] . "&number=" . $row['division_number'] . 
                "&house=" . $row['house'] . "\">" . $row['division_date'] . "#" . $row['division_number'] . 
                " " . $row['house'] . "</a>";
        } else {
            print "wikiid".$row['wiki_id'];
        }
        print "<p>Edited by ".html_scrub($row['user_name']);
        print "<p>" . $row['edit_date'] . "\n";
        print "</td>";
        # TODO: Get diff highlighting to work.  For now it is knackered.`
        list($marked_text_before, $marked_text_after) = array/*format_linediff*/(
            extract_motion_text_from_wiki_text($row['previous']),
            extract_motion_text_from_wiki_text($row['text_body']));
        list($marked_title_before, $marked_title_after) = array/*format_linediff*/(
            extract_title_from_wiki_text($row['previous']),
            extract_title_from_wiki_text($row['text_body']));
        print "<td class=\"oddcol\" width=\"42%\">" . 
            "<b>" . $marked_title_before. "</b><br>".  $marked_text_before.
            "</td>";
        print "<td class=\"evencol\" width=\"42%\">" . 
            "<b>" . $marked_title_before. "</b><br>".  $marked_text_after.
            "</td>";
        print "</td></tr>";
    }
    print "</table>\n";

?>

<?php include "footer.inc" ?>
