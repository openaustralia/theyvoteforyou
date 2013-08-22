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


function WriteEleSelectIssue($dreamid, $prevote)
{
    $selaye = (($prevote == "a") || ($prevote == "b"));
    $selnoe = (($prevote == "d") || ($prevote == "e"));
    $selind = ($prevote && !$selaye && !$selnoe);
    $selund = False;
    print "<select title=\"Change this to fit your opinion, or skip to next question\" id=\"issue-$dreamid\" onchange=\"UpdateCItable()\">\n";
    print "\t<option value=\"0\"".(!$prevote ? " SELECTED" : "")." style=\"color:gray\">select your opinion</option>\n";
    print "\t<option value=\"1\"".($selaye ? " SELECTED" : "").">in favour of</option>\n";
    print "\t<option value=\"-1\"".($selnoe ? " SELECTED" : "").">against</option>\n";
    print "\t<option value=\"0\"".($selind ? " SELECTED" : "").">indifferent about</option>\n";
    print "\t<option value=\"0\"".($selund ? " SELECTED" : "").">undecided about</option>\n";
    #print "\t<option value=\"3\">strongly in favour of</option>\n";
    #print "\t<option value=\"-3\">strongly against</option>\n";
    print "</select>\n";
}

function WriteEleIssueSection($issue, $prevote, $person)  # may replace function below
{
    print "<p class=\"sel\">";
    if (!$person || ($person == "I"))
        print "I am ";
    else
        print "$person is ";

    WriteEleSelectIssue($issue["dream_id"], $prevote);
    print $issue["action"];
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
        return "strongly<br/>for this";
    if ($distance <= 0.4)
        return "moderately<br/>for this";
    if ($distance >= 0.8)
        return "strongly<br/>against this";
    if ($distance >= 0.6)
        return "moderately<br/>against this";
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

function WriteCandidateIssueTd($candidate, $issue)
{
    $distance = $candidate["issuedistances"][$issue["name"]];
    print "\t<td class=\"elerowtd\" id=\"".$candidate["candidate_id"].'-'.$issue["dream_id"].'">';
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


function WriteIssueRow($issue, $candidates)
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
            $vsubject = $candidate["party"];
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
    foreach ($candidates as $candidate)
        WriteCandidateIssueTd($candidate, $issue);
    print "</tr>\n";

    print "\n<tr class=\"issuerow-bottom\">\n";
    foreach ($candidates as $candidate)
        print "<td>".DistanceToWord($candidate["issuedistances"][$issue["name"]])."</td>\n";
    print "</tr>\n";
}


function DDDD_WriteEleCalcTableTrans($issues, $candidates, $vkey, $person, $bthreadopinionrows)
{
    global $constituency;

    print "<tr class=\"candidaterow\">\n";
    print "<td>Candidates for <b>$constituency</b> contituency:</td>\n";
    foreach ($candidates as $candidate)
        print CandidateTdEntry($candidate, "-name");
    print "</tr>\n";
    
    print "<tr class=\"agreementrow\"><td class=\"tdright\">Agreement rating:</td>\n";
    foreach ($candidates as $candidate)
        print "\t<td><div class=\"myrankcol\" id=\"".$candidate['candidate_id']."-rank\">RK</div></td>\n";
    print "</tr>\n";
    
    for ($i = 0; $i < count($issues); $i++)
    {
        $issue = $issues[$i];
        $dreamid = $issue['dream_id'];
        print "\n\n<tr class=\"selerow\">";
        print "<td id=\"selerowc-$dreamid\" class=\"selerowc\" rowspan=\"2\">"; 
        $prevote = ($vkey && ($i < strlen($vkey)) ? $vkey[$i] : "");
        print "<div style=\"height:50%\">";
        WriteEleIssueSection($issue, $prevote, $person);
        print "</div>";
        if ($i < count($issues) - 1)
        {
            $dreamidnext = $issues[$i + 1]["dream_id"];
            print "<div style=\"float:right\"><a onclick=\"NextClick('$dreamidnext')\">next</a></div>";
        }
        else
            print "<div style=\"float:right\"><a onclick=\"NextClick('')\">finish</a></div>";
        print "</td></tr>\n";

        print "<tr id=\"newsart-$dreamid\"><td colspan=\"".count($candidates)."\">";
        WriteLongListNews($issue["name"]);
        print "</td></tr>\n";

        WriteIssueRow($issue, $candidates);
    }
    
    print "<tr class=\"agreementrow2\"><td>Agreement rating:</td>\n";
    foreach ($candidates as $candidate)
        print "\t<td><div class=\"myrankcol\" id=\"".$candidate['candidate_id']."-rankl\">RK</div></td>\n";
    print "</tr>\n";
    
    print "<tr class=\"candidaterow\">\n";
    print "<td>Candidates for <b>$constituency</b> contituency:</td>\n";
    foreach ($candidates as $candidate)
        print CandidateTdEntry($candidate, "-namel");
    print "</tr>\n";
}



header("Content-Type: text/html; charset=UTF-8");

print "<html>\n";
print "<head>\n";
print "<title>The Public Whip - How They Voted 2008</title>\n";
print "<link href=\"quiz/election2008.css\" type=\"text/css\" rel=\"stylesheet\"/>\n";
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n";

print "</head>\n";
print "<body onload=\"UpdateCItable()\">\n";
//print "<body>\n";
print "<script type=\"text/javascript\" src=\"walterzorn/wz_tooltip.js\"></script>\n";
print "<script type=\"text/javascript\" src=\"quiz/election_crewe_and_nantwich2008.js\"></script>\n";

print "<div id=\"divcrewebyelection\">\n";
print "<a href=\"/\"><h1 id=\"th1\"><a href=\"/\"><img src=\"/thepublicwhip.gif\" ></h1></a>\n";
#print "<h2 id=\"howtheyvoted\">How They Voted 2008</h2>\n";
#print "<h3 id=\"th3\">(...and so should you)</h3>\n";
print "<h4 id=\"th4a\">The party candidate calculator</h4>\n";
print "<h4 id=\"th4b\"><strike>Crewe and Nantwich</strike>$constituency</h4>\n";
print "<h4 id=\"th4c\">by-election: 6 November 2008</h4>\n";

$vdash = mysql_real_escape_string(db_scrub($_GET["dash"])); # used to tell if /by-election or /byelection was used
$vpostcode = db_scrub($_POST["vpostcode"]);  # a string of letters (each a-e for strong favour to against) in order of the policies
$vvote = mysql_real_escape_string(db_scrub($_POST["vvote"]));
$vkey = mysql_real_escape_string(db_scrub($_POST["vkey"]));
$vcomment = mysql_real_escape_string(db_scrub($_POST["vcomment"]));
$vinitials = mysql_real_escape_string(db_scrub($_POST["vinitials"]));
$vrand = $_POST["vrand"];
if ($vrand)
    $vrand = (int)$vrand;
else
    $vrand = rand(10, 10000000);
$person = db_scrub($_POST["vname"]); # name of person who expressing these opinions

if ($person == "I")
    $person = "";
SetCandidateIssueDistances($db, $candidates, $issues);

print "<script type=\"text/javascript\">\n";
WriteJavascriptElecTable($candidates, $issues);
print "</script>\n";

print "<p style=\"background-color:#ffbbbb; margin:22px\"><b>The by-election was <a href=\"http://news.bbc.co.uk/2/hi/uk_news/politics/7415362.stm\">won</a> by Edward Timpson (Con).  Sign up for email alerts about his speeches (which will include his maiden speech) <a href=\"http://www.theyworkforyou.com/mp/edward_timpson/crewe_and_nantwich\">here</a> on theyworkforyou.com.  Thank you for your attention.</b>
    Why not try <a href=\"/fortytwodays.php\">the fortytwo days quiz?</a></p>\n";

print "<div class=\"secpol\" id=\"sec-top\">\n";
print "<table class=\"candidatetable\" style=\"float:right\">\n"; 
print "<caption>List of candidates
       <a href=\"http://www.glenrothesbyelection.com/\" target=\"_blank\">(from glenrothesbyelection.com)</a></caption>\n";
//print "<tr><th>Candidate</th><th>Party (electoral-commission)</th></tr>\n";
for ($i = 0; $i < count($candidatesA); $i++)
{
    $candidate = $candidatesA[$i];
    if ($candidate["votetype"] == "leftoffice")
        continue; 
    print "<tr><td>";
    if ($candidate["url"])
//        print "<a href=\"".$candidate["url"]."\" target=\"_blank\">".$candidate["name"]." - ".$candidate["party"]."</a>"; 
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

$referrer = $_SERVER["HTTP_REFERER"];
$querystring = $_SERVER["QUERY_STRING"];
$ipnumber = $_SERVER["REMOTE_ADDR"];
if (!$referrer)
    $referrer = $_SERVER["HTTP_USER_AGENT"];

# we've had a posting
if ($vkey)
{
    print "<p class=\"vcomment\">\n";
    print "Thanks for your information";
    if ($vinitials)
        print ", $vinitials"; 
    if ($vcomment)
        print ", and thanks for the comment";
    print ".</p>\n";

    if (preg_match("/.*?house=z/", $referrer))
    {
        $db->query("SELECT vkey, vvote, url, referrer, pw_logincoming.ltime AS ltime0, pw_dyn_crewe_comments.ltime AS ltime1, vinitials, vpostcode, vcomment 
                    FROM pw_logincoming 
                    LEFT JOIN pw_dyn_crewe_comments 
                    ON thing_id = vrand
                    WHERE page = 'crewe_election' 
                    AND vpostcode <> ''
                    ORDER BY ltime0 DESC
                    LIMIT 9150");
        print "<table style=\"clear:both\">\n";
        $i = 0; 
        while ($row = $db->fetch_row_assoc())
        {
            $i++;
            #print "<tr><td>$i</td><td>".$row["ltime0"]."</td><td>".$row["ltime1"]."</td><td>".$row["url"]."</td><td style=\"font-size:60%\">".$row["referrer"]."</td><td>".$row["vpostcode"]."</td><td style=\"width:40%\">".$row["vcomment"]."</td></tr>\n";
            print "<tr><td>$i</td><td>".$row["ltime0"]."</td><td>".$row["vdash"]."</td><td>".$row["url"]."</td><td style=\"font-size:60%\">".$row["referrer"]."</td><td>".$row["vpostcode"]."</td><td style=\"width:40%\">".$row["vcomment"]."</td></tr>\n";
        }
        print "</table>\n";
    }

// we've got to do something constructive with the comments...

    print "<p>If you like, you can sign up for a (very infrequent) newsletter on the front page of 
           <a href=\"http://www.publicwhip.org.uk\">Public Whip</a>, 
           or see if you can make any sense of another little 
           webpage I do called <a href=\"http://www.undemocracy.com\">undemocracy.com</a>.</p>\n";
    print "<p>Or go and visit one of the proper campaign websites in the table on the right.</p>\n";
    print "<p>Yours, <br> Julian Todd</p>\n";
    print "<div class=\"footq\">
       <a title=\"Public Whip is open source software\" href=\"/project/code.php\">Source code</a>
       <a title=\"Send comments, problems or suggestions\" href=\"/email.php\">Contact us</a>
       <a href=\"http://okd.okfn.org\"><img src=\"/images/ok_80x23_red_green.png\"></a>
       </div>\n";

    print "</div>\n";

    //$db->query("drop table if exists pw_dyn_crewe_comments");
    //$db->query("create table pw_dyn_crewe_comments (vkey varchar(20), ltime timestamp, vrand int, vvote varchar(20), vinitials varchar(20), vpostcode varchar(20), vcomment text)");

    
    $db->query("INSERT INTO pw_dyn_crewe_comments (vkey, ltime, vvote, vinitials, vpostcode, vrand, vcomment)
                VALUES ('$vkey', NOW(), '$vvote', '$vinitials', '$vpostcode', $vrand, '$vcomment')");
    
    print "</body>\n";
    print "</html>\n";
    exit;
}

print "<p>This website helps you pick which party  
        votes in Parliament according to your views
        on a selection of issues. These are based on the numbers in 
        <a href=\"http://www.theyworkforyou.com\">theyworkforyou.com</a>. 
        </p>

        <p>If you already know who you are going to vote for, this website helps you 
        see which issues you probably disagree with them about.</p>

        <p>Only the <b>Labour</b>, <b>LibDem</b> and <b>Conservative</b> Parties 
        are shown, because the others in the election have 
        had no MPs in Parliament.</p>

        <p>Gwyneth Dunwoody is included for reference because she sometimes 
        voted differently from the majority of the Labour Party.</p>";

        //<p>Your answers are not sent to any computer, unless 
        //you choose to submit them at the end.</p>

        
print "<p class=\"seclinks\"><a href=\"#sec-".$issues[0]["dream_id"]."\" class=\"st\" title=\"Click here for the first question\">start &gt;&gt;</a></p>";
print "</div>";

#print "<table class=\"elecalc\">\n";
#WriteEleCalcTableTrans($issues, $candidates, $vkey, $person, $bthreadopinionrows);
#print "</table>\n";


    $n = count($issues);
    for ($i = 0; $i < $n; $i++)
    {
        $issue = $issues[$i];
        $dreamid = $issue['dream_id'];
        $ofnumber = "(<i>".($i + 1)." of $n</i>)";
        print "<div class=\"secpol\" id=\"sec-".$issue["dream_id"]."\">";
        print "<h2>".$issue["name"]." <small>$ofnumber</small></h2>\n";

        print "<table class=\"elecalc elecalc-single\">\n"; 
        WriteIssueRow($issue, $candidates);
        print "</table>\n";
        
        //print "<table border=1><tr><td style=\"width:50%\">\n";
        print "\n\n<div class=\"sissue\">\n";
        //print "<p>Use the drop-down box to state your opinion to complete the sentence. $ofnumber</p>\n";
        $prevote = ($vkey && ($i < strlen($vkey)) ? $vkey[$i] : "");
        WriteEleIssueSection($issue, $prevote, $person);
        print "</div>\n";

        //print "</td><td style=\"width:50%\">\n";
        //print "</td></tr></table>\n";
        $acont = "http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"];
        //print "<p>Click <a href=\"$acont\" target=\"_blank\" title=\"List of relevant votes in Parliament\">here</a> to see the votes in Parliament this was based on.</p>";

        WriteLongListNews($issue["name"]);

        
        print "<p class=\"seclinks\">";
        if ($i == count($issues) - 1)
            print "<a href=\"#sec-summs\" class=\"st\">next &gt;&gt;</a>\n";
        else
            print "<a href=\"#sec-".$issues[$i + 1]["dream_id"]."\" class=\"st\" title=\"Go to next question\">next &gt;&gt;</a>\n";
        if ($i != 0)
            print "<a class=\"ss\" href=\"#sec-".$issues[$i - 1]["dream_id"]."\" title=\"Go to previous question\">previous &lt;&lt;</a>\n";
        print "<a class=\"ss\" href=\"#\" title=\"Go back to top of questionaire\">top</a>\n";
        print "</p>\n";
        print "</div>\n\n";
    }
    
    print "<div class=\"secpol\" id=\"sec-summs\">";
    print "<h2>Summary of results</h2>\n\n";
    print "<p>This table lists the issues on which you have expressed a preference.
           Use the tick-boxes to say which are the most important to you.
           The scores are added up to give the party that votes closest to you 
           in Parliament.</p>";
    print "<p>If a box is red it's in the row of an issue 
           you disagree with that party on.  Click on the word \"FOR\" or \"AGAINST\" to see how the individual votes 
           for that policy break down.</p>\n";
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
        $inputtype = "type=\"checkbox\" id=\"$issuestrengthid\" value=\"strong\" onchange=\"UpdateCItable()\"$checked";
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
    print "<p class=\"seclinks\"><a href=\"#sec-upload\" class=\"st\">next &gt;&gt;</a>\n";
    print "</div>\n";


    print "<div class=\"usecpol\" id=\"sec-upload\">\n";
    print "<h2>Give us your views</h2>\n\n";
     
    print "<div id=\"uploadop\">\n";
    print "<form action=\"http://www.publicwhip.org.uk/election_crewe_and_nantwich_2008.php\" method=\"post\">\n";
    
    print "<table>\n";
    print "<caption>Upload your opinions if you dare</caption>\n";
    print "<tr><td>Your postcode:</td> <td><input type=\"text\" name=\"vpostcode\" id=\"vpostcode\"> </input></td></tr>\n";
    print "<tr><td>Your initials:</td> <td><input type=\"text\" name=\"vinitials\" id=\"vinitials\"> </input></td></tr>\n";
    print "<tr style=\"display:none\"><td>Opinion code:</td><td><input type=\"text\" name=\"vkey\" id=\"vkey\" value=\"ccccccccccc\" readonly></td></tr>\n";
    print "<tr style=\"display:none\"><td>Random number:</td><td><input type=\"text\" name=\"vrand\" id=\"vrand\" value=\"$vrand\" readonly></td></tr>\n";
    print "<tr><td colspan=\"2\">Your intended vote:</td><tr>\n";
    print "<tr><td colspan=\"2\"><select id=\"vvote\" name=\"vvote\">\n";
    print "\t<option value=\"undecided\" SELECTED>undecided</option>\n";
    print "\t<option value=\"notvote\">not voting</option>\n";
    print "\t<option value=\"notvote\">can't vote</option>\n";
    print "\t<option value=\"nobusiness\">prefer not to say</option>\n";
    for ($i = 0; $i < count($candidatesA); $i++)
    {
        $candidate = $candidatesA[$i];
        if ($candidate["votetype"] == "leftoffice")
            continue; 
        print "\t<option value=\"".$candidate["party_code"]."\">";
        print $candidate["name"]." (".$candidate["party"].")";
        print "</option>\n";
    } 
    print "</select></td></tr>\n";
    print "<tr><td colspan=\"2\">Comments:</td><tr>\n";
    print "<tr><td colspan=\"2\"><textarea id=\"vcomment\" name=\"vcomment\" rows=\"5\" cols=\"40\"></textarea></td></tr>\n";
    
    print "<tr><td colspan=\"2\"><input type=\"submit\" value=\"Upload my comments\" title=\"Don't forget to click here\"></input></td></tr>\n";
    print "</table>\n";
    print "</form>\n";
    print "</div>\n";

    print "<p>If you have decided on the party you support,  
           make sure you vote.
           You can contact <a href=\"http://www.creweandnantwichlabour.org.uk/contact_us\" target=\"_blank\">Labour</a>, 
           <a href=\"http://www.creweandnantwichconservatives.com/survey.php?surveyid=7\" target=\"_blank\">Conservative</a>, 
           <a href=\"http://www.elizabethshenton.com/contact-elizabeth-shenton/\" target=\"_blank\">LibDem</a>, or one 
           of the smaller parties listed at the top of this page and leave them your name and 
           address and they'll make sure they chase you up on the day in case you forget to vote.</p>

           <p>Please leave your post-code and make a comment to help improve this website for future elections.
           <i>Don't forget to click on the <b>\"Upload my comments\"</b> button</i>!</p>";
    
    print "<p>One last thing.  About those hospital car parking charges which <a href=\"http://www.elizabethshenton.com/leighton-hospital-53/\">have featured</a> 
           during the campaign: try 
            <a href=\"http://www.whatdotheyknow.com/body/mid_cheshire_hospitals_nhs_foundation_trust\">asking 
           the hospital about them</a> using the Freedom of Information laws.  
           These laws were 
           <a href=\"http://www.publicwhip.org.uk/policy.php?id=1008\">created by the MPs</a> back in the year 2000, 
           and are very useful for helping us help ourselves.</p>\n";
    
    /*print "<h2 style=\"clear:both\">Frequently Asked Questions</h2>\n";
    print "<p><b>Why is this site biased against Labour?</b></p>\n";
    print "<p>The bias that is present is entirely due to the selection of votes and policies.
           There has been limited time and resources for completing the research for all of the Parliamentary votes.</p>

           <p>Supporters of the Labour Party who want to improve its standing 
           in relation to this type of analysis are strongly invited to help find the popular votes that their 
           favourite party has cast in Parliament and 
           <a href=\"http://www.publicwhip.org.uk/faq.php#help\">explain them accurately</a> 
           in words that are easy to understand.  Get in touch if you need advice on how to do it.</p>\n";

    print "<p style=\"margin-top:1em\"><b>Why don't you mention important issues like the minimum wage?</b></p>\n"; 
    print "<p>The <a href=\"http://en.wikipedia.org/wiki/National_Minimum_Wage_Act_1998\">National 
           Minimum Wage Act 1998</a> was passed ten years ago. 
           Like the <a href=\"http://en.wikipedia.org/wiki/Human_Rights_Act_1998\">Human Rights Act 1998</a>
           and the <a href=\"http://en.wikipedia.org/wiki/Freedom_of_Information_Act_2000\">Freedom of Information Act 2000</a>, 
           it was a step forward.  However there needs to be evidence that the policy is still in place.  
           After all, the Labour Party used to stand for nuclear disarmament, and doesn't any more.</p>\n";

    
    print "<p style=\"margin-top:1em\"><b>What about things like continued investment in education and the health service which the Labour Party stands for?  Where are they?</b></p>\n";
    print "<p>If these are subject to a vote in Parliament, we can easily put them in once someone finds them.
           If not, then it's tricky and shows a limitation of using Parliamentary votes 
           as the sole basis for determining the right party for you to support.</p>
           <p>Public spending and accountability is a sticky issue.  
           The main problem is that the numbers don't make any sense unless they are put into context. And even then it's difficult 
           to tell the difference between actual increased investment in public services, and the same  
           services simply costing a lot more money than they used to.
           As a result, we are generally left with interpreting the numbers according to our prejudices.</p>
           <p>There was a  
           <a href=\"http://www.publicwhip.org.uk/division.php?date=2007-06-29&number=169\">vote in Parliament 
           on 29 June 2007</a> about establishing a public website containing a break-down of all the Government 
           expenditure across the country, to which only 18 MPs turned up.</p>
           <p>In general, the advantage belongs to those who pay attention to the details.  
           Currently, only businesses take the time to scrutinize the flow of public expenditures.
           Unless there are active citizen's groups investigating it on the public's behalf, 
           there's no saying what is going on.</p>
           


           <p>JT</p>\n";
   */
   print "</div>\n";
    #print "<p class=\"seclinks\"><a href=\"#frant\">finally &gt;&gt;</a>\n";
    #print "<a class=\"ss\" href=\"#sec-".$issues[count($issues) - 1]["dream_id"]."\">previous &lt;&lt;</a>\n";
    #print "<a class=\"ss\" href=\"#\">top</a>\n";
    print "</div>";

/*
print "<div class=\"secpol\" id=\"frant\">\n";
print "<h2 id=\"frant\">What now?</h2>";
print "<p>The election system in the UK requires you to choose a person.
       Since you cannot make any indication about the policies you really support,
       you are often forced to make some serious compromises when you cast your vote.
       The political class will routinely try to persuade you that these compromises 
       don't matter and can be forgotten, so it is up to you to make them known.</p>

       <p>Use the information you find on <a href=\"http://www.publicwhip.org.uk\">the Public Whip</a>
       to discover which MPs (and parties) agree with you on each issue,
       and isolate those topics that are of most concern.  
       Raise them with the candidates whenever you can, and make 
       up your mind based on what they say.</p>

       <p>The candidates are free to make promises and break promises, or avoid saying anything 
       at all -- but ultimately they need you to give them your vote to survive.  Never forget that.</p>
       
       <p>When MPs are elected into their job, they go to London and pass 
       laws, set taxes, and determin Government spending by casting votes in your name in Parliament.  
       There are hundreds of these votes per year, and the complete list is 
       <a href=\"http://www.publicwhip.org.uk/divisions.php\" target=\"_blank\">here</a>.  
       Only a fraction of them have been converted into plain english, 
       but it's hard work, and <a href=\"http://www.publicwhip.org.uk/faq.php#motionedit\">needs help</a>.
       The politicians don't want to make it easy and are not interested in 
       helping people find out what they don't think they need to know and would merely make 
       their job more difficult.</p>

       <p>Instead, they prefer to talk about car parking charges at the local hospital 
       over which they have absolutely no control.  What they in fact do control are laws that allow you to  
       <a href=\"http://www.whatdotheyknow.com/body/mid_cheshire_hospitals_nhs_foundation_trust\">ask the hospital</a> 
       yourself where the money is going, who decides, and to get an answer.  But that's a whole other story...</p>

       <p>A non-party leaflet associated to this webpage and is being distributed in Crewe and Nantwich can 
       be downloaded from <a href=\"/pdf/creweleaflet.pdf\">here</a>.</p>

       <p>To set these issues in a far greater context of world problems, visit 
       <a href=\"http://www.undemocracy.com\">undemocracy.com</a>. Thanks.</p>
       </div>";
*/

print "<div class=\"footq\">
       <a title=\"Public Whip is open source software\" href=\"/project/code.php\">Source code</a>
       <a title=\"Send comments, problems or suggestions\" href=\"/email.php\">Contact us</a>
       <a href=\"http://okd.okfn.org\"><img src=\"/images/ok_80x23_red_green.png\"></a>
       </div>\n";

print "</div>\n";
print "</body>\n";
print "</html>\n";


