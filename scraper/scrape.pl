#! /usr/bin/perl -w 
use strict;

# $Id: scrape.pl,v 1.1 2003/08/14 19:35:48 frabcus Exp $
# The script you actually run to do screen scraping from Hansard.  Run
# with no arguments for usage information.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use WWW::Mechanize;
use Getopt::Long;
use clean;
use finddays;
use content;
use divisions;
use calc;
use mplist;

my $from;
my $to;
my $result = GetOptions ("from=s"   => \$from,
                          "to=s" => \$to);

my $where_clause = "";
my @where_params;
$where_clause .= "and day_date >= ? " if defined $from;
push @where_params, $from if defined $from;
$where_clause .= "and day_date <= ? " if defined $to;
push @where_params, $to if defined $to;

if ($#ARGV < 0 || (!$result))
{
    help();
    exit;
}

my $dbh = db::connect();

foreach my $argnum (0 .. $#ARGV)
{
    $_ = $ARGV[$argnum];
    if ($_ eq "clean")
    {
        clean();
    }
    elsif ($_ eq "mps")
    {
        mps();
    }
    elsif ($_ eq "months")
    {
        crawl_recent_months();
    }
    elsif ($_ eq "sessions")
    {
        crawl_recent_sessions();
    }
    elsif ($_ eq "content")
    {
        all_content();
    }
    elsif ($_ eq "divisions")
    {
        all_divisions();        
    }
    elsif ($_ eq "calc")
    {
        update_calc();
    }
    elsif ($_ eq "check")
    {
        check();
    }
    elsif ($_ eq "words")
    {
        word_count();
    }
    else
    {
        help();
        exit;
    }
}
exit;

sub help
{
print <<END;

Downloads divisions from Hansard via HTTP, and parses them into MP
voting records within a MySQL database.

scrape.pl [OPTION]... [COMMAND]...

Commands are any or all of:
mps - insert MPs into database from local raw data files
clean - tidy up bad records in the database from interrupted crawls
months - scan recent months and find day URLs
sessions - scan recent sessions and find day URLs
content - fetch debate content for all days
divisions - parse divisions from local content and add them to database
check - check database consistency
calc - update cached calculations, do this after every crawl
words - count word frequencies

These options apply to "content" and "divisions" commands only:
--from=YYYY-MM-DD - from date to apply, or else all into the past
--to=YYYY-MM-DD - to date to apply, or else all into the future

END

}

sub mps
{
    print "Inserting MPs...\n";
    mplist::insert_mps($dbh);
}

sub clean
{
    print "Erasing half-parsed divisions...\n";
    clean::erase_duff_divisions($dbh);
    print "Fixing up corrections we know about...\n";
    clean::fix_division_corrections($dbh);
}

sub crawl_recent_months
{
    # Test most recent month and sessions crawl
    my $agent = WWW::Mechanize->new();
    my $start_url = "http://www.publications.parliament.uk/pa/cm/cmhansrd.htm";
    $agent->get($start_url)->is_success() or die "Failed to read URL $start_url";
    print "Scanning recent months...\n";
    finddays::recent_months($dbh, $agent);
    # Add this on end of recent_months to start only back from Jan:
    #, "cmhn0301");
    #http://www.publications.parliament.uk/pa/cm/cmhn0302.htm
}

sub crawl_recent_sessions
{
    # Test most recent month and sessions crawl
    my $agent = WWW::Mechanize->new();
    my $start_url = "http://www.publications.parliament.uk/pa/cm/cmhansrd.htm";
    $agent->get($start_url)->is_success() or die "Failed to read URL $start_url";
    print "Scanning recent sessions...\n";
    finddays::recent_sessions($dbh, $agent);
}

sub update_calc
{
    print "Counting party statistics...\n";
    calc::count_party_stats($dbh);
    print "Guessing whip for each party/division...\n";
    calc::guess_whip_for_all($dbh);
    print "Counting rebellions/attendence by MP...\n";
    calc::count_mp_info($dbh);
    print "Counting rebellions/turnout by division...\n";
    calc::count_division_info($dbh);
}

sub check
{
    print "Checking integrity...\n";
    clean::check_integrity($dbh);
}

sub word_count
{
    print "Counting word frequencies...\n";
    calc::count_word_frequencies($dbh);
}

sub all_content
{
    my $agent = WWW::Mechanize->new();

    my $sth = db::query($dbh, "select pw_hansard_day.day_date,
        first_page_url from pw_hansard_day left join pw_debate_content on
        pw_hansard_day.day_date = pw_debate_content.day_date where
        pw_debate_content.day_date is null $where_clause order by day_date desc", 
        @where_params);
    
    print "Getting content for " . $sth->rows() . " missing days\n\n";
    while (my @data = $sth->fetchrow_array())
    {
        my ($date, $url) = @data;
        print "Date $date\n";
        $agent->get($url);
        content::fetch_day_content($dbh, $agent, $date);
    }
}

sub all_divisions
{
    if (defined $from && $from eq $to)
    {
        # If we select one day, clean out all parsed divisions so far
        # for that day and reparse
        my $sth = db::query($dbh, "update pw_debate_content set divisions_extracted = 0 where 1=1 $where_clause", @where_params);
        my $new_where_clause = $where_clause;
        $new_where_clause =~ s/day_date/division_date/g;
        $sth = db::query($dbh, "update pw_division set valid = 0 where 1=1 $new_where_clause", @where_params);
        clean();
    }

    my $sth = db::query($dbh, "select day_date, content from pw_debate_content where divisions_extracted = 0 $where_clause", @where_params);
    print "Getting divisions for " . $sth->rows() . " days\n\n";
    while (my @data = $sth->fetchrow_array())
    {
        my ($day_date, $content) = @data;
        divisions::parse_all_divisions_on_page($dbh, $content, $day_date);
    }
}


