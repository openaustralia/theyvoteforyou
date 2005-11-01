<?php require_once "../common.inc";
# $Id: liaison.php,v 1.8 2005/11/01 01:23:17 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
$title = "Hansard Liaison Subproject"; pw_header();
?>

<p>The Public Whip puts the pages on the parliamentary website through
punishing tests, which immediately highlight small typing mistakes in
gigabytes of data.  It's rare that you'll notice an error with 
the human eye, but to us writing the software it appears that they are
everywhere.

<h2>Subproject Goals</h2>

<p>The Hansard Liaison Subproject aims to:

<ol>
<li>Track errors which cause material problems for the Public Whip
project.  For example, ambiguous or missing division listings.
Get these corrected on the Hansard website, or clarified so we can add
exceptions to our code.
<li>Work with the official record to improve the quality of their
website.  This includes standards compliant HTML,
consistency of data to aid computerised parsing, and ultimately
provision of information as XML or other structured data files.
<li>Persuade the official record to record the party whips at a division,
if it is clearly visible such as a member waving people into the right
lobby.
</ol>

<h2>Current Status</h2>
<ol>
<li>Currently, we email the House of Commons Information Office, and they get
any serious errors fixed.  They respond to material errors fairly quickly by
either updating parliament.uk, or emailing us with the correction.
<li>We've visited TSO, talked to people in parliament and to MPs about this.
But this is going to take some time.  There is currently a project in
parliament to update their systems to use XML, but the status of the project is
unknown. 
<li>No material progress yet.  Our <a href="../faq.php#freevotes">definition of rebellion</a>
has caused some complaints from MPs, but these so far haven't encouraged either
the parties or Hansard to publish the official party whip for each party.
</ol>

<h2>Hansard Bug Tracker</h2>

<p>For a while we used standard bug tracking software to keep track of errors
in Hansard.  You can browse them using the link below.  Some of the errors are
"serious" which means there is a gap in the public record.  Others are just
formatting errors which (sometimes massively) inconvenience us.

<p><a
href="http://sourceforge.net/tracker/?atid=602722&group_id=87640&func=browse">Hansard
error tracker on Sourceforge</a>

<h2>Baffled Outsider's Guide to the Parliamentary Bureaucracy</h2>

<p><a href="http://www.hansard-westminster.co.uk">Hansard</a> are part
of Parliament.  They are separate from Government, of course. They have
about 16 reporters who sit in the chamber and listen to a small amount of
debate in five or ten minute "shifts".  They then spend an hour typing
it up on a computer with a tape recording.  They produce the Official
Report each day in some (unknown) file format, and it is electronically
transferred to TSO (The Stationary Office).

<p>TSO originates from the Government office HMSO.  Note, <strong>not</strong>
an office of Parliament, although they were employed by Parliament.  TSO was
created by privatising part of HMSO in 1996.  They are an independent, private
publishing company.  They take the electronic Hansard, and from it produce the
daily paper copy.  They also make the bound copies.  More recently, they make
the web site.

<p>(This is clearly a relic of the past, as if web publishing were
analogous to normal publishing.  You don't need a printing press, and
the equivalent (a web server) already exists within the organisation
which wants to publish it, making it pointless for them to contract it
out to an external one.  A reform could streamline this.)

<p>The website publications.parliament.uk is on a separate server to
parliament.uk.  It is managed by TSO rather than Parliament.  TSO also
do other publishing work, but they are a customer of the Parliament
website, so they have to answer to them.

<p><span class="ptitle">House of Commons Information Office (HCInfo)</span>.
The first port of call for anything.  These are
very friendly folk.  They seem used to the most peculiar of queries.
Best is to ring them up on 020 7219 4272. Email <a
href="mailto:hcinfo@parliament.uk">hcinfo@parliament.uk</a>.

<p><span class="ptitle">House of Commons Library Help Desk</span>.
Another help desk, though more for internal use by parliament, whereas
HCInfo is for external use.  Their phone is 0207 219 2345.

<p><span class="ptitle">Information Architecture Support</span>.  If
you email <a
href="mailto:webmaster@parliament.uk">webmaster@parliament.uk</a> it
goes to this division of parliament.

<p><span class="ptitle">The Stationary Office (TSO)</span>.  
This privatised part of the old HMSO (Her Majesty's Stationary
Office) is based mainly in Norwich.  Their phone number is
08457 023474.

<p><span class="ptitle">Parliamentary Press</span>.  An office
of TSO based in London.  Phone them on 0207 394 4255.

<p><span class="ptitle">HMSO Crown Copyright Office</span>. This
is the last remaining non-privatised part of HMSO, the rest is now
owned by TSO.  They deal with all crown and parliamentary copyright
issues.  Phone them on 01603 621000.

<?php pw_footer() ?>

