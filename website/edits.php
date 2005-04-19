<?php require_once "common.inc";

    # $dreamid: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

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
        <td>Object</td>
        <td>Division Title</td>
        <td>Motion Text</td>
        <td>Made by</td>
        <td>Date</td>
        </tr>";

    function format_linediff($prev, $next) {
        $df  = new WordLevelDiff(array($prev), array($next));
        $opening = $df->orig();
        $closing = $df->closing();
        return "<table>".
               "<tr><td><b>After:</b></td><td> " . join($closing, " ") . "</td></tr>".
               "<tr><td><b>Before:</b></td><td> " . join($opening, " ") . "</td></tr>".
               "</table>";
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
        if ($matches = get_motion_from_key($row['object_key'])) {
            $division_date = $matches[1];
            $division_number = $matches[2];
            print "<td><a href=\"division.php?date=" . $division_date . "&number=" . $division_number . "\">" . $division_date . "#" . $division_number . "</a></td>";
        } else {
            print "<td>" . $row['object_key'] . "</td>";
        }
        print "<td>" .  format_linediff(
            extract_title_from_wiki_text($row['previous']),
            extract_title_from_wiki_text($row['text_body'])
            ) . "</td>\n";
        print "<td>" . format_linediff(
            extract_motion_text_from_wiki_text($row['previous']),
            extract_motion_text_from_wiki_text($row['text_body'])
            ) . "</td>\n";
        #print "<td>" . extract_motion_text_from_wiki_text($row['text_body']) . "</td>";
        #print "<td>" . extract_motion_text_from_wiki_text($row['previous']) . "</td>";
        print "<td>" . html_scrub($row['user_name']) . "</td>";
        print "<td>" . $row['edit_date'] . "</td>\n";
        print "</td></tr>";
    }
    print "</table>\n";

?>

<?php include "footer.inc" ?>
