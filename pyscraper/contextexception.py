#! $Id: contextexception.py,v 1.1 2004/04/01 17:05:46 frabcus Exp $
# vim:sw=8:ts=8:et:nowrap

class ContextException(Exception):

    def __init__(self, description, stamp = None, fragment = None):
        self.description = description
        self.stamp = stamp
        self.fragment = fragment

    def __str__(self):
        ret = self.description + "\n"
        if self.stamp:
            ret = ret + repr(self.stamp) + "\n"
        if self.fragment:
            ret = ret + "Fragment: " + repr(self.fragment) + "\n"
        return ret

