#! $Id: contextexception.py,v 1.4 2004/04/09 15:50:29 frabcus Exp $
# vim:sw=8:ts=8:et:nowrap

import os
import sys
from resolvemembernames import memberList

class ContextException(Exception):

    def __init__(self, description, stamp = None, fragment = None):
        self.description = description
        self.stamp = stamp
        self.fragment = fragment

    def __str__(self):
        ret = ""
        if self.fragment:
            ret = ret + "Fragment: " + repr(self.fragment) + "\n"
        ret = ret + self.description + "\n"
        if self.stamp:
            ret = ret + repr(self.stamp) + "\n"
        return ret

def RunPatchTool(type, sdate, ce):
        if not ce.stamp:
                print "No stamp available, so won't move your cursor to right place"
        else:
                assert ce.stamp.sdate == sdate

        print "\nHit RETURN to launch your editor to make patches "
        sys.stdin.readline()
        if not ce.stamp:
                status = os.system("./patchtool %s %s" % (type, sdate))
        else:
                status = os.system("./patchtool %s %s -c /%s" % (type, sdate, ce.stamp.GetAName()))

        memberList.reloadXML()



