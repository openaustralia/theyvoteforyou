# $Id: divsxml.pm,v 1.2 2004/03/23 14:57:49 frabcus Exp $
# Loads divisions from the XML files made by pyscraper into 
# the MySQL database for the Public Whip website.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package divsxml;
use strict;

use XML::Twig;
use Text::Autoformat;
use db;
use error;
use Data::Dumper;
use Unicode::String qw(utf8 latin1 utf16);

our $toppath = $ENV{'HOME'} . "/pwdata/";
our $debatepath = $toppath . "scrapedxml/debates/";
our $curdate;
our $dbh;

our $lastmajor = "";
our $lastminor = "";

sub read_xml_files
{
    $dbh = shift;
    my $from = shift;
    my $to = shift;

    my $twig = XML::Twig->new(twig_handlers => { 
            'division' => \&loaddivision,
            'major-heading' => \&storemajor,
            'minor-heading' => \&storeminor,
        }, output_filter => 'safe');

    opendir DIR, $debatepath or die "Cannot open $debatepath: $!\n";
    while (my $file = readdir(DIR)) {
        if ($file =~ m/^debates(\d\d\d\d-\d\d-\d\d).xml$/)
        {
            $curdate = $1;
            if (($curdate ge $from) and ($curdate le $to))
            {
                error::log("Processing XML divisions", $curdate, error::USEFUL);
                $twig->parsefile($debatepath . "debates" . $curdate. ".xml");
            }
        }
    }
    closedir DIR;

}

sub array_difference
{
        my $array1 = shift;
        my $array2 = shift;

        my @union = ();
        my @intersection = ();
        my @difference = ();

        my %count = ();
        foreach my $element (@$array1, @$array2) { $count{$element}++ }
        foreach my $element (keys %count) {
                push @union, $element;
                push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
        }
        return \@difference;
}

sub storeminor
{ 
	my ($twig, $minor) = @_;

    $lastminor = $minor->sprint(1);
}

sub storemajor
{ 
	my ($twig, $major) = @_;

    $lastmajor = $major->sprint(1);
    $lastminor = "";
}

sub loaddivision
{ 
	my ($twig, $div) = @_;

    my $divdate = $div->att('divdate');
    die "inconsistent date" if $divdate ne $curdate;
    my $divnumber = $div->att('divnumber');
    my $heading = $lastmajor;
    if ($lastminor)
    {
        $heading .= " &#8212; " . $lastminor;
    }

    # we lowercase if necessary
    if ($heading !~ m/[a-z]/)
    {
        $heading =~ s/^\s+//; # spaces confuse autoformat
        $heading =~ s/\s+$//;
        $heading = autoformat $heading, { case => 'highlight' };
    }
    # clear up all spaces to be just spaces, not line feeds, and
    # not be trailing leading (autoformat puts them in)
    $heading =~ s/^\s+//;
    $heading =~ s/\s+$//;
    $heading =~ s/\s+/ /g;

    # Should emdashes in headings have spaces round them?  This removes them if they shouldn't.
    # $heading =~ s/ \&\#8212; /\&\#8212;/g;
    
    my $url = $div->att('url');
    my $motion_text = "No motion text available";

    my $votes;
	for (my $mplist = $div->first_child('mplist'); $mplist; 
		$mplist = $mplist->next_sibling('mplist'))
    {
        for (my $mpname = $mplist->first_child('mpname'); $mpname; 
            $mpname = $mpname->next_sibling('mpname'))
        {
            my $vote = $mpname->att('vote'); 
            my $tell = $mpname->att('teller'); 
            if (not defined($tell)) 
                { $tell = ""; }
            elsif ($tell eq "yes")
                { $tell = "tell"; }
            else
                { die "unexpected tell value $tell"; }
            my $id = $mpname->att('id'); 
            $id =~ s:uk.org.publicwhip/member/::;
            push @{$votes->{$id}}, "$tell$vote";
        }
    }

    # See if we already have the division
    my $sth = db::query($dbh, "select division_id, valid, division_name, motion from pw_division where
        division_number = ? and division_date = ?", $divnumber, $divdate);
    die "Division $divnumber on $divdate already in database more than once" if ($sth->rows > 1);

    if ($sth->rows > 0)
    { 
        my @data = $sth->fetchrow_array();
        die "Incomplete division $divnumber, $divdate already exists, clean the database" if ($data[1] != 1);
        my $existing_divid = $data[0];
        my $existing_heading = $data[2];
        my $existing_motion = $data[3];
        if (($existing_heading ne $heading) or ($existing_motion ne $motion_text))
        {
            db::query($dbh, "update pw_division set division_name = ?, motion = ? where division_id = ?", $heading, $motion_text, $existing_divid);
            error::log("Existing division $divnumber, $divdate, id $existing_divid name $existing_heading has had its name and/or motion text corrected with the one from XML called $heading", $divdate, error::USEFUL);
        }
        else
        {
            error::log("Division already in DB for division $divnumber on date $divdate", $divdate, error::USEFUL);
            my $sth = db::query($dbh, "select mp_id, vote from pw_vote where division_id = $existing_divid");
            my $existing_votes;
            while (@data = $sth->fetchrow_array())
            {
                my $exist_mpid = $data[0];
                my $exist_vote = $data[1];
                if ($exist_vote eq "both")
                {
                    push @{$existing_votes->{$exist_mpid}}, "aye";
                    push @{$existing_votes->{$exist_mpid}}, "no";
                }
                else
                {
                    push @{$existing_votes->{$exist_mpid}}, $exist_vote;
                }
            }

            my @voters = keys %$votes;
            my @existing_voters = keys %$existing_votes;
            @voters = sort @voters;
            @existing_voters = sort @existing_voters;
            my $missing = array_difference(\@voters,  \@existing_voters);
            my $amount = @$missing;
            if ($amount > 0 )
            {
                print Dumper($missing);
                error::die("Voter list differs in XML to one in database - $amount in symmetric diff", $curdate) 
            }

            foreach my $testid (@voters)
            {
                my $indvotes = $votes->{$testid};
                my $existing_indvotes = $existing_votes->{$testid};
                @$indvotes = sort @$indvotes;
                @$existing_indvotes = sort @$existing_indvotes;
                # print $testid, $indvotes, $existing_indvotes, "\n";
                my $missing = array_difference($indvotes, $existing_indvotes);
                my $amount = @$missing;
                if ($amount > 0 )
                {
                    print "xml ", Dumper($indvotes), "\n";
                    print "db ", Dumper($existing_indvotes), "\n";
                    error::die("Votes for MP $testid differs between database and XML", $curdate);
                }

            }

        }
        return;
    }
    
    # Add division to tables
    db::query($dbh, "insert into pw_division 
        (valid, division_date, division_number, division_name, source_url, motion) values
        (0, ?, ?, ?, ?, ?)", $divdate, $divnumber, $heading, $url, $motion_text);
    $sth = db::query($dbh, "select last_insert_id()");
    die "Failed to get last insert id for new division" if $sth->rows != 1;
    my @data = $sth->fetchrow_array();
    my $division_id = $data[0];

    foreach my $mp_id (keys %$votes)
    {
        my $votelist = $votes->{$mp_id};
        foreach my $vote (@$votelist)
        {
                db::query($dbh, "insert into pw_vote (division_id, mp_id, vote) values (?,?,?)", 
                    $division_id, $mp_id, $vote);
        }
    }

    # Confirm change (this should be done with transactions, but I don't
    # want to get into them as web providers I want to use may not offer
    # support for that db type in mysql)
    db::query($dbh, "update pw_division set valid = 1 where division_id = ?", $division_id);
    error::log("XML added new division $divnumber $heading", $divdate, error::IMPORTANT);
}

=pod
    # Ignore capital "DEFERRED DIVISION" headings, as they are
    # announced in the middle of other debates and confuse
    # things (the actual votes appear at the end of the days
    # proceedings, with a separate lowercase "deferred division" heading)
    #elsif ($text !~ m/DEFERRED DIVISION/)
    # 2003-02-26 Iraq debate has a capital title
    # "BUSINESS OF THE HOUSE" which is unimportant
    # and otherwise overwrites the correct title
    #if ($text !~ m/BUSINESS OF THE HOUSE/) 
=cut

1;
