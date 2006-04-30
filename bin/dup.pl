#!/usr/bin/perl
#
# Program to list duplicate perl monger groups.
# 
# The output is a list of group names followed by ids.
#
# Note that some duplicates are valid. E.g. there is a Cambridge in the
# UK and another in the US.
#

use strict;
use warnings;

use XML::XPath;

my %groups;

my $xml = XML::XPath->new(filename => 'perl_mongers.xml')
  || die 'badness!!';

foreach ($xml->findnodes('/perl_mongers/group')) {
  my $id = $_->findvalue('@id');
  my $name = $_->findvalue('name/text()');
  $name =~ s/\s//g;

  push @{$groups{$name}}, $id;
}

foreach (sort keys %groups) {
  next if @{$groups{$_}} == 1;

  print "$_: @{$groups{$_}}\n"
}
