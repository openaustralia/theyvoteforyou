#! /usr/bin/perl -w 
use strict;

# $Id: load.pl,v 1.2 2004/06/08 13:05:09 frabcus Exp $
# The script you actually run to do screen scraping from Hansard.  Run
# with no arguments for usage information.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use WWW::Mechanize;
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
my $where_clause = "";
my @where_params;
$where_clause .= "and day_date >= ? " if defined $from;
push @where_params, $from if defined $from;
$where_clause .= "and day_date <= ? " if defined $to;
push @where_params, $to if defined $to;
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
exit;

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
    print "Erasing half-parsed divisions...\n";
    PublicWhip::Clean::erase_duff_divisions($dbh);
}

sub update_calc {
    print "Counting party statistics...\n";
    PublicWhip::Calc::count_party_stats($dbh);
    print "Guessing whip for each party/division...\n";
    PublicWhip::Calc::guess_whip_for_all($dbh);
    print "Counting rebellions/attendence by MP...\n";
    PublicWhip::Calc::count_mp_info($dbh);
    print "Counting rebellions/turnout by division...\n";
    PublicWhip::Calc::count_division_info($dbh);
    print "Rankings...\n";
    PublicWhip::Calc::current_rankings($dbh);
}

sub check {
    print "Checking integrity...\n";
    PublicWhip::Clean::check_integrity($dbh);
    print "Fixing up corrections we know about...\n";
    PublicWhip::Clean::fix_division_corrections($dbh);
    print "Fixing bothway votes...\n";
    PublicWhip::Clean::fix_bothway_voters($dbh);
}

sub all_divsxml {
    PublicWhip::DivsXML::read_xml_files( $dbh, $from, $to );
}

sub test {
    print "Temporary testing code...\n";
}

