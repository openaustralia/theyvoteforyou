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
$vterdet = $_GET["vterdet"];
$vpubem = $_GET["vpubem"];

if ($mpval)
{
    $mpprop = $mpval["mpprop"];
    $party = $mpprop["party"];
    $name = $mpprop["name"];
    $constituency = $mpprop["constituency"];
    $minentered_house = $mpval["minentered_house"];

    #print_r($mpval);
    $votes = GetVotes($db, $mpprop["person"], 1039);
    #print_r($rows);

    $part4_terroristcertification = GetVote($votes, "2001-11-21", 75);
    $part4_indefinitedetention = GetVote($votes, "2001-11-21", 76);
    $part4_siac = GetVote($votes, "2001-11-21", 77);
    $part4_privy = GetVote($votes, "2004-02-25", 59);
    $part4_renewal = GetVote($votes, "2004-03-03", 71);

    $d90days = GetVote($votes, "2005-11-09", 84);
    $d28days = GetVote($votes, "2005-11-09", 85);

    $d42days_enable = GetVote($votes, "2008-06-11", 219);
    $d42days_procedure = GetVote($votes, "2008-06-11", 220);

    print "<p>Your MP, <b>$name</b>,
           currently representing the constituency of <b>$constituency</b>,
           entered Parliament\n";
    if ($minentered_house == "1997-05-01")
        print " on or before the May 1997 General Election,\n";
    else
        print " on ".pretty_date($minentered_house).",\n";
    print " and was able to vote on the detention of terrorist suspects without charge ";
    print " for up to 42 days";
    if ($d90days <> "notmp")
        print " and 90 days.";
    else
        print " but not 90 days.";
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
    if ($part4_terroristcertification <> "notmp")
    {
        print "<tr><td>21&nbsp;November&nbsp;2001</td><td>Power of Home Secretary to certify people as terrorists</td><td>$part4_terroristcertification</td></tr>\n";
        print "<tr><td>21&nbsp;November&nbsp;2001</td><td>Ability to detain certified terrorists indefinitely if they are foreign</td><td>$part4_terroristcertification</td></tr>\n";
    }
    if ($part4_renewal <> "notmp")
    {
        print "<tr><td>3&nbsp;March&nbsp;2004</td><td>Renewal of the regime to detain foreign terrorists indefinitely</td><td>$part4_renewal</td></tr>\n";
    }
    if ($d90days <> "notmp")
    {
        print "<tr><td>9&nbsp;November&nbsp;2005</td><td>Extention of period of detention to 90 days</td><td>$d90days</td></tr>\n";
        print "<tr><td>9&nbsp;November&nbsp;2005</td><td>Extention of period of detention to 28 days (avoiding 60 days)</td><td>$d28days</td></tr>\n";
    }

    if ($d42days_enable <> "notmp")
    {
        print "<tr><td>11 June 2008</td><td>Define the conditions for detention up to 42 days</td><td>$d42days_enable</td></tr>\n";
        print "<tr><td>11 June 2008</td><td>Create the power to detain terrorist suspects up to 42 days</td><td>$d42days_procedure</td></tr>\n";
    }
    print "</table>\n";

    print "<div id=\"yourfav\">\n";
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
        print "<p>You are in favour of detaining terrorist suspects in connection to 
               the affairs of Northern Ireland for up to 7 days before charging 
               them with a crime.  
               This was the state of the law from 1974 until 2000 when the powers 
               of detention were widened to all terrorism-related acts.</p>";
    else
        print "<p>You are in favour of treating terrorism on the level of any other 
               crime, like murder, kidnapping, or rape, where the police have 
               no more than 48 hours to decide whether to charge someone they 
               have arrested, or let them go.  
               This was the state of the law until 1974 when a special case 
               was made for terrorism relating to Northern Ireland, but 
               it was not until 2000 when it was extended to all other sources of terrorism.</p>";
    print "</div>\n"; 

    #print_r($mpval);
    print "<p>Your selection was <b>$vterdet</b></p>\n";
    print "<p>We need some thoughts on how we are going to design this page to respond to the four options.  Also,
           the answers for David Davis and Boris Johnson's constituencies will be different.
           We can also add -- in special cases -- a: 'BTW, your MP also voted to exempt himself and Parliament from
           the Freedom of Information Act'.</p>\n";
    print "<p>The material we have to work with can be seen by <b>clicking <a href=\"/mp.php?".$mpval["mpprop"]["mpanchor"]."&dmp=1039\">here</a> to compare ";
    print $mpval["mpprop"]["fullname"]." to 'No detention without charge'.</b></p>\n";
    print "<p>We can begin with what we are going to say to someone who agrees it should be less than 28.</p>\n";
    print "<p>The next bubble along, Aidan, is probably ID cards, with questions like:\n";
    print "<a href=\"http://www.publicwhip.org.uk/division.php?date=2006-02-13&number=160&dmp=230\">Are you for or against the government having to publish a detailed report about their cost and benefits?</a>.</p>\n";
}


else
{
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

    print "<div id=\"checkmpbutton\"><input type=\"submit\" value=\"Check my MP\"></div>\n";
    print "</form>\n";

    print "<div id=\"footer\">Produced by the Public Whip</div>\n";

    print "</div>\n";
}


#print "<span id=\"tagth\"><a href=\"/\">Memory Hole</a><br/><select><option title=\"one\">OOOO</option></select></span>\n";
#print '<script type="text/javascript">Hithere();</script>';

print "</body>\n";
print "</html>\n";


