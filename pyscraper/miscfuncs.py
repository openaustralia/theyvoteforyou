#! /usr/bin/python2.3
import re


def ApplyFixSubstitutions(text, sdate, fixsubs):
	for sub in fixsubs:
		if sub[3] == 'all' or sub[3] == sdate:
			(text, n) = re.subn(sub[0], sub[1], text)
			if (sub[2] != -1) and (n != sub[2]):
				raise Exception, 'wrong substitutions %d on %s' % (n, sub[0])
	return text

def FixHTMLEntities(text):
    text = re.sub('&#150;', '-', text)
    text = re.sub('&#151;', ' -- ', text)
    text = re.sub('"', '&quot;', text)
# These wrong - should add entities to top of XML instead:
#   text = re.sub('&#163;', '&pound;', text)
    text = re.sub('&nbsp;', ' ', text)

    # The regexp pattern (?! ... ) is a "A zero-width negative
    # look-ahead assertion", which basically means "the ... pattern
    # is not there".  i.e. This matches all ampersands not followed by
    # some-letters-and-a-semicolon.
    text = re.sub("&(?![a-z]+;)", "&amp;", text)

    # take out ALL tags
    text = re.sub('<[^>]*>', ' ', text)
    return text

