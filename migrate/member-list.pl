#!/usr/bin/perl -w
use strict;
use lib "../scraper/";

# $Id: member-list.pl,v 1.1 2003/11/12 14:38:55 frabcus Exp $
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
    entered_house, left_house, entered_reason, left_reason from pw_mp
    order by entered_house, last_name, first_name, constituency");

while (my @row = $sth->fetchrow_array())
{
    print "<member>\n";
    print " <title>$row[2]</title> <firstname>$row[0]</firstname> <lastname>$row[1]</lastname>\n";
    print " <constituency>$row[3]</constituency> <party>$row[4]</party>\n";
    print " <date from=\"$row[5]\" to=\"$row[6]\" fromwhy=\"$row[7]\" towhy=\"$row[8]\" />\n";
    print "</member>\n";
}

print "\n\n<members>\n"; 

