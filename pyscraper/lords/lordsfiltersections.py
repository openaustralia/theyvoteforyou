#! /usr/bin/python2.3
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

from filterdivision import FilterDivision
from lordsfilterdivisions import LordsFilterDivision
from lordsfilterdivisions import LordsDivisionParsingPart
from filterdebatespeech import FilterDebateSpeech

from contextexception import ContextException

# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = 	[
				( '<UL><UL><UL>(?i)', '<UL>', -1, 'all'),
				( '</UL></UL></UL>(?i)', '</UL>', -1, 'all'),
		]


def StripDebateHeading(hmatch, ih, headspeak, bopt=False):
	if (not re.match(hmatch, headspeak[ih][0])) or headspeak[ih][2]:
		if bopt:
			return ih
		print headspeak[ih]
		raise Exception, 'non-conforming "%s" heading ' % hmatch
	return ih + 1

def StripLordsDebateHeadings(headspeak, sdate):
	# check and strip the first two headings in as much as they are there
	ih = 0
	ih = StripDebateHeading('Initial', ih, headspeak)


	# House of Lords
	ih = StripDebateHeading('house of lords(?i)', ih, headspeak, True)

	# Thursday, 18th December 2003.
	if not re.match('the house met at .*(?i)', headspeak[ih][0]):
		if ((sdate != mx.DateTime.DateTimeFrom(headspeak[ih][0]).date)) or headspeak[ih][2]:
			print headspeak[ih]
			raise Exception, 'non-conforming date heading '
		ih = ih + 1


	if re.match("THE QUEEN'S SPEECH", headspeak[ih][0]):
		print headspeak[ih][0]
		print "*******  skipping entirely **********"
		return (None, None)

	# The House met at eleven of the clock (Prayers having been read earlier at the Judicial Sitting by the Lord Bishop of St Albans): The CHAIRMAN OF COMMITTEES on the Woolsack.
	gstarttime = re.match('(?:reassembling.*?recess, )?the house met at (.*)(?i)', headspeak[ih][0])
	if (not gstarttime) or headspeak[ih][2]:
		print headspeak[ih]
		raise Exception, 'non-conforming "%s" heading ' % hmatch
	ih = ih + 1


	# Prayers&#151;Read by the Lord Bishop of Southwell.
	ih = StripDebateHeading('prayers(?i)', ih, headspeak, True)



	# find the url, colnum and time stamps that occur before anything else in the unspoken text
	stampurl = StampUrl(sdate)

	# set the time from the wording 'house met at' thing.
	for j in range(0, ih):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl):
		raise Exception, ' missing stamp url at beginning of file '
	return (ih, stampurl)



# Handle normal type heading
def LordsHeadingPart(headingtxt, stampurl):
	bmajorheading = False

	headingtxtfx = FixHTMLEntities(headingtxt)
	qb = qspeech('nospeaker="true"', headingtxtfx, stampurl)
	if bmajorheading:
		qb.typ = 'major-heading'
	else:
		qb.typ = 'minor-heading'

	# headings become one unmarked paragraph of text
	qb.stext = [ headingtxtfx ]
	return qb


# this function is taken from debdivisionsections
def SubsPWtextset(stext):
	res = [ ]
	for st in stext:
		if re.search('pwmotiontext="yes"', st) or not re.match('<p', st):
			res.append(st)
		else:
			res.append(re.sub('<p(.*?)>', '<p\\1 pwmotiontext="yes">', st))
	return res

#	<p>On Question, Whether the said amendment (No. 2) shall be agreed to?</p>
#reqput = re.compile('%s|%s|%s|%s|%s(?i)' % (regqput, regqputt, regitbe, regitbepq1, regitbepq))
resaidamend =  re.compile("<p[^>]*>On Question, (?:[Ww]hether|That) (?:the said amendment|the amendment|the House|Clause|Amendment|the Bill|the said [Mm]otion|Lord|the manuscript|the Motion)")

#	<p>On Question, Whether the said amendment (No. 2) shall be agreed to?</p>
#	<p>Their Lordships divided: Contents, 133; Not-Contents, 118.</p>
#housedivtxt = "The (?:House|Committee) (?:(?:having )?divided|proceeded to a Division)"
relorddiv = re.compile('<p[^>]*>(?:\*\s*)?Their Lordships divided: Contents,? (\d+); Not-Contents, (\d+)\.</p>$')
def GrabLordDivisionProced(qbp, qbd):
	if not re.match("speech|motion", qbp.typ) or len(qbp.stext) < 1:
		print qbp.stext
		raise Exception, "previous to division not speech"

	hdg = relorddiv.match(qbp.stext[-1])
	if not hdg:
		print qbp.stext[-1]
		raise ContextException("no lordships divided before division", stamp=qbp.sstampurl)

	# if previous thing is already a no-speaker, we don't need to break it out
	# (the coding on the question put is complex and multilined)
	if re.search('nospeaker="true"', qbp.speaker):
		qbp.stext = SubsPWtextset(qbp.stext)
		return None

	# look back at previous paragraphs and skim off a part of what's there
	# to make a non-spoken bit reporting on the division.
	iskim = 1
	if not resaidamend.match(qbp.stext[-2]):
		print qbp.stext[-2]
		raise ContextException("no on said amendment", stamp=qbp.sstampurl, fragment=qbp.stext[-2])
	iskim = 2

	# copy the two lines into a non-speaking paragraph.
	qbdp = qspeech('nospeaker="true"', "", qbp.sstampurl)
	qbdp.typ = 'speech'
	qbdp.stext = SubsPWtextset(qbp.stext[-iskim:])

	# trim back the given one by two lines
	qbp.stext = qbp.stext[:-iskim]

	return qbdp

# separate out the making of motions and my lords speeches
def FilterLordsSpeech(qb):
	recol = re.search('colon="(:?)"', qb.speaker)
	if not recol: # no match cases
		return None

	# no colon, must be making a motion
	if recol.group(1):
		if re.search("<p>moved (?i)", qb.stext[0]):
			print qb.speaker
			print qb.stext[0]
			raise ContextException("has moved amendment after colon", stamp=qb.sstampurl)
		return None

	# just a question
	if re.match("<p>asked Her Majesty's Government|<p>rose to (?:ask|call|draw attention|consider)|<p>asked the|<p>&mdash;Took the Oath", qb.stext[0]):
		return None

	# identify a moved amendment
	if not re.match("<p>moved,? |<p>Amendments? |<p>had given notice|<p>rose to move", qb.stext[0]):
		print qb.stext
		print "no moved amendment"
		raise ContextException("missing moved amendment", stamp=qb.sstampurl)
		return None

	# separate out when he starts to speak about his motion
	nstext = [ ]
	for i in range(len(qb.stext)):
		rens = re.match("(<p>The noble \S* said:\s*)", qb.stext[i])
		if rens:
			nstext = [ "<p>" +  qb.stext[i][rens.end(1):] ]
			nstext.extend(qb.stext[i+1:])
			qb.stext = qb.stext[:i]
			break
	assert i > 0
	qb.stext = SubsPWtextset(qb.stext)
	qb.typ = 'motion'

	if not nstext:
		return None

	# build the speech part
	qbres = qspeech(string.replace(qb.speaker, 'colon=""', 'colon=":"'), "", qb.sstampurl)
	qbres.typ = 'speech'
	qbres.stext = nstext
	return qbres



################
# main function
################
def LordsFilterSections(text, sdate):
	# make the corrections at this level which enables the headings to be resolved.
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# split into list of triples of (heading, pre-first speech text, [ (speaker, text) ])
	headspeak = SplitHeadingsSpeakers(text)


	# break down into lists of headings and lists of speeches
	(ih, stampurl) = StripLordsDebateHeadings(headspeak, sdate)
	if ih == None:
		return

	# loop through each detected heading and the detected partitioning of speeches which follow.
	# this is a flat output of qspeeches, some encoding headings, and some divisions.
	# see the typ variable for the type.
	flatb = [ ]

	for sht in headspeak[ih:]:
		# triplet of ( heading, unspokentext, [(speaker, text)] )
		headingtxt = string.strip(sht[0])
		unspoketxt = sht[1]
		speechestxt = sht[2]

		# the heading detection, as a division or a heading speech object
		# detect division headings
		gdiv = re.match('Division No. (\d+)', headingtxt)

		# heading type
		if not gdiv:
			qbh = LordsHeadingPart(headingtxt, stampurl)
			flatb.append(qbh)

		# division type
		else:
			(unspoketxt, qbd) = LordsDivisionParsingPart(string.atoi(gdiv.group(1)), unspoketxt, stampurl, sdate)

			# grab some division text off the back end of the previous speech
			# and wrap into a new no-speaker speech
			qbdp = GrabLordDivisionProced(flatb[-1], qbd)
			if qbdp:
				flatb.append(qbdp)
			flatb.append(qbd)

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
			qbsep = FilterLordsSpeech(qb)
			flatb.append(qb)
			if qbsep:
				flatb.append(qbsep)


	# we now have everything flattened out in a series of speeches
	return flatb


