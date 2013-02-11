<?php

# $Id: tablemake.inc,v 1.99 2010/03/12 12:26:46 publicwhip Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.



# this assigns an mp here and returns the MP's party
function divmpconds(&$aquery, &$placeholders, $voter, $bonlyvotes, $bperson, $i)
{
    global $bdebug;

    # build the selection
    $aquery["qselect"] .= ", pwvote$i.vote as vote$i";

    # searching against a person, not just an mpid
    if ($bperson)
    {
        $aquery["qjoin"]   .= "	LEFT JOIN pw_vote as pwvote$i ON
                                    pwvote$i.division_id = pw_division.division_id";
        $aquery["qjoin"]   .= " LEFT JOIN pw_mp as pwmp$i ON
                                    pwvote$i.mp_id = pwmp$i.mp_id";
        $aquery["qwhere"]  .= " AND pwmp$i.person = :pwh_pwmp".$i."_person";
        $placeholders[':pwh_pwmp'.$i.'_person']=$voter["mpprop"]['person'];

        # get the fields for this particular person time range
        $datecond = "";
        foreach ($voter['mpprops'] as $mpprop)
        {
            if ($datecond != "") {
                $datecond .= " OR ";
            }
            $datecond .= ' (pw_division.division_date >= :pwh_pwdiv'.$i.'_entered AND pw_division.division_date < :pwh_pwdiv'.$i.'_left '.
                                ' AND pw_division.house = :pwh_pwdiv'.$i.'_house)';
            $placeholders[':pwh_pwdiv'.$i.'_entered']=$mpprop['enteredhouse'];
            $placeholders[':pwh_pwdiv'.$i.'_left']=$mpprop['lefthouse'];
            $placeholders[':pwh_pwdiv'.$i.'_house']=$mpprop['house'];
        }
        if ($datecond != "") {
            $aquery["qwhere"] .= " AND ($datecond)";
        }
        $aquery["qwhere"] .= " AND pwmp$i.person = :pwh_pwmp".$i."_person";
    }

    # searching against an mp
    else
    {
        $aquery["qjoin"]   .= " LEFT JOIN pw_vote as pwvote$i ON
                                    pwvote$i.division_id = pw_division.division_id
                                    AND pwvote$i.mp_id = :pwh_pwvote".$i."_mpid";
        $placeholders[':pwh_pwvote'.$i.'_mpid']=$voter['mpid'];
        # limit down the time range if not a full-join
        $datecond .= ' (pw_division.division_date >= :pwh_pwdiv'.$i.'_entered AND pw_division.division_date < :pwh_pwdiv'.$i.'_left '.
            ' AND pw_division.house = :pwh_pwdiv'.$i.'_house)';
        $placeholders[':pwh_pwdiv'.$i.'_entered']=$voter['enteredhouse'];
        $placeholders[':pwh_pwdiv'.$i.'_left']=$voter['lefthouse'];
        $placeholders[':pwh_pwdiv'.$i.'_house']=$voter['house'];
        $aquery["qwhere"] .= " AND $datecond";

        $aquery["name$i"] = $voter["name"];
        $aquery["party$i"] = $voter["party"];
    }

    if ($bonlyvotes) {
        $aquery["qwhere"] .= " AND pwvote$i.vote IS NOT NULL";
    }
    $aquery["vote$i"] = "pwvote$i.vote";  # used because whipping has a special column
}

# this joins a dreammp here
function divdreammpconds(&$aquery, &$placeholders, $dreammpid, $bonlyvotes, $i)
{
    # build the selection.  There is no division_id in the dreamvote table
    $aquery["qselect"] .= ", pwvote$i.vote as vote$i";
    $aquery["qjoin"]   .= " LEFT JOIN pw_dyn_dreamvote as pwvote$i ON
                                pwvote$i.dream_id = :pwh_ddmpc_".$i."_dreamid
                                 AND pwvote$i.division_date = pw_division.division_date
                                 AND pwvote$i.division_number = pw_division.division_number";
    $placeholders[':pwh_ddmpc_'.$i.'_dreamid']=$dreammpid;
    # limit down the time range if not a full-join
    if ($bonlyvotes)
    {
        if ($i == 2) # don't show when policy abstains
            $aquery["qjoin"] .= " AND pwvote$i.vote <> 'both'";
        $aquery["qwhere"] .= " AND pwvote$i.vote IS NOT NULL";
    }

    $aquery["vote$i"] = "pwvote$i.vote";  # used because whipping has a special column
}

# this joins a party vote here
function divpartyconds(&$aquery, &$placeholders, $party, $i)
{
    # parties always vote everywhere, so safe to join to one
    $aquery["qselect"] .= ", pwvote$i.whip_guess as vote$i";
    $aquery["qjoin"]   .= " LEFT JOIN pw_cache_whip as pwvote$i ON
                                pwvote$i.division_id = pw_division.division_id
                                AND pwvote$i.party = :pwh_divpartyconds_".$i."_party";
    $placeholders[':pwh_divpartyconds_'.$i.'_party']=$party;
    $aquery["vote$i"] = "pwvote$i.whip_guess";  # used because whipping has a special column
}

# this joins a party vote here
function divaggregateconds(&$aquery, &$placeholders, $dreamid, $baggnames, $i)
{
    # parties always vote everywhere, so safe to join to one
    #vote enum("aye", "no", "both", "aye3", "no3") not null,
    $aquery["qselect"] .= ", MAX(pw_dyn_dreamvote_agg.vote) AS vote$i";
    $aquery["qselect"] .= ", MAX(CASE pw_dyn_dreamvote_agg.vote WHEN 'aye' THEN 1 WHEN 'aye3' THEN 3 ELSE 0 END) AS vote2aye";
    $aquery["qselect"] .= ", MAX(CASE pw_dyn_dreamvote_agg.vote WHEN 'no' THEN 1 WHEN 'no3' THEN 3 ELSE 0 END) AS vote2no";
    $aquery["qselect"] .= ", MAX(CASE pw_dyn_dreamvote_agg.vote WHEN 'both' THEN 1 ELSE 0 END) AS vote2abstain";

    $aquery["qjoin"]   .= " LEFT JOIN pw_dyn_aggregate_dreammp, pw_dyn_dreamvote AS pw_dyn_dreamvote_agg
								ON pw_dyn_aggregate_dreammp.dream_id_sel = pw_dyn_dreamvote_agg.dream_id
								AND pw_dyn_aggregate_dreammp.dream_id_agg = :pwh_divaggregateconds_".$i."_dreamid";
								#AND pw_dyn_dreamvote_agg.division_id = pw_division.division_id";i
    $placeholders[':pwh_divaggregateconds_'.$i.'_dreamid']=$dreamid;
    $aquery["qjoin"]    .=   "  AND pw_dyn_dreamvote_agg.division_date = pw_division.division_date
                                AND pw_dyn_dreamvote_agg.division_number = pw_division.division_number"; # AND HOUSE!!!

	// apply a list of names as well.  (will be more involved to make these hyperlinks, probably by concatting ids and using a php mapping)
	if ($baggnames)
	{
		$aquery["qjoin"]   .= " LEFT JOIN pw_dyn_dreammp AS pw_dyn_dreammp_agg
									ON pw_dyn_dreammp_agg.dream_id = pw_dyn_dreamvote_agg.dream_id";
	    #$aquery["qselect"] .= ", GROUP_CONCAT(DISTINCT pw_dyn_dreammp_agg.name
		#									  ORDER BY pw_dyn_dreammp_agg.name DESC SEPARATOR ', ') AS vote2names";
        $aquery["qselect"] .= ", MAX(pw_dyn_dreammp_agg.name) AS vote2names"; // we lack the above function here
    }

	$aquery["qgroup"] = " GROUP BY pw_division.division_id";  # this is all designed to capture aggregate votes that go both ways
    $aquery["vote$i"] = "pw_dyn_dreamvote_agg.vote";
}



# the votes
function workrolevote($votertype, &$vote, $row)
{
    if ($votertype == "mp" or $votertype == "person")
    {
        if ($vote == "tellaye")
            return "aye";
        if ($vote == "tellno")
            return "no";
        if ($vote == "both")
            return "";
        if ($vote == "")
        {
            $vote = "absent";
            return "";
        }
    }
    else if ($votertype == "dreammp")
	{
		if ($vote == "both")
        {
            $vote = "abstain";
            return "";
        }
        if ($vote == "aye3")
        {
            $vote = "aye3";
            return "aye";
        }
        if ($vote == "no3")
        {
            $vote = "no3";
            return "no";
        }
    }
    else if ($votertype == "party")
    {
        if ($vote == "unknown" || $vote == "none")
            return "";
    }
    else if ($votertype == "aggregate")
	{
	    //max(CASE pw_dyn_dreamvote_agg.vote WHEN 'aye' THEN 1 WHEN 'aye3' THEN 3 ELSE 0) AS vote2aye
    	//max(CASE pw_dyn_dreamvote_agg.vote WHEN 'no' THEN 1 WHEN 'no3' THEN 3 ELSE 0) AS vote2no
		if (($row["vote2aye"] != 0) && ($row["vote2no"] != 0))
		{
			$vote = "clash";
			return "";
		}
		if ($row["vote2aye"] != 0)
        {
        	$vote = ($row["vote2aye"] == 3 ? "aye3" : "aye");
            return "aye";
        }
		if ($row["vote2no"] != 0)
        {
        	$vote = ($row["vote2no"] == 3 ? "no3" : "no");
            return "no";
        }
		$vote = ($row["vote2abstain"] != 0 ? "abstain" : "");
		return "";
    }
    return $vote;
}

# this makes a comment on the row used to highlight rebels
function workrolecolumn(&$roleclass, &$votedesc, &$votedesclong, $voter1type, &$vote1, $voter2type, &$vote2, $showwhich, &$dismetric, $row)
{
    $votedesc = "";
    $votedesclong = "";
	$dismetric["total"] += 1;

    # no comparison vote
    $dtvote1 = workrolevote($voter1type, $vote1, $row);
    if ($voter2type == "")
        return "<td></td>";

    $vote2line3 = ($vote2 == "aye3" or $vote2 == "no3");
    $dtvote2 = workrolevote($voter2type, $vote2, $row);

    # mp to party terminology
    if ($voter1type == "mp" && $voter2type == "party")
    {
        if ($vote1 == "absent")
        {
            $votedesc = "absent";
            $dismetric["ab1"] += 1;
        }
        elseif ($vote2 == "unknown" || $vote2 == "none") {
            $votedesc = ($vote2 == "none" ? "Free" : "Unknown");
            $dismetric["ab2"] += 1;
        }
        elseif ($dtvote1 == $dtvote2)
            $dismetric["agree"] += 1;
        else
        {
            $roleclass = "rebel";
            $votedesc = "Rebel";
            $dismetric["disagree"] += 1;
        }

        if ($vote1 == "tellaye" || $vote1 == "tellno")
        {
            $roleclass .= "teller";
            $votedesc .= " Teller";
        }
        if ($votedesc == "") {
            $votedesc = "Loyal";
        }
    }

    # other cross comparisons
    # (borrows css colour coding, but should have its own)
    else if ($voter2type == "aggregate")
    {
        if ($vote2 == "clash")
        {
        	$roleclass = "rebel"; # red
			$dismetric["clashes"] += 1; 
		}
        else if ($dtvote1 != $dtvote2)
        {
        	$roleclass = "rebelteller"; # yellow
			$dismetric["updates"] += 1;
		}
	}

    else
    {
        # abstention by dreammp
        if ($dtvote2 == "" or $dtvote2 == "abstain")
        {
            $roleclass = "rebelteller"; # yellow
            $votedesc = "none";
            $dismetric["ab2"] += 1;
            $votedesclong = "Policy abstained";
        }

        # differences
        elseif ($dtvote1 != $dtvote2)
        {
            if ($dtvote1 == "" or $dtvote1 == "abstain")
            {
                $roleclass = "rebelteller"; # yellow
                $votedesc = "absent";
                if ($dtvote2 == "" or $dtvote2 == "abstain")
                    $dismetric["abboth"] += 1;
                else
                    $dismetric[($vote2line3 ? "ab1line3" : "ab1")] += 1;
                $votedesclong = "MP absent";
            }
            else
            {
                $roleclass = "rebel";
                $votedesc = "disagrees with policy";
                $dismetric[($vote2line3 ? "disagree3" : "disagree")]++;
                $votedesclong = "MP opposed Policy ";
            }
        }

        # same
        else
        {
            $roleclass = "teller";  # green
            $votedesc = "agrees with policy";
            $dismetric[($vote2line3 ? "agree3" : "agree")] += 1;
            $votedesclong = "MP supported Policy";
        }
    }

    return "<td class=\"$roleclass\">$votedesc</td>";
}



function print_column_headings($vote1, $vote2, $columnforms, $party)
{
	print "<tr class=\"headings\">";

    if ($columnforms["hitcounter"])
        print "<td>Hits</td>";
	if ($columnforms["house"])
		print "<td>House</td>";
	if ($columnforms["divisionnumber"])
		print "<td>No.</td>";
	if ($columnforms["divisiondate"])
		print "<td>Date</td>";
    if ($columnforms["divisiontime"])
        print "<td>Time</td>";
	if ($columnforms["divisiontitle"])
		print "<td>Subject</td>";

// some of these are going to require links put into them (sorting, or going to a particular person)

//function writelinkheading($desc, $link)  print $link ? "<td><a href=\"$link\">$desc</a></td>" : "<td>$desc</td>";
//            writelinkheading($voter1["name"], $divtabattr["voter1link"]);
//            writelinkheading($voter2["mpprop"]["name"], $divtabattr["voter2link"]);

	if ($columnforms["voter1type"] == "party")
		print "<td>$vote1 Vote</td>";
	if ($columnforms["voter1type"] == "dreammp")
	{
		if ($columnforms["isdreammp"])
			print "<td>Dream Vote</td>";
		else
			print "<td class=\"policyvotehead\">Policy vote</td>";
	}
	if ($columnforms["voter1type"] == "mp")
		print "<td>".$vote1['name']."</td>";
	if ($columnforms["voter2type"] == "party")
		print "<td>$vote2 Vote</td>";
	if ($columnforms["voter2type"] == "dreammp")
		print "<td class=\"policyvotehead\">Policy vote</td>";
	if ($columnforms["voter2type"] == "person")
		print "<td>".$vote2['mpprop']['name']."</td>";
	if ($columnforms["aggregate_vote"])
		print "<td>Policies Vote</td>";
	if ($columnforms["aggregate_names"])
		print "<td>Policies</td>";

	if ($columnforms["role"]) {
        print "<td>".$columnforms["role"]."</td>";
    }

    if ($columnforms["similarity"])
        print "<td>Similarity</td>";
	if ($columnforms["voteoverlap"])
       print "<td>Overlap</td>";
	if ($columnforms["rebellions"])
        print "<td>Rebels<br>(<a href=\"/faq.php#clarify\">explain..</a>)</td>";
	if ($columnforms["turnout"])
		print "<td>Turnout</td>\n";
    if ($columnforms["majority"])
        print "<td>Majority</td>";
    
    if ($columnforms["party_agreement"])
        print "<td>$party Policy Agreement</td>";
    if ($columnforms["party_turnout"])
        print "<td>$party Turnout</td>";
    if ($columnforms["loyal"])
    {
        if ($party == "XB")
            print "<td>Ayes</td><td>Noes</td>";
        else
            print "<td>Loyal</td><td>Rebels</td>";
    }
    
    if ($columnforms["ayes"] and $columnforms["noes"])
        print "<td>$party with Majority</td> <td>$party with minority</td>";
    else
    {
        if ($columnforms["ayes"])
            print "<td>$party Ayes</td>";
        if ($columnforms["noes"])
            print "<td>$party Noes</td>";
    }
    if ($columnforms["boths"])
        print "<td>Boths</td>";
    if ($columnforms["whip_guess"])
        print "<td>Whip Guess</td>";

    if ($columnforms["speeches"])
        print "<td>Debate</td>";

	print "</tr>\n";
}


// prints one row of the table according to format in $columnforms
// this makes it easier to generating the heading and shuffle the columns
function print_division_row($nrows, $pretrowclass, $rolecol, $roleclass, $vote1, $vote2, $row, $divhref, $divhrefcloseappend, $hrefsource, $columnforms)
{
    print "<tr class=\"".(($nrows % 2 == 1) ? "odd" : "even")."$pretrowclass\">";

    if ($columnforms["hitcounter"])
        print "<td>".$row["hits"]."</td>";
	if ($columnforms["house"]) {
        $house_name = "Commons";
        if( $row['divisionhouse'] == "lords" )
            $house_name = "Lords";
        if( $row['divisionhouse'] == "scotland" )
            $house_name = "Scotland";
	    print "<td class=\"".$row['divisionhouse']."\">".$house_name."</td>";
    }
    if ($columnforms["divisionnumber"])
        print "<td>".$row['divisionnumber']."</td>";
	if ($columnforms["divisiondate"])
	    print "<td>".pretty_date($row['divisiondate'])."</td>";
    if ($columnforms["divisiontime"])
        print "<td>".substr($row['divisiontime'], 1, 5)."</td>";

	if ($columnforms["divisiontitle"])
	{
	    $divdesc_edited = extract_title_from_wiki_text($row['text_body']);
	    $divdesc = ($divdesc_edited ? $divdesc_edited : $row['division_name']);
	    print "<td>";
	    if ($divhref)
			print "<a href=\"$divhref\">";
		print "$divdesc";
	    if ($columnforms["divisiontitle"] == "listunedited" and !$row['motionedited'])
	        print " <i>(unedited)</i>";
	    if ($divhref)
		    print "</a>";
	    print "</td>\n";
	}

    if ($columnforms["voter1type"])
    {
	    if ($columnforms["voter2type"] == "dreammp")
		    print "<td class=\"$roleclass\">";
        else
            print "<td>";
        if ($columnforms["voter1type"] == "dreammp" && !$vote1)
            print "non-voter";
        else if ($columnforms["voter1type"] == "dreammp") 
            print vote_display_in_table($vote1, $row["aye_majority"]);
        else
            print vote_display_in_table($vote1, $row["aye_majority"]);
        print "</td>";
    }
    if ($columnforms["voter2type"])
    {
	    if ($columnforms["aggregate_vote"])
		    print "<td class=\"$roleclass\">";
        else
            print "<td>";
        #print vote_display_in_table($vote2, 0/*$row["aye_majority"]*/)."</td>\n";
        print vote_display_in_table($vote2, ($columnforms["voter2type"] != "dreammp" ? 0 : $row["aye_majority"]))."</td>\n";
    }
	if ($columnforms["aggregate_names"])
		print "<td>".$row["vote2names"]."</td>";

    if ($columnforms["role"])
		print $rolecol;

    if ($columnforms["similarity"])
    {
    	$similarity = (1.0 - (float)$row['divdistance']) * 100.0;
        print "<td>".number_format($similarity, 0)."%";
        if ($divhrefcloseappend != "SAMEDIVISION")
			print "<br>(<a href=\"$divhref$divhrefcloseappend\"><b>details...</b></a>)";
        print "</td>";
	}
	if ($columnforms["voteoverlap"])
       print "<td>".$row['voteoverlap']."</td>";

	if ($columnforms["rebellions"])
        print "<td>".$row['rebellions']."</td>";
	if ($columnforms["turnout"])
		print "<td>".$row['turnout']."</td>\n";
    if ($columnforms["majority"])
        print "<td>".abs($row['aye_majority'])."</td>";

    $turnout = $row['ayes'] + $row['noes'] + $row['boths'];
    if ($columnforms["party_agreement"])
    {
        if ($vote1 == "aye" || $vote1 == "aye3")
            print "<td>".percentise_votes_short($row['ayes'], $turnout)."</td>";
        else if ($vote1 == "no" || $vote1 == "no3")
            print "<td>".percentise_votes_short($row['noes'], $turnout)."</td>";
        else 
            print "<td> n / a </td>";
    }
    if ($columnforms["party_turnout"])
    {
        $turnout = $row['ayes'] + $row['noes'] + $row['boths'];
        print "<td>".percentise_votes_short($turnout, $row['possible_votes'])."</td>";
    }
    if ($columnforms["loyal"])
    {
        if ($row["whip_guess"] == "no")
            print "<td>".$row['noes']."</td>"."<td>".$row['ayes']."</td>";
        else
            print "<td>".$row['ayes']."</td>"."<td>".$row['noes']."</td>";
    }
    if ($columnforms["ayes"] and $columnforms["noes"])
    {
        if ($row['aye_majority'] >= 0)
            print "<td>".$row['ayes']."</td> <td>".$row['noes']."</td>";
        else
            print "<td>".$row['noes']."</td> <td>".$row['ayes']."</td>";
    }
    else
    {
        if ($columnforms["ayes"])
            print "<td>".$row['ayes']."</td>";
        if ($columnforms["noes"])
            print "<td>".$row['noes']."</td>";
    }
    if ($columnforms["boths"])
        print "<td>".$row['boths']."</td>";
    if ($columnforms["whip_guess"])
        print "<td>".$row['whip_guess']."</td>";

    if ($columnforms["speeches"])
        print "<td><a href=\"$hrefsource\">speeches</a></td>";

    print "</tr>\n";
}

function GetPartyVoteSummaryH($db, $div_id)
{
    global $pwpdo;
    $query = "SELECT pw_mp.party, COUNT(*) AS counter, vote, whip_guess
              FROM pw_vote, pw_mp, pw_cache_whip
              WHERE pw_vote.division_id = ?
                AND pw_vote.mp_id = pw_mp.mp_id
                AND pw_cache_whip.division_id = pw_vote.division_id
                AND pw_cache_whip.party = pw_mp.party
              GROUP BY pw_mp.party, vote
              ORDER BY party, vote";
    $pwpdo->query($query,array($div_id));

    # Precalc values
    $ayes = array();
    $noes = array();
    $boths = array();
    $tellayes = array();
    $tellnoes = array();
    $whips = array();
    $totalpartyvote = array();

    while ($row = $pwpdo->fetch_row())
    {
        $party = $row['party'];
        $count = $row['counter'];
        $vote = $row['vote'];
        $whip = $row['whip_guess'];

        $totalpartyvote[$party] += $count;

        if ($vote == "aye")
            $ayes[$party] += $count;
        else if ($vote == "no")
            $noes[$party] += $count;
        else if ($vote == "both")
            $boths[$party] += $count;
        else if ($vote == "tellaye")
            $tellayes[$party] += $count;
        else if ($vote == "tellno")
            $tellnoes[$party] += $count;
        else
            print "Unknown vote type: " + $vote;
        $whips[$party] = $whip;
    }
    $votes = array_sum(array_values($ayes)) +
                array_sum(array_values($noes)) +
                array_sum(array_values($boths)) +
                array_sum(array_values($tellayes)) +
                array_sum(array_values($tellnoes));

    $partysummary = array('ayes' => $ayes,
                          'noes' => $noes,
                          'boths' => $boths,
                          'tellayes' => $tellayes,
                          'tellnoes' => $tellnoes,
                          'whips' => $whips,
                          'votes' => $votes,
                          'totalpartyvote' => $totalpartyvote);
    return $partysummary;
}


function writepersonvote($lnrows, $cla, $name, $vote, $ayecla, $nocla)
{
    print "<tr class=\"".($lnrows != -1 ? (($lnrows % 2 == 1) ? "odd" : "even") : "")."$cla\">";
    print "<td>$name</td>";
    if (($vote == "aye") || ($vote == "AYE"))
        print "<td$ayecla>Aye</td><td$nocla></td>";
    else if (($vote == "aye3") || ($vote == "AYE3"))
        print "<td$ayecla>Aye (strong)</td><td$nocla></td>";
    else if (($vote == "no") || ($vote == "NO"))
        print "<td$ayecla></td><td$nocla>No</td>";
    else if (($vote == "no3") || ($vote == "NO3"))
        print "<td$ayecla></td><td$nocla>No (strong)</td>";
    else
        print "<td colspan=2 align=center>$vote</td>";
    print "</tr>\n";
}
function vote_display_in_table($vote, $aye_majority) 
{
    if ($aye_majority && ($vote == "aye" || $vote == "aye3" || $vote == "no" || $vote == "no3"))
    {
        if (($aye_majority >= 0) == ($vote == "aye" || $vote == "aye3"))
            $res = "Majority";
        else
            $res = "<i>minority</i>";
        if ($vote == "aye3" || $vote == "no3")
            $res .= " (strong)";

        #if ($vote == "aye3" or $vote == "aye")
        #    $res .= " <sup>aye</sup>";
        #if ($vote == "no3" or $vote == "no")
        #    $res .= " <sup>no</sup>";
        return $res;
    }

    if ($vote == "aye3")
        return "aye (strong)";
    if ($vote == 'no3')
        return "no (strong)";
	if ($vote == '')
		return "non-voter";
    return $vote;
}
function writenumbervote(&$lnrows, $gname, $sayes, $snoes, $ayecla, $nocla)
{
    if ($sayes == "")
        $sayes = 0;
    if ($snoes == "")
        $snoes = 0;
    print "<tr class=\"".(($lnrows % 2 == 1) ? "odd" : "even")."\">";
    print "<td>$gname</td><td$ayecla>$sayes</td><td$nocla>$snoes</td></tr>\n";
    $lnrows += 1;
}
function print_motion_row($motiontext, $db, $divisionid, $pretrowclass, $rolecol, $roleclass, $votedesc, $votedesclong, $voter1, $vote1, $voter2attr, $vote2, $row, $divhref, $hrefsource)
{
    # title part of the expanded motion text
    print "<tr class=\"motiontitle$pretrowclass\">";

    $divlink = "<a href=\"$divhref\">";
    $divdesc_edited = extract_title_from_wiki_text($row['text_body']);
    $divdesc = $divdesc_edited ? $divdesc_edited : $row['division_name'];
    print "<td colspan=7 align=left>$divlink$divdesc - " .
	    date("j M Y", strtotime($row["divisiondate"])) .
	" - Division No. " . $row['divisionnumber'] . "</a> </td>";
    print "</tr>\n";

    print "<tr valign=\"top\">";
    print "<td>";

    # Coloured box saying whether MP and Dream MP agree/disgagree/miss
    # null means we are dealing with a dreammp
    print "<table class=\"policyvotehead\" style=\"background-color:#eeeeee\">";
    if ($voter2attr)
        writepersonvote(-1, "", "Policy '" . html_scrub($voter2attr['name']) . "'", $vote2, "", "");
    else
        writepersonvote(-1, "", "Policy '" . html_scrub($voter1) . "'", $vote1, "", ""); 
    print "</table>";

    # make the table of party in the left hand side
    print "<table class=\"votetab\">";
    //print "<tr class=\"headings\"><td></td><td>Aye</td><td>No</td></tr>\n";

    $lnrows = 0;

    # get the summary of the rest of the voting from the database
    $partysummary = GetPartyVoteSummaryH($db, $divisionid);

    # total up votes
    $totalayes = array_sum(array_values($partysummary['ayes'])) + array_sum(array_values($partysummary['tellayes']));
    $totalnoes = array_sum(array_values($partysummary['noes'])) + array_sum(array_values($partysummary['tellnoes']));

    # MP's vote
    $ayecla = ($totalayes > $totalnoes ? " class=\"majority\"" : "");
    $nocla = ($totalnoes > $totalayes ? " class=\"majority\"" : "");
    if ($voter2attr) {
        writepersonvote(0, $roleclass, $voter1['name'], $vote1, $ayecla, $nocla);
    }
    //writepersonvote($lnrows, "strong", $voter1['name'], $vote1, $ayecla, $nocla);

    if (false===isset($voter1['party'])) {
        $party='';
    } else {
    # votes of rest of parties (a rather poor way to put it together)
    $party = $voter1['party'];
    }
    $partys = array();
    if ($voter2attr) {
        array_push($partys, $party);
    }
    if ($party != "Lab") {
        array_push($partys, "Lab");
    }
    if ($party != "Con") {
        array_push($partys, "Con");
    }
    if ($party != "LDem") {
        array_push($partys, "LDem");
    }
    foreach ($partys as $lparty)
        writenumbervote($lnrows, $lparty, $partysummary['ayes'][$lparty], $partysummary['noes'][$lparty], $ayecla, $nocla);
    writenumbervote($lnrows, "Total", $totalayes, $totalnoes, $ayecla, $nocla);

    print "</table></td>";

    # motion part of the text
    print "<td colspan=4>$motiontext</td>\n";

    print "</tr>\n";
}


function writeevents(&$events, $date, $breversed)
{
    while ($events && (!$date or ($breversed == ($date >= $events[count($events) - 1][0])))){
        $event = array_pop($events);
        if ($event[2] != "Ignoreevent")
        {
            print "<tr class=\"jobevent\"><td>".pretty_date($event[0])."</td>";
            print "<td colspan=\"5\" align=center>".$event[4]."</td><td colspan=1></td></tr>\n";
        }
    }
}




# Table that shows a selected heap of divisions, and provides a comparison between
# one or two independent voting actors.
#
# votertype is 'dreammp', 'mp', 'party', 'aggregate'
# voter is a mpid, dreammpid, blank-for-self party,
# divclose is divattr, or null
# showwhich is 'everyvote', 'rebellions10', 'party', 'search', 'all1',
#    'all2', 'either', 'both', 'bothdiff' (tellers appear automatically)
#    if showwhich is 'party' then party records which one
#    (then we need a signal for order and for expanded display, and for events)
#    if 'search' then search is the search string
# votedisplay is none, 'fullmotion'(for showing the jmp view)
# headings is 'none', 'columns', 'fulldesc'(for changing mps)
# sortby is 'date', 'subject', 'rebellions', 'turnout', 'closeness'
# parldatelimit is null or a line from $parliaments
# motionwikistate is nothing or 'listunedited' for the "(unedited)" symbols
# display_house is nothing/'both', or 'commons', or 'lords'
#
function division_table($db, $divtabattr, $db2="", $events = "")
{
    update_divisions_wiki_id($db);

    global $bdebug;
    global $pwpdo;
    $placeholders=array();
    # extract attibutes
    $showwhich = $divtabattr["showwhich"];
    $voter1type = $divtabattr["voter1type"];
    $voter1 = $divtabattr["voter1"];
    $voter2type = $divtabattr["voter2type"];
    $voter2 = $divtabattr["voter2"];
    $voter2attr = $divtabattr["voter2attr"];
    $headings = $divtabattr["headings"];


    # the list list and forms of the columns we are going to output
	$columnforms = array();
    $columnforms["divisiondate"] = "yes";
    if ($divtabattr["hitcounter"])  {
        $columnforms["hitcounter"] = "yes";
    }
    # the underlying division list
    $aquery = array();
    $aquery["qselect"] = " SELECT
                            pw_division.division_number AS divisionnumber,
                            pw_division.division_date 	AS divisiondate,
                            pw_division.clock_time      AS divisiontime,
                            pw_division.house           AS divisionhouse,
                            division_name, source_url, debate_url, pw_division.source_gid AS source_gid, debate_gid, aye_majority";
    $aquery["qfrom"]   = " FROM pw_division";
    $aquery["qjoin"]   = " LEFT JOIN pw_cache_divinfo ON pw_cache_divinfo.division_id = pw_division.division_id";

    # where clause with limitation for one parliament, or dummy condition
    $aquery["qwhere"]  = " WHERE 1=1";
    if ($divtabattr["parldatelimit"]) {
        $aquery["qwhere"] .= " AND (pw_division.division_date >= :pwd_parldatefrom AND pw_division.division_date < :pwd_parldatelimit)";
        $placeholders[':pwd_parldatefrom']=$divtabattr["parldatelimit"]['from'];
        $placeholders[':pwd_parldatelimit']=$divtabattr["parldatelimit"]['to'];
    }
	if (($divtabattr["display_house"] == "lords") or ($divtabattr["display_house"] == "commons") or ($divtabattr["display_house"] == "scotland")) {
		$aquery["qwhere"] .= " AND pw_division.house = :pwd_display_house";
        $placeholders[':pwd_display_house']=$divtabattr["display_house"];
    } else if ($divtabattr["display_house"] == "z") {
		$aquery["qwhere"] .= " AND pw_division.house = \"commons\" AND pw_division.division_date >= \"2009-06\"";
} else {
		$columnforms["house"] = "yes";  # a mixed list needs to state the house
    }
    # accumulate the ordering command
    $aquery["qorder"]  = " ORDER BY";
    $sortby = $divtabattr["sortby"];

	$divclose = $divtabattr["divclose"];
	if ($divclose)
	{
		$aquery["qselect"] .= ", pw_cache_divdiv_distance.distance AS divdistance
				       , (pw_cache_divdiv_distance.nvotessame+pw_cache_divdiv_distance.nvotesdiff) AS voteoverlap";
		$aquery["qjoin"] .= " LEFT JOIN pw_cache_divdiv_distance
								ON pw_cache_divdiv_distance.division_id = :pwd_divdiv_distance_divid
								AND pw_cache_divdiv_distance.division_id2 = pw_division.division_id";
        $placeholders[':pwd_divdiv_distance_divid']=$divclose['division_id'];
		$aquery["qwhere"] .= " AND pw_cache_divdiv_distance.distance IS NOT null";

		$columnforms['similarity'] = "yes";
		$columnforms['voteoverlap'] = "yes";
	}


    $breversed = ($sortby == "datereversed");
    if ($sortby == "subject")
        $aquery["qorder"] .= " division_name, ";
    if ($sortby == "rebellions")
    {
        if ($showwhich == "party")
            $aquery["qorder"] .= " (IF(whip_guess = 'aye', no_votes + no_tells, 0) + IF(whip_guess = 'no', aye_votes + aye_tells, 0)) DESC, ";
        else
            $aquery["qorder"] .= " rebellions DESC,";
    }
    if ($sortby == "turnout")
    {
        if ($showwhich == "party")
            $aquery["qorder"] .= " (aye_votes + aye_tells + no_votes + no_tells + both_votes) DESC, ";
        else
            $aquery["qorder"] .= " turnout DESC, ";
	}
    if ($sortby == 'closeness')
		$aquery["qorder"] .= " pw_cache_divdiv_distance.distance, ";
    if ($breversed)
        $aquery["qorder"] .= " divisiondate, divisionhouse, divisionnumber";
    else # by date (for all other cases)
        $aquery["qorder"] .= " divisiondate DESC, clock_time DESC, divisionnumber DESC";

    # corrected column (yet another division_id coding!)
    # motionwikistate is nothing or 'listunedited' for the "(unedited)" symbols
    if ($divclose) {
	    $columnforms["divisiontitle"] = 'close';
    } else if ($divtabattr["motionwikistate"]) {
	    $columnforms["divisiontitle"] = 'unedited';
    } else {
	    $columnforms["divisiontitle"] = 'yes';
    }

    $aquery["qselect"] .= ", pw_dyn_wiki_motion.wiki_id AS motionedited, pw_dyn_wiki_motion.text_body AS text_body";
    $aquery["qjoin"]  .= "  LEFT JOIN pw_cache_divwiki ON pw_cache_divwiki.division_date = pw_division.division_date
                                    AND pw_cache_divwiki.division_number = pw_division.division_number AND pw_cache_divwiki.house = pw_division.house
                            LEFT JOIN pw_dyn_wiki_motion ON pw_dyn_wiki_motion.wiki_id = pw_cache_divwiki.wiki_id
                            ";

    # full motion text display
    if ($divtabattr['votedisplay'] == 'fullmotion')
        $aquery["qselect"] .= ", pw_division.division_id AS divisionid";


    $columnforms["voter1type"] = $voter1type;
    $columnforms["voter2type"] = $voter2type;
	if ($voter2type && ($voter2type != 'aggregate'))
		$columnforms["role"] = "R&ocirc;le";
    if ($voter1type == 'mp')
        $columnforms["voter1house"] = $voter1["house"];
    if ($voter2type == 'mp')
        $columnforms["voter2house"] = $voter2["house"];
	if ($voter2type == 'aggregate')
	{
		$columnforms["isdreammp"] = "yes";  // we can call the column a dream vote without the aggregate column
		$columnforms["aggregate_vote"] = ($showwhich == "either");
        $columnforms["aggregate_names"] = "yes";
	}

    # construct the first column of votes
    $bonlyvotes1 = ($showwhich == "all1" or $showwhich == "both" or $showwhich == "bothdiff" or $voter1type == "dreammp");
    if ($voter1type == "mp")
        divmpconds($aquery, $placeholders, $voter1, $bonlyvotes1, false, 1);
    if ($voter1type == "dreammp")
        divdreammpconds($aquery, $placeholders, $voter1, $bonlyvotes1, 1);

    if (!$voter1type && !$divclose)  # this case means we are listing all divisions without a driver
	{
		$aquery["qselect"] .= ", rebellions, turnout";
	    if ($divtabattr["headings"] != "frontpageshort")
        {
            $columnforms["divisiontime"] = "yes";
            if ($showwhich != "party")
    		{

                $columnforms["rebellions"] = 'yes';
	        	$columnforms["turnout"] = 'yes';
                $columnforms["majority"] = 'yes';
            }
        }
	}

    # construct the second column of votes (if it exists)
    if ($voter2type != "")
    {
        $bonlyvotes2 = ($showwhich == "all2" or $showwhich == "both" or $showwhich == "bothdiff");
        if ($voter2type == "dreammp") 
        {

            #$columnforms["voter1type"] = null;
            #$columnforms["voter2type"] = null;
            #$columnforms["role"] = "Agreement with policy above";
            $columnforms["role"] = null;
            divdreammpconds($aquery, $placeholders, $voter2, $bonlyvotes2, 2);
        } 
        else if ($voter2type == "party") 
        {
            if ($voter2 == "")
                $voter2 = $aquery["party1"];
            divpartyconds($aquery, $placeholders, $voter2, 2);
        }
        else if ($voter2type == "person")
            divmpconds($aquery, $placeholders, $voter2, $bonlyvotes2, true, 2);
		else if ($voter2type == "aggregate")
			divaggregateconds($aquery, $placeholders, $voter2, $columnforms["aggregate_names"], 2);

        # put in the selection mechanism of diffs into this
        if ($showwhich == "bothdiff")
            $aquery["qwhere"]  .= " AND ".$aquery["vote1"]." <> ".$aquery["vote2"];
        else if ($showwhich == "either")
            $aquery["qwhere"]  .= " AND (".$aquery["vote1"]." IS NOT NULL OR ".$aquery["vote2"]." IS NOT NULL)";
    }


    # apply a selection for "controversial" divisions
    if ($showwhich == "rebellions10")
        $aquery["qwhere"]  .= " AND rebellions > 10";

	# link in the party info
	if ($showwhich == "party")
	{
		$aquery["qselect"] .= ", (pw_cache_whip.aye_votes + pw_cache_whip.aye_tells) AS ayes,
								 (pw_cache_whip.no_votes + pw_cache_whip.no_tells) AS noes,
								 pw_cache_whip.both_votes AS boths,
								 pw_cache_whip.possible_votes AS possible_votes,
								 pw_cache_whip.whip_guess AS whip_guess";

		$aquery["qjoin"] .= " LEFT JOIN pw_cache_whip
								ON pw_cache_whip.division_id = pw_division.division_id AND pw_cache_whip.party = :pwd_party_whip_join";
        $placeholders[':pwd_party_whip_join']=$divtabattr['party'];
	    if ($voter1type == "dreammp")
        {
            #$columnforms["ayes"] = "yes";
            #$columnforms["noes"] = "yes"; 
            $columnforms["party_turnout"] = "yes";
            $columnforms["party_agreement"] = "yes"; 
            $columnforms["voter1type"] = null;  # kill this column
        }
        else
        {
            $columnforms["loyal"] = "yes";
	        $columnforms["rebels"] = "yes";
    	    #$columnforms["whip_guess"] = "yes";
	        $columnforms["party_turnout"] = "yes";
		    if ($divtabattr["display_house"] != "lords")
	            $columnforms["boths"] = "yes";
        }
	}

    # search
    if ($showwhich == "search") 
    {
        $aquery["qwhere"]  .= " AND (
                LOWER(convert(division_name using utf8)) LIKE :pwd_namesearch
                OR LOWER(convert(motion using utf8)) LIKE :pwd_namesearch
                OR LOWER(convert(text_body using utf8)) LIKE :pwd_namesearch
                )";
        $placeholders[':pwd_namesearch']='%'.$divtabattr['search'].'%';
    }

    # apply the limit
    if ($divtabattr["limitby"] != "") {
        $aquery["qlimit"] = " LIMIT ".(int)$divtabattr["limitby"];
    }
    if ($columnforms["hitcounter"])
    {
        $aquery["qselect"] .= ", COUNT(*)-1 AS hits"; # can't avoid the overcounting on the first
	    $aquery["qgroup"] = " GROUP BY pw_division.division_id"; # if set, it's this anyway
        $aquery["qjoin"] .= " LEFT JOIN pw_logincoming 
                              ON pw_logincoming.page = 'division'
                              AND pw_logincoming.ltime > '2009'
                              AND pw_logincoming.thing_id = pw_division.division_id";
    }
    
    # main set that grabs all the divisions and makes a coarse subsampling
    $query = $aquery["qselect"].$aquery["qfrom"].$aquery["qjoin"].$aquery["qwhere"].$aquery["qgroup"].$aquery["qorder"].$aquery["qlimit"];

    $allRows=$pwpdo->fetch_all_rows($query,$placeholders);


    # make the printing
    $prettyrow = 0;
    $nrows = 0;


    # write the headings if wanted
    if ($headings == "columns" or $headings == "fulldesc")
    {
        print_column_headings($voter1, $voter2, $columnforms, $divtabattr["party"]);

        # blank case table; must say something
        if (count($allRows)===0)
        {
            $prettyrow = pretty_row_start($prettyrow, "");
            $mess = "no votes listed";
            if ($showwhich == "bothdiff" and $voter1type == "mp" and $voter2type == "party")
                $mess = "no rebellions, never teller";
            elseif ($showwhich == "search")
                $mess = "no divisions found";
            $cspan = count($columnforms);
            print "<td colspan=$cspan>$mess</td></tr>\n";
        }
    }

    # sums for the distance metric (the second voter controls the 3-line quality
    $dismetric = array("agree"=>0, "disagree"=>0, "agree3"=>0, "disagree3"=>0,
                       "ab1"=>0, "ab1line3"=>0, "ab2"=>0, "abboth"=>0,
					   "clashes"=>0, "updates"=>0, "total"=>0);
    foreach ($allRows as $row) {
        # mark the role column and fix the terminology of the vote
        $pretrowclass = "";
        if ($voter1type != "")
        {
            $vote1 = $row['vote1'];
            $vote2 = $row['vote2'];

            # detect three line whips (in dream mps)
            if ($vote1 == "aye3" or $vote1 == "no3" or $vote2 == "aye3" or $vote2 == "no3")
                $pretrowclass = "strong";

            $roleclass = "";
            $votedesc = "";
            $votedesclong = "";
            $rolecol = workrolecolumn($roleclass, $votedesc, $votedesclong, $voter1type, $vote1, $voter2type, $vote2, $showwhich, $dismetric, $row);
            if ($rolecol == "")
                continue;      # final filter bail out
        }

        # colour red if rebellions, except cases where it's ugly or unnecessary
        else if (!$divclose && $row['rebellions'] >= 10 && $sortby != "rebellions" && $showwhich != "rebellions10" && $showwhich != "party")
            $pretrowclass = "rebel";

        $debate_gid = str_replace("uk.org.publicwhip/debate/", "", $row['debate_gid']); # this entry in the database should tell us if it is a lords type.
        if ($debate_gid != "")
            $hrefsource = "http://www.theyworkforyou.com/debates/?id=$debate_gid";
        else
            $hrefsource = $row['source_url'];

        $divhref = "division.php?date=".urlencode($row['divisiondate'])."&number=".urlencode($row['divisionnumber']);
        if ($divclose)
        {
			if (($row['divisiondate'] == $divclose['division_date']) && ($row['divisionnumber'] == $divclose['division_number']))
			{
				$divhrefcloseappend = "SAMEDIVISION";
				$divhref = "";
			}
			else
	        	$divhrefcloseappend = "&date2=".urlencode($divclose['division_date'])."&number2=".urlencode($divclose['division_number']);
        }
        if ($divhref)
		{
			$divhref .= $divtabattr["divhrefappend"];
	        if ($row["divisionhouse"] == "lords")
	            $divhref .= "&house=lords";
            elseif ($row["divisionhouse"] == "scotland")
	            $divhref .= "&house=scotland";
		}

        # write out the events
        writeevents($events, $row['divisiondate'], $breversed);
        # votedisplay is none, 'fullmotion'(for showing the jmp view)
        if ($divtabattr['votedisplay'] == 'fullmotion')
        {
            // I suspect this is using the same instance of $db and destroying the current position
            $wikiinfo = get_wiki_current_value("motion", array($row['divisiondate'], $row['divisionnumber'], $row['divisionhouse']));
            $motiontext = extract_motion_text_from_wiki_text($wikiinfo['text_body']);
			print_motion_row($motiontext, $db2, $row['divisionid'], $pretrowclass, $rolecol, $roleclass, $votedesc, $votedesclong, ($voter2attr? $voter1 : $divtabattr['voter1name']), $vote1, $voter2attr, $vote2, $row, $divhref, $hrefsource);
			$nrows += 2;
        }
        else
        {
            print_division_row($nrows, $pretrowclass, $rolecol, $roleclass, $vote1, $vote2, $row, $divhref, $divhrefcloseappend, $hrefsource, $columnforms);
            $nrows += 1;
        }
    }
    # finish the remainder of the events
    writeevents($events, "", $breversed);

    return $dismetric;
}

?>
