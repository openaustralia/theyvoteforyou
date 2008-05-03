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
require_once "election2008issues.inc";

$db = new DB();
$db2 = new DB();


function WriteEleSelectIssue($dreamid, $prevote)
{
    $selaye = (($prevote == "a") || ($prevote == "b"));
    $selnoe = (($prevote == "d") || ($prevote == "e"));
    $selind = (!$selaye && !$selnoe);
    print "<select id=\"issue-$dreamid\" onchange=\"UpdateCItable()\">\n";
    print "\t<option value=\"0\"".($selind ? " SELECTED" : "").">indifferent about</option>\n";
    print "\t<option value=\"1\"".($selaye ? " SELECTED" : "").">in favour of</option>\n";
    #print "\t<option value=\"3\">strongly in favour of</option>\n";
    print "\t<option value=\"-1\"".($selnoe ? " SELECTED" : "").">against</option>\n";
    #print "\t<option value=\"-3\">strongly against</option>\n";
    print "</select>\n";
}

function WriteEleIssueSection($issue, $prevote, $person)  # may replace function below
{
    //print "\n\n<div class=\"sissue\">\n";
    if (!$person || ($person == "I"))
        print "I am ";
    else
        print "$person is ";

    WriteEleSelectIssue($issue["dream_id"], $prevote);
    print $issue["action"];
    $issuestrengthid = "issue-strength-".$issue["dream_id"];
    $checked = (($prevote == "a") || ($prevode == "e") ? " checked" : "");
    $inputtype = "type=\"checkbox\" id=\"$issuestrengthid\" value=\"strong\" onchange=\"UpdateCItable()\"$checked";
    print "<br/> (<input $inputtype> Very important</input>)\n";
    //print "</div>\n";
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
    print "\t<td id=\"".$candidate["candidate_id"].'-'.$issue["dream_id"].'">';
    if ($candidate["matchid"])
    {
        $acont = "href=\"http://www.publicwhip.org.uk/mp.php?dmp=".$issue["dream_id"].
              '&amp;'.$candidate["matchid"].'"'.#.'&display=motions"'
              " onmouseover=\"Tip('Show comparison with MP or party')\"";
    }
    else
        $acont = "href=\"http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"].'&display=motions"';
    
    
    if ($candidate["votetype"] == "incumbent")
        $vsubject = "Your MP";
    else if ($candidate["votetype"] == "party")
        $vsubject = $candidate["party"]." MPs";
    else if (($candidate["votetype"] == "dream") && ($distance != -1))
        $vsubject = "Party would have";
    else
        $vsubject = Null;
    if ($vsubject)
        print "$vsubject <a $acont target=\"_blank\">voted</a> ";
    print DistanceToWord($distance)."</td>\n";
}


function WriteIssueRow($issue, $candidates)
{
    print "\n<tr class=\"issuerow\" id=\"".$issue["dream_id"]."-row\">\n";
    #print "<th>".$issue["name"]."</th>\n";

    $issuelink = "http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"];
    #print "<th class=\"issue\"><a href=\"$issuelink\">".$issue["name"]."</a></th>\n";
    #print "<th> </th>\n";
    foreach ($candidates as $candidate)
        WriteCandidateIssueTd($candidate, $issue);
    print "</tr>\n";
}


function WriteEleCalcTableTrans($issues, $candidates, $vkey, $person, $bthreadopinionrows)
{
    global $constituency;

    print "<tr class=\"candidaterow\">\n";
    print "<td>Candidates for <b>$constituency</b> contituency:</td>\n";
    foreach ($candidates as $candidate)
        print CandidateTdEntry($candidate, "-name");
    print "</tr>\n";
    
    print "<tr class=\"agreementrow\"><td>Agreement rating:</td>\n";
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
print "<script type=\"text/javascript\" src=\"quiz/election2008.js\"></script>\n";

print "<div id=\"divQuizResults\">\n";
#print "<h1 id=\"th1\"><a href=\"/\"><span class=\"fir\">The Public Whip</span></a></h1>\n";
print "<h2 id=\"howtheyvoted\">How They Voted 2008</h2>\n";
print "<h3 id=\"th3\">(...and so should you)</h3>\n";
print "<h4 id=\"th4\">The candidate calculator for <i>$constituency</i></h4>\n";
print "<p></p>\n\n";

$vkey = $_GET["vkey"];  # a string of letters (each a-e for strong favour to against) in order of the policies
$person = $_GET["vname"]; # name of person who expressing these opinions

if ($person == "I")
    $person = "";
SetCandidateIssueDistances($db, $candidates, $issues);

print "<script type=\"text/javascript\">\n";
WriteJavascriptElecTable($candidates, $issues);
print "</script>\n";

if (!$person)
{
    print "<h2>Instructions</h2>\n";
    print "<p>Choose some or all of your political opinions from the options below 
           to see how they compare against your MP's voting record, versus the voting record 
           of an average MP for each of the parties whose candidates are standing against them.</p>
           
           <p>For candidates whose parties have no representation in Parliament (eg the Green party), 
           a hypothetical voting record 
           will need to be supplied on behalf of the candidate by ticking off from the 
           <a href=\"http://www.publicwhip.org.uk/divisions.php\">list of all votes</a> 
           using a policy object such as <a href=\"http://www.publicwhip.org.uk/policy.php?id=1013\">this</a>.
           The party can arrange to do the on behalf of their candidates, but the sooner it is started the better because 
           there won't be any time once the election is called.</p>";
}
else
    print "<h2>Voting expression for $person</h2>";


            
        
print "<h2><a class=\"start\" onclick=\"NextClick('".$issues[0]["dream_id"]."')\">start</a></h2>";


print "<table class=\"elecalc\">\n";
WriteEleCalcTableTrans($issues, $candidates, $vkey, $person, $bthreadopinionrows);
print "</table>\n";

if (!$person)
{
    print "<form action=\"http://www.publicwhip.org.uk/election2008.php\" method=\"get\">\n";
    print "Your name: <input type=\"text\" name=\"vname\" id=\"vname\"> </input>\n";
    print "<input type=\"text\" name=\"vkey\" id=\"vkey\" value=\"ccccccccccc\">\n";
    print "<input type=\"submit\" value=\"Record my opinions\">\n";
    print "</form>\n";
}

print "<h2>What to do next</h2>";
print "<p>No candidate or party will agree with you on all the issues. 
       Because the election requires you to select a single person rather than declare the policies 
       you support, your choice will necessarily be a compromise.  
       You can use this webpage to discover which candidates agree with you on most of the issues,
       and isolate the subjects that are of most concern.  
       Hopefully this will help you be better informed when you cast your ballot at the General Election.</p> 
       
       <p>If you are in a constituency with a sitting MP who is seeking re-election, this website helps you identify the 
       specific votes in Parliament where you believe they acted against the overwhelming opinion 
       of the people whom they represented.  The days leading up to the election is best time to 
       raise inconvenient questions about these specific votes, because this is the one moment when 
       the public's opinion really matters and the MP can be forced to defend his or her record.
       If no one checks the record, the MP cannot be held accountable to it, 
       either for voting with the party whip and against public opinion, or with public opinion and against the 
       party whip (hence sacrificing any possibility of a ministerial career), or 
       with their \"conscience\" and thus having an opinion of their own.</p>";

#print "<span id=\"tagth\"><a href=\"/\">Memory Hole</a><br/><select><option title=\"one\">OOOO</option></select></span>\n";
#print '<script type="text/javascript">Hithere();</script>';

print "</div>\n";
print "</body>\n";
print "</html>\n";


