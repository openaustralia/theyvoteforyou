<?php require_once "common.inc";
# $Id: faq.php,v 1.70 2006/02/17 17:20:12 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
$paddingforanchors = true; $title = "Help - Frequently Asked Questions"; pw_header();
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
<li><a href="#freevotes">Why do you incorrectly say people are rebels in free votes?</a> </li>
<li><a href="#abstentions">How do you estimate abstentions?</a> </li>
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
<p>The House of Commons <i>divides</i> many times each week into those who
vote <i>aye</i> (yes, for the motion) and those who vote <i>no</i> (against the
motion).  Each political party has <i>whips</i> who try to make their
<i>MPs</i> (Members of Parliament) vote for the party line.  Sometimes an MP
<i>rebels</i> by voting against the party whip.  A <i>teller</i> is
an MP involved in the counting of the vote.  For more information on all these
terms, see the
<a href="http://www.parliament.uk/parliamentary_publications_and_archives/factsheets/p09.cfm">
Parliament factsheet on divisions</a>.
<p>The <i>House of Lords</i> is the second chamber of the Parliament. Proposed
legislation must be approved by both Houses before it becomes law. <i>Lords</i> become
members by a complex mixture of appointment, religion, appelation, hereditary
entitlement and self election, which frankly we can't work out. They still
divide, just like the commons. But being "ayes" and "noes" is a bit too, ummm,
common for them. Instead they are said to be either <i>content</i> or
<i>not-content</i> with the motion.

<h2 class="faq"><a name="how">How does the Public Whip work?</a></h2>
<p>All the 
<a href="http://www.parliament.the-stationery-office.co.uk/pa/cm/cmhansrd.htm">House of Commons</a>  and
<a href="http://www.parliament.the-stationery-office.co.uk/pa/ld/ldhansrd.htm">House of Lords</a>
debate transcripts (collectively, Hansard)
back to 1988 are published electronically on the World Wide Web.  We've written
a program to read them for you and separate out all the records of voting.  This
information has been added into an online database which you can
access.


<h2 class="faq"><a name="timeperiod">What time period does it cover?</a></h2>
<p>Voting data for MPs extends back across three parliaments to the May 1997
General Election, although there are a few divisions missing in the 1997
parliament.  Lords membership data extends back to the big reform in 1999,
because nobody can remember who the members were before then.  Lords divisions
currently go back to just May 2005. New divisions usually appear in Public Whip
the next morning, but sometimes take a day or two longer.  We give no warranty
for the data; there may be factual inaccuracies.  <a
href="mailto:team@publicwhip.org.uk">Let us know</a> if you find any.

<?php
    require_once "db.inc";
    require_once "parliaments.inc";
    $db = new DB();

    $div_count = $db->query_one_value("select count(*) from pw_division");
    $mp_count = $db->query_one_value("select count(*) from pw_mp");
    $vote_count = $db->query_one_value("select count(*) from pw_vote");
    $vote_per_div = round($vote_count / $div_count, 1);
    $db->query("select count(*) from pw_mp group by party"); $parties = $db->rows();
    $rebellious_votes = $db->query_one_value("select sum(rebellions) from pw_cache_mpinfo");
    $rebelocity = round(100 * $rebellious_votes / $vote_count, 2);
    $attendance = round(100 * $vote_count / $div_count / ($mp_count / parliament_count()), 2);
?>

<p>Some numeric statistics: The database contains <strong><?=number_format($mp_count)?></strong>
MP and Lord records from <strong><?=$parties?></strong> parties. We've counted
<strong><?=number_format($div_count)?></strong> divisions.  A mean of
<strong><?=$vote_per_div?></strong> MPs/Lords voted in each division.  In total
<strong><?=number_format($vote_count)?></strong> votes were cast, of which
<strong><?=number_format($rebellious_votes)?></strong> were against the majority vote for
their party.  That's an overall <strong><?=$attendance?>%</strong> attendance
rate and <strong><?=$rebelocity?>%</strong> rebellion rate.



<h2 class="faq"><a name="clarify">What do the "rebellion" and "attendance" figures mean exactly?</a></h2>

<p>The apparent meaning of the data can be misleading, so do not to
jump to conclusions about MPs or Lords until you have understood it.

<p>"Attendance" is for voting or telling in divisions. An MP may have a
low attendance because they have abstained, have ministerial or
other duties or they are the speaker.  Perhaps they consider each division
carefully, and only vote when they know about the subject. Lords are 
appointed for life, so they may have decided to retire.
Sinn F&eacute;in MPs, because they haven't taken taken the
oath of allegiance, are unable to vote.
A full list of reasons for low attendance can be found in the Divisions section
on page 11 of <a
href="http://www.parliament.uk/commons/lib/research/rp2003/rp03-032.pdf">a
House of Commons library research paper</a>.  Note also that the Public
Whip does not currently record if a member spoke in the debate but did
not vote.

<p>"Rebellion" on this website means a vote against the majority vote by
members of the MP's party.  Unfortunately this will indicate that many members
have rebelled in a free vote.  Until precise data on when and how strongly each
party has whipped is made available, there is no true way of identifying a
"rebellion".  We know of no heuristics which can reliably detect free votes.
See also the <a href="#freevotes">next question</a>.


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
and at the same time not tell us.  There is no contradiction in admitting the whip
exists and recording it officially&mdash;after all some whips
<a href="http://www.civilservice.gov.uk/management_information/parliamentary/parliamentary_pay/pay/payments_on_leaving_office/index.asp#tables">
are paid a salary by the taxpayer</a> so
there is a precedent for admitting they exist.


<h2 class="faq"><a name="abstentions">How do you estimate abstentions?</a></h2>

<p>It isn't possible for an MP or a Lord to abstain in the UK parliament.  They can
however not vote at all.  We try to detect massive low turnouts on the division
page by estimating abstentions for each party.

<p>They are calculated from the expected turnout, which is statistical based on
the average proportionate turnout for that party in all divisions. A negative
abstention indicates that more members of that party than expected voted; this
is always relative, so it could be that another party has failed to turn out
<i>en masse</i>.</p>

<p>Sometimes MPs also indicate abstention by <a href="boths.php">voting both
aye and no</a>. Lords aren't allowed to do this, the clerks delete them 
completely from the roll call.


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

<p>Policies are intended be a new tool for checking the voting behaviour of an
MP or a Lord, on top of the ability to read their individual votes.  They
provide nothing more than a flash summary of the data, a summary which you can
drill down through to get to the raw evidence.</p>


<h2 class="faq"><a name="legal">Legal question, what can I use this information for?</a></h2>

<p>Anything.  This website is copyrighted by us, and the software is free open source.
You are free to use them how you like within the terms of the public license.
The data is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for a
particular purpose.

<p>Amongst other things, this means that if you use it, you should
double check the information.  It may be wrong.  If you are going to rely on it,
at the very least do some random cross-checking to make sure it is valid.
Whichever way, use it at your own risk.  Of course we'd rather you helped us fix the
software and correct any contact.
See the answer to <a href="#contact">I've found an error</a> for details.

<p>If you reproduce this information, or derive any interesting results from
it, we ask you to refer your readers to www.publicwhip.org.uk.  This way they
can use and contribute themselves.


<h2 class="faq"><a name="playwith">Can I play with the software?</a></h2>

<p> Sure.  All the software we've written is free (libre and gratuit), protected by the <a href="GPL.php">GNU General Public License</a>.  It's not complicated,
anyone can have a go running them.  But there's only a point in doing
this if you are going to change it as otherwise you will see the same
results.  For more details go to the special <a
href="project/code.php">coding section</a> of this website.


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
<p>None.  It was started by just two guys <a href="http://www.flourish.org">Francis</a> and <a
href="http://www.goatchurch.org.uk">Julian</a> who had an idea and made it
happen.  <a href="http://www.knownoffender.net/">Giles</a> designed the
original look of the website.  We're hosted by the ever helpful and encouraging
<a href="http://www.mythic-beasts.com/">Mythic Beasts</a>.  These days lots
of other people help out with bits of code, writing and design.


<h2 class="faq"><a name="theyworkforyou">What's your connection with TheyWorkForYou.com?</a></h2>

<p>Both of us, Francis and Julian, are members of that project, but Public Whip
is not.  These projects use the same underlying code to interpret the online
Hansard pages, but they make different displays of it.  That code and
data is in the separate <a href="http://ukparse.kforge.net/parlparse">Parliament
Parser</a> project.  We are not part of a business and there is no reason for
any project to have control over any other project, so they don't.  You could
take our code and derive a new project from it should you wish.  In fact, if
you have an idea and the time, we will encourage you and give you all the
support we can.</p>



<h2 class="faq"><a name="interviews">Are you happy to give interviews about Public Whip?</a></h2>

<p>Yes.  Both Francis and Julian have given interviews over the phone 
(ring 07970 543358) in the past and had their pictures taken for newspapers.
We would be happy to do more of this.  Francis has even featured on the radio
in "Yesterday in Parliament".  Julian lives in Liverpool, and Francis resides
in Cambridge.  Both travel to London whenever there is something interesting
happening there.  Neither of us has had any working experience inside
Parliament, and so our opinions are very much formed from the outside.  </p>


<h2 class="faq"><a name="money">Do you make any money out of Public Whip?</a></h2>

<p>No.  The only money we've seen is from someone who contributed 70 pounds
towards our internet bill.  We have no moral objection to earning money from
our work, it's just that we are not willing to compromise with the need for
this sort of work to be public and freely available at no cost.  </p>


<h2 class="faq"><a name="living">How do you earn enough to make a living?</a></h2>

<p>We don't have expensive lifestyles.  Francis does IT contract work
for various clients including <a href="http://www.mysociety.org">mySociety</a>,
and Julian is a self-employed programmer of <a href="http://www.freesteel.co.uk/">machine tool software</a>.  Francis and
Julian first met and worked together in 1997 as employees of <a
href="http://www.ncgraphics.co.uk">NC Graphics</a>, a machine tool software company in
Cambridge, before they became enlightened enough to abandon such working
practices and enjoy life without ever having to answer to a boss.  </p>

<p>Many people have hobbies, like pigeon breeding or vintage car racing, that
are far more costly and time consuming than running a webpage.  Just because
the skills we have used can earn real money in the marketplace doesn't mean it
has to be difficult and boring.  </p>

<h2 class="faq"><a name="millions">I've just got a job at a company that's been contracted
by Parliament, or some other organisation, to process Parliamentary data.  I
don't understand why you have written your software for free in your spare time
when I'm paid to do the same thing.</a></h2>

<p>Neither do we.  Often, systems for procuring software give, shall we say,
somewhat suboptimal results.  We'd like less public money to be blown on
software projects that don't work.  If you work for such a company, we'd be
honoured if you approached us for technical advice on how to solve some of the
problems we have encountered during the development of our software.

<p>Sometimes programmers who work in corporations exist in a state of fear and
feel that if they speak to anyone on the outside of the organization they will
get sacked, then sued for releasing commercial secrets, and wind up homeless
never able to get another job again.  If you are too afraid, you do not need to
speak to us.  We have posted up everything we know on <a
href="http://ukparse.kforge.net/parlparse">Parliament Parse</a>.  If there's
anything we're missing which you'd like to see there, drop us a line or post
onto the forum anonymously.</p>


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

<h2 class="faq"><a name="patents">What is the fuss about software patents?</a></h2>
<p>A new European directive on software patents threatens the existence
of websites like The Public Whip.   We'd like your help to stop it.  <a
href="patents/index.html">For more information see here</a>.

<h2 class="faq"><a name="election">What did you do for the 2005 election?</a></h2>
<p>During the 2005 General Election campaign we ran a <a href="election.php">how
they voted quiz</a>.  You can still take it and link to the results.


<h2 class="faq"><a name="help">Can I help with the project?</a></h2>
<p>Sure!  There's lots to be done.  Your first task is to get to know
the structure of the project and think about how better to explain it to
people who don't know much about it, like yourself.  Improvements
in accessibility are the top priority.

<p>The next thing to look at is editing the motion descriptions on some of
the divisions.  We desperately need more people involved in this, and
it is the quickest way to get tangible results.
See the <a href="#motionedit">following question</a> for details.

<p>If you are more technically minded, please glance at the
<a href="http://ukparse.kforge.net/parlparse">Parliament Parser</a>
project, to see if that is your cup of tea.  This is the core
system which enables all our projects to function and where a
difference can be made.

<p>Finally, if that's not enough, there is a wider list of
<a href="http://www.mysociety.org/moin.cgi/VolunteerTasks">
Volunteer Tasks</a> at mySociety.

<p>Hopefully, between all that, you kind find something that
fits your mood.  Email us <a href="mailto:team@publicwhip.org.uk">team@publicwhip.org.uk</a>
if you need to know more.



<h2 class="faq"><a name="motionedit">What do you mean by editing the motion description?</a></h2>

<p>When there is a division in Parliament, it is not always easy to
see what it means.  Quite often you have to scan through
all of the debate in which the division took place (looking for the
phrase "I beg to move"), and have a good knowledge of the the jargon
to work it out.  Also, many votes are about making changes in other
documents (eg "to leave out line 5 on page 13 of the Ordinary Persons Pensions Bill")
which needs to be found and made available through a link.

<p>The Public Whip software is nowhere near sophisticated enough to do this
automatically, and it requires help from a person like you.
You can find out more about it on our <a href="project/research.php"> Research page</a>,
where there is a page of ideas on how to do it.  Please
feel free to discuss things in the
<a href="forum/viewforum.php?f=2"> division forum</a>.

<p>In the longer term, it would be better if Parliament told us the
meanings of their votes in plain english from the beginning, rather than hiding
what they were doing behind layers of unnecessary technicalities so
that people didn't have to invent sites like Public Whip to make it
possible to work out what was going on.  If enough of us got involved
we would be able to tell MPs in exact detail everything we expect
their record to be, and get something close to what we want.


<h2 class="faq"><a name="simproj">What other projects are similar to Public Whip?</a></h2>

<p>We rely on the <a href="http://ukparse.kforge.net/parlparse">Parliament
Parser project</a>
and are closely associated with <a href="http://www.theyworkforyou.com/">theyworkforyou.com</a>,
<a href="http://www.writetothem.com/">writetothem.com</a>,
<a href="http://www.hearfromyourmp.com/">hearfromyourmp.com</a>,
and <a href="http://downingstreetsays.com/">downingstreetsays.com</a>,
partly on account of the fact that we have contributed code to them.
We support anyone who is keen to keen to adapt our systems to
other Parliaments. 

<p>Outside of the Open Source community, some academics have worked in this
area.  Usually, however, after going through the expense of gathering their
data, and writing their academic books and papers and giving their
interviews, they throw it all
away and don't get round to building a live website.
The most active person in this field at the moment is
<a href="http://revolts.co.uk/">Philip Cowley</a> who
makes much of his research available in PDF form, and has written
two books which are relevant to our work.  Julian has
reviewed both and has posted them into the forum at
<a href="http://www.publicwhip.org.uk/forum/viewtopic.php?t=59"> Review of
"Revolts and Rebellions" (Blair's Parliament 1997-2001)</a> and
<a href="http://www.publicwhip.org.uk/forum/viewtopic.php?t=202"> Review of
"The Rebels" (Blair's Parliament 2001-2005)</a>.
You are free to make comments and start a discussion.

<p>Many news organizations publish Parliamentary data, and so therefore
must be doing some of the same work we are doing, without
necessarily knowing that they can use everything we have done for free as a
basis.  Examples include <a
href="http://politics.guardian.co.uk/aristotle/">The Guardian</a> and <a
href="http://news.bbc.co.uk/1/hi/uk_politics/2160988.stm"> The BBC</a>.

<p>Beyond even this, we are aware that political parties and lobbying
groups research and derive information such as this, but don't
make any of it public.  It's worth people asking themselves why
this is the case, and being prepared to make a distinction between
the claim that "they have a right to do so", and whether
it is "right".

<p>You can read more about this subject in the 
<a href="http://en.wikipedia.org/wiki/Parliamentary_informatics">Parliamentary
Informatics</a> Wikipedia article.


<h2 class="faq"><a name="keepup">How can I keep up with what you are doing?</a></h2>
<p><a href="account/register.php">Subscribe to our newsletter!</a>  It's
at most once a month, and has interesting news and articles
relating to the project. You can <a href="/forum/">chat with other users</a> on
our forum.


<h2 class="faq"><a name="contact">There's something wrong with your webpage / I've found an error / Your wording is dreadfully unclear / Can I make a suggestion?</a></h2>

<p>Please post your comments <a href="/forum/">in the forum</a>
under <b>Bugs and Problems</b> or <b>Suggestions and Ideas</b> instead of
emailing us.  This will give us an obvious place to post our replies which you
can look up should you be interested.  </p>

<p>Putting it there is likely to be more effective at getting things done
because if the whole world is able to see just how flaky our system is becoming,
we're more likely to be embarrassed enough to take action.</p>

<p>Email us at <a
href="mailto:team@publicwhip.org.uk">team@publicwhip.org.uk</a> only if it's
something you think should be kept private. Or if the forum isn't working for you.</p>

<?php pw_footer() ?>

