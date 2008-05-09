<?php require_once "common.inc";

# The Public Whip, Copyright (C) 2008 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.


# here is the data that will have to be loaded from the database
$constituency = "Crewe and Nantwich"; # mpc=urlencode()
$candidatesA = array();

$candidatesA[] = array("name" => "Tamsin Dunwoody",
                      "url"=>"http://www.creweandnantwichlabour.org.uk/",
                      "party" => "Labour", 
                      "party_code" => "Lab", "votetype"=>"party", "matchid" => "party=Lab",
                      "party_url" => "http://www.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmGB=1&frmPartyID=6&frmType=partydetail");

$candidatesA[] = array("name" => "Gwyneth Dunwoody", 
                      "url"=>"http://www.gwynethdunwoody.co.uk/",
                      "party" => "Labour", "votetype"=>"leftoffice", "personid" => 10181,
                      "matchid" => "mpn=Gwyneth_Dunwoody&mpc=Crewe+%26amp%3B+Nantwich");

$candidatesA[] = array("name" => "Gemma Garrett",
                       "party_code" => "BfB",
                       "party" => "Independent");

$candidatesA[] = array("name" => "Mike Nattrass",
                      "url"=>"http://www.ukip.org/ukip/index.php?option=com_content&task=view&id=616&Itemid=57",
                      "party_code" => "UKIP",
                      "party" => "United Kingdom Independence Party",
                      "party_url" => "http://www.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmGB=1&frmPartyID=60&frmType=partydetail");

$candidatesA[] = array("name" => "David Roberts",
                       "url" => "http://www.englishdemocrats.org.uk",
                       "party_code" => "ED",
                       "party" => "English Democrats",
                       "party_url" => "http://www.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmGB=1&frmPartyID=114&frmType=partydetail");

$candidatesA[] = array("name" => "Elizabeth Shenton",
                      "url"=>"http://www.elizabethshenton.com/",
                      "party" => "Liberal Democrats", 
                      "party_code" => "LDem", "votetype"=>"party", "matchid" => "party=LDem",
                      "party_url" => "http://www.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmGB=1&frmPartyID=26&frmType=partydetail");

$candidatesA[] = array("name" => "Robert Smith",
                       "url" => "http://eastcheshire.greenparty.org.uk/",
                       "party_code" => "Green",
                       "party" => "Green Party",
                       "party_url" => "http://www.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmGB=1&frmPartyID=64&frmType=partydetail");

$candidatesA[] = array("name" => "Paul Thorogood",
                       "url"=>"http://www.cuttaxonpetrol.co.uk/",
                       "party_code" => "Diesel",
                       "party" => "Cut Tax on Petrol and Diesel",
                       "party_url" => "http://www.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmGB=1&frmPartyID=834&frmType=partydetail");

$candidatesA[] = array("name" => "Edward Timpson", 
                      "url"=>"http://www.creweandnantwichconservatives.com/",
                      "party" => "Conservatives",
                      "party_code" => "Con", "votetype"=>"party", "matchid" => "party=LDem",
                      "party_url" => "http://www.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm?frmGB=1&frmPartyID=25&frmType=partydetail");

$candidatesA[] = array("name" => "Mark Walklate",
                      "party_code" => "Walklate",
                      "party" => "Independent",
                      );


# filter out list and apply the matchids to these columns
$candidates = array();
for ($i = 0; $i < count($candidatesA); $i++)
{
    $candidatesA[$i]["candidate_id"] = $i + 10; 
    if ($candidatesA[$i]["matchid"])
        $candidates[] = $candidatesA[$i];
}


# the issues to be compared against
$issues = array();
$issues[] = array("dream_id" => 1012,  "name" => "Post offices", 
                    "action" => "the Government's post office modernisation programme");
$issues[] = array("dream_id" => 963,  "name" => "Invade Iraq", 
                    "action" => "the 2003 invasion of Iraq");
$issues[] = array("dream_id" => 975,  "name" => "Investigate Iraq", 
                    "action" => "investigating the Iraq war");
$issues[] = array("dream_id" => 1001, "name" => "Public MPs", 
                    "action" => "the Freedom of Information Act continuing to apply to MPs and Parliament");
$issues[] = array("dream_id" => 1003, "name" => "Replace Trident", 
                    "action" => "replacing the Trident submarine-launched nuclear weapons system");
$issues[] = array("dream_id" => 1000, "name" => "Ban smoking", 
                    "action" => "banning smoking in all public places");
$issues[] = array("dream_id" => 981,  "name" => "Control orders", 
                    "action" => "Control Orders for terrorist suspects");
$issues[] = array("dream_id" => 1009, "name" => "ID Cards", 
                    "action" => "compulsory biometric ID Cards and identity register for all citizens");
$issues[] = array("dream_id" => 852,  "name" => "Nuclear power", 
                    "action" => "new civil nuclear power plants");
$issues[] = array("dream_id" => 856,  "name" => "Abolish Parliament",
                    "action" => "giving the Government the power to summarily change any law without a vote in Parliament");
$issues[] = array("dream_id" => 629,  "name" => "Parliament protest",
                    "action" => "allowing protests to take place around Parliament");
$issues[] = array("dream_id" => 1034,  "name" => "Ban fox hunting",
                    "action" => "the total ban on fox hunting");
$issues[] = array("dream_id" => 1035,  "name" => "University tuition fees",
                    "action" => "that universities should be allowed to charge the students tuition fees");


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
            $partydistance = $issuepartydistances[$issue["name"]][$candidate["party_code"]];
            if (($candidate["votetype"] == "incumbent") or ($candidate["votetype"] == "leftoffice"))
                $distance = GetIncumbentIssueDistances($db, $candidate, $issue["dream_id"]);
            else  # this is where we do the dreammp case
                $distance = $partydistance;
            $candidate["issuedistances"][$issue["name"]] = ($distance === null ? -1 : (float)$distance);
        }
    }
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


