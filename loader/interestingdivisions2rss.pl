#!/usr/bin/perl

use warnings;
use strict;
use PublicWhip::DB;
use PublicWhip::Parliaments;
use PublicWhip::SQLfragments;
use XML::RSS;

my $dbh = PublicWhip::DB::connect();
my $this_parliament=PublicWhip::Parliaments::getcurrent();

my $results=  PublicWhip::DB::query($dbh,
		 PublicWhip::SQLfragments::divisions_query_start(
		 	'date_format(division_date, "%a, %d %b %Y %T +0000") as division_date_formatted, ') .
		 "and ". PublicWhip::SQLfragments::parliament_query_range_div($this_parliament) .
		 PublicWhip::SQLfragments::divisions_controversial() .
		" limit 30 "
		);


 my $rss = new XML::RSS (version => '1.0');
 $rss->channel(
   title        => "Interesting Parliamentary Divisions",
   link         => "http://www.publicwhip.org.uk/",
   description  => "Interesting Divisions from The Public Whip - http://www.publicwhip.org.uk/ .",
   dc => {
     subject    => "Interesting Parliamentary Divisions",
     creator    => 'team@publicwhip.org.uk',
     publisher  => 'team@publicwhip.org.uk',
     rights     => 'Copyright PublicWhip 2005',
     language   => 'en-gb',
     ttl        =>  600
   },
   syn => {
     updatePeriod     => "daily",
     updateFrequency  => "1",
     updateBase       => "1901-01-01T00:00+00:00",
   },
 );

   while (my $result= $results->fetchrow_hashref) {
            $rss->add_item(
		  dc=> {date => "$result->{division_date_formatted}"},
	          title => "$result->{rebellions} rebellions in $result->{division_name}",
                  link => "http://www.publicwhip.org.uk/division.php?date=$result->{division_date}&number=$result->{division_number}",
		  description => "<p>$result->{rebellions} MPs rebelled out of $result->{turnout} voters in this vote on $result->{division_name} in the House of Commons.</p>",
                );

}
   print $rss->as_string;


