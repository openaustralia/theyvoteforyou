<?php
# $Id: decodeids.inc,v 1.12 2005/04/07 08:44:30 theyworkforyou Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include "parliaments.inc";
include "postcode.inc";
require_once "wiki.inc";

# this maps all constituency names to numbers
include "constituencies.inc";

# get the constituency and names to use from an mpid
# mpgen says the equivalence class is by constituency or by person
function get_mpid_attr($db, $mpid, $bbyconstituency, $i)
{
    global $bdebug;
    # convert the mpid into a person-id
    $query = "SELECT first_name, last_name, constituency, person, party, mp_id
              FROM   pw_mp
              WHERE mp_id = $mpid";

    if ($bdebug == 1)
        print "<h1>getmpattr: $query</h1>\n";
    $row = $db->query_one_row_assoc($query);

    # build the anchor tag
    $mpname = $row['first_name'].' '.$row['last_name'];
    $mpanchor = "mpn$i=".urlencode(str_replace(" ", "_", $mpname))."&"."mpc$i=".urlencode($row['constituency']);

    $constituency = $row['constituency'];
    $person = $row['person'];
    $party = $row['party'];

    # get the mpids in this class, for the person, or all reps of a constituency
    if ($bbyconstituency)
        $qwhere = "constituency = '$constituency'";
    else
        $qwhere = "person = $person";
    $query = "SELECT pw_mp.mp_id as mpid, title, first_name, last_name, constituency, person, party,
                entered_house, left_house, party, entered_reason, left_reason,
                rebellions, votes_attended, votes_possible, tells
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
    while ($row = $db->fetch_row_assoc())
    {
        $mppropname = $row['first_name'].' '.$row['last_name'];
        $mppropanchor = "mpn$i=".urlencode(str_replace(" ", "_", $mppropname))."&"."mpc$i=".urlencode($row['constituency']);
        $mpprop = 	array("mpid"		=> $row['mpid'],
                          "title" 		=> $row['title'],
                          "name" 		=> $mppropname,
                          "person"		=> $row['person'],
                          "party"		=> $row['party'],
                          "constituency" => $row['constituency'],
                          "mpanchor"	=> $mppropanchor,
                          "enteredhouse" => $row['entered_house'],
                          "lefthouse" 	=> $row['left_house'],
                          "enteredreason" => $row['entered_reason'],
                          "leftreason" 	=> $row['left_reason'],
                          "rebellions" 	=> $row['rebellions'],
                          "votesattended" => $row['votes_attended'],
                          "votespossible" => $row['votes_possible'],
                          "tells" 		=> $row['tells']);

        if ($bdebug == 1)
        {
            print "<h1>prop:";
            print_r($mpprop);
            print "</h1>\n";
        }

        array_push($mpprops, $mpprop);
        if ($row['mpid'] == $mpprop['mpid'])  # recover the original mp
            $thismpprop = $mpprop;


        array_push($mpids, $row['mp_id']);
        if ($person != $row['person'])
            $bmultiperson = true;
    }

    if ($bdebug == 1)
        print "<h1>$mpname, $constituency, multiperson:$multiperson</h1>\n";

    return array("mpprops"		=> $mpprops,
                 "mpprop"		=> $thismpprop,
                 "bmultiperson" => $bmultiperson);
}

# this is used for getting mpids from links prior to 2005-03
function decode_mpid_legacy($db)
{
    global $bdebug;
    global $consmatch, $consnames;

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

    # get the name and constituency
    $constituency = $_GET["constituency"];
    if ($constituency == "")
        return null;
    # The consmatch converts constituency to canonical form as it comes in
    $constituency = strtolower(stripslashes(html_entity_decode($constituency)));
    $constituency = $consnames[$consmatch[$constituency]];
    $constituency = db_scrub($constituency);
    $first_name = db_scrub($_GET["firstname"]);
    $last_name = db_scrub($_GET["lastname"]);
    if ($bdebug == 1)
        print "<h1> FN=$first_name LN=$last_name CO=$constituency</h1>";

    $qwhere = "WHERE constituency = '$constituency'";
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
function get_mpid_attr_decode($db, $i)
{
    global $bdebug;
    global $consmatch, $consnames;

    $mpname = db_scrub($_GET["mpn$i"]);
    $mpconstituency = db_scrub($_GET["mpc$i"]);
    $mppostcode = db_scrub($_GET["mppc$i"]);
    $mpurlid = db_scrub($_GET["mpid$i"]);
    if ($bdebug == 1)
        print "<h1> MPN=".html_scrub($mpname)." MPC=".html_scrub($mpconstituency)." MPPC=".html_scrub($mppostcode)."</h1>";

    if (is_postcode($mppostcode)) {
        $pccons = postcode_to_constituency($mppostcode);
        if (isset($pccons)) {
            $mpconstituency = $pccons; 
        }
    }
        
    if ($mpname == "" and $mpconstituency == "")
    {
        if ($mpurlid != "") {
            # By identifier directly
            $mpid = $mpurlid;
        }
        else {
            if ($i != "")   # legacy doesn't apply to second and third entries which may be blank
                return null;
            $mpid = decode_mpid_legacy($db);
            if ($mpid == null)
                return null;
            $bbyconstituency = false;
        }
    }

    # this is stable for one or both matching labels being present
    # hard case is two mps in same constituency at different times with same name

    # extract the constituency
    else
    {
        $qwhere = "";
        if ($mpconstituency != "")
        {
            $constituency = strtolower(stripslashes(html_entity_decode($mpconstituency)));
            $constituency = str_replace("_", " ", $constituency);
            $constituency = $consnames[$consmatch[$constituency]];
            $constituency = db_scrub($constituency);
            if ($constituency == "")
            {
                print "Error, constituency " . $mpconstituency . " not found";
                exit;
            }
            $qwhere = "constituency = '$constituency'";
        }
        if ($mpname != "")
        {
            if ($qwhere != "")
                $qwhere .= " and ";
            $mpname = str_replace("_", " ", $mpname);
            $qwhere .= "'$mpname' = CONCAT(first_name, ' ', last_name)";
        }

        $query = "SELECT mp_id, first_name, last_name, entered_house
                  FROM   pw_mp
                  WHERE $qwhere
                  ORDER BY entered_house
                  DESC LIMIT 1";
        $row = $db->query_one_row($query);
        $mpid = db_scrub($row[0]);
        $bbyconstituency = ($mpname == "");
    }

    return get_mpid_attr($db, $mpid, $bbyconstituency, $i);
}

# do the attributes for a dream mp
function get_dreammpid_attr_decode($db, $i)
{
    $dreammpid = db_scrub($_GET["dmp$i"]);
    if ($dreammpid == "")
        return null;
    $query = "SELECT name, description, pw_dyn_user.user_id as userid, user_name, rollie_Id
              FROM pw_dyn_rolliemp, pw_dyn_user
              WHERE pw_dyn_rolliemp.user_id = pw_dyn_user.user_id
                    AND rollie_Id = '$dreammpid'";
    $row = $db->query_one_row_assoc($query);
    $dmp_name = $row[0];

    return array("dreammpid" 	=> $dreammpid,
                 "name" 		=> $row['name'],
                 "description" 	=> $row['description'],
                 "userid" 		=> $row['userid'],
                 "user_name" 	=> $row['user_name'],
                 "anchor"		=> "dmp$i=".urlencode($dreammpid));
}

# do the attributes for a division listing
function get_division_attr_decode($db, $i)
{
    global $bdebug;
    $div_date = db_scrub($_GET["date$i"]);
    $div_no = db_scrub($_GET["number$i"]);
    if (!$div_date and $i != "")
        $div_date = db_scrub($_GET["date"]);
    if (!$div_date or !$div_no)
        return none;

    $query = "SELECT division_date, division_number,
                     pw_division.division_id AS division_id,
                     division_name, motion, notes,
                     source_url, debate_url, source_gid, debate_gid,
                     rebellions, turnout
              FROM pw_division
              LEFT JOIN pw_cache_divinfo
                ON pw_cache_divinfo.division_id = pw_division.division_id
              WHERE division_date = '$div_date' AND division_number = '$div_no'";

    # warning error shows up from this line if in debug since it comes before the first characters that set the type in head.inc
    if ($bdebug == 1)
        print "<h5>$query</h5>";
    $row = $db->query_one_row_assoc($query);
    $motion_key = get_motion_wiki_key($row["division_date"], $row['division_number']);

    return array("division_date" 	=> $row["division_date"],
                 "division_number" 	=> $row['division_number'],
                 "division_id" 		=> $row['division_id'],
                 "prettydate"		=> date("j M Y", strtotime($row["division_date"])),
                 "name"				=> $row["division_name"],
                 "debate_url"		=> $row["debate_url"],
                 "source_url"		=> $row["source_url"],
                 "debate_gid"		=> $row["debate_gid"],
                 "source_gid"		=> $row["source_gid"],
                 "rebellions"		=> $row["rebellions"],
                 "turnout"			=> $row["turnout"],
                 "divhref"			=> "division.php?date=".urlencode($row["division_date"])."&number=".urlencode($row["division_number"]),
                 "motion_key"		=> $motion_key,
                 "original_motion"	=> $row["motion"]);
}
?>
