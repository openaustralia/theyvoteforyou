<?php require_once "common.inc";
pw_header();
print '<h1>Sorry, the 2005 "how they voted" election quiz is no longer available (basically, we can no longer lookup 2005 postcodes to constituency boundaries to find who your MP was: plus the election happened quite some time ago).</h1>';
pw_footer();
exit();

# $Id: election.php,v 1.27 2009/05/19 14:56:08 marklon Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# 2005 General Election special

# TODO:
# Maybe display anyway when postcode wrong
# Think about dream/person distance, check it works OK
# Do redirect stuff, using interstitial and cookies?

require_once "db.inc";
require_once "decodeids.inc";
require_once "dream.inc";
require_once "pretty.inc";
require_once "constituencies.inc";
require_once "account/user.inc";
$db = new DB();
$db2 = new DB();

$wales_constituencies = array(
    "uk.org.publicwhip/cons/1" => 1,
    "uk.org.publicwhip/cons/9" => 1,
    "uk.org.publicwhip/cons/61" => 1,
    "uk.org.publicwhip/cons/79" => 1,
    "uk.org.publicwhip/cons/85" => 1,
    "uk.org.publicwhip/cons/104" => 1,
    "uk.org.publicwhip/cons/105" => 1,
    "uk.org.publicwhip/cons/112" => 1,
    "uk.org.publicwhip/cons/113" => 1,
    "uk.org.publicwhip/cons/114" => 1,
    "uk.org.publicwhip/cons/115" => 1,
    "uk.org.publicwhip/cons/117" => 1,
    "uk.org.publicwhip/cons/118" => 1,
    "uk.org.publicwhip/cons/124" => 1,
    "uk.org.publicwhip/cons/139" => 1,
    "uk.org.publicwhip/cons/140" => 1,
    "uk.org.publicwhip/cons/147" => 1,
    "uk.org.publicwhip/cons/163" => 1,
    "uk.org.publicwhip/cons/168" => 1,
    "uk.org.publicwhip/cons/255" => 1,
    "uk.org.publicwhip/cons/311" => 1,
    "uk.org.publicwhip/cons/351" => 1,
    "uk.org.publicwhip/cons/368" => 1,
    "uk.org.publicwhip/cons/370" => 1,
    "uk.org.publicwhip/cons/383" => 1,
    "uk.org.publicwhip/cons/384" => 1,
    "uk.org.publicwhip/cons/389" => 1,
    "uk.org.publicwhip/cons/398" => 1,
    "uk.org.publicwhip/cons/399" => 1,
    "uk.org.publicwhip/cons/440" => 1,
    "uk.org.publicwhip/cons/457" => 1,
    "uk.org.publicwhip/cons/462" => 1,
    "uk.org.publicwhip/cons/473" => 1,
    "uk.org.publicwhip/cons/569" => 1,
    "uk.org.publicwhip/cons/570" => 1,
    "uk.org.publicwhip/cons/582" => 1,
    "uk.org.publicwhip/cons/595" => 1,
    "uk.org.publicwhip/cons/596" => 1,
    "uk.org.publicwhip/cons/653" => 1,
    "uk.org.publicwhip/cons/658" => 1,
);

$scotland_constituencies = array(
    "uk.org.publicwhip/cons/2" => 1,
    "uk.org.publicwhip/cons/3" => 1,
    "uk.org.publicwhip/cons/4" => 1,
    "uk.org.publicwhip/cons/5" => 1,
    "uk.org.publicwhip/cons/11" => 1,
    "uk.org.publicwhip/cons/12" => 1,
    "uk.org.publicwhip/cons/18" => 1,
    "uk.org.publicwhip/cons/20" => 1,
    "uk.org.publicwhip/cons/106" => 1,
    "uk.org.publicwhip/cons/119" => 1,
    "uk.org.publicwhip/cons/122" => 1,
    "uk.org.publicwhip/cons/141" => 1,
    "uk.org.publicwhip/cons/142" => 1,
    "uk.org.publicwhip/cons/143" => 1,
    "uk.org.publicwhip/cons/160" => 1,
    "uk.org.publicwhip/cons/161" => 1,
    "uk.org.publicwhip/cons/162" => 1,
    "uk.org.publicwhip/cons/181" => 1,
    "uk.org.publicwhip/cons/182" => 1,
    "uk.org.publicwhip/cons/183" => 1,
    "uk.org.publicwhip/cons/184" => 1,
    "uk.org.publicwhip/cons/185" => 1,
    "uk.org.publicwhip/cons/186" => 1,
    "uk.org.publicwhip/cons/196" => 1,
    "uk.org.publicwhip/cons/198" => 1,
    "uk.org.publicwhip/cons/204" => 1,
    "uk.org.publicwhip/cons/207" => 1,
    "uk.org.publicwhip/cons/208" => 1,
    "uk.org.publicwhip/cons/209" => 1,
    "uk.org.publicwhip/cons/212" => 1,
    "uk.org.publicwhip/cons/210" => 1,
    "uk.org.publicwhip/cons/211" => 1,
    "uk.org.publicwhip/cons/225" => 1,
    "uk.org.publicwhip/cons/226" => 1,
    "uk.org.publicwhip/cons/238" => 1,
    "uk.org.publicwhip/cons/242" => 1,
    "uk.org.publicwhip/cons/243" => 1,
    "uk.org.publicwhip/cons/244" => 1,
    "uk.org.publicwhip/cons/245" => 1,
    "uk.org.publicwhip/cons/246" => 1,
    "uk.org.publicwhip/cons/247" => 1,
    "uk.org.publicwhip/cons/248" => 1,
    "uk.org.publicwhip/cons/249" => 1,
    "uk.org.publicwhip/cons/250" => 1,
    "uk.org.publicwhip/cons/251" => 1,
    "uk.org.publicwhip/cons/253" => 1,
    "uk.org.publicwhip/cons/260" => 1,
    "uk.org.publicwhip/cons/269" => 1,
    "uk.org.publicwhip/cons/270" => 1,
    "uk.org.publicwhip/cons/306" => 1,
    "uk.org.publicwhip/cons/316" => 1,
    "uk.org.publicwhip/cons/322" => 1,
    "uk.org.publicwhip/cons/344" => 1,
    "uk.org.publicwhip/cons/350" => 1,
    "uk.org.publicwhip/cons/379" => 1,
    "uk.org.publicwhip/cons/385" => 1,
    "uk.org.publicwhip/cons/388" => 1,
    "uk.org.publicwhip/cons/411" => 1,
    "uk.org.publicwhip/cons/420" => 1,
    "uk.org.publicwhip/cons/439" => 1,
    "uk.org.publicwhip/cons/444" => 1,
    "uk.org.publicwhip/cons/448" => 1,
    "uk.org.publicwhip/cons/449" => 1,
    "uk.org.publicwhip/cons/452" => 1,
    "uk.org.publicwhip/cons/481" => 1,
    "uk.org.publicwhip/cons/485" => 1,
    "uk.org.publicwhip/cons/548" => 1,
    "uk.org.publicwhip/cons/559" => 1,
    "uk.org.publicwhip/cons/588" => 1,
    "uk.org.publicwhip/cons/619" => 1,
    "uk.org.publicwhip/cons/632" => 1,
    "uk.org.publicwhip/cons/627" => 1,
);

$northern_ireland_constituencies = array(
    "uk.org.publicwhip/cons/35" => 1,
    "uk.org.publicwhip/cons/36" => 1,
    "uk.org.publicwhip/cons/37" => 1,
    "uk.org.publicwhip/cons/38" => 1,
    "uk.org.publicwhip/cons/192" => 1,
    "uk.org.publicwhip/cons/197" => 1,
    "uk.org.publicwhip/cons/231" => 1,
    "uk.org.publicwhip/cons/235" => 1,
    "uk.org.publicwhip/cons/325" => 1,
    "uk.org.publicwhip/cons/375" => 1,
    "uk.org.publicwhip/cons/400" => 1,
    "uk.org.publicwhip/cons/402" => 1,
    "uk.org.publicwhip/cons/406" => 1,
    "uk.org.publicwhip/cons/515" => 1,
    "uk.org.publicwhip/cons/519" => 1,
    "uk.org.publicwhip/cons/557" => 1,
    "uk.org.publicwhip/cons/593" => 1,
    "uk.org.publicwhip/cons/629" => 1,
);


$ranks = array(
        "strongly for" => 1.0,
        "moderately for" => 0.75,
        "neutral/mixed on" => 0.50,
        "moderately against" => 0.25,
        "strongly against" => 0.0,
        "don't know about" => 0.50,
    );

# Commented out ids are the original Dream MPs now turned into policies.
# Uncommented out ones are frozen Dream MPs copied from election time.
$issues = array(
	array(828 /*363*/, "<strong>foundation hospitals</strong>", false, "foundation hospital"),
	array(829 /*367*/, "<strong>student top-up fees</strong>", true, "top-up fees"),
        array(830 /*258*/, "Labour's <strong>anti-terrorism laws</strong>", true, "terrorism"),
        array(831 /*219*/, "the <strong>Iraq war</strong>", true, "iraq"),
        array(832 /*230*/, "introducing <strong>ID cards</strong>", true, "id cards"),
        array(833 /*358*/, "the <strong>ban on fox hunting</strong>", true, "hunting"),
        array(834 /*371*/, "equal <strong>gay rights</strong>", false, "gay")
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
    print "\"" . normalise_constituency_name(strtolower($k)) . "\" => 1,\n";
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

function our_number_format($number) {
    return round((1.0-$number) * 100) . "%";
}

function print_friends_form($word) {
?>
<form id="howtovotefriends" name="howtovotefriends" method="post" action="election.php?friend">
<p>Found this useful?  <strong>Pass it on</strong>
<br>Your <strong>friend's email</strong>: 
    <input type="text" size="20" name="friendsemail" value="<?php echo htmlspecialchars($_POST['friendsemail'])?>">
<br>Your name: 
    <input type="text" size="20" name="yourname" value="<?php echo htmlspecialchars($_POST['yourname'])?>">
<br>Your email: 
    <input type="text" size="20" name="youremail" value="<?php echo htmlspecialchars($_POST['youremail'])?>">
    <input type="hidden" name="submitfriend" value="1">
<br>    <input type="submit" name="button" value="Tell <?php echo $word?> Friend">
<br><small>(privacy: we will not store your email or your friend's email, we
will only use it to send your message to your friend)</small> </p>
</form>
<?
}

function opinion_value($value, $curr)
{
    $ret = "value=\"" . html_scrub($value) . "\" ";
    if ($value === $curr) {
        $ret .= "selected ";
    }
    return $ret;
}

// Grab shorter URL if it is one
$qstring = $_SERVER["QUERY_STRING"];
$shorter_url = false;
$mpid = -1;
if (preg_match ("/^(.*);([0-4]{7})$/", $qstring, $matches)) {
    $_GET = array();
    $_GET['submit'] = "1";
    $_GET['mppc'] = $matches[1];
    $c = 0;
    foreach ($issues as $issue) {
        $dreamid = $issue[0];
        $_GET["i$dreamid"] = floatval(substr($matches[2], $c, 1)) / 4.0;
        $c++;
    }
    $shorter_url = true;
}

// Validate if a submit
$errors = array();
if ($_GET['submit']) {
    $constituency = postcode_to_constituency($db, $_GET['mppc'], "2001");
    $row = $db->query_onez_row_assoc("select * from pw_mp where constituency = '$constituency' 
        and entered_house <= '2005-04-11' and '2005-04-11' <= left_house");
    if ($row)
        $mpid = $row['mp_id'];
    $mpattr = get_mpid_attr($mpid, false, 1, null);
    if ($mpattr == null) {
        $errors[] = "Your MP wasn't found.  Please check you
            entered the postcode correctly.";
    }
    foreach ($issues as $issue) {
        $dreamid = $issue[0];
        if (!array_key_exists("i$dreamid", $_GET) || $_GET["i$dreamid"] < 0) {
            $errors[] = "Please select your opinion on " . $issue[1] . ".";
        }
    }
}

// Redirect to shorter URL
if ($_GET['submit'] and !$errors and !$shorter_url) {
    $qpc = strtoupper(trim($_GET['mppc']));
    $qpc = str_replace(" ", "", $qpc);
    $quick = "?$qpc;";
    foreach ($issues as $issue) {
        $dreamid = $issue[0];
        $quick .= intval($_GET["i$dreamid"] * 4);
    }

    header("Location: /election.php$quick\n");
    return;
}

header("Content-Type: text/html; charset=UTF-8");
?>

<html>

<head>
<title>The Public Whip - How They Voted 2005</title>
<link href="quiz/quiz.css" type="text/css" rel="stylesheet"/>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

</head>
<?
    if ($_GET['submit'] and !$errors) {
        # See if MP is standing again
        $mpattr = $mpattr['mpprops'][0];
        $constituency = str_replace("&amp;", "&", $mpattr['constituency']);
        $house = $mpattr['house'];

        $standing_again = false;
        if ($mpattr['leftreason'] == "general_election_standing") {
            $standing_again = true;
        }

        # Regional parties
        $consid = normalise_constituency_name(strtolower($constituency), $house, "2001");
        if (!$consid) {
            print "<div class=\"error\">Constituency '$constituency' not found, please <a href=\"team@publicwhip.org.uk\">let us know</a>.</div>";
            exit;
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
        $mp_party = $parties[$mpattr['party']];

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
where dream_id = $dreamid group by party";
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
                where dream_id = $dreamid and person = " . $mpattr['person'];
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
?>
<body>
<div id="divQuizResults">
<h1><a href="/"><span class="fir">The Public Whip</span></a></h1>
<h2>How They Voted 2005</h2>
<h3>(...and so how you should)</h3>
<h4>Quick Election Quiz</h4>
<?

        print "<p class=\"advice\">";
        if ($best_party == "Your MP") {
?>
        The Public Whip suggests you vote for 
        <b><?php echo $mpattr['name']?> (<?php echo $mp_party?>)</b>, your ex-MP
	in <?php echo $constituency?>.
<?
        } else {
?>
        The Public Whip suggests you vote <b><?php echo $best_party?></b>
	in <?php echo $constituency?>.
<?
        }
        if ($standing_again) {
?>
        This is based on how your ex-MP (who is standing again) 
        and MPs of other parties voted in parliament over the last 4 years, 
        compared to your opinion on these issues. </p>
<?
        } else {
?>
        This is based on how MPs of that party voted in parliament over the
        last 4 years, compared to your opinion on these issues.
	Your ex-MP isn't standing again, so we haven't specifically used their vote.
    </p>
<?
        }
        print "</p>";
        //<br>distance $best_comparison
    
        print_friends_form("a");

?>

<p class="links">
<b>Questions?</b> Email <a href="mailto:team@publicwhip.org.uk">team@publicwhip.org.uk</a> 
<b>Media enquiries?</b>  Ring Francis Irving on 07970 543358.
</p>

<p class="links">
We recommend you <b>look at other sources</b> before deciding how to vote.  
You might like to take the <a href="http://www.politicalsurvey2005.com/">Political
Survey 2005</a> (more detailed and based on opinion poll data), 
or use <a href="http://www.howtovote.co.uk/">how2vote</a> (which asks you
which of different manifesto policies you prefer).  For more detail <a
href="http://www.theywanttobeelected.com/manifestos/">read and annotate the
manifestos</a>, or get a useful opinion poll trend graph and links from
<a href="http://election.beasts.org/">election.beasts.org</a>.
</p>

<p class="links">
<a href="election.php">Take the Public Whip quiz again</a> <em>or</em>
<a href="/">Go to the main Public Whip website</a>
</p>

<h5>Detailed Breakdown</h5>
<p>How we worked out who you should vote for.
<?

        # Print table
        print "<table id=\"tblResult\" class=\"votes\" >";
        print "<tr class=\"headings\"><th>Issue (numbers are from <br>100% agrees
strongly to <br>0% disagrees strongly)</th><th>You</th>";
        foreach ($unique_parties as $party) {
            if ($party == $mp_party and $standing_again) {
                print "<th>$party</th><th>".$mpattr['name']. "<br>(your 
                    $party<br>ex-MP)</th>";
            } else {
                print "<th>$party</th>";
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
            print our_number_format($distances[$dreamid]['You']);
            print "</td>";

            foreach ($unique_parties as $party) {
                print "<td>";
                $distance = $distances[$dreamid][$party];
                print dist_to_desc($distance) . " ";
                print our_number_format($distance);
                if ($party == $mp_party and $standing_again) {
                    print " <td><a href=\"mp.php?".$mpattr['mpanchor']."&dmp=$dreamid&display=motions\">" . 
                        dist_to_desc($distances[$dreamid]['Your MP']) . "</a> ";
                    print our_number_format($distances[$dreamid]['Your MP']);
                    print "</td>";
                }
                print "</td>";
            }
            print "</tr>";
        }
        print "<tr class=\"last\">";
        print "<td>Comparison with your opinion:
	 <br>100% voted same as your view
	 <br>0% voted opposite to your view</td>";
        print "<td>&nbsp;</td>";
        foreach ($unique_parties as $party) {
            $comparison = $distances['Comparison'][$party];
            $comparison /= $issuecount;
            print "<td>"; 
            print dist_to_desc($comparison);
            print "<br>with you ";
            print our_number_format($comparison);
            print "</td>";
            if ($party == $mp_party and $standing_again) {
                $comparison = $distances['Comparison']['Your MP'];
                $comparison /= $issuecount;
                print "<td>";
                print dist_to_desc($comparison);
                print "<br>with you ";
                print our_number_format($comparison);
                print "</td>";
            }
        }
        print "</table>";
?>
<p>This table shows how members of each parliamentary party voted on each issue
in parliament between 2001 and 2005.  These are averages for each party.  So,
Labour comes out as only "agree" on many issues, rather than "agree
(strong)", because many members rebelled on these controversial issues.
Follow the link for each issue to find out more about which votes we used
to do this calculation.  The links in your ex-MP's column (if they are standing
again) will take you to a detailed breakdown of how they voted on the issue.
</p>
<p>The last row shows how each party compares to you.  The difference between
you and the party on each each is summed up and averaged.  100% means you 
exactly agree with how the party voted, 0% means you exactly disagree.
Each issue is given equal weight, although if you were neutral on an issue
it will naturally score less.  The party which we suggest you vote for (above)
has the largest value in this bottom row.
</p>
<?
    }
    elseif ($_POST['submitfriend']) {
?>
<body>
<div id="divQuizResults">
<h1><a href="/"><span class="fir">The Public Whip</span></a></h1>
<h2>How They Voted 2005</h2>
<h3>(...and so how you should)</h3>
<h4>Quick Election Quiz</h4>

<?
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
            print "<p class=\"error\">
                Form not complete, please correct and try again.  
                $error
                </p>";
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
                print "<p class=\"advice\">Mail successfully sent to ".
                    htmlspecialchars($_POST['friendsemail']).
                    "</p><p class=\"advice\">You can send another if you like!</p>";
            }
            else {
                print "<div class=\"error\">Failed to send mail</div>";
            }

            $_POST['friendsemail'] = "";
            print_friends_form("another");
?>
<p class="links"><a href="election.php">Take the quiz again</a> <em>or</em>
<a href="/">Go to the main Public Whip website</a> </p>
</div>
<?
        }
    } else {
?>
<body>
<div id="frmHowToVote">
<form name="howtovote" method="get" action="election.php">
<h1><a href="/"><span class="fir">The Public Whip</span></a></h1>
<h2>How They Voted 2005</h2>
<h3>(...and so how you should)</h3>
<h4>Quick Election Quiz</h4>
<?
    if ($errors) {
        print "<p class=\"error\">";
        print join($errors, "<br>");
        print "</p>";
    }
?>

<ol id="olQuiz">
	<li>
			Enter your UK <strong>postcode</strong>: <input type="text" size="10" name="mppc" value="<?php echo htmlspecialchars($_GET['mppc'])?>" id="Text1"> <br/>
			(so we know who your last <abbr title="Member of Parliament">MP</abbr> was)
	</li>
	<li>
		<p>
			Choose how you feel about each of these issues.  We'll tell you how your ex-<abbr title="Member of Parliament">MP</abbr> and each party voted on them in parliament over the last 4 years.
		</p>
		
		<ul id="ulQuestions">


<?
    foreach ($issues as $issue) {
        print "<li>";
        print 'I am <select name="i'.$issue[0].'">' . "\n";
        print "<option value=\"-1\" selected>-- please choose --</option>\n";
        foreach ($ranks as $rank_name => $rank_value) {
            print "<option ";
            print opinion_value($rank_value, ($_GET['submit'] ? floatval($_GET['i'.$issue[0]]) : ""));
            print ">$rank_name</option>\n";
        }
        print "</select>" . $issue[1] .  "\n";
        print "</li>";
    }
?>

		</ul>

	</li>
</ol>

<input id="submit" name="submit" type="hidden"  value="1">

<div id="submit"><input type="submit" name="button" value="Submit" id="button"></div>

<p id="pPoweredBy">
Powered by <a href="http://www.publicwhip.org.uk" title="Go to the main Public Whip website">The Public Whip</a>
</p>

</form>

</div>
</body>
<?
    }
?>

</html>
