<?php require_once "common.inc";

    # $dreamid: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "gather.inc";
    include "pretty.inc";
    $db = new DB(); 

    $title = "Motion Text Edits";
    include "header.inc";
?>
   <p>Recent changes to motion text.
<?php

    print "<table class=\"edits\">\n";
    print "<tr class=\"headings\">
        <td>Object</td>
        <td>Text</td>
        <td>Made by</td>
        <td>Date</td>
        </tr>";

    $query = "select object_key, text_body, user_name, pw_dyn_user.user_id as user_id, 
                     edit_date 
             from pw_dyn_wiki, pw_dyn_user
             where pw_dyn_wiki.user_id = pw_dyn_user.user_id
             order by pw_dyn_wiki.edit_date desc";
    $db->query($query);

    $prettyrow = 0;
    while ($row = $db->fetch_row_assoc())
    {
        $prettyrow = pretty_row_start($prettyrow);
        if ($matches = get_motion_from_key($row['object_key'])) {
            $division_date = $matches[1];
            $division_number = $matches[2];
            print "<td><a href=\"division.php?date=\"" . $division_date . "&number=" . $division_number . ">" . $division_date . "#" . $division_number . "</a></td>";
        } else {
            print "<td>" . $row['object_key'] . "</td>";
        }
        print "<td>" . trim_characters(sanitise_wiki_text_for_display($row['text_body']), 0, 200) . "</td>\n";
        print "<td>" . html_scrub($row['user_name']) . "</td>";
        print "<td>" . $row['edit_date'] . "</td>\n";
        print "</td></tr>";
    }
    print "</table>\n";

?>

<?php include "footer.inc" ?>
