#!/usr/bin/perl

while(<>) {
    if (my ($a, $b) = m#member/(\d+).*html/(\d+)#) {
        print "$b,http://www.theyworkforyou.com/mp/?m=$a\n";
    } else {
        print STDERR "Didn't match: $_\n";
    }
}

