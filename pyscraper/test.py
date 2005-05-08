#! /usr/bin/python2.3

import sys
from resolvemembernames import memberList

print memberList.canonicalcons("Aberdeen North", "2001-01-01")
print memberList.canonicalcons("Aberdeen North", "2005-05-06")

print memberList.matchdebatename("Solicitor-General", None, "2003-11-21")
print memberList.matchdebatename("The Advocate-General for Scotland", None, "2004-07-30")

print memberList.getmembersoneelection("uk.org.publicwhip/member/1238")
print memberList.getmembersoneelection("uk.org.publicwhip/member/1353")
print memberList.getmembersoneelection("uk.org.publicwhip/member/1357")

print memberList.matchdebatename("Mr. Mackay", None, "2003-11-21")
print memberList.matchdebatename("James Marshall", None, "2003-11-21")
print memberList.matchdebatename("Gareth Thomas", "Clwyd, West", "2003-11-21")
print memberList.matchdebatename("Gareth Thomas", None, "2005-05-07")

print memberList.matchfullnamecons("Mr. MacDonald", "Western Isles", "2005-04-01")
print memberList.matchfullnamecons("Mr. MacNeil", "Na h-Eileanan an Iar", "2005-04-01")
print memberList.matchfullnamecons("Mr. MacDonald", "Western Isles", "2005-05-07")
print memberList.matchfullnamecons("Mr. MacNeil", "Na h-Eileanan an Iar", "2005-05-07")

print memberList.matchfullnamecons("The Prime Minister", None, "2003-11-21")
# print memberList.matchfullnamecons("The Prime Minister", None, "1992-11-21")
print memberList.matchfullnamecons("George Galloway", None, "1999-01-01")
print memberList.matchfullnamecons("George Galloway", None, "2005-01-01")
print memberList.matchfullnamecons("George Galloway", "Bethnal Green & Bow", "2005-01-01")
print memberList.matchfullnamecons("George Galloway", None, "2005-05-06")

