<?php require_once "common.inc";
    # $Id: jmp.php,v 1.8 2005/02/18 12:13:18 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.
    include "cache-begin.inc";

    include "db.inc";
    include "parliaments.inc";
    include "constituencies.inc";
    include "gather.inc";
    $db1 = new DB();
    $db = new DB();

    $first_name = db_scrub($_GET["firstname"]);
    $last_name = db_scrub($_GET["lastname"]);
	$dreammpid = db_scrub($_GET["dreammpid"]);
    # The consmatch converts constituency to canonical form as it comes in
    $constituency = $_GET["constituency"];
    $constituency = $consnames[$consmatch[strtolower(stripslashes(html_entity_decode($constituency)))]];
    $constituency = db_scrub($constituency);
    $id = db_scrub($_GET["id"]);
    if ($constituency == "" and $id == "") {
        print "Error, constituency " . $_GET["constituency"] . " not found";
        exit;
    }

    if ($last_name == "" && $first_name =="")
    {
		if ($constituency == "")
		{
			$id = str_replace("uk.org.publicwhip/member/", "", $id);
			$query = "select first_name, last_name, constituency
				from pw_mp where mp_id = '$id'
				order by entered_house desc limit 1";
			$row = $db1->query_one_row($query);
			$first_name = db_scrub($row[0]);
			$last_name = db_scrub($row[1]);
			$constituency = db_scrub($row[2]);
		}
		else
		{
            $constituency = $constituency;
			$query = "select first_name, last_name
				from pw_mp where constituency = '$constituency'
				order by entered_house desc limit 1";
			$row = $db1->query_one_row($query);
			$first_name = db_scrub($row[0]);
			$last_name = db_scrub($row[1]);
		}
    }

    $this_anchor = "mp.php?firstname=" . urlencode($first_name) .
        "&lastname=" . urlencode($last_name) . "&constituency=" .
        urlencode($constituency);

	$mpattrib = array('first_name' => $first_name, 'last_name' => $last_name,
		              'constituency' => $constituency, 'id' => $id);

	# get the chosen dream MP
    $now = strftime("%Y-%m-%d");
	if ($dreammpid == "") {
        die("Need a DreamMP id");
    }
    $query = "select name, description, pw_dyn_user.user_id, user_name
        from pw_dyn_rolliemp, pw_dyn_user
        where pw_dyn_rolliemp.user_id = pw_dyn_user.user_id and rollie_Id = '$dreammpid'";
    $row = $db1->query_one_row($query);
    $dmp_name = html_scrub($row[0]);
    $dmp_description = $row[1];
    $dmp_user_id = $row[2];
    $dmp_user_name = $row[3];

	# do the header, which opens a title table
    $title = html_scrub("Comparison - $first_name $last_name MP with '$dmp_name' Dream MP");
	include "header.inc";
	print "</td></tr><tr><td>\n"; # get rid of colspan
    print "<h2>Selected by '<a href=\"dreammp.php?id=$dreammpid\">$dmp_name</a>' - Dream MP</h2>";
	print "</td><td align=\"right\">Date: $now</td>\n";

    # close the table
	print "</table>\n"; # get rid of header

    $query = "select person from pw_mp where ";
    $query .= "first_name = '$first_name' and last_name='$last_name' and";
    $query .= " constituency = '$constituency' order by entered_house desc limit 1";
    $db1->query($query);
    $row = $db1->fetch_row();
    $person = $row[0];
?>

<?
 	$query = "select dept, position, from_date, to_date
        from pw_moffice where pw_moffice.person = '$person'
        order by from_date desc";
    $db1->query($query);
    $prettyrow = 0;
    $events = array();
    $currently_minister = "";
    while ($row = $db1->fetch_row_assoc())
    {
        if ($row["from_date"] <= $now && $now <= $row["to_date"])
        {
            $currently_minister = $row["position"].  ", " .  $row["dept"];
        }
        if ($row["to_date"] != "9999-12-31")
        {
            array_push($events, array($row["to_date"], "Stopped being " .  $row["position"].  ", " . $row["dept"]));
        }
        array_push($events, array($row["from_date"], "Became " .  $row["position"]. ", " . $row["dept"]));
    }
    $events = array_reverse($events);
?>

<?
	$query = "select first_name, last_name, title, constituency,
        party, pw_mp.mp_id, round(100*rebellions/votes_attended,1),
        round(100*votes_attended/votes_possible,1),
        rebellions, votes_attended, votes_possible,
        entered_house, left_house,
        entered_reason, left_reason,
        tells, person from pw_mp,
        pw_cache_mpinfo where
        pw_mp.mp_id = pw_cache_mpinfo.mp_id and ";
    $query .= "first_name = '$first_name' and last_name='$last_name' and";
    $query .= " constituency = '$constituency' order by entered_house desc";
    $db1->query($query);

    $prettyrow = 0;
    $mp_ids = array();
    $parties = array();
    $from_dates = array();
    $to_dates = array();
    $enter_reason = array();
    $left_reason = array();
    $person = 0;
    while ($row = $db1->fetch_row())
    {
        $prettyrow = pretty_row_start($prettyrow);
        $row[6] = percentise($row[6]);
        $row[7] = percentise($row[7]);
        if ($row[12] == "9999-12-31") { $row[12] = "still in office"; }
        array_push($mp_ids, $row[5]);
        array_push($parties, $row[4]);
        array_push($from_dates, $row[11]);
        array_push($to_dates, $row[12]);
        array_push($enter_reason, $row[13]);
        array_push($left_reason, $row[14]);
        $person = $row[16];
    }
?>


<?php

    function print_event($event)
    {
		print "<p><table class=\"container\">\n";
		print "<tr><td> $event[0] </td><td> $event[1] </td></tr>\n";
		print "<table></p>\n";
    }
	function writepersonvote($cla, $name, $vote)
	{
        global $prettyrow;
        $prettyrow = pretty_row_start($prettyrow);
		print "<td>$name</td>";
		if (($vote == "aye") || ($vote == "tellaye"))
			print "<td>Aye</td><td></td>";
		else if (($vote == "aye") || ($vote == "no"))
			print "<td></td><td>No</td>";
		else
			print "<td colspan=\"2\">$vote</td>";
		print "</tr>\n";
	}
	function writenumbervote($gname, $sayes, $snoes)
	{
        if ($sayes == "")
			$sayes = 0;
        if ($snoes == "")
			$snoes = 0;
        global $prettyrow;
        $prettyrow = pretty_row_start($prettyrow);
		print "<td>$gname</td><td>$sayes</td><td>$snoes</td></tr>\n";
	}

    $shortmpname = substr($first_name, 0, 1).".".$last_name;

    $events_ix = 0;
    for ($i = 0; $i < count($mp_ids); ++$i)
    {
        # Table of votes in each division
		$party = $parties[$i];
		$qselect = "pw_division.division_id, pw_division.division_number, pw_division.division_date,
		            division_name, source_url, motion";
		$qfrom =   "pw_division";
		$qwhere =  "";
		$qtail =   "order by division_date, division_number";


		if ($dreammpid != "")
		{
			$qselect .= ", pw_dyn_rollievote.vote";
			$qfrom .= ", pw_dyn_rollievote";
			$qwhere = "     pw_dyn_rollievote.rolliemp_id = '$dreammpid' and
						     pw_dyn_rollievote.division_number = pw_division.division_number and
						     pw_dyn_rollievote.division_date = pw_division.division_date";
		}

        else
        {
			$qselect .= ", pw_vote.vote";
			$qfrom .= ", pw_vote";
			$qwhere =  "pw_vote.mp_id = $mp_ids[$i] and
			            pw_division.division_id = pw_vote.division_id";
        }

        $query = "select ".$qselect." FROM ".$qfrom." WHERE ".$qwhere." ".$qtail;
        $db1->query($query);


        while ($row = $db1->fetch_row_both())
        {
			$division_id = $row[0];
			$division_number = $row[1];
			$division_date = $row[2];
            $division_name = $row['division_name'];
			$vote = $row[6];

			$dreamvote = "";
			# extract the real vote of the MP for this
			if ($dreammpid != "")
			{
				$dreamvote = $vote;
				$vote = "absent";
		        $db->query("SELECT vote FROM pw_vote WHERE pw_vote.division_id = $division_id and pw_vote.mp_id = $mp_ids[$i]");
		        if ($rowvote = $db->fetch_row())
		        	$vote = $rowvote[0];
			}

			$row4 = $row['source_url'];
            $motion_key = get_motion_wiki_key($division_date, $division_number);
            $motion_data = get_wiki_current_value($motion_key);
			$motion = sanitise_wiki_text_for_display($motion_data['text_body']);

            while ($events_ix < count($events) && $division_date >= $events[$events_ix][0])
			{
                print_event($events[$events_ix]);
                $events_ix ++;
            }


			# now make the full text
			print "<p>\n";
			print "<table class=\"container\">\n";
			$divlink = "<a href=\"division.php?date=$division_date&number=$division_number\">";
			print "<tr><th align=\"left\">$divlink $division_name </a></th><th>$divlink $division_date #$division_number </a></th></tr>\n";
			print "<tr valign=\"top\"><td width=\"80%\">$motion</td>\n";

			print "<td><table>";
			print "<tr class=\"headings\"><td></td><td>Aye</td><td>No</td></tr>\n";
            $prettyrow = 0;

			writepersonvote("strong", $shortmpname, $vote);
			if ($dreamvote != "")
				writepersonvote("", "DreamMP", $dreamvote);

			# get the summary of the rest of the voting from the database
			$partysummary = GetPartyVoteSummary($db, $division_id);

			# total votes
			$totalayes = array_sum(array_values($partysummary['ayes'])) + array_sum(array_values($partysummary['tellayes']));
			$totalnoes = array_sum(array_values($partysummary['noes'])) + array_sum(array_values($partysummary['tellnoes']));
			writenumbervote("Total", $totalayes, $totalnoes);

			# votes within party
			writenumbervote($party, $partysummary['ayes'][$party], $partysummary['noes'][$party]);

			# votes of rest of parties
			arsort($partysummary['totalpartyvote']);
			$nplines = 3;
			foreach ($partysummary['totalpartyvote'] as $lparty => $val)
			{
				if ($lparty != $party)
					writenumbervote($lparty, $partysummary['ayes'][$lparty], $partysummary['noes'][$lparty]);
				if ($nplines -- == 0)
					break;
			}
			print "</table></td></tr>\n";

			print "</table>\n";
			print "</p>\n";
        }
    }
    while ($events_ix < count($events))
    {
        print_event($events[$events_ix]);
        $events_ix ++;
    }
# re-open for the footer
print "<table align=\"center\" class=\"container\" cellpadding=\"0\" cellspacing=\"0\">\n";
?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
