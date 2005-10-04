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

    $key = db_scrub($_GET["key"]);
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
    list($dummy, $division_date, $division_number) =  get_motion_from_key($key);
    $query = "select concat('motion-', pw_division.division_date, '-', pw_division.division_number) as object_key, 
                     motion, division_name from pw_division ";
    if ($key)
        $query .= " where division_date = '$division_date' and division_number = '$division_number'";
    $db->query($query);
    $previous = array();
    while ($row = $db->fetch_row_assoc()) {
        $previous[$row['object_key']] = add_motion_missing_wrappers($row['motion'], $row['division_name']);
    }

    // And loop through later ones
    $query = "select object_key, text_body, user_name, pw_dyn_user.user_id as user_id, 
                     edit_date 
             from pw_dyn_wiki, pw_dyn_user
             where pw_dyn_wiki.user_id = pw_dyn_user.user_id ";
    if ($key) 
        $query .= "and object_key = '$key' ";
    $query .= "order by pw_dyn_wiki.edit_date";
    $db->query($query);
    $rows = array();
    while ($row = $db->fetch_row_assoc()) {
        $row['previous'] = $previous[$row['object_key']];
        array_unshift($rows, $row); 
        $previous[$row['object_key']] = $row['text_body'];
    }

    $prettyrow = 0;
    foreach ($rows as $row)
    {
        $prettyrow = pretty_row_start($prettyrow);
        print "<td valign=\"top\">";
        if ($matches = get_motion_from_key($row['object_key'])) {
            $division_date = $matches[1];
            $division_number = $matches[2];
            print "<a href=\"division.php?date=" . $division_date . "&number=" . $division_number . "\">" . $division_date . "#" . $division_number . "</a>";
        } else {
            print $row['object_key'];
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
        print "<td class=\"oddcol\">" . 
            "<b>" . $marked_title_before. "</b><br>".  $marked_text_before.
            "</td>";
        print "<td class=\"evencol\">" . 
            "<b>" . $marked_title_before. "</b><br>".  $marked_text_after.
            "</td>";
        print "</td></tr>";
    }
    print "</table>\n";

?>

<?php include "footer.inc" ?>
