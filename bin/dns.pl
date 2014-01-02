#!/usr/bin/perl -w
#
# Program to list the leader's email address for all active perl
# monger groups. Output is written to stdout.
#

use strict;
use Net::DNS;
use XML::XPath;

$|++;

my $res = Net::DNS::Resolver->new;

my $xp = XML::XPath->new(filename => 'perl_mongers.xml')
  || die 'badness!!';

my @nodes = ($xp->findnodes('/perl_mongers/group'));
@nodes = map  { $_->[0] }
         sort { $a->[1] cmp $b->[1] }
         map  { [ $_, lc $_->findnodes('name') ] }
         @nodes;

foreach (@nodes) {
  print "\n\n";
  print $_->findvalue('name'), ' [',
        $_->findvalue('@status') || 'inactive', "]\n";
  my $host = $_->findvalue('web');
  unless ($host) {
    print "No host\n";
    next;
  }
  $host =~ s|^http://||;
  $host =~ s|/.*$||;
  print "$host\n";
  my $dns = $res->search($host);
  unless ($dns) {
    print "No DNS\n";
    next;
  }
  foreach my $a ($dns->answer) {
    next unless $a->type eq 'A';
    print $a->address, "\n";
  }
  my @mx = mx($res, $host);
  unless (@mx) {
    print "No MX\n";
    next;
  }
  foreach my $m (@mx) {
    print $m->preference, ' ', $m->exchange, "\n";
  }
}

