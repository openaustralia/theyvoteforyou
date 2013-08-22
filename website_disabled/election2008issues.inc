<?php require_once "common.inc";

# The Public Whip, Copyright (C) 2008 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.


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
        $candidate["snum"] = 0.0; 
        $candidate["sden"] = 0.0; 
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


