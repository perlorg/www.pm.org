#!/usr/bin/perl 
use strict;
use warnings FATAL => 'all';

use Getopt::Long qw(GetOptions);
use XML::Simple  qw(XMLin);
use Data::Dumper qw(Dumper);
use LWP::UserAgent;


my %opts;
usage() if not @ARGV;
GetOptions(\%opts, "help", "ping") or usage();
usage() if $opts{help};

$| = 1;

my $source = 'perl_mongers.xml';
die "Cannot fine '$source'\n" if not -e $source;

my $ref = XMLin($source,  ForceArray => 1);

#print join ", ", keys %$ref;
#print Dumper $ref;

if ($opts{ping}) {
    ping();
}

sub ping {
    my $ua = LWP::UserAgent->new;
    $ua->timeout(5);
    foreach my $group (@{$ref->{group}}) {
        #print "Name $group->{name}[0]\n";
        #print "Email $group->{email}[0]\n";
        #print Dumper $group->{email}[0];
        #print "$group->{location}[0]{country}[0]\n";

        if (not defined $group->{status}) {
            print "status is undef for $group->{name}[0] - ERROR\n";
            next;
        }
        if (ref $group->{status}) {
            print "status is a ref: $group->{status} for $group->{name}[0] - ERROR\n";
            next;
        }
        if ($group->{status} =~ m{^(dead|inactive|sleeping|spam|on hold)$}) {
            next;
        }
        if ($group->{status} ne 'active') {
            print "Invalid status '$group->{status}' for $group->{name}[0] - ERROR\n";
            next;
        }

        if (not defined $group->{web}[0]) {
            print "web not defined for $group->{name}[0] - ERROR\n";
            next;
        }
        if (ref $group->{web}[0]) {
            print "web is a ref: $group->{name}[0] - ERROR\n";
            next;
        }

        print "pinging $group->{web}[0]";
        my $response  = $ua->get($group->{web}[0]);
        if ($response->is_success) {
            print " - DONE\n";
        } else {
            print " - $group->{name}[0] FAILED " . $response->status_line . "\n";
        }
    }
}


sub usage {
    print <<"END_USAGE";
Usage: $0
    --help         this help
    --ping         ping the web servers
END_USAGE
    exit;
}


