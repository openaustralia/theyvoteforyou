#! /usr/bin/perl
# Make the constituency XML file, has heuristics to match same names

print <<END;
<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>

<!--

Unique identifiers and alternative names for UK parliamentary constituencies.
Currently as they are in 2003 - will need to update when boundary changes come
in.

Currently has the name forms used for the list of MPs on the Parliament website
and by the ONS (Office of National Statistics).  The Parliament versions are more
accurate, so considered canonical.

-->

END

my @parl;
open(PARL, '<constituencies2003-parluk.txt');
while (<PARL>) { chomp; push @parl, $_; }
my %ons;
open(ONS, '<constituencies2003-ons.txt');
while (<ONS>) { chomp; $ons{$_} = 1; }

# Find matches
my %pairs;
foreach $p (@parl)
{
    my $o = undef;

    # for exact matches
    $_ = $p;
    if ($ons{$_} == 1) { $o = $_; } 

    # for "Westmorland & Lonsdale" == "Westmorland and Lonsdale"
    s/&/and/;
    if ($ons{$_} == 1) { $o = $_; } 

    # for "Chester, City of" == "City of Chester"
    s/([^,]*), (.*)/$2 $1/; 
    if ($ons{$_} == 1) { $o = $_; } 

    # for "Glasgow, Rutherglen" == "Glasgow Rutherglen"
    $_ = $p;
    s/, / /; 
    if ($ons{$_} == 1) { $o = $_; } 
    
    # for "Ashton-under-Lyne" == "Ashton under Lyne"
    $_ = $p;
    s/-/ /g; 
    if ($ons{$_} == 1) { $o = $_; } 

    # Special cases
    $_ = $p;
    if ($_ eq "Redditch") { $o = "Reddith"; }
    if ($_ eq "Middlesbrough") { $o = "Middlesborough"; }
    if ($_ eq "Middlesbrough South & East Cleveland") { $o = "Middlesborough South and East Cleveland"; }
    if ($_ eq "Epsom & Ewell") { $o = "Epson and Ewell"; }
    if ($_ eq "Ynys Môn") { $o = "Ynys Mon"; }
    if ($_ eq "Ruislip - Northwood") { $o = "Ruislip-Northwood"; }
    if ($_ eq "Stockton South") { $o = "Stockport South"; } # !!!, ONS messed up...

    # Mark match
    if ($o)
    {
        $pairs{$p} = $o;
        $ons{$o} = undef;
    }
    else
    {
        print STDERR "Failure (in parl not in ons): ", $_ , "\n";
    }
}

foreach $o (keys(%ons))
{
    if ($ons{$o})
    {
        print STDERR "Failure (in ons not in parl): ", $o, "\n";
    }
}

$c = 0;
foreach $_ (sort(keys(%pairs)))
{
    $p = $_;
    $o = $pairs{$p};
    $p =~ s/&/&amp;/;
    $o =~ s/&/&amp;/;
    if ($o eq $p) { $o = "" } else { $o = "\n    <name text=\"$o\"/>"; }
    $c++;
print <<END;
<constituency id="uk.org.publicwhip/cons/$c">
    <name text="$p"/>$o
</constituency>
END
}

print "\n";
print "</publicwhip>\n";

