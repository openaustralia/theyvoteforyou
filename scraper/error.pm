# $Id: error.pm,v 1.3 2003/09/25 20:29:17 uid37249 Exp $
# Error handling.  We often find divisions with slightly different
# date that requires updating of the parser, or new special case code.
# This module centrally handles parsing errors for ease.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package error;
use strict;

use Carp;

use constant IMPORTANT => 10;
use constant USEFUL => 5;
use constant CHITTER => 1;

our $verbosity = IMPORTANT;

sub setverbosity
{
    my $new = shift;
    $verbosity = $new;    
}

sub printout
{
    my $stubid = shift;
    my $msg = shift;
    my $location = shift;
    
    print STDERR $stubid . " $msg";
    print " - " . $location if $location ne "";
    print "\n";
}

sub log
{
    my $msg = shift;
    my $location = shift;
    my $level = shift;

    # Don't show anything if level lower than verbosity level
    if ($level < $verbosity)
    {
        return;
    }

    if ($level == IMPORTANT)
    {
        printout("LOG+", $msg, $location);
    }
    elsif ($level == USEFUL)
    {
        printout("LOG=", $msg, $location);
    }
    elsif ($level == CHITTER)
    {
        printout("LOG-", $msg, $location);
    }
    else 
    {
        die "Unknown verbosity " . $level;
    }
}

sub warn
{
    my $msg = shift;
    my $location = shift;

    printout("WARN", $msg, $location);
}

sub die
{
    my $msg = shift;
    my $location = shift;
    die_print($msg, $location);
    confess "ESCAPE_FROM_DIV_PARSE";
}

sub die_print
{
    my $msg = shift;
    my $location = shift;
    printout("DIE!", $msg, $location);
}

1;

