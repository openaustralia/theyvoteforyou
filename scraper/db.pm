# $Id: db.pm,v 1.4 2003/10/03 17:56:36 frabcus Exp $
# Bumf for accessing the MySQL database

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package db;
use strict;

use DBI;

sub connect
{
    my $dbh = DBI->connect("DBI:mysql:tpw")
                or die "Couldn't connect to database: " . DBI->errstr;
    return $dbh;
}

sub query
{
    my $dbh = shift;
    my $query = shift;
    error::log("Query: $query Params: @_", "", error::CHITTER);
    my $sth = $dbh->prepare($query)
                or die "Couldn't prepare statement: " . $dbh->errstr . "\n$query";
    $sth->execute(@_) 
                or die "Couldn't execute statement: " . $dbh->errstr. "\n$query";
    return $sth;
}

#   $sth->finish;

1;
