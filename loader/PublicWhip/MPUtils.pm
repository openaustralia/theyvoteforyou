# $Id: MPUtils.pm,v 1.1 2004/06/08 11:56:54 frabcus Exp $
# Parse names of MPs, search for an MP in the database.  Copes with the
# various textual varieties you get, such as initials absent or present,
# name abbreviations, titles/honours present or absent.  Uses a mixture
# of heuristics and special cases to do this.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package PublicWhip::MPUtils;
use strict;

# Pretend we're in Wales to cope with the accent in Siôn's name
# (hope this doesn't have other unforseen consequences, such as the
# sorting of names with a double L that will affect English names
# in a confusing manner)
#use POSIX;
#use locale;
#setlocale(LC_CTYPE, "cy.ISO8859-14") or die "Welsh setlocale failed";
# This code didn't work everywhere, so we explicitly check for the
# letter ô in various regexps below.

sub parse_formal_name {
    $_ = shift;

    # "rah" here is a typo in division 64 on 13 Jan 2003 "Ancram, rah Michael"
    my $titles =
"Dr\\ |Hon\\ |hon\\ |rah\\ |rh\\ |Mrs\\ |Ms\\ |Dr\\ |Mr\\ |Miss\\ |Ms\\ |Rt\\ Hon\\ |The\\ Reverend\\ |Sir\\ |Rev\\ ";
    my $honourifics = "\\ CBE|\\ OBE|\\ MBE|\\ QC|\\ BEM|\\ rh|\\ RH";

    # Sometimes get weird hyphens, decimal char 150, hex 96.  Convert to
    # normal.  Division 319, 24 Sept 2002 is an example.
    s/\x96/-/g;

    # Remove dots, but leave a space between them
    s/\./ /g;
    s/  / /g;

    # Strip "and" at start or end (for tellers)
    s/ and$//;
    s/^and //;

    # Strip trailing and leading spaces
    s/^\s+//;
    s/\s+$//;

    $_ = "Simon, Sion" if ( $_ eq "Simon, Sio(r)n (B'ham Erdington)" );

    # Parse MP name strings
    my ( $last, $title, $first, $extra );

    # First of all, ones such as.
    # Ancram, Rt Hon Michael QC (Con)
    # Campbell, rh Menzies <i>(NE Fife)</i>
    if (
        m/^                   # start of line
      ([\w\-' Ö]+)        # last name (into var1) (IDS has space in his surname)
      ,\                  # comma and space
      ($titles)*          # any titles they may have, or none (into var2)
      ([\w. ôö]+?)        # first name and initials (into var3) not greedy
      (?:$honourifics)*   # any honourifics they may have, or none
      (?:\ \((.+)\))?     # last info (party or constituency) is everything in brackets (into var4)
      $                   # end of line
      /x
      )
    {
        ( $last, $title, $first, $extra ) = ( $1, $2, $3, $4 );
    }
    elsif (
        m/^                   # start of line
      ($titles)*          # any titles they may have, or none (into var1)
      ([\w. ôö]+?)        # first name and initials (into var2) not greedy
      \                   # space
      ([\w\-'Ö]+)         # last name (into var3) - hope IDS is never teller! we want initials to go in first name, and there is no separator
      $                   # end of line
      /x
      )

    {
        ( $title, $first, $last ) = ( $1, $2, $3 );
    }
    else {
        die "Couldn't match parts of $_";
    }

    # Remove space from after titles
    if ( defined $title ) {
        chop $title;
    }

    # Strip trailing and leading spaces
    $first =~ s/^\s+//;
    $first =~ s/\s+$//;

    return ( $first, $last, $title, $extra );
}

# Returns ID of an MP given their name, title and constituency
sub find_mp {
    my ( $dbh, $firstname, $lastname, $title, $constituency, $date ) = @_;

    # Special cases for constituencies
    $constituency = "" if ( !defined $constituency );
    $constituency =~ s/ W$/ West/;
    $constituency = "Carmarthen East & Dinefwr"
      if ( $constituency eq "E Carmarthen" );
    $constituency = "Great Yarmouth" if ( $constituency eq "Gt Yarmouth" );
    $constituency = "West Aberdeenshire & Kincardine"
      if ( $constituency eq "Aberdeenshire and Kincardine" );
    $constituency = "Carmarthen East & Dinefwr"
      if ( $constituency eq "E Carmarthen and Dinefwr" );
    $constituency = "Swansea West" if ( $constituency eq "Swansea W" );

    # Special cases for MP name variants
    # 2001- parliament...
    $firstname = "Siôn" if ( $firstname eq "Sion"     && $lastname eq "Simon" );
    $firstname = "Nick" if ( $firstname eq "Nicholas" && $lastname eq "Brown" );
    $firstname = "Geoff" if ( $firstname eq "Geoffrey" && $lastname eq "Hoon" );
    $firstname = "Jonathan R"
      if ( $firstname eq "Jonathan" && $lastname eq "Shaw" );
    $firstname = "Dave" if ( $firstname eq "David"   && $lastname eq "Watts" );
    $firstname = "Des"  if ( $firstname eq "Desmond" && $lastname eq "Browne" );
    $firstname = "Annette"
      if ( $firstname eq "Annette L" && $lastname eq "Brooke" );
    $lastname  = "Öpik" if ( $firstname eq "Lembit" && $lastname eq "Opik" );
    $firstname = "Siôn" if ( $firstname eq "Siön"   && $lastname eq "Simon" );
    $firstname = "Gareth"
      if ( $firstname eq "Gareth R"
        && $lastname     eq "Thomas"
        && $constituency eq "Harrow West" );

    if (   $firstname eq "Gareth R"
        && $lastname     eq "Thomas"
        && $constituency eq "" )
    {
        $firstname    = "Gareth";
        $constituency = "Harrow West";
    }
    $firstname = "Raymond" if ( $firstname eq "Ray" && $lastname eq "Powell" );
    $lastname = "Clark" if ( $firstname eq "Helen" && $lastname eq "Brinton" );
    $firstname = "Gregory" if ( $firstname eq "Greg" && $lastname eq "Barker" );
    $firstname = "Bob" if ( $firstname eq "Robert" && $lastname eq "Spink" );
    $firstname = "Robert"
      if ( $firstname eq "Robert N" && $lastname eq "Wareing" );
    $firstname = "Jimmy" if ( $firstname eq "James" && $lastname eq "Wray" );

    $lastname = "Murrison"
      if ( $firstname eq "Andrew" && $lastname eq "Morrison" );
    $lastname = "Turner"
      if ( $firstname eq "Andrew"
        && $lastname     eq "Taylor"
        && $constituency eq "Isle of Wight" );

    # 1997-2001 parliament...
    $firstname = "Bob"
      if ( $firstname eq "Robert" && $lastname eq "Ainsworth" );
    $firstname = "Jeffrey M"
      if ( $firstname eq "Jeffrey" && $lastname eq "Donaldson" );
    $firstname = "Gerry"
      if ( $firstname eq "Gerald" && $lastname eq "Bermingham" );
    $firstname = "John" if ( $firstname eq "John M" && $lastname eq "Taylor" );
    $firstname = "Peter" if ( $firstname eq "Peter L" && $lastname eq "Pike" );
    $firstname = "Andrew"
      if ( $firstname eq "Andrew F" && $lastname eq "Bennett" );
    $firstname = "Ray" if ( $firstname eq "Raymond" && $lastname eq "Whitney" );
    $firstname = "Stephen"
      if ( $firstname eq "Steve" && $lastname eq "McCabe" );
    $firstname = "Norman"
      if ( $firstname eq "Norman A" && $lastname eq "Godman" );
    $firstname = "Jim" if ( $firstname eq "James" && $lastname eq "Wallace" );
    $firstname = "Edward" if ( $firstname eq "Eddie" && $lastname eq "O'Hara" );
    $firstname = "Andy" if ( $firstname eq "Andrew" && $lastname eq "Reed" );
    $firstname = "Mo" if ( $firstname eq "Marjorie" && $lastname eq "Mowlam" );
    $firstname = "Alan"
      if ( $firstname eq "Alan W" && $lastname eq "Williams" );
    $firstname = "Bob" if ( $firstname eq "Robert" && $lastname eq "Blizzard" );
    $firstname = "Archie"
      if ( $firstname eq "Archibald" && $lastname eq "Hamilton" );
    $firstname = "Tom" if ( $firstname eq "Thomas" && $lastname eq "Brake" );
    $firstname = "Liz"
      if ( $firstname eq "Elizabeth" && $lastname eq "Blackman" );
    $firstname = "Tony" if ( $firstname eq "Anthony" && $lastname eq "Colman" );
    $firstname = "Jack"
      if ( $firstname eq "John"
        && $lastname     eq "Cunningham"
        && $constituency eq "Copeland" );
    $firstname = "Michael"
      if ( $firstname eq "Michael John"
        && $lastname     eq "Foster"
        && $constituency eq "Worcester" );
    $firstname = "Michael"
      if ( $firstname eq "Michael J"
        && $lastname     eq "Foster"
        && $constituency eq "Worcester" );
    $firstname = "Michael"
      if ( $firstname eq "Michael J"
        && $lastname eq "Foster"
        && $date     eq "2001-01-17" )
      ; # Michael Foster (worcester) tells 3 times on this day, with an ambiguous name listing, but Jabez (the other Michael Foster) votes each time, so it is clear what the situation is
    $firstname = "Anthony D"
      if ( $firstname eq "Tony D"
        && $lastname     eq "Wright"
        && $constituency eq "Great Yarmouth" );
    $firstname = "Anthony D"
      if ( $firstname eq "Tony"
        && $lastname     eq "Wright"
        && $constituency eq "Great Yarmouth" );
    $firstname = "Steve"
      if ( $firstname eq "Professor Steve" && $lastname eq "Webb" );
    $lastname = "Plaskitt"
      if ( $firstname eq "James" && $lastname eq "Plaskit" );
    $firstname = "Claire"
      if ( $firstname eq "Clare" && $lastname eq "Curtis-Thomas" );
    $firstname = "Phil"  if ( $firstname eq "Philip" && $lastname eq "Hope" );
    $firstname = "Steve" if ( $firstname eq "Steven" && $lastname eq "Webb" );
    $firstname = "Dale"
      if ( $firstname eq "D N" && $lastname eq "Campbell-Savours" );
    $firstname = "Jenny"
      if ( $firstname eq "Jennifer" && $lastname eq "Jones" );
    $firstname = "Joe"   if ( $firstname eq "Joseph" && $lastname eq "Ashton" );
    $firstname = "Tommy" if ( $firstname eq "Thomas" && $lastname eq "Graham" );
    $firstname = "David" if ( $firstname eq "D avid" && $lastname eq "Amess" );
    $firstname = "Christopher"
      if ( $firstname eq "Christoper" && $lastname eq "Gill" );
    $firstname = "Tess" if ( $firstname eq "Tessa" && $lastname eq "Kingham" );
    $firstname = "Andrew" if ( $firstname eq "Andy" && $lastname eq "Love" );
    $firstname = "Denis" if ( $firstname eq "Dennis" && $lastname eq "Murphy" );
    $firstname = "Bill"
      if ( $firstname eq "William" && $lastname eq "O'Brien" );
    $firstname = "Chris"
      if ( $firstname eq "Christine" && $lastname eq "McCafferty" );
    $firstname = "Phil" if ( $firstname eq "Philip" && $lastname eq "Sawford" );
    $firstname = "Rudi" if ( $firstname eq "Rudolf" && $lastname eq "Vis" );
    $firstname = "Thomas"
      if ( $firstname eq "Th omas" && $lastname eq "McAvoy" );
    $firstname = "Michael"
      if ( $firstname eq "Mich ael" && $lastname eq "Ancram" );
    $firstname = "Michael"
      if ( $firstname eq "Michael J" && $lastname eq "Martin" );
    $firstname = "Robert"
      if ( $firstname eq "Robert W"
        && $lastname     eq "Smith"
        && $constituency eq "West Aberdeenshire & Kincardine" );
    $lastname = "Fitzsimons"
      if ( $firstname eq "Lorna" && $lastname eq "Fitzsimmons" );
    $lastname = "Mandelson"
      if ( $firstname eq "Peter" && $lastname eq "Mandleson" );
    $firstname = "Rosie"
      if ( $firstname eq "Rose" && $lastname eq "Winterton" );

    if ( $firstname eq "Nick St" && $lastname eq "Aubyn" ) {
        $firstname = "Nick";
        $lastname  = "St Aubyn";
    }

    # Search for first name, last name,date exact match
    my $sth = PublicWhip::DB::query(
        $dbh, "select mp_id from pw_mp where 
        first_name = ? and last_name = ? and entered_house <= ?
        and left_house >= ?", $firstname, $lastname, $date, $date
    );
    my $hits = $sth->rows;

    # If we find too many, use constituency to discriminate
    if ( $hits > 1 ) {

#        print "Duplicate name discriminating by constituency: $firstname, $lastname, $constituency\n";
        $sth = PublicWhip::DB::query(
            $dbh, "select mp_id from pw_mp where 
            first_name = ? and last_name = ? and constituency = ? and entered_house <= ?
            and left_house >= ?",
            $firstname, $lastname, $constituency, $date, $date
        );
        $hits = $sth->rows;
    }

    die "Too many matches for /$firstname/$lastname/$constituency/$date/"
      if $hits > 1;
    die "Can't find MP /$firstname/$lastname/$constituency/$date/" if $hits < 1;

    my @data  = $sth->fetchrow_array();
    my $mp_id = $data[0];

    return $mp_id;
}

1;
