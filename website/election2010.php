<?php require_once "common.inc";


# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# 2007 General Election special

require_once "db.inc";
require_once "decodeids.inc";
require_once "dream.inc";
require_once "pretty.inc";
require_once "constituencies.inc";
require_once "account/user.inc";

require_once "election2008articles.inc";
require_once "election_glenrothes_2008issues.inc";

$db = new DB();
$db2 = new DB();

$n = count($issues);    
global $issues; 
global $n; 

function WriteEleSelectIssue($dreamid, $vpresel)
{
    $did = "issue-$dreamid";
    print "<select id=\"$did\" name=\"$did\" onchange=\"UpdateCItable('$did')\">\n";
    //print "<select title=\"Change this to fit your opinion, or skip to next question\" id=\"$did\" name=\"$did\" onchange=\"UpdateCItable('$did')\">\n";
    print "\t<option value=\"00\"".(!$vpresel || ($vpresel == "00") ? " SELECTED" : "")." style=\"color:red\">select your opinion</option>\n";
    print "\t<option value=\"1\"".($vpresel == "1" ? " SELECTED" : "").">in favour of</option>\n";
    print "\t<option value=\"-1\"".($vpresel == "-1" ? " SELECTED" : "").">against</option>\n";
    print "\t<option value=\"0\"".($vpresel == "000" ? " SELECTED" : "").">indifferent about</option>\n";
    print "\t<option value=\"0\"".($vpresel == "0" ? " SELECTED" : "").">undecided about</option>\n";
    #print "\t<option value=\"3\">strongly in favour of</option>\n";
    #print "\t<option value=\"-3\">strongly against</option>\n";
    print "</select>\n";
}

function GetSelectIssuePrint($vpresel)
{
    if ($vpresel == "1")
        return "in favour of"; 
    else if ($vpresel == "-1")
        return "against"; 
    return "unsure of";
}


function WriteEleIssueSection($issue, $vpresel, $person, $vprintview)  # may replace function below
{
    print "<p class=\"sel\">";
    if (!$person || ($person == "I"))
        print "I am ";
    else
        print "$person is ";

    if ($vprintview)
        print "[<em>".GetSelectIssuePrint($vpresel)."</em>]"; 
    else
        WriteEleSelectIssue($issue["dream_id"], $vpresel);
    print " ".$issue["action"];
    print "</p>\n";

}

function WriteEleCalcIssueRow($issues)
{
    print "<tr class=\"issuerow\">\n";
    print "<td><a onmouseover=\"TagToTip('tagth', STICKY, true, DURATION, 8000, ABOVE, true)\">The Candidates</a></td>\n";
}


function DistanceToWord($distance)
{
    if ($distance == -1)
        return "Not<br/>present";
    if ($distance <= 0.2)
        return "strongly<br/><b>for</b> this";
    if ($distance <= 0.4)
        return "moderately<br/><b>for</b> this";
    if ($distance >= 0.8)
        return "strongly<br/><b>against</b> this";
    if ($distance >= 0.6)
        return "moderately<br/><b>against</b> this";
    return "mixed";
}

function DistanceToWordShort($distance)
{
    if ($distance == -1)
        return "no vote";
    if ($distance <= 0.2)
        return "<b>FOR</b>";
    if ($distance <= 0.4)
        return "for";
    if ($distance >= 0.8)
        return "<b>AGAINST</b>";
    if ($distance >= 0.6)
        return "against";
    return "mixed";
}


function CandidateTdEntry($candidate, $suff)
{
    $cid = $candidate["candidate_id"].$suff;
    $name = $candidate["name"];
    $party = $candidate["party"];
    $url = $candidate["url"];   # default to party if not existing
    $incum = ($candidate["votetype"] == "incumbent" ? " <i>(incumbent)</i>" : "");
    return "<td class=\"mpcol\" id=\"$cid\"><a href=\"$url\">$name<br/>($party)$incum</a></td>\n";
}

function WriteCandidateIssueTd(&$candidate, $issue, $vpresel, $distance)
{
    $distance = $candidate["issuedistances"][$issue["name"]];
    if ($vpresel)
    {
        $imap = (int)($vpresel); 
        if ($distance == "-1")
            $bcolour = "gray"; // not present
        else if ($imap == 0)
            $bcolour = "gray"; // neutral
        else 
        {
            $score = -((float)($distance) - 0.5) * 2 * $imap; 
            if ($score < -0.7)
            {
                $bcolour = "#f078ae";
                $ssmiley = '/smileys/mad.gif'; 
            }
            else if ($score < -0.2)
            {
                $bcolour = "#ccaaaa";
                $ssmiley = '/smileys/sad3.gif';
            }
            else if ($score <= 0.2)
            {
                $bcolour = "#bbbbbb";
                $ssmiley = '/smileys/unsure1.gif';
            }
            else if ($score <= 0.7)
            {
                $bcolour = "#bcddbc";
                $ssmiley = '/smileys/delighted.gif';
            }
            else
            {
                $bcolour = "#adffad";
                $ssmiley = '/smileys/glasses2.gif';
            }
            $candidate["snum"] += $score;
            $candidate["sden"] += abs($imap);
        }
    
        print "\t<td class=\"elerowtd\" id=\"".$candidate["candidate_id"].'-'.$issue["dream_id"].'" style="background-color:'.$bcolour.';">';
        if ($ssmiley)
            print "<img src=\"$ssmiley\">\n"; 
    }
    else
        print "\t<td class=\"elerowtd\" id=\"".$candidate["candidate_id"].'-'.$issue["dream_id"].'">';

    if ($candidate["matchid"])
    {
        if (preg_match("/party=/", $candidate["matchid"]))
            $acont = "href=\"http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"]."&amp;".$candidate["matchid"]."\" onmouseover=\"Tip('Show comparison with ".$candidate["party"]." MPs')\"";
        else
            $acont = "href=\"http://www.publicwhip.org.uk/mp.php?dmp=".$issue["dream_id"].
              '&amp;'.$candidate["matchid"].'"'.#.'&display=motions"'
              " onmouseover=\"Tip('Show comparison with MP')\"";
    }
    else
        $acont = "href=\"http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"].'&display=motions"';
    
    
    if ($candidate["votetype"] == "incumbent")
        $vsubject = "Your MP";
    else if ($candidate["votetype"] == "party")
        $vsubject = $candidate["party"]." MPs";
    else if (($candidate["votetype"] == "dream") && ($distance != -1))
        $vsubject = "Party would have";
    else if ($candidate["votetype"] == "leftoffice")
        $vsubject = $candidate["name"];
    else
        $vsubject = Null;
    if ($vsubject and !$bshort)
        print " <a $acont target=\"_blank\">voted</a> "; // $vsubject was at front of print before moved to a different row
    //print DistanceToWord($distance);
    //print "  ".(int)($distance * 10 + 0.5);
    print "</td>\n";
}

function WriteCandidateIssueTdShort($candidate, $issue)
{
    $distance = $candidate["issuedistances"][$issue["name"]];
    print "\t<td id=\"S-".$candidate["candidate_id"].'-'.$issue["dream_id"].'" class="tds">';
    if ($candidate["matchid"])
    {
        if (preg_match("/party=/", $candidate["matchid"]))
            $acont = "href=\"http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"]."&amp;".$candidate["matchid"]."\" onmouseover=\"Tip('Show comparison with Party')\"";
        else
            $acont = "href=\"http://www.publicwhip.org.uk/mp.php?dmp=".$issue["dream_id"].
              '&amp;'.$candidate["matchid"].'"'.#.'&display=motions"'
              " onmouseover=\"Tip('Show comparison with MP')\"";
    }
    else
        $acont = "href=\"http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"].'&display=motions"';
    
    
    print "<a $acont target=\"_blank\">";
    print DistanceToWordShort($distance);
    print "</a></td>\n";
}


function WriteIssueRow($issue, &$candidates, $vpresel)
{
    #print "<th>".$issue["name"]."</th>\n";

    $issuelink = "http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"];
    #print "<th class=\"issue\"><a href=\"$issuelink\">".$issue["name"]."</a></th>\n";
    #print "<th> </th>\n";
    
    print "\n<tr class=\"issuerow-top\" >\n";
    foreach ($candidates as $candidate)
    {
        if ($candidate["votetype"] == "incumbent")
            $vsubject = "Your MP";
        else if ($candidate["votetype"] == "party")
        {
            $vsubject = $candidate["party"];
            if ($candidate["party_short"])
                $vsubject = $candidate["party_short"]; 
        }
        else if (($candidate["votetype"] == "dream") && ($distance != -1))
            $vsubject = "Party would have";
        else if ($candidate["votetype"] == "leftoffice")
            $vsubject = $candidate["name"];
        else
            $vsubject = Null;
        print "<td class=\"".$candidate["party_code"]."\">$vsubject</td>"; //WriteCandidateIssueTd($candidate, $issue);
    }
    print "</tr>\n"; 
    
    print "\n<tr class=\"issuerow-middle\" id=\"".$issue["dream_id"]."-row\">\n";
    foreach ($candidates as &$candidate)
    {
        $distance = $candidate["issuedistances"][$issue["name"]];
        WriteCandidateIssueTd($candidate, $issue, $vpresel, $distance);
    }
    unset($candidate);
    print "</tr>\n";

    print "\n<tr class=\"issuerow-bottom\">\n";
    foreach ($candidates as $candidate)
    {
        $distance = $candidate["issuedistances"][$issue["name"]];
        print "<td>".DistanceToWord($distance)."</td>\n";
    }
    print "</tr>\n";
}


function WriteFrontPage($triedpostcode, $vrand)
{
    print "<html>\n";
    print "<head>\n";
    print "<title>The Public Whip - How They Voted 2010</title>\n";
    print "<link href=\"quiz/election2008.css\" type=\"text/css\" rel=\"stylesheet\"/>\n";
    print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n";

    print "<body style=\"text-align:center\">\n";
    print "<script type=\"text/javascript\" src=\"walterzorn/wz_tooltip.js\"></script>\n";
    print "<script type=\"text/javascript\" src=\"quiz/election_glenrothes2008.js\"></script>\n";

    print "<div id=\"divcrewebyelection\">\n";
    print "<a href=\"/\"><h1 id=\"th1\"><a href=\"/\"><img src=\"/thepublicwhip.gif\" ></h1></a>\n";
    #print "<h2 id=\"howtheyvoted\">How They Voted 2008</h2>\n";
    #print "<h3 id=\"th3\">(...and so should you)</h3>\n";
    print "<h4 id=\"th4a\">The quick party candidate calculator</h4>\n";
    print "<h4 id=\"th4b\">for the 2010 General Election</h4>\n";
    print "<h4 id=\"th4c\">6 May 2010</h4>\n";
    print "<p style=\"color:red; font-size: 100%;\">send feedback: team@publicwhip.org.uk 
           </p>\n";


    print "<div id=\"opform\">";
    if ($triedpostcode)
        print "<p style=\"color:red\">Postcode: '$triedpostcode' doesn't work</p>\n"; 
    print "<form action=\"\" method=\"get\">";
    print "<div class=\"frontpostcodesec\">To find out how your views compare to the main political parties, type in <em>either</em>:\n";
    print "<ul>\n";
    print "<li>Your postcode: <input type=\"text\" name=\"mppc\" id=\"mppc\" size=\"8\" onKeyDown=\"if(event.keyCode==13)event.keyCode=0\"> </input>, <em>or</em> </li>
           <li>Your parliamentary constituency: <input type=\"text\" name=\"mpc\" id=\"mpc\"> </input> </li>
           </ul>
           </div>\n";
    print "<div class=\"frontpostcodesec\">\n";
    print "<div id=\"checkmpbutton\"><input type=\"submit\" style=\"font-size:40px\" value=\"Go to the votes \"></div>\n";
    print "</div>";
    print "<div id=\"dynamicpage\" style=\"display:none\"><img src=\"/smileys/mad.gif\">\n"; 
    print "<p>Random number:</td><td><input type=\"text\" name=\"vrand\" id=\"vrand\" value=\"$vrand\" readonly></p>\n";
    print "</div>\n"; 
    print "</form></div>\n";
    WriteFooter();
}

function WriteFooter()
{
    print "<div class=\"footq\" style=\"clear: both\">
       <a title=\"Public Whip is open source software\" href=\"/project/code.php\">Source code</a>
       <a title=\"Send comments, problems or suggestions\" href=\"/email.php\">Contact us</a>
       <a href=\"http://okd.okfn.org\"><img src=\"/images/ok_80x23_red_green.png\"></a>
       </div>\n";

    print "</div>\n";
    print "</body>\n";
    print "</html>\n";
}

function WriteIntro($isbyelection, $issues)
{
    print "<p>Find which parties or candidate 
        represents your views in the UK Parliament 
        on a range of issues. 
        </p>\n";

    print "<p>(This has been hastily put together while I work on the 
               <a href=\"http://www.thestraightchoice.org\">TheStraightChoice.org</a>, because there is 
               <b>still</b> no <a href=\"\">other election quiz site</a> that looks at what MPs actually do, 
               rather than what they say they're going to do.)</p>";

    print "<p class=\"seclinks\"><a href=\"#sec-".$issues[0]["dream_id"]."\" class=\"st\" title=\"Click here for the first question\">start &gt;&gt;</a></p>";
    print "<p>The $n issues in this calculator are: \n";
    print "<table style=\"padding-left:30px;\">";
    $tri = 0;
    $n = count($issues); 
    for ($i = 0; $i < $n; $i++)
    {
        if ($tri == 0)
            print "<tr>"; 
        $issue = $issues[$i];
        $dreamid = $issue['dream_id'];
        print "<td><a href=\"#sec-$dreamid\">".$issue["name"]."</a></td>\n";
        if (($tri == 3) || ($i == $n - 1))
        {
            $tri = 0; 
            print "</tr>";
        }
        else
            $tri += 1; 
    }
    print "</table>";
    print "Skip to the end at any time, and do only the ones that interest you.</p>\n";
    print "</div>";
}

function WritePartyScores($candidates)
{
        print "<div class=\"partyscores\">"; 
        
        $scandidates = array(); 
        for ($i = 0; $i < count($candidates); $i++)
        {
            $candidate = $candidates[$i]; 
            $score = ($candidate["snum"] + $candidate["sden"]) * 5; 
            $outof = $candidate["sden"] * 2 * 5; 
            $rate = ($outof != 0.0 ? $score / $outof : 0.0); 
            $scandidates[$i] = -$rate; 
        }
        asort($scandidates); 

        print "<table>\n";
        print "<tr><th>MP or Party</th>"; 
        if ($isbyelection)
            print "</th>Candidate</th>"; 
        print "<th>Your agreement<br /> with their votes</th></tr>\n"; 
        foreach ($scandidates as $i => $rate)
        {
            $candidate = $candidates[$i]; 
            print "<tr>"; 
            if (!$isbyelection && ($i == 0))
                print "<td>".$candidate["name"]." MP</td>\n"; 
            else
                print "<td>".$candidate["party"]."</td>\n"; 
            if ($isbyelection)
                print "<td>".$candidate["name"]."</td>\n"; 
            print "<td>".number_format((-$rate) * 100, 1)."%</td>"; 
            print "</tr>\n";
        }
        print "</table>\n"; 
        print "</div>\n"; 
}

function WriteHitcounters($db)
{
    $qselect = "SELECT u1.vpostcode, u1.referrer, u1.ltime, max(u2.ltime) AS time_last, count(*), u2.vevent, u1.vrand, vconstituency, vdash"; 
    $qfrom = " FROM pw_dyn_glenrothes_use AS u1"; 
    $qleftjoin = " LEFT JOIN pw_dyn_glenrothes_event AS u2 ON (u1.vrand = u2.vrand)"; 
    $qwhere = "";# WHERE vdash != ''"; 
    $qgroup = " GROUP BY u1.vrand ORDER BY u1.ltime DESC"; 
    $query = $qselect.$qfrom.$qleftjoin.$qwhere.$qgroup; 
    $db->query($query); 
    print "<table>\n";
    $ii = 0;
    while ($row = $db->fetch_row())
        {
            $vconstituency = $row[7]; 
            $vpostcode = $row[0]; 
            $referrer = $row[1];
            $vmin = $row[2]; 
            $vmax = $row[3]; 
            $vcount = $row[4]; 
            $vevent = $row[5];
            $vrand = $row[6];
            $vdash = $row[8];
            print "<tr><td".($vdash ? ' style="background-color:red"' : '').">$ii-$vrand</td><td>$vpostcode.($vconstituency)</td><td>$vmin</td><td>$vmax</td><td>$vcount</td><td>$vevent</td><td>$referrer</td></tr>\n"; 
            $ii++;
        }
    print "</table>\n";
    
    //$db->query(" SELECT * FROM pw_dyn_glenrothes_use"); 
    //while ($row = $db->fetch_row())
    //{
    //    print "<p>\n"; 
    //    print_r($row); 
    //}

}


#
# start of direct printing
#
$vdash = mysql_real_escape_string(db_scrub($_GET["dash"])); # used to tell if /by-election or /byelection was used
$vpostcode = db_scrub($_POST["vpostcode"]);  # a string of letters (each a-e for strong favour to against) in order of the policies
$vrand = db_scrub($_GET["vrand"]);
$vevent = db_scrub($_GET["vevent"]);

$vprintview = $_GET["print"];
$person = db_scrub($_POST["vname"]); # name of person who expressing these opinions
$vhideunselected = $_GET["hideunselected"];
if ($person == "I")
    $person = "";


// a link was selected and notified by the javascript, mark it down and leave
if ($vrand && $vevent) 
{
    header("Content-Type: text/html; charset=UTF-8");
    //print "<H1>Hi there</h1>\n"; 
    //$db->query("drop table if exists pw_dyn_glenrothes_event");
    //$db->query("create table pw_dyn_glenrothes_event (ltime timestamp, vrand int, vevent VARCHAR(30))");
    $vconstituency = db_scrub($_GET["mpc"]); 
    $db->query("INSERT INTO pw_dyn_glenrothes_event (ltime, vrand, vevent)
                VALUES (NOW(), $vrand, '$vevent')");
    // case of just a img src sent out
    exit(0); 
}

$vpostcode = db_scrub($_GET["mppc"]);
$vconstituency = db_scrub($_GET["mpc"]);
if (is_postcode($vpostcode) or $_GET["mpc"])
{
    // this function does its own _GETs.  Maybe it should
    $mpval = get_mpid_attr_decode($db, $db2, "", "2010");  
}

# front page
if (!$vrand)
{
    // generate the random number and note it down into the main user table
    $vrand = rand(10, 10000000);
    //$db->query("drop table if exists pw_dyn_glenrothes_use");
    //$db->query("create table pw_dyn_glenrothes_use (ltime timestamp, vrand int, vpostcode varchar(20), vconstituency varchar(40), referrer varchar(200), ipnumber varchar(25), vdash varchar(7))");
    if (!isrobot())
    {
        //$hithere = "<h1>hithere $vrand</h1>"; 
        $db->query("INSERT INTO pw_dyn_glenrothes_use (ltime, vrand, vpostcode, vconstituency, referrer, ipnumber, vdash)
                    VALUES (NOW(), $vrand, '', '', '$referrer', '$ipnumber', '$vdash')");
    }
}

// random number already set
else
{
    $vrand = (int)$vrand;
    if (!isrobot() and preg_match("/.*?house=z/", $referrer))
    {
        header("Content-Type: text/html; charset=UTF-8");
        print "<h1>hit counters</h1>\n"; 
        WriteHitCounters($db); 
        exit(0); 
    }
}

// no matching MP found
if (!$mpval)
{
    header("Content-Type: text/html; charset=UTF-8");
print $hithere;
    WriteFrontPage($vpostcode, $vrand);
    exit(0);
}

$mpprop = $mpval["mpprop"]; 
$vconstituency = $mpprop["constituency"]; 

if (!$printview)
{
    // we're doing the page.  now post in the postcode that we now have
    $db->query("SELECT ltime, referrer, vdash FROM pw_dyn_glenrothes_use WHERE vrand = $vrand");
    $row = $db->fetch_row();
    if ($row)
    {
        $ltime = $row[0]; 
        $referrer = $row[1]; 
        $vdash = $row[2]; 
        $db->query("DELETE FROM pw_dyn_glenrothes_use WHERE vrand = $vrand"); 
        $db->query("INSERT INTO pw_dyn_glenrothes_use (ltime, vrand, vpostcode, vconstituency, referrer, ipnumber, vdash)
                    VALUES ('$ltime', $vrand, '$vpostcode', '$vconstituency', '$referrer', '$ipnumber', '$vdash')");
    }
}

header("Content-Type: text/html; charset=UTF-8");

print "<html>\n";
print "<head>\n";
print "<title>The Public Whip - How They Voted 2008</title>\n";
print "<link href=\"quiz/election2008.css\" type=\"text/css\" rel=\"stylesheet\"/>\n";
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n";
print "</head>\n";

if ($vprintview)
    print "<body onload=\"NotifyEvent('printview')\">\n";
else
    print "<body onload=\"UpdateCItable('onload')\">\n";
print "<script type=\"text/javascript\" src=\"walterzorn/wz_tooltip.js\"></script>\n";
print "<script type=\"text/javascript\" src=\"quiz/election_glenrothes2008.js\"></script>\n";

print "<div id=\"divmain\">\n";
print "<div id=\"divcrewebyelection\">\n";
if (!$vprintview)
    print "<a href=\"/\"><h1 id=\"th1\"><a href=\"/\"><img src=\"/thepublicwhip.gif\" ></h1></a>\n";
#print "<h2 id=\"howtheyvoted\">How They Voted 2008</h2>\n";
#print "<h3 id=\"th3\">(...and so should you)</h3>\n";

print "<h4 id=\"th4a\">The party candidate calculator</h4>\n";

$bisbyelection = false; // ($mpprop["constituency"] == "Glenrothes");

if ($bisbyelection)
{
    print "<h4 id=\"th4b\">".$mpprop["constituency"]."</h4>\n";
    print "<h4 id=\"th4c\">by-election: 6 November 2008</h4>\n";
}
else
{
    print "<h4 id=\"th4b\">Your constituency: ".$mpprop["constituency"]."</h4>\n";
    print "<h4 id=\"th4c\">Your MP: ".$mpprop["name"]."</h4>\n";
}


// insert sitting MP
if (!$bisbyelection && $mpprop)
{
    // wipe out the SNP entry
    $candidates[0] = array("name" => $mpprop["name"], 
                      "url"=>"http://www.gwynethdunwoody.co.uk/",
                      "party" => $mpprop["party"], "votetype"=>"leftoffice", "personid" => $mpprop["person"],
                      "candidate_id"=>100,
                      "party_code"=>"incumbant",
                      "matchid" => $mpprop["mpanchor"]);
}


SetCandidateIssueDistances($db, $candidates, $issues);

print "<script type=\"text/javascript\">\n";
WriteJavascriptElecTable($candidates, $issues);
print "</script>\n";


if ($bisbyelection && !$vprintview)
{
    print "<div class=\"secpol\" id=\"sec-top\">\n";
    print "<table class=\"candidatetable\" style=\"float:right\">\n"; 
    print "<caption>List of candidates
           <a href=\"http://www.glenrothesbyelection.com/\" target=\"_blank\">(glenrothesbyelection.com)</a></caption>\n";
    //print "<tr><th>Candidate</th><th>Party (electoral-commission)</th></tr>\n";
    for ($i = 0; $i < count($candidatesA); $i++)
    {
        $candidate = $candidatesA[$i];
        if ($candidate["votetype"] == "leftoffice")
            continue; 
        print "<tr><td>";
        if ($candidate["url"])
            print "<a href=\"".$candidate["url"]."\" target=\"_blank\"><b>".$candidate["party"]."</b> - ".$candidate["name"]."</a>"; 
        else
            print $candidate["name"];
        //print "</td><td>";
        //if ($candidate["party_url"])
        //    print "<a href=\"".$candidate["party_url"]."\" target=\"_blank\">".$candidate["party"]."</a>";
        //else
        //    print $candidate["party"];
        print "</td></tr>\n";
    }
    print "</table>\n"; 
}


    if (!$vprintview)
        WriteIntro($isbyelection, $issues);


    $n = count($issues);    
    print "<form action=\"\" method=\"get\">\n";
    $secpol = ($vprintview ? "secpolprint" : "secpol"); 
    for ($i = 0; $i < $n; $i++)
    {
        $issue = $issues[$i];
        $dreamid = $issue['dream_id'];
        $vpresel = $_GET["issue-$dreamid"];

        if ($vprintview && ($vhideunselected && ($vpresel == "00")))
            continue; 
        
        $ofnumber = ($vprintview ? "" : "<small>(<i>".($i + 1)." of $n</i>)</small>");
        print "<div class=\"$secpol\" id=\"sec-".$issue["dream_id"]."\">";
        if (!$vprintview)
            print "<h2>".$issue["name"]." $ofnumber</h2>\n";
        

        if ($vprintview)
        {
            print "<table class=\"elecalc elecalc-print\">\n"; 
            $issuestrengthid = "issue-strength-".$issue["dream_id"];
            $imap = ((int)($vpresel)) * ($_GET[$issuestrengthid] ? 3 : 1); 
            WriteIssueRow($issue, $candidates, $imap);   
        }
        else
        {
            print "<table class=\"elecalc elecalc-single\">\n"; 
            WriteIssueRow($issue, $candidates, null);
        }
        print "</table>\n";
        
        print "\n\n<div class=\"".($vprintview ? "sissueprint" : "sissue")."\">\n";
        WriteEleIssueSection($issue, $vpresel, $person, $vprintview);
        print "</div>\n";
        
        
        if (!$vprintview)
            WriteLongListNews($issue["name"]);

        $acont = "http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"];
        
        if (!$vprintview)
        {
            print "<p class=\"seclinks\">";
            if ($i == count($issues) - 1)
                print "<a href=\"#sec-summs\" class=\"st\">next &gt;&gt;</a>\n";
            else
                print "<a href=\"#sec-".$issues[$i + 1]["dream_id"]."\" class=\"st\" title=\"Go to next question\">next &gt;&gt;</a>\n";
           if ($i != 0)
                print "<a class=\"ss\" href=\"#sec-".$issues[$i - 1]["dream_id"]."\" title=\"Go to previous question\">previous &lt;&lt;</a>\n";
            //print "<a class=\"ss\" href=\"#\" title=\"Go back to top of questionaire\">top</a>\n";
            print "<a class=\"ss\" href=\"#sec-summs\" title=\"Skip to end of questionaire\">end</a>\n";
            print "</p>\n";
        }
        print "</div>\n\n";
    }
    
    if (!$vprintview)
    {
        print "<div class=\"secpol\" id=\"sec-summs\">";
        print "<h2>Summary of results</h2>\n\n";
        print "<p>Click on the <b>important</b> check-boxes to score the issues you care most about.  
               If the party or MP gets those right, then you may forgive them for their other policies.</p>\n";
        print "<p><input type=\"checkbox\" name=\"hideunselected\" id=\"hideunselected\" value=\"1\" onclick=\"UpdateCItable('hideunselected')\" checked\">Hide unselected entries</input></p>\n";
        print "<table class=\"elecalc\">\n"; 
        print "<tr class=\"candidaterow\">\n";
        print "<td colspan=\"2\">Parliamentary parties for <b>$constituency</b> contituency:</td>\n";
        foreach ($candidates as $candidate)
        {
            print "<td class=\"mpcol\" id=\"".$candidate["candidate_id"]."-name\">";
            print "<a href=\"".$candidate["url"]."\">";
            if ($candidate["votetype"] == "party")
                print $candidate["party"];
            else
                print "(".$candidate["name"].")";
            print "</a></td>\n";
        }
        print "</tr>\n";
    
        print "<tr class=\"agreementrow\"><td colspan=\"2\" style=\"text-align:right\">Agreement rating:</td>\n";
        foreach ($candidates as $candidate)
            print "\t<td><div class=\"myrankcol\" id=\"".$candidate['candidate_id']."-rank\">RK</div></td>\n";
        print "</tr>\n";
    
        for ($i = 0; $i < count($issues); $i++)
        {
            $issue = $issues[$i];
            $dreamid = $issue['dream_id'];
            $issuestrengthid = "issue-strength-".$issue["dream_id"];
            $checked = (($prevote == "a") || ($prevode == "e") ? " checked" : "");
            $inputtype = "type=\"checkbox\" id=\"$issuestrengthid\" name=\"$issuestrengthid\" value=\"strong\" onclick=\"UpdateCItable('$issuestrengthid')\"$checked";
            print "\n<tr class=\"issuerow\" id=\"S-".$issue["dream_id"]."-row\">\n";
            print "<td><a href=\"#sec-$dreamid\">".$issue["name"]."</a></td>\n";
            print "<td><input $inputtype> important</input></td>\n";
    
            #print "<th>".$issue["name"]."</th>\n";

            $issuelink = "http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"];
            #print "<th class=\"issue\"><a href=\"$issuelink\">".$issue["name"]."</a></th>\n";
            #print "<th> </th>\n";
            foreach ($candidates as $candidate)
                WriteCandidateIssueTdShort($candidate, $issue);
            print "</tr>\n";
        }
        print "</table>\n";
        print "<p id=\"ypartychoice\">Your answers are most similar to <span id=\"yourpartychoice\">unknown</span>.  You should strongly consider voting for them.</p>\n"; 
        print "<p class=\"seclinks\"><a href=\"#sec-upload\" class=\"st\">next &gt;&gt;</a>\n";
        print "</div>\n";
    }
    
    if ($vprintview)
        WritePartyScores($candidates); 
    
    if (!$vprintview)
    {
        print "<div class=\"usecpol\" id=\"sec-upload\">\n";
        print "<h2>What you can do now</h2>\n\n";
        print "<p class=\"usecprint\">Click on the button: <input type=\"submit\" name=\"print\" value=\"Printer ready\" title=\"Make printer view\"></input> to summarize the results onto one page that you can take with you.</p>\n";
        print "<p class=\"empara\">Democracy cannot survive on a single visit to the polling booth once every couple of years.  
                Responsible people have to do enough of the following to make a difference:</p>\n";
        print "<h3>Communicate with your representative</h3>\n";
        print "<p>After they are elected, 
                watch your MP by signing up for email alerts, reading their speeches and leaving comments on 
                <a href=\"http://www.theyworkforyou.com/\">TheyWorkForYou.com</a>.\n"; 
        print "You should <a href=\"http://www.writetothem.com/\">Write To Them</a> and say which way you'd like them to vote on any issue.  Better yet, print out the details of a vote that they have done and ask them to explain it when you visit them at their surgery.</p>\n";
        print "<h3>Participate in the political process</h3>\n";
        print "<p>Influence flows through the political parties we have, not the ones you might want there to be.  
                Contact a local branch of an active political party and ask if you can meet to find how you can 
                get involved.</p>
                <ul><li><a href=\"http://www.labour.org.uk/tools_for_your_website#join\">Labour</a></li>
                <li><a href=\"http://www.conservatives.com/Get_involved.aspx\">Conservative</a></li>
                <li><a href=\"http://www.libdems.org.uk/in_your_area\">Lib Dem</a></li>
                <li><a href=\"http://www.snp.org/join\">SNP</a></li>
                <li><a href=\"http://www.greenparty.org.uk/getinvolved\">Green Party</a></li>
                <li><a href=\"http://en.wikipedia.org/wiki/List_of_political_parties_in_the_United_Kingdom#Major_political_parties_in_the_House_of_Commons\">others...</a></li></ul>\n";  
        print "<p class=\"empara\">Getting involved includes running for office.</p>\n"; 

        print "<h3>Participate in governance without the mediation of politicians</h3>\n"; 
        print "<p>There are consultation meetings, public inquiries, and open council sessions happening across 
                the country all the time.  When you need to know hidden details, you can make 
                <a href=\"http://www.whatdotheyknow.com/\">Freedom of Information requests</a> about information you have a right to know.</p>
               <p>When an MP intervenes in a local matter, they are not doing anything that people can't do for themselves 
               with help from their own community.  The only thing special about an MP is their right 
                speak and vote in the House of Commons, which is the supreme body of authority in the land.</p>\n"; 
        //print "<li>Write to your local paper and tell others about the political actions taken in your name and how you feel about it.</li>\n"; 
        print "<h3>Do something with this webpage</h3>\n"; 
        print "<p>Why not forward this webpage to a friend, or  
                <A HREF=\"mailto:team@publicwhip.org.uk?subject=byelection quiz&Dear Publicwhip,\">send your comments to PublicWhip</a>?</p>"; 
        print "<p>Perhaps you can research, design, print and distribute leaflets 
               similar to <a href=\"http://www.publicwhip.org.uk/quiz/glenrothesflier.pdf\">this publicwhip flier</a> 
               to your neighbourhood to inform people of facts which do not appear on any of the election candidates' 
               leaflets.  Are you happy with the quality and lack of intelligence found in campaign literature?  
               Then do something about it!</p>\n"; 
    
        print "<div id=\"dynamicpage\" style=\"display:none\"><img src=\"/smileys/mad.gif\">\n"; 
        print "<p>Your postcode: <input type=\"text\" name=\"mppc\" id=\"mppc\" size=\"8\" value=\"$vpostcode\" readonly></p>\n";
        print "<p>Your parliamentary constituency: <input type=\"text\" name=\"mpc\" id=\"mpc\" value=\"$vconstituency\" readonly></p>\n";
        print "<p>Random number:</td><td><input type=\"text\" name=\"vrand\" id=\"vrand\" value=\"$vrand\" readonly></p>\n";
        print "</div>\n"; 
    }

    print "</form>\n";

print "</div>\n";


if (!$vprintview)
    WriteFooter();
else
    print "</div></body></html>\n"; 


