<?php
# $Id: rtablepeop.inc,v 1.4 2009/05/25 10:48:26 marklon Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once $toppath . "links.inc";
require_once $toppath . "parliaments.inc";


function print_mpcolumn_headings($columnforms)
{
    print "<tr class=\"headings\">";
    if ($columnforms["distancetoagreement"])
        print "<td>Agreement</td>"; 
    if ($columnforms["name"])
	    print "<td>Name</td>";
	if ($columnforms["place"])
        print "<td>Constituency</td>";
	if ($columnforms["party"])
	    print "<td>Party</td>";

	if ($columnforms["vote"])
        print "<td>Vote</td>";
	if ($columnforms["vote_a"])
        print "<td>Vote (a)</td>";
	if ($columnforms["vote_b"])
        print "<td>Vote (b)</td>";

	if ($columnforms["dates"])
        print "<td>Dates</td>"; 
    if ($columnforms["rebellions"])
	    print "<td>Rebellions<br>(<a href=\"/faq.php#clarify\">explain...</a>)</td>";
	if ($columnforms["attendance"])
	    print "<td>Attendance<br>(<a href=\"/faq.php#clarify\">explain...</a>)</td>";
    print "</tr>";
}

function print_mp_row($nrows, $row, $name, $href, $colstyle, $showwhich, $friendlk, $columnforms)
{
    # row colour
    $sclass = "";
    if ($colstyle == "division")
    {
		$vote = str_replace("tell", "", $row["vote"]);
        if ($vote == "both")
            $sclass = "both";
        elseif (($showwhich != "rebels")
                && ($row["whip_guess"] != "unknown") && ($row["whip_guess"] != "none")
				&& ($vote != "") && ($vote != $row["whip_guess"]))
            $sclass = "rebel";
    }
    elseif ($colstyle == "division2" or $colstyle == "division2invert")
    {
        $dtvote_a = str_replace("tell", "", $row["vote_a"]);
        if ($dtvote_a != "aye" and $dtvote_a != "no")
            $dtvote_a = "neither";
        $dtvote_b = str_replace("tell", "", $row["vote_b"]);
        $sclassd = "rebelteller";
        if ($dtvote_b != "aye" and $dtvote_b != "no")
            $dtvote_b = "neither";
        elseif ($dtvote_a != "neither")
            $sclassd = ((($colstyle == "division2invert") == ($dtvote_a == $dtvote_b)) ? "rebel" : "teller");
    }

    print "<tr class=\"".(($nrows % 2 == 1) ? "odd" : "even").$sclass."\">";


    # row numbering
	if ($columnforms["rownumbering"])
        print "<td>$nrows</td>";

    #distance voting table
    if ($columnforms["distancetoagreement"])
    {
        $distance = $row['distance']; 
        print "<td>"; 
        if ($friendlk)
            print "<a href=\"$href&$friendlk\"><b>"; 
        print pretty_distance_to_agreement($distance); 
        if ($friendlk)
            print "</b></a>"; 
        print "</td>"; 
    }


    # name and constituency
	if ($columnforms["name"])
	    print "<td><a href=\"$href\">$name</a></td>";

    # we could mark if there are other MPs in this constituency and make a link to them
    #print "<td>".$row['constituency']."</td>";
	if ($columnforms["place"])
	{
    	print "<td>";
		if ($row['house'] != 'lords')
		print "<a href=\"mp.php?mpc=".urlencode($row['constituency'])."&house=".urlencode($row['house'])."\">".$row['constituency']."</a>";
    	else
        	print "<i>(Lords)</i>";
		print "</td>";
	}

	if ($columnforms["party"])
	{
		$party = pretty_party_raw($row['party']);
	    if ($row["entered_reason"] == "changed_party" or $row["left_reason"] == "changed_party")
	        $party = "whilst ".$party;
	    if (($columnforms["party"] == "ministerial") and $row["ministerial"])
	        $party = $party.($row["ministerial"] == "PPS" ? " (PPS)" : " (minister)");
	    print "<td>$party</td>";
	}

	if ($columnforms["vote"])
        print "<td>".($row["vote"] ? $row["vote"] : "absent")."</td>";
	if ($columnforms["vote_a"])
		print "<td>".($row["vote_a"] ? $row["vote_a"] : "absent")."</td>\n";
	if ($columnforms["vote_b"])
        print "<td class=\"$sclassd\">".($row["vote_b"] ? $row["vote_b"] : "absent")."</td>\n";

	if ($columnforms["dates"])
    {
        $y1 = substr($row["entered_house"], 0, 4);
	    $y2 = substr($row["left_house"], 0, 4);
        if ($y1 == "0000")
            $y1 = "<i>1999</i>"; // only the case if this is the lords
	    if ($y2 == "9999")
		    $y2 = "<i>present</i>";//date("Y");
        $yearrange = "($y1-$y2)";  # could be included in the percentise_votes as an extra bit
        print "<td>$yearrange</td>";
    }

	if ($columnforms["rebellions"])
        if (whipless_party($row["party"]))
            print "<td class=\"percent\">n/a</td>";
        else
            print "<td class=\"percent\">".percentise_votes_short($row['rebellions'], $row['votes_attended'])."</td>";
	if ($columnforms["attendance"])
        print "<td class=\"percent\">".percentise_votes_short($row['votes_attended'], $row['votes_possible'])."</td>";

    print "</tr>\n";
}


# a function which generates any table of mps for printing,
# and marks their votes or distance rankings, or second votes
# in another division.
# This is used to show the people who are friends, where
# listtype is:
#   'parliament', then 'parliament' is a value from $parliaments,
#   'mpdistance', then 'mpfriend' is an mpprop for distance from
# 	'dreamdistance', then 'dreammpid' is what we compare to
#   'division', then 'divdate', 'divno', 'divhouse' index into that
#     'division2', then there's also 'divdate2', 'divno2'
#   'search', then 'search' is a query string to search for
# limit is nothing or a number
# sortby is 'turnout', 'rebellions', 'name', 'constituency', 'attendance', 'party', 'vote'
# showwhich is 'rebels', 'changes', 'voters', 'allpossible'
# ministerial is 'yes' or none.
function mp_table($db, $mptabattr)
{
    global $bdebug;
    global $parliaments;

    if ($bdebug == 1)
        print_r($mptabattr);

    $aquery = array();
    $aquery["qselect"] = "SELECT first_name, last_name, title, constituency, pw_mp.party AS party, pw_mp.house as house,
                                 entered_house, left_house,
                                 entered_reason, left_reason,
                                 pw_mp.mp_id AS mpid,
                                 rebellions, votes_attended, votes_possible";
    $aquery["qfrom"] =  " FROM pw_mp";
    $aquery["qjoin"] =  " LEFT JOIN pw_cache_mpinfo ON pw_cache_mpinfo.mp_id = pw_mp.mp_id";
    $aquery["qwhere"] = " WHERE 1=1";

	$columnforms = array();


	$tailorder = ""; 
	if ($mptabattr["sortby"] == "constituency")
	    $tailorder = " constituency, last_name, first_name";
	# by name primarily
	elseif ($mptabattr["house"] == "lords")
	    $tailorder = " concat(first_name, substring(last_name, 4))";  # a hack to strip the of-s and make the names comparable
	elseif ($mptabattr["house"] == "commons")
	    $tailorder = " replace(last_name, '&Ouml;', 'O'), first_name, constituency";
    elseif ($mptabattr["house"] == "scotland")
        $tailorder = " last_name, first_name, constituency";

	# we're stuffed for lords sorting, till we make it much more elaborate
	else
	    $tailorder = " concat(substring(replace(last_name, '&Ouml;', 'O'), (house='commons')), first_name, substring(last_name, (house='lords')*4)), constituency"; 

	if ($mptabattr["sortby"] != "party" and !(($mptabattr["sortby"] == "vote") and ($mptabattr["listtype"] != 'division') and ($mptabattr["listtype"] != 'division2')))
	    $tailorder .= ", party";

        
	# main ordering functionality
    if ($mptabattr["listtype"] != 'dreamdistance')
    {
    	$aquery["qorder"]  = " ORDER BY";
	    if ($mptabattr["sortby"] == "rebellions")
	        $aquery["qorder"] .= " round(rebellions/votes_attended,10) desc,";
	    elseif ($mptabattr["sortby"] == "attendance")
	        $aquery["qorder"] .= " round(votes_attended/votes_possible,10) desc,";

	    if ($mptabattr["listtype"] == 'division')
	    {
	        if ($mptabattr["sortby"] == "party")
	            $aquery["qorder"] .= " replace(pw_mp.party, 'Lab', 'ZZZ') DESC, ";
	        elseif ($mptabattr["sortby"] == "vote")
	            $aquery["qorder"] .= " pw_vote_sortorder.position DESC, ";
	    }

	    elseif ($mptabattr["listtype"] == 'division2')
	    {
	        if ($mptabattr["sortby"] == "party")
	            $aquery["qorder"] .= " party, pw_vote_sortorder_a.position DESC, pw_vote_sortorder_b.position DESC, ";
	        elseif ($mptabattr["sortby"] == "vote")
	            $aquery["qorder"] .= " pw_vote_sortorder_a.position DESC, pw_vote_sortorder_b.position DESC, ";
	        elseif ($mptabattr["sortby"] == "vote2")
	            $aquery["qorder"] .= " pw_vote_sortorder_b.position DESC, pw_vote_sortorder_a.position DESC, ";
	    }

	    # without a vote column (just a list of MPs)
	    else
	    {
	        if ($mptabattr["sortby"] == "party")
	            $aquery["qorder"] .= " party, ";
	        elseif ($mptabattr["sortby"] == "vote")
	            $aquery["qorder"] .= " vote, party, ";
            elseif ($mptabattr["sortby"] == "date")
                $aquery["qorder"] .= " left_house,"; 
	    }

		# trail off by name
	    $aquery["qorder"] .= $tailorder;
	    if ($bdebug == 1)
	        print "\n<h3>".$aquery["qorder"]."</h3>\n";
	}

    # go through the different list selection cases
    $showwhich = $mptabattr["showwhich"];

    $friendlk = "";  // added to the end of a link

    # range of mps in one parliament
    if ($mptabattr["listtype"] == 'parliament')
    {
        $parliament = $mptabattr["parliament"];
        if ($parliament == "now")
			$aquery["qwhere"] .= " AND left_house = '9999-12-31'";
		elseif ($parliament == "all")
            $columnforms["dates"] = "yes"; 
        else
		{
	        $parliament_entry = $parliaments[$parliament];
			$aquery["qwhere"] .= " AND left_house > '".$parliament_entry['from']."'
	                               AND entered_house <= '".$parliament_entry['to']."'";
		}

		$columnforms["rebellions"] = "yes";
		$columnforms["attendance"] = "yes";
    }

    # list of possible friends of an mp
    elseif ($mptabattr["listtype"] == 'mpdistance')
    {
        $mpprop = $mptabattr["mpfriend"];
        $aquery["qselect"] .= ", distance_a as distance";
        $aquery["qjoin"] .= " LEFT JOIN pw_cache_realreal_distance
                                ON pw_cache_realreal_distance.mp_id1 = pw_mp.mp_id
                                 AND pw_cache_realreal_distance.mp_id1 <> ".$mpprop["mpid"]."
                                 AND pw_cache_realreal_distance.mp_id2 = ".$mpprop["mpid"];
        $aquery["qwhere"] .= " AND distance_a IS NOT null AND distance_a != -1";
        $aquery["qorder"] = " ORDER BY distance_a, $tailorder";
        $friendlk = $mpprop['mpanchor2'];
		$columnforms["distancetoagreement"] = "yes";
    }

    elseif ($mptabattr["listtype"] == 'dreamdistance')
    {
        $dreamid = $mptabattr["dreammpid"];
        update_dreammp_person_distance($db, $dreamid);

        # we need to make the proper equation here, to people
        $aquery["qselect"]  .= ", distance_a AS distance";
        $aquery["qjoin"] 	.= " LEFT JOIN pw_cache_dreamreal_distance
                                    ON pw_cache_dreamreal_distance.person = pw_mp.person
                                    AND pw_cache_dreamreal_distance.dream_id = $dreamid";
        $aquery["qorder"] = " ORDER BY distance, $tailorder";

        # this should use the left-reason case
        $aquery["qwhere"] 	.= " AND left_house = '9999-12-31'
                                 AND distance_a <> -1";

        $friendlk = "dmp=".$mptabattr["dreammpid"];
		$columnforms["distancetoagreement"] = "yes";
    }

    # list MPs voting in one division
    elseif ($mptabattr["listtype"] == 'division')
    {
        # the division vote (joined)
        $aquery["qselect"] 	.= ", pw_vote.vote AS vote";
        $aquery["qjoin"] 	.= " LEFT JOIN pw_vote ON pw_vote.mp_id = pw_mp.mp_id
                                    AND pw_vote.division_id = ".$mptabattr["divid"];

        if ($showwhich == 'allpossible')
            $aquery["qwhere"] 	.= " AND entered_house <= '".$mptabattr["divdate"]."'
                                     AND left_house > '".$mptabattr["divdate"]."'
                                     AND house = '".$mptabattr["house"]."'";
        else
            $aquery["qwhere"] 	.= " AND pw_vote.vote IS NOT null";

        # the whip guess
        $aquery["qselect"]	.= ", whip_guess";
        $aquery["qjoin"]	.= " LEFT JOIN pw_cache_whip
                                    ON pw_cache_whip.division_id = ".$mptabattr["divid"]."
                                    AND pw_cache_whip.party = pw_mp.party";


        # comparison to the whip
        if ($showwhich == 'rebels')
            $aquery["qwhere"]	.= " AND whip_guess <> 'unknown'
            						 AND whip_guess <> 'none'
                                     AND whip_guess <> replace(pw_vote.vote, 'tell', '')";
                                     #AND pw_vote.vote <> 'both'

        # vote table sorting
        $aquery["qselect"] 	.= ", pw_vote_sortorder.position AS votesort";
        $aquery["qjoin"] 	.= " LEFT JOIN pw_vote_sortorder
                                    ON pw_vote_sortorder.vote = pw_vote.vote";

        $columnforms["vote"] = "yes";
    }
    # search names of MPs
    elseif ($mptabattr["listtype"] == 'search')
    {
        $search = $mptabattr["search"];
        $score_clause = "(";
        $score_clause .= "(lower(concat(first_name, ' ', last_name)) = '$search') * 10";
        $querybits = explode(" ", $search);
        foreach ($querybits as $querybit)
        {
            $querybits = trim($querybits);
            if ($querybits != "")
            {
                $score_clause .= "+ (lower(constituency) = '$querybit') * 10 + 
                (soundex(concat(first_name, ' ', last_name)) = soundex('$querybit')) * 8 + 
                (soundex(constituency) = soundex('$querybit')) * 8 + 
                (soundex(last_name) = soundex('$querybit')) * 6 + 
                (lower(constituency) like '%$querybit%') * 4 + 
                (lower(last_name) like '%$querybit%') * 4 + 
                (soundex(first_name) = soundex('$querybit')) * 2 + 
                (lower(first_name) like '%$querybit%') + 
                (soundex(constituency) like concat('%',soundex('$querybit'),'%'))";
            }
        }
        $score_clause .= ")";
        $aquery["qwhere"] 	.= " AND ($score_clause > 0) ";
        $aquery["qgroupby"] = " GROUP BY concat(first_name, ' ', last_name, ' ', constituency)"; 
        if ($mptabattr["sortby"] == "score") 
        {
            $aquery["qorder"]  = " ORDER BY";
	    	$aquery["qorder"] .= " $score_clause DESC";
        }
    }

    # double division case
    elseif ($mptabattr["listtype"] == 'division2')
    {
        $aquery["qselect"] 	.= ", pw_vote_a.vote AS vote_a, pw_vote_b.vote AS vote_b";
        $aquery["qjoin"] 	.= " LEFT JOIN pw_vote AS pw_vote_a ON pw_vote_a.mp_id = pw_mp.mp_id
                                    AND pw_vote_a.division_id = ".$mptabattr["divid"];
        $aquery["qjoin"] 	.= " LEFT JOIN pw_vote AS pw_vote_b ON pw_vote_b.mp_id = pw_mp.mp_id
                                    AND pw_vote_b.division_id = ".$mptabattr["divid2"];

        if ($showwhich == "rebels")
        {
            $aquery["qwhere"] 	.= " AND pw_vote_a.vote IS NOT null AND pw_vote_b.vote IS NOT null
                                     AND pw_vote_a.vote <> 'both' AND pw_vote_b.vote <> 'both'";
            $aquery["qwhere"] 	.= " AND ((pw_vote_a.vote = 'tellaye' OR pw_vote_a.vote = 'aye')";
            $aquery["qwhere"] 	.= ($mptabattr["div2invert"] ? " = " : " <> ");
            $aquery["qwhere"] 	.= "(pw_vote_b.vote = 'tellaye' OR pw_vote_b.vote = 'aye'))";
        }
        if ($showwhich == "changes")
        {
            $aquery["qwhere"] .= " AND (";
			if ($mptabattr["div2invert"])
			{
            	$aquery["qwhere"] .= "((pw_vote_a.vote = 'tellaye' OR pw_vote_a.vote = 'aye') = (pw_vote_b.vote = 'tellaye' OR pw_vote_b.vote = 'aye')) OR ";
            	$aquery["qwhere"] .= "((pw_vote_a.vote = 'tellno' OR pw_vote_a.vote = 'no') = (pw_vote_b.vote = 'tellno' OR pw_vote_b.vote = 'no'))";
			}
			else
			{
            	$aquery["qwhere"] .= "((pw_vote_a.vote = 'tellaye' OR pw_vote_a.vote = 'aye') = (pw_vote_b.vote = 'tellno' OR pw_vote_b.vote = 'no')) OR ";
            	$aquery["qwhere"] .= "((pw_vote_a.vote = 'tellno' OR pw_vote_a.vote = 'no') = (pw_vote_b.vote = 'tellaye' OR pw_vote_b.vote = 'aye'))";
			}
            $aquery["qwhere"] .= " OR ((pw_vote_a.vote IS null) <> (pw_vote_b.vote IS null))";
            $aquery["qwhere"] .= " OR ((pw_vote_a.vote = 'both') <> (pw_vote_b.vote = 'both')))";
        }
        if ($showwhich == "allpossible")
        {
            $house_condition = "";
            if( $mptabattr["house"] and ($mptabattr["house"] != 'both' and $mptabattr["house"] != 'all') )
                $house_condition = " AND house = '".$mptabattr["house"]."'";
            $aquery["qwhere"] 	.= " AND entered_house <= '".$mptabattr["divdate"]."'
                                     AND left_house > '".$mptabattr["divdate"]."'";
            $aquery["qwhere"] 	.= " AND entered_house <= '".$mptabattr["divdate2"]."'
                                     AND left_house > '".$mptabattr["divdate2"]."'".
                                     $house_condition;
        }
        else  #  "voters"
            $aquery["qwhere"] 	.= " AND (pw_vote_a.vote IS NOT null OR pw_vote_b.vote IS NOT null)";


        # vote table sorting (on both)
        $aquery["qselect"] 	.= ", pw_vote_sortorder_a.position AS votesort_a, pw_vote_sortorder_b.position AS votesort_b";
        $aquery["qjoin"] 	.= " LEFT JOIN pw_vote_sortorder AS pw_vote_sortorder_a
                                    ON pw_vote_sortorder_a.vote = pw_vote_a.vote
                                 LEFT JOIN pw_vote_sortorder AS pw_vote_sortorder_b
                                    ON pw_vote_sortorder_b.vote = pw_vote_b.vote";

        $columnforms["vote_a"] = "yes";
        $columnforms["vote_b"] = "yes";
    }

# end list type considerations

   	# is minister
    if ($mptabattr["ministerial"])
    {
        $aquery["qselect"] 	.= ", pw_moffice.position AS ministerial";
        $aquery["qjoin"] 	.= " LEFT JOIN pw_moffice ON pw_moffice.person = pw_mp.person
									AND (pw_moffice.from_date <= '".$mptabattr["divdate"]."')
                                    AND (pw_moffice.to_date > '".$mptabattr["divdate"]."')
                                    AND (pw_moffice.position <> 'Chairman')
                                    AND (pw_moffice.position <> '')";  # the last two refer to select committee positions

        $aquery["qgroupby"] = " GROUP BY pw_mp.mp_id";  # remove double ministers
		$columnforms["party"] = "ministerial";
	}
	else
		$columnforms["party"] = "yes";

    $house = $mptabattr["house"];
    if ($house and ($house != "both" and $house != "all"))
		$aquery["qwhere"]   .= " AND pw_mp.house = '$house'";

    # apply the limit
    if ($mptabattr["limit"])
        $aquery["qlimit"] = " LIMIT ".$mptabattr["limit"];


    $query = $aquery["qselect"].$aquery["qfrom"].$aquery["qjoin"].$aquery["qwhere"].$aquery["qgroupby"].$aquery["qorder"].$aquery["qlimit"];
    if ($bdebug == 1)
        print "\n<h3>$query</h3>\n";
    $db->query($query);

    # determine the column type
//  this $colstyle will be totally replaced by columnforms
    if ($friendlk)
        $colstyle = $mptabattr["listtype"];
    elseif ($mptabattr["limit"])
        $colstyle = "short".$mptabattr["sortby"]; # a short table on the index page
    elseif ($mptabattr["listtype"] == "division")
        $colstyle = "division";
    elseif ($mptabattr["listtype"] == "division2")
        $colstyle = "division2".($mptabattr["div2invert"] ? "invert" : "");
    else
        $colstyle = "list";

	if ($mptabattr["limit"])
	{
		if ($mptabattr["sortby"] == "rebellions")
		{
			$columnforms["rownumbering"] = "yes";
            $columnforms["attendance"] = "";
			$columnforms["rebellions"] = "yes";
		}
		if ($mptabattr["sortby"] == "attendance")
		{
			$columnforms["rownumbering"] = "yes";
			$columnforms["attendance"] = "yes";
            $columnforms["rebellions"] = "";
		}
	}


	$columnforms["name"] = "yes";
	if ($house != "lords")
		$columnforms["place"] = "yes";

	#if ($mptabattr["headings"])
	#	print_mpcolumn_headings($columnforms);

    # now output a sentence when there is an empty table (in cases where that can happen)
    if ($db->rows() == 0)
	{
		print "<tr class=\"even\"><td colspan=\"".count($columnforms)."\">";
		if ($colstyle == "division" and $showwhich == "rebels")
        	print "no rebellions";
		else if ($colstyle == "division2" and $showwhich == "rebels")
        	print "no opposites found";
		else if ($colstyle == "division2" and $showwhich == "changes")
        	print "no differences found";
        else if ($mptabattr["listtype"] == "search")
			print "no members found";
		else
			print "No results found";
		print "</td></tr>\n";
	}

    $bnofavour = True;
    $nrows = 0;
    $rows = array();
    $prevpartytype = "";
    while ($row = $db->fetch_row_assoc())
    {
        $party = $row["party"];
        if (!$prevpartytype or ($party != $prevpartytype["party"]))
        {
            $prevpartytype = array("type"=> "party", "party"=>$party, "favour"=>0, "against"=>0, "absent"=>0);
            $rows[] = $prevpartytype;
            $iprevpartytype = count($rows) - 1;
        }
        $rows[] = $row;
        $vote = $row["vote"];
        if ($vote == "aye")
            $dvote = "favour";
        else if ($vote == "no")
            $dvote = "against";
        else
            $dvote = "absent";
        $rows[$iprevpartytype][$dvote] += 1;
    }
    #$rows = $db->fetch_rows_assoc();
    $ncols = 11;
    $drows = (int)(count($rows) / $ncols);
    for ($ci = 0; $ci < $drows; $ci++)
    #foreach ($rows as $row)
    #while ($row = $db->fetch_row_assoc())
    {
        print "<tr>";
        for ($cc = 0; $cc < $ncols; $cc++)
        {
            $i = $cc  * $drows + $ci;
            if ($i > count($rows))
                break;
            
            $row = $rows[$i];
            if ($row["type"] == "party")
            {
                print "<td class=\"".$row["party"]." partytype\">".$row["party"].":&nbsp;+".$row["favour"]."&nbsp;-".$row["against"]."&nbsp;(".$row["absent"].")</td>\n";
                continue;
            }
            $mpname = $row['first_name']." ".$row['last_name'];
            $href = "mp.php?" . link_to_mp($row);
            if (strlen($mpname) > 22)
                $mpname = $row['first_name'][0]." ".$row['last_name'];
            if (strlen($mpname) > 18)
                $mpname = $row['first_name'][0]." ".substr($row['last_name'], 0, 14)."-";
            
            $vote = $row["vote"];
            if ($vote == "aye" or $vote == "tellaye")
                $dvote = ($bnofavour ? "against" : "favour");
            else if ($vote == "no" or $vote == "tellno")
                $dvote = ($bnofavour ? "favour" : "against");
            else if ($vote == "both")
                $dvote = "both";
            else
                $dvote = "absent";
            if ($vote == "tellaye" or $vote == "tellno")
                $dvote .= " teller";
            $cla = $dvote." ".$row["party"];
            if (($ci == 0) or ($rows[$i - 1]["party"] != $row["party"]))
                $cla .= " topborder";
            if ($ci == $drows - 1)
                $cla .= " bottomborder";
            if ($cc == $ncols - 1)
                $cla .= " rightborder";

            $toolt = $row['first_name']." ".$row['last_name']." (".$row['constituency'].")";
            if ($row['ministerial'])
            {
                $cla .= " ".($row['ministerial'] == "PPS" ? "PPS" : "minister");
                $toolt .= ", ".$row['ministerial'];
            }
            else
                $toolt .= ", ".$row["party"];
            $toolt .= " : $vote";
            #if ($ci < 4)
            #    print "<td class=\"spp\">&nbsp;</td>";
            #else
            #    print "<td class=\"spp\"><div></div></td>";
            print "<td class=\"$cla\"><a href=\"$href\" title=\"$toolt\">$mpname</a></td>";
            #print_mp_row($nrows, $row, $mpname, $href, $colstyle, $showwhich, $friendlk, $columnforms);
        }
        print "</tr>\n";
    }


    # return value
    # find the number of voters which are the same
    if ($mptabattr["listtype"] == 'mpdistance' and $mptabattr["limit"])
    {
        $query = "SELECT pw_mp.mp_id as mpid".$aquery["qfrom"].$aquery["qjoin"].$aquery["qwhere"]." AND distance_a = 0";
        if ($bdebug == 1)
            print "\n<h3>$query</h3>\n";
        $db->query($query);
        $same_voters = $db->rows();
        if ($same_voters >= $mptabattr["limit"])
            return $same_voters;
    }
}
?>
