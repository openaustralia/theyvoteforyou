# $Id: mputils.pm,v 1.2 2003/09/29 19:36:28 frabcus Exp $
# Parse names of MPs, search for an MP in the database.  Copes with the
# various textual varieties you get, such as initials absent or present,
# name abbreviations, titles/honours present or absent.  Uses a mixture
# of heuristics and special cases to do this.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package mputils;
use strict;

# Pretend we're in Wales to cope with the accent in Siôn's name
# (hope this doesn't have other unforseen consequences, such as the
# sorting of names with a double L that will affect English names 
# in a confusing manner)
#use POSIX;
#use locale;
#setlocale(LC_CTYPE, "cy.ISO8859-14") or die "Welsh setlocale failed";

sub parse_formal_name
{
    $_ = shift;

    # "rah" here is a typo in division 64 on 13 Jan 2003 "Ancram, rah Michael"
    my $titles = "Dr\\ |Hon\\ |hon\\ |rah\\ |rh\\ |Mrs\\ |Ms\\ |Dr\\ |Mr\\ |Miss\\ |Ms\\ |Rt\\ Hon\\ |The\\ Reverend\\ |Sir\\ |Rev\\ ";
    my $honourifics = "\\ CBE|\\ OBE|\\ MBE|\\ QC|\\ BEM|\\ rh|\\ RH";

    # Sometimes get weird hyphens, decimal char 150, hex 96.  Convert to
    # normal.  Division 319, 24 Sept 2002 is an example.
    s/\x96/-/g;

    # Remove dots, but leave a space between them
    s/\./ /g;
    s/  / /g;
    # Strip trailing and leading spaces
    s/^\s+//;
    s/\s+$//;

    # Parse strings such as:
    # Ancram, Rt Hon Michael QC (Con)
    # Campbell, rh Menzies <i>(NE Fife)</i>
    m/^                   # start of line
      ([\w\-' Ö]+)        # last name (into var1) (IDS has space in his surname)
      ,\                  # comma and space
      ($titles)*          # any titles they may have, or none (into var2)
      ([\w. ôö]+?)        # first name and initials (into var3) not greedy
      (?:$honourifics)*   # any honourifics they may have, or none
      (?:\ \((.+)\))?     # last info (party or constituency) is everything in brackets (into var4)
      $                   # end of line
      /x
        or die "Couldn't match parts of $_";

    my ($last, $title, $first, $extra) = ($1, $2, $3, $4);

    # Remove space from after titles
    if (defined $title)
    {
        chop $title;
    }

    # Strip trailing and leading spaces
    $first =~ s/^\s+//;
    $first =~ s/\s+$//;

    return ($first, $last, $title, $extra);
}

# Returns ID of an MP given their name, title and constituency
sub find_mp
{   
    my($dbh, $firstname, $lastname, $title, $constituency, $date) = @_;

    # Special cases for constituencies
    $constituency = "" if (! defined $constituency);
    $constituency =~ s/ W$/ West/;

    # Special cases for MP name variants
    $firstname = "Nick" if ($firstname eq "Nicholas" && $lastname eq "Brown");
    $firstname = "Geoff" if ($firstname eq "Geoffrey" && $lastname eq "Hoon");
    $firstname = "Jonathan R" if ($firstname eq "Jonathan" && $lastname eq "Shaw");
    $firstname = "Dave" if ($firstname eq "David" && $lastname eq "Watts");
    $firstname = "Des" if ($firstname eq "Desmond" && $lastname eq "Browne");
    $firstname = "Annette" if ($firstname eq "Annette L" && $lastname eq "Brooke");
    $lastname = "Öpik" if ($firstname eq "Lembit" && $lastname eq "Opik");
    $firstname = "Siôn" if ($firstname eq "Siön" && $lastname eq "Simon");
    $firstname = "Gareth" if ($firstname eq "Gareth R" && $lastname eq "Thomas" && $constituency eq "Harrow West");
    $firstname = "Raymond" if ($firstname eq "Ray" && $lastname eq "Powell");
    $lastname = "Clark" if ($firstname eq "Helen" && $lastname eq "Brinton");
    $firstname = "Gregory" if ($firstname eq "Greg" && $lastname eq "Barker");
    $firstname = "Bob" if ($firstname eq "Robert" && $lastname eq "Spink");
    $firstname = "Robert" if ($firstname eq "Robert N" && $lastname eq "Wareing");
    $firstname = "Jimmy" if ($firstname eq "James" && $lastname eq "Wray");

    # Our clerks make their first genuine spelling mistakes as far as I can tell...
    # http://www.publications.parliament.uk/pa/cm200203/cmhansrd/cm030226/debtext/30226-35.htm
    $lastname = "Murrison" if ($firstname eq "Andrew" && $lastname eq "Morrison");
    $lastname = "Turner" if ($firstname eq "Andrew" && $lastname eq "Taylor" && $constituency eq "Isle of Wight");

    # Search for first name, last name,date exact match
    my $sth = db::query($dbh, "select mp_id from pw_mp where 
        first_name = ? and last_name = ? and entered_house <= ?
        and left_house >= ?", $firstname, $lastname, $date, $date);
    my $hits = $sth->rows;

    # If we find too many, use constituency to discriminate
    if ($hits > 1)
    {
        #print "Duplicate name discriminating by constituency: $firstname, $lastname, $constituency"
        $sth = db::query($dbh, "select mp_id from pw_mp where 
            first_name = ? and last_name = ? and constituency = ?",
            $firstname, $lastname, $constituency);
        $hits = $sth->rows;
    }
    
    die "Too many matches for /$firstname/$lastname/$constituency/$date/" if $hits > 1;
    die "Can't find MP /$firstname/$lastname/$constituency/$date/" if $hits < 1;

    my @data = $sth->fetchrow_array();
    my $mp_id = $data[0];

    return $mp_id;
}

1;
