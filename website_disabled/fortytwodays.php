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
    global $pwpdo;
    $qselect = "SELECT pw_division.division_date AS date, pw_division.division_number AS number, pw_vote.vote AS vote";
    $qfrom = " FROM pw_dyn_dreamvote";
    $qjoin = " LEFT JOIN pw_division ON pw_division.division_date = pw_dyn_dreamvote.division_date
                                    AND pw_division.division_number = pw_dyn_dreamvote.division_number
                                    AND pw_division.house = pw_dyn_dreamvote.house";
    $qjoin .= " LEFT JOIN pw_mp ON pw_mp.person = ?";
    $qjoin .= " LEFT JOIN pw_vote ON pw_vote.mp_id = pw_mp.mp_id
                                 AND pw_vote.division_id = pw_division.division_id";
    $qwhere = " WHERE pw_dyn_dreamvote.dream_id = ?";
    $qwhere .= " AND (pw_division.division_date >= pw_mp.entered_house AND pw_division.division_date < pw_mp.left_house)";

    $query=$qselect.$qfrom.$qjoin.$qwhere;
    $pwpdo->query($query,array($person,$dreamid));
    $res = array();
    while ($row = $pwpdo->fetch_row())
        $res[] = $row;
    return $res;
}

function GetDreamDistance($db, $person, $dreamid)
{
    global $pwpdo;
    $query = "SELECT distance_a AS distance FROM pw_cache_dreamreal_distance WHERE dream_id=? AND person=?";
    $row=$pwpdo->get_single_row($query,array($dreamid,$person));
    return ($row ? $row["distance"] : 0.5); 
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
        print "<p>You agree with indefinite detention without charge of
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
        print "<p>You agree with detaining terrorist suspects for up to 90 days
                before telling them of the crime they have committed.
                This was proposed by Tony Blair's government in November 2005,
                but MPs voted against it by a majority of 31.";
        if ($d90days == "no")
            print "Your MP was among those voting against it.";
        print "</p>\n";
    }
    else if ($vterdet == "42")
    {
        print "<p>You agree with detaining terrorist suspects for up to 42 days
                before telling them of the crime they have committed.
                This was voted through by MPs on 11 June this year.</p>\n";
    }
    else if ($vterdet == "28")
    {
        print "<p>You agree with detaining terrorist suspects for up to 28 days
                before telling them of the crime they have committed.
                This was the state of the law between March 2006 and now,
                when the time limit is in the process of being revised upwards to 42 days.</p>\n";
    }
    else if ($vterdet == "14")
    {
        print "<p>You agree with detaining terrorist suspects for up to 14 days
               before telling them of the crime they have committed.
               This was the state of the law between November 2003 and March 2006.</p>\n";
    }
    else if ($vterdet == "7")
    {
        print "<p>You agree with detaining terrorist suspects for up to 7 days
               before telling them of the crime they have committed.
               This is five days beyond the maximum period for other types of crime,
               and was the state of the law between 2000 and November 2003.</p>\n";
    }
    else if ($vterdet == "7i")
    {
        print "<p>You agree with detaining terrorist suspects in connection with 
               the affairs of Northern Ireland for up to 7 days before charging
               them with a crime.
               This was the state of the law from 1974 until 2000 when the powers
               of detention were widened to encompass all terrorism-related acts.</p>";
    }
    else if ($vterdet == "2")
    {
        print "<p>You agree with treating terrorism on the level of any other
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


function WriteMPvoterow($mpanchor, $a, $vnvote)
{
    if ($vnvote[3] == "notmp")
        return;
    $vv = $vnvote[3];
    if ($vv == "tellno")
        $vv = "no"; 
    if ($vv == "tellaye")
        $vv = "aye"; 
    if ((($a == "aye") && ($vv == "aye")) || (($a == "no") && ($vv == "no")))
        print "<tr class=\"agree\">\n"; 
    else if ((($a == "aye") && ($vv == "no")) || (($a == "no") && ($vv == "aye")))
        print "<tr class=\"disagree\">\n"; 
    else 
        print "<tr>\n"; 

    print "<td>".pretty_date($vnvote[0])."</td>";
    print "<td><a href=\"http://www.publicwhip.org.uk/division.php?date=".$vnvote[0]."&number=".$vnvote[1]."&$mpanchor\">";
    print $vnvote[2];
    print "</a></td>";
    if ($vv == "aye")
        $vv = "for"; 
    if ($vv == "no")
        $vv = "against";
    print "<td>$vv</td>";
    print "</tr>\n";
}

function WriteMPvotetable($vnvotes, $vterdet, $vpubem, $mpanchor)
{
    # could also add a colour in to the aye column according to vterdet
    $aind = ($vterdet == "ind" ? "aye" : "no"); 
    $apubem = ((($vpubem == "no-agree") || ($vpubem == "yes-agree")) ? "aye" : "no"); 
    $a90 = ((($vterdet == "90") || ($vterdet == "ind")) ? "aye" : "no"); 
    $a42 = ((($vterdet == "90") || ($vterdet == "42") || ($vterdet == "ind")) ? "aye" : "no"); 
    WriteMPvoterow($mpanchor, $aind, $vnvotes["part4_terroristcertification"]);
    WriteMPvoterow($mpanchor, $aind, $vnvotes["part4_indefinitedetention"]);
    WriteMPvoterow($mpanchor, $apubem, $vnvotes["public_emergency"]);
    WriteMPvoterow($mpanchor, $aind, $vnvotes["part4_renewal"]);
    WriteMPvoterow($mpanchor, $a90, $vnvotes["d90days"]);
    WriteMPvoterow($mpanchor, "", $vnvotes["d28days"]);
    WriteMPvoterow($mpanchor, $a42, $vnvotes["d42days_enable"]);
    WriteMPvoterow($mpanchor, $a42, $vnvotes["d42days_procedure"]);
}

function WriteTimeline()
{
    print "<h2>Brief history of detention without charge in the UK</h2>\n";
    print "<p>Terrorist activity and terrorist laws in the UK have varied considerably 
           over the past 40 years.  This is a potted history 
           of recent legislative changes, and their justification.
           For a reasonably comprehensive list of terrorist incidents 
           since 1939, go <a href=\"http://en.wikipedia.org/wiki/List_of_terrorist_incidents_in_the_United_Kingdom\">here</a>.</p>\n"; 

    print "<div class=\"dethist\">\n";
    print "<ul>
           <li>1974 - The <a href=\"http://en.wikipedia.org/wiki/Prevention_of_Terrorism_Acts\">Prevention of Terrorism Acts</a>,
                passed in response to the bombing campaign by the IRA, allowed for people suspected of
                involvement to be held for an additional <b>5 days</b> beyond the initial period of 48 hours.
                These measures were controversial and labelled \"Temporary Provisions\" and needed to be renewed every year.</li>
           <li>1998 - <a href=\"http://www.opsi.gov.uk/acts/acts1998/ukpga_19980042_en_1\">The Human Rights Act 1998</a> was passed, finally making the
                <a href=\"http://www.hri.org/docs/ECHR50.html\">European Convention on Human Rights</a>
                part of UK law 5 decades after it had been originally drafted.
                It contained a <a href=\"http://www.opsi.gov.uk/acts/acts1998/ukpga_19980042_en_5#sch3\">special section</a>
                discussing the situation.</li>
           <li>2000 - The <a href=\"http://www.opsi.gov.uk/acts/acts2000/ukpga_20000011_en_1\">Terrorism Act 2000</a> was passed and made the <b>7 day</b>
                police detention of terrorist
                suspects permanent, although there was <a href=\"http://www.publications.parliament.uk/pa/cm199900/cmhansrd/vo000315/debtext/00315-41.htm\">advice</a>
                that it should be revised down to 4 days.</li>
           <li>2001, September 11 - A terrorist attack against the United States (not the United Kingdom)
                which \"changed everything\".</li>
           <li>2001, November 13 - A public emergency threatening the life of the nation is <a href=\"http://www.opsi.gov.uk/si/si2001/20013644.htm\">declared</a>
                by the Home Secretary for the purpose of implementing the Anti-Terrorism, Crime and Security Act.</li>
           <li>2001, December 14 - The <a href=\"http://www.opsi.gov.uk/acts/acts2001/ukpga_20010024_en_1\">Anti-Terrorism, Crime and Security Act 2001</a>
                passes into law, which includes the
                <a href=\"http://en.wikipedia.org/wiki/Anti-terrorism,_Crime_and_Security_Act_2001#Part_4\">part 4 powers</a>
                which enables the indefinite detention of foreign nationals who the Home Secretary believes,
                but can't or is unwilling to prove, are international terrorists.</li>
           <li>2003 - A section of the Criminal Justic Act 2003 was passed, which included extending
                the period to <b>14 days</b>.  This proceded without a vote.  
                The minister 
                <a href=\"http://www.theyworkforyou.com/debates/?id=2003-05-20.940.2#g942.3\">explained to Parliament</a>
                that it was a necessary result of time-consuming forensic procedures.</li>
           <li>2004 - The Law Lords 
                <a href=\"http://www.publications.parliament.uk/pa/ld200405/ldjudgmt/jd041216/a&oth-1.htm\">ruled</a> 
                that Part 4 of the Anti-Terrorism, Crime and Security Act
                violated the Human Rights Act (indefinite detention and discrimination), as well as 
                doubting that the extent of the measures put in place 
                were \"strictly required by the exigencies of the situation\" by the 
                \"public emergency\" so declared.</li>
           <li>2005, April - The state of public emergency was finally 
                <a href=\"http://www.opsi.gov.uk/si/si2005/20051071.htm\">lifted</a></li>
           <li>2005, 7 July - Suicide <a href=\"http://en.wikipedia.org/wiki/7_July_2005_London_bombings\">terrorist attacks</a>
                in London perpetrated by four criminals who could not have been subject to the 
                <a href=\"http://en.wikipedia.org/wiki/Anti-terrorism,_Crime_and_Security_Act_2001#Part_4\">indefinite 
                detention without charge</a> provisions because they were UK citizens.</li>
           <li>2005 - Tony Blair presses Parliament to revise the maximum period for detention of suspects
                without telling them of the crime they have committed to 90 days,
                citing the case that the evidence for the crime could be
                on encrypted computer hard drives.  He loses his first whipped vote since
                1997 (although 293 MPs <a href=\"http://www.publicwhip.org.uk/division.php?date=2005-11-09&number=84\">vote for it</a>)
                and the MPs compromise on <b>28 days</b>.</li>
           <li>2008, June - A sustained campaign by the Prime Minister results in MPs
                <a href=\"http://www.publicwhip.org.uk/division.php?date=2008-06-11&number=219&mpn=David_Davis&mpc=Haltemprice_%26amp%3B_Howden\">voting</a>
                to revise this period up to <b>42 days</b>.</li>
           </ul>
        </div>
          ";
}


function WritePubemChart($db, $vpubem)
{
    global $pwpdo;
    # don't know how to make these ignore repeated loads of the page on the same vrand key
    $query = "SELECT SUM(vpubem = 'no-disagree') AS no_disagree,
                     SUM(vpubem = 'no-agree') AS no_agree,
                     SUM(vpubem = 'yes-agree') AS yes_agree,
                     SUM(vpubem = 'yes-disagree') AS yes_disagree,
                     SUM(vpubem is not NULL) AS total
              FROM pw_dyn_fortytwoday_comments
             ";
	$row = $pwpdo->get_single_row($query,array());
    $tdno_disagree = ($vpubem == "no-disagree" ? " class=\"agpe\"" : ""); 
    $tdno_agree = ($vpubem == "no-agree" ? " class=\"agpe\"" : ""); 
    $tdyes_disagree = ($vpubem == "yes-disagree" ? " class=\"agpe\"" : ""); 
    $tdyes_agree = ($vpubem == "yes-agree" ? " class=\"agpe\"" : ""); 
    
    $ftotal = $row["total"] / 100.0;
    $no_disagree = $row["no_disagree"]; 
    $no_agree = $row["no_agree"]; 
    $yes_disagree = $row["yes_disagree"]; 
    $yes_agree = $row["yes_agree"]; 

    $hno_disagree = (int)($no_disagree / $ftotal); 
    $hno_agree = (int)($no_agree / $ftotal); 
    $hyes_disagree = (int)($yes_disagree / $ftotal); 
    $hyes_agree = (int)($yes_agree / $ftotal); 
    
    print "<table class=\"bars\">\n";
    #print "<tr><td>$no_disagree</td><td>$no_agree</td><td>$yes_disagree</td><td>$yes_agree</td></tr>\n"; 

    print "<tr class=\"bars\">"; 
    print "<td><div style=\"padding-top:".(2*$hno_disagree)."px; background-color:#b0b0d0;\">$hno_disagree%</div></td>\n"; 
    print "<td><div style=\"padding-top:".(2*$hno_agree)."px; background-color:#a0a0d0;\">$hno_agree%</div></td>\n"; 
    print "<td><div style=\"padding-top:".(2*$hyes_disagree)."px; background-color:#9090d0;\">$hyes_disagree%</div></td>\n"; 
    print "<td><div style=\"padding-top:".(2*$hyes_agree)."px; background-color:#8080d0;\">$hyes_agree%</div></td>\n"; 
    print "</tr>\n"; 
    print "<tr><th$tdno_disagree>Didn't know<br/>don't agree</th>
                      <th$tdno_agree>Didn't know<br/>but agreed</th>
                      <th$tdyes_disagree>Knew<br/>but disagreed</th>
                      <th$tdyes_agree>Knew<br/>and agreed</th></tr>\n";
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
body { width:800px; margin-left:auto; margin-right:auto; text-align:center; }
h1#th1 { background:#003300; padding:0; margin:0 }
h4#th4a { color: #399611; margin-top: 10px; font-size: 35px; margin-bottom: 5px; text-align: center }
h4#th4b { color: #304030; margin-top: 7px; width: 650px; font-size: 20px; margin-bottom: 5px; font-style: italic; }
h2 { color: #102010; margin-top: 4em; border-left: 10px #5050ff solid; padding-left: 10px; border-top: thin blue solid}
input { color: #303070 }
div#content { text-align: left; width: 800px; }
div#Zopform {  border: thin black solid; padding: 20px }
div.quessec { text-align: left; border: thin black solid; width: 600px; margin-left: auto; margin-right: auto; padding: 10px; margin-top:10px; background-color: #beffbe;}
div.oprad { margin-top:10px; padding:5px; font-size:120%; margin-left: 20px; }
div#checkmpbutton { font-size: 200%; text-align:center; margin:20px;}
div#footer { background-color:black; color:white;  border: thin black solid;  margin-top: 2em; }
table.votetab td { border: thin black solid; background-color: #e0e0e0; }
table.votetab { margin-left:auto; margin-right:auto }
div#yourfav p { text-align: left; padding-left: 10px; background-color:#beffbe; width:80%; margin-left:auto; margin-right:auto; padding:10px; }
div#foiparl { text-align: left; background-color:#fed9d8; width:80%; margin-left:auto; margin-right:auto; padding:5px; margin-bottom: 20px; border: thick red dotted; }
tr.agree td { background-color:#90ff90; }
tr.disagree td { background-color:#ff9090; }
.agpe { background-color:#b0ffb0; }
div.dethist { text-align: left; height:200px; margin-top:1em; overflow:auto; border: thin blue solid; background-color:#c9d9ff;}
div.dethist li { margin-top:20px }
table.bars { border: thin black solid; margin-left: auto; margin-right:auto; }
tr.bars td { padding-top: 20px; vertical-align:bottom; padding-left:50px; padding-right:50px; margin-left: auto; margin-right:auto; }
tr.bars div { width:50px; vertical-align:bottom; text-align:center; margin-left: auto; margin-right:auto;}:
";

print "</style>\n";

print "</head>\n";
print "<body class=\"fortytwodays\">\n";
#print "<script type=\"text/javascript\" src=\"quiz/election2008.js\"></script>\n";

print "<a href=\"/\"><h1 id=\"th1\"><a href=\"/\"><img src=\"/thepublicwhip.gif\" ></h1></a>\n";
print "<h4 id=\"th4a\">The Forty-two Days Question</h4>\n";
#print "<h1>The Public Whip - Forty-two days</h1>\n";
#print "<h4 id=\"th4\">The candidate calculator for <i>$constituency</i></h4>\n";
#print "<p></p>\n\n";

if (is_postcode($_GET["mppc"]) or $_GET["mpc"])
    $mpval = get_mpid_attr_decode($db, $db2, "");
$vterdet = db_scrub($_GET["vterdet"]);
$vpubemknow = db_scrub($_GET["vpubemknow"]);
$vpubemagg = db_scrub($_GET["vpubemagg"]);
$vpubem = "$vpubemknow-$vpubemagg"; 
$vrand = db_scrub($_GET["vrand"]);
if ($vrand)
    $vrand = (int)$vrand;
else
    $vrand = rand(10, 10000000);

$vdash = mysql_real_escape_string(db_scrub($_GET["dash"])); # used to tell if /by-election or /byelection was used
$vformfilled = ($vterdet and $vpubemknow and $vpubemagg);

$referrer = $_SERVER["HTTP_REFERER"];
$querystring = $_SERVER["QUERY_STRING"];
$ipnumber = $_SERVER["REMOTE_ADDR"];
if (!$referrer) {
    $referrer = $_SERVER["HTTP_USER_AGENT"];
}
$showhits = ($referrer and preg_match("/.*?house=z/", $referrer));

if ($mpval and $vformfilled)
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
        "part4_renewal" => array("2004-03-03", 71, "Renewal of law for detaining certified terrorists indefinitely"),
        "d90days" => array("2005-11-09", 84, "Extention of period of detention without charge to 90 days"),
        "d28days" => array("2005-11-09", 85, "Extention of period of detention to 28 days (but not 60)"),
        "d42days_enable" => array("2008-06-11", 219, "Conditions to enable detention without charge up to 42 days"),
        "d42days_procedure" => array("2008-06-11", 220, "Power to detain suspects without charge for up to 42 days"),
                    );

    # book the values into a database
    #$db->query("drop table if exists pw_dyn_fortytwoday_comments");
    #$db->query("create table pw_dyn_fortytwoday_comments (vterdet varchar(10), vpubem varchar(20), ltime timestamp, vrand int, vpostcode varchar(20), constituency varchar(80))");
    #$db->query("INSERT INTO pw_dyn_fortytwoday_comments (vterdet, vpubem, ltime, vrand, vpostcode, constituency)
    #            VALUES ('$vterdet', '$vpubem', NOW(), $vrand, '$vpostcode', '".mysql_real_escape_string($constituency)."')");

    # looks up as a batch.  Or we could look up individually for easier coding
    $votes = GetVotes($db, $mpprop["person"], 1039);
    foreach ($vnvotes as $vname => &$vnvote)
        $vnvote[] = GetVote($votes, $vnvote[0], $vnvote[1]);

    print "<div id=\"content\">\n"; 
    $atcsa = "<a href=\"http://www.opsi.gov.uk/acts/acts2001/ukpga_20010024_en_1\">Anti-terrorism, Crime and Security Act 2001</a>";
    $party = $mpprop["party"]; 
    print "<p><b><a href=\"http://www.publicwhip.org.uk/mp.php?".$mpprop["mpanchor"]."\">$name MP ($party)</a></b>,
           representing the constituency of <b>$constituency</b>,\n";
    if ($minentered_house == "1997-05-01")
    {
        print " has been in Parliament long enough to vote on the detention of 
                terrorist suspects without charge for up to 90 days, as well as 
                on earlier laws of indefinite detention without charge of foreign suspects under the $atcsa.\n";
    }
    else
    {
        print " entered Parliament on ".pretty_date($minentered_house).",\n";
        print " and was able to vote on the detention of terrorist suspects without charge ";
        print " for up to 42 days";
        if ($d90days <> "notmp")
            print " and to 90 days.";
        else
            print " but not to 90 days.";
        if ($minentered_house <= "2001-11-21")
            print " $name was also in Parliament for the votes on the $atcsa which enabled the indefinite detention 
                    of foreign nationals whom the Home Secretary believed were terrorists.\n";
        else if ($minentered_house <= "2004-03-03")
            print " $name was not in Parliament for the votes on the $atcsa which enabled indefinite detention
                    without charge of foreign nationals whom the Home Secretary believed were terrorists, 
                    but was there when MPs voted to renew these powers.\n";
        else
            print " $name was not in Parliament at the time when MPs voted for detention without charge of
                    foreign nationals whom the Home Secretary believed were terrorists, under the $atcsa.\n";
    }
    print "</p>\n";


    print "<div id=\"yourfav\">\n";
    WriteYourSummary($vterdet);
    print "</div>\n";

    print "<p>The votes by $name MP are listed in the table below.  
           Those you disagree with are coloured red, the ones you agree with are green, 
           and the rest are harder to work out.</p>
           <p>Not all votes are as they seem.  Click on the links to find out more.</p>\n";

    print "<div class=\"votetab\">\n"; 
    print "<table class=\"votetab\">\n";
    WriteMPvotetable($vnvotes, $vterdet, $vpubem, $mpprop["mpanchor"]);
    print "</table>\n";
    print "<p>The standard Public Whip comparison table for rating $name's votes on this issue is, 
           <a href=\"/mp.php?".$mpprop["mpanchor"]."&dmp=1039\">here</a>.</p>\n";
    print "</div>\n"; 

    print "<div id=\"lawsummary\">\n";
    WriteTimeline();
    print "</div>\n";

    print "<div id=\"pubemchart\">\n";
    print "<h2>Responses to the public emergency question</h2>";
    print "<p>Here are the results of the poll on what percentage of 
            people using this website either <em>knew of</em> 
            or <em>agreed with</em> the Government's 
            declaration that there was a 
            <b>'public emergency threatening the life of the nation'</b>,
            (as debated by MPs <a href=\"http://www.theyworkforyou.com/debates/?id=2001-11-19.124.0\">here</a>).</p>\n"; 
    WritePubemChart($db, $vpubem);
    print "</div>\n";


    print "<h2>What you can do now</h2>\n";
    print "<p>Unless you tell people about what you think, no one -- including the politicians -- 
            will be able to take account of it.</p>\n"; 
    print "<p><i>Please consider</i>:</p>\n"; 
    print "<ul><li><a href=\"http://www.writetothem.com/\">Writing to your MP</a> to tell them 
            what you think "; 
    if (($vpubemagg == "aye") && ($vnvotes["public_emergency"] == "aye"))
        print "about their vote approving of the declaration of a public emergency which you thought 
                was unjustified, and ask them to explain it."; 
    else
        print "about their votes, for and against your views, and ask them to explain 
                any which you don't understand."; 
    print "</li>\n"; 
    print "<li><a href=\"mailto:?subject=My MP and 42 days detention
    &body=See what how your MP voted:  http://www.publicwhip.org.uk/fortytwodays.php\">Emailing a friend</a> 
           about this web-page.</li>
           <li><a href=\"http://www.pledgebank.com/byelectionwhip\">Joining a pledge</a> to distribute leaflets 
           about the candidates and party voting records at a by-election in the future.</li>
           <li>Joining a political party that holds meetings in your area 
           (<a href=\"http://www.labour.org.uk/labour_supporters_network\">Labour</a>, 
           <a href=\"https://www.conservatives.com/tile.do?def=involved.join.page\">Conservatives</a>, 
           <a href=\"http://www.libdems.org.uk/support/index.html\">LibDems</a>, 
           <a href=\"http://www.greenparty.org.uk/getinvolved\">Green</a>)</li>
           <li><a href=\"http://www.publicwhip.org.uk/newsletters/signup.php\">Signing up</a> for the 
           Public Whip newsletter to hear about any other special polls such as this.</li>

            </ul>\n"; 

    
    $foiparl = GetDreamDistance($db, $mpprop["person"], 996);
    if ($foiparl > 0.6)
    {
        print "<div id=\"foiparl\">
               Did you know that $name MP also voted to hide the affairs of all MPs 
               (eg their expense claims) 
               from the 
               Freedom of Information Act?  
               <br>Click <a href=\"/mp.php?".$mpprop["mpanchor"]."&dmp=996\">here</a> to find out the details.
               </div>\n"; 
    }
    print "</div>\n"; # .content

}


else
{

    $allents = ($mpval ? " <span style=\"color:red; background-color:#ffb0b0; \"><b>all of</b></span>" : ""); 
    print "<h4 id=\"th4b\">Fill in$allents this form to see if your MP
           agrees with you, according to their votes in Parliament.</h4>";

    print "<div id=\"opform\">\n";
    print "<form action=\"/fortytwodays.php\" method=\"get\">\n";

    print "<div class=\"quessec\">Type in <em>either</em>:
           <ul>
           <li>Your postcode: <input type=\"text\" name=\"mppc\" id=\"mppc\" size=\"8\" onKeyDown=\"if(event.keyCode==13)event.keyCode=0\"> </input>, <em>or</em> </li>
           <li>Your parliamentary constituency: <input type=\"text\" name=\"mpc\" id=\"mpc\"> </input> </li>
           </ul>
           </div>\n";

    print "<div class=\"quessec\">\n";
    print "<div>How long should the police be allowed to detain someone as a suspected terrorist
                   without telling them what crime they have committed?</div>\n";
    print "<div class=\"oprad\">\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"ind\">indefinitely (applies only to foreigners)</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"90\">up to 90 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"42\">up to 42 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"28\">up to 28 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"14\">up to 14 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"7\">up to 7 days</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"7i\">up to 7 days (relating to Northern Ireland)</input></div>\n";
    print "<div><input type=\"radio\" name=\"vterdet\" value=\"2\">up to 2 days (in line with other violent crime)</input></div>\n";
    print "</div>\n";
    print "</div>\n";

    print "<div class=\"quessec\">\n";
    print "<div>Did you know that the government declared a
           <em><b>'public emergency threatening the life of the nation'</b></em> 
           within the meaning of Article 15 of the 
           <a href=\"http://www.hri.org/docs/ECHR50.html\">European Convention of Human Rights</a>
           between 
           <a href=\"http://www.opsi.gov.uk/si/si2001/20013644.htm\">13 November 2001</a> and 
           <a href=\"http://www.opsi.gov.uk/si/si2005/20051071.htm\">8 April 2005</a>?</div>\n";
    print "<div class=\"oprad\">\n";
    print "<div><input type=\"radio\" name=\"vpubemknow\" value=\"yes\">Yes</input></div>\n";
    print "<div><input type=\"radio\" name=\"vpubemknow\" value=\"no\">No</input></div>\n";
    print "</div>\n";
    
    print "<div style=\"margin-top:2em\">Do you believe that it was reasonable for the government to declare a 
           <em><b>'public emergency threatening the life of the nation'</b></em> 
           between 2001 and 2005?  
           <br>(<em>You can read the debate in Parliament about it 
           <a href=\"http://www.theyworkforyou.com/debates/?id=2001-11-19.124.0\">here</a>.</em>)\n";
    print "<div class=\"oprad\">\n";
    print "<div><input type=\"radio\" name=\"vpubemagg\" value=\"agree\">Yes it was reasonable</input></div>\n";
    print "<div><input type=\"radio\" name=\"vpubemagg\" value=\"disagree\">No it was not reasonable</input></div>\n";
    print "</div>\n";
    print "<div style=\"margin-top:2em; background-color:yellow\">Now click on the <b>big button</b> below.</div>\n"; 
    print "</div>\n";
    
    print "</div>\n";

    print "<div style=\"display:none\">Random number: <input type=\"text\" name=\"vrand\" id=\"vrand\" value=\"$vrand\" readonly></div>\n";

    print "<div class=\"quessec\">\n";
    print "<div id=\"checkmpbutton\"><input type=\"submit\" value=\"Check my MP\"></div>\n";
    print "</div>\n"; 
    
    print "</form>\n";


    print "</div>\n";
}


#print "<span id=\"tagth\"><a href=\"/\">Memory Hole</a><br/><select><option title=\"one\">OOOO</option></select></span>\n";
#print '<script type="text/javascript">Hithere();</script>';
print "<div id=\"footer\">Produced by <a href=\"/\" style=\"color:#a0a0ff\">the Public Whip</a> 
       For contact details, see <a href=\"http://www.publicwhip.org.uk/faq.php#interviews\" style=\"color:#a0a0ff\">FAQ</a></div>\n";

print "</body>\n";
print "</html>\n";


