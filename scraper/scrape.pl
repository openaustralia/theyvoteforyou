#! /usr/bin/perl -w 
use strict;

# $Id: scrape.pl,v 1.6 2003/10/02 09:42:03 frabcus Exp $
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
use error;

my $from;
my $to;
my $date;
my $verbose;
my $chitter;
my $quiet;
my $force;
my $result = GetOptions ("from=s"   => \$from,
                          "to=s" => \$to,
                          "date=s" => \$date,
                          "verbose" => \$verbose,
                          "chitter" => \$chitter,
                          "quiet" => \$quiet,
                          "force" => \$force);

if ($date)
{
    die "Specify either specific date or date range, not both" if ($from || $to);
    $from = $date;
    $to = $date;
}
my $where_clause = "";
my @where_params;
$where_clause .= "and day_date >= ? " if defined $from;
push @where_params, $from if defined $from;
$where_clause .= "and day_date <= ? " if defined $to;
push @where_params, $to if defined $to;

error::setverbosity(error::IMPORTANT + 1) if $quiet;
error::setverbosity(error::USEFUL) if $verbose;
error::setverbosity(error::CHITTER) if $chitter;

if ($#ARGV < 0 || (!$result))
{
    help();
    exit;
}

my $dbh = db::connect();

foreach my $argnum (0 .. $#ARGV)
{
    clean();

    $_ = $ARGV[$argnum];
    if ($_ eq "mps")
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

Commands are any or all of these, in order you want them run:
mps - insert MPs into database from local raw data files
months - scan back through months to get new day URLs
sessions - scan recent sessions and find day URLs
content - fetch debate content for all days
divisions - parse divisions from local content and add them to database
check - check database consistency
calc - update cached calculations, do this after every crawl
words - count word frequencies

These options apply to "content" and "divisions" commands only:
--date=YYYY-MM-DD - date to apply to
--from=YYYY-MM-DD - process all from this date onwards
--to=YYYY-MM-DD - process all up to this date
(you can specify from and to for an inclusive date range)
--force - delete previous data, and refetch/recalculate

These are general options:
--quiet - say nothing, except for errors
--verbose - say more about what is going on
--chitter - display detailed debug logs

END

}

# Called every time to tidy up database
sub clean
{
    print "Erasing half-parsed divisions...\n";
    clean::erase_duff_divisions($dbh);
}

sub mps
{
    print "Inserting MPs...\n";
    mplist::insert_mps($dbh);
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
    finddays::recent_sessions($dbh, $agent, "cmse0001", "cmse9798"); # inclusive
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
    print "Fixing up corrections we know about...\n";
    clean::fix_division_corrections($dbh);
    print "Fixing bothway votes...\n";
    clean::fix_bothway_voters($dbh);
}

sub word_count
{
    print "Counting word frequencies...\n";
    calc::count_word_frequencies($dbh);
}

sub all_content
{
    my $agent = WWW::Mechanize->new();

    if ($force)
    {
        my $sth = db::query($dbh, "delete from pw_debate_content where
            1=1 $where_clause", @where_params);
        clear_divisions_in_range();
    }

    my $new_where_clause = $where_clause;
    $new_where_clause =~ s/day_date/pw_hansard_day.day_date/g;
    my $sth = db::query($dbh, "select pw_hansard_day.day_date,
        first_page_url from pw_hansard_day left join pw_debate_content on
        pw_hansard_day.day_date = pw_debate_content.day_date where
        pw_debate_content.day_date is null $new_where_clause order by day_date desc", 
        @where_params);
    
    print "Getting content for " . $sth->rows() . " missing days\n";
    while (my @data = $sth->fetchrow_array())
    {
        my ($date, $url) = @data;
        $agent->get($url);
        content::fetch_day_content($dbh, $agent, $date);
    }
}

# Clean out all parsed divisions we already have for date range
sub clear_divisions_in_range
{
    my $sth = db::query($dbh, "update pw_debate_content set divisions_extracted = 0 where 1=1 $where_clause", @where_params);
    my $new_where_clause = $where_clause;
    $new_where_clause =~ s/day_date/division_date/g;
    $sth = db::query($dbh, "update pw_division set valid = 0 where 1=1 $new_where_clause", @where_params);
    clean();
}

sub all_divisions
{
    if ($force)
    {
        clear_divisions_in_range();
    }

    my $sth = db::query($dbh, "select day_date, content from pw_debate_content where divisions_extracted = 0 $where_clause", @where_params);
    print "Getting divisions for " . $sth->rows() . " days\n\n";
    while (my @data = $sth->fetchrow_array())
    {
        my ($day_date, $content) = @data;
        divisions::parse_all_divisions_on_page($dbh, $content, $day_date);
    }
}


