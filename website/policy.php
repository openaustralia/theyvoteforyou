<?php require_once "common.inc";

    # $id: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include('database.inc');
    $db = new DB();

	# standard decoding functions for the url attributes
	include "decodeids.inc";
	include "tablemake.inc";

    include "render.inc";
    include "dream.inc";
	include "tablepeop.inc";

	# this replaces a lot of the work just below
	$voter = get_dreammpid_attr_decode($db, "id");  # for pulling a dreammpid from id= rather than the more standard dmp=
    $policyname = html_scrub($voter["name"]);
	$dreamid = $voter["dreammpid"];

    $title = "Policy - $policyname";

	# constants
	$dismodes = array();
	$dismodes["summary"] = array("dtype"	=> "summary",
								 "description" => "Votes",
								 "comparisons" => "yes",
								 "divisionlist" => "selected",
								 "policybox" => "yes");
	$dismodes["everyvote"] = array("dtype"	=> "everyvote",
								   "divisionlist" => "all",
							 	   "description" => "Every division");

	# work out which display mode we are in
	$display = $_GET["display"];
	if (!$dismodes[$display])
		$display = "summary"; # default
	$dismode = $dismodes[$display];

    # make list of links to other display modes
    $second_links = array();
    foreach ($dismodes as $ldisplay => $ldismode)
    {
        $leadch = " | ";
        $dlink = "href=\"policy.php?id=".$dreamid.($ldisplay != "summary" ? "&display=$ldisplay" : "")."\"";
        array_push($second_links, "<a $dlink class=\"".($ldisplay == $display ? "on" : "off")."\">".$ldismode["description"]."</a>");
    }

    include "header.inc";

	if ($dismode["policybox"])
	{
		print "<div class=\"tabledreambox\">";
	    print dream_box($dreamid, $policyname);
	    print '<p>Why not <a href="#dreambox">add this to your own website?</a></p>';
	    print "</div>";
	}

    print "<p><b>Definition:</b> " . str_replace("\n", "<br>", html_scrub($voter["description"])). "</p>";
    if ($voter["private"])
        print "<p><b>Made by:</b> " . html_scrub($voter["user_name"]) . " (this is a legacy Dream MP)";
    print "</p>";

    print "<p><a href=\"account/editpolicy.php?id=$dreamid\">Edit definition</a>";
    $discuss_url = dream_post_forum_link($db, $dreamid);
    if (!$discuss_url) {
        // First time someone logged in comes along, add policy to the forum
        global $domain_name;
        if (user_getid()) {
            dream_post_forum_action($db, $dreamid, "Policy introduced to forum.\n\n[b]Name:[/b] [url=http://$domain_name/policy.php?id=".$dreamid."]".$policyname."[/url]\n[b]Definition:[/b] ".$voter['description']);
            $discuss_url = dream_post_forum_link($db, $dreamid);
        } else {
            print ' | <a href="http://'.$domain_name.'/forum/viewforum.php?f=1">Discuss</a>';
        }
    }
    if ($discuss_url)
        print ' | <a href="'.htmlspecialchars($discuss_url).'">Discuss changes</a>';

	if ($dismode["divisionlist"] == "selected")
	{
		print "<h2><a name=\"divisions\">Selected Divisions</a></h2>
	    <p>Divisions which have been selected for this policy.";
	    if ($voter["votes_count"])
	        print " <b>".$voter["votes_count"]."</b> votes, of which <b>".$voter["edited_count"]."</b> have edited motion text.";
		else
		print "</p>\n";
        if (user_getid()) {
            $db->query("update pw_dyn_user set active_policy_id = $dreamid where user_id = " . user_getid());
            print "<p>This is now your active policy; to select other votes for this policy, go to any division page.";
        }
	}
	else
	{
		print "<h2><a name=\"divisions\">Every Division</a></h2>\n";
	}

    print "<table class=\"divisions\">\n";
	$divtabattr = array(
			"voter1type" 	=> "dreammp",
			"voter1"        => $dreamid,
			"showwhich"		=> ($dismode["divisionlist"] == "selected" ? "all1" : "everyvote"),
			"headings"		=> 'columns',
			"divhrefappend"	=> "&dmp=$dreamid", # gives link to crossover page
			"motionwikistate" => "listunedited");
	division_table($db, $divtabattr);
    print "</table>\n";

/*    print "You need to select which votes support your policy.
    To do this <a href=\"search.php\">search</a> or <a
    href=\"divisions.php\">browse</a> for divisions.  On the page for each
    division you can choose how someone supporting your policy would have
    voted.  Only vote on divisions which are relevant to your policy."; */

	if ($dismode["comparisons"])
	{
	    print "<h2><a name=\"comparison\">Comparison to MPs</a></h2>";

	    print "<p>Grades MPs acording to how often they voted with the policy.
	            If, in policy divisions where the MP voted, they
	            always voted the same as the policy then the score is 0.0.  If they always voted
	            differently, the score is 1.0.";

		$mptabattr = array("listtype" => 'dreamdistance',
						   'dreammpid' => $dreamid);
		print "<table class=\"mps\">\n";
		print "<tr class=\"headings\"><td>Name</td><td>Constituency</td><td>Party</td><td>Distance</td></tr>\n";
		mp_table($db, $mptabattr);
		print "</table>\n";
	}

	if ($dismode["policybox"])
	{
	    print '<h2><a name="dreambox">Add Policies to Your Website</a></h2>';
	    print '<p>Get people thinking about your issue, by adding a policy search
				box to your website.  This lets people compare their own MP to your policy,
				like this.</p>';
	    print dream_box($dreamid, $policyname);
	    print '<p>To do this copy and paste the following HTML into your website.
				Feel free to fiddle with it to fit the look of your site better.  We only
				ask that you leave the link to Public Whip in.';
	    print '<pre class="htmlsource">';
	    print htmlspecialchars(dream_box($dreamid, $policyname));
	    print '</pre>';
	}
?>

<?php include "footer.inc" ?>

