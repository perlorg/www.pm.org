#!/usr/bin/perl -w
#
# Program to count perl monger groups by status.
#

$|++;

use XML::XPath;

my $xp = XML::XPath->new(filename => 'perl_mongers.xml')
  || die 'badness!!';

my @nodes = $xp->findnodes('/perl_mongers/group');

my %counts;

foreach (@nodes) {
  $counts{$_->findvalue('@status')}++;
}

my $tot;
print map { $tot += $counts{$_}; "$_ : $counts{$_}\n" } keys %counts;

print "\nTotal: $tot\n";

