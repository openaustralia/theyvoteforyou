<?php
    # $Id: decodeids.inc,v 1.4 2005/02/21 13:12:21 goatchurch Exp $

    # The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "parliaments.inc";

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
			$qwhere = "constituency = $constituency";
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

		return array("mpid" 		=> $mpid,
					 "mpname" 		=> $mpname,
					 "constituency" => $constituency,
					 "personid"		=> $person,
					 "party"		=> $party,
					 "mpanchor"		=> $mpanchor,
					 "mpids"		=> $mpids,
					 "mpprops"		=> $mpprops,
					 "mpprop"		=> $thismpprop,
					 "bmultiperson" => $bmultiperson);
	}

	# this is used for getting mpids from links prior to 2005-03
	function decode_mpid_legacy($db)
	{
		global $consmatch, $consnames;

	    $first_name = db_scrub($_GET["firstname"]);
	    $last_name = db_scrub($_GET["lastname"]);
	    # The consmatch converts constituency to canonical form as it comes in
	    $constituency = $_GET["constituency"];
	    $constituency = strtolower(stripslashes(html_entity_decode($constituency)));
		$cmatch = $consmatch[$constituency];
		$cmatch = $consmatch["city of york"];
	    $constituency = $consnames[$consmatch[$constituency]];
		$constituency = db_scrub($constituency);
	    $id = db_scrub($_GET["id"]);
	    if ($constituency == "" and $id == "")
			return null;

	   	if ($constituency == "")
		{
			$id = str_replace("uk.org.publicwhip/member/", "", $id);
			$query = "select first_name, last_name, constituency
				from pw_mp where mp_id = '$id'
				order by entered_house desc limit 1";
			$row = $db->query_one_row($query);
			$first_name = db_scrub($row[0]);
			$last_name = db_scrub($row[1]);
			$constituency = db_scrub($row[2]);
		}
		else
		{
			$query = "select first_name, last_name, mp_id
				from pw_mp where constituency = '$constituency'
				order by entered_house desc limit 1";
			$row = $db->query_one_row($query);
			$first_name = db_scrub($row[0]);
			$last_name = db_scrub($row[1]);
			$id = db_scrub($row[2]);
		}
		return $id;
	}


	# returns the ith mpid from the link (0th is blank)
	function get_mpid_attr_decode($db, $i)
	{
		global $consmatch, $consnames;

		$mpname = db_scrub($_GET["mpn$i"]);
		$mpconstituency = db_scrub($_GET["mpc$i"]);
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
					 "username" 	=> $row['username'],
					 "anchor"		=> "dmp$i=".urlencode($dreammpid));

	}
?>


