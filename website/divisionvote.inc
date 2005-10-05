<?php

# $Id: divisionvote.inc,v 1.11 2005/10/05 13:14:07 goatchurch Exp $
# Handles the dreammp vote on the divisions page

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

        # Dream MP feature
        function vote_value($value, $curr)
        {
            $ret = "value=\"" . html_scrub($value) . "\" ";
            if ($value == $curr)
            {
                $ret .= "selected ";
            }
            return $ret;
        }

		# the generated table on the division page
        function write_dream_vote($db, $divattr)
        {
			global $bdebug;
            $submit=mysql_escape_string($_POST["submit"]);

            print "<div class=\"tabledream\">";
            print "<span class=\"ptitle\">Policy Votes</span>";

			$qrdiv = "pw_dyn_dreamvote.division_date = '".$divattr["division_date"]."'
					   AND pw_dyn_dreamvote.division_number = '".$divattr["division_number"]."'";

            $query = "SELECT pw_dyn_dreammp.dream_id, name, description,
							 pw_dyn_dreamvote.vote AS vote, private
					  FROM pw_dyn_dreammp
					  LEFT JOIN pw_dyn_dreamvote
					    ON pw_dyn_dreamvote.dream_id = pw_dyn_dreammp.dream_id
					     AND $qrdiv
					  WHERE NOT private OR user_id = '".user_getid()."'
                      ORDER BY private";

            print "<p>Select this division as relevant to a policy.</p>";
			if ($bdebug == 1)
				print "<h2>$query</h2>";

            print '<FORM ACTION="'.$divattr["divhref"].'" METHOD="POST">';
            print '<table>';

            $db->query($query);
            $rowarray = $db->fetch_rows_assoc();
            foreach ($rowarray as $row)
            {
				$vote = $row["vote"];
				if (!$vote)
					$vote = '--';

                # alter dream MP's vote if they submitted form
                if ($submit)
                {
                    $changedvote = mysql_escape_string($_POST["vote" . $row['dream_id']]);
                    if ($changedvote != $vote)
                    {
                        print "<tr><td colspan=2><div class=\"error\">";
                        notify_dream_mp_updated($db, intval($row['dream_id']));
                        notify_division_updated($db, $date, $div_no);

                        if ($changedvote == "--")
                        {
                            $query = "DELETE FROM pw_dyn_dreamvote
									  WHERE dream_id='".$row['dream_id']."'
									   AND $qrdiv";
							if ($bdebug == 1)
								print "<h2>$query</h2>";

                            $db->query($query);
                            if ($db->rows() == 0)
                                print "Error changing '" . html_scrub($row['name']) . "' to non-voter (no change)";
                            elseif ($db->rows() > 1)
                                print "Error changing '" . html_scrub($row['name']) . "' to non-voter (too many rows)";
                            audit_log("Changed '" . $row['name'] . "' to non-voter for division " . $date . " " . $div_no);
                            print html_scrub("Changed '" . $row['name'] . "' to non-voter");
                        }
                        else
                        {
                            if ($vote == "--")
                                $query = "INSERT INTO pw_dyn_dreamvote
											(vote, dream_id, division_date, division_number)
										  VALUES
										  	('$changedvote', '".$row['dream_id']."', '".$divattr["division_date"]."', '".$divattr["division_number"]."')";
							else
	                            $query = "UPDATE pw_dyn_dreamvote
										  SET vote='$changedvote'
										  WHERE dream_id='".$row['dream_id']."'
										   AND $qrdiv";

							if ($bdebug == 1)
								print "<h2>$query</h2>";
                            $db->query($query);
                            if ($db->rows() == 0)
                                print "Error changing '" . html_scrub($row['name']) . "' to " . $changedvote . " (no change)";
                            elseif ($db->rows() > 1)
                                print "Error changing '" . html_scrub($row['name']) . "' to " . $changedvote . " (too many rows)";
                            audit_log("Changed '" . $row['name'] . "' to " . $changedvote . " for division " . $date . " " . $div_no);
                            print html_scrub("Changed '" . $row['name'] . "' to " . $changedvote);
                        }
                        print "</div></td></tr>";
                        $vote = $changedvote;
                    }
                }
                # display dream MP vote
                print "<tr><td>\n";
                print '<a href="policy.php?id=' . $row['dream_id'] . '">' . html_scrub($row['name']) . "</a>: \n";
                if ($row['private']) {
                    print " (legacy Dream MP)";
                }
                print "</td><td>\n";
                print ' <select name="vote' . $row['dream_id'] . '" size="1">
                                    <option ' . vote_value("--", $vote) . '>Non-voter</option>
                                    <option ' . vote_value("aye3", $vote) . '>Aye 3-Line</option>
                                    <option ' . vote_value("aye", $vote) . '>Aye</option>
                                    <option ' . vote_value("both", $vote) . '>Abstain</option>
                                    <option ' . vote_value("no", $vote) . '>No</option>
                                    <option ' . vote_value("no3", $vote) . '>No 3-Line</option>
                                </select></p>';
                print '</td></tr>';
            }
            print "<tr><td>\n";
            print ' <a href="account/addpolicy.php">[Make a new policy]</a>';
            print "</td><td>\n";
            if (count($rowarray) > 0)
                print '<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Update Votes">';
            print '</td></tr>';
            print '<tr><td colspan=2><a href="http://www.publicwhip.org.uk/forum/viewforum.php?f=1">Questions? Discuss it here</a></td><tr>';
            print '</table>';
            print '</FORM>';
            print "</div>";
        }


?>
