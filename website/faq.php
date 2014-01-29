<?php require_once "common.inc";
require_once "db.inc";

# $Id: faq.php,v 1.95 2010/12/11 15:05:01 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
$paddingforanchors = true; $title = "Help - Frequently Asked Questions"; pw_header();

$db = new DB(); 

?>

<p>
<ul>
<li><a href="#whatis">What is the Public Whip?</a> </li>
<li><a href="#how">How does the Public Whip work?</a> </li>
<li><a href="#timeperiod">What time period does it cover?</a> </li>


<br>
<li><a href="#division">What is a division? </a> </li>
<li><a href="#division-occur">When does a division occur?</a> </li>
<li><a href="#decisions">Why don’t all decisions made in Parliament appear on Public Whip?</a> </li>
<li><a href="#summaries">Why don’t all the divisions have edited summaries? </a> </li>

<br>
<li><a href="#policies">What are Policies and how do they work?</a> </li>
<li><a href="#rebelandfree">What are “Rebel Voters” and what is a “Free Vote”? </a> </li>
<li><a href="#clarify">What do the "attendance" and "rebellion" figures mean?</a> </li>

<br>
<li><a href="#legal">Legal question: what can I use this information for?</a> </li>
<li><a href="#playwith">Can I play with the software?</a> </li>
<li><a href="#datalicence">What licence is the data under?</a> </li>
<li><a href="#organisation">What organisation is behind the Public Whip?</a> </li>

<br>
<li><a href="#help">Can I help with the project?</a> </li>
<li><a href="#contact">How can I contact you?</a> </li>
</ul>
</p>



<h2 class="faq"><a name="whatis">What is the Public Whip?</a></h2>
<p>
    Public Whip is a project to track the voting patterns of Australian federal politicians. We're an independent, non-governmental project of the charity <a href="https://www.openaustraliafoundation.org.au/">OpenAustralia Foundation</a>. 
</p>


<h2 class="faq"><a name="#how">How does the Public Whip work?</a></h2>
<p>
Debate transcripts of the House of Representatives and the Senate are published online as <a href="http://www.aph.gov.au/Parliamentary_Business/Hansard">Hansard</a>. Public Whip takes these records and compiles lists of votes that you can access under <a href="http://publicwhip-test.openaustraliafoundation.org.au/divisions.php">Divisions</a>. You can search through these votes using our <a href="http://publicwhip-test.openaustraliafoundation.org.au/index.php">search function</a> on the home page or you can browse the votes that are relevant to the particular policy areas listed under <a href="http://publicwhip-test.openaustraliafoundation.org.au/policies.php">Policies</a> (for more on our policies, see <a href="#policies">What are Policies and how do they work?</a>).
</p>

<h2 class="faq"><a name="#timeperiod">What time period does it cover?</a></h2>

<p>
The Public Whip’s voting and membership data extends back to 2006. New divisions are added as soon as possible after becoming available. We give no warranty for the data so <a href="# contact">let us know</a> if you find any factual inaccuracies.
</p>

<?php
    require_once "db.inc";
    require_once "parliaments.inc";
    global $pwpdo;

    $div_count=$pwpdo->get_single_row('SELECT COUNT(*) as div_count FROM pw_division',array());
    $mp_count=$pwpdo->get_single_row('select count(distinct pw_mp.person) AS mp_count from pw_mp',array());
    $vote_count=$pwpdo->get_single_row('select count(*) AS vote_count from pw_vote',array());
    $vote_per_div = round($vote_count['vote_count'] / $div_count['div_count'], 1);
    $parties=$pwpdo->fetch_all_rows('select count(*) from pw_mp group by party',array());
    $parties=count($parties);
    $rebellious_votes=$pwpdo->get_single_row('select sum(rebellions) AS rebellions from pw_cache_mpinfo',array());
    $rebelocity = round(100 * $rebellious_votes['rebellions'] / $vote_count['vote_count'], 2);
    $attendance = round(100 * $vote_count['vote_count'] / $div_count['div_count'] / ($mp_count['mp_count'] / parliament_count()), 2);

?>

<p><b>Numerics:</b> The database contains <strong><?php echo number_format($mp_count['mp_count'])?></strong>
distinct Representatives and Senators from <strong><?php echo $parties?></strong> parties who have voted across
<strong><?php echo number_format($div_count['div_count'])?></strong> divisions.
In total <strong><?php echo number_format($vote_count['vote_count'])?></strong> votes were cast
giving an average of <strong><?php echo $vote_per_div?></strong> per division.
Of these <strong><?php echo number_format($rebellious_votes['rebellions'])?></strong> were against the majority vote for
their party giving an average rebellion rate of <strong><?php echo $rebelocity?>%</strong>.


<h2 class="faq"><a name="#division">What is a division?</a></h2>

<p>
A division is a formal vote on a motion in the House of Representatives or the Senate. A motion is a formal proposal put to the House or Senate to take action of some kind.
</p>
<p>
When a division is called on a particular motion, Members of Parliament (MPs) in the House of Representatives or Senators in the Senate divide themselves into two groups: one that votes Aye (yes) and one that votes No. Each political party has whips who try to persuade their members to vote along party lines. 
</p>


<h2 class="faq"><a name="#division-occur">When does a division occur?</a></h2>

<p>
Most decisions in Parliament are made <a href="http://www.peo.gov.au/students/fact_sheets/voting_chambers.html">‘on the voices’</a> and not by division. When a question is asked by the Chair, the Members of Parliament (MPs) or Senators call out Aye (yes) or No and the Chair decides which are in the majority without recording the names of who voted and how they voted.
</p>
<p>
A division is only called if two or more MPs or Senators call for one. If only one MP or Senator calls for a division then their name may be recorded in the official record (the Hansard) but no division will occur.
</p>
<p>
In the House of Representatives, if there are four or less MPs on a side of the division then the division does not proceed and the Speaker declares the decision of the House immediately. However, the names of the MPs in the minority are recorded.
</p>
<p>
In the Senate, if there is only one Senator on a side of the division then the division does not proceed and the President declares the decision of the Senate immediately. However, the names of the lone Senator may be recorded.
</p>


<h2 class="faq"><a name="#decisions">Why don’t all decisions made in Parliament appear on Public Whip?</a></h2>

<p>
Public Whip is concerned with the voting patterns of politicians, which means it is limited to formal votes (known as divisions, see <a href="#division">What is a division?</a>). This is because politicians’ names and how they voted are only recorded in the official record of Parliament (known as the Hansard) when a division occurs.
</p>
<p>
Unfortunately, most decisions in Parliament are not made by division (see <a href="#division-occur">When does a division occur?</a>) and so do not appear on this site.
</p>


<h2 class="faq"><a name="#summaries">Why don’t all the divisions have edited summaries?</a></h2>

<p>
When you click on a link for a <a href="http://publicwhip-test.openaustraliafoundation.org.au/divisions.php">division</a>, you will be taken to a summary that will either contain an edited description of the division or text taken automatically from the official record of Parliament (known as Hansard). In some cases, the summary will contain no text.
</p>
<p>
Currently, the divisions with edited summaries are those that are relevant to one of the <a href="http://publicwhip-test.openaustraliafoundation.org.au/policies.php">Policies</a>. See our <a href="publicwhip-test.openaustraliafoundation.org.au/project/research.php">Research</a> page to find out more about how the summaries are edited.
</p>


<h2 class="faq"><a name="#policies">What are Policies and how do they work?</a></h2>

<p>
On Public Whip, the <a href="http://publicwhip-test.openaustraliafoundation.org.au/policies.php">Policies</a> are sets of votes on an issue.
</p>
<p>
We choose and develop particular Policies for a number of reasons. For example, we prioritise issues where politicians have rebelled (e.g. the <a href="http://publicwhip-test.openaustraliafoundation.org.au/policy.php?id=10">local government recognition divisions</a>) or where parties have allowed their members to take a free vote (e.g. the <a href="http://publicwhip-test.openaustraliafoundation.org.au/policy.php?id=1">same sex marriage divisions</a>) because these divisions give a strong indication of an individual politician’s voting patterns (see <a href="#rebelandfree">What are “Rebel Voters” and what is a “Free Vote”?</a>). Other reasons for selecting a particular Policy include whether the matter was an election issue (e.g. the <a href="http://publicwhip-test.openaustraliafoundation.org.au/policy.php?id=3">carbon price</a>) and whether there was a high level of attendance (see <a href="#clarify">What do the “attendance” and “rebellion” figures mean?</a>).
</p>
<p>
Unfortunately, Policies are restricted to issues that are voted on by division because those are the only decisions that appear on Public Whip (see <a href="#decisions">Why don’t all decisions made in Parliament appear on Public Whip?</a>)
</p>


<h2 class="faq"><a name="#rebelandfree">What are “Rebel Voters” and what is a “Free Vote”?</a></h2>

<p>
An MP or Senator rebels by voting against the <a href="http://www.peo.gov.au/students/fact_sheets/party_whip.html">party whip</a>. This is known as <a href="http://www.peo.gov.au/students/fact_sheets/crossing_floor.html">crossing the floor</a> and rarely occurs these days. 
</p>
<p>
In contrast, a free vote (also known as a conscience vote) occurs when MPs or Senators are not obliged to vote with their party.
</p>


<h2 class="faq"><a name="#clarify">What do the "attendance" and "rebellion" figures mean?</a></h2>

<p>
"Attendance" figures record the politicians who vote or tell in any given division. A <a href="http://www.peo.gov.au/students/gloss_tuvwxyz.html">teller</a> is appointed by a chair to count (or ‘tell’) the Members of Parliament or Senators voting in a division.
</p>
<p>
There are several reasons why a politician may have low attendance figures. For example, they may have abstained, have ministerial or other duties or they may be the speaker. Currently, the Public Whip does not record if a member spoke in the debate but did not vote.
</p>
<p>
"Rebellion" figures record the number of rebel votes (see <a href="#rebelandfree">What are “Rebel Voters” and what is a “Free Vote”?</a>).
</p>


<h2 class="faq"><a name="#legal">Legal question: what can I use this information for?</a></h2>

<p>
You can use the information freely so long as you credit the Public Whip and share it (see <a href="#datalicence">What licence is the data under?</a>). However, you should double check the information to make sure it is correct. If you find an error, please <a href="#contact">contact us</a> and let us know.
</p>

<h2 class="faq"><a name="#playwith">Can I play with the software?</a></h2>

<p>
Yes. All the software we've written is free and protected by the <a href="http://www.fsf.org/licensing/licenses/agpl-3.0.html">GNU Affero General Public License</a> (which means you can use it and change it, but you have to release any changes you make). It's available for <a href="https://github.com/openaustralia/publicwhip">download on Github</a>.
</p>

<h2 class="faq"><a name="#datalicence">What licence is the data under?</a></h2>

<p>
To the extent which we have rights to this database of politicians’ voting records and related information, it is licensed under the <a href="http://opendatacommons.org/licenses/odbl/">Open Data Commons Open Database License</a>. This is an attribution, share-alike licence. That means that you must credit the Public Whip, for example via a link, if you use the data. It also means that if you build on this data, you must also share the result under a compatible open data licence. 
</p>

<h2 class="faq"><a name="#organisation">What organisation is behind the Public Whip?</a></h2>

<p>
Public Whip in Australia was started and is run by the <a href="https://www.openaustraliafoundation.org.au/">OpenAustralia Foundation</a>, a charity. It is based on the <a href="http://www.publicwhip.org.uk/">UK Public Whip site</a> which was created by <a href="http://www.flourish.org/">Francis Irving</a> and <a href="http://www.goatchurch.org.uk/">Julian Todd</a> in 2003.
</p>

<h2 class="faq"><a name="#help">Can I help with the project?</a></h2>
<p>
Yes! We're looking for people who are interested in making the voting records more accessible as well as people with particular skill-sets that they feel they could contribute. If this sounds like you, please email us at <a href="mailto:contact@openaustralia.org">contact@openaustralia.org</a>.
</p>

<h2 class="faq"><a name="#contact">How can I contact you?</a></h2>
<p>
You can contact us via email at <a href="mailto:contact@openaustralia.org">contact@openaustralia.org</a> or our <a href="http://twitter.com/openaustralia">Twitter account</a>.
</p>
<p>
Please contact us if you find an error, have a suggestion or have any questions.
</p>



<?php pw_footer() ?>


