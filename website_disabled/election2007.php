<?php require_once "common.inc";

# $Id: election2007.php,v 1.20 2009/05/19 14:56:08 marklon Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# 2007 General Election special

# TODO:
# Update wales_constituencies etc.
# Sort out postcode lookup for new boundaries
# Error handling of failed postcode lookup don't work
# Update links to other quizes
# Get standing again data, and remove XXX remove me
# Independents - north wales, and george galloway
# Fix shorter URL redirecting
# Maybe display anyway when postcode wrong
# At least say you need javascript
# Question from hell backwards for LRRB

# TODO old:
# Think about dream/person distance, check it works OK
# Do redirect stuff, using interstitial and cookies?

$postcode_year = 2005;
$date_clause = "entered_house <= '2007-11-01' and '2007-11-01' <= left_house";

require_once "db.inc";
require_once "decodeids.inc";
require_once "dream.inc";
require_once "pretty.inc";
require_once "constituencies.inc";
require_once "account/user.inc";

require_once "election2007articles.inc";
require_once "election2007questions.inc";
require_once "election2007constituencies.inc";

$db = new DB();
$db2 = new DB();


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
        array(999, "<strong>investigating</strong> the <strong>Iraq war</strong>", false),
        array(1001, "<strong>Freedom of Information</strong> applying to <strong>MPs</strong>", false),
        array(1002, "<strong>Government</strong> altering the law <strong>without Parliament</strong>",
true),
        array(1000, "the <strong>smoking ban</strong>", false),
        array(1003, "replacing the <strong>Trident nuclear weapons</strong>", false),
        array(1004, "Labour's <strong>anti-terrorism laws</strong>", true),
        array(1005, "introducing <strong>ID cards</strong>", true),
    );

$policystrnum = array("iraq"=>0, "foia"=>1, "lrrb"=>2, "smoking"=>3, "trident"=>4,
    "terrorism"=>5, "idcards"=>6);
$policynumstr = array_flip($policystrnum);

// Name in database => display name
$parties = array(
    "Lab" => "Labour",
    "Con" => "Conservative",
    "LDem" => "Liberal Democrat",
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


/*
// Grab shorter URL if it is one
$qstring = $_SERVER["QUERY_STRING"];
$shorter_url = false;
$mpid = -1;
if (preg_match ("/^(.*);([0-4]+)$/", $qstring, $matches)) {
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
*/

// Validate if a submit
$errors = array();
if ($_GET['submit']) {
    $mpattr = null;
    $constituency = postcode_to_constituency($db, $_GET['mppc'], $postcode_year);
$constituency = "Kirkcaldy &amp; Cowdenbeath"; // XXX temp
    if ($constituency) {
        $row = $db->query_onez_row_assoc("select * from pw_mp where constituency = '$constituency'
            and ($date_clause)");
        if ($row)
            $mpid = $row['mp_id'];
        $mpattr = get_mpid_attr($mpid, false, 1, null);
        if ($mpattr == null) {
            $errors[] = "Your MP wasn't found.  Please check you
                entered the postcode correctly.";
        }
    }
}

// Redirect to shorter URL
/*if ($_GET['submit'] and !$errors and !$shorter_url) {
    $qpc = strtoupper(trim($_GET['mppc']));
    $qpc = str_replace(" ", "", $qpc);
    $quick = "?$qpc;";
    foreach ($issues as $issue) {
        $dreamid = $issue[0];
        $quick .= intval($_GET["i$dreamid"] * 4);
    }

    header("Location: /election2007.php$quick\n");
    return;
}*/

header("Content-Type: text/html; charset=UTF-8");
?>

<html>

<head>
<title>The Public Whip - How They Voted 2007</title>
<link href="quiz/quiz2007.css" type="text/css" rel="stylesheet"/>
<link href="quiz/slider.css" type="text/css" rel="stylesheet"/>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

<script type="text/javascript" src="./quiz/slider.js"></script>

<?php    if ($_GET['submit'] /*and !$errors*/) {

        # See if MP is standing again
        $mpattr = $mpattr['mpprops'][0];
        $constituency = str_replace("&amp;", "&", $mpattr['constituency']);
        $house = $mpattr['house'];

        $standing_again = false;
        if ($mpattr['leftreason'] == "general_election_notstanding") {
            $standing_again = true;
        }
$standing_again = true; # XXX remove me

        # Regional parties
        $consid = normalise_constituency_name(strtolower($constituency), $house, "2001");
        if (!$consid) {
            print "<div class=\"error\">Constituency '$constituency' not found, please <a href=\"team@publicwhip.org.uk\">let us know</a>.</div>";
#            exit;
        } else {
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
        }
        $lookup_parties = $parties;
        if ($standing_again) {
            $lookup_parties["Your MP"] = "Your MP";
            unset($lookup_parties[$mpattr["party"]]);
        }
        $unique_parties = array_keys($lookup_parties);
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
    and $date_clause
where dream_id = $dreamid group by party";
            $db->query($query);
            $party_dist = array();
            while ($row = $db->fetch_row_assoc()) {
                $dist = $row['dist'];
                if ($issue[2])
                    $dist = 1.0 - $dist;
                $party_dist[$row['party']] += $dist;
            } 
            foreach ($unique_parties as $party) {
                $distance = $party_dist[$party];
                if ($distance == null) {
                    $distance = 0.5;
                }
                $distances[$dreamid][$party] = $distance;
                $distances['Comparison'][$party] += abs($distance - $distances[$dreamid]['You']);
            }

            # And for your MP, if you have one
            if ($mpattr) {
                $query = "select distance_a as dist from pw_cache_dreamreal_distance
                    where dream_id = $dreamid and person = " . $mpattr['person'];
                $row = $db->query_onez_row_assoc($query);
                $dist = $row ? $row['dist'] : 0.5;
                if ($issue[2])
                    $dist = 1.0 - $dist;
                $distances[$dreamid]["Your MP"] = $dist;
                $distances['Comparison']["Your MP"] += abs($dist - $distances[$dreamid]['You']);
            }
        }

        // Work out the questions from hell
        if ($mpattr) {
            $polfill = array();
            foreach ($questlistmaps as $questmap)
            {
                $polval = $questmap["policydir"] . $policystrnum[$questmap["issue"]];
                #print "<pre>"; print_r($questmap); print "</pre>";
                if (!$polfill[$polval])
                {
                    #print "<pre>"; print_r($questmap); print "</pre>";
                    # XXX should be only when MP is standing again
                    $divdate = $questmap["date"];
                    $divnum = $questmap["divisionno"];
                    $query = "select vote from pw_vote
                                left join pw_mp on pw_mp.mp_id = pw_vote.mp_id
                                left join pw_division on pw_division.division_id = pw_vote.division_id
                                where pw_mp.person = " . $mpattr['person'] . "
                                and pw_division.division_date = '" . $divdate . "' and pw_division.division_number = " . $divnum . "
                                ";
                    list ($mpvote) = $db->query_onez_row($query);
                    if (!$mpvote)
                        $mpvote = "absent";
                    #print $mpvote . " --> " . $questmap["mpvote"] . "<br>";
                    if ($mpvote == $questmap["mpvote"]) {
                        $polfill[$polval] = 'Why did XXXX '.$questmap["mpposition"]." ".$questmap["question"]."?";

                        $polfill[$polval] .= " This division was on " . date("j M Y");
                    }
                }
            }
        }

?>
<script type="text/javascript">


poswords = ["Extremely against","Strongly against","Moderately against","Slightly against",
                  "Indifferent about",
                  "Slightly for", "Moderately for", "Strongly for", "Extremely for"];

var npolicies = <?php echo count($issues)?>;

weights = [ 0, 1, 3, 6, 10 ];  // from indifferent to extremely

partyvotes = [
<?
     $c = -1;
     foreach ($issues as $issue) {
        $c++;
        print "[";
        foreach ($unique_parties as $party) {
            $distance = $party_dist[$party];
            if ($distance == null) {
                $distance = 0.5;
            }
            // Javascript wants 0 to mean slider on left, 1 to mean slider on right
            print 1.0 - $distances[$issue[0]][$party];

            print ", ";
        }
        print "], \n";
    }
?>
]

partyscores = [ 
<?php foreach ($unique_parties as $party) {
    print "0.0, ";
   }
?>
];

function polgreatestdiff(partychoice)
{
    var policyworst = 0;
    var policyworstdiff = 0;
    for (var i = 0; i < npolicies; i++)
    {
        r = parseInt(document.getElementById('slider-pol' + i).value, 10) || 0;
        rs = (r + 4) * 1.0 / 8;
        var poldiff = Math.abs(partyvotes[i][partychoice] - rs) * Math.abs(r / 4.0);
//        if (i == 2) 
//            alert("i = " + i + " poldiff = " + poldiff + " r = " + r + " rs = " + rs + " pv[i][pc] = " + partyvotes[i][partychoice]);
        if (poldiff >= policyworstdiff)
        {
            policyworst = i;
            policyworstdiff = poldiff;
        }
    }
    return policyworst;
}

function selpol()
{
    for (var j = 0; j < partyscores.length; j++)
        partyscores[j] = 0.0;

    var r;
    var wsum = 0.0;
    for (var i = 0; i < npolicies; i++)
    {
        r = parseInt(document.getElementById('slider-pol' + i).value, 10) || 0;
        document.getElementById('spanpol' + i).innerHTML = poswords[r + 4];
        if (r == 0)
            continue; // no contribution
        partyvote = partyvotes[i];
        tw = weights[(r < 0 ? -r : r)];
        for (var j = 0; j < partyscores.length; j++)  // loop through the parties
        {
            var pr = (partyvote[j] >= 0.5 ? partyvote[j] - 0.5 : 0.5 - partyvote[j]) * 2;
            if ((partyvote[j] > 0.5) == (r > 0))
                partyscores[j] += (pr + 1) * tw;
            else
                partyscores[j] += (1 - pr) * tw;
        }
        wsum += tw * 2;
    }

    var partyfirstnumber = 0, partyfirstpercent = 0;
    var partysecondnumber = 0, partysecondpercent = 0;
    for (var j = 0; j < partyscores.length; j++)
    {
        s = (wsum != 0.0 ? partyscores[j] / wsum : 0.5);
        sp = Math.round(s * 200);
        if (sp < 1)
            sp = 1;
        document.getElementById('party' + j).style["width"] = sp + "px";
        // document.getElementById('howtheyvoted').innerHTML = j + " " + sp;
        pp = Math.round(partyscores[j] * 100);
        wsp = Math.round(wsum * 100);
        //document.getElementById('party' + j).innerHTML = pp + " / " + wsp;

        if (sp >= partyfirstpercent)
        {
            partysecondnumber = partyfirstnumber;
            partysecondpercent = partyfirstpercent;

            partyfirstnumber = j;
            partyfirstpercent = sp;
        }

        else if (sp >= partysecondpercent)
        {
            partysecondnumber = j;
            partysecondpercent = sp;
        }
    }

    // document.getElementById('partychoice').innerHTML = document.getElementById('partyname' + partyfirstnumber).innerHTML;
    // document.getElementById('partychoicepercent').innerHTML = partyfirstpercent + "%";

    // document.getElementById('partychoicesecond').innerHTML = document.getElementById('partyname' + partysecondnumber).innerHTML;
    // document.getElementById('partychoicesecondpercent').innerHTML = partysecondpercent + "%";

//    polworst = polgreatestdiff(partyfirstnumber);
    polworst = polgreatestdiff(partyscores.length - 1);
// polworst = 1; // hack to choose policy type
// document.getElementById('policyworst').innerHTML = document.getElementById('polname' + polworst).innerHTML;

    for (var i = 0; i < npolicies; i++) {
        d1 = document.getElementById('policy' + '-against' + i);
        d2 = document.getElementById('policy' + '-for' + i);
        if (i == polworst) {
            r = parseInt(document.getElementById('slider-pol' + i).value, 10) || 0;
            if (d1) 
                d1.style.visibility = (r < 0 ? "visible" : "hidden");
            if (d2)
                d2.style.visibility = (r > 0 ? "visible" : "hidden");
        } else {
            if (d1) 
                d1.style.visibility = "hidden";
            if (d2)
                d2.style.visibility = "hidden";
        }
    }
}

// Demo specific onload event (uses the addEvent method bundled with the slider)
//fdSliderController.addEvent(window, 'load', createColorBox);

//]]>
</script>
<?php } ?>

</head>
<?
    // Display the main page
    if ($_GET['submit'] /*and !$errors*/) {
?>
<body>
<div id="divQuizResults">
<h1><a href="/"><span class="fir">The Public Whip</span></a></h1>
<h2 id="howtheyvoted">How They Voted 2007</h2>
<h3>(...and so how you should)</h3>
<h4>Quick Election Quiz</h4>
<?
    if ($errors) {
        print "<p class=\"error\">";
        print join($errors, "<br>");
        print "</p>";
    }
?>
<?

        //print "<p class=\"advice\">";
        //print "</p>";
?>
        <div>
        <div class="policypanel" style="width:60em">
        <h5>Your views</h5>
        <table>
  
<?php
     $c = -1;
     foreach ($issues as $issue) {
        $c++;
?>
        <tr><td><input name="sliderpol<?php echo $c?>" id="slider-pol<?php echo $c?>" type="text" title="silly title" class="fd_range_-4_4 fd_classname_polslider fd_hide_input fd_callback_selpol" value="0" /></td>
            <td id="spanpol<?php echo $c?>" class="sliderposword">XXX</td>
            <td id="polname<?php echo $c?>"><?php echo $issue[1]?></td>
        </tr>
<?
    }
?>
        </table>

        <h5>Did they vote in Parliament how you wanted?</h5>
        <div class="partytableholder">
        <table class="partytable">
        <tr>
        <td>
        </td>
        <td>
        <div style="width: 200px">
        <span style="float: left">
        0%
        </span>
        <span style="float: right">
        100%
        </span>
        </div>
        </td>
        </tr>

        <?php
            $c = -1;
            foreach ($unique_parties as $party) {
                print "<tr>";
                $c++;
                if ($party == "Your MP") 
                    $display_party = $mpattr['name'] . " ex-MP<br>(" . $parties[$mpattr['party']] . ")";
                else
                    $display_party = $parties[$party];
                print '<td class="partyheadings" id="partyname'.$c.'">'.$display_party.'</td>';

                if ($party == "Your MP") 
                    $col = party_to_colour($mpattr['party']);
                else
                    $col = party_to_colour($party);
                print '<td><div id="party'.$c.'" style="width:0px; height:40px; ; background: '.$col.'; "></div></td>';
                print "</tr>";
            }
        ?>
        </table>
        </div>

<!--        <tr style="height:110px; vertical-align:bottom;"> -->

        <!-- <td id="recview">Public Whip recommends you vote
        <center><span id="partychoice">YYY</span></center>
        as it matches your political opinion by
        <span id="partychoicepercent">ZZ%</span>.
        -->
        <!--Your second choice
        <span id="partychoicesecond">YYY</span> matches you by
        <span id="partychoicesecondpercent">ZZ%</span>.-->
        </td>
        </tr>
        </table>
        </div>
        <!--<p id="worstmatching">The worst matching policy is: <span id="policyworst">PPP</span></p>-->

        <div class="question_from_hell">
<?
        foreach ($polfill as $code => $text) {
            print '<div class="floating_question" id="'.$code.'" style="position:absolute">';
            print "<h5>Question from Hell</h5>";
            $text = str_replace("XXXX", "<strong>".$mpattr["name"]."</strong>", $text);
            print $text;
            print "<p><em>Ask this when irksome ".$parties[$mpattr["party"]]." people knock on your door, or to your former MP at a local hustings.</em>";
            $issue = str_replace("policy-against", "", str_replace("policy-for", "", $code));
            if ($newsarticles[$policynumstr[intval($issue)]]) {
                foreach ($newsarticles[$policynumstr[intval($issue)]] as $id => $newsarticle)
                    print '<p>'.StrArticle($newsarticle).'</p>';
            }

            print "</div>";
        }
?>
        </div>
        <br>
        <br>
        <br>
        <br>
        <br>

        </div>

<p class="links">
<b>Questions?</b> Email <a href="mailto:team@publicwhip.org.uk">team@publicwhip.org.uk</a> 
<b>Media enquiries?</b>  Ring Francis Irving on 07970 543358.
<br><a href="election2007.php">Change postcode</a> <em>or</em>
<a href="/">Go to the main Public Whip website</a>
</p>

        <script type="text/javascript">
        //<![CDATA[

        // Calling the construct() method here as were using an object method as a callback and I want to be sure that
        // the slider object exists when the onload event fires (for Internet Explorers benefit as usual)
        // You dont have to call the construct in this way if your using plain-jane functions as a callback
        // You can always use your preferred onDOMContentLoaded function e.g. jQuery's $(document).ready or YAHOO's onDocumentReady event
        fdSliderController.construct();
        selpol();

        //]]>
        </script>
<?

    } else {
?>
<body>
<div id="divQuizResults">
<h1><a href="/"><span class="fir">The Public Whip</span></a></h1>
<h2>How They Voted 2007</h2>
<h3>(...and so how you should)</h3>
<h4>Quick Election Quiz</h4>
<form id="frmHowToVote" name="howtovote" method="get" action="election2007.php">

Enter your UK <strong>postcode</strong>: <input type="text" size="10" name="mppc" value="<?php echo htmlspecialchars($_GET['mppc'])?>" id="Text1"> <br/>
(so we know who your last <abbr title="Member of Parliament">MP</abbr> was)

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
