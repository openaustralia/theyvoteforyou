<?php require_once "common.inc";

# $Id: election.php,v 1.8 2005/04/14 09:01:54 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# http://publicwhip.owl/election.php?i363=0.75&i367=0.75&i258=0.25&i219=0&i230=0.25&i358=0.5&i371=1&mpn=Anne%20Campbell&mpc=Cambridge&submit=Submit

# TODO:
# Maybe display anyway when postcode wrong
# Think about dream/person distance, check it works OK
# Do redirect stuff, using interstitial and cookies?

include "db.inc";
include "decodeids.inc";
include "dream.inc";
include "pretty.inc";
include "constituencies.inc";
include "account/user.inc";
$db = new DB();

$ranks = array(
        "strongly for" => 1.0,
        "moderately for" => 0.75,
        "neutral/mixed on" => 0.50,
        "moderately against" => 0.25,
        "strongly against" => 0.0,
        "don't know about" => 0.50,
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

// Name in database => display name
$parties = array(
    "Lab" => "Labour",
    "Con" => "Conservative",
    "LDem" => "Liberal Democrat",
    "Lab/Co-op" => "Labour"
);

$wales_parties = array(
    "PC" => "Plaid Cymru"
);

$scotland_parties = array(
    "SNP" => "SNP", 
);

$northern_ireland_parties = array(
      "SF" => "Sinn Féin",
      "DU" => "DUP",
      "SDLP" => "SDLP",
      "UU" => "UUP", 
);

$independents = array(
    "Ind" => "Independent",
    /* "Ind Con" => "Independent",
    "Ind Lab" => "Independent",
    "Ind UU" => "Independent", */
);

/*print "<pre>";
print count(array_keys($northern_ireland_constituencies));
foreach ($northern_ireland_constituencies as $k) {
    print "\"" . $consmatch[strtolower($k)] . "\" => 1,\n";
}
print "</pre>";*/

function dist_to_desc($dist) {
    if ($dist < 0.125) 
        return "Agree<br>(strong)";
    elseif ($dist < 0.375)
        return "Agree";
    elseif ($dist < 0.625)
        return "Neutral";
    elseif ($dist < 0.875)
        return "Disagree";
    else 
        return "Disagree<br>(strong)";
}

function print_friends_form($word) {
?>
<form name="howtovotefriends" method="post" action="election.php?friend">
<p>Found this useful?  Tell <?=$word?> friend ----&gt;
Your <strong>friend's email</strong>: 
    <input type="text" size="20" name="friendsemail" value="<?=htmlspecialchars($_POST['friendsemail'])?>">
<br><strong>Your name</strong>: 
    <input type="text" size="15" name="yourname" value="<?=htmlspecialchars($_POST['yourname'])?>">
<strong>Your email</strong>: 
    <input type="text" size="20" name="youremail" value="<?=htmlspecialchars($_POST['youremail'])?>">
    <input type="hidden" name="submitfriend" value="1">
    <input type="submit" name="button" value="Tell <?=$word?> Friend">
</p>
</form>
<?
}
    header("Content-Type: text/html; charset=UTF-8");
?>

<html>
<head>
<title>The Public Whip - How They Voted 2005</title>
<link href="publicwhip.css" type="text/css" rel="stylesheet">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

</head>

<body class="election">

<p><img src="../thepublicwhip.gif" alt="The Public Whip">
<br>Counting votes on your behalf</p>

<h1>How They Voted 2005
<br><small>(and so how you should vote)</small>
</h1>

<?
    function opinion_value($value, $curr)
    {
        $ret = "value=\"" . html_scrub($value) . "\" ";
        if ($value === $curr) {
            $ret .= "selected ";
        }
        return $ret;
    }

    $errors = array();
    if ($_GET['submit']) {
        // Display voting records
    	$mpattr = get_mpid_attr_decode($db, "");
        if ($mpattr == null) {
            $errors[] = "Your MP wasn't found.  Please check you
                entered the postcode correctly.";
        }
        foreach ($issues as $issue) {
            $dreamid = $issue[0];
            if (!array_key_exists("i$dreamid", $_GET) || $_GET["i$dreamid"] < 0) {
                $errors[] = "Please select your opinion on " . $issue[1];
            }
        }
    }
    if ($errors) {
        print "<p class=\"error\">";
        print join($errors, "<br>");
        print "</p>";
    }

    if ($_GET['submit'] and !$errors) {
        # See if MP is standing again
        $mpattr = $mpattr['mpprops'][0];
        $mp_party = $parties[$mpattr['party']];
        $constituency = str_replace("&amp;", "&", $mpattr['constituency']);

        $standing_again = false;
        if ($mpattr['leftreason'] == "general_election_standing") {
            $standing_again = true;
        }

        # Regional parties
        $consid = $consmatch[strtolower($constituency)];
        if (!$consid) {
            print "<div class=\"error\">Constituency '$constituency' not found, please <a href=\"team@publicwhip.org.uk\">let us know</a>.</div>";
        }
        if (array_key_exists($consid, $wales_constituencies)) {
            $parties = array_merge($parties, $wales_parties);
        }
        if (array_key_exists($consid, $scotland_constituencies)) {
            $parties = array_merge($parties, $scotland_parties);
        }
        if (array_key_exists($consid, $northern_ireland_constituencies)) {
            $parties = $northern_ireland_parties;
        }  
        if ($consid == "uk.org.publicwhip/cons/655") { // Wyre Forest, Richard Taylor (Ind)
            $parties = array_merge($parties, $independents); 
        }
        $unique_parties = array_values($parties);
        $unique_parties = array_unique($unique_parties);

	#print "<p>MP party $mp_party standing again $standing_again<p>";

        # Go through each issue to extract data
        $distances = array();
        $distances['Comparision'] = array();
        $issuecount = 0;
        foreach ($issues as $issue) {
            $dreamid = $issue[0];
            $distances[$dreamid] = array();
            $issuecount++;

            # Find your score
            $distances[$dreamid]['You'] = 1.0 - floatval($_GET["i$dreamid"]);

            # Find distance from Dream MP to each party
            update_dreammp_person_distance($db, $dreamid);
            $query = "select avg(distance_a) as dist, party from 
pw_cache_dreamreal_distance 
left join pw_mp 
on pw_mp.person = pw_cache_dreamreal_distance.person 
   and left_house = '2005-04-11' 
where rollie_id = $dreamid group by party";
            $db->query($query);
            $party_dist = array();
            while ($row = $db->fetch_row_assoc()) {
                $dist = $row['dist'];
                if ($issue[2])
                    $dist = 1.0 - $dist;
                $canonparty = $parties[$row['party']];
                $party_dist[$canonparty] += $dist;
            } 
            foreach ($unique_parties as $party) {
                $distance = $party_dist[$party];
                if ($distance == null) {
                    $distance = 0.5;
                }
                $distances[$dreamid][$party] = $distance;
                $distances['Comparison'][$party] += abs($distance - $distances[$dreamid]['You']);
            }

            # And for your MP
            $query = "select distance_a as dist from pw_cache_dreamreal_distance
                where rollie_id = $dreamid and person = " . $mpattr['person'];
            $row = $db->query_onez_row_assoc($query);
            $dist = $row ? $row['dist'] : 0.5;
            if ($issue[2])
                $dist = 1.0 - $dist;
            $distances[$dreamid]["Your MP"] = $dist;
            $distances['Comparison']["Your MP"] += abs($dist - $distances[$dreamid]['You']);
        }

# For debugging
#$distances['Comparison']["Your MP"] = 0;
#$distances['Comparison']["Labour"] = 0;
#$standing_again = false;

        # Find who you should vote for
        $best_party = null;
        $best_comparison = 1000000;
        foreach ($distances['Comparison'] as $party => $comparison) {
            # Remove one out of MP's party and MP
            if ($standing_again) {
                if ($party == $mp_party)
                    continue;
            } else {
                if ($party == "Your MP")
                    continue;
            }
            # Test for best
            if ($comparison < $best_comparison) {
                $best_party = $party;
                $best_comparison = $comparison;

            }
        }

        print "<p class=\"advice\">";
        if ($best_party == "Your MP") {
?>
        We recommend you vote for 
        <b><?=$mpattr['name']?> (<?=$mp_party?>)</b> your ex-MP
<?
        } else {
?>
        We recommend you vote <b><?=$best_party?></b> 
<?
        }
        if ($standing_again) {
?>
        <br>&mdash; based on how your ex-MP (who is standing again) 
        and MPs of other parties voted in parliament over the last 4 years, 
        compared to your opinion on these issues</p>
<?
        } else {
?>
        <br>&mdash; based on how MPs of that party voted in parliament over the
        last 4 years, compared to your opinion on these issues
	(your ex-MP isn't standing again, so we haven't specifically used their vote)</p>
<?
        }
        print "</p>";
        //<br>distance $best_comparison
    
        print_friends_form("a");

?>

<p><a href="/">Go to the main Public Whip website</a>
<h1>Detailed Breakdown</h1>

<?

        # Print table
        print "<table class=\"votes\">";
        print "<tr class=\"headings\"><td>Issue</td><td>You</td>";
        foreach ($unique_parties as $party) {
            if ($party == $mp_party and $standing_again) {
                print "<td>$party</td><td>".$mpattr['name']. "<br>(your 
                    $party<br>ex-MP)</td>";
            } else {
                print "<td>$party</td>";
            }
        }
        print "</tr>\n";
        $pretty_row = 0;
        foreach ($issues as $issue) {
            $pretty_row = pretty_row_start($pretty_row);
            $dreamid = $issue[0];
            print "<td><a href=\"dreammp.php?id=$dreamid\">" . $issue[1] . "</a></td>";
            print "<td>" . 
                dist_to_desc($distances[$dreamid]['You']) . " ";
            #print $distances[$dreamid]['You'];
            print "</td>";

            foreach ($unique_parties as $party) {
                print "<td>";
                $distance = $distances[$dreamid][$party];
                print dist_to_desc($distance) . " ";
                #print round($distance,2);
                if ($party == $mp_party and $standing_again) {
                    print " <td><a href=\"mp.php?".$mpattr['mpanchor']."&dmp=$dreamid\">" . 
                        dist_to_desc($distances[$dreamid]['Your MP']) . "</a> ";
                    #print round($distances[$dreamid]['Your MP'],2);
                    print "</td>";
                }
                print "</td>";
            }
            print "</tr>";
        }
        print "<tr class=\"headings\">";
        print "<td>Comparison with your opinion:</td>";
        print "<td>&nbsp;</td>";
        foreach ($unique_parties as $party) {
            $comparison = $distances['Comparison'][$party];
            $comparison /= $issuecount;
            print "<td>"; 
            print dist_to_desc($comparison);
            print "<br>with you";
            #print round($comparison,2);
            print "</td>";
            if ($party == $mp_party and $standing_again) {
                $comparison = $distances['Comparison']['Your MP'];
                $comparison /= $issuecount;
                print "<td>";
                print dist_to_desc($comparison);
                print "<br>with you";
                #print round($comparison,2);
                print "</td>";
            }
        }
        print "</table>";
    }
    elseif ($_POST['submitfriend']) {
        $error = "";
        if (!$_POST['friendsemail'] || !$_POST['yourname'] || !$_POST['youremail']) {
            $error .= "Please enter all details. ";
        } else {
            if (!pw_validate_email($_POST['friendsemail']))
                $error .= "Enter a valid email address for your friend. ";
            if (!pw_validate_email($_POST['youremail']))
                $error .= "Enter a valid email address for yourself. ";
        }
        if ($error) {
            print "<div class=\"error\">
                <h2>Form not complete, please correct and try again</h2>
                $error
                </div>";
            print_friends_form("a");
        } else {
            $message = <<<END
Your friend ${_POST['yourname']} <${_POST['youremail']}> saw this
'how to vote' website and thought of you.

http://www.publicwhip.org.uk/election.php

The site asks your opinion on key issues (such as the Iraq war,
Hunting and Foundation Hospitals).  Then it compares your opinion
with the actual vote in parliament of MPs over the last four
years, and recommends which party you should vote for.

Unlike the parties, we don't have any marketing budget, so
please help us out by forwarding this to any of your friends
who might like it.  We believe that both MPs and parties should
be held to account for how they voted in parliament.

Enjoy the election!

-- The Public Whip team

The Public Whip ( http://www.publicwhip.org.uk ) is a project to
data-mine the voting record of Members of the United Kingdom
Parliament, so that you can hold them to account. 
END;
			$success = mail ($_POST['friendsemail'],'How to vote based on how MPs voted in the last 4 years',$message,'From: The Public Whip <team@publicwhip.org.uk>');
            if ($success) {
                print "<p><span class=\"ptitle\">Mail successfully sent to " .
                    htmlspecialchars($_POST['friendsemail']).
                    "<br>You can send another if you like!</span></p>";
            }
            else {
                print "<div class=\"error\">Failed to send mail</div>";
            }

            $_POST['friendsemail'] = "";
            print_friends_form("another");
?><p><a href="/">Go to the main Public Whip website</a> <?
        }
    } else {
?>

<form name="howtovote" method="get" action="election.php">

<p>Your <strong>postcode</strong>: <input type="text" size="10" name="mppc" value="<?=htmlspecialchars($_GET['mppc'])?>">
 (so we know who your last MP was)</p>

<p>Choose how you feel about each of these issues.  We'll tell you how your<br>
ex-MP and each party voted on them in parliament over the last
4 years.</p>

<!--<input type="hidden" name="newpost" value="2">-->
<p> <center><table border="0">
<?
    foreach ($issues as $issue) {
        print "<tr>";
        print '<td>I am</td><td><select name="i'.$issue[0].'">' . "\n";
        print "<option value=\"-1\" selected>-- please choose --</option>\n";
        foreach ($ranks as $rank_name => $rank_value) {
            print "<option ";
            print opinion_value($rank_value, ($_GET['submit'] ? floatval($_GET['i'.$issue[0]]) : ""));
            print ">$rank_name</option>\n";
        }
        print "</select></td><td>" . $issue[1] .  "</td>\n";
        print "</tr>";
    }
?>
</table></center>
</p>

<input type="hidden" name="submit" value="1">
<p><input type="submit" name="button" value="Submit"></p>
</form>

<p><a href="/">Instead, go to the main Public Whip website</a>

<?
    }
?>

</body>

</html>
