#! /usr/bin/python2.3

import sys
import re
import os
import string
import StringIO

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

toaskregexp = 'to ask the (secretary of state for (?:' +\
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
				'work and pensions)|' +\
							\
				'chairman of the (?:' +\
				'accommodation and works committee|' +\
				'catering committee|' +\
				'public accounts committee|' +\
				'administration committee)' +\
							\
				'secretary of wales|' +\
				'leader of the house|' +\
				'minister of state, department for international development' +\
				'secretary of state, department for international development' +\
				'minister of agriculture, fisheries and food|' +\
				'minister for the cabinet office|' +\
				'minister for women|' +\
				'prime minister|' +\
				'(?:office of the )?deputy prime minister|' +\
				'parliamentary secretary|' +\
				'chancellor of the exchequer|' +\
				'president of the council|' +\
				'solicitor-general|' +\
				'advocate-general' +\
				')(?i)'

retoask = re.compile(toaskregexp)


class quesstruc:

	def __init__(self, text):
		self.text = text
		se = retoask.findall(text)
		if len(se) == 0:
			print text

	def writexml(self, fout):
		fout.write('<question textlength="%d"/>\n' % len(self.text))


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

	res.write("reply %d\n" % len(text))

	sres = res.getvalue()
	res.close()
	return sres
