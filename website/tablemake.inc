<?php

# $Id: tablemake.inc,v 1.26 2005/07/15 16:25:00 frabcus Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.



# this assigns an mp here and returns the MP's party
function divmpconds(&$aquery, &$db, $voter, $bonlyvotes, $bperson, $i)
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
        $aquery["qwhere"]  .= " AND pwmp$i.person = ".$voter["mpprop"]['person'];

        # get the fields for this particular person time range
        $datecond = "";
        foreach ($voter['mpprops'] as $mpprop)
        {
            if ($datecond != "")
                $datecond .= " OR ";
            if ($bdebug == 1)
                print_r($mpprop);
            $datecond .= " (pw_division.division_date >= \"".$mpprop['enteredhouse']."\"
                                AND pw_division.division_date < \"".$mpprop['lefthouse']."\")";
        }
        if ($datecond != "")
            $aquery["qwhere"] .= " AND ($datecond)";
        $aquery["qwhere"] .= " AND pwmp$i.person = ".$voter["mpprop"]['person'];
        if ($bdebug == 1)
            print "<h1>datecond: $datecond</h1>\n";
    }

    # searching against an mp
    else
    {
        if ($bdebug == 1)
        {
            print "<h1>";
            print_r($voter);
            print "</h1>\n";
        }
        $aquery["qjoin"]   .= " LEFT JOIN pw_vote as pwvote$i ON
                                    pwvote$i.division_id = pw_division.division_id
                                    AND pwvote$i.mp_id = ".$voter['mpid'];

        # limit down the time range if not a full-join
        $datecond = " (pw_division.division_date >= \"".$voter['enteredhouse']."\"
                            AND pw_division.division_date < \"".$voter['lefthouse']."\")";
        $aquery["qwhere"] .= " AND $datecond";

        $aquery["name$i"] = $voter["name"];
        $aquery["party$i"] = $voter["party"];
    }

    if ($bonlyvotes)
        $aquery["qwhere"] .= " AND pwvote$i.vote IS NOT NULL";

    $aquery["vote$i"] = "pwvote$i.vote";  # used because whipping has a special column
}

# this joins a dreammp here
function divdreammpconds(&$aquery, &$db, $dreammpid, $bonlyvotes, $i)
{
    # build the selection.  There is no division_id in the rollievote table
    $aquery["qselect"] .= ", pwvote$i.vote as vote$i";
    $aquery["qjoin"]   .= " LEFT JOIN pw_dyn_dreamvote as pwvote$i ON
                                pwvote$i.rollie_id = $dreammpid
                                 AND pwvote$i.division_date = pw_division.division_date
                                 AND pwvote$i.division_number = pw_division.division_number";

    # limit down the time range if not a full-join
    if ($bonlyvotes)
        $aquery["qwhere"] .= " AND pwvote$i.vote IS NOT NULL";

    $aquery["vote$i"] = "pwvote$i.vote";  # used because whipping has a special column
}

# this joins a party vote here
function divpartyconds(&$aquery, &$db, $party, $i)
{
    # parties always vote everywhere, so safe to join to one
    $aquery["qselect"] .= ", pwvote$i.whip_guess as vote$i";
    $aquery["qjoin"]   .= " LEFT JOIN pw_cache_whip as pwvote$i ON
                                pwvote$i.division_id = pw_division.division_id
                                AND pwvote$i.party = \"$party\"";

    $aquery["vote$i"] = "pwvote$i.whip_guess";  # used because whipping has a special column
}




# the votes
function workrolevote($votertype, &$vote)
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
            $vote = "aye (3 line)";
            return "aye";
        }
        if ($vote == "no3")
        {
            $vote = "no (3 line)";
            return "no";
        }
    }
    else if ($votertype == "party")
    {
        if ($vote == "unknown")
            return "";
    }
    return $vote;
}

# this makes a comment on the row used to highlight rebels
function workrolecolumn(&$roleclass, &$votedesc, &$votedesclong, $voter1type, &$vote1, $voter2type, &$vote2, $showwhich, &$dismetric)
{
    $votedesc = "";
    $votedesclong = "";

    # no comparison vote
    $dtvote1 = workrolevote($voter1type, $vote1);
    if ($voter2type == "")
        return "<td></td>";

    $vote2line3 = ($vote2 == "aye3" or $vote2 == "no3");
    $dtvote2 = workrolevote($voter2type, $vote2);

    # mp to party terminology
    if ($voter1type == "mp" and $voter2type == "party")
    {
        if ($vote1 == "absent")
        {
            $votedesc = "absent";
            $dismetric["ab1"] += 1;
        }
        elseif ($vote2 == "unknown")
            $dismetric["ab2"] += 1;
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
    else
    {
	# abstention by dreammp
        if ($dtvote2 == "" or $dtvote2 == "abstain")
        {
            $roleclass = "rebelteller"; # yellow
            $votedesc = "none";
            $dismetric["ab2"] += 1;
            $votedesclong = "Dream MP abstained";
        }

        # differences
        elseif ($dtvote1 != $dtvote2)
        {
            if ($dtvote1 == "" or $dtvote1 == "abstain")
            {
                $roleclass = "rebelteller"; # yellow
                $votedesc = "none";
                if ($dtvote2 == "" or $dtvote2 == "abstain")
                    $dismetric["abboth"] += 1;
                else
                    $dismetric[($vote2line3 ? "ab1line3" : "ab1")] += 1;
                $votedesclong = "MP absent";
            }
            else
            {
                $roleclass = "rebel";
                $votedesc = "disagree";
                $dismetric[($vote2line3 ? "disagree3" : "disagree")]++;
                $votedesclong = "MP rebelled against Dream MP";
            }
        }

        # same
        else
        {
            $roleclass = "teller";  # green
            $votedesc = "agree";
            $dismetric[($vote2line3 ? "agree3" : "agree")] += 1;
            $votedesclong = "MP loyal to Dream MP";
        }
    }

    return "<td class=\"$roleclass\">$votedesc</td>";
}


function print_event($event)
{
    global $prettyrow;
    $prettyrow = pretty_row_start($prettyrow);
    print "<td>&nbsp;</td><td>&nbsp;</td>";
    print "<td>" . $event[0] . "</td>";
    print "<td colspan=7>" . $event[1] .  "</td></tr>\n";
}

function print_division_row($nrows, $pretrowclass, $rolecol, $voter1type, $voter2type, $vote1, $vote2, $row, $showmotionwikistate, $divhref, $hrefsource)
{
    print "<tr class=\"".(($nrows % 2 == 1) ? "odd" : "even")."$pretrowclass\">";
    if ($voter2type != "")
        print $rolecol;
    print "<td>".$row['divisiondate']."</td>";
    print "<td>".$row['divisionnumber']."</td>";
    $divdesc_edited = extract_title_from_wiki_text($row['text_body']);
    $divdesc = $divdesc_edited ? $divdesc_edited : $row['division_name'];
    print "<td>";
    print "<a href=\"$divhref\">$divdesc";
    if ($showmotionwikistate == "listunedited" and !$row['motionedited'])
        print " <i>(unedited)</i>";
    print "</a>";

    print "</td>\n";

    if ($voter1type != "")
    {
        print "<td>$vote1</td>";
        if ($voter2type != "")
            print "<td>$vote2</td>\n";

        # no reason not to have a speeches column on the division table, but we don't
        print "<td><a href=\"$hrefsource\">speeches</a></td>";
    }

    # alternative columns on division table
    else {
        print "<td>".$row['rebellions']."</td> <td>".$row['turnout']."</td>\n";
    }
    print "</tr>\n";
}

function GetPartyVoteSummaryH($db, $div_id)
{
    $query = "SELECT pw_mp.party, COUNT(*), vote, whip_guess
              FROM pw_vote, pw_mp, pw_cache_whip
              WHERE pw_vote.division_id = $div_id
                AND pw_vote.mp_id = pw_mp.mp_id
                AND pw_cache_whip.division_id = pw_vote.division_id
                AND pw_cache_whip.party = pw_mp.party
              GROUP BY pw_mp.party, vote
              ORDER BY party, vote";
    $db->query($query);

    # Precalc values
    $ayes = array();
    $noes = array();
    $boths = array();
    $tellayes = array();
    $tellnoes = array();
    $whips = array();
    $totalpartyvote = array();

    while ($row = $db->fetch_row())
    {
        $party = $row[0];
        $count = $row[1];
        $vote = $row[2];
        $whip = $row[3];

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
function writepersonvote(&$lnrows, $cla, $name, $vote, $ayecla, $nocla)
{
    print "<tr class=\"".(($lnrows % 2 == 1) ? "odd" : "even")."$cla\">";
    print "<td>$name</td>";
    if (($vote == "aye") || ($vote == "AYE"))
        print "<td$ayecla>Aye</td><td$nocla></td>";
    else if (($vote == "no") || ($vote == "NO"))
        print "<td$ayecla></td><td$nocla>No</td>";
    else
        print "<td colspan=2 align=center>$vote</td>";
    print "</tr>\n";
    $lnrows += 1;
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
function print_motion_row($motiontext, $db, $divisionid, $pretrowclass, $rolecol, $roleclass, $votedesc, $votedesclong, $voter1, $vote1, $vote2, $row, $divhref, $hrefsource)
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
    print "<table class=\"votetab\">";
    print "<tr>";
    print "<td class=\"$roleclass\">";
    print $votedesclong;
    print "</td>";
    print "</tr>";
    print "</table>";

    # make the table of party in the right hand side
    print "<table class=\"votetab\">";
    #print "<tr class=\"headings\"><td></td><td>Aye</td><td>No</td></tr>\n";

    $lnrows = 0;

    # get the summary of the rest of the voting from the database
    $partysummary = GetPartyVoteSummaryH($db, $divisionid);

    # total up votes
    $totalayes = array_sum(array_values($partysummary['ayes'])) + array_sum(array_values($partysummary['tellayes']));
    $totalnoes = array_sum(array_values($partysummary['noes'])) + array_sum(array_values($partysummary['tellnoes']));

    # MP's vote
    $ayecla = ($totalayes > $totalnoes ? " class=\"majority\"" : "");
    $nocla = ($totalnoes > $totalayes ? " class=\"majority\"" : "");
    writepersonvote($lnrows, "strong", $voter1['name'], $vote1, $ayecla, $nocla);

    # Dream MP's vote
    if ($vote2 != "")
        writepersonvote($lnrows, "", "DreamMP", $vote2, $ayecla, $nocla);

    # votes of rest of parties (a rather poor way to put it together)
    $party = $voter1['party'];
    $partys = array($party);
    if ($party != "Lab")
        array_push($partys, "Lab");
    if ($party != "Con")
        array_push($partys, "Con");
    if ($party != "LDem")
        array_push($partys, "LDem");
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
    while ($events && (!$date or ($breversed == ($date >= $events[count($events) - 1][0]))))
    {
        $event = array_pop($events);
        print "<tr class=\"jobevent\"><td></td><td>$event[0]</td>";
        print "<td colspan=2 align=center>$event[1]</td><td colspan=3></td></tr>\n";
    }
}

function writelinkheading($desc, $link)
{
    if ($link)
        print "<td><a href=\"$link\">$desc</a></td>";
    else
        print "<td>$desc</td>";
}

# table that shows a selected heap of divisions, and provides a comparison between
# one or two independent voting actors.
# votertype is 'dreammp', 'mp', 'party'
# voter is a mpid, dreammpid, blank-for-self party,
# showwhich is 'everyvote', 'rebellions10', 'all1', 'all2', 'either', 'both', 'bothdiff' (tellers appear automatically)
# (then we need a signal for order and for expanded display, and for events)
# votedisplay is none, 'fullmotion'(for showing the jmp view)
# headings is 'none', 'columns', 'fulldesc'(for changing mps)
# sortby is 'date', 'subject', 'rebellions', 'turnout'
# $parldatelimit is null or a line from $parliaments
# motionwikistate is nothing or 'listunedited' for the "(unedited)" symbols
function division_table($db, $divtabattr, $events = "")
{
    update_divisions_wiki_id($db);

    global $bdebug;
    if ($bdebug == 1)
    {
        print "<h1>";
        print_r($divtabattr);
        print "</h1>";
    }

    # the underlying division list
    $aquery = array();
    $aquery["qselect"] = " SELECT
                            pw_division.division_number AS divisionnumber,
                            pw_division.division_date 	AS divisiondate,
                            division_name, source_url, debate_url, source_gid, debate_gid";

    $aquery["qfrom"]   = " FROM pw_division";
    $aquery["qjoin"]   = " LEFT JOIN pw_cache_divinfo ON pw_cache_divinfo.division_id = pw_division.division_id";

    # where clause with limitation for one parliament, or dummy condition
    $aquery["qwhere"]  = " WHERE 1=1";
    if ($divtabattr["parldatelimit"])
        $aquery["qwhere"]  = " WHERE (pw_division.division_date >= \"".$divtabattr["parldatelimit"]['from']."\"
                                      AND pw_division.division_date < \"".$divtabattr["parldatelimit"]['to']."\")";


    # accumulate the ordering command
    $aquery["qorder"]  = " ORDER BY";
    $sortby = $divtabattr["sortby"];
    $breversed = ($sortby == "datereversed");
    if ($sortby == "subject")
        $aquery["qorder"] .= " division_name, ";
    if ($sortby == "rebellions" or $sortby == "turnout")
        $aquery["qorder"] .= " $sortby DESC, ";
    if ($breversed)
        $aquery["qorder"] .= " divisiondate, divisionnumber";
    else # by date (for all other cases)
        $aquery["qorder"] .= " divisiondate DESC, divisionnumber DESC";

    # corrected column (yet another division_id coding!)
    # motionwikistate is nothing or 'listunedited' for the "(unedited)" symbols
    $showmotionwikistate = $divtabattr["motionwikistate"];
    $aquery["qselect"] .= ", pw_dyn_wiki.wiki_id AS motionedited, pw_dyn_wiki.text_body AS text_body";
    $aquery["qjoin"]  .= "  LEFT JOIN pw_cache_divwiki ON pw_cache_divwiki.division_date = pw_division.division_date
                                    AND pw_cache_divwiki.division_number = pw_division.division_number
                            LEFT JOIN pw_dyn_wiki ON pw_dyn_wiki.wiki_id = pw_cache_divwiki.wiki_id
                            ";

    # full motion text display
    if ($divtabattr['votedisplay'] == 'fullmotion')
    {
        $aquery["qselect"] .= ", pw_division.division_id AS divisionid";
    }

    # extract attibutes
    $showwhich = $divtabattr["showwhich"];
    $voter1type = $divtabattr["voter1type"];
    $voter1 = $divtabattr["voter1"];
    $voter2type = $divtabattr["voter2type"];
    $voter2 = $divtabattr["voter2"];
    $headings = $divtabattr["headings"];

    # construct the first column of votes
    $bonlyvotes1 = ($showwhich == "all1" or $showwhich == "both" or $showwhich == "bothdiff");
    if ($divtabattr["voter1type"] == "mp")
        divmpconds($aquery, $db, $voter1, $bonlyvotes1, false, 1);
    else if ($voter1type == "dreammp")
        divdreammpconds($aquery, $db, $voter1, $bonlyvotes1, 1);
    else if ($voter1type == "")  # this case means we are listing all divisions without a driver
        $aquery["qselect"] .= ", rebellions, turnout";


    # construct the second column of votes (if it exists)
    if ($voter2type != "")
    {
        $bonlyvotes2 = ($showwhich == "all2" or $showwhich == "both" or $showwhich == "bothdiff");
        if ($voter2type == "dreammp")
            divdreammpconds($aquery, $db, $voter2, $bonlyvotes2, 2);
        else if ($voter2type == "party")
        {
            if ($voter2 == "")
                $voter2 = $aquery["party1"];
            divpartyconds($aquery, $db, $voter2, 2);
        }
        else if ($voter2type == "person")
            divmpconds($aquery, $db, $voter2, $bonlyvotes2, true, 2);

        # put in the selection mechanism of diffs into this
        if ($showwhich == "bothdiff")
            $aquery["qwhere"]  .= " AND ".$aquery["vote1"]." <> ".$aquery["vote2"];
        else if ($showwhich == "either")
            $aquery["qwhere"]  .= " AND (".$aquery["vote1"]." IS NOT NULL OR ".$aquery["vote2"]." IS NOT NULL)";
    }

    # apply a selection for "controversial" divisions
    if ($showwhich == "rebellions10")
        $aquery["qwhere"]  .= " AND rebellions > 10";

    # apply the limit
    if ($divtabattr["limitby"] != "")
        $aquery["qlimit"] = " LIMIT ".$divtabattr["limitby"];

    # main set that grabs all the divisions and makes a coarse subsampling
    $query = $aquery["qselect"].$aquery["qfrom"].$aquery["qjoin"].$aquery["qwhere"].$aquery["qgroup"].$aquery["qorder"].$aquery["qlimit"];
    if ($bdebug == 1)
    {
        if ($divtabattr["limitby"] == "")
        {
            $query .= " LIMIT 30";
            print "<h3>Limiting by 30 for shorter table</h3>";
        }
        print "<h1>GGGG $voter1type ";
        print_r($voter1);
        print" $voter2type $voter2 $showwhich $headings</h1>";
        print "<h1>query: $query</h1>\n";
    }
    $db->query($query);


    # make the printing
    $prettyrow = 0;
    $nrows = 0;


    # write the headings if wanted
    if ($headings == "columns" or $headings == "fulldesc")
    {
        print "<tr class=\"headings\">";
        if ($voter2type != "")
            print "<td>Comparison</td>";
        print "<td>Date</td><td>No.</td>";
        print "<td>Subject</td>";

        # comparison type
        if ($voter1type == "mp" and $voter2type == "person")
        {
            writelinkheading($voter1["name"], $divtabattr["voter1link"]);
            writelinkheading($voter2["mpprop"]["name"], $divtabattr["voter2link"]);
        }

        # mp to dream or party type
        else
        {
            if ($voter1type == "party")
                print "<td>$voter1 Vote</td>";
            else if ($voter1type == "dreammp")
                print "<td>Dream Vote</td>";
            else
                print "<td>Vote</td>";

            if ($voter2type != "")
            {
                if ($voter2type == "party")
                    print "<td>$voter2 Vote</td>";
                else if ($voter2type == "dreammp")
                    writelinkheading("Dream Vote", $divtabattr["voter2link"]);
                else
                    print "<td>Vote</td>";
            }
        }
        print "<td>Debate</td></tr>\n";


        # blank case table; must say something
        if ($db->rows() == 0)
        {
            $prettyrow = pretty_row_start($prettyrow, "");
            $mess = "no votes listed";
            if ($showwhich == "bothdiff" and $voter1type == "mp" and $voter2type == "party")
                $mess = "no rebellions, never teller";
            $cspan = ($voter2type != "" ? 7 : 5);
            print "<td colspan=$cspan>$mess</td></tr>\n";
        }
    }

    # sums for the distance metric (the second voter controls the 3-line quality
    $dismetric = array("agree"=>0, "disagree"=>0, "agree3"=>0, "disagree3"=>0,
                       "ab1"=>0, "ab1line3"=>0, "ab2"=>0, "abboth"=>0);

    while ($row = $db->fetch_row_assoc())
    {
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
            $rolecol = workrolecolumn($roleclass, $votedesc, $votedesclong, $voter1type, $vote1, $voter2type, $vote2, $showwhich, $dismetric);
            if ($rolecol == "")
                continue;      # final filter bail out
        }

        # colour red if rebellions, except cases where it's ugly or unnecessary
        else if ($row['rebellions'] >= 10 and $sortby != "rebellions" and $showwhich != "rebellions10")
            $pretrowclass = "rebel";

        $debate_gid = str_replace("uk.org.publicwhip/debate/", "", $row['debate_gid']);
        if ($debate_gid != "")
            $hrefsource = "http://www.theyworkforyou.com/debates/?id=$debate_gid";
        else
            $hrefsource = $row['source_url'];

        $divhref = "division.php?date=".urlencode($row['divisiondate'])."&number=".urlencode($row['divisionnumber']);

        # write out the events
        writeevents($events, $row['divisiondate'], $breversed);

        # votedisplay is none, 'fullmotion'(for showing the jmp view)
        if ($divtabattr['votedisplay'] == 'fullmotion')
        {
            $division_key = get_motion_wiki_key($row['divisiondate'], $row['divisionnumber']);
            $wikiinfo = get_wiki_current_value($division_key);
			$motiontext = extract_motion_text_from_wiki_text($wikiinfo['text_body']);
			print_motion_row($motiontext, $db, $row['divisionid'], $pretrowclass, $rolecol, $roleclass, $votedesc, $votedesclong, $voter1, $vote1, $vote2, $row, $divhref, $hrefsource);
			$nrows += 2;
        }
        else
        {
            print_division_row($nrows, $pretrowclass, $rolecol, $voter1type, $voter2type, $vote1, $vote2, $row, $showmotionwikistate, $divhref, $hrefsource);
            $nrows += 1;
        }
    }

    # finish the remainder of the events
    writeevents($events, "", $breversed);

    return $dismetric;
}

?>
