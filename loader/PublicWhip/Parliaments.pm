# $Id: Parliaments.pm,v 1.2 2005/01/01 19:12:46 sams Exp $
# List of parliaments we are covering.  This data is duplicated in
# website/parliaments.inc.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# XXX Does anything ever use this?

=doc
    my @parls = PublicWhip::Parliaments::getlist();
    foreach my $parl (@parls)
    {
        print $$parl{"id"}, $$parl{"from"}, $$parl{"to"};
    }
=cut

package PublicWhip::Parliaments;
use strict;

our @list = ( # put newer Parliaments first
    { id => '2001', from => '2001-06-07', to => '9999-12-31', name => '2001' },
    { id => '1997', from => '1997-05-01', to => '2001-05-14', name => '1997' }
);

sub getlist {
    return @list;
}

sub getcurrent {
	return ($list[0]);
}

1;
