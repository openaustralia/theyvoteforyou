<?php require_once "common.inc";

# $Id: election.php,v 1.1 2005/04/12 00:36:31 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# http://publicwhip.owl/election.php?i363=0.75&i367=0.75&i258=0.25&i219=0&i230=0.25&i358=0.5&i371=1&mpn=Anne%20Campbell&mpc=Cambridge&submit=Submit

include "db.inc";
include "decodeids.inc";
include "dream.inc";
include "pretty.inc";
$db = new DB();

$ranks = array(
        "strongly for" => 1.0,
        "moderately for" => 0.75,
        "neutral/mixed on" => 0.50,
        "moderately against" => 0.25,
        "strongly against" => 0.0
    );

$issues = array(
		array(363, "introducing <strong>foundation hospitals</strong>", false, "foundation hospital"),
		array(367, "introducing <strong>student top-up fees</strong>", true, "top-up fees"),
        array(258, "Labour's <strong>anti-terrorism laws</strong>", true, "terrorism"),
        array(219, "the <strong>Iraq war</strong>", true, "iraq"),
        array(230, "introducing <strong>ID cards</strong>", true, "id cards"),
        array(358, "the <strong>fox hunting ban</strong>", true, "hunting"),
        array(371, "equal <strong>gay rights</strong>", false, "gay")
    );

$parties = array(
    "Lab" => array("Labour"),
    "Con" => array("Conservative"),
    "LDem" => array("Liberal Democrat"),
    "Lab/Co-op" => array("Labour"),
    "Ind" => array("Independent"),
    "Ind Con" => array("Independent"),
    "Ind Lab" => array("Independent"),
    "Ind UU" => array("Independent"),
    "SF" => array("Sinn Féin"),
    "PC" => array("Plaid Cymru"),
    "DU" => array("DUP"),
    "SDLP" => array("SDLP"),
    "SNP" => array("SNP"),
    "UU" => array("UUP"),
);

?>

<html>
<head>
<title>The Public Whip - How They Voted 2005</title>
<link href="publicwhip.css" type="text/css" rel="stylesheet">

</head>

<body class="election">

<p><img src="../thepublicwhip.gif" alt="The Public Whip">
<br>Counting votes on your behalf</p>

<?
    function opinion_value($value, $curr)
    {
        $ret = "value=\"" . html_scrub($value) . "\" ";
        if ($value === $curr)
        {
            $ret .= "selected ";
        }
        return $ret;
    }


    if ($_GET['submit']) {
        print_r($_GET);
        print "<p>";
    	$mpattr = get_mpid_attr_decode($db, "");
        if ($mpattr == null) {
            $title = "MP not found";
            print "<p>No MP found. If you entered a postcode, please make
                sure it is correct.  Or you can <a href=\"/mps.php\">browse
                all MPs</a>.";
            exit;
        }
        $mpattr = $mpattr['mpprop'];
        print_r($mpattr);
        print "<table border=1>";
        foreach ($issues as $issue) {
            print "<tr>";
            print "<td>" . $issue[1] . "</td>";
            print "<td>" . $yourscore . "</td>";
            $dreamid = $issue[0];
            update_dreammp_person_distance($db, $dreamid);
            $yourscore = floatval($_GET["i$dreamid"]);
            $query = "select avg(distance_a) as dist, party from pw_cache_dreamreal_distance left join pw_mp on pw_mp.person = pw_cache_dreamreal_distance.person where rollie_id = $dreamid group by party";
            $db->query($query);
            $party_dist = array();
            while ($row = $db->fetch_row_assoc()) {
                $dist = $row['dist'];
                if ($issue[2]) {
                    $dist = 1.0 - $dist;
                }
                $canonparty = $parties[$row['party']][0];
                print $row['party'] . " $canonparty <br>";
                $party_dist[$canonparty] += $dist;
            } 
            $temp = array_unique($parties);
            foreach (array_keys($party_dist) as $party) {
                if ($party_dist[$party]) {
                    print "<td>";
                    print $party ."=" . percentise(round($party_dist[$party] * 100, 0));
                    print "</td>";
                }
            }
            print "</tr>";
        }
        print "</table>";
    } else {
?>
<h1>How They Voted 2005</h1>
<p>(and so how you should vote)</p>

<form name="howtovote" method="get" action="election.php">

<p>Choose how you feel about each of these issues.  We'll tell you
how your ex-MP and each party voted on them in parliament over the last
4 years.</p>

<!--<input type="hidden" name="newpost" value="2">-->
<p>
<?
    $firstbr = true;
    foreach ($issues as $issue) {
        if ($firstbr)
            $firstbr = false;
        else
            print '<br>';
        print 'I am <select name="i'.$issue[0].'">' . "\n";
        print "<option value=\"-1\" selected>-- please choose --</option>\n";
        foreach ($ranks as $rank_name => $rank_value) {
            print "<option ";
            print opinion_value($rank_value, "");
            print ">$rank_name</option>\n";
        }
        print "</select> " . $issue[1] .  "\n";
    }
?>
</p>

<p>Your <strong>postcode</strong>: <input type="text" size="10" name="mppc">
 (so we know who your last MP was)</p>

<p><input type="submit" name="submit" value="Submit"></p>
</form>

<p><a href="/">Intead, go to the main Public Whip website</a>
<?
    }
?>

</body>

</html>
