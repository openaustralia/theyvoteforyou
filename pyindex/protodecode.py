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
pwprotoindexdir = os.path.join(toppath, "protoindex")

pwxmldirs = os.path.join(toppath, "scrapedxml")
pwxmwrans = os.path.join(pwxmldirs, "wrans")


def ReadNumberPair(fin):
	ln = os.read(fin, 20)
	lng = re.match('\s*(\d+)\s*(\d+)\n$', ln)
	if not lng:
		print ln
		raise Exception, ' does not match pair of numbers '
	return (string.atoi(lng.group(1)), string.atoi(lng.group(2)))


def FetchWrans(wrid):
	# extract the filenames and the column number
	gcolid = re.match('uk.org.publicwhip/wrans/(.*?)\.(\d+)W(?:\.(\d+))?', wrid)

	fname = 'answers%s.xml' % gcolid.group(1)
	fname = os.path.join(pwxmwrans, fname)

	fninx = 'answers%s-ind.txt' % gcolid.group(1)
	fninx = os.path.join(pwprotoidxdir, fninx)

	colnum = string.atoi(gcolid.group(2))

	# get the first line of the index to find the column number
	finx = os.open(fninx, os.O_RDONLY)
	(lcolnum, lse) = ReadNumberPair(finx)

	# seek to correct column number
	if colnum > lcolnum:
		os.lseek(finx, (colnum - lcolnum) * 20, 0)
		(lcolnum, lse) = ReadNumberPair(finx)
	if lcolnum != colnum:
		raise Exception, ' colnum mismatch '

	# length of string we will read out
	lgth = ReadNumberPair(finx)[1] - lse
	os.close(finx)

	# open, seek and snip out the string with the column of answers
	fwrin = os.open(fname, os.O_RDONLY)
	os.lseek(fwrin, lse, 0)
	print lse, lgth
	wranscol = os.read(fwrin, lgth)
	os.close(fwrin)

	# we have the column.  bail out if we don't need the question
	if not gcolid.group(3):
		return wranscol

	regsq = '<wrans id="%s"[\s\S]*?</wrans>' % wrid
	wrg = re.search(regsq, wranscol)
	if not wrg:
		raise Exception, ' no matching question! '
	return wrg.group(0)


def DecodeWord(ww):
	# find the two-letter named file
	lww = string.lower(ww)
	fname = os.path.join(pwprotoindexdir, lww[0:2] + '.txt')
	if not os.path.isfile(fname):
		return [ ]

	# open and get the header information
	finw = os.open(fname, os.O_RDONLY)
	head = os.read(finw, 20)
	headn = re.findall('\d+', head)
	nwords = string.atoi(headn[0])
	wlsz = string.atoi(headn[1])

	# read in the string of words and their indexes
	# (we could search this string with a binary chop)
	wl = os.read(finw, wlsz + nwords * 10)

	# search by regular expression for index and given word
	regww = '(\\d+) %s\n' % lww
	maww = re.search(regww, wl)
	res = [ ]
	if maww:
		# go to the correct location in the column of numbers of that index,
		# and pull it and the subsequent lseek values out
		ind = string.atoi(maww.group(1))
		os.lseek(finw, 20 + wlsz + nwords * 10 + ind * 10, 0)
		rg = os.read(finw, 20)

		# fetch the string between the range, which will be our list of indexes
		rgn = re.findall('\d+', rg)
		rglo = string.atoi(rgn[0])
		rghi = string.atoi(rgn[1])
		os.lseek(finw, rglo, 0)

		sinx = os.read(finw, rghi - rglo)
		for sin in re.findall('\S+', sinx):
			res.append(re.sub('[qrt]:', 'uk.org.publicwhip/wrans/', sin))

	os.close(finw)
	return res


# main calling function which demonstrates the searching
word = '1028member'
indl = DecodeWord(word)
print indl
for wrid in indl:
	print FetchWrans(wrid)

