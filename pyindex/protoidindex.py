#! /usr/bin/python2.3

# this makes the list of files which will dereference the ids and column numbers into lseek values

import sys
import re
import os
import string
import cStringIO
import xml.sax


toppath = os.path.expanduser('~/pwdata')

# master function which carries the glued pages into the xml filtered pages

# in/output directories
pwprotoidxdir = os.path.join(toppath, "protoidx")

pwxmldirs = os.path.join(toppath, "scrapedxml")
pwxmwrans = os.path.join(pwxmldirs, "wrans")



###############
# main function

# clear the directory
if not os.path.isdir(pwprotoidxdir):
	os.mkdir(pwprotoidxdir)
for fn in os.listdir(pwprotoidxdir):
	os.remove(os.path.join(pwprotoidxdir, fn))

# loop through the files and append them in
fwransxmlall = os.listdir(pwxmwrans)
fwransxmlall = filter(lambda f: re.search("\.xml$", f) , fwransxmlall)
fwransxmlall.sort()
fwransxmlall.reverse()
for fwrans in fwransxmlall:
#	if fwrans < 'answers2003-08':
#		break
#	print ' -- ' + fwrans


	fnamex = re.sub('\.xml', '-ind.txt', fwrans)
	fxml = open(os.path.join(pwxmwrans, fwrans), "r")
	fnamex = os.path.join(pwprotoidxdir, fnamex)
	fout = open(fnamex, "w")

	nlse = 0
	firstcolno = -1
	colno = -1

	while 1:
		line = fxml.readline()
		if not line:
			break
		gind = re.match('<wrans id="uk.org.publicwhip/wrans/(.*?\.(\d+)W)\.\d+"', line)
		if gind:
			ncolno = string.atoi(gind.group(2))
			if ncolno != colno:
				if colno == -1:
					colno = ncolno - 1
					firstcolno = colno
				elif ncolno < colno:
					raise Exception, ' colnumbers descending '
				while colno < ncolno:
					colno = colno + 1
					fout.write('%9d %9d\n' % (colno, nlse))
		nlse = nlse + len(line)
	fout.write('%9d %9d\n' % (colno + 1, nlse))

	fxml.close()
	fout.close()
	if os.stat(fnamex)[6] != (colno - firstcolno + 1) * 20:
		raise Exception, ' programming adding up error '


