#! /usr/bin/python2.3

import sys
import re
import os
import string

# this will return a list of triples (number, title, stext)
# where stext = [ (speaker, text) ]
# SepSectionsSpeeches(fr)


lsectionregexp = '(<h\d><center>.*?</center></h\d>|<h\d align=center>.*?</h\d>|<center>.*?</center>)(?i)'
sectionregexp1 = '<center>(.*?)</center>(?i)'
sectionregexp2 = '<h\d align=center>(.*?)</h\d>(?i)'


# build into speaker pairs
# <speaker name="Mrs. Gwyneth Dunwoody  (Crewe and Nantwich)"><font color="#003fcf">Mrs. Gwyneth Dunwoody  (Crewe and Nantwich)</font></speaker>


def splitintospeakerpairs(fr):
	pss = []  # result
	fs = re.split('(<speaker .*?>.*?</speaker>)', fr)
	speaker = 'Initial'
	for fss in fs:
		speakergroup = re.findall('<speaker name="(.*?)">.*?</speaker>', fss)
		if len(speakergroup) == 0:
			if speaker:
				if speaker == 'Initial':
					# the last one is numbers on oral questions
					cspeech = re.sub('\s|<[^>]*>|\d+[.]', '', fss)
					if len(cspeech) == 0:
						speaker = 'NoneInitial'
				if speaker != 'NoneInitial':
					pss.append( (speaker, fss ) )
			else:
				print " no speaker for text"
			speaker = None

		else:
			if speaker and (speaker != 'Initial'):
				print " no text for speaker " + speaker
			speaker = speakergroup[0]
	if speaker and (speaker != 'Initial'):
		print " no text for speaker at end " + speaker
	return pss


def SepSectionsSpeeches(fr):
	# build into pairs bloocked by title
	fs = re.split(lsectionregexp, fr)
	pfs = []  # result
	heading = "Initial"
	for i in range(len(fs)):
		sectiongroup = re.findall(sectionregexp1, fs[i])
		if len(sectiongroup) == 0:
			sectiongroup = re.findall(sectionregexp2, fs[i])
			if len(sectiongroup) == 0:
				if not heading:
					print " no heading for text"
					heading = ''
				speechlist = splitintospeakerpairs(fs[i])
				if (heading != "Initial") or (len(speechlist) != 0):
					pfs.append( (len(pfs), heading, speechlist ) )
				heading = None
				continue

		if heading:
			pfs.append( (len(pfs), heading, [] ) )
		heading = sectiongroup[0]
	if heading:
		pfs.append( (len(pfs) , heading, [] ) )

	return pfs


