#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

# output to check for undetected member names
seelines = open('emblinks.txt', "w")

# this detects the domain
reglinkdomt = '(?:\.or[gq]|\.com|[\.\s]uk|\.tv|\.net|\.gov|\.int|\.info|\.it|\.ch|\.es|\.mz|\.lu|\.fr|\.dk|\.mil)(?!\w)'
reglinkdomf = 'http://(?:(?:www.)?defraweb|nswebcopy|\d+\.\d+\.\d+\.\d+)|www.defraweb'
reglinkdom = '(?:http ?:? ?/{1,3}(?:www)?|www)(?:(?:[^/:;,?=](?!www\.))*?(?:%s))+|%s' % (reglinkdomt, reglinkdomf)

# this detects the middle section of a url between the slashes.
reglinkmid = '(?:/(?:(?:[^/:;,?="]|&#\d+;)(?!www\.))+)*/'

# this detects the tail section of a url trailing a slash
#reglinktail = '[^./:;,]*(?:\.\s?(?:s?html?|pdf|xls|(?:asp|php|cfm(?:\?[^\s.]+)?)))|\w*'
regasptype = '(?:asp|php|cfm)(?:\?\s?\w+=[\w/]+(?:&\w+=[\w/%]+)*)?'
reglinktail = '(?:[^./:;,?=]|&#\d+;)*(?:\.\s?(?:s?html?|xls|pdf(?:\?Open ?Element)?|%s))|(?:[\w-]|&#\d+;)*' % regasptype


#reglink = '((%s)(?:(%s)(?:(%s))?)?)(?i)' % (reglinkdom, reglinkmid, reglinktail)
relink = re.compile('((%s)(?:(%s)(%s)?)?)(?i)' % (reglinkdom, reglinkmid, reglinktail))


def ExtractHTTPlink(stex, qs):

	qlink = relink.search(stex)

	# no link found.  output if there should be.
	if not qlink:
		if re.search('www|http|ftp(?i)', stex):
			seelines.write(qs.sdate)
			seelines.write('\t')
			seelines.write(' --failed to find link-- ' + stex + '\n')
			print ' --failed to find link-- ' + stex
		return (None,None,None)


	qspan = qlink.span(1)
	qstr = qlink.group(1)


	qstrdom = re.sub('^http|[:/\s]', '', qlink.group(2))
	if not re.match('[\w\-.]*$', qstrdom):
		print ' bad domain -- ' + qstrdom

	qstrmid = ''
	if qlink.group(3):
		qstrmid = re.sub(' ', '', qlink.group(3))
		qstrmid = re.sub('&#15[01];', '-', qstrmid)
		qstrmid = re.sub('&#95;', '_', qstrmid)
		if re.search('&#\d+;', qstrmid):
			print ' undemangled href symbol ' + qstrmid
		qstrmid = re.sub('&', '&amp;', qstrmid)
	if not re.match('[\w\-/.+;&]*$', qstrmid):
		print ' bad midd -- ' + qstrmid

	qstrtail = ''
	if qlink.group(4):
		qstrtail = re.sub(' ', '', qlink.group(4))
		qstrtail = re.sub('&#15[01];', '-', qstrtail)
		qstrtail = re.sub('&#95;', '_', qstrtail)
		if re.search('&#\d+;', qstrtail):
			print ' undemangled href symbol ' + qstrtail
		qstrtail = re.sub('&', '&amp;', qstrtail)
	if not re.match('[\w\-./\?&=%;]*$', qstrtail):
		print ' bad tail -- ' + qstrtail


	qstrlink = 'http://%s%s%s' % (qstrdom, qstrmid, qstrtail)
	qtags = ( '<a href="%s">' % qstrlink, '</a>' )

	# write out debug stuff
	qplpch = [ ]
	slo = qspan[0] - 10
	shi = qspan[1] + 20
	if slo < 0:
		slo = 0
	if shi > len(stex):
		shi = len(stex)
	qplpch.append(stex[slo:qspan[0]])
	qplpch.append('(' + qlink.group(2) + ')')

	if qlink.group(3):
		qplpch.append('(' + qlink.group(3) + ')')
	if qlink.group(4):
		qplpch.append('(' + qlink.group(4) + ')')

	qplpch.append(stex[qspan[1]:shi])
	#print ' **** ' + string.join(qplpch)
	seelines.write(qs.sdate)
	seelines.write('\t')
	map(seelines.write, qplpch)
	seelines.write('\n')


	return (qspan,qstr,qtags)
