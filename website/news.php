<?  $title = "News"; include "header.inc";
# $Id: news.php,v 1.4 2003/09/17 12:01:33 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

/*
<h2>2003 by Francis</h2>
<p></p>
*/
?>

<h2>Detecting abstentions - 16 September 2003 by Francis</h2>
<p>Quite often members deliberately refrain from voting in a division,
even if they are in the house so could have done so.  Conversely, on an
important vote, the whip of one party will deliberately try and get a
higher turnout.  A while ago Becka suggested a way of detecting these
effects.</p>

<p>You add up the turnouts for each party across <b>all</b> divisions
and end up with a percentage expected vote share per party.  Then you
calculate, given the total turnout for this particular division, what
the percentage would lead you to expect.  If the number of voters in
the party is much different from your expectation, then something
interesting is happening.</p>

<p>This calculation has been in Public Whip for a while, manifest as a
mysterious column of numbers on the party table in the division listing.
I've hopefully made it a bit clearer, using the terminology of
abstentions, and displating high abstention parties even if nobody in them
voted.  Have a look at the recent <a
href="division.php?date=2003-09-10&number=307">Iraq and the UN vote</a>,
where the Lib Dems proposed a motion.  You can see from the large
abstention number for the Conservatives that the party whip must have
been to abstain.  Indeed none of them voted at all.</p>

<h2>Which Gareth Thomas? - 12 September 2003 by Francis</h2>
<p>One of the things I'm doing at the moment is improving the quality of
data for the current parliament.  There are sometimes ommissions or
inconsistencies within Hansard itself.  Those errors for recent months
are corrected when the session is put into a "bound volume".  Although
this concept originally applied to the paper versions of Hansard, it is
passed on to the electronic version.  There are also sometimes errors in
the bound volume text as well.</p>

<p>One example is <a
href="http://www.publications.parliament.uk/pa/cm200203/cmhansrd/cm030120/debtext/30120-25.htm">division 56</a> from
during a debate on occupational pensions at the start of this year.
There are two MPs both called Gareth Thomas, one the member for Clwyd
West and the other for Harrow West.  In this division Hansard doesn't
say which one it was that voted.
I asked the <a
href="http://www.parliament.uk/directories/hcio.cfm">House of Commons
Information Office</a>, who seem to regularly get strange queries like
this.  After some time researching the answer, someone in this
not-quite-byzantine bureaucracy kindly emailed me on Wednesday to say
that the voting member was the one for Harrow West.  You can now
<a href="division.php?date=2003-01-20&number=56&showall=yes">see the
division</a> on this site.</p>

<p>This all sounds a bit trivial and tedious, if necessary as every
MP's reputation could be at stake.  But there are worse things
to come.  The scariest is that quite often the count of votes does
not equal the count listed in Hansard "The House divided: Ayes 100, Noes
200.", when there are actually perhaps 101 ayes listed.  This
happens often enough that I haven't quite dare mention it to HCIO
yet.</p>

<h2>Summer's ended - 9 September 2003 by Francis</h2>
<p>Parliament has reconvened now summer is over.  However, under this new
system, after only two weeks it will adjourn for the party conferences. 
Yesterday there were <a href="search.php?query=water+bill&button=Search">three divisions
votes</a> on the Water Bill.  I'm doing these updates semi-manually at
the moment, so new divisions will only be available a few days after
they happen.</p>

<?php include "footer.inc" ?>
