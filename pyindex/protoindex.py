#! /usr/bin/python2.3

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

tempfile = os.path.join(toppath, "filtertemp")


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
	if fwrans < 'answers2003-08':
		break
	print ' -- ' + fwrans
	wr = wransxmlscan(os.path.join(pwxmwrans, fwrans))

# go through all the files, re-open and sort them
for k in unsortindfile.keys():
	fname = unsortindfile[k].name
	unsortindfile[k].close()

	fin = open(fname, "r")
	wlines = fin.readlines()
	fin.close()

	wlines.sort()

	# now make the outputs, removing repeats
	fout = open(fname, "w")
	word = ''
	for wl in wlines:
		itab = string.index(wl, '\t')
		lword = wl[:itab]
		wrid = wl[itab+1:len(wl)-1]	# lose the linefeed.
		if word != lword:
			if word:
				fout.write('\n')
			word = lword
			fout.write(word)
			fout.write('\t')
			fout.write(wrid)
		else:
			fout.write(' ')
			fout.write(wrid)
	if word:
		fout.write('\n')
	fout.close()


