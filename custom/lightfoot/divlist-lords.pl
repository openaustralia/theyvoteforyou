#!/usr/bin/perl -I ../../loader

use lib "../../scraper/";
use PublicWhip::Error;
use PublicWhip::DB;
my $dbh = PublicWhip::DB::connect();

my $sth = PublicWhip::DB::query($dbh, "select division_id, division_date, division_number, division_name from pw_division " .
        " where house = 'lords' order by division_date desc, division_number desc");
print $sth->rows . " divisions\n";
while (my @data = $sth->fetchrow_array())
{
    print $data[1] . " " . $data[2] . "#" . $data[3] . "\n";
}


