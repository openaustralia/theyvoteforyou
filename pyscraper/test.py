#! /usr/bin/python2.3

from resolvemembernames import memberList

print memberList.matchdebatename("Mr. Mackay", None, "2003-11-21")
print memberList.matchdebatename("James Marshall", None, "2003-11-21")
print memberList.matchdebatename("Gareth Thomas", "Clwyd, West", "2003-11-21")

(id, remadename, remadecons) = memberList.matchfullnamecons("The Prime Minister", None, "2003-11-21")
print "tpm is " + id + " " + remadename
#(id, remadename, remadecons) = memberList.matchfullnamecons("The Prime Minister", None, "1992-11-21")
#print "tpm a bit ago " + id + " " + remadename
(id, remadename, remadecons) = memberList.matchfullnamecons("George Galloway", None, "1999-01-01")
print "george is " + id + " " + remadename

