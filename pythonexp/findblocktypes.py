import sys
import re

# this filter finds the speakers and replaces with full itendifiers
# <speaker name="Eric Martlew  (Carlisle)"/>

# in and out files for this filter
filein = "f4hocdaydebate2000-11-07.htm"
fileout = "f5hocdaydebate2000-11-07.htm"

# <H4><center>Iraq</center></H4>
ltitleregexp = '(<h\d><center>.*?</center></h\d>)(?i)'
titleregexp = '<h\d><center>(.*?)</center></h\d>(?i)'


fin = open(filein);
fr = fin.read()
fs = re.split(ltitleregexp, fr)
fin.close()

fout = open(fileout, "w");

# the map which will expand the names from the common abbreviations

bOralQuestions = 0
questiontitle = ''

for fss in fs:
	if not fss:
		continue
	titlegroup = re.match(titleregexp, fss)
	if not titlegroup:
		if bOralQuestions:
			numbergroup = re.search('[^.]*?(\d+)[.]', fss)
			if numbergroup:
				print " question number " + numbergroup.group(1)
			fout.write(fss)
		continue
	title = titlegroup.group(1)

	if re.search('oral.*?questions(?i)', title):
		if bOralQuestions:
			print " *** error more than one oral questions "
		bOralQuestions = 1
	elif re.search('points.*?order(?i)', title):
		bOralQuestions = 0
	elif bOralQuestions:
		questiontitle = titlegroup.group(1)
	#print titlegroup.group(1)


fout.close()

