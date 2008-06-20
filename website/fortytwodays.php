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
require_once "postcode.inc";


function GetVotes($db, $person, $dreamid)
{
    $qselect = "SELECT pw_division.division_date AS date, pw_division.division_number AS number, pw_vote.vote AS vote";
    $qfrom = " FROM pw_dyn_dreamvote";
    $qjoin = " LEFT JOIN pw_division ON pw_division.division_date = pw_dyn_dreamvote.division_date
                                    AND pw_division.division_number = pw_dyn_dreamvote.division_number
                                    AND pw_division.house = pw_dyn_dreamvote.house";
    $qjoin .= " LEFT JOIN pw_mp ON pw_mp.person = $person";
    $qjoin .= " LEFT JOIN pw_vote ON pw_vote.mp_id = pw_mp.mp_id
                                 AND pw_vote.division_id = pw_division.division_id";
    $qwhere = " WHERE pw_dyn_dreamvote.dream_id = $dreamid";
    $qwhere .= " AND (pw_division.division_date >= pw_mp.entered_house AND pw_division.division_date < pw_mp.left_house)";

    $db->query($qselect.$qfrom.$qjoin.$qwhere);
    $res = array();
    while ($row = $db->fetch_row_assoc())
        $res[] = $row;
    return $res;
}

function GetVote($votes, $date, $number)
{
    foreach ($votes as $vote)
    {
        if ($vote["date"] == $date and $vote["number"] == $number)
            return ($vote["vote"] ? $vote["vote"] : "absent");
    }
    return "notmp";
}

function WriteYourSummary($vterdet)
{
    if ($vterdet == "ind")
    {
        print "<p>You are in favour of indefinite detention without charge of
                foreign nationals who are terrorist suspects.  This law came into
                force in December 2001, and approximately 20 people were held
                without charge in Belmarsh Prison.</p>
               <p>Unfortunately it didn't last because the law was overturned by
                the Law Lords in December 2004 as it violated the
                European Convention on Human Rights -- the right to be brought to trial
                after arrest -- and the fact that it discriminated against foreigners
                who were no more likely to commit terrorist acts than UK citizens.</p>";
    }
    else if ($vterdet == "90")
    {
        print "<p>You are in favour of detaining terrorist suspects for up to 90 days
                before telling them of the crime they have committed.
                This was proposed by Tony Blair's government in November 2005,
                but MPs voted against it by a majority of 31.";
        if ($d90days == "no")
            print "Your MP was among those voting against it.";
        print "</p>\n";
    }
    else if ($vterdet == "42")
    {
        print "<p>You are in favour of detaining terrorist suspects for up to 42 days
                before telling them of the crime they have committed.
                This was voted through by MPs on 11 June this year.</p>\n";
    }
    else if ($vterdet == "28")
    {
        print "<p>You are in favour of detaining terrorist suspects for up to 28 days
                before telling them of the crime they have committed.
                This was the state of the law between March 2006 and now,
                when the time limit is in the process of being revised upwards to 42 days.</p>\n";
    }
    else if ($vterdet == "14")
    {
        print "<p>You are in favour of detaining terrorist suspects for up to 14 days
               before telling them of the crime they have committed.
               This was the state of the law between November 2003 and March 2006.</p>\n";
    }
    else if ($vterdet == "7")
    {
        print "<p>You are in favour of detaining terrorist suspects for up to 7 days
               before telling them of the crime they have committed.
               This is five days beyond the maximum period for other types of crime,
               and was the state of the law between 2000 and November 2003.</p>\n";
    }
    else if ($vterdet == "7i")
    {
        print "<p>You are in favour of detaining terrorist suspects in connection to
               the affairs of Northern Ireland for up to 7 days before charging
               them with a crime.
               This was the state of the law from 1974 until 2000 when the powers
               of detention were widened to all terrorism-related acts.</p>";
    }
    else if ($vterdet == "2")
    {
        print "<p>You are in favour of treating terrorism on the level of any other
               crime, like murder, kidnapping, or rape, where the police have
               no more than 48 hours to decide whether to charge someone they
               have arrested, or let them go.
               This was the state of the law until 1974 when a special case
               was made for terrorism relating to Northern Ireland, but
               it was not until 2000 when it was extended to all other sources of terrorism.</p>";
    }
    else if ($vterdet)
        print "<p>Not recognized: $vterdet</p>\n";
}


function WriteMPvoterow($mpanchor, $vnvote)
{
    if ($vnvote[3] == "notmp")
        return;
    print "<tr><td>".pretty_date($vnvote[0])."</td>";
    print "<td><a href=\"http://www.publicwhip.org.uk/division.php?date=".$vnvote[0]."&number=".$vnvote[1]."&$mpanchor\">";
    print $vnvote[2];
    print "</a></td>";
    print "<td>".$vnvote[3]."</td>";
    print "</tr>\n";
}

function WriteMPvotetable($vnvotes, $vterdet, $vpubem, $mpanchor)
{
    # could also add a colour in to the aye column according to vterdet
    WriteMPvoterow($mpanchor, $vnvotes["part4_terroristcertification"]);
    WriteMPvoterow($mpanchor, $vnvotes["part4_indefinitedetention"]);
    WriteMPvoterow($mpanchor, $vnvotes["public_emergency"]);
    WriteMPvoterow($mpanchor, $vnvotes["part4_renewal"]);
    WriteMPvoterow($mpanchor, $vnvotes["d90days"]);
    WriteMPvoterow($mpanchor, $vnvotes["d28days"]);
    WriteMPvoterow($mpanchor, $vnvotes["d42days_procedure"]);
}

function WriteTimeline()
{
    print "<ul>
           <li>1974 1986 1989 Temporary Provisions (up to seven days)</li>
           <li>2000 7 days Terrorism Act</li>
           <li>2001 indefinitely for foreign nationals - Anti-Terrorism Act</li>
           <li>2001 public emergency declared</li>
           <li>2003 14 days Criminal Justice Act</li>
           <li>2004 (indefinite detention struck down due to violation of ECHR)</li>
           <li>2005 public emergency lifted</li>
           <li>2006 28 days Terrorism Act</li>
           <li>2008 42 days Counter-Terrorism Act</li>
           </ul>
          ";
}

function WritePubemChart($vpubem)
{
    $query = "SELECT SUM(vpubem = 'no-disagree') AS no_disagree,
                     SUM(vpubem = 'no-agree') AS no_agree,
                     SUM(vpubem = 'yes-agree') AS yes_agree,
                     SUM(vpubem = 'yes-disagree') AS yes_disagree,
                     COUNT(vpubem is not NULL) AS total
              FROM pw_logincoming
              LEFT JOIN pw_dyn_fortytwoday_comments ON pw_dyn_fortytwoday_comments.vrand = pw_logincoming.thing_id
             ";
	$row = $db2->query_one_row_assoc($query);
    print "<table><tr><th>Didn't know<br/>don't agree</th><th>Didn't know<br/>but agree</th>
                      <th>Knew<br/>and agree</th><th>Knew<br/>but disagreed</th></tr>";
    print "<tr><td>".$row["no_disagree"]."</td><td>".$row["no_agree"]."</td>
               <td>".$row["yes_agree"]."</td><td>".$row["yes_disagree"]."</td></tr>";
    print "</table>\n";
}

# start of output
$db = new DB();
$db2 = new DB();

header("Content-Type: text/html; charset=UTF-8");

print "<html>\n";
print "<head>\n";
print "<title>The Public Whip - Forty-Two Days</title>\n";
print "<link href=\"publicwhip.css\" type=\"text/css\" rel=\"stylesheet\"/>\n";
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n";

print "<style type=\"text/css\">\n";
print "
body { width:800px; margin-left:auto; margin-right:auto; }
input { color: #303070 }
div#Zopform {  border: thin black solid; padding: 10px }
div.quessec { border: thin black solid; padding: 10px; margin-top:10px; }
div.oprad { margin-top:10px; padding:5px; background-color:#e0e0d0; font-size:120%;}
div#checkmpbutton { font-size: 200%; text-align:center; margin:10px;}
div#footer { background-color:black; color:white;  border: thin black solid; }
table.votetab td { border: thin black solid; }
div#yourfav { background-color:#fed9d8; }
    ";

print "</style>\n";

print "</head>\n";
print "<body class=\"fortytwodays\">\n";
#print "<script type=\"text/javascript\" src=\"quiz/election2008.js\"></script>\n";

print "<h1>The Public Whip - Forty-two days</h1>\n";
#print "<h4 id=\"th4\">The candidate calculator for <i>$constituency</i></h4>\n";
#print "<p></p>\n\n";

if (is_postcode($_GET["mppc"]) or $_GET["mpc"])
    $mpval = get_mpid_attr_decode($db, $db2, "");
$vterdet = db_scrub($_GET["vterdet"]);
$vpubem = db_scrub($_GET["vpubem"]);
$vrand = db_scrub($_GET["vrand"]);
if ($vrand)
    $vrand = (int)$vrand;
else
    $vrand = rand(10, 10000000);

$vdash = mysql_escape_string(db_scrub($_GET["dash"])); # used to tell if /by-election or /byelection was used

$referrer = $_SERVER["HTTP_REFERER"];
$querystring = $_SERVER["QUERY_STRING"];
$ipnumber = $_SERVER["REMOTE_ADDR"];
if (!$referrer)
    $referrer = $_SERVER["HTTP_USER_AGENT"];

if ($mpval)
{
    $mpprop = $mpval["mpprop"];
    $party = $mpprop["party"];
    $name = $mpprop["name"];
    $constituency = $mpprop["constituency"];
    $minentered_house = $mpval["minentered_house"];

    $vnvotes = array(
        "part4_terroristcertification" => array("2001-11-21", 75, "Power of Home Secretary to certify individuals as terrorists"),
        "part4_indefinitedetention" => array("2001-11-21", 76, "Power to detain certified terrorists indefinitely if foreign"),
        "public_emergency" => array("2001-11-21", 70, "Declaration of public emergency threatening the life of the nation"),
        "part4_siac" => array("2001-11-21", 77),
        "part4_privy" => array("2004-02-25", 59),
        "part4_renewal" => array("2004-03-03", 71, "Renewal of law for detaining certified international terrorists indefinitely"),
        "d90days" => array("2005-11-09", 84, "Extention of period of detention without charge to 90 days"),
        "d28days" => array("2005-11-09", 85, "Extention of period of detention without charge to 28 days"),
        "d42days_enable" => = array("2008-06-11", 219, "Conditions to enable detention without charge up to 42 days"),
        "d42days_procedure" => array("2008-06-11", 220, "Power to detain suspects without charge for up to 42 days"),
                    )

    # book the values into a database
    $db->query("drop table if exists pw_dyn_fortytwoday_comments");
    $db->query("create table pw_dyn_fortytwoday_comments (vterdet varchar(10), vpubem varchar(10), ltime timestamp, vrand int, vpostcode varchar(20), constituency varchar(80))");
    $db->query("INSERT INTO pw_dyn_fortytwoday_comments (vterdet, vpubem, ltime, vrand, vpostcode, constituency)
                VALUES ('$vterdet', '$vpubem', NOW(), $vrand, '$vpostcode', '".mysql_escape_string($constituency)."')");

    # looks up as a batch.  Or we could look up individually for easier coding
    $votes = GetVotes($db, $mpprop["person"], 1039);
    foreach ($vnvotes as $vname => &$vnvote)
        $vnvote[] = GetVote($votes, $vnvote[0], $vnvote[1]);

    print "<p><b>$name</b>,
           represents the constituency of <b>$constituency</b> and
           entered Parliament\n";
    if ($minentered_house == "1997-05-01")
        print " on or before the May 1997 General Election,\n";
    else
        print " on ".pretty_date($minentered_house).",\n";
    print " which means they were able to vote on the detention of terrorist suspects without charge ";
    print " for up to 42 days";
    if ($d90days <> "notmp")
        print " and to 90 days.";
    else
        print " but not to 90 days.";
    print "</p>\n";

    print "<p>\n";
    if ($minentered_house <= "2001-11-21")
        print " $name was also in Parliament for the votes which established detention without charge or trial of
                foreign nationals whom the Home Secretary believed were terrorists.";
    else if ($minentered_house <= "2004-03-03")
        print " $name was not in Parliament for the vote which established detention without charge of
                foreign nationals whom the Home Secretary believed were terrorists, but was there
                when MPs voted to renew these powers were renewed.";
    else
        print " $name was not in Parliament at the time when MPs established detention without charge of
                foreign nationals whom the Home Secretary believed were terrorists.";
    print "</p>\n";

    print "<p>The votes on these issues were as follows:</p>\n";
    print "<table class=\"votetab\">\n";
    WriteMPvotetable($vnvotes, $vterdet, $vpubem, $mpprop["mpanchor"]);
    print "</table>\n";

    print "<div id=\"yourfav\">\n";
    WriteYourSummary($vterdet);
    print "</div>\n";

    print "<div id=\"lawsummary\">\n";
    WriteTimeline();
    print "</div>\n";

    print "<div id=\"pubemchart\">\n";
    print "<h2>Responses to public emergency question</h2>";
    WritePubemChart($vpubem);
    print "</div>\n";
}


else
{
    if (!isrobot() and !preg_match("/.*?house=z/", $querystring))
    {
        $db->query("INSERT INTO pw_logincoming
                (referrer, ltime, ipnumber, page, subject, url, thing_id)
                VALUES ('$referrer', NOW(), '$ipnumber', 'fortytwodays', '', '$vdash', $vrand)");
    }

    print "<p>Fill in this form to find out if your MP
           agrees with you, according to their votes in Parliament.
           </p>";

    print "<div id=\"opform\">\n";
    print "<form action=\"http://www.publicwhip.org.uk/fortytwodays.php\" method=\"get\">\n";

    print "<div class=\"quessec\">Your postcode: <input type=\"text\" name=\"mppc\" id=\"mppc\" size=\"8\"> </input>
           or Parliamentary Constituency: <input type=\"text\" name=\"mpc\" id=\"mpc\"> </input> </div>\n";

    print "<div class=\"quessec\">\n";
    print "<div>How long should the police be allowed to detain someone as a suspected terrorist
                   without telling them what crime they may have committed?</div>\n";
    print "<div class=\"oprad\">\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"ind\">indefinitely (applies only to foreigners)</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"90\">up to 90 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"42\">up to 42 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"28\">up to 28 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"14\">up to 14 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"7\">up to 7 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"7i\">up to 7 days (only in connection with Northern Ireland)</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"2\">up to 2 days (in line with other violent crime)</input></div>\n";
    print "</div>\n";
    print "</div>\n";

    print "<div class=\"quessec\">\n";
    print "<div>Did you know that the Home Secretary declared a
           <em><b>'public emergency threatening the life of the nation'</b></em> between November 2001 and April 2005,
           within the meaning of <a href=\"http://www.hri.org/docs/ECHR50.html#C.Art15\">Article 15(1)</a>
           of the European Convention of Human Rights?\n";
    print "<a href=\"http://www.opsi.gov.uk/si/si2001/20013644.htm\">[1]</a> <a href=\"http://www.opsi.gov.uk/si/si2005/20051071.htm\">[2]</a> <a href=\"http://www.hri.org/docs/ECHR50.html#C.Art15\">[3]</a></p></div>\n";
    print "<div class=\"oprad\">\n";
    print "<div><input type=\"radio\" name=\"vpubem\" value=\"no-disagree\">No, and I don't agree with it</input></div>\n";
    print "<div><input type=\"radio\" name=\"vpubem\" value=\"no-agree\">No, but I'm glad it happened</input></div>\n";
    print "<div><input type=\"radio\" name=\"vpubem\" value=\"yes-agree\">Yes, and I think it was right</input></div>\n";
    print "<div><input type=\"radio\" name=\"vpubem\" value=\"yes-disagree\">Yes, but I believe it was unjustified</input></div>\n";
    print "</div>\n";
    print "</div>\n";

    print "<div style=\"display:block\">Random number: <input type=\"text\" name=\"vrand\" id=\"vrand\" value=\"$vrand\" readonly></div>\n";

    print "<div id=\"checkmpbutton\"><input type=\"submit\" value=\"Check my MP\"></div>\n";

    print "</form>\n";

    print "<div id=\"footer\">Produced by the Public Whip</div>\n";

    print "</div>\n";
}


#print "<span id=\"tagth\"><a href=\"/\">Memory Hole</a><br/><select><option title=\"one\">OOOO</option></select></span>\n";
#print '<script type="text/javascript">Hithere();</script>';

print "</body>\n";
print "</html>\n";


