#! $Id: contextexception.py,v 1.2 2004/04/07 18:53:34 frabcus Exp $
# vim:sw=8:ts=8:et:nowrap

import os
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

def RunPatchTool(type, ce):
        if type != "wrans":
                raise Exception, "Only wrans in patchtool at the moment"
        if not ce.stamp:
                raise Exception, "Require a stamp in ContextException for this for now"

        status = os.system("./patchtool %s %s -c /%s" % (type, ce.stamp.sdate, ce.stamp.GetAName()))

        memberList.reloadXML()



