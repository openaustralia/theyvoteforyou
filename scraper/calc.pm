# $Id: calc.pm,v 1.9 2004/01/26 10:04:58 frabcus Exp $
# Calculates various data and caches it in the database.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package calc;
use strict;

use HTML::TokeParser;

sub guess_whip_for_all
{
    my $dbh = shift;

    db::query($dbh, "drop table if exists pw_cache_whip");
    db::query($dbh, 
    "create table pw_cache_whip (
        division_id int not null,
        party varchar(200) not null,
        whip_guess enum(\"aye\", \"no\", \"unknown\") not null,
        unique(division_id, party)
    );");

    my $sth = db::query($dbh, "select division_id from pw_division");
    while (my @data = $sth->fetchrow_array())
    {
        my ($divid) = @data;
#        print "Division $divid\n";
        guess_whip_for_division($dbh, $divid);
    }
}

sub guess_whip_for_division
{
    my $dbh = shift;
    my $divid = shift;

    # Work out the mode vote for each party, by counting ayes as
    # positive and noes as negative and adding up into a hash (%partycount)
    my $lastparty;
    my %partycount;
    my $sth = db::query($dbh, "select count(*), vote, party from pw_vote,pw_mp where division_id=? and pw_vote.mp_id = pw_mp.mp_id group by vote, party order by party;", $divid);
    while (my @data = $sth->fetchrow_array())
    {
        my ($count, $vote, $party) = @data;
        # Tellers tell for the side they would have voted for
        if ($vote eq "aye" or $vote eq "tellaye") 
        {
            $partycount{$party} += $count;
        }
        elsif ($vote eq "no" or $vote eq "tellno")
        {
            $partycount{$party} -= $count;
        }
        elsif ($vote eq "both") 
        {
            # just ensure key is there
            $partycount{$party} += 0;
        }
        else
        {
            die "Vote neither aye, no nor both - party $party division $divid";
        }
    }
    foreach (keys %partycount)
    {
#        print " $_ total $partycount{$_}\n";
        my $c = $partycount{$_};
        my $vote = "unknown";
        $vote = "aye" if ($c > 0);
        $vote = "no" if ($c < 0);
        my $sth = db::query($dbh, "insert into pw_cache_whip (division_id, party, whip_guess) values (?, ?, ?)", $divid, $_, $vote);
    }
}

sub count_mp_info
{
	my $dbh = shift;
	count_mp_info_dated($dbh, "1000-01-01", "9999-12-31", "pw_cache_mpinfo")
}

sub count_mp_info_session2002
{
	my $dbh = shift;	
	count_mp_info_dated($dbh, "2002-11-13", "2003-11-20", "pw_cache_mpinfo_session2002");
}

sub count_mp_info_dated
{
    my $dbh = shift;
	my $from = shift;
	my $to = shift;
	my $table = shift;

    db::query($dbh, "drop table if exists $table");
    db::query($dbh, 
    "create table $table (
        mp_id int not null,
        rebellions int not null,
        tells int not null,
        votes_attended int not null,
        votes_possible int not null,
        index(mp_id)
    );");

	my $sth = db::query($dbh, "select mp_id, party, entered_house,
		left_house from pw_mp where 
		(entered_house >= ? and entered_house <= ?) or
		(left_house >= ? and left_house <= ?) or
		(entered_house < ? and left_house > ?)", 
		$from, $to, $from, $to, $from, $to);

    while (my @data = $sth->fetchrow_array())
    {
        my ($mpid, $party, $entered_house, $left_house) = @data;

        my $sth = db::query($dbh, "select pw_vote.division_id, pw_vote.vote,
            pw_cache_whip.whip_guess from pw_cache_whip, pw_vote,
			pw_division where pw_cache_whip.party = ? and
			pw_cache_whip.division_id = pw_vote.division_id and
			pw_vote.mp_id = ? and pw_cache_whip.whip_guess <> 'unknown'
			and pw_vote.vote <> 'both' and pw_cache_whip.whip_guess <>
			replace(pw_vote.vote, 'tell', '') and
			pw_division.division_id = pw_vote.division_id and
			(division_date >= ? and division_date <= ?)
            ", $party, $mpid, $from, $to);
        my $rebel_count = $sth->rows;

        $sth = db::query($dbh, " select pw_vote.division_id, vote
            from pw_vote, pw_division where mp_id = ? 
            and (vote = 'tellaye' or vote = 'tellno') and
			pw_division.division_id = pw_vote.division_id and
			(division_date >= ? and division_date <= ?)
			", $mpid, $from, $to);
        my $tell_count = $sth->rows;

        $sth = db::query($dbh, "select count(*) from pw_vote,
			pw_division where mp_id = $mpid
			and pw_division.division_id = pw_vote.division_id and
			(division_date >= ? and division_date <= ?)
			", $from, $to);
        die "Failed to get vote count" if $sth->rows != 1;
        my $votes = $sth->fetchrow_arrayref()->[0];
        
        $sth = db::query($dbh, "select count(*) from pw_division
            where division_date >= ? and division_date <= ?
			and division_date >= ? and division_date <= ?",
            $entered_house, $left_house, $from, $to);
        die "Failed to get division count" if $sth->rows != 1;
        my $divisions = $sth->fetchrow_arrayref()->[0];

#        print "MP $mpid $party $rebel_count\n";

        db::query($dbh, "insert into $table (mp_id, rebellions,
        tells, votes_attended, votes_possible)
            values (?, ?, ?, ?, ?)", $mpid, $rebel_count, $tell_count, $votes, $divisions);
    }
}

sub count_division_info
{
    my $dbh = shift;

    db::query($dbh, "drop table if exists pw_cache_divinfo");
    db::query($dbh, 
    "create table pw_cache_divinfo (
        division_id int not null,
        rebellions int not null,
        turnout int not null,
        index(division_id)
    );");

    my $sth = db::query($dbh, "select division_id from pw_division");
    while (my @data = $sth->fetchrow_array())
    {
        my ($division_id) = @data;

        my $sth = db::query($dbh, "select count(*) from pw_vote,
            pw_cache_whip, pw_mp where pw_vote.division_id = ? and
            pw_cache_whip.division_id = ? and 
            pw_mp.party = pw_cache_whip.party and 
            pw_vote.mp_id = pw_mp.mp_id and 
            pw_cache_whip.whip_guess <> 'unknown' and 
            pw_vote.vote <> 'both' and
            pw_cache_whip.whip_guess <> replace(pw_vote.vote, 'tell', '')
            ", $division_id, $division_id);

        die "Failed to count rebels for div $division_id" if $sth->rows != 1;
        my $rebellions = $sth->fetchrow_arrayref()->[0];

        $sth = db::query($dbh, "select count(*) from pw_vote
            where pw_vote.division_id = ?", $division_id);
        my $turnout = $sth->fetchrow_arrayref()->[0];

#        print "division $division_id $rebellions\n";

        db::query($dbh, "insert into pw_cache_divinfo (division_id, rebellions, turnout)
            values (?, ?, ?)", $division_id, $rebellions, $turnout);
    }
}

sub count_party_stats
{
    my $dbh = shift;

    db::query($dbh, "drop table if exists pw_cache_partyinfo");
    db::query($dbh, 
    "create table pw_cache_partyinfo (
        party varchar(100) not null,
        total_votes int not null,
    );");

    my $sth = db::query($dbh, "select party, count(vote) from pw_vote, pw_mp where pw_vote.mp_id =
                pw_mp.mp_id group by party");
    while (my @data = $sth->fetchrow_array())
    {
        my ($party, $count) = @data;

        db::query($dbh, "insert into pw_cache_partyinfo (party, total_votes)
            values (?, ?)", $party, $count);
    }
}

1;
