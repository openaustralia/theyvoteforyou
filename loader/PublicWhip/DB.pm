# $Id: DB.pm,v 1.1 2004/06/08 11:56:54 frabcus Exp $
# Bumf for accessing the MySQL database

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package PublicWhip::DB;
use strict;

# Copy config.pm.incvs to config.pm and edit it
use PublicWhip::Config;
use PublicWhip::Error;

use DBI;

sub connect {
    my $dbh = DBI->connect(
        $PublicWhip::Config::dbspec, $PublicWhip::Config::user,
        $PublicWhip::Config::pass, { RaiseError => 1, PrintError => 0 }
      )
      or die "Couldn't connect to database: " . DBI->errstr;
    return $dbh;
}

sub query {
    my $dbh   = shift;
    my $query = shift;
    PublicWhip::Error::log( "Query: $query Params: @_", "", ERR_CHITTER );
    my $sth = $dbh->prepare($query)
      or die "Couldn't prepare statement: " . $dbh->errstr . "\n$query";
    $sth->execute(@_)
      or die "Couldn't execute statement: " . $dbh->errstr . "\n$query";
    return $sth;
}

#   $sth->finish;

1;
