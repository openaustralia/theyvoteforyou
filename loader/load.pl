#! /usr/bin/perl -w 
use strict;

# $Id: load.pl,v 1.7 2004/11/20 18:29:34 frabcus Exp $
# The script you actually run to do screen scraping from Hansard.  Run
# with no arguments for usage information.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use Getopt::Long;
use PublicWhip::Clean;
use PublicWhip::DivsXML;
use PublicWhip::Calc;
use PublicWhip::DB;
use PublicWhip::Error;

my $from;
my $to;
my $date;
my $verbose;
my $chitter;
my $quiet;
my $result = GetOptions(
    "from=s"  => \$from,
    "to=s"    => \$to,
    "date=s"  => \$date,
    "verbose" => \$verbose,
    "chitter" => \$chitter,
    "quiet"   => \$quiet,
);

if ($date) {
    die "Specify either specific date or date range, not both"
      if ( $from || $to );
    $from = $date;
    $to   = $date;
}
$from = "1000-01-01" if not defined $from;
$to   = "9999-12-31" if not defined $to;

PublicWhip::Error::setverbosity(ERR_IMPORTANT + 1 ) if $quiet;
PublicWhip::Error::setverbosity(ERR_USEFUL)          if $verbose;
PublicWhip::Error::setverbosity(ERR_CHITTER)         if $chitter;

if ( $#ARGV < 0 || ( !$result ) ) {
    help();
    exit;
}

my $dbh = PublicWhip::DB::connect();

for (@ARGV) {
    clean();

    if    ( $_ eq "divsxml" )   { all_divsxml(); }
    elsif ( $_ eq "calc" )      { update_calc(); }
    elsif ( $_ eq "check" )     { check(); }
    elsif ( $_ eq "test" )      { test(); }
    else { help(); exit; }
}

if ($PublicWhip::DivsXML::divisions_changed) {
    exit 1;
} else {
    exit;
}

sub help {
    print <<END;

Loads voting lists from XML files into MySQL database for the Public Whip
website.  Peforms various statistical calculations and consistency checks.

scrape.pl [OPTION]... [COMMAND]...

Commands are any or all of these, in order you want them run:
divsxml - parse divisions from XML files and add them to database
check - check database consistency
calc - update cached calculations, do this after every crawl

These options apply to 'divsxml' command only:
--date=YYYY-MM-DD - date to apply to
--from=YYYY-MM-DD - process all from this date onwards
--to=YYYY-MM-DD - process all up to this date
(you can specify from and to for an inclusive date range)

These are general options:
--quiet - say nothing, except for errors
--verbose - say more about what is going on
--chitter - display detailed debug logs

END

}

# Called every time to tidy up database
sub clean {
    PublicWhip::Error::log("Erasing half-parsed divisions...", "", ERR_USEFUL);
    PublicWhip::Clean::erase_duff_divisions($dbh);
}

sub update_calc {
    PublicWhip::Error::log("Counting party statistics...", "", ERR_USEFUL);
    PublicWhip::Calc::count_party_stats($dbh);
    PublicWhip::Error::log("Guessing whip for each party/division...", "", ERR_USEFUL);
    PublicWhip::Calc::guess_whip_for_all($dbh);
    PublicWhip::Error::log("Counting rebellions/attendence by MP...", "", ERR_USEFUL);
    PublicWhip::Calc::count_mp_info($dbh);
    PublicWhip::Error::log("Counting rebellions/turnout by division...", "", ERR_USEFUL);
    PublicWhip::Calc::count_division_info($dbh);
    PublicWhip::Error::log("Rankings...", "", ERR_USEFUL);
    PublicWhip::Calc::current_rankings($dbh);
}

sub check {
    PublicWhip::Error::log("Fixing up corrections we know about...", "", ERR_USEFUL);
    PublicWhip::Clean::fix_division_corrections($dbh);
    PublicWhip::Error::log("Fixing bothway votes...", "", ERR_USEFUL);
    PublicWhip::Clean::fix_bothway_voters($dbh);
    PublicWhip::Error::log("Checking integrity...", "", ERR_USEFUL);
    PublicWhip::Clean::check_integrity($dbh, $from, $to);
}

sub all_divsxml {
    PublicWhip::DivsXML::read_xml_files( $dbh, $from, $to );
}

sub test {
    PublicWhip::Error::log("Temporary testing code...", "", ERR_USEFUL);
}

