# $Id: divisions.pm,v 1.3 2003/09/12 09:41:43 frabcus Exp $
# Parses the body text of a page of Hansard containing a division.
# Records the division and votes in a database, matching MP names
# to an MP already in the database.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package divisions;
use strict;

use HTML::TokeParser;
use Date::Parse;
use Text::Autoformat;

use db;
use mputils;
use error;

our $last_heading;
our $source_url;

# Parameters are:
# $dbh - database session
# $content - HTML page to scan for divisions
# $day_date - date of the page
sub parse_all_divisions_on_page
{
    my $dbh = shift;
    my $content = shift;
    my $day_date = shift;

    # Special case for division 114, 14 March 2003 where the names are
    # bunched together on one line.  Yeuch.  The regexps fix this in a
    # fairly nasty way.  
    if ($day_date eq "2003-03-14")
    {
        $content =~ s/([a-z])([A-Z])/$1<br>\n$2/g;
        $content =~ s/(\)\<\/i\>)([A-Z])/$1<br>\n$2/g;
        error::log("Patched a bad case of line bunching", $day_date, error::IMPORTANT);
    }
    # Another nasty nasty day.
    if ($day_date eq "2003-09-10")
    {
        $content =~ s/([a-bd-z])([A-Z])/$1<br>\n$2/g; # no c for "Mc" names
        $content =~ s/(\)\<\/i\>)([A-Z])/$1<br>\n$2/g;
        $content =~ s/Brook, Mrs Annette L\.Bruce, Malcolm/Brooke, Mrs Annette<br>Bruce, Malcolm/;
        $content =~ s/Donaldson, Jeffrey M.Doughty, Sue/Donaldson, Jeffrey M.<br>Doughty, Sue/;
        $content =~ s/Baird Vera/Baird, Vera/;
        $content =~ s/Brown, Russell,/Brown, Russell/;
        $content =~ s/EricMeale/Eric<br>Meale/;
        error::log("Patched a dot terminated bunch", $day_date, error::IMPORTANT);
    }
    # Similar but less severe one for division 60, 23 January 2003
    if ($day_date eq "2003-01-23")
    {
        $content =~ s/Cameron, DavidCash, William/Cameron, David<br>Cash, William/;
        error::log("Patched a bad day 23 January 2003", $day_date, error::IMPORTANT);
    }
    # And again for division 4, 20 November 2002
    if ($day_date eq "2002-11-20")
    {
        $content =~ s/Sheridan, JimSimon,/Sheridan, Jim<br>Simon,/;
        error::log("Patched a bad day 20 November 2002", $day_date, error::IMPORTANT);
    }
    # Yeuch, even more evil! 27 November 2002
    if ($day_date eq "2002-11-27")
    {
        $content =~ s/(.*,.*)/<br>$1/g;
        # The Gareth Thomas's here aren't ambiguous despite missing
        # constituencies, as both voted and they voted the same!
        $content =~ s/Thomas, Gareth\n<br>Thomas, Gareth/Thomas, Gareth (Clwyd West)<br>Thomas, Gareth (Harrow West)/;
        error::log("Patched a bad day 27 November 2002", $day_date, error::IMPORTANT);
    }
    # Fix ambiguous Gareth Thomas, info as to which provided by email
    # via House of Commons Information Office.
    if ($day_date eq "2003-01-20")
    {
        $content =~ s/Thomas, Gareth\n/Thomas, Gareth (Harrow West)/;
        error::log("Disambiguated a Gareth Thomas", $day_date, error::IMPORTANT);
    }
    # Comma missing and "Barron" misspelling typo 5 December 2001
    if ($day_date eq "2001-12-05")
    {
        $content =~ s/Baron Kevin/Barron, Kevin/;
        error::log("Patched a bad day 5 December 2001", $day_date, error::IMPORTANT);
    }
    # Another for 16 July 2001
    if ($day_date eq "2001-07-16")
    {
        $content =~ s/\n/\n<br>/g;
        error::log("Patched a bad day 16 July 2001", $day_date, error::IMPORTANT);
    }

    my $p = HTML::TokeParser->new(\$content);

    $last_heading = "";
    $source_url = "";
    my $continue = 1;
    my $ok = 1;
    while($continue)
    {
        # Parse division, trapping fatal errors
        eval
        {
            $continue = divisions::parse_one_division($dbh, $p, $day_date);
        };
        if ($@)
        {
            $ok = 0;
            if ($@ !~ m/ESCAPE_FROM_DIV_PARSE/)
            {
                error::die_print($@, $day_date . " " . $source_url);
            }
        }
    }

    # Record that we are done - extracted all divisions from here
    if ($ok)
    {
        db::query($dbh, "update pw_debate_content set divisions_extracted = 1 where day_date = ?", $day_date);
    }
}

sub parse_one_division
{
    my $dbh = shift;
    my $p = shift;
    my $day_date = shift;

    # Find next division, and get its number and name:
    # <B>Division No. 217</B>
    my $division_number;
    my $last_subheading = "";
    my $last_anchor = "";
    my $last_token;
    my $motion_text = "";
    while(1)
    {   
        my $token = $p->get_token() or return 0;
        my $amendment_move = ($token->[0] eq "T" and $token->[1] =~ m/I beg to move/) ? 1 : 0;

        if ($token->[0] eq "C")
        {
            $_ = $token->[1];
            # We find comments with the original source pages in
            # our amalgamated entire-day content pages.
            if (m/Public Whip source (.*) /)
            {
                $source_url = $1;
            }
        }
        elsif ($token->[0] eq "S" and 
            ($token->[1] eq "center"
            or ($token->[1] eq "h3" and $token->[2]{align} and $token->[2]{align} eq "center"))
            )
        {
            my $startwas = $token->[1];

            # We've found a title
            $token = $p->get_token(); # skip <b> token if there is one
            $p->unget_token($token) if ($token->[0] eq "T");
            my $text = $p->get_trimmed_text("/" . $startwas);
            error::log("Title scan: $text", $day_date, error::CHITTER);

            # See if it is a division number
            if ($text =~ m/^Division No. ([0-9]+)$/)
            {
                $division_number = $1;
                last;
            }
            # Ignore capital "DEFERRED DIVISION" headings, as they are
            # announced in the middle of other debates and confuse
            # things (the actual votes appear at the end of the days
            # proceedings, with a separate lowercase "deferred division" heading)
            elsif ($text !~ m/DEFERRED DIVISION/)
            {
                # Otherwise store it as the subject of a division
                # is the name of the previous title to the division 
                if ($text !~ m/[[:lower:]]/)
                {
                    # 2003-02-26 Iraq debate has a capital title
                    # "BUSINESS OF THE HOUSE" which is unimportant
                    # and otherwise overwrites the correct title
                    if ($text !~ m/BUSINESS OF THE HOUSE/) 
                    {
                        # If all upper case then it is a super heading,
                        # which we lowercase first of all
                        $text = autoformat $text, { case => 'highlight' };
                        # strip trailing/leading spaces autoformat puts in...
                        $text =~ s/^\s+//;
                        $text =~ s/\s+$//;
                        $last_heading = $text;
                        $motion_text = "";
                        $last_subheading = "";
                    }
                }
                elsif ($last_anchor =~ m/head/)
                {
                    # If it is in an anchor tag name with "head" in
                    # it, then also a super heading
                    $last_heading = $text;
                    $motion_text = "";
                    $last_subheading = "";
                }
                else
                {
                    # else... subheading
                    $last_subheading = $text;
                }
                $last_anchor = "";
            }
        }
        elsif ($token->[0] eq "S" and $token->[1] eq "a")
        {
            $last_anchor = $token->[2]{name} if $token->[2]{name};
        }
        # Heuristics to find the text which contains the motion, and to
        # ignore things like quotations in the debate, names of
        # newspapers in italics and so on
        elsif (($token->[0] eq "S" and $token->[1] eq "i" and $last_token->[0] eq "C")
            or ($token->[0] eq "S" and $token->[1] eq "font" and $token->[2]{size} eq "-1")
            or $amendment_move)
        {
            my $text = "";
            my $allow_quote = 0;
            if ($amendment_move)
            {
                $text = $token->[1];
                $allow_quote = 1;
            }

            # Extract all text up until the next <p> or <center> tag
            my $met_end = 0;
            while(1)
            {
                my $local_token = $p->get_token() or return 0;
                if ($local_token->[0] eq "T")
                {
                    $_ = $local_token->[1];
                    if ($_ ne "")
                    {
                        $text .= $_;
                        print "Has no content\n" if $_ eq "";

                    }
                }
                elsif ($local_token->[0] eq "S" and $met_end)
                {
                    if ($local_token->[1] eq "center" or $local_token->[1] eq "p" or $local_token->[1] eq "a")
                    {
                        $p->unget_token($local_token); 
                        last;
                    }
                }
                elsif ($local_token->[0] eq "S" and $local_token->[1] eq "p")
                {
                    $text .= "<p>";
                }
                elsif ($local_token->[0] eq "E" and not $met_end)
                {
                    if ($local_token->[1] eq $token->[1] or $amendment_move)
                    {
                        $met_end = 1;
                    }
                }
                if ($local_token->[0] eq "S" or $local_token->[0] eq "E")
                {
                    $text .= " ";
                }
            }
            # Ignore quotations (whether start or end of them),
            # except amendments (just after "I beg to move") have quotes
            my $plaintext = $text;
            $plaintext =~ s/<(([^ >]|\n)*)>//g;
            # For some reason capital X appears instead of quotes
            # (e.g. on 2002-11-25)
            if ($allow_quote or ($plaintext !~ m/^\s*["'X]/ and $plaintext !~ m/["']\.?\s*$/))
            {
                $met_end = 1 if ($amendment_move);
                $allow_quote = 0;

                $motion_text .= "<p>" . $text;
                # Remove duplicate adjacent paragraph markers
                while ($motion_text =~ s/\<p\>\s*\<p\>/\<p\>/g)
                {
                }
            }
        }
        $last_token = $token;
     }
    die "Couldn't find source URL" if $source_url eq "";
    die "Couldn't find division heading" if $last_heading eq "";
    my $division_name = $last_heading;
    $division_name .= " - " . $last_subheading if $last_subheading ne "";

    # See if we already have the division
    my $sth = db::query($dbh, "select division_id, valid, division_name from pw_division where
        division_number = ? and division_date = ?",
        $division_number, $day_date);

    die "Division $division_number on $day_date already in database more than once" if ($sth->rows > 1);
    if ($sth->rows > 0)
    { 
        my @data = $sth->fetchrow_array();
        die "Incomplete division $division_number, $day_date already exists, clean the database" if ($data[1] != 1);
        if ($data[2] ne $division_name)
        {
            db::query($dbh, "update pw_division set division_name = ? where division_id = ?", $division_name, $data[0]);
            error::log("Existing division $division_number, $day_date, " . $data[2] . " has had its name corrected with the one we have found called $division_name", $day_date, error::USEFUL);
        }
        else
        {
            error::log("Division already in DB for division $division_number on date $day_date", $day_date, error::USEFUL);
        }
        return 1;
    }
    
    # Add division to tables
    db::query($dbh, "insert into pw_division 
        (valid, division_date, division_number, division_name, source_url, motion) values
        (0, ?, ?, ?, ?, ?)", $day_date, $division_number, $division_name, $source_url, $motion_text);
    $sth = db::query($dbh, "select last_insert_id()");
    die "Failed to get last insert id for new division" if $sth->rows != 1;
    my @data = $sth->fetchrow_array();
    my $division_id = $data[0];

    # Can add an AYE or a NOE
    local *add_name = sub
    {
        my $name = shift;
        my $isaye = shift;
        
        my ($firstname, $lastname, $title, $constituency) = mputils::parse_formal_name($name);
#        error::log("MP parse: $firstname/$lastname/$title --- $constituency", $day_date, error::CHITTER);

        my $mp_id = mputils::find_mp($dbh, $firstname, $lastname, $title, $constituency, $day_date);

        db::query($dbh, "insert into pw_vote (division_id, mp_id, vote) 
            values (?,?,?)", 
            $division_id, $mp_id, $isaye ? "aye" : "noe");
        error::log("MP parse found: $mp_id $firstname $lastname", $day_date, error::CHITTER);
    };

    my $reuselast = undef;
    local *aye_or_noe_scan = sub
    {
        my $teller_tag;
        my $isaye;

        # Find start of aye/noe
        while (1)
        {
            if (defined $reuselast)
            {
                $_ = $reuselast;
                undef $reuselast;
            }
            else
            {
                my $token = $p->get_tag("br") or die "Couldn't find AYE/NOE";
                $_ = $p->get_trimmed_text("p");
            }

            error::log("Aye/no scan: $_\n", $day_date, error::CHITTER);
            if (m/AYES/)
            {
                $teller_tag = "Ayes";
                $isaye = 1;
                last;
            }
            if (m/NOES/)
            {
                $teller_tag = "Noes";
                $isaye = 0;
                last;
            }
        }
        
        # Parse votes
        while (1)
        {
            my $token = $p->get_tag("br", "p") or die "Couldn't find vote end";
            $_ = $p->get_trimmed_text();
            my $t = $p->get_token();
            if ($t->[0] eq "S" && $t->[1] eq "i")
            {
                $_ .= " " if ($_ ne "");
                $_ .= $p->get_trimmed_text("/i");
            }
            else
            {
                $p->unget_token($t);
            }

            next if $_ eq "";
            last if m/Tellers for the $teller_tag/;
            if (m/AYES/ or m/NOES/ or m/Question accordingly/)
            {
                $reuselast = $_;
                error::warn("No tellers, check correct parsing of division $division_number",
                     $day_date);
                last;
            }
            if (m/^\((.+)\)$/)
            {
                error::log("Hit and ignored a lone constituency $_", $day_date, error::CHITTER);
                next;
            }

            add_name($_, $isaye);
        }

        return $isaye;
    };

    my $aye_first = aye_or_noe_scan();
    my $aye_second = aye_or_noe_scan();
    die "Double AYE or double NOE" if ($aye_first == $aye_second);

    # Confirm change (this should be done with transactions, but I don't
    # want to get into them as web providers I want to use may not offer
    # support for that db type in mysql)
    db::query($dbh, "update pw_division set valid = 1 where division_id = ?", $division_id);
    error::log("Added new division $division_number $division_name", $day_date, error::IMPORTANT);

    return 1;
}

1;
