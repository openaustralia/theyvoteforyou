# $Id: parliaments.pm,v 1.1 2003/10/04 13:46:22 frabcus Exp $
# List of parliaments we are covering.  This data is duplicated in
# website/parliaments.inc.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package parliaments;
use strict;

our @list = (
    {id => '2001', from => '2001-06-07', to => '9999-12-31', name => '2001'},
    {id => '1997', from => '1997-05-01', to => '2001-05-14', name => '1997'}
);

1;
