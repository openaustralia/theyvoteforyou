# $Id: DivsXML.pm,v 1.11 2006/02/15 00:45:14 publicwhip Exp $
# vim:sw=4:ts=4:et:nowrap

# Loads divisions from the XML files made by pyscraper into
# the MySQL database for the Public Whip website.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package PublicWhip::DivsXML;
use strict;

use XML::Twig;
use Text::Autoformat;
use PublicWhip::DB;
use PublicWhip::Error;
use Data::Dumper;
use Unicode::String qw(utf8 latin1 utf16);

our $toppath    = $ENV{'HOME'} . "/pwdata/";

our $cursuffix;
our $curdate;
our $dbh;

our $lastmajor;
our $lastminor;
our $lastmotiontext;
our $lastheadingurl;
our $lastheadinggid;

our $divisions_changed;

our $house;

sub read_xml_files {
    $dbh = shift;
    my $from = shift;
    my $to   = shift;
    my $debatepath = shift;
    my $fileprefix  = shift;
    $house  = shift; # global
    die if $house ne "lords" && $house ne "commons";

    $divisions_changed = 0;

    # We have a separate parser to extract attributes from publicwhip header
    my $twig_header = XML::Twig->new();

    my $twig = XML::Twig->new(
        twig_handlers => {
            'division'      => \&loaddivision,
            'major-heading' => \&storemajor,
            'minor-heading' => \&storeminor,
            'p'             => \&storemotion,
        },
        output_filter => 'safe'
    );

    opendir DIR, $debatepath or die "Cannot open $debatepath: $!\n";
    while ( my $file = readdir(DIR) ) {
        if ( $file =~ m/^$fileprefix(\d\d\d\d-\d\d-\d\d)([a-z]*).xml$/ ) {
            $curdate = $1;
            $cursuffix = $2;
            if ( ( $curdate ge $from ) and ( $curdate le $to ) ) {
                PublicWhip::Error::log( "Processing XML divisions", $curdate, ERR_USEFUL );
                $lastmajor      = "";
                $lastminor      = "";
                $lastmotiontext = "";
                $lastheadingurl = "";
                $lastheadinggid = "";
                my $file_to_parse = $debatepath . "$fileprefix" . $curdate . $cursuffix . ".xml";
                PublicWhip::Error::log( "File: $file_to_parse", $curdate, ERR_USEFUL );

                $twig_header->parsefile($file_to_parse);
                my $root = $twig_header->root();
                my $in_latest_file = 0;
                if ($root->att('latest') && $root->att('latest') eq "yes") {
                    PublicWhip::Error::log( "File is latest for date", $curdate, ERR_USEFUL );
                    $in_latest_file = 1;
                } elsif ($root->att('latest') && $root->att('latest') eq "no") {
                    PublicWhip::Error::log( "File is old one for date", $curdate, ERR_USEFUL );
                    $in_latest_file = 0;
                } elsif (!$root->att('latest')) {
                    # legacy files
                    PublicWhip::Error::log( "File is legacy file, so is latest for date", $curdate, ERR_USEFUL );
                    $in_latest_file = 1;
                } else {
                    die "unknown attributes in publicwhip tag";
                }
                
                if ($in_latest_file) {
                    $twig->parsefile($file_to_parse);
                }
            }
        }
    }
    closedir DIR;

}

sub array_difference {
    my $array1 = shift;
    my $array2 = shift;

    my @union        = ();
    my @intersection = ();
    my @difference   = ();

    my %count = ();
    foreach my $element ( @$array1, @$array2 ) { $count{$element}++ }
    foreach my $element ( keys %count ) {
        push @union, $element;
        push @{ $count{$element} > 1 ? \@intersection : \@difference },
          $element;
    }
    return \@difference;
}

sub storeminor {
    my ( $twig, $minor ) = @_;

    my $t = $minor->sprint(1);

    $lastminor      = $t;
    $lastmotiontext = "";
    $lastheadingurl = $minor->att('url');
    $lastheadinggid = $minor->att('id');
}

sub storemajor {
    my ( $twig, $major ) = @_;

    my $t = $major->sprint(1);

    # Ignore capital "DEFERRED DIVISION" headings, as they are
    # announced in the middle of other debates and confuse
    # things (the actual votes appear at the end of the days
    # proceedings, with a separate lowercase "deferred division" heading)
    if ( $t =~ m/^\s*DEFERRED DIVISION\s*$/ ) {
        return;
    }

    # 2003-02-26 Iraq debate has a capital title
    # "BUSINESS OF THE HOUSE" which is unimportant
    # and otherwise overwrites the correct title
    if ( $t =~ m/^\s*BUSINESS OF THE HOUSE\s*$/ ) {
        return;
    }

    $lastmajor      = $t;
    $lastminor      = "";
    $lastmotiontext = "";
    $lastheadingurl = $major->att('url');
    $lastheadinggid = $major->att('id');
}

sub storemotion {
    my ( $twig, $p ) = @_;

    if ( $p->att('pwmotiontext') ) {
        $lastmotiontext .= $p->sprint(0);
        $lastmotiontext .= "\n\n";
    }
    if ( $p->att('pwmotionwithdrawn') ) {
        $lastmotiontext = "";
    }
}

# Converts all capital parts of a heading to mixed case
sub fix_case {
    $_ = shift;

    #        print "b:" . $_ . "\n";

    # We work on each hyphen (mdash, &#8212;) separated section separately
    my @parts = split /&#8212;/;
    my @fixed_parts = map( &fix_case_part, @parts );
    $_ = join( " &#8212; ", @fixed_parts );

    s/Orders of the Day &#8212; //;

    #        print "a:" . $_ . "\n";
    return $_;
}

sub fix_case_part {

    # This mainly applies to departmental names for Oral Answers to Questions
    #        print "fix_case_part " . $_ . "\n";

    # if it is all capitals in Hansard
    # e.g. CABINET OFFICE
    if ( !m/[a-z]/ ) {
        s/\s+$//;    # these confuse autoformat into thinking it is a heading...
        s/^\s+//;
        $_ = autoformat $_, { case => 'highlight' };
    }

    # strip trailing/leading spaces (autoformat puts in)
    s/\s+$//;
    s/^\s+//;
    s/\s+/ /g;

    return $_;
}

sub loaddivision {
    my ( $twig, $div ) = @_;

    # Makes heading

    my $divdate = $div->att('divdate');
    die "inconsistent date" if $divdate ne $curdate;
    my $divnumber = $div->att('divnumber');
    my $heading   = "";
    if ($lastmajor) {
        $heading .= fix_case($lastmajor);
    }
    if ($lastmajor && $lastminor) {
        $heading .= " &#8212; ";
    }
    if ($lastminor) {
        $heading .= fix_case($lastminor);
    }

# Should emdashes in headings have spaces round them?  This removes them if they shouldn't.
# $heading =~ s/ \&\#8212; /\&\#8212;/g;

    my $url         = $div->att('url');
    my $gid         = $div->att('id');
    my $debate_url  = $lastheadingurl;
    my $debate_gid  = $lastheadinggid;
    my $motion_text = $lastmotiontext;
    $lastmotiontext = "";
    if ( $motion_text eq "" ) {
        $motion_text = "No motion text available";
    }

    # Find votes of MPs
    my $votes;
    for (
        my $mplist = $div->first_child($house eq 'lords' ? 'lordlist' : 'mplist') ;
        $mplist ;
        $mplist = $mplist->next_sibling($house eq 'lords' ? 'lordlist' : 'mplist')
      )
    {
        for (
            my $mpname = $mplist->first_child($house eq 'lords' ? 'lord' : 'mpname') ;
            $mpname ;
            $mpname = $mpname->next_sibling($house eq 'lords' ? 'lord' : 'mpname')
          )
        {
            my $vote = $mpname->att('vote');
            my $tell = $mpname->att('teller');
            if ( not defined($tell) ) { $tell = ""; }
            elsif ( $tell eq "yes" ) { $tell = "tell"; }
            else { die "unexpected tell value $tell"; }
            my $id = $mpname->att('id');
            if ($house eq 'commons') {
                $id =~ s:uk.org.publicwhip/member/::;
            } else {
                $id =~ s:uk.org.publicwhip/lord/::;
            }
            die "Not an integer MP identifier: $id" if ($id !~ m/^[1-9][0-9]*$/);
            if ($house eq 'lords') {
                $vote = 'aye' if $vote eq 'content';
                $vote = 'no' if $vote eq 'not-content';
            }
            push @{ $votes->{$id} }, "$tell$vote";
        }
    }

    # See if we already have the division
    my $sth = PublicWhip::DB::query(
        $dbh,
"select division_id, valid, division_name, motion, source_url,
debate_url, source_gid, debate_gid from pw_division where
        division_number = ? and division_date = ? and house = ?", $divnumber, $divdate, $house
    );
    die "Division $divnumber on $divdate house $house already in database more than once" if ( $sth->rows > 1 );

    if ( $sth->rows > 0 ) {

        # We already have - update it
        my @data = $sth->fetchrow_array();
        die
"Incomplete division $divnumber, $divdate already exists, clean the database"
          if ( $data[1] != 1 );
        my $existing_divid      = $data[0];
        my $existing_heading    = $data[2];
        my $existing_motion     = $data[3];
        my $existing_source_url = $data[4];
        my $existing_debate_url = $data[5];
        my $existing_source_gid = $data[6];
        my $existing_debate_gid = $data[7];
        if (   ( $existing_heading ne $heading )
            or ( $existing_motion     ne $motion_text )
            or ( $existing_source_url ne $url )
            or ( $existing_debate_url ne $debate_url )
            or ( $existing_source_gid ne $gid )
            or ( $existing_debate_gid ne $debate_gid ) )
        {
            my $sth = PublicWhip::DB::query(
                $dbh,
"update pw_division set division_name = ?, motion = ?, source_url = ?,
debate_url = ?, source_gid = ?, debate_gid = ? where division_id = ? and house = ?",
                $heading,
                $motion_text,
                $url,
                $debate_url,
                $gid,
                $debate_gid,
                $existing_divid,
                $house
            );

            die "Failed to fix division name/motion/URLs" if $sth->rows != 1;
            PublicWhip::Error::log(
"Existing division $house, $divnumber, $divdate, id $existing_divid name $existing_heading has had its name/motion/URLs/gids corrected with the one from XML called $heading",
                $divdate, ERR_IMPORTANT);
            $PublicWhip::DivsXML::divisions_changed = 1;
        }
        else {
            PublicWhip::Error::log(
"Division already in DB for $house division $divnumber on date $divdate",
                $divdate, ERR_USEFUL
            );
        }

        my $sth = PublicWhip::DB::query( $dbh,
"select mp_id, vote from pw_vote where division_id = $existing_divid"
        );
        my $existing_votes;
        while ( @data = $sth->fetchrow_array() ) {
            my $exist_mpid = $data[0];
            my $exist_vote = $data[1];
            if ( $exist_vote eq "both" ) {
                push @{ $existing_votes->{$exist_mpid} }, "aye";
                push @{ $existing_votes->{$exist_mpid} }, "no";
            }
            else {
                push @{ $existing_votes->{$exist_mpid} }, $exist_vote;
            }
        }

        my $differ = 0;

        my @voters          = keys %$votes;
        my @existing_voters = keys %$existing_votes;
        @voters          = sort @voters;
        @existing_voters = sort @existing_voters;
        my $missing = array_difference( \@voters, \@existing_voters );
        my $amount = @$missing;
        if ( $amount > 0 ) {
            PublicWhip::Error::log(
"Voter list differs in XML to one in database - $amount in symmetric diff\n$url"
                  . Dumper($missing),
                , $divdate . " " . $divnumber, ERR_USEFUL
            );
            $differ = 1;
        }

        if ( !$differ ) {
            foreach my $testid (@voters) {
                my $indvotes          = $votes->{$testid};
                my $existing_indvotes = $existing_votes->{$testid};
                @$indvotes          = sort @$indvotes;
                @$existing_indvotes = sort @$existing_indvotes;

                # print $testid, $indvotes, $existing_indvotes, "\n";
                my $missing = array_difference( $indvotes, $existing_indvotes );
                my $amount = @$missing;
                if ( $amount > 0 ) {
                    PublicWhip::Error::log(
"Votes for MP $testid differs between database and XML\n"
                          . "xml "
                          . Dumper($indvotes) . "\n" . "db "
                          . Dumper($existing_indvotes) . "\n",
                        $curdate, ERR_USEFUL
                    );
                    $differ = 1;
                }
            }
        }

        if ($differ) {

            # Remove existing division we're correcting
            my $sth = PublicWhip::DB::query(
                $dbh, "delete from pw_division where
                division_number = ? and division_date = ? and house = ?", $divnumber, $divdate, $house
            );
            die "Deleted not one old version of division but "
              . $sth->rows
              . " for $house $divnumber on $divdate"
              if ( $sth->rows != 1 );
            PublicWhip::Clean::erase_duff_divisions($dbh);
        }
        else {

            # We already have the correct division
            return;
        }
    }

    #print "new division $house $divdate $divnumber $heading\n";

    # Add division to tables
    PublicWhip::DB::query(
        $dbh, "insert into pw_division 
        (valid, division_date, division_number, house, division_name,
        source_url, debate_url, source_gid, debate_gid, motion) values
        (0, ?, ?, ?, ?, ?, ?, ?, ?, ?)", $divdate, $divnumber, $house, $heading, $url,
        $debate_url, $gid, $debate_gid,           $motion_text
    );
    $sth = PublicWhip::DB::query( $dbh, "select last_insert_id()" );
    die "Failed to get last insert id for new division" if $sth->rows != 1;
    my @data        = $sth->fetchrow_array();
    my $division_id = $data[0];

    foreach my $mp_id ( keys %$votes ) {
        my $votelist = $votes->{$mp_id};
        foreach my $vote (@$votelist) {
            PublicWhip::DB::query(
                $dbh,
                "insert into pw_vote (division_id, mp_id, vote) values (?,?,?)",
                $division_id,
                $mp_id,
                $vote
            );
        }
    }

    # Confirm change (this should be done with transactions, but I don't
    # want to get into them as web providers I want to use may not offer
    # support for that db type in mysql)
    PublicWhip::DB::query( $dbh,
        "update pw_division set valid = 1 where division_id = ?",
        $division_id );
    PublicWhip::Error::log( "Added new division $house $divnumber $heading from XML",
        $divdate, ERR_IMPORTANT );
    $PublicWhip::DivsXML::divisions_changed = 1;
}

1;
