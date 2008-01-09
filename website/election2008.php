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


$db = new DB();
$db2 = new DB();

# here is the data that will have to be loaded from the database
$constituency = "Brighton, Kemptown"; # mpc=urlencode()
$candidates = array();
$candidates[] = array("candidate_id" => 1, "name" => "Mr Desmond Turner", 
                      "url"=>"http://www.labouronline.org/wibs/165220/home",
                      "party" => "Lab", "votetype"=>"incumbent", "personid" => 10608,
                      "matchid" => "mpn=Desmond_Turner&mpc=Brighton%2C+Kemptown");
$candidates[] = array("candidate_id" => 2, "name" => "Mr Simon Kirby", 
                      "url"=>"http://www.kirbyforkemptown.org/",
                      "party" => "Con", "votetype"=>"party", "matchid" => "mpn=Michael_Fabricant");
$candidates[] = array("candidate_id" => 3, "name" => "Mr Ben Duncan",
                      "url"=>"http://www.brightonandhovegreenparty.org.uk/h/n/YOUR_REPS/queenspark/ALL///",
                      "party" => "Green", "votetype"=>"dream", "matchid" => "");
$candidates[] = array("candidate_id" => 4, "name" => "Mr Ben Herbert",
                      "url"=>"http://www.brightonandhove.libdems.org.uk/news/000332/lib_dems_select_new_chairperson.html",
                      "party" => "LDem", "votetype"=>"party", "matchid" => "mpn=Norman_Baker");

$candidates[] = array("candidate_id" => 5, "name" => "Mr Average Labour",
                      "url"=>"http://www.labour.org.uk",
                      "party" => "Lab", "votetype"=>"party", "matchid" => "mpn=Gordon_Brown");

# the issues to be compared against
$issues = array();
$issues[] = array("dream_id" => 963,  "name" => "Invade Iraq", 
                    "action" => "the 2003 invasion of Iraq");
$issues[] = array("dream_id" => 999,  "name" => "Investigate Iraq", 
                    "action" => "investigating the Iraq war");
$issues[] = array("dream_id" => 1001, "name" => "Public MPs", 
                    "action" => "the Freedom of Information Act applying to Parliament and MPs");
$issues[] = array("dream_id" => 1003, "name" => "Replace Trident", 
                    "action" => "replacing the Trident nuclear weapons system");
$issues[] = array("dream_id" => 1000, "name" => "Ban smoking", 
                    "action" => "the smoking ban in all public places");
$issues[] = array("dream_id" => 981,  "name" => "Control orders", 
                    "action" => "Control Orders for terrorist suspects");
$issues[] = array("dream_id" => 1009, "name" => "ID Cards", 
                    "action" => "compulsory biometric ID Cards and identity register for all citizens");
$issues[] = array("dream_id" => 852,  "name" => "Nuclear power", 
                    "action" => "new fissile nuclear power plants");
$issues[] = array("dream_id" => 856,  "name" => "Abolish Parliament",
                    "action" => "giving the government the power to summarily change any law");
$issues[] = array("dream_id" => 629,  "name" => "Parliament protest",
                    "action" => "allowing protests to take place around Parliament");
$issues[] = array("dream_id" => 358,  "name" => "Allow foxhunting",
                    "action" => "fox hunting should not be banned");
$issues[] = array("dream_id" => 367,  "name" => "Free universities",
                    "action" => "no university tuition fees");

function WriteEleSelectIssue($dreamid)
{
    print "<select id=\"issue-$dreamid\" onchange=\"UpdateCItable()\">\n";
    print "\t<option value=\"0\">indifferent about</option>\n";
    print "\t<option value=\"1\">in favour of</option>\n";
    print "\t<option value=\"3\">strongly in favour of</option>\n";
    print "\t<option value=\"-1\">against</option>\n";
    print "\t<option value=\"-3\">strongly against</option>\n";
    print "</select>\n";
}

function WriteEleIssueSection($issue)  # may replace function below
{
    print "\n\n<div class=\"sissue\">\n";
    print "I am ";
    WriteEleSelectIssue($issue["dream_id"]);
    print $issue["action"];
    $newsid = "news".$issue["dream_id"];
    print " <a onclick=\"shownews('$newsid', this)\" class=\"shownews\">show news</a>\n";
    WriteLongListNews($issue["name"], $newsid);
    print "</div>\n";
}

function WriteEleCalcIssueRow($issues)
{
    print "<tr class=\"issuerow\">\n";
    print "<td><a onmouseover=\"TagToTip('tagth', STICKY, true, DURATION, 8000, ABOVE, true)\">The Candidates</a></td>\n";
    print "<td>My views ---&gt;</td>\n";
    foreach ($issues as $issue)
        print "<td>".$issue["name"]."</td>\n";
    print "</tr>\n";
return;

    print "<tr class=\"issuerow2\">\n";
    print "<td class=\"mpcol\">Candidates</td>\n";
    print "<td class=\"myrankcol\">My score</td>\n";
    foreach ($issues as $issue)
    {
        print "<td>";
        WriteEleSelectIssue($issue["dream_id"]);
        print "</td>\n";
    }
    print "</tr>";
}

function GetPartyDistances($db, $dream_id)
{
    update_dreammp_person_distance($db, $dream_id);
    $qselect = "SELECT AVG(distance_a) as distance, party";
    $qfrom =   " FROM pw_cache_dreamreal_distance";
    $qjoin =   " LEFT JOIN pw_mp ON pw_mp.person = pw_cache_dreamreal_distance.person";
    $qwhere =  " WHERE house = 'commons' AND dream_id = '$dream_id'";
    $qgroup =  " GROUP BY party";

    $db->query($qselect.$qfrom.$qjoin.$qwhere.$qgroup);
    $partydistances = array();
    while ($row = $db->fetch_row_assoc())
        $partydistances[$row['party']] = ($row["distance"]);
    return $partydistances;
}

function GetIncumbentIssueDistances($db, $candidate, $dream_id)
{
    update_dreammp_person_distance($db, $dream_id);
    $person_id = $candidate["personid"];
    $qselect = "SELECT distance_a AS distance";
    $qfrom =   " FROM pw_cache_dreamreal_distance";
    $qwhere =  " WHERE pw_cache_dreamreal_distance.person = '$person_id' AND dream_id = '$dream_id'";
    $row = $db->query_onez_row_assoc($qselect.$qfrom.$qwhere);
    if (($row == null) || ($row["distance"] === null))
        return null;
    return strval($row["distance"] + 0.0);
}

function SetCandidateIssueDistances($db, &$candidates, $issues)
{
    foreach ($issues as $issue)
        $issuepartydistances[$issue["name"]] = GetPartyDistances($db, $issue["dream_id"]);

    foreach ($candidates as &$candidate)  # & required so we can set its value
    {
        foreach ($issues as $issue)
        {
            $partydistance = $issuepartydistances[$issue["name"]][$candidate["party"]];
            if ($candidate["votetype"] == "incumbent")
                $distance = GetIncumbentIssueDistances($db, $candidate, $issue["dream_id"]);
            else  # this is where we do the dreammp case
                $distance = $partydistance;
            $candidate["issuedistances"][$issue["name"]] = ($distance === null ? -1 : (float)$distance);
        }
    }
}

function DistanceToWord($distance)
{
    if ($distance == -1)
        return "Not<br/>present";
    if ($distance <= 0.2)
        return "strongly<br/>for";
    if ($distance <= 0.4)
        return "moderately<br/>for";
    if ($distance >= 0.8)
        return "strongly<br/>against";
    if ($distance >= 0.6)
        return "moderately<br/>against";
    return "mixed";
}

function CandidateTdEntry($candidate)
{
    $cid = $candidate["candidate_id"]."-name";
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
        print "<a href=\"http://www.publicwhip.org.uk/mp.php?dmp=".$issue["dream_id"];
        print '&amp;'.$candidate["matchid"].'"';#.'&display=motions"';
        print " onmouseover=\"Tip('Show comparison with MP or party')\">";
    }
    else
        print "<a href=\"http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"].'&display=motions">';
    if ($candidate["votetype"] == "incumbent")
        print "MP voted ";
    else if ($candidate["votetype"] == "party")
        print "Party voted ";
    else if (($candidate["votetype"] == "dream") && ($distance != -1))
        print "Party would have voted ";
    print DistanceToWord($distance)."</a></td>\n";
}

function WriteCandidateRow($candidate, $issues)
{
    $candidate_id = $candidate["candidate_id"];
    print "<tr class=\"candidaterow\">\n";
    print CandidateTdEntry($candidate);

    print "\t<td><div class=\"myrankcol\" id=\"$candidate_id-rank\">RK</div></td>\n";
    foreach ($issues as $issue)
        WriteCandidateIssueTd($candidate, $issue);
    print "</tr>";
}

function WriteIssueRow($issue, $candidates)
{
    print "<tr class=\"issuerow\" id=\"".$issue["dream_id"]."-row\">\n";
    #print "<th>".$issue["name"]."</th>\n";
    print "<th><a href=\"http://www.publicwhip.org.uk/policy.php?id=".$issue["dream_id"]."\">".$issue["name"]."</a></th>\n";
    foreach ($candidates as $candidate)
        WriteCandidateIssueTd($candidate, $issue);
    print "</tr>\n";
}

function WriteEleCalcTable($candidates, $issues)
{
    WriteEleCalcIssueRow($issues);
    foreach ($candidates as $candidate)
        WriteCandidateRow($candidate, $issues);
}

function WriteEleCalcTableTrans($issues, $candidates)
{
    print "<tr class=\"candidaterow\">\n";
    print "<td>Candidates:</td>\n";
    foreach ($candidates as $candidate)
        print CandidateTdEntry($candidate);
    print "</tr>\n";
    
    print "<tr><td>Agreement rating:</td>\n";
    foreach ($candidates as $candidate)
        print "\t<td><div class=\"myrankcol\" id=\"".$candidate['candidate_id']."-rank\">RK</div></td>\n";
    print "</tr>\n";
    
    foreach ($issues as $issue)
        WriteIssueRow($issue, $candidates);
}

function WriteJavascriptElecTable($candidates, $issues)
{
    print "// issue user-opinion map\n";
    print "var issues = ";
    for ($i = 0; $i < count($issues); $i++)
        print ($i == 0 ? "[" : ", ").$issues[$i]["dream_id"];
    print "];\n";
    print "var candidates = ";
    for ($j = 0; $j < count($candidates); $j++)
        print ($j == 0 ? "[" : ", ").$candidates[$j]["candidate_id"];
    print "];\n\n";

    print "// candidate-issue distance table\n";
    print "var citable = [ \n";
    foreach ($candidates as $candidate)
    {
        print "  [";
        foreach ($issues as $issue)
        {
            $distance = $candidate["issuedistances"][$issue["name"]];
            print "$distance, ";
        }
        print "],\n";
    }
    print "     ];\n";
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
print "<h1 id=\"th1\"><a href=\"/\"><span class=\"fir\">The Public Whip</span></a></h1>\n";
print "<h2 id=\"howtheyvoted\">How They Voted 2008</h2>\n";
print "<h3 id=\"th3\">(...and so should you)</h3>\n";
print "<h4 id=\"th4\">The candidate calculator for <i>$constituency</i></h4>\n";
print "<p></p>\n\n";

SetCandidateIssueDistances($db, $candidates, $issues);

print "<script type=\"text/javascript\">\n";
WriteJavascriptElecTable($candidates, $issues);
print "</script>\n";

print "<h2>My opinions</h2>\n";
print "<p><b>Instructions:</b> Select some or all of your opinions, and see how they compare to the candidate's 
       voting record, if they are the incumbent, or the party's voting record in Parliament. 
       For parties which have no representation in Parliament (eg the Green party), a hypothetical voting record 
       can be supplied by ticking off the way an MP of that party would have voted from the 
       <a href=\"http://www.publicwhip.org.uk/divisions.php\">list of all votes</a> 
       using a policy object such as <a href=\"http://www.publicwhip.org.uk/policy.php?id=1013\">this</a>.";


print "<div class=\"sissues\">\n";
$nic = (int)(count($issues) / 2);
print "<table><tr><td>\n";
#print "<div class=\"sissuecol2\">\n";
for ($i = $nic; $i < count($issues); $i++)
    WriteEleIssueSection($issues[$i]);
print "</td><td>\n";
#print "</div>\n<div class=\"sissuecol1\">\n";
for ($i = 0; $i < $nic; $i++)
    WriteEleIssueSection($issues[$i]);
print "</td></tr></table>\n";
#print "</div>\n";
print "</div>\n\n";

print "<h2>How my opinions compare to the candidates' voting record</h2>\n";
print "<p>This rating depends <b>only</b> on their voting record in Parliament (if they are an incumbent), 
       or the average voting record of all MPs of the same party if they are a challenger,
       or the hypothetical voting pattern if they belong to a party that has had no MPs in Parliament.</p>
       <p>Click on the name of the candidate to go to their campaign website for further details.</p>
       ";

print "<table class=\"elecalc\">\n";
#WriteEleCalcTable($candidates, $issues);
WriteEleCalcTableTrans($issues, $candidates);
print "</table>\n";

print "<h2>What to do next</h2>";
print "<p>No candidate can agree with you on all the issues you believe in.";
print " Please use this webpage to find those votes in Parliament in the name of the candidate you support";
print " that you most disagree with, and ask them about it during the campaign.";

#print "<span id=\"tagth\"><a href=\"/\">Memory Hole</a><br/><select><option title=\"one\">OOOO</option></select></span>\n";
#print '<script type="text/javascript">Hithere();</script>';

print "</div>\n";
print "</body>\n";
print "</html>\n";


