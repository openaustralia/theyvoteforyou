#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from resolvemembernames import memberList
from parlphrases import parlPhrases

# do your conversion from perl to python here!!

# it's possible we want to make this a class, like with speeches.
# so that it sits in our list easily.  

def FilterDivision(divno, divtext, followspeeches):
	print "-- lots of work for Francis Division no. %d " % divno
	return [ ]


