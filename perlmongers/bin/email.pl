#!/usr/bin/perl -w
#
# Program to list the leader's email address for all active perl
# monger groups. Output is written to stdout.
#

use strict;

$|++;

use XML::XPath;

my $xp = XML::XPath->new(filename => 'perl_mongers.xml')
  || die 'badness!!';

my @nodes = ($xp->findnodes('/perl_mongers/group[@status="active"]'));

foreach (@nodes) {
  print $_->findvalue('tsar/email'), "\n";
}

