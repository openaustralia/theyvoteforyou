#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import re
import os
import string


# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime


from miscfuncs import ApplyFixSubstitutions

from splitheadingsspeakers import SplitHeadingsSpeakers
from splitheadingsspeakers import StampUrl

from clsinglespeech import qspeech
from parlphrases import parlPhrases

from miscfuncs import FixHTMLEntities
from miscfuncs import WriteXMLHeader
from miscfuncs import WriteXMLFile

from filterdivision import FilterDivision
from filterdebatespeech import FilterDebateSpeech


fixsubs = 	[
        ( 'Taylor, Andrew', 'Turner, Andrew', 1, '2003-02-26'),
        ( '(Brown, Russell),', '\\1', 1, '2003-09-10'),
        ( 'Baird Vera', 'Baird, Vera', 1, '2003-09-10'),
        ( 'itemMercer', 'Mercer', 1, '2003-10-15'),
        ( 'Livingston\)', '(Livingston)', 1, '2003-10-27'),
        ( '<BR>\n, David', '<BR>\nBorrow, David', 1, '2003-11-18'),
        ( '(Charlotte Atkins an)<BR>\s*d', '\\1d<BR>', 1, '2004-03-15'),
	( "(<H3 align=center>.*?)(House of Commons</H3>)\s*(<H2.*?</H2>)\s*(The House.*?clock)", \
		'\\1</H3>\n<H3 align=center>\\2\n\\3\n<H3 align=center>\\4</H3>', 1, '2003-10-27'),
        ( '(<H4><center>THIRD VOLUME OF SESSION 2003&#150;2004)(House of Commons</center></H4>)', \
                '\\1</center></H4>\n<H4><center>\\2', 1, '2004-01-26'),
	( "(<H3 align=center>TENTH VOLUME OF SESSION 2002&#150;2003)(House of Commons</H3>)", \
		'\\1</H3>\n<H3 align=center>\\2', 1, '2003-04-07'),
	( "(<H3 align=center>NINTH VOLUME OF SESSION 2002&#150;2003)ana(House of Commons</H3>)", \
		'\\1</H3>\n<H3 align=center>\\2', 1, '2003-03-24'),
	( '\{\*\*pq num="76041"\*\*\}', '', 1, '2002-10-30'),
        ( '(2003)(House of Commons)', '\\1</center></H4>\n<H4><center>\\2', 1, '2003-06-03'),
        ( '(2003)(House of Commons)', '\\1</center></H4>\n<H4><center>\\2', 1, '2003-05-12'),
        ( '(2003)(House of Commons)', '\\1</center></H4>\n<H4><center>\\2', 1, '2003-04-28'),

        ( '(<FONT SIZE=-1>2 Dec. 2003)', '\\1\n</FONT></TD></TR>\n</TABLE>', 1, '2004-02-05'),

	( '<i> </i>', '', 1, '2003-01-27'),

	( '<UL><UL>Adjourned', '</UL><UL><UL><UL>Adjourned', 1, '2003-05-22'), # putting a consistent error back in
	( '<UL><UL>End', '</UL><UL><UL><UL>End', 1, '2002-11-07'), # as above
        ( '<UL><UL>', '<UL><UL><UL>', 1, '2003-06-25'),

	( '<UL><UL><UL>Adjourned', '<UL>Adjourned', 1, '2004-03-05'),
	( 'o\'clock\.\s*</UL></UL></UL>', 'o\'clock.</UL>', 1, '2004-03-05'),

	( '<UL><UL><UL>', '<UL>', 1, 'all'),
	( '</UL></UL></UL>', '</UL>', 1, 'all'),
		]

rehousediv = re.compile('<p[^>]*>(?:<i>)?\s*The (?:House|Committee) (?:having )?divided(?:</i>|:)+ Ayes,? (\d+), Noes (\d+)\.</p>$')

foutdivisionreports = open("divreport.html", "w")
#foutdivisionreports = None
def PreviewDivisionTextGuess(foutdivisionreports, flatb):
	# loop back to find the heading title
	# (replicating the code in the publicwhip database builder, for preview)
	iTx = 1
	i = 1
	heading = "NONE"
	while i < len(flatb):
		if re.search("division", flatb[-i].typ) and iTx == 1:
			iTx = i
		if re.search("heading", flatb[-i].typ):
			heading = string.join(flatb[-i].stext)
			break
		i += 1
	# the place we search for motion text from
	if iTx == 1:
		iTx = i
 	# keep going back to find the major heading
 	if i < len(flatb) and not re.search("major-heading", flatb[-i].typ):
		while i < len(flatb):
			i += 1
			if re.search("major-heading", flatb[-i].typ):
				heading = '%s %s' % (string.join(flatb[-i].stext), heading)
				break

	divno = re.search('divnumber="(\d+)"', flatb[-1].speaker).group(1)
	link = flatb[-1].sstampurl.GetUrl()
	pwlink = 'http://www.publicwhip.org.uk/division.php?date=%s&number=%s' % (flatb[-1].sstampurl.sdate, divno)
	foutdivisionreports.write('<h2><a href="%s">Division %s</a>   <a href="%s">%s</a></h2>\n' % (pwlink, divno, link, heading))

	hdivcg = re.match('\s*<divisioncount ayes="(\d+)" noes="(\d+)"', flatb[-1].stext[0])
	hdivcayes = string.atoi(hdivcg.group(1))
	hdivcnoes = string.atoi(hdivcg.group(2))

	# check for house divided consistency in vote counting
	bMismatch = False
	hdg = rehousediv.match(flatb[-2].stext[-1])
	if hdg:
		hdivayes = string.atoi(hdg.group(1))
		hdivnoes = string.atoi(hdg.group(2))

		if (hdivayes != hdivcayes) or (hdivnoes != hdivcnoes):
			bMismatch = True

	if bMismatch:
		foutdivisionreports.write('<p><b>Mismatch Count Ayes: %d, Count Noes: %d.</b></p>\n' % (hdivcayes, hdivcnoes))

	# write out the detected motion text for Francis
	while iTx >= 3:
		iTx -= 1
		j = 0
		while j < len(flatb[-iTx].stext):
			if re.search('pwmotiontext="True"', flatb[-iTx].stext[j]):
				foutdivisionreports.write("%s\n" % flatb[-iTx].stext[j])
			j += 1



# parse through the usual intro headings at the beginning of the file.
#[Mr. Speaker in the Chair] 0
def StripDebateHeading(hmatch, ih, headspeak, bopt=False):
	if (not re.match(hmatch, headspeak[ih][0])) or headspeak[ih][2]:
		if bopt:
			return ih
		print headspeak[ih]
		raise Exception, 'non-conforming "%s" heading ' % hmatch
	return ih + 1

def StripDebateHeadings(headspeak, sdate):
	# check and strip the first two headings in as much as they are there
	ih = 0
	ih = StripDebateHeading('Initial', ih, headspeak)

	# volume type heading
	if headspeak[ih][0] == 'THE PARLIAMENTARY DEBATES':
		ih = StripDebateHeading('THE PARLIAMENTARY DEBATES', ih, headspeak)
		ih = StripDebateHeading('OFFICIAL REPORT', ih, headspeak)
		ih = StripDebateHeading('IN THE .*? SESSION OF THE .*? PARLIAMENT OF THE', ih, headspeak)
		ih = StripDebateHeading('UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND', ih, headspeak, True)
		ih = StripDebateHeading('\[WHICH OPENED .*?\]', ih, headspeak, True)
		ih = StripDebateHeading('.*? YEAR OF THE REIGN OF.*?', ih, headspeak)
		ih = StripDebateHeading('HER MAJESTY QUEEN ELIZABETH II', ih, headspeak, True)
		ih = StripDebateHeading('SI.*? SERIES', ih, headspeak)
		ih = StripDebateHeading('VOLUME \d+', ih, headspeak)
		ih = StripDebateHeading('.*? VOLUME OF SESSION .*?', ih, headspeak)


	#House of Commons
	ih = StripDebateHeading('house of commons(?i)', ih, headspeak)

	# Tuesday 9 December 2003
	if not re.match('the house met at .*(?i)', headspeak[ih][0]):
		if ((sdate != mx.DateTime.DateTimeFrom(headspeak[ih][0]).date)) or headspeak[ih][2]:
			print headspeak[ih]
			raise Exception, 'non-conforming date heading '
		ih = ih + 1


	#The House met at half-past Ten o'clock
	gstarttime = re.match('the house met at (.*)(?i)', headspeak[ih][0])
	if (not gstarttime) or headspeak[ih][2]:
		print headspeak[ih]
		raise Exception, 'non-conforming "%s" heading ' % hmatch
	ih = ih + 1


	#PRAYERS
	ih = StripDebateHeading('prayers(?i)', ih, headspeak)


	# in the chair
	ih = StripDebateHeading('\[.*? in the chair\](?i)', ih, headspeak, True)


	# find the url, colnum and time stamps that occur before anything else in the unspoken text
	stampurl = StampUrl(sdate)

	# set the time from the wording 'house met at' thing.
	time = gstarttime.group(1)
	if re.match("^half-past Nine(?i)", time):
		newtime = '09:30:00'
	elif re.match("^half-past Ten(?i)", time):
		newtime = '10:30:00'
	elif re.match("^twenty-five minutes pastEleven(?i)", time):
		newtime = '11:25:00'
	elif re.match("^half-past Eleven(?i)", time):
		newtime = '11:30:00'
	elif re.match("^half-past Two(?i)", time):
		newtime = '14:30:00'
	else:
		newtime = "unknown " + time
		raise Exception, "Start time not known: " + time
	stampurl.timestamp = '<stamp time="%s"/>' % newtime

	for j in range(0, ih):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl):
		raise Exception, ' missing stamp url at beginning of file '
	return (ih, stampurl)




# Handle normal type heading
def NormalHeadingPart(sht0, stampurl):
	# This is an attempt at major heading detection.
	# This theory is utterly flawed since you can only tell the major headings
	# by context, for example, the title of the adjournment debate, which is a
	# separate entity from whatever came before, and so should not be within that
	# prior major heading.  Also, Oral questions heading is a super-major heading,
	# so doesn't fit into the scheme.

	# detect if this is a major heading and record it in the correct variable

	# set the title for this batch
	sht0 = string.strip(sht0)

	bmajorheading = False


	# Oral question are really a major heading
	if sht0 == 'Oral Answers to Questions':
		bmajorheading = True
	# Check if there are any other spellings of "Oral Answers to Questions" with a loose match
	elif re.search('oral(?i)', sht0) and re.search('ques(?i)', sht0):
		raise Exception, 'Oral question match not precise enough: %s' % sht0

	# All upper case headings
	elif not re.search('[a-z]', sht0):
		bmajorheading = True

	# Other major headings, marked by _head in their anchor tag
	elif re.search('_head', stampurl.aname):
		bmajorheading = True

	# we're not writing a block for division headings
	# write out block for headings
	qb = qspeech('nospeaker="true"', FixHTMLEntities(sht0), stampurl)
	if bmajorheading:
		qb.typ = 'major-heading'
	else:
		qb.typ = 'minor-heading'

	# headings become one unmarked paragraph of text
	qb.stext = [ qb.text ]
	return qb


# handle a division case
def DivisionParsingPart(divno, unspoketxt, stampurl, sdate):
	# find the ending of the division and split it off.
	gquesacc = re.search("(Question accordingly)", unspoketxt)
	if gquesacc:
		divtext = unspoketxt[:gquesacc.end(1)]
		unspoketxt = unspoketxt[gquesacc.start(1):]
	else:
		divtext = unspoketxt
		print "division missing question accordingly"
		unspoketxt = ''

	# Add a division object (will contain votes and motion text)
	spattr = 'nospeaker="true" divdate="%s" divnumber="%s"' % (sdate, divno)
	qbd = qspeech(spattr, divtext, stampurl)
	qbd.typ = 'division' # this type field seems easiest way

	# filtering divisions here because we may need more sophisticated detection
	# of end of division than the "Question accordingly" marker.
	qbd.stext = FilterDivision(qbd.text, sdate)

	return (unspoketxt, qbd)


# pull out the lines in the previous speech
#	<p><i>Question put,</i> That the amendment be made: &mdash; </p>
#	<p class="announce-division" ayes="145" noes="366"><i>The House divided:</i> Ayes 145, Noes 366.</p>
rehousedivmarginal = re.compile('house divided.*?ayes.*?Noes')

# these are cases where a division is a correction, so there is no text above 
# (in the database the result gets substituted)
redivshouldappear = re.compile('.*?Division .*? should appear as follows:|.*?in col.*?insert')

#<a name="40316-33_para15"><i>It being Seven o'clock,</i> Madam Deputy Speaker <i>put the Question already proposed from the Chair, pursuant to Order [5 January].</i>
regqput = ".*?question put.*?</p>"
regqputt = ".*?question, .*?, put.*?</p>"
regitbe = "(?:<[^>]*>|\s)*It being .*?o'clock(?i)"
regitbepq = "(?:<[^>]*>|\s)*It being .*? hours .*? put the question(?i)"
regitbepq1 = "(?:<[^>]*>|\s)*It being .*? (?:hour|minute).*?(?i)"
reqput = re.compile('%s|%s|%s|%s|%s(?i)' % (regqput, regqputt, regitbe, regitbepq1, regitbepq))

# this hack sets the motion text flag on a set of paragraphs
# for use by the publicwhip motion text stuff
def SubsPWtextset(stext):
	res = [ ]
	for st in stext:
		if re.search('pwmotiontext="True"', st) or not re.match('<p', st):
			res.append(st)
		else:
			res.append(re.sub('<p(.*?)>', '<p\\1 pwmotiontext="True">', st))
	return res

def GrabDivisionProced(qbp, qbd):
	if qbp.typ != 'speech' or len(qbp.stext) < 1:

		# this is that crazy correction one
		if qbp.sstampurl.sdate == '2003-12-18':
			return None

		print qbp.stext
		raise Exception, "previous to division not speech"


	hdg = rehousediv.match(qbp.stext[-1])
	if not hdg:
		hdg = redivshouldappear.match(qbp.stext[-1])
	if not hdg:
		print qbp.stext[-1]
		# another correction one
		#:  qbp.sstampurl.sdate == '2003-09-16':
		if True:
			raise Exception, "no house divided before division"
		return None

	# if previous thing is already a no-speaker, we don't need to break it out
	# (the coding on the question put is complex and multilined)
	if re.search('nospeaker="true"', qbp.speaker):
		qbp.stext = SubsPWtextset(qbp.stext)
		return None

	# look back at previous paragraphs and skim off a part of what's there
	# to make a non-spoken bit reporting on the division.
	iskim = 1
	if re.search('Serjeant at Arms|peaceful outcome', qbp.stext[-2]):
		pass
	else:
		while len(qbp.stext) >= iskim:
			if reqput.match(qbp.stext[-iskim]):
				break
			iskim += 1

		# haven't found a question put before we reach the front
		if len(qbp.stext) < iskim:
			iskim = 1
			# VALID in 99% of cases: raise Exception, "no question put before division"

	# copy the two lines into a non-speaking paragraph.
	qbdp = qspeech('nospeaker="true"', "", qbp.sstampurl)
	qbdp.typ = 'speech'
	qbdp.stext = SubsPWtextset(qbp.stext[-iskim:])


	# trim back the given one by two lines
	qbp.stext = qbp.stext[:-iskim]

	return qbdp


################
# main function
################
def FilterDebateSections(fout, text, sdate):
	# make the corrections at this level which enables the headings to be resolved.
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# split into list of triples of (heading, pre-first speech text, [ (speaker, text) ])
	headspeak = SplitHeadingsSpeakers(text)

	# break down into lists of headings and lists of speeches
	(ih, stampurl) = StripDebateHeadings(headspeak, sdate)

	# loop through each detected heading and the detected partitioning of speeches which follow.
	# this is a flat output of qspeeches, some encoding headings, and some divisions.
	# see the typ variable for the type.
	flatb = [ ]
	for i in range(ih, len(headspeak)):
		# triplet of ( heading, unspokentext, [(speaker, text)] )
		sht = headspeak[i]
		headingtxt = string.strip(sht[0])
		unspoketxt = sht[1]
		speechestxt = sht[2]

		# the heading detection, as a division or a heading speech object
		# detect division headings
		gdiv = re.match('Division No. (\d+)', headingtxt)

		# heading type
		if not gdiv:
			qbh = NormalHeadingPart(headingtxt, stampurl)

			# ram together minor headings into previous ones which have no speeches
			if qbh.typ == 'minor-heading' and len(flatb) > 0 and flatb[-1].typ == 'minor-heading':
				flatb[-1].stext.append(" &mdash; ")
				flatb[-1].stext.extend(qbh.stext)

			# otherwise put out this heading
			else:
				flatb.append(qbh)

		# division case
		else:
			(unspoketxt, qbd) = DivisionParsingPart(string.atoi(gdiv.group(1)), unspoketxt, stampurl, sdate)

			# grab some division text off the back end of the previous speech 
			# and wrap into a new no-speaker speech
			qbdp = GrabDivisionProced(flatb[-1], qbd)
			if qbdp:
				flatb.append(qbdp)
			flatb.append(qbd)

			# write out our file with the report of all divisions
			if foutdivisionreports:
				PreviewDivisionTextGuess(foutdivisionreports, flatb)

		# continue and output unaccounted for unspoken text occuring after a
		# division, or after a heading
		if (not re.match('(?:<[^>]*>|\s)*$', unspoketxt)):
			qb = qspeech('nospeaker="true"', unspoketxt, stampurl)
			qb.typ = 'speech'
			FilterDebateSpeech(qb)
			flatb.append(qb)

		# there is no text; update from stamps if there are any
		else:
			stampurl.UpdateStampUrl(unspoketxt)

		# go through each of the speeches in a block and put it into our batch of speeches
		for ss in speechestxt:
			qb = qspeech(ss[0], ss[1], stampurl)
			qb.typ = 'speech'
			FilterDebateSpeech(qb)
			flatb.append(qb)


	# we now have everything flattened out in a series of speeches

	# output the list of entities
	WriteXMLFile(fout, flatb, sdate)



