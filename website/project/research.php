<?php
require_once "../common.inc";
require_once "../db.inc";
# $Id: research.php,v 1.9 2005/12/09 13:59:13 goatchurch Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$title = "Parliamentary Research"; pw_header();
?>

<h2>Introduction</h2>

<p>Many people use Public Whip to research their area of special interest 
and understand what Parliament is doing.  We want to make it possible for 
everyone to share the workload of decoding the jargon and summarising 
the documents.  Just being able to help one another to find necessary 
information will be a major step forward.

<h2>Commenting on debates</h2>

<p>Over at <a href="http://www.theyworkforyou.com">TheyWorkForYou.com</a>
(there is a direct link from every division page)
you can post your comments against speeches in the Parliamentary debates.    
This is a good way to highlight important facts or
add information that may have been left out of the official discussion.

<h2>Division description editing</h2>

<p>When the system uploads a new Parliamentary division, it prints the following statement 
above the words:

<blockquote>Description automatically extracted from the debate, please edit it
to make it better.</blockquote>

<p>While <a href="http://www.theyworkforyou.com">TheyWorkForYou.com</a> helps
to make the debates more friendly, it doesn't make the motions more readable, and our computer
program often guesses it wrong. Not only that, even when it gets it right, the
accurate text uses too much Parliamentary jargon and refers to other documents
by page and line number where it would better be served by a
hyperlink.  This is particularly true for legislation.

<p>Public Whip allows anyone to write a plain english version of the
motion, with links to explanations and relevant document.

<p>We are looking for people who are passionate about issues in
Parliament that have been subject to frequent, repeated votes by MPs.
It could be immigration, education, the environment, transport, international development, and so on.
Find these divisions, mark
them with a Policy, and fix the division descriptions so that other people can
see the precise meaning of what was voted upon.  Public Whip is about
making an informed choice based on the definitive record,
and not having to take anyone's word for things.

<h2>Examples of division description editing</h2>

<p>The first example is <a href="http://www.publicwhip.org.uk/division.php?date=2005-03-02&number=110">Council Tax - 2 Mar 2005 - Division No. 110</a>, which is an opposition motion.  These have a simple
structure, but even so wording and formatting changes make the effect of the
motion much clearer.  The crucial thing it that it should be easier to tell
what Aye and No mean.

<table> <tr class="headings"><th>Before Editing</th><th>After Editing</th></tr>
<tr><td class="oddcol">
        <p>I beg to move,</p>

        <p>That this House notes that council tax bills have increased by 70 per
    cent. under the Labour Government, with further above-inflation rises planned
    in the forthcoming year and after the general election; expresses concern that
    pensioners have been hit hardest and calls on the Government to implement the
    Conservative policy of an automatic council tax discount for those aged 65 and
    over; notes with alarm the Government's plans in any third term for a
    revaluation which would lead to greater inequities and new higher council tax
    bands; rejects Liberal Democrat plans for a local income tax, regional income
    tax and higher national income tax; and calls for less bureaucracy and
    interference from Whitehall and regional bureaucrats in local government
    funding and for greater transparency in the allocation of local funding for
    councils.</p> <p>I beg to move, To leave out from &quot;House&quot; to the end
    of the Question and to add instead thereof:</p>
        <p class="indent">&quot;welcomes the Government's support for local
    government with its 33 per cent. grant increase in real terms since 1997,
    compared to a real terms cut of 7 per cent. in the last four years of the
    previous administration; notes that the increase in council tax this year is
    set to be the lowest in over a decade at around 4 per cent. and the second
    lowest since it was introduced and is less than the increase in average
    earnings; notes CIPFA's view that it will add less than &#163;1 a week to
    average council tax bills; further notes that the effect of the Opposition's
    policy to cut grant to councils and abolish capping would allow council tax to
    rise unchecked; and looks forward to the report of the Lyons inquiry into local
    government funding which is due by the end of this year.&quot;</p>
    <p><i>Question put,</i> That the original words stand part of the
    Question:&#8212;</p>

        <p><i>The House divided:</i> Ayes 140, Noes 322.</p>

</td><td class="evencol">

 <p>The no voters successfully changed the motion text from:</p>     <p
class="indent">This House notes that council tax bills have increased by 70 per
cent. under the Labour Government, with further above-inflation rises planned
in the forthcoming year and after the general election; expresses concern that
pensioners have been hit hardest and calls on the Government to implement the
Conservative policy of an automatic council tax discount for those aged 65 and
over; notes with alarm the Government's plans in any third term for a
revaluation which would lead to greater inequities and new higher council tax
bands; rejects Liberal Democrat plans for a local income tax, regional income
tax and higher national income tax; and calls for less bureaucracy and
interference from Whitehall and regional bureaucrats in local government
funding and for greater transparency in the allocation of local funding for
councils.</p> <p>To:</p>
    <p class="indent">This House welcomes the Government's support for local
government with its 33 per cent. grant increase in real terms since 1997,
compared to a real terms cut of 7 per cent. in the last four years of the
previous administration; notes that the increase in council tax this year is
set to be the lowest in over a decade at around 4 per cent. and the second
lowest since it was introduced and is less than the increase in average
earnings; notes <a href="http://www.cipfa.org.uk/">CIPFA</a>'s view that it
will add less than &#163;1 a week to average council tax bills; further notes
that the effect of the Opposition's policy to cut grant to councils and abolish
capping would allow council tax to rise unchecked; and looks forward to the
report of the Lyons inquiry into local government funding which is due by the
end of this year.</p>

</td></tr>
</table>

<p>The second example is <a href="http://www.publicwhip.org.uk/division.php?date=2002-10-29&number=335">Ministerial Statements proposals - 29 Oct 2002 - Division No. 335</a>, which is a motion to change parliamentary
procedures.  This has a textual amendment to a motion, and can be explained in less
technical language than the original.

<table> <tr class="headings"><th>Before Editing</th><th>After Editing</th></tr>
<tr><td class="oddcol">

 <p class="italic">Motion made, and Question proposed,</p>    <p
class="indent">That this House takes note of the Third Report from the
Procedure Committee, <i>Parliamentary Questions,</i> House of Commons Paper No.
622, and the Government Response thereto, Cm 5628, and approves the proposals
in both for a quota on named day questions, a reduction in the daily quota of
questions per department, the introduction of electronic tabling subject to
safeguards to ensure the authenticity of questions and the power of the Speaker
to modify or halt the system if it appears it is being abused, and the timing
and printing of answers to written questions and written ministerial
statements. &#8212;<i>[Mr. Woolas.]</i></p>    <p class="italic">Amendment
proposed: (a), in line 8, leave out 'and written Ministerial
statements'.&#8212;[Mr. Greg Knight.]</p> <p><i>Question put</i>, That the
amendment be made:&#8212;</p> <p><i>The House divided:</i> Ayes 144, Noes
386.</p>

</td><td class="evencol">

<p>The Aye-voters failed to remove the words <i>'and written ministerial
statements'</i> from the motion:</p> <p class="indent">This House takes note of
the <a
href="http://www.publications.parliament.uk/pa/cm200102/cmselect/cmproced/622/62202.htm">Third
Report from the Procedure Committee, <i>Parliamentary Questions,</i> House of
Commons Paper No. 622</a>, and the Government Response thereto, <a
href="http://www.hmso.gov.uk/information/cmpapers/cm_5600.htm">Cm 5628</a>, and
approves the proposals in both for a quota on named day questions, a reduction
in the daily quota of questions per department, the introduction of electronic
tabling subject to safeguards to ensure the authenticity of questions and the
power of the Speaker to modify or halt the system if it appears it is being
abused, and the timing and printing of answers to written questions <i>and
written ministerial statements</i>.</p>

</td></tr>
</table>

<p>TODO: Give third example of legislative amendment vote.

<h2>Guidelines for editing the description of divisions</h2>

<ul class="motionguidelines">

<li>Avoid Parliamentary jargon.  Phrases like "Question Put", "I beg to move",
and "Third Reading" should not be used unless explained.  

<li>Make it clear which side won the vote so people don't need to read the
numbers to discover the result.  When they do look at the vote chart after
reading the division description, they should already know what the Ayes and Noes mean.  

<li>Whenever there is an amendment to a motion, both the original motion and
the amended motion should be listed, never the amendment which is meaningless
on its own.  

<li>Include all possible hyper-links.  Parliamentary motions can mention
Departmental Reports, Command Papers, UN resolutions, items in the news, and
past statements or votes in the House.  Track everything down using Google and
make links to them so that people who don't know these source documents exist
can find them.   Political statements must at no time be more than one click
away from the facts that support or dispute it.  

<li>If there is a vote to pass a Statutory Instrument, link to the Statutory
Instrument and the Statute.  Votes to change the Parliamentary Standing Orders
should link to both versions of the Standing Order and provide an explanation
and examples.  However, not every mention of a Standing Order needs to be
linked if it's the Speaker reading them out to justify what going to happen
next.  

<li>A division on a piece of legislation must have the full and correct name of
the Bill in the title followed by a dash "--" and any further qualifiers:
"Money Resolution", "Second Reading", "Programme Motion", etc.  

<li>The reason for these qualifiers in a legislation division is to put the
vote in its place within the standard procedural plot.  Links to the next unit
(eg the Standing Committee page) and the preceding unit of the plot is also
desirable.  

<li>You must endeavor to link to the correct version of the Bill.  There can be
several and you must carefully examine the titles and the dates to be sure to
get them right.  The links to them are often broken, but the pages can be found
by searching for the title in quotes plus site:parliament.uk in Google.  

<li>When a clause or set of clauses are agreed to, link to them directly and
summarize their meaning if possible.  Interpret the meaning as best you can,
and if you can't fully understand it, say so.  If a clause amends another Act
that is online, then link directly to that part of the Act that has been
changed.  In the future we will be able to create back-links.  The word
"clause" and "section" are sometimes used interchangeably.  

<li>Amendments to clauses are the hardest part of the job.  You have to read
the top and the bottom of the debate relating to the division very carefully.
When the Speaker says: "With this it will be convenient to discuss the
following Amendments" he's telling you the subject of the debate, not the
meaning of the division.  The division only applies to what the MP said in the
phrase: "I beg to move".  However, some of the amendments the speaker lists may
need to be considered because the amendment that was moved is incomplete on its
own.  This is because each contiguous change in the text is a separate
amendment.  It's sometimes possible to find a webpage listing all the
amendments.  

<li>Watch out for the phrase "Amendment by leave withdrawn" just before the
division is called, or you will put in the wrong text.  Sometimes the Speaker
restates the amendment before or after the division, but many times not.  Watch
out for negations: "That the original words of the clause stand part" versus
"That the amendment be made."  

<li>Once you have started working through the votes on a Bill, stick to it.  It
can take as long as an hour to piece together the meaning of a division in the
worst case.  Fortunately, they don't vote on the most boring parts of the Bill,
so you don't need to analyze them.  However, it's a good idea to page through
the full text of a Bill to get a feel for its content.  Once you get to know it
a little bit you'll be best placed to finish it off, so do so.  

<li>As well as making the division description as clear, readable and honest as
possible so that people can decide how they feel about the MPs who voted for or
against it, leave it in a state that gives those who want to do further
research a head start.  If you spent an hour working out a motion, think of it
as saving an hour of someone else's time, which means they will be able to do
research that would otherwise not have been possible.  For example, newspaper
reporters need to get to creditable facts quickly.  You may have given them a
channel into the heart of the process which means they don't have to rely on a
self-serving Government press notice to track down the news.  

<li>Division description editors are independent of Parliament, which means we
can be critical of its process in the way that anyone in the system is
unwilling or unable to be.  But check up on each other's work whenever you can.

<li>We have experienced little use and no actual signs of abuse.  Until we
experience abuse, we cannot make provisions for it.  In practice, wikis
experience surprisingly little abuse, probably because it's usually obvious and
there are more people prepared to erase the abuse than create it.  There's
always the chance that a party may try to hijack this outlet as they do so many
political happening.  However it's unlikely because it could too easily be
found out and backfire.  

<li>To prevent us (Francis and Julian) from abusing PublicWhip, we have
released all the code under the General Public License.  We would also like to
establish a public repository for all the Policy and Motion Text information
so that we can't be accused of owning the information.  The safeguard is that
anyone with the right skills can download and establish a rival version of
PublicWhip (under another domain name) in case we get lazy, sell out, or run
into some sort of legal hassle.  We must ensure that it can live on by
disabling our ability to abolish it.  

</ul>

<?php pw_footer() ?>

