#! /usr/bin/python2.3

import sys
import re
import os
import string
import StringIO

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

toaskregexp = '^((?:<[^>]*>|\s)*)' +\
		'to ask the (secretary of state for (?:' +\
				'defence|' +\
				'northern ireland|' +\
				'education and employment|' +\
				'education and skills|' +\
				'health|' +\
				'trade and industry|' +\
				'social security|' +\
				'the home department|' +\
				'scotland|' +\
				'wales|' +\
				'culture, media and sport|' +\
				'the environment, transport and the regions|' +\
				'transport, local government and the regions|' +\
				'international development|' +\
				'foreign and commonwealth affairs|' +\
				'environment, food and rural affairs|' +\
				'transport|' +\
				'works? and pensions)|' +\
							\
				'chairman of the (?:' +\
				'accommodation and works committee|' +\
				'catering committee|' +\
				'public accounts committee|' +\
				'administration committee)' +\
							\
				'secretary of wales|' +\
				'leader of the house|' +\
				'minister of state, department for international development|' +\
				'secretary of state, department for international development|' +\
				'minister of state for international development|' +\
				'minister of agriculture, fisheries and food|' +\
				'minister for the cabinet office|' +\
				'minister for women|' +\
				'prime minister|' +\
				'(?:office of the )?deputy prime minister|' +\
				'parliamentary secretary, department for constitutional affairs|' +\
				'parliamentary secretary|' +\
				'chancellor of the exchequer|' +\
				'president of the council|' +\
				'solicitor[-\s]general|' +\
				'advocate[-\s]general' +\
				')([\s\S]*)$(?i)'

retoask = re.compile(toaskregexp)

alphabet = '0abcdefghijklmnopqrstuvwxyz'

class quesstruc:

	def extractqnumsections(self):
		lnumlist = []
		if re.search('\(1\)[\s\S]*?\(2\)', self.text):
			numsec = re.split('(\(\d+\))', self.text)
			inum = 0
			for ns in numsec:
				nfa = re.findall('\((\d+)\)', ns)
				if len(nfa) != 0:
					if inum == 0:
						lnumlist.append('')
						inum = 1
					linum = string.atoi(nfa[0])
					if linum != inum:
						print 'non-consecutive numbering'
				else:
					lnumlist.append(ns)
					inum = inum + 1
		else:
			lnumlist.append(self.text)

		# now do the letter lists and put into numlist
		self.numlist = []
		for i in range(len(lnumlist)):
			letlist = []
			if re.search('<i>\(a\)</i>[\s\S]*?<i>\(b\)</i>(?i)', lnumlist[i]):
				letsec = re.split('(<i>\([a-z]\)</i>)(?i)', lnumlist[i])
				ilet = 0
				for ls in letsec:
					lfa = re.findall('<i>\(([a-z])\)</i>(?i)', ls)
					if len(lfa) != 0:
						if ilet == 0:
							letlist.append(('0', ''))
							ilet = 1
						lilet = string.find(alphabet, lfa[0]) # don't know ascii
						if lilet != ilet:
							print 'non-consecutive lettering ' + lfa[0]
							print lilet
					else:
						letlist.append(ls)
						ilet = ilet + 1
			else:
				letlist.append(lnumlist[i])


			# remove <ul> and <p> garbage from ends of the sections
			nletlist = []
			for ll in letlist:
				nfj = re.findall('^(?:</?p>|</?ul>|\s)*([\s\S]*?)(?:</?p>|</?ul>|\s)*$(?i)', ll)
				si = re.sub('<qcode [^>]*>$', '', nfj[0])
				tags = re.findall('<(\w*)[^>]*>', si)
				if len(tags) != 0:
					self.errtag = 'bad sections parsing'
				nletlist.append(nfj[0])
			self.numlist.append(nletlist)


	def __init__(self, text):
		self.text = None
		self.errtag = None

		# split off the to ask part
		se = retoask.findall(text)
		if len(se) == 0:
			if not re.search('to ask the hon[.] member for(?i)', text):
				print text
			return

		# we have a recognized person who is asked

		#check for junk
		if re.sub('</?p>|\s(?i)', '', se[0][0]) != '':
			print 'unrecognized junk before to ask: ' + se[0][0]

		self.whoasked = se[0][1]
		self.text = se[0][2]

		self.extractqnumsections()


	def writexml(self, fout):
		if not self.text:
			return

		fout.write('<toask>%s</toask>\n' % self.whoasked)
		if self.errtag:
			fout.write('<queserror>%s</queserror>\n' % self.errtag)
			return

		for i in range(0, len(self.numlist)):
			if (i == 0) and (len(self.numlist[i]) == 0):
				continue
			if (i != 0):
				fout.write('<subques num="%d">\n' % i)
				for j in range(len(self.numlist[i])):
					if (i == 0) and (len(self.numlist[i][j]) == 0):
						continue
					if (j != 0):
						fout.write('<subletques let="%s">\n' % alphabet[j])
					fout.write(self.numlist[i][j])
					fout.write('\n')
					if (j != 0):
						fout.write('</subletques>\n')
			if (i != 0):
				fout.write('</subques>\n')

def FixQuestion(text):
	res = StringIO.StringIO()

	# sort out qnums
	bqnum = re.subn('\[(\d+?)\]', '<qcode qnum="\\1"/>', text)
	text = bqnum[0]
	if bqnum[1] != 0:
		qs = quesstruc(text)
		qs.writexml(res)
	else:
		res.write("<error>qnum missing</error>\n")


	sres = res.getvalue()
	res.close()
	return sres


def FixReply(text):
	res = StringIO.StringIO()

	if re.search('\[\d+?\]', text):
		res.write("<error>qnum present in answer</error>\n")
		print 'qnum present in answer'

	res.write('<reply textlength="%d"/>\n' % len(text))

	sres = res.getvalue()
	res.close()
	return sres
