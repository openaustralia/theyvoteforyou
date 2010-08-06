# $Id: DivsXML.pm,v 1.20 2010/08/06 16:27:14 publicwhip Exp $
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
our @speechesbefore;

our $divisions_changed;

our $house;

our %spmotions;
our $lastlongestspid;
our $spsubject;

sub read_xml_files {
    $dbh = shift;
    my $from = shift;
    my $to   = shift;
    my $debatepath = shift;
    my $fileprefix  = shift;
    $house  = shift; # global
    my $motionspath;
    if( $house eq "scotland" ) {
        $motionspath = shift;
    }
    die if $house ne "lords" && $house ne "commons" and $house ne "scotland";

    %spmotions = ();
    if ($house eq "scotland") {
        print "Loading SP motions...\n";
        # If this for the Scottish Parliament, parse all the motions
        # with SPIDs:
        my $twig_sp_motions = XML::Twig->new( twig_handlers => {
            'spmotion'  => \&loadspmotion },
                              output_filter => 'safe' );
        my @motionsfiles = glob($motionspath . "*.xml");
        foreach( @motionsfiles ) {
            $twig_sp_motions->parsefile($_);
        }
        print "done.\n";
    }

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
                @speechesbefore = ();
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
    @speechesbefore = ();
    $lastheadingurl = $minor->att('url');
    $lastheadinggid = $minor->att('id');
    $lastlongestspid = "";
    $spsubject = "";
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
    @speechesbefore = ();
    $lastheadingurl = $major->att('url');
    $lastheadinggid = $major->att('id');
    $lastlongestspid = "";
    $spsubject = "";
}

sub storemotion {
    my ( $twig, $p ) = @_;

    if ( $p->att('pwmotiontext') ) {
        if ( $p->att('pwmotiontext') eq "withdrawn" || $p->att('pwmotiontext') eq "agreedto") {
            $lastmotiontext = "";
        } else {
            $lastmotiontext .= $p->sprint(0);
            $lastmotiontext .= "\n\n";
        }
    }

    if ( $house eq "scotland" ) {
	# If this is a paragraph from a Scottish Parliament debate
	# then we want to look for IDs of the form S[0-9]M-[0-9\.]+ so
	# that we can use that key to extract further information
	# about the motion from the XML.
	#
	# The longest of these is likely to be the ID acutally
	# referred to, since descriptions of amendments include both,
	# and the amendment IDs are formed by adding .1, .2, etc. to
	# the ID.
	my $ptext = $p->sprint(0);
	my @matches = $ptext =~ /S[0-9]M-[0-9\.]+/g;
	my $longestinthis = "";
	foreach my $match (@matches) {
	    if (length($match) >= length($longestinthis)) {
		$longestinthis = $match;
	    }
	}
	if ($longestinthis) {
	    $lastlongestspid = $longestinthis;
	}
	push @speechesbefore, $ptext;
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
    #print "---- $divdate --- $house --------------------------\n";
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
    if ($lastlongestspid) {
	my $amendment = "";
	if ($lastlongestspid =~ /\./) {
	    $amendment = " (Amendment)";
	}
	$heading = "[$lastlongestspid$amendment] $heading";
    }
    if ($spsubject) {
	$heading .= " &#8212; $spsubject";
    }

# Should emdashes in headings have spaces round them?  This removes them if they shouldn't.
# $heading =~ s/ \&\#8212; /\&\#8212;/g;

    my $url         = $div->att('url');
    my $gid         = $div->att('id');
    my $debate_url  = $lastheadingurl;
    my $debate_gid  = $lastheadinggid;
    my $motion_text = $lastmotiontext;
    my $clock_time = $div->att('time');
    $lastmotiontext = "";
    if ($house eq 'scotland') {
        $motion_text = join("\n\n",@speechesbefore[-3..-1]);
        if ($lastlongestspid) {
            my $prefix_with = "<p>This looks like the vote on $lastlongestspid</p>";
            if (exists $spmotions{$lastlongestspid}) {
                my $motionsref = $spmotions{$lastlongestspid};
                my @motions = @{$motionsref};
                foreach (@motions) {
                    my %motion = %{$_};
                    $prefix_with .= "<p>The description in the <a href=\"$motion{'url'}\">bulletin on $motion{'date'}</a> is:</p>";
                    $prefix_with .= "<p class=\"bulletin-quote\">$motion{'text'}</p>";
                }
            }
            $prefix_with .= "<p>You can <a href=\"http://www.theyworkforyou.com/search/?s=&phrase=";
            $prefix_with .= $lastlongestspid;
            $prefix_with .= "&exclude=&from=$divdate&to=$divdate\">search for this motion (";
            $prefix_with .= $lastlongestspid.") on TheyWorkForYou</a></p>";
            $prefix_with .= "<p><b>Text Introducing Division:</b></p>";
            if ($motion_text eq "") {
                $motion_text = $prefix_with . "<p>No text found</p>";
            } else {
                $motion_text = $prefix_with . "<p>$motion_text</p>";
            }
        }
    }
    if ($motion_text eq "") {
        $motion_text = "<p>No motion text available</p>";
    }

    $clock_time = "" if !$clock_time;
    if ($clock_time =~ m/^\d\d:\d\d:\d\d$/) {
        $clock_time = "0" . $clock_time; # 3 digit hours due to >24 hour days that parliament sometimes has
    }
    if ($clock_time !~ m/^\d\d\d:\d\d:\d\d$/) {
        PublicWhip::Error::warn("clock time '$clock_time' not in right format");
        $clock_time = '';
    }

    my $listeltname = 'mplist';
    $listeltname = 'lordlist' if $house eq 'lords';
    $listeltname = 'msplist' if $house eq 'scotland';

    my $votereltname = 'mpname';
    $votereltname = 'lord' if $house eq 'lords';
    $votereltname = 'mspname' if $house eq 'scotland';

    # Find votes of MPs
    my $votes;
    for (
        my $mplist = $div->first_child($listeltname) ;
        $mplist ;
        $mplist = $mplist->next_sibling($listeltname)
      )
    {
        for (
            my $mpname = $mplist->first_child($votereltname) ;
            $mpname ;
            $mpname = $mpname->next_sibling($votereltname)
          )
        {
            my $vote = $mpname->att('vote');
            my $tell = $mpname->att('teller');
            if ( not defined($tell) ) { $tell = ""; }
            elsif ( $tell eq "yes" ) { $tell = "tell"; }
            else { die "unexpected tell value $tell"; }
            my $id = $mpname->att('id');
            if ($house eq 'commons' or $house eq 'scotland') {
                $id =~ s:uk.org.publicwhip/member/::;
            } else {
                $id =~ s:uk.org.publicwhip/lord/::;
            }
            die "Not an integer MP identifier: $id" if ($id !~ m/^[1-9][0-9]*$/);
            if ($house eq 'lords') {
                $vote = 'aye' if $vote eq 'content';
                $vote = 'no' if $vote eq 'not-content';
            } elsif ($house eq 'scotland') {
		$vote = 'aye' if $vote eq 'for';
		$vote = 'no' if $vote eq 'against';
		$vote = 'abstention' if $vote eq 'abstentions';
		$vote = 'spoiled' if $vote eq 'spoiled votes';
	    }
            push @{ $votes->{$id} }, "$tell$vote";
        }
    }

    # print "searching for divnumber $divnumber divdate $divdate house $house\n";

    # See if we already have the division
    my $sth = PublicWhip::DB::query(
        $dbh,
"select division_id, valid, division_name, motion, source_url,
debate_url, source_gid, debate_gid, clock_time from pw_division where
        division_number = ? and division_date = ? and house = ?", $divnumber, $divdate, $house
    );
    die "Division $divnumber on $divdate house $house already in database more than once" if ( $sth->rows > 1 );

    if ( $sth->rows > 0 ) {

	# print "Already have that one...\n";

        # We already have - update it
        my @data = $sth->fetchrow_array();
        die "Incomplete division $divnumber, $divdate already exists, clean the database" if ( $data[1] != 1 );
        my $existing_divid      = $data[0];
        my $existing_heading    = $data[2];
        my $existing_motion     = $data[3];
        my $existing_source_url = $data[4];
        my $existing_debate_url = $data[5];
        my $existing_source_gid = $data[6];
        my $existing_debate_gid = $data[7];
        my $existing_clock_time = $data[8];
        $existing_clock_time = "" if !$existing_clock_time;

        # Extra debugging, since I'm not sure why these differ:

        #if ($existing_heading ne $heading) {
        #    print "####! Difference heading between\n == $existing_heading\n == $heading\n";
        #}
        #if ($existing_motion ne $motion_text) {
        #    print "####! Difference motion between\n == $existing_motion\n == $motion_text\n";
        #}
        #if ($existing_source_url ne $url) {
        #    print "####! Difference url between\n == $existing_source_url\n == $url\n";
        #}
        #if ($existing_debate_url ne $debate_url) {
        #    print "####! Difference debate between\n == $existing_debate_url\n == $debate_url\n";
        #}
        #if ($existing_source_gid ne $gid) {
        #    print "####! Difference gid between\n == $existing_source_gid\n == $gid\n";
        #}
        #if ($existing_debate_gid ne $debate_gid) {
        #    print "####! Difference debate_gid between\n == $existing_debate_gid\n == $debate_gid\n";
        #}
        #if ($existing_clock_time ne $clock_time) {
        #    print "####! Difference clock time between\n == $existing_clock_time\n == $clock_time\n";
        #}

        if (   ( $existing_heading ne $heading )
            or ( $existing_motion     ne $motion_text )
            or ( $existing_source_url ne $url )
            or ( $existing_debate_url ne $debate_url )
            or ( $existing_source_gid ne $gid )
            or ( $existing_debate_gid ne $debate_gid ) 
            or ( $existing_clock_time ne $clock_time) )
        {
            my $sth = PublicWhip::DB::query(
                $dbh,
"update pw_division set division_name = ?, motion = ?, source_url = ?,
debate_url = ?, source_gid = ?, debate_gid = ?, clock_time = ? where division_id = ? and house = ?",
                $heading,
                $motion_text,
                $url,
                $debate_url,
                $gid,
                $debate_gid,
                $clock_time,
                $existing_divid,
                $house
            );

            die "Failed to fix division name/motion/URLs/clock" if $sth->rows != 1;
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
	    # print "They don't differ...\n";
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
	    # print "There was a difference...\n";
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
	    # print "There was a difference...\n";
            # We already have the correct division
            return;
        }
    }

    #print "new division $house $divdate $divnumber $heading\n";
    #print "going to insert\n";

    #print "divdate is: $divdate\n";
    #print "divnumber is: $divnumber\n";
    #print "house is $house\n";
    #print "heading is $heading\n";
    #print "url is $url\n";
    #print "debate_url is $debate_url\n";
    #print "gid is $gid\n";
    #print "debate_gid is $debate_gid\n";
    #print "motion_text is $motion_text\n";
    #print "clock_time    is $clock_time   \n";

    # Add division to tables
    PublicWhip::DB::query(
        $dbh, "insert into pw_division 
        (valid, division_date, division_number, house, division_name,
        source_url, debate_url, source_gid, debate_gid, motion, clock_time) values
        (0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", $divdate, $divnumber, $house, $heading, $url,
        $debate_url, $gid, $debate_gid, $motion_text, $clock_time
    );
    $sth = PublicWhip::DB::query( $dbh, "select last_insert_id()" );
    die "Failed to get last insert id for new division" if $sth->rows != 1;
    my @data        = $sth->fetchrow_array();
    my $division_id = $data[0];

    foreach my $mp_id ( keys %$votes ) {
	# print "Considering mp_id $mp_id\n";
        my $votelist = $votes->{$mp_id};
        foreach my $vote (@$votelist) {
	    # print "  Considering vote $vote\n";
	    # print "  Division ID $division_id\n";
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

sub loadspmotion {
    my ( $twig, $motion ) = @_;

    my %m = ();
    my $spid = $motion->att('spid');
    $m{'spid'} = $spid;
    $m{'date'} = $motion->att('date');
    $m{'url'}  = $motion->att('url');
    $m{'text'} = $motion->text;

    if( exists $spmotions{$spid} ) {
	my $existingref = $spmotions{$spid};
	push(@{$existingref},\%m);
    } else {
	my @newarray = ();
	push(@newarray,\%m);
	$spmotions{$spid} = \@newarray;
    }
}

1;
