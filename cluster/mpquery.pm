# $Id: mpquery.pm,v 1.2 2003/09/17 14:27:42 frabcus Exp $
# This is included by octavein.pl and mpcoords2db.pl.
# It defines the set of MPs which we are going to analyse.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package mpquery;
use strict;

sub get_mp_ixs()
{
    my $dbh = shift; 
    my $sth = db::query($dbh, "select pw_mp.mp_id from pw_mp, pw_cache_mpinfo where
        pw_mp.mp_id = pw_cache_mpinfo.mp_id and votes_attended > 0 order by pw_mp.last_name");
    my @mp_ixs;
    while (my @data = $sth->fetchrow_array())
    {
        push @mp_ixs, $data[0];
    }
    return @mp_ixs;
}

1;
