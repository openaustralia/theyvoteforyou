<html><head><title>Iraq war divisions</title></head>
<body>
<?php
# $Id: iraq.php,v 1.1 2003/10/08 11:05:54 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include "../db.inc";
include "../render.inc";
$db = new DB(); 

$issues = array(
# date, div-number, vote-being-marked, alignment-of-voter-who-votes-that-way, weight-for-sorting, colour
array('2002-09-24', '319', 'aye', 'good', '0', '0'),
array('2002-11-25', '6', 'noe', 'bad', '0', '0'),
array('2003-02-26', '97', 'aye', 'bad', '0', '5'),
array('2003-02-26', '96', 'noe', 'bad', '0', '0'),
array('2003-03-18', '118', 'aye', 'bad', '128', '10'),
array('2003-03-18', '117', 'noe', 'bad', '0', '5'),
array('2003-06-04', '217', 'noe', 'bad', '0', '0'),
array('2003-07-16', '294', 'noe', 'bad', '0', '0'),
array('2003-09-10', '307', 'noe', 'bad', '0', '0'));

$div_ids = array();
$newissues = array();
foreach ($issues as $key => $issue)
{
    # Read in data about the divisions
    $row = $db->query_one_row("select division_id from pw_division 
        where division_date = '$issue[0]' and division_number = '$issue[1]'");
    $newissues[$row[0]] = $issue;
    array_push($div_ids, $row[0]);
}
$issues = $newissues;

# Get list of all MPs
$mps = array();
$db->query("select mp_id, first_name, last_name, party from pw_mp");
while ($row = $db->fetch_row())
{
    $mps[$row[0]]['first'] = $row[1];
    $mps[$row[0]]['last'] = $row[2];
    $mps[$row[0]]['party'] = $row[3];
}

# Get all the relevant votes
$db->query("select mp_id, division_id, vote from pw_vote where division_id=" .
            join(" or division_id = ", $div_ids));
$votes = array();
while ($row = $db->fetch_row())
{
    $blobvote = $issues[$row[1]][2];
    if ($row[2] == $blobvote)
    {
        $votes[$row[0]][$row[1]] = "blob";
    }
    else
    {
        $votes[$row[0]][$row[1]] = "--";
    }
#    $votes[$row[0]][$row[1]] = $row[2];
}

# Sort the MPs by priority columns, and then by name
function vote_cmp($a, $b)
{
    global $issues, $votes, $mps;
    $acount = 0; $bcount = 0;
    foreach ($issues as $key => $issue)
    {
        if ($votes[$a][$key] == "blob" or $votes[$a][$key] == "")
        {
            $acount = $acount + $issue[4];
        }
        if ($votes[$b][$key] == "blob" or $votes[$b][$key] == "")
        {
            $bcount = $bcount + $issue[4];
        }
    }
    if ($acount != $bcount)
        return $bcount - $acount; 
    else
    {
        $cmp = strcasecmp($mps[$a]['last'] . $mps[$a]['first'],
            $mps[$b]['last'] . $mps[$b]['first']);
        return $cmp;
    }
}
uksort($mps, vote_cmp);

print "<table width=100%><tr><td width=50%>";
# Print out table
print "<table align=center><h2 align=center>Allowed war</h2>\n";
# ... header
print "<th>"; $i = 0; foreach ($issues as $key => $issue) { $i++; print "<td>$i</td>"; } print "</th>\n";
# ... body
$i = 0;
$last_initial = "A";
foreach (array_keys($mps) as $mp)
{
    $this_initial = substr($mps[$mp]['last'], 0, 1);
    if ($last_initial == "Y" && $this_initial == "A")
    {
        print "</table></td><td width=50% valign=top><table align=center><h2 align=center>Tried to veto war";
        print "<th>"; $i = 0; foreach ($issues as $key => $issue) { $i++; print "<td>$i</td>"; } print "</th>\n";
    }
    $last_initial = $this_initial;

    print "<tr>";
    $i++;
    print "<td>" . $mps[$mp]['first'] . " " . $mps[$mp]['last'] . " (" .  $mps[$mp]['party'] . ") </td>";
    foreach ($issues as $key => $issue)
    {       
        $blobvote = $votes[$mp][$key];
        if ($blobvote == "blob")
            $blobvote = "&bull;";
        else if ($blobvote == "--")
            $blobvote = "o";
        else 
            $blobvote = "-";
        $col = "";
        if ($issue[5] >= 9) { $col = "bgcolor=#ffff88";}
        else if ($issue[5] > 4) { $col = "bgcolor=#ffffdd";}
        print "<td $col>" . $blobvote . "</td>";
    }
    print "</tr>\n";
}
print "</table></td></tr></table>\n";

?>
<p align=center>Generated using data from <a href="http://www.publicwhip.org.uk">www.publicwhip.org.uk</a>

