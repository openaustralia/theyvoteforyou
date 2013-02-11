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

<a href="http://www.newstatesman.com/newmedia">
<img align="right" src="images/nmawinnerbutton.gif" border="0"></a>

<p>
<ul>
<li><a href="#whatis">What is the Public Whip?</a> </li>
<li><a href="#jargon">First, can you explain "division" and other political jargon?</a> </li>
<li><a href="#how">How does the Public Whip work?</a> </li>
<li><a href="#timeperiod">What time period does it cover?</a> </li>

<br>
<li><a href="#clarify">What do the "rebellion" and "attendance" figures mean exactly?</a> </li>
<li><a href="#ayemajority">Why do you refer to Majority and Minority instead of Aye and No?</a> </li>
<li><a href="#sitinprivate">What is a motion to sit in private?</a></li>
<li><a href="#freevotes">Why do you incorrectly say people are rebels in free votes?</a> </li>
<li><a href="#divno">Why is the division numbering different between the Commons and the Lords?</a> </li>
<li><a href="#policies">What are Policies and how do they work?</a> </li>

<br>
<li><a href="#legal">Legal question, what can I use this information for?</a> </li>
<li><a href="#playwith">Can I play with the software?</a> </li>
<li><a href="#whyfree">Why are you giving everything away for free?</a> </li>

<br>
<li><a href="#organisation">What organisation is behind the Public Whip?</a> </li>
<li><a href="#theyworkforyou">What's your connection with TheyWorkForYou.com?</a> </li>
<li><a href="#interviews">Are you happy to give interviews about Public Whip?</a> </li>
<li><a href="#money">Do you make any money out of Public Whip?</a> </li>
<li><a href="#living">How do you earn enough to make a living?</a> </li>
<li><a href="#millions">I've just got a job at a company that's been contracted
... to process Parliamentary data ...</a>
</li>
<li><a href="#officials">Have you had any problems from MPs or other politicians with what you are doing?</a> </li>

<br>
<li><a href="#rss">Are there any RSS syndication feeds?</a> </li>
<li><a href="#spreadsheet">Where is the data in spreadsheet file format or in XML?</a> </li>
<li><a href="#datamodel">How does this XML nonsense all work?</a> </li>
<li><a href="#patents">What is the fuss about software patents?</a> </li>
<li><a href="#election">What did you do for the 2005 election?</a> </li>

<br>
<li><a href="#help">Can I help with the project?</a> </li>
<li><a href="#motionedit">What do you mean by editing the motion description?</a> </li>
<li><a href="#simproj">What other projects are similar to Public Whip?</a></li>
<li><a href="#keepup">How can I keep up with what you are doing?</a> </li>
<li><a href="#contact">There's something wrong with your webpage / I've found an error / Your wording is dreadfully unclear / Can I make a suggestion?</a> </li>
</ul>
</p>



<h2 class="faq"><a name="whatis">What is the Public Whip?</a></h2>
<p>Public Whip is a project to watch Members of the United Kingdom
Parliament, so that the public (people like us) can better understand and
influence their voting patterns.  We're an independent, non-governmental
project.


<h2 class="faq"><a name="jargon">First, can you explain "division" and other political jargon?</a></h2>
<p>The House of Commons <b>divides</b> several times each week into <b>MPs</b> (Members of Parliament) 
who vote <b>Aye</b> (yes, for the motion) and those who vote <b>No</b> (against the
motion).</p>

<p>Each political party has <b>whips</b> who try to persuade their
members to vote for the party line.  In return for loyalty, the party promotes 
them into desirable jobs and supports their re-election campaigns at the General Election.
The <b>whip</b> sometimes refers to the letter sent to each MP by their party 
at the start of the week informing them of the divisions they are expected to attend.
The word <b>whip</b> can also refer to the membership of the party -- 
so that removing the whip from a member is considered the ultimate sanction.</p>

<p>An MP <b>rebels</b> by voting against the party whip.</b></p>

<p>A <b>teller</b> is an MP involved in the counting of the vote.  There are 
two tellers for the Ayes and two for the Noes, unless it is a <b>deferred division</b> 
in which case voting takes place by signing a sheet of paper rather than walking through 
the division lobbies.  Although the tellers technically don't vote, 
it is conventional to assume that they do; an exception being when the vote would 
have been unanimous, but for the two MPs who are required to report on the lack of votes 
for the other side.</p>

<p>For more information on all these terms, see the
<a href="http://www.parliament.uk/parliamentary_publications_and_archives/factsheets/p09.cfm">
Parliament factsheet on divisions</a>.
<p>The <i>House of Lords</i> is the second chamber of the Parliament. 
Proposed legislation passes through both Houses before it becomes law.
<i>Lords</i> become members by a complex mixture of 
<a href="http://website.lineone.net/~david.beamish/index.htm">appointment</a>, religion,
appelation, hereditary entitlement and self election.
They still divide, as in the House of Commons, but instead of Aye and No
they are <b>Content</b> and <b>Not-Content</b>.

<h2 class="faq"><a name="how">How does the Public Whip work?</a></h2>
<p>All the 
<a href="http://www.parliament.the-stationery-office.co.uk/pa/cm/cmhansrd.htm">House of Commons</a>  and
<a href="http://www.parliament.the-stationery-office.co.uk/pa/ld/ldhansrd.htm">House of Lords</a>
debate transcripts (collectively, Hansard)
back to 1988 are published electronically on the World Wide Web.  We've written
a program to read them for you and separate out all the records of voting.  This
information has been web-scraped into an online database which you can
access.


<h2 class="faq"><a name="timeperiod">What time period does it cover?</a></h2>
<p>Voting and membership data for MPs extends back to
the May 1997 General Election, although there are a few divisions missing in
the 1997 parliament.  Lords membership data extends back to the big reform in
1999, because nobody can remember who the members were before then.  Lords
divisions currently go back to July 2001. New divisions usually appear in
Public Whip the next morning, but sometimes take a day or two longer.  We give
no warranty for the data; there may be factual inaccuracies.  <a
href="mailto:team@publicwhip.org.uk">Let us know</a> if you find any.

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
distinct MPs and Lords from <strong><?php echo $parties?></strong> parties who have voted across
<strong><?php echo number_format($div_count['div_count'])?></strong> divisions.
In total <strong><?php echo number_format($vote_count['vote_count'])?></strong> votes were cast
giving an average of <strong><?php echo $vote_per_div?></strong> per division.
Of these <strong><?php echo number_format($rebellious_votes['rebellions'])?></strong> were against the majority vote for
their party giving an average rebellion rate of <strong><?php echo $rebelocity?>%</strong>.


<h2 class="faq"><a name="clarify">What do the "rebellion" and "attendance" figures mean exactly?</a></h2>

<p>The apparent meaning of the data can be misleading, so do not to
jump to conclusions about MPs or Lords until you have understood it.

<p>"Attendance" is for voting or telling in divisions. An MP may have a
low attendance because they have abstained, have ministerial or
other duties or they are the speaker.  Perhaps they consider each division
carefully, and only vote when they know about the subject. Lords are 
appointed for life, so they may have decided to retire.
Sinn F&eacute;in MPs, because they haven't taken the
oath of allegiance, are unable to vote.
A full list of reasons for low attendance can be found in the Divisions section
on page 11 of <a
href="http://www.parliament.uk/commons/lib/research/rp2003/rp03-032.pdf">a
House of Commons library research paper</a>.  Note also that the Public
Whip does not currently record if a member spoke in the debate but did
not vote.

<p><strong>Extra note, October 2008:</strong> We have found that people
take the attendance in divisions too seriously, when it is really pretty
meaningless. At Public Whip, we'd rather an MP actually scrutinised law
and made it better, and voted well on it, rather than voted more often.
Therefore we have removed attendance from the main MP table.

<p>"Rebellion" on this website means a vote against the majority vote by
members of the MP's party.  Unfortunately this will indicate that many members
have rebelled in a free vote.  Until precise data on when and how strongly each
party has whipped is made available, there is no true way of identifying a
"rebellion".  We know of no heuristics which can reliably detect free votes.
See also the <a href="#freevotes">next question</a>.


<h2 class="faq"><a name="sitinprivate">What is a motion to sit in private?</a></h2>

<p>There are a number of arcane procedures 
listed in the 
<a href="http://www.publications.parliament.uk/pa/cm/cmstords.htm">Standing Orders</a> 
which have been carried over for hundreds of years.  
All recent versions and their renumberings are listed there.</p>  

<p>The <a href="http://www.publications.parliament.uk/pa/cm200607/cmstords/405/40527.htm#a184">2007 Standing Order 163 (Motions to sit in Private)</a>
says:</p>

<blockquote>If any MP moves 
<i>'That the House sit in private'</i> the Speaker shall put the
question to a division.  Such a Motion may be made no more than once 
per day.</blockquote>
  		
<p>The <a href="http://www.publications.parliament.uk/pa/cm200607/cmstords/405/40509.htm#a44">2007 Standing Order 41 (Quorum)</a>
says:</p>

<blockquote>If it should appear that fewer than forty Members
have taken part in a division, the business under consideration shall 
be suspended.</blockquote>

<p>(As an aside, the Quorum rule has a second part which says: <i>"The House shall 
not be counted at any time."</i> which prevents anyone from putting on 
record how badly the debate is attended in relation to the number 
of MPs who lend their weight to the vote when the division bell sounds. 
It is also made explicit by <a href="http://www.publications.parliament.uk/pa/cm200607/cmstords/405/40508.htm#a42">2007 Standing Order 39</a> that 
<i>"A Member may vote in a division although he did not hear the question put"</i>.)</p>

<p>These two rules combine into the gambit used by 
<a href="http://www.theyworkforyou.com/debates/?id=2003-03-14.594.0#g596.4">Andrew Dismore MP in March 2003</a>
to end discussion of the <a href="http://www.publications.parliament.uk/pa/cm200203/cmbills/029/03029.i.html">Government Powers (Limitation) Bill</a> 
when only 23 MPs presented themselves to vote -- 
there may have been many more in the building who were ordered to stay away 
to ensure lack of quorum.</p>

<p>The counter-measure to this gambit, often exercised by the late Eric Forth MP, 
was to <a href="http://www.publicwhip.org.uk/division.php?date=2005-10-28&number=72">call 
for the motion to sit in private at the start of the sitting</a>, which then rules 
it out for the rest of the day.</p>

<p>The Speaker has ruled that Motion to sit in private can be moved at 
any time no matter how nonsensical it is, <a href="http://www.theyworkforyou.com/debates/?id=2007-05-18a.875.1#g875.2">as 
she did just before Andrew Dismore MP called for it in May 2007</a> to head off an 
attempted filibuster on the matter of whether Parliament and MPs' 
correspondence should be 
<a href="http://www.publicwhip.org.uk/policy.php?id=996">
off limits 
to the Freedom of Information Act.</a>

<p>If you don't like the way Parliamentary procedures get written and used
in order to obscure the divide between what you believe is an overwhelming 
public position and their personal power play, then learn more about it, 
<a href="http://www.pledgebank.com">organize</a>, and 
<a href="http://www.writetothem.com">write to them</a>.</p>

<h2 class="faq"><a name="freevotes">Why do you incorrectly say people are rebels in free votes?</a></h2>

<p>The short answer to this question is <a href="http://www.theyworkforyou.com/debate/?id=2005-02-07.1200.2">succinctly given by the Speaker</a>.  Here is
the long answer.

<p>There is no official, public data about the party whip.  At the moment
we guess based on the majority vote by MPs or Lords for each party.  In order to
correctly identify rebels, we need to know each party's whip in each division.
There are two ways this could be officially recorded.

<ol>
<li>Hansard clerks could record the whip.  They could either be officially told
the whip by each party's whips' office, or they could deduce it from the
presence of offical whips.  The whip would then be written in Hansard next to
the division listing.
<li>Each whips' office could publish their official whip on their website after
each vote.  If you are a member of a political party, and want to fix the Public
Whip site, lobby them to do this, then let us know.
</ol>

<p>Parties can't have it both ways&mdash;complain that we don't take account of what the whip is,
and at the same time not tell us what it is.  There is no contradiction in admitting the whip
exists and recording it officially&mdash;after all some whips
<a href="http://www.civilservice.gov.uk/management_information/parliamentary/parliamentary_pay/pay/payments_on_leaving_office/index.asp#tables">
are paid a salary by the taxpayer</a> so
there is a precedent for admitting they exist.

<h2 class="faq"><a name="ayemajority">Why do you refer to Majority and Minority instead of Aye and No?</a> </h2>
<p>Whether a vote is an Aye or a No is less informative than it seems, because it depends 
exactly on the words of the question put (for example: "Motion that the amendment be made" 
versus "Motion that the original words shall stand"), as well as the meaning of the amendment 
which itself carries the possibility of a further negation by its use of words 
("insert the clause" versus "delete the clause").</p>

<p>In truth it would be less confusing if the votes were between "Option (a)" and "Option (b)"
with their meanings clearly expressed.  Indeed, this form of words in the motion text 
has been tried out, as in "Those voting No wanted this, and the Ayes wanted that", 
but then you have to know which side won in order to determine what happened.</p>

<p>But we don't need to express it like that, because all the votes are in the past and 
we always know which side won, and it's the winning side that determines what happens, 
as opposed to what could have happened.  (What could have happened does matter, because if 
it was an alternative version of the law that turned out to be better in the long run 
than what was chosen, then it ought to reflect on the quality of the judgment of the MPs
who were in the minority.)</p>

<p>Accordingly, in many of the explanations and lists we say Majority and Minority because it 
gives a clearer picture of what happened (as well as which side was which in the case of 
the absolute majority for the Government that is in the House of Commons), even 
though the words are less easy to understand than the often misleading "Aye" and "No".</p>

<h2 class="faq"><a name="divno">Why is the division number different between the Commons and the Lords?</a></h2>

<p>Good question.  In the Commons, Division No. 1 is the first vote of the Parliamentary 
session or year, but in the Lords it is the first vote of the day.  
It would appear that, although both Houses are in the same building and operate 
the same procedure, they are run on completely different sets of paperwork 
that may have been the same at one point in the past, but has 
since evolved apart.  

<p>We would be grateful to someone with access to some very old volumes of 
Hansard if they could check out when these different numbering systems became 
established and let us know.  

<p>With great difficulty, we have generalized the software that supports 
Public Whip to run both houses after it was initially designed only to run 
the Commons.  We therefore have learnt more about the syntactic incompatibilities 
between the two houses than we care to know.  The process is fraught with 
possible errors.  Please email us if 
you see any mistakes where we have said that the MPs were 'Content'. 


<h2 class="faq"><a name="policies">What are Policies and how do they work?</a></h2>

<p>On Public Whip, a Policy is a set of votes that represent a view on a
particular issue.  They can be used to automatically measure the voting
characteristics of a particular MP or Lord (or someone who has been both)
without the need to examine and compare the votes individually.</p>

<p>You do not have to agree with a Policy to have a valid opinion
about the clarity of its description or choice of votes.
This is why we've based their maintenance on a <a href="http://en.wikipedia.org/wiki/Wiki">Wiki</a>
where everyone who is logged in can edit them.  This means that when a Policy
gets out of date, for example new votes have appeared that it should be voting
on, it's up to anyone who sees it to fix it.  It also means you can make
a new policy yourself. </p>

<p>Policies are intended be a tool for checking the voting behaviour of an
MP or a Lord, on top of the ability to read their individual votes.  They
provide nothing more than a flash summary of the data, a summary which you can
drill down through to get to the raw evidence.</p>


<h2 class="faq"><a name="legal">Legal question, what can I use this information for?</a></h2>

<p>Anything, as long as you share it.  This website is copyrighted by us, and 
the software is free open source. The data is licensed under an open data license.  
See the next two questions for details. </p>

<p>Amongst other things, this means that if you use it, you should
double check the information.  It may be wrong.  If you are going to rely on it,
at the very least do some random cross-checking to make sure it is valid.
Whichever way, use it at your own risk.  Of course we'd rather you helped us fix the
software and correct any contact.
See the answer to <a href="#contact">I've found an error</a> for details.</p>

<p>If you reproduce this information, or derive any interesting results from
it, you must refer your readers to www.publicwhip.org.uk.  This way they
can use and contribute themselves.</p>

<p>Public Whip's data meets with the 
<a href="http://okd.okfn.org/">Open Knowledge Definition</a>.
 <!-- Open Knowledge Link -->
<a href="http://okd.okfn.org/">
<img style="vertical-align: bottom" alt="This material is Open Knowledge" border="0"
src="/images/ok_80x23_red_green.png" /></a>
<!-- /Open Knowledge Link -->

<h2 class="faq"><a name="playwith">Can I play with the software?</a></h2>

<p> Sure.  All the software we've written is free (libre and gratuit), protected by the <a href="http://www.fsf.org/licensing/licenses/agpl-3.0.html">GNU Affero General Public License</a> (which means you can use it and change it, but you have to release any changes you make).  It's not complicated,
anyone can have a go running them.  But there's only a point in doing
this if you are going to change it as otherwise you will see the same
results.  For more details go to the special <a
href="project/code.php">coding section</a> of this website.

<h2 class="faq"><a name="datalicense">What license is the data under?</a></h2>

<p> To the extent which we have rights to this database of MPs voting records 
and related information, it is licensed under the 
<a href="http://opendatacommons.org/licenses/odbl/">Open Data Commons Open Database License</a>.
This is an attribution, share-alike license. That means that you must credit the Public
Whip, for example via a link, if you use the data. It also means that if you build
on this data, you must also share the result under a compatible open data license.
</p>

<h2 class="faq"><a name="whyfree">Why are you giving everything away for free?</a></h2>

<p>We're not; we're letting you take copies.  Whatever you do, we still
have our computers, all the programs, and our domain name.  The more
people who are playing with this sort of thing, the more cool ideas can
come out of it.

<p>We could wrap it up as a service and sell it to political lobbying
organizations for cash.  This would, however, be pointless since it
would take away the notion of the public having access to it.  All that
would happen is that the people who are already organized influentially
would retain all the power but would have slightly better software
(which they probably have already).


<h2 class="faq"><a name="organisation">What organisation is behind the Public Whip?</a></h2>
<p>It was started by just two guys <a href="http://www.flourish.org">Francis</a> and <a
href="http://www.goatchurch.org.uk">Julian</a> who had an idea and made it happen. In August 2011 it was handed over to <a href="http://www.bairwell.com/">Beebware Ltd</a> to further develop and expand the project. The site will remain true to its open source roots.</p>


<h2 class="faq"><a name="theyworkforyou">What's your connection with TheyWorkForYou.com?</a></h2>

<p>Both of Public Whip's founders, Francis and Julian, are members of that project, but Bairwell and Public Whip are not. Both projects currently use code and data in the separate <a href="http://ukparse.kforge.net/parlparse">Parliament
Parser</a> project.</p>



<h2 class="faq"><a name="interviews">Are you happy to give interviews about Public Whip?</a></h2>

<p>Yes, though at the time of writing (September 2011) we are still getting to grips with the project. Email team@publicwhip.org.uk for press enquiries (we're always happy to hear from bloggers as well as major news organisations).</p>


<h2 class="faq"><a name="money">Do you make any money out of Public Whip?</a></h2>

<p>Public Whip is run on a not-for-profit basis. We are preparing to offer a limited number of sponsorship and advertising packages to carefully selected organisations, the income from which will contribute to the redevelopment and expansion of the project. If you are interested in sponsoring, or advertising with, Public Whip please contact us via team@publicwhip.org.uk .</p>

<h2 class="faq"><a name="living">How do you earn enough to make a living?</a></h2>

<p>We're a small web development company that works on many commercial projects. We run Public Whip in our .spare. time, and fund it out of our own pocket, because we believe in it.</p>

<h2 class="faq"><a name="millions">I've just got a job at a company that's been contracted
by Parliament, or some other organisation, to process Parliamentary data.  I
don't understand why you have written your software for free in your spare time
when I'm paid to do the same thing.</a></h2>

<p>Good for you! Feel free to approach us for any advice we can offer on solving the problems we have encountered during the development of the software. There's also quite a lot of information posted on <a href="http://ukparse.kforge.net/parlparse">Parliament Parse</a>.</p>


<h2 class="faq"><a name="officials">Have you had any problems from MPs or other politicians with what you are doing?</a></h2>

<p>Mostly they ignore us.  If anyone in power has had an objection to what we
are doing, they have kept it to themselves.  As a rule, politicians must
contrive to frame their desires into something that relates to the public
interest.  We can't rule out the possibility that some creative genius will 
eventually invent a reason
which explains how what we are doing causes more harm than good, but it's unlikely.  </p>

<p>Most of the problems have had to do with the inaccuracies
in the <a href="#freevotes">attendance and rebellion rates</a>.
Once we point out that we can only be improved the data
only when the politicians are willing to publish their secret party whip information,
the criticism generally falls silent.  </p>



<h2 class="faq"><a name="rss">Are there any RSS syndication feeds?</a></h2>

<p> First an explanation.  RSS is a way to let you easily read news from lots
of different sources.  You need a special program called a newsreader to do
this.  On the BBC website, there's a <a href="http://news.bbc.co.uk/2/hi/help/3223484.stm">full
description</a> of how to do it.  We provide the following RSS feeds:

<p>
<a href="/feeds/interestingdivisions.xml">interestingdivisions.xml</a> &mdash; Find out every time there are more than 10 "rebellions" in a division.
<br><a href="/feeds/alldivisions.xml">alldivisions.xml</a> &mdash; Keep on top of every division in Parliament, after it happens.

<h2 class="faq"><a name="spreadsheet">Where is the data in spreadsheet file format or in XML?</a></h2>

<p> Take a look at our <a href="project/data.php">Raw Data</a> page.

<h2 class="faq"><a name="datamodel">How does this XML nonsense all work?</a> </h2>

<p>To us XML is nothing more than a standard text file for structured information, 
so any highfalutin' claims you may have heard about it do not apply in our case.  

<p>When the Hansard debates go online on the parliament.uk website, our 
parsing software starts to work on it.  Step one is to download all the 
pages and 'de-pagenate' them.  This turns each day into one page, which you 
can see a directory of <a href="http://ukparse.kforge.net/parldata/cmpages/debates/"> here</a>.  

<p>You can browse through our full list of archived original data 
in <a href="http://ukparse.kforge.net/parldata/"> this directory</a>, 
including a daily copy of frequently updated pages such as 
<a href="http://ukparse.kforge.net/parldata/cmpages/chgpages/govposts/"> lists of ministerial positions</a>, 
which is how we keep track of this data when it becomes history and 
is nowhere else recorded.  

<p>After downloading, or 'scraping', the pages are parsed into a fairly self-explanatory 
XML format, examples of which can be seen <a href="http://ukparse.kforge.net/parldata/scrapedxml/debates/"> 
in this directory</a>.  For further information, please see the <a href="http://ukparse.kforge.net/parlparse/"> 
Parliament Parser homepage</a>.  

<p>Often there are typos, mistakes, or unusual unusual formatting that the parser can't cope with, in 
which case they need to get patched up before the process can complete.  This usually 
accounts for the delay in the morning.  Some examples of patch files can be 
found in <a href="http://ukparse.kforge.net/parldata/patches/debates/"> this directory</a>.  
Later in the day some sharp-eyed MP or clerk might spot them independently 
and ask for a correction in the text which they could have found out about 
by checking these diff files.  When there are corrections, we keep both versions 
and mark up the differences.  Look for XML files where there is both an 'a' and 'b' 
version on the same date.  



<h2 class="faq"><a name="patents">What is the fuss about software patents?</a></h2>
<p>A new European directive on software patents threatens the existence
of websites like The Public Whip.   We'd like your help to stop it.  <a
href="patents/index.html">For more information see here</a>.

<h2 class="faq"><a name="election">What did you do for the 2005 election?</a></h2>
<p>During the 2005 General Election campaign we ran a <a href="election.php">how
they voted quiz</a>.  You can still take it and link to the results.


<h2 class="faq"><a name="help">Can I help with the project?</a></h2>
<p>Sure! We're looking for people who are interested in editing the motion descriptions on some of the divisions. See the following question for details. If you have particular skill-sets that you feel you could contribute, then do please email us at team@publicwhip.org.uk.</p>



<h2 class="faq"><a name="motionedit">What do you mean by editing the motion description?</a></h2>

<p>When there is a division in Parliament, it is not always easy to see what it means. Quite often you have to scan through all of the debate in which the division took place (looking for the phrase "I beg to move"), and have a good knowledge of the the jargon to work it out. Also, many votes are about making changes in other documents (eg "to leave out line 5 on page 13 of the Ordinary Persons Pensions Bill") which needs to be found and made available through a link.</p>
<p>The Public Whip software isn't currently sophisticated enough to do this automatically, and it requires help from a person like you. You can find out more about it on our <a href="/project/research.php">Research page</a>, where there is a page of ideas on how to do it.</p>

<p>In the longer term, it would be better if Parliament told us the meanings of their votes in plain english from the beginning, rather than hiding what they were doing behind layers of unnecessary technicalities so that people didn't have to invent sites like Public Whip to make it possible to work out what was going on. If enough of us got involved we would be able to tell MPs in exact detail everything we expect their record to be, and get something close to what we want.</p>


<h2 class="faq"><a name="simproj">What other projects are similar to Public Whip?</a></h2>

<p>We currently rely on the <a href="http://ukparse.kforge.net/parlparse">Parliament Parser</a> project.</p>
<p>Outside of the Open Source community, some academics have worked in this area. Usually, however, after going through the expense of gathering their data, and writing their academic books and papers and giving their interviews, they throw it all away and don't get round to building a live website. The most active person in this field at the moment is <a href="http://revolts.co.uk/">Philip Cowley</a> who makes much of his research available in PDF form.</p>
<p>Many news organizations publish Parliamentary data, and so therefore must be doing some of the same work we are doing, without necessarily knowing that they can use everything we have done for free as a basis.</p> 
<p>You can read more about this subject in the <a href="http://en.wikipedia.org/wiki/Parliamentary_informatics">Parliamentary Informatics</a> Wikipedia article.</p>


<h2 class="faq"><a name="keepup">How can I keep up with what you are doing?</a></h2>
<p>There's the <a href="http://blog.publicwhip.org.uk/">blog</a> and our <a href="http://www.facebook.com/pages/Public-Whip/199268083464697">Facebook page</a>, or you can ask us questions and get updates via and our <a href="http://twitter.com/publicwhip">Twitter account</a>.</p>


<h2 class="faq"><a name="contact">There's something wrong with your webpage / I've found an error / Your wording is dreadfully unclear / Can I make a suggestion?</a></h2>

<p>You can contact us via email at team@publicwhip.org.uk, our <a href="http://www.facebook.com/pages/Public-Whip/199268083464697">Facebook page</a> and our <a href="http://twitter.com/publicwhip">Twitter account</a>. We are currently investigating the best option for error reporting, so please use one of the above methods in the meantime.</p>

<?php pw_footer() ?>


