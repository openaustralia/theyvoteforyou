#! /usr/bin/python2.3

from resolvemembernames import memberList

print memberList.matchdebatename("Annette L. Brooke", None, "2003-11-21")
print memberList.matchdebatename("Gareth Thomas", "Clwyd, West", "2003-11-21")

(id, reason, remade) = memberList.matchfullname("The Prime Minister", "2003-11-21")
print "tpm is " + id + " " + remade
(id, reason, remade) = memberList.matchfullname("The Prime Minister", "1992-11-21")
print "tpm a bit ago " + id + " " + remade
(id, reason, remade) = memberList.matchfullname("George Galloway", "1999-01-01")
print "george is " + id + " " + remade

