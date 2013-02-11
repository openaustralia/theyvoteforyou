<?php require_once "common.inc";
    # $id: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    require_once "database.inc";

	require_once "tablemake.inc";
	require_once "tableoth.inc";

    require_once "parliaments.inc";
    require_once "constituencies.inc";
    require_once "dream.inc";
    require_once "account/user.inc";
    $dbo = new DB();
    $db = new DB();
	global $bdebug;

	update_dreammp_votemeasures($db, null, 0); # for all

    $title = "Policies";
    pw_header();
?>
<p>Policies are stated positions on a particular issue. For example "Privatise
the NHS", or "Join the Euro". Each policy has a definition and a way to
vote in relevant divisions in Parliament.

   <p>This table summarises all policies, including how many times they have
   "voted".  Click on their name to get a comparison of a policy to all MPs.
   <b>You can get a policy to the top by editing and
   correcting motion text for its divisions.</b> </p>
<?php

    print "<table class=\"mps\">\n";
	$dreamtabattr = array("listtype" => 'mainlist',
					      'listlength' => "allpublic", 
						  'headings' => "yes");
	if ($_GET["house"] == "z")
        $dreamtabattr["hitcounter"] = "yes"; 
    $c = print_policy_table($db, $dreamtabattr);
    print "</table>\n";
    print "That makes $c policies which have voted in at least one division.";

?>

<?php pw_footer() ?>
