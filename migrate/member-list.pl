#!/usr/bin/perl -w
use strict;
use lib "../scraper/";

# $Id: member-list.pl,v 1.2 2003/11/18 20:17:46 frabcus Exp $
# Outputs MP list as XML

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use error;
use db;
my $dbh = db::connect();

print "<members>\n\n"; 

my $sth = db::query($dbh, "select first_name, last_name, title, constituency, party, 
    entered_house, left_house, entered_reason, left_reason, mp_id from pw_mp
    order by entered_house, last_name, first_name, constituency");

while (my @row = $sth->fetchrow_array())
{
    print <<END
<member
    id="uk.org.publicwhip/member/$row[9]"
    house="commons"
    title="$row[2]" firstname="$row[0]" lastname="$row[1]"
    constituency="$row[3]" party="$row[4]"
    fromdate="$row[5]" todate="$row[6]" fromwhy="$row[7]" towhy="$row[8]"
/>
END
}

print "\n\n<members>\n"; 

