<?php
    # $Id: decodeids.inc,v 1.1 2005/02/18 16:41:20 goatchurch Exp $

    # The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "parliaments.inc";

 	# this maps all constituency names to numbers
    include "constituencies.inc";

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
	function decode_mpid($db, $i)
	{
		global $consmatch, $consnames;

		if ($i == 0)
			$i = "";
		$mpname = db_scrub($_GET["mpn$i"]);
		$mpconstituency = db_scrub($_GET["mpc$i"]);
		if ($mpname == "" and $mpconstituency == "")
		{
			if ($i != "")   # legacy doesn't apply to second and third entries which may be blank
				return "";
			return decode_mpid_legacy($db);
		}

		# this is stable for one or both matching labels being present
		# hard case is two mps in same constituency at different times with same name

		# extract the constituency
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
		return db_scrub($row[0]);
	}

	# get the constituency and names to use from an mpid
	function get_mpid_attr($db, $mpid, $i="")
	{
		$query = "SELECT first_name, last_name, constituency, person, party, mp_id
				  FROM   pw_mp
				  WHERE mp_id = $mpid";
		$row = $db->query_one_row($query);

		$mpname = $row[0].' '.$row[1];
		if ($i == 0)
			$i = "";
		$mpanchor = "mpn$i=".urlencode(str_replace(" ", "_", $mpname))."&"."mpc$i=".urlencode($row[2]);
		return array("mpname" 		=> $mpname,
					 "constituency" => $row[2],
					 "personid"		=> $row[3],
					 "party"		=> $row[4],
					 "mpanchor"		=> $mpanchor);
	}


?>


