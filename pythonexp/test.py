#! /usr/bin/python2.3

from resolvemembernames import memberList

(id, reason) = memberList.matchfullname("Mr. Galloway", "2003-11-21")
print "george is " + id

import resolvemembernames

(id, reason) = memberList.matchfullname("George Galloway", "1999-01-01")
print "george is " + id

print "after"

