#! /usr/bin/python2.3

# this makes the list of indexes for the different words, and will have a quick decoding.

import sys
import re
import os
import string
import cStringIO
import xml.sax


toppath = os.path.expanduser('~/pwdata')

# master function which carries the glued pages into the xml filtered pages

# in/output directories
pwprotoindexdir = os.path.join(toppath, "pwprotoindex")

pwxmldirs = os.path.join(toppath, "pwscrapedxml")
pwxmwrans = os.path.join(pwxmldirs, "wrans")


# gives prefixes and file handles
unsortindfile = { }


# the parsing of a particular file
class wransxmlscan(xml.sax.handler.ContentHandler):

	def ChunkWords(self, wstring, typ):
		for ww in re.findall('[A-Za-z]+', wstring):
			if len(ww) >= 3:
				lww = string.lower(ww)
				if (lww == 'the') or (lww == 'and'):
					continue
				self.IndexWord(lww, typ)
	
	def IndexWord(self, lww, typ):
		fout = unsortindfile.get(lww[0:2], None)
		if not fout:
			fname = os.path.join(pwprotoindexdir, lww[0:2] + '.txt')
			print fname
			fout = open(fname, "w")
			unsortindfile[lww[0:2]] = fout
		fout.write(lww)
		fout.write('\t')
		fout.write(typ)
		fout.write(self.wrid)
		fout.write('\n')


	def __init__(self, fname):
		self.binspeech = ''
		self.binpara = 0
		self.bintable = 0
		self.tagdepth = 0
		self.tagdepighigher = 0


		parser = xml.sax.make_parser()
		parser.setContentHandler(self)
		parser.parse(fname)


	def startElement(self, name, attr):

		self.tagdepighigher = self.tagdepth

		if name == 'wrans':
			self.wrid = re.sub('^uk.org.publicwhip/wrans/', '', attr['id'])
			self.ChunkWords(attr['title'], 't:')

		elif name == 'speech':
			self.binspeech = 'q:'
			if attr['type'] == 'reply':
				self.binspeech = 'r:'
			mpnum = re.sub('^uk.org.publicwhip/member/', '', attr['speakerid'])
			self.IndexWord(mpnum + 'member', self.binspeech)
				
		elif name == 'p':
			self.binpara = 1
			self.tagdepighigher = self.tagdepth + 1

		# acceptable tags
		elif name == 'i':
			self.tagdepighigher = self.tagdepth + 1

		self.tagdepth = self.tagdepth + 1


	def endElement(self, name):
		self.tagdepth = self.tagdepth - 1

		if name == 'p':
			self.binpara = 0

	def characters(self, text):
		if self.binpara and (self.tagdepth <= self.tagdepighigher):
			self.ChunkWords(text, self.binspeech)

###############
# main function

# clear the directory
if not os.path.isdir(pwprotoindexdir):
	os.mkdir(pwprotoindexdir)
for fn in os.listdir(pwprotoindexdir):
	os.remove(os.path.join(pwprotoindexdir, fn))

# loop through the files and append them in
fwransxmlall = os.listdir(pwxmwrans)
fwransxmlall.sort()
fwransxmlall.reverse()
for fwrans in fwransxmlall:
#	if fwrans < 'answers2003-08':
#		break
	print ' -- ' + fwrans
	wr = wransxmlscan(os.path.join(pwxmwrans, fwrans))


# go through all the files we've made; close, re-open and sort them
for k in unsortindfile.keys():
	fname = unsortindfile[k].name
	unsortindfile[k].close()

	# re-open
	fin = open(fname, "r")
	wlines = fin.readlines()
	fin.close()

	wlines.sort()

	# now make list of pairs: (words, lists of links)
	liwordlinks = [ ]

	word = ''
	liwlink = [ ]
	lillink = ''
	nwordc = 0

	for wl in wlines:
		itab = string.index(wl, '\t')
		lword = wl[:itab]
		wrid = wl[itab+1:len(wl)-1]	# lose the linefeed
		if word != lword:
			if word:
				liwordlinks.append( (word, liwlink) )
			liwlink = [ ]
			lillink = ''
			word = lword
			nwordc = nwordc + len(word)	# only need to do for new words
		if wrid != lillink:
			liwlink.append(wrid)
			lillink = wrid
	if word:
		liwordlinks.append( (word, liwlink) )


	# now make the outputs, removing repeats
	fout = open(fname, "w")

	# the numbers which will set the size of the file (20 bytes)
	fout.write('%9d %9d\n' % (len(liwordlinks), nwordc))

	# write out the words (we could number them so it's possible to binary search this list)
	for i in range(len(liwordlinks)):
		fout.write('%8d %s\n' % (i, liwordlinks[i][0]))

	# write out the lseek offsets (fixed fields)
	lseo = 20 + nwordc + (10 * len(liwordlinks)) + (len(liwordlinks) + 1) * 10
	for liw in liwordlinks:
		fout.write('%9d\n' % lseo)
		for lw in liw[1]:
			lseo = lseo + len(lw) + 1
	fout.write('%9d\n' % lseo)

	# write out the links on each line
	for liw in liwordlinks:
		fout.write(liw[1][0])
		for lw in liw[1][1:]:
			fout.write(' ')
			fout.write(lw)
		fout.write('\n')

	fout.close()
	if os.stat(fname)[6] != lseo:
		raise Exception, ' programming adding up error '

