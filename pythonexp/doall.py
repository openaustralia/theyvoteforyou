#! /usr/bin/python2.3

import sys
import re
import os
import string

from findallhocdaydebate import FindAllHocDayDebate
from gluehocdaydebate import GlueHocDayDebate
from removelinebreaks import RemoveLineChars

from fixdebatecolumnnumbers import FixColumnNumbers
from fixspeakernames import SpeakerNames
from foldsections import Folding

from fixwranscolumnnumbers import FixWransColumnNumbers
from fixwransspeakernames import WransSpeakerNames
from wranssections import WransSections

dtemp = "daydebtemp.htm"
def ScanDirectories(func, dirout, dirin):
	if not os.path.isdir(dirout):
		os.mkdir(dirout)
	fdirin = os.listdir(dirin)
	for fin in fdirin:
		sdate = re.findall('\d{4}-\d{2}-\d{2}', fin)[0]
		jfin = os.path.join(dirin, fin)
		jfout = os.path.join(dirout, fin)
		if not os.path.isfile(jfout):
			ofin = open(jfin)
			finr = ofin.read()
			ofin.close()

			print fin
			tempfile = open(dtemp, "w")
			apply(func, (tempfile, finr, sdate))
			tempfile.close()
			os.rename(dtemp, jfout)





# file names and directories
urlindex = "http://www.publications.parliament.uk/pa/cm/cmhansrd.htm"
hocdaydebatelist = "hocdaydebatelist.xml"

# daily debates directories
dirglueddaydebates = 'glueddaydebates'
dirremovechars = 'c1daydebateremovechars'
dircolumnnumbers = 'c2daydebatefixcolumnnumbers'
dirspeakers = 'c3daydebatematchspeakers'
dirfolding = 'c4folding'

# written answers directories
dirgluedwranswers = 'gluedwranswers'
dirwaremovechars = 'c1wransremovechars'
dirwacolumnnumbers = 'c2wransfixcolumnnumbers'
dirwaspeakers = 'c3wransmatchspeakers'
dirwrans = 'c4wrans'



# discover the index of all the pages
if not os.path.isfile(hocdaydebatelist):
	daydebates = open(hocdaydebatelist, "w");
	FindAllHocDayDebate(daydebates, urlindex)
	daydebates.close()

# grab all the days we can
# (comment the function call out line out if you want it to run past)
GlueHocDayDebate(dirgluedwranswers, hocdaydebatelist, 'answers', 'answers')

print dirwaremovechars
ScanDirectories(RemoveLineChars, dirwaremovechars, dirgluedwranswers)
print dirwacolumnnumbers
#ScanDirectories(FixWransColumnNumbers, dirwacolumnnumbers, dirwaremovechars)
print dirwaspeakers
#ScanDirectories(WransSpeakerNames, dirwaspeakers, dirwacolumnnumbers)
print dirwrans
ScanDirectories(WransSections, dirwrans, dirwaspeakers)
sys.exit()


# grab all the days we can
# (comment the function call out line out if you want it to run past)
#GlueHocDayDebate(dirglueddaydebates, hocdaydebatelist, 'debate', 'daydeb')


# remove chars and comments
# filters files to c1daydebateremovechars/ without their comments,
ScanDirectories(RemoveLineChars, dirremovechars, dirglueddaydebates)

# converts columns and times into xml stamps
ScanDirectories(FixColumnNumbers, dircolumnnumbers, dirremovechars)

# tracks down all announced speaker names
ScanDirectories(SpeakerNames, dirspeakers, dircolumnnumbers)

# trying to separate out the different bits according to title and content.
ScanDirectories(Folding, dirfolding, dirspeakers)
