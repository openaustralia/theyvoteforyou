import sys
import re

# this filter finds the speakers and replaces with full itendifiers
# <speaker name="Eric Martlew  (Carlisle)"/>

# in and out files for this filter
filein = "f3hocdaydebate2000-11-07.htm"
fileout = "f4hocdaydebate2000-11-07.htm"

# <B> Mr. Eric Martlew  (Carlisle):</B>
# <B> Mr. Grieve: </B>
lspeakerregexp = '(<b>.*?</b>):?(?i)'
speakerregexp = '<b>\s*([^:]*?):?\s*</b>(?i)'


fin = open(filein);
fr = fin.read()
fs = re.split(lspeakerregexp, fr)
fin.close()

fout = open(fileout, "w");

# the map which will expand the names from the common abbreviations
nameexp = {  }

for fss in fs:
	if not fss:
		continue
	speakergroup = re.match(speakerregexp, fss)
	if not speakergroup:
		fout.write(fss)
		continue

	# we have a string in bold
	boldnamestring = speakergroup.group(1)

	# discard divisions from consideration
	if (re.search('Division', boldnamestring)):
		fout.write(fss)
		continue

	# full name type : Mr. Eric Martlew  (Carlisle)
	# oofficial name type: The Secretary of State for Foreign and Commonwealth Affairs   (Mr. Robin Cook)
	bracketgroup = re.match('(.*?)\s*[(](.*?)[)].*?', boldnamestring)
	if bracketgroup:
		# first determin which of side is the name
		if re.search('president|minister|secretary(?i)', bracketgroup.group(1)):
			realname = bracketgroup.group(2)
		else:
			realname = bracketgroup.group(1) # the other is the constituency

		# take out the dots
		realname = re.sub('[.]', '', realname)

		# add in realname and its abbreviations
		if not nameexp.has_key(realname):
			nameexp[realname] = boldnamestring
			realnamegroup = re.match('(Mr|Mrs|Ms|Sir|Dr)\s+(\w+?)\s+(.+?)$', realname)
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

	print boldnamestring
	fout.write('<speaker name="%s">\n' % boldnamestring)


fout.close()

