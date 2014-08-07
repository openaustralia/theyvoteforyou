#! /usr/bin/perl -w 
use strict;
use lib "../scraper/";

# $Id: wordfreq.pl,v 1.1 2004/01/26 10:04:58 frabcus Exp $
# Some rough playing with counting word frequencies in Hansard

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use db;
my $dbh = db::connect();

# Get list of all dates we know about
my $sth = db::query($dbh, "select day_date from pw_cache_wordfreq group by day_date");
my %hash;
while (my @data = $sth->fetchrow_array())
{
    my ($date) = @data;
    $hash{$date} = 0;
}

# Get data for our word
$sth = db::query($dbh, "select day_date, count from pw_cache_wordfreq where word=?", $ARGV[0]);
while (my @data = $sth->fetchrow_array())
{
    my ($date, $count) = @data;
    $hash{$date} = $count;
}

my $c = 0;
foreach (sort keys(%hash))
{
    $c++;
    # $_
    print "$c " . $hash{$_} . "\n";
}
print "\n";

