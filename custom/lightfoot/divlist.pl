#!/usr/bin/perl

use lib "../../scraper/";
use error;
use db;
use parliaments;
my $dbh = db::connect();

my $sth = db::query($dbh, "select division_id, division_date, division_number, division_name from pw_division " .
        " order by division_date desc, division_number desc");
print $sth->rows . " divisions\n";
while (my @data = $sth->fetchrow_array())
{
    print $data[1] . " " . $data[2] . "#" . $data[3] . "\n";
}


