#! /usr/bin/python2.3

import sys
import re
import os
import string

# this filter finds the speakers and replaces with full itendifiers
# <speaker name="Eric Martlew  (Carlisle)"><p>Eric Martlew  (Carlisle)</p></speaker>

# in and out files for this filter
dirin = "c2daydebatefixcolumnnumbers"
dirout = "c3daydebatematchspeakers"
dtemp = "gdaydebtemp.htm"


# <B> Mr. Eric Martlew  (Carlisle):</B>
# <B> Mr. Grieve: </B>
lspeakerregexp = '(<b>.*?</b>\s*?:|<b>.*?</b>)(?i)'
speakerregexp = '<b>\s*([^:]*?):?\s*</b>(?i)'

#print re.findall(lspeakerregexp, '<b> hi there </b> \n: dkdk')
#sys.exit()

# scan through directory
fdirin = os.listdir(dirin)

for fin in fdirin:
	jfin = os.path.join(dirin, fin)
	jfout = os.path.join(dirout, fin)
	if os.path.isfile(jfout):
		print "skipping " + fin
		continue

	print fin
	fin = open(jfin);
	fr = fin.read()
	fin.close()

	tempfile = open(dtemp, "w")

	# setup for scanning through the file.
	# we should have a name matching module which gets the unique ids, and
	# takes the full speaker name and date to find a match.
	fs = re.split(lspeakerregexp, fr)

	# hard code one value
	nameexp = { 'The Prime Minister':'Mr. Tony Blair ((The Prime Minister))'}

	# the map which will expand the names from the common abbreviations
	for fss in fs:
		if not fss:
			continue
		speakergroup = re.findall(speakerregexp, fss)
		if len(speakergroup) == 0:
			tempfile.write(fss)
			continue

		# we have a string in bold
		boldnamestring = speakergroup[0]

		# discard divisions from consideration
		if (re.search('Division', boldnamestring)):
			tempfile.write(fss)
			continue

		# full name type : Mr. Eric Martlew  (Carlisle)
		# official name type: The Secretary of State for Foreign and Commonwealth Affairs   (Mr. Robin Cook)
		bracketgroup = re.match('(.*?)\s*[(](.*?)[)].*?', boldnamestring)
		if bracketgroup:
			# first determin which of side is the name
			if re.search('president|minister|secretary|chancellor|leader|general(?i)', bracketgroup.group(1)):
				realname = bracketgroup.group(2)
				# rearrange the name so that the title is in place of constituency in more brackets
				office = bracketgroup.group(1)
				boldnamestring = '%s ((%s))' % (realname, office)

				# let the office refer to the person as well
				# only seen with Prime Minister, which is now hardcoded
				#if not nameexp.has_key(office):
				#	nameexp[office] = boldnamestring
			else:
				realname = bracketgroup.group(1) # the other is the constituency

			# take out the dots
			realname = re.sub('[.]', '', realname)

			# add in realname and its abbreviations into the mapping
			if not nameexp.has_key(realname):
				nameexp[realname] = boldnamestring
				realnamegroup = re.match('(Mr|Mrs|Miss|Ms|Sir|Dr)\s+(\w+?)\s+(.+?)$', realname)
				if realnamegroup:
					shortrealname = realnamegroup.group(1) + ' ' + realnamegroup.group(3)
					if nameexp.has_key(shortrealname):
						print "*** short realname ambiguous " + shortrealname + "  " + nameexp[shortrealname] + boldnamestring
						nameexp[shortrealname] = "ambiguous"
					else:
						nameexp[shortrealname] = boldnamestring


		else:
			shortname = re.sub('[.]', '', boldnamestring)
			if re.search('hon member(?i)', shortname):
				boldnamestring = shortname
			elif re.search('mr speaker(?i)', shortname):
				boldnamestring = shortname

			elif nameexp.has_key(shortname):
				boldnamestring = nameexp[shortname]
			else:
				boldnamestring = 'ambiguous'
				print "long name not found for " + shortname

			if boldnamestring == 'ambiguous':
				boldnamestring = shortname

		# now output what we've decided
		#print boldnamestring
		tempfile.write('<p><speaker name="%s"><font color="#003fcf">%s</font></speaker></p>\n' % (boldnamestring, boldnamestring))

	tempfile.close()
	os.rename(dtemp, jfout)

