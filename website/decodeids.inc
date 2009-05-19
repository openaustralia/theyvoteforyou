<?php
# $Id: decodeids.inc,v 1.48 2009/05/19 14:47:21 marklon Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once $toppath . "parliaments.inc";
require_once $toppath . "postcode.inc";
require_once $toppath . "wiki.inc";
require_once $toppath . "links.inc";

# this maps all constituency names to numbers
require_once $toppath . "constituencies.inc";

# get the constituency and names to use from an mpid
# mpgen says the equivalence class is by constituency or by person
function get_mpid_attr($db, $db2, $mpid, $bbyconstituency, $i, $voter2dream_overlap)
{
    global $bdebug;
    # convert the mpid into a person-id
    $query = "SELECT title, first_name, last_name, constituency, person, party, house, mp_id
              FROM   pw_mp
              WHERE mp_id = $mpid";

    if ($bdebug == 1)
        print "<h1>getmpattr: $query</h1>\n";
    $row = $db->query_one_row_assoc($query);

    # build the anchor tag
    $mpname = $row['title'].' '.$row['first_name'].' '.$row['last_name'];
    $constituency = $row['constituency'];
    $person = $row['person'];
    $party = $row['party'];
    $house = $row['house'];

    # get the mpids in this class, for the person, or all reps of a constituency
    if ($bbyconstituency)
        $qwhere = "constituency = '".db_scrub($constituency)."'";
    else
        $qwhere = "person = $person";

	$qselect = "pw_mp.mp_id AS mpid, title, first_name, last_name, constituency, person, party, house,
                entered_house, left_house, party, entered_reason, left_reason,
                rebellions, votes_attended, votes_possible, tells";
    $query = "SELECT $qselect
              FROM   pw_mp
              LEFT JOIN pw_cache_mpinfo ON pw_mp.mp_id = pw_cache_mpinfo.mp_id
              WHERE $qwhere
              ORDER BY entered_house DESC";
    if ($bdebug == 1)
        print "<h1>decode person: $query</h1>\n";
    $row = $db->query($query);

    # build a set of data for each mpid in this group
    $mpids = array();
    $mpprops = array();
    $bmultiperson = false;  # record if this set really does cover more than one person
    $bmulithouse = false;
    $thismpprop = null;
    $minentered_house = "9999-12-31";
    while ($row = $db->fetch_row_assoc())
    {
        $mppropname = trim($row['title'].' '.$row['first_name'].' '.$row['last_name']);
        $mppropanchor = link_to_mp($row, 1);
        $mppropanchor2 = link_to_mp($row, 2);
        $mpprop = 	array("mpid"		=> $row['mpid'],
                          "title" 		=> $row['title'],
                          "name" 		=> $mppropname,
                          "person"		=> $row['person'],
                          "party"		=> $row['party'],
                          "constituency" => $row['constituency'],
                          "house" 		=> $row['house'],  # appeared to be missing
                          "mpanchor"	=> $mppropanchor,
                          "mpanchor2"	=> $mppropanchor2,
                          "parliament"  => date_to_parliament($row["entered_house"]),
                          "enteredhouse" => $row['entered_house'],
                          "lefthouse" 	=> $row['left_house'],
                          "enteredreason" => $row['entered_reason'],
                          "leftreason" 	=> $row['left_reason'],
                          "rebellions" 	=> $row['rebellions'],
                          "votesattended" => $row['votes_attended'],
                          "votespossible" => $row['votes_possible'],
                          "tells" 		=> $row['tells']);
		if ($row['house'] == 'commons')
		{
			$mpprop['housenamesuffix'] = 'MP';
			$mpprop['housenoun'] = 'MP';
			$mpprop['housenounplural'] = 'MPs';
			$mpprop['fullname'] = "$mppropname MP, ".$row['constituency'];
		}
		elseif ($row['house'] == 'scotland')
		{
			$mpprop['housenamesuffix'] = 'MSP';
			$mpprop['housenoun'] = 'MSP';
			$mpprop['housenounplural'] = 'MSPs';
			$mpprop['fullname'] = "$mppropname MSP, ".$row['constituency'];
		}
		else
		{
			$mpprop['housenamesuffix'] = '';
			$mpprop['housenoun'] = 'Lord';
			$mpprop['housenounplural'] = 'Lords';
			$mpprop['fullname'] = $mppropname;
		}

		# check for an over-lap with the dreammp
		if ($voter2dream_overlap)
		{
			$query = "SELECT vote FROM pw_dyn_dreamvote
					  WHERE division_date >= \"".$row['entered_house']."\" AND division_date < \"".$row['left_house']."\"
					  	AND dream_id = ".$voter2dream_overlap['dreammpid']."
						LIMIT 1";
		    if ($bdebug)
		    	print "<h1>$query</h1>\n";
			$row2 = $db2->query_onez_row_assoc($query);
			if ($row2 == null)
				continue;
		}

        if ($bdebug == 1)
        {
            print "<h4>prop:";
            print_r($mpprop);
            print "</h4>\n";
        }

        array_push($mpprops, $mpprop);
        if (($mpprop['mpid'] == $mpid) || ($thismpprop == null))  # recover the original mp, or the most recent
            $thismpprop = $mpprop;
        if (($mpprop['person'] == $thismpprop["person"])) # && ($minentered_house == "9999-12-31"))
            $minentered_house = $mpprop['enteredhouse'];

        array_push($mpids, $row['mp_id']);
        if ($person != $row['person'])
			$bmultiperson = true;
        if ($house != $row['house'])
            $bmultihouse = true;
	}

    if ($bdebug == 1)
        print "<h1>$mpname, $constituency, multiperson:".($multiperson ? "yes" : "no")."</h1>\n";

    return array("mpprops"		=> $mpprops,
                 "mpprop"		=> $thismpprop,
                 "minentered_house" => $minentered_house,
                 "bmultiperson" => $bmultiperson,
                 "bmultihouse"  => $bmultihouse);
}

# this is used for getting mpids from links prior to 2005-03
function decode_mpid_legacy($db)
{
    global $bdebug;

    $id = db_scrub($_GET["id"]);
    if ($id != "")
    {
        # value from theyworkforyou
        if (stristr($id, "uk.org.publicwhip/member/"))
            return str_replace("uk.org.publicwhip/member/", "", $id);
        if ($bdebug == 1)
            print "<h1>unrecognized id=$id";
        return null;
    }

    # For a while we allowed this style for MPs
    $mpurlid = db_scrub($_GET["mpid"]);
    if ($mpurlid) {
        # By identifier directly
        $mpid = $mpurlid;
        $query = "SELECT mp_id FROM pw_mp WHERE gid='uk.org.publicwhip/member/".$mpurlid."'
            or gid='uk.org.publicwhip/lord/".$mpurlid."'";
        $row = $db->query_one_row_assoc($query);
        return db_scrub($row["mp_id"]);
     }

    # get the name and constituency
    $constituency = $_GET["constituency"];
    if ($constituency == "")
        return null;
    $constituency = strtolower(stripslashes(html_entity_decode($constituency)));
    $constituency = normalise_constituency_name($db, $constituency);
    $constituency = db_scrub($constituency);
    $first_name = db_scrub($_GET["firstname"]);
    $last_name = db_scrub($_GET["lastname"]);
    if ($bdebug == 1)
        print "<h1> FN=$first_name LN=$last_name CO=$constituency</h1>";

    $qwhere = "WHERE ";
    if ($constituency)
	    $qwhere .= "constituency = '$constituency'";
    else
	    $qwhere .= "1 = 1";
    if ($first_name != "")
        $qwhere .= " AND first_name = '$first_name' AND last_name = '$last_name'";

    $query = "SELECT mp_id
              FROM pw_mp
              $qwhere
              ORDER BY entered_house DESC LIMIT 1";
    $row = $db->query_one_row_assoc($query);
    $id = db_scrub($row["mp_id"]);
    return $id;
}


# returns the ith mpid from the link (0th is blank)
# pc_parl is parliament to do any postcode lookup in (default = current)
function get_mpid_attr_decode($db, $db2, $i, $voter2dream_overlap=null, $pc_parl=null)
{
    global $bdebug;

    $mpname = db_scrub($_GET["mpn$i"]);
    $mpconstituency = db_scrub($_GET["mpc$i"]);
    $mphouse = db_scrub($_GET["house$i"]);
    $mppostcode = db_scrub($_GET["mppc$i"]);
    if ($bdebug == 1)
        print "<h1> MPN=".html_scrub($mpname)." MPC=".html_scrub($mpconstituency)." MPPC=".html_scrub($mppostcode)." HOUSE=".html_scrub($mphouse)."</h1>";

    if (is_postcode($mppostcode)) {
        $pccons = postcode_to_constituency($db, $mppostcode, $pc_parl, $mphouse);
        if (isset($pccons)) {
            $mpconstituency = $pccons;
        }
    }

    if ($mpname == "" and $mpconstituency == "")
    {
        if ($i != "")   # legacy doesn't apply to second and third entries which may be blank
            return null;
        $mpid = decode_mpid_legacy($db);
        if ($mpid == null)
            return null;
        $bbyconstituency = false;
    }

    # this is stable for one or both matching labels being present
    # hard case is two mps in same constituency at different times with same name

    # extract the constituency
    else
    {
        $qwhere = "";
        if ($mpconstituency != "" && $mpconstituency != "Lords")
        {
            $constituency = strtolower(stripslashes(html_entity_decode($mpconstituency)));
            $constituency = str_replace("_", " ", $constituency);
            $constituency = normalise_constituency_name($db, $constituency);
            $constituency = db_scrub($constituency);
            if ($constituency == "")
            {
                print "Error, constituency " . $mpconstituency . " not found";
                exit;
            }
            $qwhere = "constituency = '$constituency'";
            if ($mphouse=='scotland') {
                $qwhere .= " and house = 'scotland'";
            } elseif ($mphouse=='commons') {
                $qwhere .= " and house = 'commons'";
            }
        }
        if ($mpname != "")
        {
            if ($qwhere != "")
                $qwhere .= " and ";
            $mpname = str_replace("_", " ", $mpname);
            $qwhere .= "('$mpname' = CONCAT(first_name, ' ', last_name)";
            $qwhere .= " OR '$mpname' = CONCAT(title, ' ', first_name, ' ', last_name))";
        }

        $query = "SELECT mp_id
                  FROM   pw_mp
                  WHERE $qwhere
                  ORDER BY entered_house
                  DESC LIMIT 1";
        $row = $db->query_one_row($query);
        $mpid = db_scrub($row[0]);
        $bbyconstituency = ($mpname == "");
    }

    return get_mpid_attr($db, $db2, $mpid, $bbyconstituency, $i, $voter2dream_overlap);
}

# do the attributes for a dream mp
function get_dreammpid_attr_decode($db, $i)
{
    $dreammpid = db_scrub($_GET[($i == "id" ? $i : "dmp$i")]);  # so we can choose to look for id= instead of dmp=
    if ($dreammpid == "" && $i == "id")
        $dreammpid = db_scrub($_POST[$i]); 
    if ($dreammpid == "")
        return null;
    $dreammpid = intval($dreammpid);
	$qselect = "SELECT pw_dyn_dreammp.name AS name, pw_dyn_dreammp.description AS description,
					   pw_dyn_user.user_id AS user_id, user_name,
					   votes_count, edited_motions_count,
                       private";
	$qfrom	 = " FROM pw_dyn_dreammp";
	$qjoin 	 = " LEFT JOIN pw_cache_dreaminfo ON pw_cache_dreaminfo.dream_id = pw_dyn_dreammp.dream_id";
	$qjoin 	.= " LEFT JOIN pw_dyn_user ON pw_dyn_user.user_id = pw_dyn_dreammp.user_id";
	$qwhere  = " WHERE pw_dyn_dreammp.dream_id = $dreammpid";
	$query = $qselect.$qfrom.$qjoin.$qwhere;

    $row = $db->query_one_row_assoc($query);
    $dmp_name = $row[0];

    return array("dreammpid" 	=> $dreammpid,
                 "name" 		=> $row['name'],
                 "description" 	=> $row['description'],
                 "userid" 		=> $row['user_id'],
                 "user_name" 	=> $row['user_name'],
                 "private" 		=> $row['private'],
                 "votes_count" 	=> $row['votes_count'],
                 "edited_count" => $row['edited_motions_count'],
                 "anchor"		=> "dmp$i=".urlencode($dreammpid));
}

# do the attributes for a division listing, use defaults when $i is set
function get_division_attr_decode($db, $i)
{
    global $bdebug;
    $div_date = db_scrub($_GET["date$i"]);
    $div_no = db_scrub($_GET["number$i"]);
    $div_house = db_scrub($_GET["house$i"]);
	if (!$div_house)
		$div_house = "commons";
    if (!$div_date and $i != "")
        $div_date = db_scrub($_GET["date"]);
    if (!$div_date or ($div_no != 0 && !$div_no))
        return none;

    $query = "SELECT division_date, division_number, house,
                     pw_division.division_id AS division_id,
                     division_name, motion, notes,
                     source_url, debate_url, source_gid, debate_gid,
                     rebellions, turnout, aye_majority, clock_time
              FROM pw_division
              LEFT JOIN pw_cache_divinfo
                ON pw_cache_divinfo.division_id = pw_division.division_id
              WHERE division_date = '$div_date' AND division_number = '$div_no' AND house = '$div_house'";

    # warning error shows up from this line if in debug since it comes before the first characters that set the type in head.inc
    if ($bdebug == 1)
        print "<h5>$query</h5>";
    $row = $db->query_onez_row_assoc($query);
    if (!$row)
        return "none";

    $house_paramter = "";
    if ($row['house'] == "lords") {
        $house_parameter = "&house=lords";
    } elseif ($row['house'] == "scotland") {
        $house_parameter = "&house=scotland";
    }

    return array("division_date" 	=> $row["division_date"],
                 "division_number" 	=> $row['division_number'],
                 "house"            => $row['house'],
                 "division_id" 		=> $row['division_id'],
                 "prettydate"		=> date("j M Y", strtotime($row["division_date"])),
                 "parliament"		=> date_to_parliament($row["division_date"]),
                 "name"				=> $row["division_name"],
                 "debate_url"		=> $row["debate_url"],
                 "source_url"		=> $row["source_url"],
                 "debate_gid"		=> $row["debate_gid"],
                 "source_gid"		=> $row["source_gid"],
                 "rebellions"		=> $row["rebellions"],
                 "turnout"			=> $row["turnout"],
                 "aye_majority"     => $row["aye_majority"],
                 "clock_time"       => $row["clock_time"],
                 "divhref"			=> "division.php?date=".urlencode($row["division_date"])."&number=".urlencode($row["division_number"]).$house_parameter,
                 "original_motion"	=> $row["motion"]);
}

function dismodes_to_second_links($thispage, $dismodes, $tpsort, $display) 
{
    $second_links = array();
    foreach ($dismodes as $ldisplay => $ldismode)
	{
        # hack to avoid dangling dmps
        if ($ldisplay == "alldreams")
            $thispage = preg_replace("/&dmp=\d+/", "", $thispage);

        $dlink = $thispage.($ldisplay == "summary" ? "" : "&display=$ldisplay").$tpsort;
        array_push($second_links, array(
            'tooltip' => $ldismode["tooltip"],
            'current' => ($ldisplay == $display ? "on" : "off"),
            'href' => $dlink,
            'text' => $ldismode["description"]));
	}
    if (count($second_links) <= 1)
        return array();
    return $second_links;
}

?>
