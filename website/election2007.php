<?php require_once "common.inc";

# $Id: election2007.php,v 1.10 2007/10/03 00:47:37 publicwhip Exp $

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
        array(999, "<strong>investigating</strong> the <strong>Iraq war</strong>", false),
        array(996, "<strong>Freedom of Information</strong> applying to <strong>MPs</strong>", false), # XXX not 2007 specific
        array(863, "<strong>Government</strong> altering the law <strong>without Parliament</strong>", true), # XXX not 2007 specific
        array(1000, "the <strong>smoking ban</strong>", false),
        array(984, "replacing the <strong>Trident nuclear weapons</strong>", false), # XXX not 2007 specific
        # XXX terrorism - there are loads of votes
        # XXX ID cards - there are loads of votes
    );
$polyicystrnum = array("iraq"=>0, "foia"=>1, "lrrb"=>2, "smoking"=>3, "trident"=>4);

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


// "Question from hell" - Public Whip edition
$questlist = array();
$questlist_raw = array();

$swapXvoteP = array("policy-for"=>"policy-against", "no"=>"aye", "aye"=>"no", "vote against"=>"vote for", "vote for"=>"vote against");
$swapXabst = array("policy-for"=>"policy-for", "no"=>"absent", "aye"=>"absent", "vote against"=>"not turn up to vote for", "vote for"=>"not vote against");
$swapXabstP = array("policy-for"=>"policy-against", "no"=>"absent", "aye"=>"absent", "vote against"=>"not turn up to vote against", "vote for"=>"not vote for");
function swapvals($pp, $ss)
{
    return array($pp[0], $ss[$pp[1]], $pp[2], $ss[$pp[3]], $ss[$pp[4]], $pp[5]);
}

/// ... Iraq
$questlistraw[] = array("iraq", "policy-for", "2007-06-11#135", "no", "vote against", "Why did XXXX VVVV
                the principle of an independent inquiry
                to review the way in which the responsibilities of Government
                were discharged in relation to Iraq?");

$questlistraw[] = array("iraq", "policy-for", "2007-10-31#330", "no", "vote against", "Why did XXXX VVVV
                there being a select committee
                to review the way in which the responsibilities of Government
                were discharged in relation to Iraq?");

$questlistraw[] = array("iraq", "policy-for", "2007-06-11#136", "aye", "vote for", "Why did XXXX VVVV
                the recognition that for a further inquiry into Iraq would
                would divert attention
                whilst the whole effort of the effort of the Government
                and the armed forces was directed towards improving the condition of Iraq?");

$questlistraw[] = array("iraq", "policy-for", "2007-10-31#331", "aye", "vote for", "Why did XXXX VVVV
                the recognition that for a further inquiry into Iraq would
                would divert attention
                whilst the whole effort of the effort of the Government
                and the armed forces was directed towards improving the condition of Iraq?");


// ... Legislative and Regulatory Reform Bill
$questlistraw[] = array("lrrb", "policy-for", "2006-05-15#232", "no", "vote against", "Why did XXXX VVVV
                requiring the Government to act \"reasonably\" when altering the
                law to reduce regulatory burdens?");

$questlistraw[] = array("lrrb", "policy-for", "2006-05-16#237", "no", "vote against", "Why did XXXX VVVV
                the ability of a minority of MPs to decide that a proposed change in
                the law was not uncontroversial enough to bypass the usual procedures of
                Parliament?");

$questlistraw[] = array("lrrb", "policy-for", "2006-05-16#235", "no", "vote against", "Why did XXXX VVVV
                requiring the Government to produce an annual report
                on the benefits of the changes it had made to to the law outside the usual procedures of Parliament
                on DDDD?");

$questlistraw[] = array("lrrb", "policy-for", "2006-05-16#240", "no", "vote against", "Why did XXXX VVVV
                requiring the Government to take notice of the of the view of a
                select committee when it decided that a proposed change to the law
                was not proportional, balanced and consistent with policy objectives on DDDD?");

$questlistraw[] = array("lrrb", "policy-for", "2006-05-16#238", "no", "vote for", "Why did XXXX VVVV
                a Government Minister to be able to confer his law rewriting powers to
                people who were not accountable to Parliament?");


// ... Trident
$questlistraw[] = array("trident", "policy-for", "2007-03-14#77", "aye", "vote for", "Why did XXXX VVVV
                extending the life of Trident while remaining unconvinced of the need for an early
                decision to find a replacement?");

$questlistraw[] = array("trident", "policy-for", "2007-03-14#78", "no", "vote against", "Why did XXXX VVVV
                authorizing the Government to replace the Trident nuclear weapons system?");

// ... Smoking ban
$questlistraw[] = array("smoking", "policy-for", "2006-02-14#166", "no", "vote against", "Why did XXXX VVVV
                the third reading of the Act banning smoking in all indoor public places?");

$questlistraw[] = array("smoking", "policy-for", "2006-02-14#164", "no", "vote for", "Why did XXXX VVVV
                allowing private clubs to apply to the Local Authority
                for an exemption to the ban on smoking in all indoor public places?");

// ... FOI Amendment
$questlistraw[] = array("foia", "policy-for", "2007-05-18#121", "no", "vote against", "Why did XXXX VVVV
                limiting the proposed exemption from the Freedom of Information Act
                to matters relating to the personal affairs of a constituent?");

$questlistraw[] = array("foia", "policy-for", "2007-05-18#123", "aye", "vote for", "Why did XXXX VVVV
                the Law which would have exempted Parliament and all MPs from
                the Freedom of Information Act?");

$questlistraw[] = array("foia", "policy-for", "2007-05-18#120", "no", "vote for", "Why did XXXX VVVV
                preventing the Freedom of Information Act from applying to
                correspondence between an MP and any Government department?");

$questlistraw[] = array("foia", "policy-for", "2007-05-18#122", "aye", "vote for", "Why did XXXX VVVV
                closing the debate on the Law which would have exempted MPs from
                the Freedom of Information Act knowing that the next vote on it would pass?");

foreach ($questlistraw as $q)
{
    $questlist[] = $q;
    $questlist[] = swapvals($q, $swapXvoteP);
}
foreach ($questlistraw as $q)
{
    $questlist[] = swapvals($q, $swapXabst);
    $questlist[] = swapvals($q, $swapXabstP);
};
#print "<pre>";print_r($questlist); exit;


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

// Validate if a submit
$errors = array();
if ($_GET['submit']) {
    $constituency = postcode_to_constituency($db, $_GET['mppc'], $postcode_year);
    $row = $db->query_onez_row_assoc("select * from pw_mp where constituency = '$constituency' 
        and ($date_clause)");
    if ($row)
        $mpid = $row['mp_id'];
    $mpattr = get_mpid_attr($db, $db2, $mpid, false, 1, null);
    if ($mpattr == null) {
        $errors[] = "Your MP wasn't found.  Please check you
            entered the postcode correctly.";
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

    header("Location: /election2007.php$quick\n");
    return;
}

header("Content-Type: text/html; charset=UTF-8");
?>

<html>

<head>
<title>The Public Whip - How They Voted 2007</title>
<link href="quiz/quiz2007.css" type="text/css" rel="stylesheet"/>
<link href="quiz/slider.css" type="text/css" rel="stylesheet"/>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

<script type="text/javascript" src="./quiz/slider.js"></script>

<?    if ($_GET['submit'] /*and !$errors*/) {
        # See if MP is standing again
        $mpattr = $mpattr['mpprops'][0];
        $constituency = str_replace("&amp;", "&", $mpattr['constituency']);

        $standing_again = false;
        if ($mpattr['leftreason'] == "general_election_notstanding") {
            $standing_again = true;
        }
$standing_again = true; # XXX remove me

        # Regional parties
        $consid = normalise_constituency_name($db, strtolower($constituency), "2001");
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

        // Work out the questions from hell
        $polfill = array();
        foreach ($questlist as $quest)
        {
            $polval = $quest[1] . $polyicystrnum[$quest[0]];
            if (!$polfill[$polval])
            {
                # XXX should be only when MP is standing again
                list($divdate, $divnum) = split("#", $quest[2]);
                $query = "select vote from pw_vote 
                            left join pw_mp on pw_mp.mp_id = pw_vote.mp_id
                            left join pw_division on pw_division.division_id = pw_vote.division_id
                            where pw_mp.person = " . $mpattr['person'] . "
                            and pw_division.division_date = '" . $divdate . "' and pw_division.division_number = " . $divnum . "
                            ";
                list ($mpvote) = $db->query_onez_row($query);
                if (!$mpvote)
                    $mpvote = "absent";
                #print $mpvote . " --> " . $quest[3] . "<br>";
                if ($mpvote == $quest[3])
                    $polfill[$polval] = str_replace("VVVV", $quest[4], $quest[5]);
            }
        }
        #print "<pre>"; print_r($polfill); print "</pre>";

?>
<script type="text/javascript">


poswords = ["Extremely against","Strongly against","Moderately against","Slightly against",
                  "Indifferent about",
                  "Slightly for", "Moderately for", "Strongly for", "Extremely for"];

var npolicies = <?=count($issues)?>;

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
<? foreach ($unique_parties as $party) {
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
<? } ?>

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

        //print "<p class=\"advice\">";
        //print "</p>";
?>
        <div>
        <div class="policypanel" style="width:60em">
        <h5>Your views</h5>
        <table>
  
<?    
     $c = -1;
     foreach ($issues as $issue) {
        $c++;
?>
        <tr><td><input name="sliderpol<?=$c?>" id="slider-pol<?=$c?>" type="text" title="silly title" class="fd_range_-4_4 fd_classname_polslider fd_hide_input fd_callback_selpol" value="0" /></td>
            <td id="spanpol<?=$c?>" class="sliderposword">XXX</td>
            <td id="polname<?=$c?>"><?=$issue[1]?></td>
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

        <? 
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
#        print "<pre>"; print_r($polfill); print "</pre>";
        foreach ($polfill as $code => $text) {
            print '<div class="floating_question" id="'.$code.'" style="position:absolute">';
            print "<h5>Question from Hell</h5>";
            $text = str_replace("XXXX", "<strong>".$mpattr["name"]."</strong>", $text);
            print $text;
            print "<p><em>Ask this when irksome ".$parties[$mpattr["party"]]." people knock on your door, or to your former MP at a local hustings.</em>";
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
<?
/*    if ($errors) {
        print "<p class=\"error\">";
        print join($errors, "<br>");
        print "</p>";
    } */
?>

Enter your UK <strong>postcode</strong>: <input type="text" size="10" name="mppc" value="<?=htmlspecialchars($_GET['mppc'])?>" id="Text1"> <br/>
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
