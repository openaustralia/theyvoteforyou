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
    print_r($mpval["mpprop"]);
    $votes = GetVotes($db, $mpval["mpprop"]["person"], 1039);
    print_r($rows);

    print "<h1>".GetVote($votes, "2001-11-21", 75)."</h1>\n";
    $d90days = GetVote($votes, "2001-11-21", 75);
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


