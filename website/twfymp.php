<?php require_once "common.inc";
    # $Id: twfymp.php,v 1.1 2009/11/27 23:24:17 publicwhip Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $db = new DB();
	$db2 = new DB();

	# standard decoding functions for the url attributes
	require_once "decodeids.inc";
	require_once "tablemake.inc";
	require_once "tableoth.inc";
    require_once "dream.inc";
	require_once "tablepeop.inc";
    require_once "wiki.inc"; 

	# the main mp list

	# against a dreammp, another mp, or the party
	$voter2attr = get_dreammpid_attr_decode($db, "");
	if ($voter2attr != null)
	{
		$voter2type = "dreammp";
		$voter2 = $voter2attr['dreammpid'];
	}
	# decode the parameters.
	# first is the two voting objects which get compared together.
	# First is an mp (arranged by person or by constituency)
	# Second is another mp (by person), a dream mp, or a/the party
	$voter1attr = get_mpid_attr_decode($db, $db2, "", ($voter2type == "dreammp" ? $voter2attr : null));
	if ($voter1attr == null) {
		print "<p>No MP or Lord found. If you entered a postcode, please make
        sure it is correct.  Or you can <a href=\"/mps.php\">browse
        all MPs</a> or <a href=\"/mps.php?house=lords\">browse all Lords</a>.";
        exit;
    }
	$voter1type = "mp";

	# shorthand to get at the designated MP for this class of MP holders
	# (multiple sets of properties, usually overlapping, hold for each MP if they've had more than one term)
	$mpprop = $voter1attr["mpprop"];

	# case now is we know the two voting actors,
	# (and whether the first is a constituency or a person)
	# select a mode for what is displayed
	# code for the 0th mp def, if it is there.
    $voter1link = "mp.php?";
	$voter1link .= $mpprop['mpanchor'];


	$referrer = $_SERVER["HTTP_REFERER"];
    $querystring = $_SERVER["QUERY_STRING"];
    $ipnumber = $_SERVER["REMOTE_ADDR"];
    $mpid = $mpprop["mpid"];
    $page_logged = "twfymp"; 
    $subject_logged = ($voter2type == "dreammp" ? $voter2 : "");

    

	 header("Content-type: text/html");
     //print "<h1>hi there</h1>";

     $qselect = " SELECT pw_division.division_number AS divisionnumber,
                         pw_division.division_number AS divisionnumber,
                         pw_division.division_date   AS divisiondate,
                         pw_division.clock_time      AS divisiontime,
                         pw_division.house           AS divisionhouse,
                         division_name, source_url, debate_url, pw_division.source_gid AS source_gid, debate_gid, aye_majority";


     $dreammpid = $voter2; 
     $mpid = $mpprop["mpid"];
     $person = $mpprop["person"]; 

     $qfrom = " FROM pw_division"; 
     $qjoin =  " LEFT JOIN pw_cache_divinfo ON pw_cache_divinfo.division_id = pw_division.division_id";
     $qjoin .= " LEFT JOIN pw_dyn_dreamvote ON 
                         pw_dyn_dreamvote.dream_id = $dreammpid
                         AND pw_dyn_dreamvote.division_date = pw_division.division_date
                         AND pw_dyn_dreamvote.division_number = pw_division.division_number";
     $qselect .= ", pw_mp.person AS person"; 
     
     $qjoin .= " LEFT JOIN pw_mp ON pw_mp.person = $person 
                        AND (pw_division.division_date >= pw_mp.entered_house 
                                     AND pw_division.division_date < .pw_mp.left_house)";

     //$qjoin .= " LEFT JOIN pw_mp ON pw_mp.mp_id = $mpid"; 
     $qjoin .= " LEFT JOIN pw_vote ON pw_vote.division_id = pw_division.division_id AND pw_vote.mp_id = pw_mp.mp_id";
     $qselect .= ", pw_vote.vote AS vote"; 

     $qwhere = " WHERE 1=1"; 
     $qwhere .= " AND pw_dyn_dreamvote.vote IS NOT NULL";
     $qwhere .= " AND pw_mp.mp_id IS NOT NULL";
    
     //$qselect .= ", pw_dyn_wiki_motion.wiki_id AS motionedited, pw_dyn_wiki_motion.text_body AS text_body";
     $qselect .= ", pw_dyn_wiki_motion.text_body AS text_body";
     $qjoin  .= "  LEFT JOIN pw_cache_divwiki ON pw_cache_divwiki.division_date = pw_division.division_date
                         AND pw_cache_divwiki.division_number = pw_division.division_number AND pw_cache_divwiki.house = pw_division.house
                  LEFT JOIN pw_dyn_wiki_motion ON pw_dyn_wiki_motion.wiki_id = pw_cache_divwiki.wiki_id";

     $qlimit = " LIMIT 50"; 
     $query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup.$qorder.$qlimit;
     //print "<h2>$query</h2>"; 
     
     $db->query($query);
     print "<div>"; 
     print "<span class=\"mpname\"><b>".$mpprop["fullname"]."</b>...</span>\n"; 
     print "<ul>\n"; 
     while ($row = $db->fetch_row_assoc())
     {
        //print "<pre>";
        //print_r($row); 
        //print "</pre>"; 
        $divhref = "http://www.publicwhip.org.uk/division.php?date=".urlencode($row['divisiondate'])."&number=".urlencode($row['divisionnumber']); 
        $divhref .= "&mpn=".urlencode(str_replace(" ", "_", $mpprop["name"])); 
        $divhref .= "&mpc=".urlencode(str_replace(" ", "_", $mpprop["constituency"])); 
        
        $vote = $row["vote"]; 
        if ($vote == "tellaye")
            $vote = "aye"; 
        if ($vote == "tellno")
            $vote = "no"; 
        
        if ($vote)
            $votewithmajority = ($vote == ($row["aye_majority"] >= 0 ? "aye" : "no") ? "majority" : "minority");  
        else
            $votewithmajority = "novote"; 

        $style = " style=\"background-color: ".($votewithmajority == "majority" ? "#9f9" : ($votewithmajority == "minority" ? "#f99" : "#fee"))."\""; // add some colour for now
        print "<li class=\"$votewithmajority\"$style>";

        print "(".$row["divisiondate"].")\n"; 
        $actiontext = ($row["text_body"] ? extract_action_text_from_wiki_text($row["text_body"]) : array("title" => $row["division_name"])); 
        $action = $actiontext[$vote]; 
        //print_r($actiontext); 
        if ($action)
            print "voted ".$action; 
        else if ($vote)
            print "voted <em>$vote</em> on <i>".$actiontext["title"]."</i>"; // could convert vote here
        else
            print ($vote ? "voted $vote" : "did not vote")." on \"".$actiontext["title"]."\""; 

        // could include info if it was a rebel vote
        print "(<a href=\"$divhref\">details...</a>)"; 
        print "</li>\n"; 
     }
     print "</ul>\n"; 
     print "</div>"; 


?>

