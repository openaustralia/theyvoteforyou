<?php
    # $Id: decodeids.inc,v 1.3 2005/02/19 10:27:26 goatchurch Exp $

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
		$query = "SELECT first_name, last_name, constituency, person, party, mp_id
				  FROM   pw_mp
				  WHERE mp_id = $mpid";
		$row = $db->query_one_row_assoc($query);

		# build the anchor tag
		$mpname = $row['first_name'].' '.$row['last_name'];
		$mpanchor = "mpn$i=".urlencode(str_replace(" ", "_", $mpname))."&"."mpc$i=".urlencode($row['constituency']);

		$constituency = $row['constituency'];
		$person = $row['person'];
		$party = $row['party'];

		# get the mpids in this class (usually for the person)
		if ($bbyconstituency)
			$qwhere = "constituency = ".$constituency;
		else
			$qwhere = "person = ".$person;
		$query = "SELECT mp_id, constituency, person, entered_house
				  FROM   pw_mp
				  WHERE $qwhere
				  ORDER BY entered_house DESC";
		$row = $db->query($query);
		$mpids = array();
		$bmultiperson = false;  # record if this set really does cover more than one person
	    while ($row = $db->fetch_row_assoc())
	    {
	    	array_push($mpids, $row['mp_id']);
	        if ($person != $row['person'])
				$bmultiperson = true;
	 	}

		return array("mpid" 		=> $mpid,
					 "mpname" 		=> $mpname,
					 "constituency" => $constituency,
					 "personid"		=> $person,
					 "party"		=> $party,
					 "mpanchor"		=> $mpanchor,
					 "mpids"		=> $mpids,
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
		{
			print "Error, constituency " . $cmatch . " not found";
	        exit;
	    }

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


