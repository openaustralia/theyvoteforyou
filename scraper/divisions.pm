# $Id: divisions.pm,v 1.11 2003/11/30 18:34:00 frabcus Exp $
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

    #######################################################################
    # General stuff (done before special case)

    if ($content =~ s/\r//g)
    {
        error::log("Converted from Windows to Unix line feeds", $day_date, error::USEFUL);
    }
    
    #######################################################################
    # Special case fixes

    if ($day_date eq "2003-03-14" )
    {
        # Names bunched together on one line, fix it in a fairly crude manner
        $content =~ s/([a-z])([A-Z])/$1<br>\n$2/g;
        $content =~ s/(\)\<\/i\>)([A-Z])/$1<br>\n$2/g;
        error::log("Patched a bad case of line bunching", $day_date, error::USEFUL);
    }
    if ($day_date eq "2003-10-27")
    {
        $content =~ s/([a-bd-z])([A-Z])/$1<br>\n$2/g; # no c for "Mc" names
        $content =~ s/(\)\<\/i\>)([A-Z])/$1<br>\n$2/g;
        $content =~ s/Widdecombe, rh Miss/Widdecombe, rh Ann/g;
        $content =~ s/Cook, rh Robin <i>Livingston\)<\/i>/Cook, rh Robin <i>(Livingston)<\/i>/g;
        $content =~ s/A. J.Bell/A. J.<br>Bell/g;
        $content =~ s/Annette L.Brown/Annette L.<br>Brown/g;
        $content =~ s/Dunwoody, Mrs/Dunwoody, Gwyneth/g;
        error::log("Patched a case of line bunching", $day_date, error::USEFUL);
    }
    if ($day_date eq "2003-09-10")
    {
        $content =~ s/([a-bd-z])([A-Z])/$1<br>\n$2/g; # no c for "Mc" names
        $content =~ s/(\)\<\/i\>)([A-Z])/$1<br>\n$2/g;
        $content =~ s/Brook, Mrs Annette L\.Bruce, Malcolm/Brooke, Mrs Annette<br>Bruce, Malcolm/;
        $content =~ s/Donaldson, Jeffrey M.Doughty, Sue/Donaldson, Jeffrey M.<br>Doughty, Sue/;
        $content =~ s/Baird Vera/Baird, Vera/;
        $content =~ s/Brown, Russell,/Brown, Russell/;
        $content =~ s/EricMeale/Eric<br>Meale/;
        error::log("Patched a non terminated bunch", $day_date, error::USEFUL);
    }
    if ($day_date eq "2003-01-23")
    {
        $content =~ s/Cameron, DavidCash, William/Cameron, David<br>Cash, William/;
        error::log("Patched missing line break", $day_date, error::USEFUL);
    }
    if ($day_date eq "2002-11-20")
    {
        $content =~ s/Sheridan, JimSimon,/Sheridan, Jim<br>Simon,/;
        error::log("Patched missing line break", $day_date, error::USEFUL);
    }
    if ($day_date eq "2002-11-27")
    {
        $content =~ s/(.*,.*)/<br>$1/g;
        # The Gareth Thomas's here aren't ambiguous despite missing
        # constituencies, as both voted and they voted the same!
        $content =~ s/Thomas, Gareth\n<br>Thomas, Gareth/Thomas, Gareth (Clwyd West)<br>Thomas, Gareth (Harrow West)/;
        error::log("Patched a bad day 27 November 2002", $day_date, error::USEFUL);
    }
    if ($day_date eq "2001-12-05")
    {
        $content =~ s/Baron Kevin/Barron, Kevin/;
        error::log("Patched a bad day 5 December 2001", $day_date, error::USEFUL);
    }
    if ($content =~ s/Johnson Smith, ?\n<[Bb][Rr]>\n? Rt Hon Sir Geoffrey/Johnson Smith, Rt Hon Sir Geoffrey/g)
    {
        error::log("Patched at least one misformatted Geoffrey Johnson Smith", $day_date, error::USEFUL);
    }
    if ($day_date eq "1997-06-18")
    {
        $content =~ s/Norris Dan/Norris, Dan/g;
        error::log("Patched missing comma", $day_date, error::USEFUL);
    }
    if ($day_date eq "1998-10-21")
    {
        $content =~ s/Paige, Richard/Page, Richard/;
        error::log("Patched mispelt name", $day_date, error::USEFUL);
    }
    if ($day_date eq "2000-11-13")
    {
        $content =~ s/Field, Rt Hon Frank Fisher, Mark/Field, Rt Hon Frank\n<br>\nFisher, Mark/;
        error::log("Patched missing line break", $day_date, error::USEFUL);
    }
    if ($day_date eq "1997-07-08")
    {
        $content =~ s/Temple-Morris,Peter/Temple-Morris, Peter/;
        error::log("Patched missing space", $day_date, error::USEFUL);
    }
    if ($day_date eq "2000-03-15")
    {
        $content =~ s/Winterton, Ms Rosie <i>\n Doncaster C\)<\/i>/Winterton, Ms Rosie <i>(Doncaster C)<\/i>/;
        error::log("Patched missing open bracket", $day_date, error::USEFUL);
    }
    if ($day_date eq "1998-03-10")
    {
        $content =~ s/\(<i>Aldershot<\/i>\)/<i>(Aldershot)<\/i>/;
        error::log("Italics replaced round brackets", $day_date, error::USEFUL);
    }
    if ($day_date eq "2003-10-15")
    {
        $content =~ s/item>Mercer, Patrick/Mercer, Patrick/;
        error::log("Removed spurious text before name", $day_date, error::USEFUL);
    }
    if ($day_date eq "2003-11-18")
    { 
        # See Hansard bug: 
        # http://sourceforge.net/tracker/index.php?func=detail&aid=846654&group_id=87640&atid=602722
        $content =~s/\n, David\n/\nBorrow, David\n/;
        error::log("Fixed missing Borrow", $day_date, error::USEFUL);
    }

    #######################################################################
    # Errata
    
    # Fix ambiguous Gareth Thomas, info as to which provided by email
    # via House of Commons Information Office.
    if ($day_date eq "2003-01-20")
    {
        $content =~ s/Thomas, Gareth\n/Thomas, Gareth (Harrow West)/;
        error::log("Disambiguated a Gareth Thomas", $day_date, error::USEFUL);
    }

    #######################################################################
    # General purpose fixes (done after special case)
    
    # Another for various times, when the <br> tags are missing
    # Name on two lines (split just before constituency) when should be on one
    if ($content =~ s:\n<[Bb][Rr]>\n ?<i>(\([\w ]+?\))</i>: <i>$1</i>:g)
    {
        error::log("Patched at least one constituency on wrong line (italic)", $day_date, error::USEFUL);
    }
    if ($content =~ s:\n<[Bb][Rr]>\n (\([\w ]+?\)): $1:g)
    {
        error::log("Patched at least one constituency on wrong line (no italic)", $day_date, error::USEFUL);
    }
    if ($content =~ s:\n <i>(\([\w ]+?\))</i>: <i>$1</i>:g)
    {
        error::log("Patched at least one constituency on wrong line (italic no br)", $day_date, error::USEFUL);
    }
    # This is perhaps too sweeping a regexp, but it does the job -
    # replace any newlines with a <br>
    if ($content =~ s/\n/\n<br>\n/g)
    {
        error::log("Patched missing <br> tags", $day_date, error::USEFUL);
    }
    #print $content;

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

    # Can add an AYE or a NO
    local *add_name = sub
    {
        my $name = shift;
        my $isaye = shift;
        my $isteller = shift;

        my $vote;
        if ($isteller)
        {
            $vote = $isaye ? "tellaye" : "tellno";
        }
        else
        {
            $vote = $isaye ? "aye" : "no";
        }
        
        my ($firstname, $lastname, $title, $constituency) = mputils::parse_formal_name($name);
        my $mp_id = mputils::find_mp($dbh, $firstname, $lastname, $title, $constituency, $day_date);

        error::log("MP parse found: $mp_id $firstname $lastname", $day_date, error::CHITTER);
        db::query($dbh, "insert into pw_vote (division_id, mp_id, vote) 
            values (?,?,?)", 
            $division_id, $mp_id, $vote);
    };

    my $reuselast = undef;
    local *aye_or_no_scan = sub
    {
        my $teller_tag;
        my $isaye;

        # Find start of aye/no
        while (1)
        {
            if (defined $reuselast)
            {
                $_ = $reuselast;
                undef $reuselast;
            }
            else
            {
                my $token = $p->get_tag("br") or die "Couldn't find AYES/NOES";
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
        my $isteller = 0;
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
            error::log("Division parser: $_", $day_date, error::CHITTER);

            next if $_ eq "";
            if (m/AYES/ or m/NOES/ or m/accordingly/ or m/40 Members/ or
                m/Resolved,/ or 
                m/We will have the result/ or # 2002-01-28, due to error at end of division
                m/Question had not been decided in the affirmative/ or #2001-05-02
                m/accordingy/ or # "accordingly" is typoed on 2001-01-10 as "accordingy"
                m/Question was not decided in the affirmative/ or # 2000-04-14 
                m/the only reason that the Division was inquorate was that/ or #1999-05-21 (although there is some other bug in this code meaning the italic paragraph above isn't picked up on)
                m/That this House doth disagree with the Lords in the said amendment/ or #1997-07-30 (similar problem to just above)
                m/That three be the Quorum/ #1997-07-30
                )
            {
                $reuselast = $_;
                last;
            }
            if (m/^\((.+)\)$/)
            {
                error::log("Hit and ignored a lone constituency $_", $day_date, error::CHITTER);
                next;
            }

            if (m/Tellers for the $teller_tag/)
            {
                $isteller = 1;
            }
            else
            {
                if ($isteller and m/ and /)
                {
                    # sometimes tellers both on one line
                    my ($teller1, $teller2) = split(/ and /);
                    add_name($teller1, $isaye, $isteller);
                    add_name($teller2, $isaye, $isteller);
                }
                else
                {
                    add_name($_, $isaye, $isteller);
                }
            }
        }

        return $isaye;
    };

    my $aye_first = aye_or_no_scan();
    my $aye_second = aye_or_no_scan();
    die "Double AYES or double NOES" if ($aye_first == $aye_second);

    # Confirm change (this should be done with transactions, but I don't
    # want to get into them as web providers I want to use may not offer
    # support for that db type in mysql)
    db::query($dbh, "update pw_division set valid = 1 where division_id = ?", $division_id);
    error::log("Added new division $division_number $division_name", $day_date, error::IMPORTANT);

    return 1;
}

1;
