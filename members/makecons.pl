#! /usr/bin/perl
# $Id: makecons.pl,v 1.5 2005/05/08 09:34:15 frabcus Exp $

# Make the constituency XML file, has heuristics to match same names

# The Public Whip, Copyright (C) 2004 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

print <<END;
<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>

<!--

Unique identifiers and alternative names for UK parliamentary constituencies.
Currently as they are in 2003 - will need to update when boundary changes come
in.

Currently has the name forms used for the list of MPs on the Parliament website,
by the ONS (Office of National Statistics), and by FaxYourMP.com (also BBC iCan).
The Parliament versions are more accurate, so considered canonical.

-->

END

my @parl;
open(PARL, '<constituencies2003-parluk.txt');
while (<PARL>) { chomp; push @parl, $_; }
my %ons;
open(ONS, '<constituencies2003-ons.txt');
while (<ONS>) { chomp; $ons{$_} = 1; }
my %fax;
open(FAX, '<constituencies2003-faxyourmpix.txt');
while (<FAX>) { chomp; $fax{$_} = 1; }

# Find matches
my %opairs;
my %fpairs;
foreach $p (@parl)
{
    my $o = undef;
    my $f = undef;

    # for exact matches
    $_ = $p;
    if ($ons{$_} == 1) { $o = $_; } 
    if ($fax{$_} == 1) { $f = $_; } 

    # for "Westmorland & Lonsdale" == "Westmorland and Lonsdale"
    s/&/and/;
    if ($ons{$_} == 1) { $o = $_; } 
    if ($fax{$_} == 1) { $f = $_; } 

    # for "Chester, City of" == "City of Chester"
    s/([^,]*), (.*)/$2 $1/; 
    if ($ons{$_} == 1) { $o = $_; } 
    if ($fax{$_} == 1) { $f = $_; } 

    # for "Glasgow, Rutherglen" == "Glasgow Rutherglen"
    $_ = $p;
    s/, / /; 
    if ($ons{$_} == 1) { $o = $_; } 
    if ($fax{$_} == 1) { $f = $_; } 
    
    # for "Ashton-under-Lyne" == "Ashton under Lyne"
    $_ = $p;
    s/-/ /g; 
    if ($ons{$_} == 1) { $o = $_; } 
    if ($fax{$_} == 1) { $f = $_; } 

    # for "St. Ives" == "St Ives"
    $_ = $p;
    s/St /St. /g;
    if ($fax{$_} == 1) { $f = $_; } 

    # for "Antrim South" = "South Antrim"
    $_ = $p;
    s/(North|South|East|West|Mid|Central) (.*)/$2 $1/;
    if ($fax{$_} == 1) { $f = $_; } 
    $_ = $p;
    s/((North|South) (East|West)) (.*)/$4 $1/;
    if ($fax{$_} == 1) { $f = $_; } 

    # Various special cases for FaxYourMP ix
    $_ = $p;
    s/Kingston upon Hull/Hull/;
    s/Yorks/Yorkshire/;
    s/The Deepings/the Deepings/;
    s/, / /; 
    s/ - / /g; 
    s/&/and/;
    s/nn/n/g;
    if ($fax{$_} == 1) { $f = $_; } 
    # more complex compass stuff
    s/(North|South|East|West|Mid|Central) (.+?)\b(.*)/$2 $1$3/;
    my $old = $_;
    if ($fax{$_} == 1) { $f = $_; } 

    # Special cases
    $_ = $p;
    if ($_ eq "Redditch") { $o = "Reddith"; }
    if ($_ eq "Middlesbrough") { $o = "Middlesborough"; }
    if ($_ eq "Middlesbrough South & East Cleveland") { $o = "Middlesborough South and East Cleveland"; }
    if ($_ eq "Epsom & Ewell") { $o = "Epson and Ewell"; }
    if ($_ eq "Ynys Môn") { $o = "Ynys Mon"; $f = $o; }
    if ($_ eq "Ruislip - Northwood") { $o = "Ruislip-Northwood"; }
    if ($_ eq "Stockton South") { $o = "Stockport South"; } # !!!, ONS messed up...

    if ($_ eq "Mid Dorset & North Poole") { $f= "Dorset Mid and Poole North"; }
    if ($_ eq "Torridge & West Devon") { $f = "Devon West and Torridge"; }
    if ($_ eq "Carmarthen West & South Pembrokeshire") { $f = "Carmarthen West and Pembrokeshire South"; }

    # Mark match
    if ($o)
    {
        $opairs{$p} = $o;
        $ons{$o} = undef;
    }
    else
    {
        print STDERR "Failure (in parl not in ons): ", $p , "\n";
    }
    if ($f)
    {
        $fpairs{$p} = $f;
        $fax{$f} = undef;
    }
    else
    {
        print STDERR "Failure (in parl not in faxyourmp): ", $p , "\n";
    }
}

# Output missing members from ONS/FaxYourMP
foreach $o (keys(%ons))
{
    if ($ons{$o})
    {
        print STDERR "Failure (in ons not in parl): ", $o, "\n";
    }
}
foreach $f (keys(%fax))
{
    if ($fax{$f})
    {
        print STDERR "Failure (in faxyourmp not in parl): ", $f, "\n";
    }
}

$c = 0;
foreach $_ (sort(keys(%opairs)))
{
    $p = $_;
    $o = $opairs{$p};
    $f = $fpairs{$p};
    $p =~ s/&/&amp;/;
    $o =~ s/&/&amp;/;
    $f =~ s/&/&amp;/;
    if ($o eq $p) { $oo = "" } else { $oo = "\n    <name text=\"$o\"/> <!-- ONS -->"; }
    if ($f eq $p) { $ff = "" } else { $ff = "\n    <name text=\"$f\"/> <!-- FaxYourMP index -->"; }
    if (($f eq $o) and ($o ne $p)) { $ff = ""; }
    $c++;
#<constituency id="uk.org.publicwhip/cons/$c" fromdate="1000-01-01" todate="2005-05-04">
print <<END;
<constituency id="uk.org.publicwhip/cons/$c">
    <name text="$p"/>$oo$ff
</constituency>
END
}

print "\n";
print "</publicwhip>\n";

