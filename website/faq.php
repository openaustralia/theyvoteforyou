<?php $title = "Frequently Asked Questions"; include "header.inc" 
# $Id: faq.php,v 1.10 2003/10/15 17:15:48 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<h2>What is the Public Whip?</h2>
<p>The Public Whip is a project to monitor the voting records of
Members of the United Kingdom Parliament, so that the public (people
like us) can better influence their voting patterns.

<h2>First, can you explain "division" and other political jargon?</h2>
<p>The House of Commons <i>divides</i> many times each week into those who
vote "aye" ("yes", for the motion) and those who vote "noe" ("no",
against the motion).  Each political party has <i>whips</i> who try to
make their MPs (Members of Parliament) vote for the party line.
Sometimes an MP <i>rebels</i> by voting against the party whip.

<h2>How does the Public Whip work?</h2>
<p>All the House of Commons debate transcripts (<a href="http://www.parliament.the-stationery-office.co.uk/pa/cm/cmhansrd.htm">Hansard</a>) back to
1988 are published electronically on the World Wide Web.  We've written
a program to read it for you and separate out all the records of
voting.  This information has been added into an online database which
you can access.

<h2>What time period does it cover?</h2>
<p>The data extends back across two parliaments to the May 1997 General
Election.  New divisions are added semi-manually, so may not appear
until a few days after they happen.  We give no warranty for the data;
there may be factual inaccuracies.  <a
href="mailto:support@publicwhip.org.uk">Let us know</a> if you find any.

<?php
    include "db.inc";
    include "parliaments.inc";
    $db = new DB(); 

    $div_count = $db->query_one_value("select count(*) from pw_division");
    $mp_count = $db->query_one_value("select count(*) from pw_mp");
    $vote_count = $db->query_one_value("select count(*) from pw_vote");
    $vote_per_div = round($vote_count / $div_count, 2);
    $db->query("select count(*) from pw_mp group by party"); $parties = $db->rows();
    $rebellious_votes = $db->query_one_value("select sum(rebellions) from pw_cache_mpinfo");
    $rebelocity = round(100 * $rebellious_votes / $vote_count, 2);
    $attendance = round(100 * $vote_count / $div_count / ($mp_count / parliament_count()), 2);
?>

<p>Some numeric statistics: The database contains <?=$mp_count?> 
MPs from <?=$parties?> parties. There are <?=$div_count?> divisions
which have been counted.  A mean of <?=$vote_per_div?> MPs voted
in each division.  In total <?=$vote_count?> votes were cast, of which
<?=$rebellious_votes?> were against the majority vote for their party.
That's an overall <?=$attendance?>% attendance rate and
<?=$rebelocity?>% rebellion rate.

<h2><a name="legal">Legal question, what can I use this information for?</a></h2>

<p>Anything.  The contents of this website are copyrighted by us, and
except for the software you can use them how you like.  This data is
distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

<p>Amongst other things, this means that if you use it, you should
double check the information. It may be nonsense.  If you can't be
bothered, at least do some cursory cross checking.  Whichever way, use
is at your own risk.  Of course we'd rather you helped us fix the
software and correct any errors, so <a
href="mailto:support@publicwhip.org.uk">send us an email</a> if you find
inaccuracies.

<p>If you reproduce this information, or derive any interesting 
results from it, we ask you to refer your readers to
www.publicwhip.org.uk.  This way they can use and contribute themselves.

<h2>Can I play with the software?</h2>

<p> Sure.  All the software we've written is free (libre and gratuit), protected by the 
<a href="GPL.php">GNU General Public License</a>.  It's not complicated,
anyone can have a go running them.  But there's only a point in doing
this if you are going to change it as otherwise you will see the same
results.  For more details go the special <a
href="code.php">coding section</a> of this website.

<h2>Why are you giving everything away for free?</h2>

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

<h2>What organisation is behind the Public Whip?</h2>
<p>None.  Just two guys <a href="http://www.flourish.org">Francis</a>
and Julian who had an idea and made it happen.  <a
href="http://www.knownoffender.net/">Giles</a> designed the look of the
website.  We're hosted by the ever helpful and encouraging
<a href="http://www.mythic-beasts.com/">Mythic Beasts</a>.

<h2>How can I keep up with what you are doing?</h2>
<p><a href="account/register.php">Subscribe to our newsletter!</a>  It's
at most once a fortnight, and has interesting news and articles
relating to the project.

<h2>Where can I email?</h2>
<p>If you have any problems, comments, queries, suggestions or offers of help email <a
href="mailto:support@publicwhip.org.uk">support@publicwhip.org.uk</a>.

<?php include "footer.inc" ?>

